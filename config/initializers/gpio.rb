# rubocop:disable Output
begin
  require 'pi_piper'
  puts '*** Running with gpio support'
rescue LoadError
  Object.send(:remove_const, :PiPiper)
  puts '*** Running without gpio support'
end

GpioPort.on(GpioPort::GPIO_PORTS['READY']) if defined?(PiPiper)
