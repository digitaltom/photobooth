class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'
  ANIMATION_SUFFIX = '_animation.gif'
  PICTURE_PATH = File.join(Rails.root, 'public', 'picture_sets')

  def self.all
    dirs = Dir.glob(File.join(PICTURE_PATH, "*/*#{ANIMATION_SUFFIX}")).map { |f| f.gsub(PICTURE_PATH + '/', '').gsub(/\/[0-9\-_]*#{ANIMATION_SUFFIX}/, '') }
    dirs.sort.reverse.map { |dir| self.find dir }
  end

  def self.find date
    { path: "picture_sets/#{date}", date: date, animation: "#{date}#{ANIMATION_SUFFIX}",
      pictures: (1..4).map { |i| { polaroid: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } }
    }
  end

  def self.create
    date = Time.new.strftime(DATE_FORMAT)
    angle = -7 + Random.rand(14) + 360
    caption = date
    dir = "#{PICTURE_PATH}/#{date}"
    Syscall.execute("mkdir #{date}", dir: PICTURE_PATH)
    jobs = []
    (1..4).each do |i|
      Syscall.execute("gphoto2 --capture-image-and-download --filename #{date}_#{i}.jpg", dir: dir)
      t = Thread.new do
        Syscall.execute("time convert -caption '#{caption}' #{date}_#{i}.jpg -sample 380 -bordercolor Snow -density 100 -gravity center -pointsize 9 -polaroid -#{angle} #{date}_#{i}#{POLAROID_SUFFIX}", dir: dir)
      end
      t.abort_on_exception = true
      jobs << t
    end
    # wait until convert jobs are finished
    until !jobs.any?(&:status) do end
    Syscall.execute("time convert -delay 60 #{date}_1#{POLAROID_SUFFIX} #{date}_2#{POLAROID_SUFFIX} #{date}_3#{POLAROID_SUFFIX} #{date}_4#{POLAROID_SUFFIX} #{date}#{ANIMATION_SUFFIX}", dir: dir)
    self.find date
  end

  def self.destroy date
    Syscall.execute("rm -r #{date}", dir: PICTURE_PATH)
  end

end
