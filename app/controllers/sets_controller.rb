# frozen_string_literal: true

class SetsController < ApplicationController
  before_action :set_picture_set, only: %i[show slideshow file]

  def index
    @gallery = Gallery.active
    @picture_sets = PictureSet.all
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
    CaptureJob.perform_later(PictureSet.next_id)
    render turbo_stream: ''
  end

  # sets live outside public/ (USB stick), so only the known file names are served
  def file
    name = params.expect(:name)
    raise ActionController::RoutingError, 'File not found' unless @picture_set.files.include?(name)

    send_file File.join(@picture_set.dir, name), disposition: params[:download] ? 'attachment' : 'inline'
  end

  private

  def set_picture_set
    @picture_set = PictureSet.find(params.expect(:id))
  end
end
