# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PhotoboxConfig, type: :model do

  around do |example|
    saved = OPTS.dup
    Dir.mktmpdir do |dir|
      OPTS.photobox_conf = File.join(dir, 'photobox.yml')
      example.run
    ensure
      OPTS.replace(saved)
    end
  end

  let(:conf) { PhotoboxConfig.path }

  it 'accepts the default password from options.yml' do
    expect(PhotoboxConfig.admin_password?('photobox')).to be true
    expect(PhotoboxConfig.admin_password?('wrong')).to be false
  end

  it 'never accepts an empty password' do
    OPTS.admin_password = ''
    expect(PhotoboxConfig.admin_password?('')).to be false
  end

  it 'writes a new password into photobox.yml and keeps the comments' do
    File.write(conf, "# WLAN\nwifi_ssid: Photobox\nadmin_password: old\n")
    PhotoboxConfig.admin_password = 'new \\1 "pw"'

    expect(File.read(conf)).to eq "# WLAN\nwifi_ssid: Photobox\nadmin_password: \"new \\\\1 \\\"pw\\\"\"\n"
    expect(YAML.safe_load_file(conf)['admin_password']).to eq 'new \\1 "pw"'
    expect(PhotoboxConfig.admin_password?('new \\1 "pw"')).to be true
  end

end
