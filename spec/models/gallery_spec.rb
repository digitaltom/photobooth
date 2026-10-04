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
    expect(gallery.name).to eq 'freya-wird-50'
    expect(gallery.created_at).to be_within(1.minute).of(Time.current)
    expect(Gallery.create('Freya wird 50').name).to eq 'freya-wird-50-2'
    expect(Gallery.create('Active').name).to eq 'active-2'
    expect(Gallery.create('').name).to eq 'gallery'
    expect(Gallery.active).to eq first

    gallery.activate!
    expect(Gallery.active).to eq gallery
    expect(PictureSet.new(date: 'x').dir).to eq File.join(gallery.dir, 'x')
  end

  it 'renames the folder with the caption and keeps created_at' do
    gallery = Gallery.create('Freya wird 50')
    gallery.activate!
    FileUtils.touch(File.join(gallery.dir, 'x'))

    created_at = gallery.created_at
    renamed = gallery.rename('Hochzeit')
    expect(renamed.name).to eq 'hochzeit'
    expect(renamed.created_at).to eq created_at
    expect(renamed.caption).to eq 'Hochzeit'
    expect(File.exist?(File.join(renamed.dir, 'x'))).to be true
    expect(Gallery.active).to eq renamed
    expect(renamed.rename('Hochzeit')).to eq renamed
  end

  it 'removes a leading @ from the caption' do
    gallery = Gallery.active
    gallery.caption = '@/etc/passwd'
    expect(gallery.caption).to eq '/etc/passwd'
  end

  it 'reports the disk usage' do
    expect(Gallery.disk_usage).to include(path: PictureSet.root.to_s, source: be_present,
                                          size: be_positive, used: be_positive, avail: be_positive)
  end

end
