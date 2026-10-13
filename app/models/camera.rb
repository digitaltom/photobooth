# frozen_string_literal: true

class Camera

  FAKE_IMAGES = Rails.root.join('lib/fake_camera')
  RETRIES = 3
  # Canon EOS labels, 'c' = normal instead of fine compression (sizes for a 24 MP sensor).
  # S2 has one quality only, gphoto2 calls it S2 or cS2 by the compression that the camera reports.
  IMAGEFORMATS = {
    'L' => 'large, 6000x4000, fine',
    'cL' => 'large, 6000x4000, normal',
    'M' => 'medium, 3984x2656, fine',
    'cM' => 'medium, 3984x2656, normal',
    'S1' => 'small, 2976x1984, fine',
    'cS1' => 'small, 2976x1984, normal',
    'S2' => 'small, 2400x1600',
    'cS2' => 'small, 2400x1600'
  }.freeze

  # Takes 4 photos <date>_1.jpg .. <date>_4.jpg into dir, yields the number of each saved photo.
  def self.capture(dir, date, &)
    if OPTS.camera == 'fake'
      (1..4).each do |num|
        sleep OPTS.camera_delay.to_f
        FileUtils.cp(FAKE_IMAGES.join("#{num}.jpg"), File.join(dir, "#{date}_#{num}.jpg"))
        yield num
      end
    elsif OPTS.camera == 'webcam'
      webcam(dir, date, &)
    else
      gphoto2(dir, date, &)
    end
  end

  # One ffmpeg process per photo from a V4L2 (USB) webcam. -ss 1 drops the first second of frames:
  # the webcam adjusts its exposure in that time, the first frames are too dark.
  # A shot starts camera_delay s after the start of the previous shot, as with gphoto2 -I.
  # Without webcam_size, the webcam uses its default size.
  # ponytail: no -input_format, a size that the webcam has in MJPEG only can fail, add it when a webcam needs it
  def self.webcam(dir, date)
    device = webcam_device.shellescape
    size = "-video_size #{OPTS.webcam_size.to_s.shellescape} " if OPTS.webcam_size.present?
    (1..4).each do |num|
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Syscall.execute("ffmpeg -loglevel error -y -f v4l2 #{size}-i #{device} -ss 1 -frames:v 1 -q:v 2 #{date}_#{num}.jpg", dir: dir)
      yield num
      sleep [OPTS.camera_delay.to_f - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started), 0].max if num < 4
    end
  end

  # One process for all photos: every gphoto2 start opens a new PTP session (1-2 s).
  # capturetarget=0 is "Internal RAM" on Canon EOS: the camera does not write to its SD card first.
  # -I: a shot starts at least camera_delay s after the start of the previous shot, gphoto2 waits when the camera is faster.
  def self.gphoto2(dir, date)
    saved = 0
    attempt = 0
    begin
      attempt += 1
      Syscall.execute("gphoto2 --set-config capturetarget=0 #{imageformat_option}" \
                      "--capture-image-and-download -F 4 -I #{OPTS.camera_delay.to_i} --force-overwrite --filename #{date}_%n.jpg",
                      dir: dir) do |line|
        num = saved_number(line, date)
        next unless num

        saved = num
        yield num
      end
      raise "Image capture failed, got #{saved} of 4 photos" unless saved == 4
    rescue StandardError => e
      drain
      # only retry when no photo was taken yet, else the set would mix two sessions
      Rails.logger.warn("Retrying capture (#{attempt}): #{e.message}") && retry if saved.zero? && attempt < RETRIES
      raise e
    end
  end

  # A capture that stops after the shutter release can leave its photo in the camera RAM.
  # The next capture would download it as its first photo, so download it to a temp folder and delete it.
  # ponytail: only after a failure, a power loss during a capture still leaves the photo in the camera
  def self.drain
    Dir.mktmpdir { |tmp| Syscall.execute('gphoto2 --wait-event-and-download=2s', dir: tmp) }
  rescue StandardError => e
    Rails.logger.warn("Camera drain failed: #{e.message}")
  end

  # One gphoto2 process: the first block of --summary (model, version, serial number) and the imageformat choices.
  # ponytail: no lock against a running capture, the camera is busy then and the capture retries
  def self.info
    return { summary: "Fake camera, uses the images from #{FAKE_IMAGES}", imageformats: [] } if OPTS.camera == 'fake'
    return { summary: "Webcam #{File.basename(webcam_device)}", imageformats: webcam_sizes(webcam_device) } if OPTS.camera == 'webcam'

    output = Syscall.execute('gphoto2 --summary --get-config imageformat')
    { summary: output[/^Camera summary:.*?(?=\n\s*\n|\z)/m],
      current_imageformat: output[/^Current: (.*)$/, 1],
      # JPEG only: the polaroids need JPEG files
      imageformats: output.scan(/^Choice: \d+ (.*)$/).flatten.grep_v(/RAW/i) }
  rescue StandardError => e
    { summary: e.message, imageformats: [] }
  end

  # The capture node of the first USB webcam: udev links it as /dev/v4l/by-id/<id>-video-index0.
  # /dev/video0 can be another device, for example the codec of the Raspberry Pi.
  def self.webcam_device
    Dir['/dev/v4l/by-id/*-video-index0'].min || raise('No webcam found')
  end

  # The frame sizes of all pixel formats, the largest first. ffmpeg prints a line per format and exits with an error:
  #   [video4linux2,v4l2 @ 0x5555] Raw       :     yuyv422 :           YUYV 4:2:2 : 640x480 160x120
  def self.webcam_sizes(device)
    output = Syscall.execute("ffmpeg -hide_banner -f v4l2 -list_formats all -i #{device.shellescape} || true")
    output.lines.grep(/(Raw|Compressed)\s*:/).flat_map { |line| line.split(' : ').last.split }
          .grep(/\A\d+x\d+\z/).uniq.sort_by { |size| -size.split('x').map(&:to_i).inject(:*) }
  end

  # the option that the image format select of the admin menu writes
  def self.imageformat_key
    OPTS.camera == 'webcam' ? :webcam_size : :camera_imageformat
  end

  def self.imageformat_option
    "--set-config imageformat=#{OPTS.camera_imageformat.to_s.shellescape} " if OPTS.camera_imageformat.present?
  end

  # gphoto2 prints "Saving file as 2026-10-03_12-00-00_1.jpg"
  def self.saved_number(line, date)
    line[/Saving file as #{Regexp.escape(date)}_(\d)\.jpg/, 1]&.to_i
  end

end
