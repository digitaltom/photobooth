# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamDeck, type: :model do

  # a hidraw device: one key report per read, then EOF like an unplug
  let(:io) do
    queue = reports.dup
    instance_double(File, ioctl: 0, write: 1024).tap do |dev|
      allow(dev).to receive(:readpartial) { queue.shift || raise(EOFError) }
    end
  end
  let(:reports) { [] }
  let(:icon) { StreamDeck.send(:image, StreamDeck::ICON.to_s, *StreamDeck::FIT) }

  def key_report(*states)
    [1, *states].pack('C7')
  end

  it 'builds the same BMP as ImageMagick with the rotation and flip of the Mini' do
    expected, = Open3.capture2(PictureSet::IMAGEMAGICK, StreamDeck::ICON.to_s, *StreamDeck::FIT,
                               '-rotate', '-90', '-flip', '-type', 'TrueColor', 'BMP3:-', binmode: true)
    expect(StreamDeck.bmp(icon).byteslice(54..)).to eq expected.byteslice((-80 * 80 * 3)..)
  end

  it 'writes the key image in pages of 1024 bytes' do
    written = []
    allow(io).to receive(:write) { |page| written << page }
    StreamDeck.write_key(io, 1, StreamDeck.bmp(icon))

    expect(written.map(&:bytesize).uniq).to eq [1024]
    expect(written.first.bytes.first(6)).to eq [2, 1, 0, 0, 0, 2]
    expect(written.last.bytes.first(6)).to eq [2, 1, written.size - 1, 0, 1, 2]
    expect(written.first.byteslice(16, 2)).to eq 'BM'
  end

  it 'shows the frames of the set animation one after the other' do
    set = PictureSet.all.first # rubocop:disable Rails/RedundantActiveRecordAllMethod
    thumbs = [StreamDeck.send(:thumbnail, File.join(set.dir, set.animation)), StreamDeck.send(:thumbnail, nil)]
    keys = []
    allow(StreamDeck).to receive(:write_key) { |_, key, bmp| keys << [key, bmp] }
    shown = []

    allow(Process).to receive(:clock_gettime).and_return(0.0)
    StreamDeck.draw_sets(io, thumbs, shown)
    StreamDeck.draw_sets(io, thumbs, shown)
    expect(keys.map(&:first)).to eq [0, 2]

    # the next frame, only on the key with the animation
    allow(Process).to receive(:clock_gettime).and_return(StreamDeck::ANIMATION_DELAY)
    StreamDeck.draw_sets(io, thumbs, shown)
    expect(keys.map(&:first)).to eq [0, 2, 0]
    expect(keys.last.last).not_to eq keys.first.last
  end

  it 'scrolls the text in the locale of the kiosk' do
    FastGettext.with_locale('de') { StreamDeck.update([]) }
    expect(StreamDeck.instance_variable_get(:@state)[:text]).to eq 'Tippen, um ein Bild aufzunehmen'
  end

  context 'with key presses' do
    let(:sets) { [PictureSet.new(date: 'new'), PictureSet.new(date: 'old')] }
    let(:reports) do
      [key_report(0, 1, 0, 0, 0, 0), key_report(0, 1, 0, 0, 0, 0), key_report(0, 0, 0, 0, 0, 0),
       key_report(1, 0, 0, 0, 0, 0), key_report(0, 0, 1, 0, 0, 0), key_report(0, 0, 0, 0, 0, 1)]
    end

    it 'shoots with the camera key and the text keys and opens the sets with the others' do
      StreamDeck.update(sets)
      expect(StreamDeck).to receive(:shoot).twice
      expect(StreamDeck).to receive(:show_set).with('new').ordered
      expect(StreamDeck).to receive(:show_set).with('old').ordered
      expect { StreamDeck.read_keys(io) }.to raise_error(EOFError)
    end
  end

end
