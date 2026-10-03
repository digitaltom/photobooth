# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable-next Metrics/BlockLength
RSpec.describe PictureSet, type: :model do

  describe '#all' do

    it 'finds all picture sets' do
      sets = PictureSet.all
      expect(sets).to_not be_empty
      expect(sets.first.dir).to eq File.join(PictureSet.root, '2099-01-01_01-48-33')
    end

    it 'skips incomplete picture sets' do
      sets = PictureSet.all
      expect(sets.size).to eq 1
    end

  end

  describe '#find' do

    it 'returns found set' do
      expect(PictureSet.find('2099-01-01_01-48-33')).to be_kind_of PictureSet
    end

    it 'raises if not found' do
      expect { PictureSet.find('123') }.to raise_error('PictureSet not found')
    end

  end

  describe '.new' do

    it 'returns hash with all needed values' do
      set = PictureSet.new(date: '2099-01-01_01-48-33')
      expect(set).to_not be_nil
      expect(set.dir).to eq File.join(PictureSet.root, '2099-01-01_01-48-33')
      expect(set.date).to eq '2099-01-01_01-48-33'
      expect(set.animation).to eq '2099-01-01_01-48-33_animation.gif'
      expect(set.pictures.size).to eq 4
    end

  end

  describe '.convert_to_polaroid' do

    it 'sets the caption before it reads the photo' do
      set = PictureSet.new(date: '2099-01-01_01-48-33')
      expect(Syscall).to receive(:execute).with(/-caption 'Photobooth' 2099-01-01_01-48-33_1\.jpg/, anything)
      set.convert_to_polaroid(1, 5)
    end

    it 'writes the polaroid and the GIF frame' do
      set = PictureSet.new(date: '2099-01-01_01-48-33')
      expect(Syscall).to receive(:execute).with(/\+write 2099-01-01_01-48-33_1_polaroid\.png 2099-01-01_01-48-33_1_frame\.gif/, anything)
      set.convert_to_polaroid(1, 5)
    end

  end

  describe '.font' do

    it 'resolves a font file in the repo to an absolute path' do
      expect(PictureSet.font).to eq Rails.root.join('fonts/RockSalt-Regular.ttf').to_s
    end

    it 'keeps an ImageMagick font name' do
      allow(OPTS).to receive(:font).and_return('DejaVu-Sans')
      expect(PictureSet.font).to eq 'DejaVu-Sans'
    end

  end

  describe '.create_animation' do

    context 'file exists' do
      it 'returns' do
        set = PictureSet.new(date: '2099-01-01_01-48-33')
        expect(File).to receive(:exist?).with(File.join(set.dir, set.animation)).and_return(true)
        set.create_animation(overwrite: false)
      end
    end

    context 'file does not yet exist' do
      it 'creates animation' do
        set = PictureSet.new(date: '2099-01-01_01-48-33')
        expect(Syscall).to receive(:execute).with(/MAGICK_THREAD_LIMIT=1 .*#{PictureSet::IMAGEMAGICK} -delay/, anything)
        set.create_animation(overwrite: true)
      end
    end

  end

end
