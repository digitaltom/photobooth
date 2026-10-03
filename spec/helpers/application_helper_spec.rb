# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do

  it 'escapes special characters in the WLAN QR code' do
    allow(OPTS).to receive_messages(wifi_ssid: 'My;Box', wifi_password: 'a\\b:c')
    expect(RQRCode::QRCode).to receive(:new).with('WIFI:T:WPA;S:My\;Box;P:a\\\\b\\:c;;').and_call_original
    expect(helper.wifi_qr_svg).to include('<svg')
  end

  it 'makes an open WLAN without a password' do
    allow(OPTS).to receive_messages(wifi_ssid: nil, wifi_password: '')
    expect(RQRCode::QRCode).to receive(:new).with('WIFI:T:nopass;S:Photobox;;').and_call_original
    helper.wifi_qr_svg
  end

end
