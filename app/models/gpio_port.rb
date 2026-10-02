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

    def on(num)
      set(num, 1)
    end

    def off(num)
      set(num, 0)
    end

    private

    # -t0: set the line and exit instead of holding it
    def set(num, value)
      return unless AVAILABLE

      Syscall.execute("gpioset -t0 -c #{OPTS.gpio_chip} #{num}=#{value}")
    rescue StandardError => e
      Rails.logger.warn("GPIO #{num}=#{value} failed: #{e.message}")
    end

  end

end
