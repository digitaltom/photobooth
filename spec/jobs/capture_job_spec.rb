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

  it 'shows the new set on the kiosk when it is done' do
    # the status updates are broadcast actions too
    allow(Turbo::StreamsChannel).to receive(:broadcast_action_to)
    expect(Turbo::StreamsChannel).to receive(:broadcast_action_to)
      .with(:kiosk, action: :visit, attributes: { url: "/sets/#{id}" })

    CaptureJob.perform_now(id)
  end

  it 'reports the steps in the locale of the kiosk' do
    statuses = []
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to) do |*, partial:, locals:, **|
      statuses << ApplicationController.render(partial:, locals:)
    end

    CaptureJob.perform_now(id, 'de')

    expect(statuses.join).to include('Action, Bild 1 / 4', 'Animation wird erstellt')
    expect(I18n.locale).to eq :en
  end

  it 'shows the polaroids in the kiosk status as soon as they are written' do
    statuses = []
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to) do |*, partial:, locals:, **|
      statuses << ApplicationController.render(partial:, locals:)
    end

    CaptureJob.perform_now(id, 'de')

    polaroids = (1..4).map { |num| "src=\"/sets/#{id}/files/#{id}_#{num}_polaroid.png\"" }
    expect(statuses.last).to include(*polaroids)
    # 5 steps and 4 polaroids, all in the locale of the kiosk
    expect(statuses.size).to eq 9
    expect(statuses).to all(include('Bild').or(include('Animation wird erstellt')))
  end

  it 'keeps a set with the photos taken before the camera failed' do
    allow(Camera).to receive(:capture) do |dir, date, &block|
      (1..2).each do |num|
        FileUtils.cp(Camera::FAKE_IMAGES.join("#{num}.jpg"), File.join(dir, "#{date}_#{num}.jpg"))
        block.call(num)
      end
      raise 'Image capture failed, got 2 of 4 photos'
    end

    CaptureJob.perform_now(id)

    set = PictureSet.find(id)
    expect(set.pictures.size).to eq(2)
    expect(set.files).to all(satisfy { |name| File.exist?(File.join(set.dir, name)) })
  end

  it 'stops at the next step without a set and without an error when the kiosk cancels it' do
    allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
    allow(Camera).to receive(:capture) do |dir, date, &block|
      (1..2).each do |num|
        FileUtils.cp(Camera::FAKE_IMAGES.join("#{num}.jpg"), File.join(dir, "#{date}_#{num}.jpg"))
        block.call(num)
        CaptureJob.cancel
      end
      raise 'no third photo after the cancel'
    end
    job = CaptureJob.new(id)
    job.enqueued_at = 1.second.ago

    expect { job.perform_now }.not_to raise_error
    expect(Dir.exist?(PictureSet.new(date: id).dir)).to be false
    expect(Turbo::StreamsChannel).not_to have_received(:broadcast_update_to).with(any_args, hash_including(partial: 'kiosk/error'))
    expect(StreamDeck.instance_variable_get(:@step)).to be_nil

    # a later shoot runs
    allow(Camera).to receive(:capture).and_call_original
    CaptureJob.new(id).tap { it.enqueued_at = Time.current }.perform_now
    expect(PictureSet.find(id).pictures.size).to eq 4
  end

  it 'reports the error to the kiosk and removes the set folder' do
    allow(Camera).to receive(:capture).and_raise('Image capture failed')
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).twice

    expect { CaptureJob.perform_now(id) }.to raise_error('Image capture failed')
    expect(File).not_to exist(PictureSet.new(date: id).dir)
  end

end
