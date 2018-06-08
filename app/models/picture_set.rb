class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'.freeze
  POLAROID_SUFFIX = '_polaroid.png'.freeze
  ANIMATION_SUFFIX = '_animation.gif'.freeze
  COMBINED_SUFFIX = '_combined.jpg'.freeze
  PICTURE_PATH = Rails.root.join('public', 'picture_sets').to_s

  class << self

    def all
      dirs = Dir.glob(File.join(PICTURE_PATH, "*/*#{ANIMATION_SUFFIX}")).map do |animation|
        File.basename(File.dirname(animation))
      end
      dirs.sort.reverse.map { |dir| new(dir) }
    end

    def find(date)
      all_sets = PictureSet.all
      ps = all_sets.detect { |set| set[:date] == date }
      raise 'PictureSet not found' unless ps
      ps[:next] = all_sets[all_sets.index(ps) - 1] if all_sets.index(ps) > 0
      ps[:last] = all_sets[all_sets.index(ps) + 1] if all_sets.index(ps) < all_sets.size
      ps
    end

    def new(date)
      { path: "picture_sets/#{date}", date: date,
        animation: "#{date}#{ANIMATION_SUFFIX}", combined: "#{date}#{COMBINED_SUFFIX}",
        pictures: (1..4).map { |i| { polaroid: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } } }
    end

    def create
      date = Time.now.getlocal.strftime(DATE_FORMAT)
      dir = "#{PICTURE_PATH}/#{date}"
      angle = Random.rand(353..366)
      Syscall.execute("mkdir #{date}", dir: PICTURE_PATH)
      jobs = (1..4).collect { |i| capture_job(i, date, dir, angle) }
      GpioPort.on(GpioPort::GPIO_PORTS['PROCESSING'])
      # wait until convert jobs are finished
      until jobs.none?(&:status) do end
      # Merge all polaroid previews to an animated gif
      Syscall.execute("time convert -delay 60 #{date}_*#{POLAROID_SUFFIX} #{date}#{ANIMATION_SUFFIX}", dir: dir)
      # Merge all images in one combined image
      combine_images(date, dir)
      (1..4).each { |i| GpioPort.off(GpioPort::GPIO_PORTS["PICTURE#{i}"]) }
      GpioPort.off(GpioPort::GPIO_PORTS['PROCESSING'])
      new(date)
    end

    def destroy(date)
      Syscall.execute("rm -r #{date}", dir: PICTURE_PATH)
    end

    private

    def combine_images(date, dir)
      Thread.new do
        Syscall.execute("time montage -geometry '25%x25%+25+25<' -background '#{OPTS.background_color}' " \
          "-title '#{OPTS.image_caption}' -font '#{OPTS.image_font}' -fill '#{OPTS.font_color}' " \
          "-pointsize #{OPTS.combined_image_fontsize} -gravity 'Center' #{date}_*.jpg #{date}#{COMBINED_SUFFIX}",
                        dir: dir)
      end
    end

    def capture_job(num, date, dir, angle)
      GpioPort.on(GpioPort::GPIO_PORTS["PICTURE#{num}"])
      begin
        retries ||= 0
        Syscall.execute("gphoto2 --capture-image-and-download --filename #{date}_#{num}.jpg", dir: dir)
        raise 'Image capture failed' unless File.exist?(File.join(dir, "#{date}_#{num}.jpg"))
      rescue StandardError => e
        # rubocop:disable GuardClause
        if (retries += 1) < 3
          Rails.logger.warn("Retrying image ##{num} capture...")
          retry
        else
          raise e
        end
        # rubocop:enable GuardClause
      end
      convert_thread(num, date, dir, angle)
    end

    def convert_thread(num, date, dir, angle)
      caption = OPTS.image_caption || date
      t = Thread.new do
        Syscall.execute("time convert -caption '#{caption}' #{date}_#{num}.jpg -sample 600 -bordercolor Snow " \
        "-density 100 -gravity center -pointsize #{OPTS.image_fontsize} " \
        "-polaroid -#{angle} #{date}_#{num}#{POLAROID_SUFFIX}", dir: dir)
      end
      t.abort_on_exception = true
      t
    end
  end

end
