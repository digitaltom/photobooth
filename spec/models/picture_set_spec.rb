require 'rails_helper'

# rubocop:disable BlockLength
RSpec.describe PictureSet, type: :model do

  before do
    stub_const('PictureSet::PICTURE_PATH', Rails.root.join('spec', 'fixtures', 'filesystem'))
  end

  describe '#all' do

    it 'finds all picture sets' do
      sets = PictureSet.all
      expect(sets).to_not be_empty
      expect(sets.first.dir).to eq File.join(PictureSet::PICTURE_PATH, '2099-01-01_01-48-33')
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
      expect(set.dir).to eq File.join(PictureSet::PICTURE_PATH, '2099-01-01_01-48-33')
      expect(set.date).to eq '2099-01-01_01-48-33'
      expect(set.animation).to eq '2099-01-01_01-48-33_animation.gif'
      expect(set.pictures.size).to eq 4
    end

  end

  describe '#create' do

    before do
      allow(FileUtils).to receive(:mkdir).and_return(true)
    end

    it 'takes new picture' do
      expect(PictureSet).to receive(:new).and_call_original
      expect(Syscall).to receive(:execute).with(/gphoto2 --capture-image-and-download/, anything).exactly(4).times
      expect(Syscall).to receive(:execute).with(/convert/, anything).exactly(4).times
      allow(File).to receive(:exist?).and_return(true)
      allow(GpioPort).to receive(:on)
      allow(GpioPort).to receive(:off)
      PictureSet.create
    end

    it 'raises if image capture failed' do
      allow(PictureSet).to receive(:new).and_call_original
      allow(Syscall).to receive(:execute).with(/gphoto2 --capture-image-and-download/, anything)
      allow(GpioPort).to receive(:on)
      allow(GpioPort).to receive(:off)
      expect { PictureSet.create }.to raise_error('Image capture failed')
    end

  end

  describe '#destroy' do

    it 'deletes set with given date' do
      date = '2099-01-01_01-48-33'
      expect(Syscall).to receive(:execute).with("rm -r #{date}", dir: PictureSet::PICTURE_PATH).and_return(true)
      PictureSet.find(date).destroy
    end

  end

end
# rubocop:enable BlockLength
