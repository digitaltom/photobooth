# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin', type: :request do

  around do |example|
    saved = OPTS.dup
    Dir.mktmpdir do |dir|
      old = ENV.fetch('PHOTOBOX_STORAGE', nil)
      ENV['PHOTOBOX_STORAGE'] = dir
      OPTS.photobox_conf = File.join(dir, 'photobox.yml')
      example.run
    ensure
      ENV['PHOTOBOX_STORAGE'] = old
      OPTS.replace(saved)
    end
  end

  before do
    OPTS.wifi_ssid = 'Party;Box'
    OPTS.wifi_password = 'secret123'
    PhotoboxConfig.admin_password = 'admin-password'
    allow(Network).to receive(:devices).and_return([])
  end

  def login(password = 'admin-password')
    post '/admin/login', params: { password: password }
  end

  it 'asks for the password' do
    get '/admin'
    expect(response).to redirect_to('/admin/login')
  end

  it 'refuses a wrong password' do
    login('wrong')
    follow_redirect!
    expect(response.body).to include('Wrong password')
    get '/admin'
    expect(response).to redirect_to('/admin/login')
  end

  it 'shows the admin menu after login and ends the session after 30 minutes' do
    login
    get '/admin'
    expect(response.body).to include('Logout', 'Start new gallery', 'Restart')

    travel 31.minutes do
      get '/admin'
      expect(response).to redirect_to('/admin/login')
    end
  end

  it 'logs out' do
    login
    delete '/admin/logout'
    expect(response).to redirect_to('/')
    get '/admin'
    expect(response).to redirect_to('/admin/login')
  end

  it 'accepts the default password from options.yml' do
    OPTS.admin_password = 'photobox'
    login('photobox')
    expect(response).to redirect_to('/admin')
  end

  it 'changes the password' do
    login
    patch '/admin/password', params: { old_password: 'admin-password', new_password: 'new-password', password_repeat: 'other' }
    expect(flash[:alert]).to eq 'The passwords do not match'

    patch '/admin/password', params: { old_password: 'admin-password', new_password: 'new-password', password_repeat: 'new-password' }
    expect(flash[:notice]).to eq 'Password changed'
    expect(PhotoboxConfig.admin_password?('new-password')).to be true
  end

  it 'shows the camera and sets the image format' do
    login
    get '/admin'
    expect(response.body).to include('Fake camera', 'Keep the setting of the camera')
    expect(response.body).not_to include('cL: large')

    allow(Camera).to receive(:info).and_return(summary: 'Canon EOS 2000D', imageformats: %w[cL])
    get '/admin'
    expect(response.body).to include('cL: large, 6000x4000, normal')

    patch '/admin/imageformat', params: { imageformat: ' cL ' }
    expect(flash[:notice]).to eq 'Image format: cL'
    expect(File.read(OPTS.photobox_conf)).to include('camera_imageformat: "cL"')
  end

  it 'starts and switches galleries' do
    login
    first = Gallery.active
    post '/admin/galleries', params: { caption: 'Freya wird 50' }
    expect(Gallery.active.caption).to eq 'Freya wird 50'

    patch "/admin/galleries/#{first.name}/activate"
    expect(Gallery.active).to eq first
  end

  it 'renames a gallery' do
    login
    patch "/admin/galleries/#{Gallery.active.name}/caption", params: { caption: 'Hochzeit' }
    expect(Gallery.active.caption).to eq 'Hochzeit'
  end

  it 'lists the connected devices' do
    allow(Network).to receive(:devices).and_call_original
    allow(Syscall).to receive(:execute).and_call_original
    allow(Syscall).to receive(:execute).with('ip neigh show dev wlan0')
                                       .and_return("10.42.0.23 lladdr aa:bb:cc:dd:ee:ff REACHABLE\n10.42.0.9 FAILED\n")
    login
    get '/admin'
    expect(response.body).to include('10.42.0.23', 'aa:bb:cc:dd:ee:ff').and(exclude('10.42.0.9'))
  end

  it 'sets the time' do
    login
    expect(Syscall).to receive(:execute).with('timedatectl set-ntp false')
    expect(Syscall).to receive(:execute).with("timedatectl set-time '2026-10-04 18:30:05'")
    patch '/admin/time', params: { time: '2026-10-04T18:30:05' }
    expect(response).to redirect_to('/admin')
  end

  it 'restarts' do
    login
    expect(Syscall).to receive(:execute).with('systemctl reboot')
    post '/admin/restart'
    expect(response).to redirect_to('/admin')
  end

  it 'shows the WLAN sign with a QR code' do
    login
    get '/admin/wifi_sign'
    expect(response.body).to include('<svg', 'Party;Box', 'secret123')
  end

  it 'links the admin menu in the gallery footer' do
    get '/'
    expect(response.body).to include('href="/admin"')
  end

end
