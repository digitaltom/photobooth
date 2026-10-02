# frozen_string_literal: true

Rails.application.config.after_initialize do
  GpioPort.on(GpioPort::GPIO_PORTS['READY']) if Rails.env.production?
end
