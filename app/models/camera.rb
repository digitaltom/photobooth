# frozen_string_literal: true

class Camera

  FAKE_IMAGES = Rails.root.join('lib/fake_camera')
  RETRIES = 3

  # Takes 4 photos <date>_1.jpg .. <date>_4.jpg into dir, yields the number of each saved photo.
  def self.capture(dir, date, &)
    if OPTS.camera == 'fake'
      (1..4).each do |num|
        sleep OPTS.camera_delay.to_f
        FileUtils.cp(FAKE_IMAGES.join("#{num}.jpg"), File.join(dir, "#{date}_#{num}.jpg"))
        yield num
      end
    else
      gphoto2(dir, date, &)
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
      # only retry when no photo was taken yet, else the set would mix two sessions
      Rails.logger.warn("Retrying capture (#{attempt}): #{e.message}") && retry if saved.zero? && attempt < RETRIES
      raise e
    end
  end

  def self.imageformat_option
    "--set-config imageformat=#{OPTS.camera_imageformat.to_s.shellescape} " if OPTS.camera_imageformat.present?
  end

  # gphoto2 prints "Saving file as 2026-10-03_12-00-00_1.jpg"
  def self.saved_number(line, date)
    line[/Saving file as #{Regexp.escape(date)}_(\d)\.jpg/, 1]&.to_i
  end

end
