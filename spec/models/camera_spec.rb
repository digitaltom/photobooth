# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Camera, type: :model do

  let(:date) { '2100-01-01_00-00-00' }
  let(:output) do
    ["New file is in location /capt0000.jpg on the camera\n",
     *(1..4).map { |n| "Saving file as #{date}_#{n}.jpg\n" },
     "Deleting file /capt0000.jpg on the camera\n"]
  end

  before { allow(OPTS).to receive(:camera).and_return('gphoto2') }

  it 'reads the summary and the image formats' do
    allow(Syscall).to receive(:execute).with('gphoto2 --summary --get-config imageformat').and_return(<<~OUT)
      Camera summary:
      Manufacturer: Canon Inc.
      Model: Canon EOS 2000D

      Capture Formats: JPEG
      Label: Image Format
      Current: cS2
      Choice: 0 L
      Choice: 1 cS2
      Choice: 2 RAW + L
      END
    OUT
    expect(Camera.info).to eq(summary: "Camera summary:\nManufacturer: Canon Inc.\nModel: Canon EOS 2000D",
                              current_imageformat: 'cS2', imageformats: %w[L cS2])
  end

  it 'shows the error when there is no camera' do
    allow(Syscall).to receive(:execute).and_raise('*** Error: No camera found. ***')
    expect(Camera.info).to eq(summary: '*** Error: No camera found. ***', imageformats: [])
  end

  it 'yields each photo number from the gphoto2 output' do
    expect(Syscall).to receive(:execute).with(/gphoto2 .*-F 4 .*#{date}_%n.jpg/, dir: '/tmp') do |&block|
      output.each(&block)
    end
    expect { |b| Camera.capture('/tmp', date, &b) }.to yield_successive_args(1, 2, 3, 4)
  end

  it 'retries when gphoto2 fails before the first photo' do
    calls = 0
    allow(Syscall).to receive(:execute) do |&block|
      calls += 1
      raise 'Could not claim the USB device' if calls == 1

      output.each(&block)
    end
    expect { |b| Camera.capture('/tmp', date, &b) }.to yield_successive_args(1, 2, 3, 4)
    expect(calls).to eq 2
  end

  it 'does not retry after the first photo' do
    expect(Syscall).to receive(:execute).once do |&block|
      block.call(output[1])
      raise 'PTP I/O error'
    end
    expect { Camera.capture('/tmp', date) { nil } }.to raise_error('PTP I/O error')
  end

end
