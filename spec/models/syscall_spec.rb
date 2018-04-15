require 'rails_helper'

RSpec.describe Syscall, type: :model do

  before(:each) do
    allow(Rails.logger).to receive(:debug).and_return(true)
  end

  describe '#execute' do

    it 'executes the provided command' do
      output = Syscall.execute('uname')
      expect(output).to_not be_empty
    end

    it 'returns the output' do
      output = Syscall.execute('ls')
      expect(output).to_not be_empty
      expect(output).to match(/public/)
    end

    it 'uses the provided directory to run the command' do
      output = Syscall.execute('ls', dir: '/')
      expect(output).to_not be_empty
      expect(output).to match(/root/)
    end

    it 'raises on non-existing command' do
      expect { Syscall.execute('xyz') }.to raise_error(RuntimeError, /not found/)
    end

    it 'raises on non-zero exit code' do
      expect { Syscall.execute('ls /no') }.to raise_error(RuntimeError, /No such file/)
    end

  end

end
