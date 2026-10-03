# frozen_string_literal: true

# Takes 4 photos, renders polaroids and the GIF, reports each step to the kiosk.
class CaptureJob < ApplicationJob
  # one camera: a second tap waits until this set is done
  limits_concurrency to: 1, key: 'camera'

  GPIO_LEDS = %w[PICTURE1 PICTURE2 PICTURE3 PICTURE4 PROCESSING].freeze

  def perform(id)
    picture_set = PictureSet.new(date: id)
    FileUtils.mkdir_p(picture_set.dir)
    started = now
    threads = capture(picture_set)
    captured = now
    threads.each(&:join)
    picture_set.create_animation
    picture_set.write_yml
    logger.info format('CaptureJob %<id>s: capture %<capture>.1fs, render %<render>.1fs',
                       id: id, capture: captured - started, render: now - captured)
    broadcast_kiosk('kiosk/done')
    Turbo::StreamsChannel.broadcast_refresh_to(:gallery)
  rescue StandardError => e
    broadcast_kiosk('kiosk/error', message: e.message)
    raise
  ensure
    GPIO_LEDS.each { |port| GpioPort.off(GpioPort::GPIO_PORTS[port]) }
  end

  private

  # returns the polaroid threads, they run while the camera takes the next photo
  def capture(picture_set)
    angle = Random.rand(353..366)
    threads = []
    step(1)
    Camera.capture(picture_set.dir, picture_set.date) do |num|
      threads << Thread.new { picture_set.convert_to_polaroid(num, angle) }
      step(num + 1)
    end
    threads
  end

  # step 1..4: the camera takes photo n, step 5: processing
  def step(num)
    if num <= 4
      GpioPort.on(GpioPort::GPIO_PORTS["PICTURE#{num}"])
      broadcast_kiosk('kiosk/status', step: num)
    else
      GpioPort.on(GpioPort::GPIO_PORTS['PROCESSING'])
      broadcast_kiosk('kiosk/status', step: :processing)
    end
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def broadcast_kiosk(partial, **locals)
    Turbo::StreamsChannel.broadcast_update_to(:kiosk, target: 'kiosk-status', partial: partial, locals: locals)
  end
end
