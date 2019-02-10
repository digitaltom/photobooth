# frozen_string_literal: true

# We need to unexport the pins manually here, waiting for merge of:
# https://github.com/jwhitehorn/pi_piper/pull/32

class GpioPort

  GPIO_PORTS = { 'READY' => 23,
                 'PICTURE1' => 4,
                 'PICTURE2' => 5,
                 'PICTURE3' => 6,
                 'PICTURE4' => 17,
                 'PROCESSING' => 24 }.freeze

  class << self

    def on(num)
      return unless defined?(PiPiper)

      unexport(num)
      pin = PiPiper::Pin.new(pin: num, direction: :out)
      pin.on
    end

    def off(num)
      return unless defined?(PiPiper)

      unexport(num)
      pin = PiPiper::Pin.new(pin: num, direction: :out)
      pin.off
    end

    private

    def unexport(num)
      File.open('/sys/class/gpio/unexport', 'w') { |f| f.write(num.to_s) }
    rescue Errno::EINVAL
      Rails.logger.debug "Cannot unset gpio pin ##{num}"
    end

  end

end
