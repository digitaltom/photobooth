# frozen_string_literal: true

# Takes 4 photos, renders polaroids and the GIF, reports each step to the kiosk.
class CaptureJob < ApplicationJob
  GPIO_LEDS = %w[PICTURE1 PICTURE2 PICTURE3 PICTURE4 PROCESSING].freeze

  # locale: the kiosk status texts are in the language of the kiosk
  def perform(id, locale = I18n.default_locale)
    I18n.with_locale(locale) { capture_set(id) }
  end

  private

  def capture_set(id)
    picture_set = PictureSet.new(date: id)
    FileUtils.mkdir_p(picture_set.dir)
    started = now
    threads = []
    capture(picture_set, threads)
    captured = now
    threads.each(&:join)
    picture_set.create_animation
    picture_set.write_yml
    logger.info format('CaptureJob %<id>s: capture %<capture>.1fs, render %<render>.1fs',
                       id: id, capture: captured - started, render: now - captured)
    show(id)
  rescue StandardError => e
    broadcast_kiosk('kiosk/error', message: e.message)
    remove(picture_set, threads)
    raise
  ensure
    GPIO_LEDS.each { |port| GpioPort.off(port) }
  end

  # adds the polaroid threads, they run while the camera takes the next photo
  def capture(picture_set, threads)
    angle = Random.rand(353..366)
    @status = { step: 1, previews: {} }
    @status_lock = Mutex.new
    step(1)
    Camera.capture(picture_set.dir, picture_set.date) do |num|
      # the locale is per thread, the status texts are in the language of the kiosk
      threads << Thread.new(I18n.locale) do |locale|
        picture_set.convert_to_polaroid(num, angle)
        I18n.with_locale(locale) { polaroid_ready(picture_set, num) }
      end
      step(num + 1)
    end
  rescue StandardError => e
    raise if threads.empty?

    # 1-3 photos (for example the camera cannot focus for the next one) still make a set
    logger.warn "CaptureJob #{picture_set.date}: #{e.message}, keeping #{threads.size} photos"
  end

  # a failed capture (for example the camera cannot focus) leaves no half set in the gallery
  def remove(picture_set, threads)
    return unless picture_set

    threads&.each { |thread| thread.join rescue nil } # rubocop:disable Style/RescueModifier
    FileUtils.rm_rf(picture_set.dir)
  end

  # step 1..4: the camera takes photo n, step 5: processing
  def step(num)
    GpioPort.on(num <= 4 ? "PICTURE#{num}" : 'PROCESSING')
    update_status(step: num <= 4 ? num : :processing)
  end

  # the kiosk shows the polaroid of each photo as soon as its thread wrote it, no extra image for the preview
  def polaroid_ready(picture_set, num)
    url = Rails.application.routes.url_helpers.file_set_path(picture_set, name: "#{picture_set.date}_#{num}#{PictureSet::POLAROID_SUFFIX}")
    update_status { |status| status[:previews] = status[:previews].merge(num => url) }
  end

  # The camera steps and the polaroid threads change the status, the lock keeps their broadcasts in order
  def update_status(**changes)
    @status_lock.synchronize do
      @status = @status.merge(changes)
      yield @status if block_given?
      broadcast_kiosk('kiosk/status', **@status)
    end
  end

  # the kiosk shows the new set (visit: the Turbo stream action in application.js), the other browsers get it in the gallery
  def show(id)
    Turbo::StreamsChannel.broadcast_action_to(:kiosk, action: :visit,
                                                      attributes: { url: Rails.application.routes.url_helpers.set_path(id) })
    Turbo::StreamsChannel.broadcast_refresh_to(:gallery)
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def broadcast_kiosk(partial, **locals)
    Turbo::StreamsChannel.broadcast_update_to(:kiosk, target: 'kiosk-status', partial: partial, locals: locals)
  end
end
