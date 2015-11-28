class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'
  ANIMATION_SUFFIX = '_animation.gif'
  PICTURE_PATH = File.join(Rails.root, 'public', 'pictures')


  def self.all
    dirs = Dir.glob(File.join(PICTURE_PATH, '*')).map{|f| f.gsub(PICTURE_PATH + '/', '')}
    dirs.sort.reverse.map{|dir| self.find dir}
  end

  def self.find date
    { path: "pictures/#{date}", date: date, animation: "#{date}#{ANIMATION_SUFFIX}",
      pictures: (1..4).map{|i| { preview: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } }
    }
  end

  def self.create
    date = Time.new.strftime(DATE_FORMAT)
    angle = -15 + Random.rand(30)
    caption = date
    Syscall.execute("mkdir #{date}", dir: PICTURE_PATH)
    (1..4).each do |i|
      Syscall.execute("gphoto2 --capture-image-and-download --filename #{date}_#{i}.jpg", dir: "#{PICTURE_PATH}/#{date}")
      Syscall.execute("convert -caption '#{caption}' #{date}_#{i}.jpg -thumbnail 640x480 -bordercolor Snow -border 5x5 -density 200 -gravity center -pointsize 14 -background black -polaroid -#{angle} -resize 50% #{date}_#{i}#{POLAROID_SUFFIX}", dir: "#{PICTURE_PATH}/#{date}")
    end
    Syscall.execute("convert -delay 70 #{date}_1#{POLAROID_SUFFIX} #{date}_2#{POLAROID_SUFFIX} #{date}_3#{POLAROID_SUFFIX} #{date}_4#{POLAROID_SUFFIX} #{date}_animation.gif", dir: "#{PICTURE_PATH}/#{date}")
    self.find date
  end

end
