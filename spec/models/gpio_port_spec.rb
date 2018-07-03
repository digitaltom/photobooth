require 'rails_helper'

RSpec.describe GpioPort, type: :model do

  before(:each) do
    stub_const('PiPiper', Class.new)
    PiPiper::Pin = double('PiPiper::Pin')
  end

  describe '#on' do

    it 'turns on pin' do
      pin = double
      expect(File).to receive(:open).with('/sys/class/gpio/unexport', 'w')
      expect(PiPiper::Pin).to receive(:new).with(pin: 5, direction: :out).and_return(pin)
      expect(pin).to receive(:on)
      GpioPort.on(5)
    end

  end

  describe '#off' do

    it 'turns off pin' do
      pin = double
      expect(File).to receive(:open).with('/sys/class/gpio/unexport', 'w')
      expect(PiPiper::Pin).to receive(:new).with(pin: 5, direction: :out).and_return(pin)
      expect(pin).to receive(:off)
      GpioPort.off(5)
    end

  end

end
