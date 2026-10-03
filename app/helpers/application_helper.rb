# frozen_string_literal: true

module ApplicationHelper
  # the hotspot address, in QR codes and on signs: mDNS (photobox.local) is unreliable on Android
  PHOTOBOX_URL = 'http://10.42.0.1'

  def wifi_ssid
    OPTS.wifi_ssid.to_s.presence || 'Photobox'
  end

  # nil: open WLAN
  def wifi_password
    OPTS.wifi_password.to_s.presence
  end

  # Phones join the WLAN when they scan it.
  # https://github.com/zxing/zxing/wiki/Barcode-Contents#wi-fi-network-config-android-ios-11
  def wifi_qr_svg
    escape = ->(text) { text.gsub(/([\\;,:"])/, '\\\\\1') }
    content = "WIFI:T:#{wifi_password ? 'WPA' : 'nopass'};S:#{escape.call(wifi_ssid)};"
    content += "P:#{escape.call(wifi_password)};" if wifi_password
    # rqrcode builds the SVG from the QR modules only, no user text in it
    RQRCode::QRCode.new("#{content};").as_svg(viewbox: true, use_path: true).html_safe # rubocop:disable Rails/OutputSafety
  end
end
