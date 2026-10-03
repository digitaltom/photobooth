# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sets', type: :request do
  include ActiveJob::TestHelper

  let(:id) { '2099-01-01_01-48-33' }

  it 'starts the capture job' do
    expect { post '/picture_sets', as: :turbo_stream }.to have_enqueued_job(CaptureJob)
    expect(response.media_type).to eq 'text/vnd.turbo-stream.html'
  end

  it 'serves files of a set' do
    get "/sets/#{id}/files/#{id}_animation.gif"
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq 'image/gif'
  end

  it 'does not serve other files' do
    get "/sets/#{id}/files/..%2F..%2Fsecret"
    expect(response).to have_http_status(:not_found)
  end

  it 'redirects captive portal checks to the gallery' do
    get '/generate_204', headers: { 'Host' => 'connectivitycheck.gstatic.com' }
    expect(response).to redirect_to('http://connectivitycheck.gstatic.com/')
  end

  it 'returns 404 for unknown sets' do
    get '/sets/2018-04-10_11-22-3'
    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe 'Kiosk', type: :request do
  it 'shows the gallery below the button' do
    get '/?kiosk=1'
    expect(response.body).to include('2099-01-01_01-48-33_animation.gif')
    expect(response.body.scan('shoot_still_sw').size).to eq 4
  end

  it 'remembers the kiosk mode in a cookie until it is turned off' do
    get '/?kiosk=1'
    get '/'
    expect(response.body).to include('shoot_button')

    get '/?kiosk=0'
    expect(response.body).not_to include('shoot_button')
    get '/'
    expect(response.body).not_to include('shoot_button')
  end
end
