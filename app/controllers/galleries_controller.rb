# frozen_string_literal: true

# Live: a gallery can hold gigabytes, so the archive streams to the guest while tar reads the sets
class GalleriesController < ApplicationController
  include ActionController::Live

  def download
    gallery = Gallery.find(params.expect(:id))
    response.headers['Content-Type'] = 'application/gzip'
    response.headers['Content-Disposition'] =
      ActionDispatch::Http::ContentDisposition.format(disposition: 'attachment', filename: "#{gallery.name}.tar.gz")
    # no temp file on the SD card. gzip -1: JPEGs and GIFs hardly shrink, the archive mostly bundles the files.
    stream(['tar', '--use-compress-program=gzip -1', '-cf', '-', '-C', PictureSet.root, gallery.name])
  rescue ActionController::Live::ClientDisconnected
    logger.info "Download of gallery #{params[:id]} cancelled"
  ensure
    response.stream.close
  end

  private

  def stream(command)
    IO.popen(command, 'rb') do |output|
      while (chunk = output.read(64.kilobytes))
        response.stream.write(chunk)
      end
    end
  end
end
