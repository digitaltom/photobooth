# frozen_string_literal: true

# Status LEDs through libgpiod v2, the sysfs interface is gone in current kernels
class GpioPort

  GPIO_PORTS = { 'READY' => 23,
                 'PICTURE1' => 4,
                 'PICTURE2' => 5,
                 'PICTURE3' => 6,
                 'PICTURE4' => 17,
                 'PROCESSING' => 24 }.freeze

  AVAILABLE = system('command -v gpioset > /dev/null')

  class << self

    def on(name)
      set(name, 1)
    end

    def off(name)
      set(name, 0)
    end

    private

    # -t0: set the line and exit instead of holding it
    def set(name, value)
      return unless AVAILABLE

      Syscall.execute("gpioset -t0 -c #{OPTS.gpio_chip} #{GPIO_PORTS.fetch(name)}=#{value}")
    rescue StandardError => e
      Rails.logger.warn("GPIO #{name}=#{value} failed: #{e.message}")
    end

  end

end
