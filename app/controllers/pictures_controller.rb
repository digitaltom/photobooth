class PicturesController < ApplicationController

  protect_from_forgery with: :exception

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'


  def index
    #Time.strptime(date, DATE_FORMAT)
    @images = Dir.entries(File.join(Rails.root, 'public', 'pictures'))
                .select {|f| !File.directory?( f ) && f.include?( 'polaroid' )}.sort.reverse
                .map{|f| {name: f, date: f.gsub(POLAROID_SUFFIX, ''), path: "pictures/#{f}"} }

    render json: @images.to_json
  end


  def create
    date = Time.new.strftime(DATE_FORMAT)
    polaroid_file = "#{date}#{POLAROID_SUFFIX}"
    dir = File.join(Rails.root, 'public', 'pictures')
    angle = -15 + Random.rand(30)
    `cd #{dir}; gphoto2 --capture-image-and-download --filename #{date}.jpg`
    `cd #{dir}; convert -caption 'Cassio + Chiara, June 2016' #{date}.jpg -thumbnail 640x480 -bordercolor Snow -border 5x5 -density 200 -gravity center -pointsize 14 -background black -polaroid -#{angle} -resize 50% #{date}#{POLAROID_SUFFIX}`
    `cd #{dir}; rm #{date}.jpg`

    image = {name: polaroid_file, date: date, path: "pictures/#{polaroid_file}"}

    render json: image
  end



end
