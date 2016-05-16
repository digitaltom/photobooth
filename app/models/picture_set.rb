class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'.freeze
  POLAROID_SUFFIX = '_polaroid.png'.freeze
  ANIMATION_SUFFIX = '_animation.gif'.freeze
  PICTURE_PATH = File.join(Rails.root, 'public', 'picture_sets')

  class << self

    def all
      dirs = Dir.glob(File.join(PICTURE_PATH, "*/*#{ANIMATION_SUFFIX}"))
                .map { |f| f.gsub(PICTURE_PATH + '/', '').gsub(/\/[0-9\-_]*#{ANIMATION_SUFFIX}/, '') }
      dirs.sort.reverse.map { |dir| find dir }
    end

    def find(date)
      { path: "picture_sets/#{date}", date: date, animation: "#{date}#{ANIMATION_SUFFIX}",
        pictures: (1..4).map { |i| { polaroid: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } } }
    end

    def create
      date = Time.now.getlocal.strftime(DATE_FORMAT)
      dir = "#{PICTURE_PATH}/#{date}"
      angle = -7 + Random.rand(14) + 360
      Syscall.execute("mkdir #{date}", dir: PICTURE_PATH)
      jobs = (1..4).collect { |i| capture_job(i, date, dir, angle, OPTS.image_caption) }
      (1..4).each { |i| GpioPort.off(GpioPort::GPIO_PORTS["PICTURE#{i}"]) }
      GpioPort.on(GpioPort::GPIO_PORTS['PROCESSING'])
      # wait until convert jobs are finished
      until !jobs.any?(&:status) do end
      # Merge all polaroid previews to an animated gif
      Syscall.execute("time convert -delay 60 #{date}_*#{POLAROID_SUFFIX} #{date}#{ANIMATION_SUFFIX}", dir: dir)
      GpioPort.off(GpioPort::GPIO_PORTS['PROCESSING'])
      find date
    end

    def destroy(date)
      Syscall.execute("rm -r #{date}", dir: PICTURE_PATH)
    end

    private

    def capture_job(i, date, dir, angle, caption = nil)
      GpioPort.on(GpioPort::GPIO_PORTS["PICTURE#{i}"])
      caption ||= date
      Syscall.execute("gphoto2 --capture-image-and-download --filename #{date}_#{i}.jpg", dir: dir)
      t = Thread.new do
        Syscall.execute("time convert -caption '#{caption}' #{date}_#{i}.jpg -sample 380 -bordercolor Snow " \
        "-density 100 -gravity center -pointsize 9 -polaroid -#{angle} #{date}_#{i}#{POLAROID_SUFFIX}", dir: dir)
      end
      t.abort_on_exception = true
      t
    end

  end

end
