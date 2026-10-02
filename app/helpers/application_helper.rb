# frozen_string_literal: true

module ApplicationHelper
  # QR code with the IP, not photobox.local: mDNS is unreliable on Android
  def qr_svg(picture_set)
    RQRCode::QRCode.new("#{OPTS.public_url}#{set_path(picture_set)}").as_svg(viewbox: true, use_path: true).html_safe # rubocop:disable Rails/OutputSafety
  end
end
