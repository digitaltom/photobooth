# frozen_string_literal: true

require 'open3'

# Elgato Stream Deck Mini (USB HID) on the kiosk. The keys count 0..5 from the top left:
#   0, 2:    the newest and the second newest set, a press opens it on the kiosk
#   1:       the camera icon, a press starts the countdown on the kiosk
#   3, 4, 5: the text under the shoot button of the kiosk scrolls over them, a press also starts the countdown
# Protocol as in python-elgato-streamdeck (StreamDeckMini), read and written through /dev/hidrawN.
class StreamDeck # rubocop:disable Metrics/ClassLength

  HID_ID = 'HID_ID=0003:00000FD9:00000063'
  SHOOT_KEY = 1
  SET_KEYS = [0, 2].freeze
  TEXT_KEYS = [3, 4, 5].freeze
  # hardware knobs, tune them on the device
  BRIGHTNESS = 80 # percent
  SCROLL_STEP = 8 # pixels per frame
  FRAME_DELAY = 0.05 # seconds between the frames, on top of the USB transfer of 3 keys
  SIZE = 80 # pixels of a key
  ANIMATION_DELAY = 0.6 # seconds per frame, as -delay 60 in PictureSet#create_animation
  # an image centered on a black key
  FIT = %W[-background black -alpha remove -alpha off -resize #{SIZE}x#{SIZE} -gravity center -extent #{SIZE}x#{SIZE}].freeze
  ICON = Rails.public_path.join('images/take_picture.png')
  PAGE = 1024 # image report: 16 bytes header + image data
  HEADER = 16
  HIDIOCSFEATURE = 0xC0114806 # _IOC(_IOC_READ | _IOC_WRITE, 'H', 0x06, 17)
  RETRY = 2 # seconds, also the time until a plugged in device shows up

  class << self

    # polls for the device, so it connects on plug in and again after an unplug
    def start
      # the open kiosk page does not load again after an app restart
      update(PictureSet.all)
      Thread.new do
        loop do
          path = device
          path ? run(path) : sleep(RETRY)
        rescue StandardError => e
          # EACCES without the udev rule, EIO on unplug
          Rails.logger.warn("Stream Deck: #{e.message}") unless e.message == @error
          @error = e.message
          sleep RETRY
        end
      end
    end

    # The kiosk page calls it with its sets and in its locale. The keys change on the next frame.
    def update(picture_sets)
      @state = { sets: picture_sets.first(SET_KEYS.size).map { |set| [set.to_param, File.join(set.dir, set.animation)] },
                 text: _('Tap to take a picture') }
    end

    def shoot
      Turbo::StreamsChannel.broadcast_action_to(:kiosk, action: :shoot)
    end

    def show_set(id)
      Turbo::StreamsChannel.broadcast_action_to(:kiosk, action: :visit,
                                                        attributes: { url: Rails.application.routes.url_helpers.set_path(id) })
    end

    # one handle to write (the animation thread), one to read the keys
    def run(path)
      File.open(path, 'wb') do |out|
        out.sync = true # hidraw takes one report per write, a buffer joins them and the Mini drops off USB
        feature(out, 0x0B, 0x63) # reset
        feature(out, 0x05, 0x55, 0xAA, 0xD1, 0x01, BRIGHTNESS)
        write_key(out, SHOOT_KEY, bmp(image(ICON.to_s, *FIT)))
        Rails.logger.info('Stream Deck connected')
        @error = nil
        writer = Thread.new { animate(out) }
        writer.report_on_exception = false # an unplug also stops the read below, that one logs it
        File.open(path, 'rb') { |io| read_keys(io) }
      ensure
        writer&.kill
      end
    end

    def read_keys(io)
      states = Array.new(6, 0)
      loop do
        # byte 0: report id, bytes 1..6: key states
        new_states = io.readpartial(64).bytes[1, 6]
        new_states.each_with_index { |down, key| press(key) if down == 1 && states[key].zero? }
        states = new_states
      end
    end

    def press(key)
      id = @state[:sets][SET_KEYS.index(key)]&.first if SET_KEYS.include?(key)
      id ? show_set(id) : shoot
    end

    def animate(out)
      drawn = strip = thumbs = shown = nil
      offset = 0
      loop do
        state = @state
        unless state == drawn
          thumbs = SET_KEYS.each_index.map { |i| thumbnail(state[:sets][i]&.last) }
          strip = text_strip(drawn = state)
          shown = []
        end
        draw_sets(out, thumbs, shown)
        offset = draw_text(out, strip, offset)
        sleep FRAME_DELAY
      end
    end

    # returns the offset of the next frame
    def draw_text(out, strip, offset)
      TEXT_KEYS.each_with_index { |key, i| write_key(out, key, bmp(strip, offset + (i * SIZE))) }
      (offset + SCROLL_STEP) % ((strip.bytesize / (SIZE * 3)) - (TEXT_KEYS.size * SIZE))
    end

    # The frames of a set animation follow each other in thumbs (see image), each with SIZE columns.
    # shown: the frame on each key, a key only gets written when its frame changes
    def draw_sets(out, thumbs, shown)
      tick = (Process.clock_gettime(Process::CLOCK_MONOTONIC) / ANIMATION_DELAY).to_i
      thumbs.each_with_index do |raw, i|
        frame = tick % (raw.bytesize / (SIZE * SIZE * 3))
        next if frame == shown[i]

        write_key(out, SET_KEYS[i], bmp(raw, frame * SIZE))
        shown[i] = frame
      end
    end

    # 24 bit BMP of the key from SIZE columns of a transposed image (see image).
    # The Mini wants the image rotated by 90° counterclockwise and flipped vertically: that is the transposed image.
    # A BMP starts with the bottom row, so the rows go from the last column back to the first.
    def bmp(raw, column = 0)
      row = SIZE * 3
      pixels = (column...(column + SIZE)).reverse_each.map { |col| raw.byteslice(col * row, row) }.join
      ['BM', 54 + pixels.bytesize, 0, 54, 40, SIZE, SIZE, 1, 24, 0, pixels.bytesize, 0, 0, 0, 0]
        .pack('a2VVVVl<l<vvVVl<l<VV') + pixels
    end

    def write_key(out, key, bmp)
      pages = (0...bmp.bytesize).step(PAGE - HEADER).map { |pos| bmp.byteslice(pos, PAGE - HEADER) }
      pages.each_with_index do |data, num|
        header = [0x02, 0x01, num, 0, num == pages.size - 1 ? 1 : 0, key + 1].pack('C6x10')
        out.write((header + data).ljust(PAGE, "\0"))
      end
    end

    private

    def device
      uevent = Dir['/sys/class/hidraw/hidraw*/device/uevent'].find { |file| File.read(file).include?(HID_ID) }
      "/dev/#{uevent.split('/')[4]}" if uevent
    end

    def feature(out, *bytes)
      out.ioctl(HIDIOCSFEATURE, bytes.pack('C*').ljust(17, "\0"))
    end

    # BGR pixels with 8 bit, transposed: each row holds a column of the image, from the top
    def image(*)
      raw, status = Open3.capture2(PictureSet::IMAGEMAGICK, *, '-transpose', '-depth', '8', 'bgr:-', binmode: true)
      raise "#{PictureSet::IMAGEMAGICK} failed for a Stream Deck image" unless status.success?

      raw
    end

    # all frames of the animation (-coalesce: full frames, not only the changed part), a black key without a set
    def thumbnail(animation)
      image(animation || 'xc:black', '-coalesce', *FIT)
    rescue StandardError => e
      raise unless animation

      Rails.logger.warn("Stream Deck: #{e.message}")
      thumbnail(nil)
    end

    # The text with the width of the 3 keys in black on both sides: it scrolls in from the right and out to the left
    def text_strip(state)
      image('-background', 'black', '-fill', 'white', '-font', PictureSet.font, '-pointsize', '36',
            '-size', "x#{SIZE}", '-gravity', 'center', "label:#{state[:text]}",
            '-bordercolor', 'black', '-border', "#{TEXT_KEYS.size * SIZE}x0")
    end

  end

end
