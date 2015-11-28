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
    { path: "pictures/#{date}", date: date, animation: "#{date}_animation.gif",
      pictures: [
        { preview: "#{date}_1#{POLAROID_SUFFIX}", full: "#{date}_1.jpg" },
        { preview: "#{date}_2#{POLAROID_SUFFIX}", full: "#{date}_2.jpg" },
        { preview: "#{date}_3#{POLAROID_SUFFIX}", full: "#{date}_3.jpg" },
        { preview: "#{date}_4#{POLAROID_SUFFIX}", full: "#{date}_4.jpg" }
      ]
    }
  end

  def self.create
    date = Time.new.strftime(DATE_FORMAT)
    angle = -15 + Random.rand(30)
    caption = date

    `cd #{PICTURE_PATH}; mkdir #{date}`
    (1..4).each do |i|
      `cd #{PICTURE_PATH}/#{date}; gphoto2 --capture-image-and-download --filename #{date}_#{i}.jpg`
      `cd #{PICTURE_PATH}/#{date}; convert -caption '#{caption}' #{date}_#{i}.jpg -thumbnail 640x480 -bordercolor Snow -border 5x5 -density 200 -gravity center -pointsize 14 -background black -polaroid -#{angle} -resize 50% #{date}_#{i}#{POLAROID_SUFFIX}`
    end

    `cd #{PICTURE_PATH}/#{date}; convert -delay 70 #{date}_1#{POLAROID_SUFFIX} #{date}_2#{POLAROID_SUFFIX} #{date}_3#{POLAROID_SUFFIX} #{date}_4#{POLAROID_SUFFIX} #{date}_animation.gif`

    self.find date
  end

end
