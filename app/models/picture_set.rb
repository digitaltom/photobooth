# frozen_string_literal: true

class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'
  ANIMATION_SUFFIX = '_animation.gif'
  COMBINED_SUFFIX = '_combined.jpg'
  PICTURE_PATH = Rails.root.join('public', 'picture_sets').to_s

  attr_accessor :date, :dir, :animation, :combined, :pictures, :next, :last

  class << self

    def all
      dirs = Dir.glob(File.join(PICTURE_PATH, "*/*#{ANIMATION_SUFFIX}")).map do |animation|
        File.basename(File.dirname(animation))
      end
      Rails.logger.warn "No picture sets found at: #{PICTURE_PATH}" if dirs.empty?
      dirs.sort.reverse.map { |dir| new(date: dir) }
    end

    def find(date)
      all_sets = PictureSet.all
      ps = all_sets.detect { |set| set.date == date }
      raise 'PictureSet not found' unless ps
      ps.next = all_sets[all_sets.index(ps) - 1] if all_sets.index(ps).positive?
      ps.last = all_sets[all_sets.index(ps) + 1] if all_sets.index(ps) < all_sets.size
      ps
    end

    def create(date: Time.now.getlocal.strftime(DATE_FORMAT))
      picture_set = PictureSet.new(date: date)
      FileUtils.mkdir(picture_set.dir)
      angle = Random.rand(353..366)
      jobs = (1..4).collect { |i| capture_job(i, picture_set, angle) }
      GpioPort.on(GpioPort::GPIO_PORTS['PROCESSING'])
      # wait until convert jobs are finished
      until jobs.none?(&:status) do end
      picture_set.create_animation
      background_thread { picture_set.combine_images(overwrite: true) } if OPTS.render_collage
      (1..4).each { |i| GpioPort.off(GpioPort::GPIO_PORTS["PICTURE#{i}"]) }
      GpioPort.off(GpioPort::GPIO_PORTS['PROCESSING'])
      picture_set
    end

    private

    def capture_job(num, picture_set, angle)
      GpioPort.on(GpioPort::GPIO_PORTS["PICTURE#{num}"])
      begin
        retries ||= 0
        Syscall.execute('gphoto2 --capture-image-and-download --no-keep' \
                                "--filename #{picture_set.date}_#{num}.jpg", dir: picture_set.dir)
        raise 'Image capture failed' unless File.exist?(File.join(picture_set.dir, "#{picture_set.date}_#{num}.jpg"))
      rescue StandardError => e
        Rails.logger.warn("Retrying image ##{num} capture (#{retries})...") && retry if (retries += 1) < 3
        raise e
      end
      background_thread { picture_set.convert_to_polaroid(num, angle) }
    end

    def background_thread
      t = Thread.new { yield }
      t.abort_on_exception = true
      t
    end

  end

  def initialize(date: nil)
    @date = date
    @path = "picture_sets/#{date}"
    @dir = "#{PICTURE_PATH}/#{date}"
    @animation = "#{date}#{ANIMATION_SUFFIX}"
    @combined = "#{date}#{COMBINED_SUFFIX}"
    @pictures = (1..4).map { |i| { polaroid: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } }
  end

  def destroy
    FileUtils.rm_r dir
  end

  def convert_to_polaroid(num, angle)
    caption = OPTS.image_caption || date
    Syscall.execute("convert -caption '#{caption}' #{date}_#{num}.jpg " \
                            '-scale 600 ' \
                            '-bordercolor Snow ' \
                            '-density 100 ' \
                            '-gravity center ' \
                            "-pointsize #{OPTS.image_fontsize} " \
                            "-polaroid -#{angle} " \
                            '-trim +repage ' \
                            "#{date}_#{num}#{POLAROID_SUFFIX}", dir: dir, timing: true)
  end

  # Merge all polaroid previews to an animated gif
  def create_animation(overwrite: false)
    if !overwrite && File.exist?(File.join(dir, animation))
      Rails.logger.info "Skipping for existing animation #{dir}"
    else
      Rails.logger.info "Creating animation for #{dir}"
      Syscall.execute("convert -delay 60 #{date}_[1-4]#{POLAROID_SUFFIX} #{animation}", dir: dir, timing: true)
    end
  end

  # Create collage of all images
  def combine_images(overwrite: false)
    if !overwrite && File.exist?(File.join(dir, combined))
      Rails.logger.info "Skipping for collage creation for #{dir}"
    else
      Rails.logger.info "Creating collage for #{dir}"
      Syscall.execute("montage -geometry '25%x25%+25+25<' " \
                              "-background '#{OPTS.background_color}' " \
                              "-title '#{OPTS.image_caption}' " \
                              "-font '#{OPTS.font}' " \
                              "-fill '#{OPTS.font_color}' " \
                              "-pointsize #{OPTS.combined_image_fontsize} " \
                              "-gravity 'Center' #{date}_[1-4].jpg " \
                              "#{date}#{COMBINED_SUFFIX}", dir: dir, timing: true)
    end
  end

end
