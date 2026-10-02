# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GpioPort, type: :model do

  before { stub_const('GpioPort::AVAILABLE', true) }

  it 'turns on pin' do
    expect(Syscall).to receive(:execute).with('gpioset -t0 -c gpiochip0 5=1')
    GpioPort.on(5)
  end

  it 'turns off pin' do
    expect(Syscall).to receive(:execute).with('gpioset -t0 -c gpiochip0 5=0')
    GpioPort.off(5)
  end

  it 'continues if gpioset fails' do
    expect(Syscall).to receive(:execute).and_raise('busy')
    expect { GpioPort.on(5) }.not_to raise_error
  end

end
