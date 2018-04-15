require 'rails_helper'

# rubocop:disable BlockLength
RSpec.describe PictureSet, type: :model do

  describe '#all' do

    before do
      # PictureSet::PICTURE_PATH = Rails.root.join('spec', 'fixtures', 'filesystem').to_s
      allow(Rails.root).to receive(:join).with('public', 'picture_sets')
                                         .and_return(Rails.root, 'spec', 'fixtures', 'filesystem')
    end

    it 'finds all picture sets' do
      sets = PictureSet.all
      expect(sets).to_not be_empty
    end

    it 'skips incomplete picture sets' do
      sets = PictureSet.all
      expect(sets.size).to eq 1
    end

  end

  describe '#new' do

    it 'returns hash with all needed values' do
      set = PictureSet.new '2099-01-01_01-48-33'
      expect(set).to_not be_empty
      expect(set[:path]).to_not be_empty
      expect(set[:date]).to_not be_empty
      expect(set[:animation]).to_not be_empty
      expect(set[:pictures].size).to eq 4
    end

  end

  describe '#create' do

    before do
      allow(Syscall).to receive(:execute).and_return(true)
    end

    it 'takes new picture' do
      expect(PictureSet).to receive(:new)
      allow(GpioPort).to receive(:on)
      allow(GpioPort).to receive(:off)
      PictureSet.create
    end

  end

  describe '#destroy' do

    it 'deletes set with given date' do
      date = '2099-01-01_01-48-55'
      expect(Syscall).to receive(:execute).with("rm -r #{date}", dir: PictureSet::PICTURE_PATH).and_return(true)
      PictureSet.destroy(date)
    end

  end

end
# rubocop:enable BlockLength
