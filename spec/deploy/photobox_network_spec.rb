# frozen_string_literal: true

require 'open3'
require 'tmpdir'

describe 'deploy/image/photobox-network' do
  let(:script) { File.expand_path('../../deploy/image/photobox-network', __dir__) }

  def run_with(yaml)
    Dir.mktmpdir do |dir|
      conf = File.join(dir, 'photobox.yml')
      File.write(conf, yaml) if yaml
      out, status = Open3.capture2e({ 'RUN' => 'echo', 'PHOTOBOX_CONF' => conf, 'ROOT_HOME' => dir }, script)
      expect(status).to be_success, out
      key_file = File.join(dir, '.ssh/authorized_keys')
      [out, File.exist?(key_file) ? File.read(key_file) : nil]
    end
  end

  it 'starts the hotspot with the default photobox.yml' do
    out, = run_with(File.read(File.expand_path('../../deploy/image/photobox.yml', __dir__)))
    expect(out).to include('nmcli con add type wifi ifname wlan0 con-name photobox autoconnect yes ssid Photobox mode ap')
    expect(out).not_to include('wifi-sec')
    expect(out).to include('nmcli radio wifi on')
    expect(out).to include('iw reg set DE')
  end

  it 'uses the defaults without photobox.yml' do
    out, = run_with(nil)
    expect(out).to include('ssid Photobox')
    expect(out).not_to include('wifi-sec')
  end

  it 'uses quoted values, comments and the ssh key' do
    out, key = run_with(<<~YAML)
      wifi_ssid: "Party #1"
      wifi_password: geheim123 # comment
      ssh_authorized_key: "ssh-ed25519 AAAA me@laptop"
    YAML
    expect(out).to include('ssid Party #1').and include('wifi-sec.psk geheim123 ')
    expect(key).to eq("ssh-ed25519 AAAA me@laptop\n")
  end

  it 'opens the WLAN with an empty password' do
    out, = run_with("wifi_password:\n")
    expect(out).to include('ipv4.method shared')
    expect(out).not_to include('wifi-sec')
  end
end
