# rubocop:disable Output Lint/RescueException
begin
  $VERBOSE = nil
  require 'pi_piper'
  GpioPort.on(GpioPort::GPIO_PORTS['READY'])
  puts '*** Running with gpio support'
rescue Exception
  Object.send(:remove_const, :PiPiper)
  puts '*** Running without gpio support'
ensure
  $VERBOSE = nil
end
# rubocop:enable Output
