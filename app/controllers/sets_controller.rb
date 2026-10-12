# frozen_string_literal: true

class SetsController < ApplicationController
  before_action :set_picture_set, only: %i[show slideshow]

  def index
    @gallery = Gallery.active
    @picture_sets = PictureSet.all
    # the gallery refresh after each capture also gets here
    StreamDeck.update(@picture_sets) if kiosk?
  end

  def show; end

  # loops: after the newest set it starts again with the oldest, so new sets show up too
  def slideshow
    # PictureSet is no ActiveRecord model, it has no PictureSet.last
    @next = @picture_set.next || PictureSet.all.last # rubocop:disable Rails/RedundantActiveRecordAllMethod
  end

  # The job reports its progress to the kiosk through Turbo Stream broadcasts.
  # The response is empty: a status in it could arrive after the first broadcast and overwrite it.
  def create
    CaptureJob.perform_later(PictureSet.next_id, I18n.locale.to_s)
    render turbo_stream: ''
  end

  # Sets live outside public/ (USB stick), so only the known file names are served.
  # Also for a set without animation yet: the kiosk shows the polaroids during the capture (CaptureJob).
  def file
    picture_set = PictureSet.new(date: params.expect(:id))
    name = params.expect(:name)
    path = File.join(picture_set.dir, name)
    raise ActionController::RoutingError, 'File not found' unless picture_set.files.include?(name) && File.file?(path)

    send_file path, disposition: params[:download] ? 'attachment' : 'inline'
  end

  private

  def set_picture_set
    @picture_set = PictureSet.find(params.expect(:id))
  end
end
