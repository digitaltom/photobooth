# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Gallery, type: :model do

  around do |example|
    Dir.mktmpdir do |dir|
      old = ENV.fetch('PHOTOBOX_STORAGE', nil)
      ENV['PHOTOBOX_STORAGE'] = dir
      example.run
    ensure
      ENV['PHOTOBOX_STORAGE'] = old
    end
  end

  it 'moves sets from before galleries into the first gallery' do
    FileUtils.mkdir_p(File.join(PictureSet.root, 'old'))
    FileUtils.touch(File.join(PictureSet.root, "old/old#{PictureSet::ANIMATION_SUFFIX}"))

    gallery = Gallery.active
    expect(gallery.caption).to eq OPTS.image_caption
    expect(gallery.sets_count).to eq 1
    expect(Gallery.active).to eq gallery
    expect(Gallery.all.size).to eq 1
  end

  it 'creates and activates a gallery' do
    first = Gallery.active
    gallery = Gallery.create('Freya wird 50')
    expect(gallery.name).to eq "#{Time.now.getlocal.strftime('%Y-%m-%d')}-freya-wird-50"
    expect(Gallery.create('Freya wird 50').name).to eq "#{gallery.name}-2"
    expect(Gallery.active).to eq first

    gallery.activate!
    expect(Gallery.active).to eq gallery
    expect(PictureSet.new(date: 'x').dir).to eq File.join(gallery.dir, 'x')
  end

  it 'limits the caption and removes a leading @' do
    gallery = Gallery.active
    gallery.caption = "@/etc/passwd #{'x' * 50}"
    expect(gallery.caption).to start_with('/etc/passwd')
    expect(gallery.caption.size).to eq Gallery::CAPTION_MAX_LENGTH
  end

  it 'reports the disk usage' do
    expect(Gallery.disk_usage).to include(size: be_positive, used: be_positive, avail: be_positive)
  end

end
