# frozen_string_literal: true

# rubocop:disable Rails/Output
# rubocop:disable Lint/RescueException
begin
  $VERBOSE = nil
  require 'pi_piper'
  GpioPort.on(GpioPort::GPIO_PORTS['READY'])
  puts '*** Running with gpio support'
rescue Exception
  Object.send(:remove_const, :PiPiper)
  puts '*** Running without gpio support'
ensure
  $VERBOSE = false
end
# rubocop:enable Rails/Output
# rubocop:enable Lint/RescueException
