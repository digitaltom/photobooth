# rubocop:disable Output
begin
  require 'pi_piper'
  GpioPort.on(GpioPort::GPIO_PORTS['READY'])
  puts '*** Running with gpio support'
rescue StandardError
  Object.send(:remove_const, :PiPiper)
  puts '*** Running without gpio support'
end
# rubocop:enable Output
