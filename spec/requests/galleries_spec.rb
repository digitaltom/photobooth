# frozen_string_literal: true

require 'rails_helper'
require 'rubygems/package'

RSpec.describe 'Galleries', type: :request do

  let(:gallery) { Gallery.active }

  it 'streams all sets of the gallery as .tar.gz' do
    get "/galleries/#{gallery.name}/download"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq 'application/gzip'
    expect(response.headers['Content-Disposition']).to include("#{gallery.name}.tar.gz")
    names = Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(response.body))).map(&:full_name)
    expect(names).to include("#{gallery.name}/2099-01-01_01-48-33/2099-01-01_01-48-33_animation.gif",
                             "#{gallery.name}/event.yml")
  end

  it 'returns 404 for unknown galleries' do
    get '/galleries/unknown/download'
    expect(response).to have_http_status(:not_found)
  end

  it 'shows the WLAN QR code in a popover in the gallery footer' do
    get '/'
    expect(response.body).to include('popovertarget="wifi-qr-popover"', 'popover="auto"', '<svg', 'href="http://10.42.0.1"')
  end

  it 'serves the web manifest for the kiosk on the home screen' do
    get '/'
    expect(response.body).to include('rel="manifest"', 'name="apple-mobile-web-app-capable"')

    get '/manifest.json'
    expect(response.parsed_body).to include('display' => 'standalone', 'start_url' => '/?kiosk=1')
  end

  it 'links the download in the gallery footer' do
    get '/'
    expect(response.body).to include("href=\"/galleries/#{gallery.name}/download\"")
  end

end
