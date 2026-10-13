# frozen_string_literal: true

class SetsController < ApplicationController
  before_action :set_picture_set, only: %i[show slideshow destroy]

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

  # The countdown on the kiosk, the Stream Deck shows it on its camera key.
  # delay: milliseconds, 0: the kiosk closed its dialog, that also stops a running capture job.
  def countdown
    return head :forbidden unless kiosk?

    seconds = params[:delay].to_f.clamp(0, 10_000) / 1000
    StreamDeck.countdown(seconds)
    CaptureJob.cancel if seconds.zero?
    head :no_content
  end

  # The kiosk only: the guests on their phones see no delete button.
  # ponytail: the kiosk is a cookie (?kiosk=1), anyone on the WLAN can set it, add the admin login when that matters
  def destroy
    return head :forbidden unless kiosk?

    FileUtils.rm_rf(@picture_set.dir)
    redirect_to root_path, notice: _('Picture deleted'), status: :see_other
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
