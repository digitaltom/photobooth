# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaptureJob, type: :job do

  around do |example|
    Dir.mktmpdir do |dir|
      old = ENV.fetch('PHOTOBOX_STORAGE', nil)
      ENV['PHOTOBOX_STORAGE'] = dir
      example.run
    ensure
      ENV['PHOTOBOX_STORAGE'] = old
    end
  end

  let(:id) { '2100-01-01_00-00-00' }

  it 'renders polaroids, the animation and set.yml with the fake camera' do
    CaptureJob.perform_now(id)

    set = PictureSet.find(id)
    expect(set.files).to all(satisfy { |name| File.exist?(File.join(set.dir, name)) })
    expect(Dir.glob(File.join(set.dir, "*#{PictureSet::FRAME_SUFFIX}"))).to be_empty
    expect(YAML.safe_load_file(File.join(set.dir, 'set.yml'))).to include('caption' => OPTS.image_caption)
  end

  it 'reports the error to the kiosk' do
    allow(Camera).to receive(:capture).and_raise('Image capture failed')
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice

    expect { CaptureJob.perform_now(id) }.to raise_error('Image capture failed')
  end

end
