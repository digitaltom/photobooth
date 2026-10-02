# frozen_string_literal: true

# A picture set is a folder with 4 photos, their polaroids, the animated GIF and set.json.
# The gallery reads the filesystem, there is no database.
class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'
  ANIMATION_SUFFIX = '_animation.gif'
  IMAGEMAGICK = system('command -v magick > /dev/null') ? 'magick' : 'convert'

  attr_accessor :date, :dir, :animation, :pictures, :next, :last

  class << self

    # the admin menu will later point this to the USB stick
    def root
      ENV['PHOTOBOX_STORAGE'].presence || OPTS.storage_path.presence || Rails.root.join('storage/sets').to_s
    end

    def all
      dirs = Dir.glob(File.join(root, "*/*#{ANIMATION_SUFFIX}")).map do |animation|
        File.basename(File.dirname(animation))
      end
      Rails.logger.warn "No picture sets found at: #{root}" if dirs.empty?
      dirs.sort.reverse.map { |dir| new(date: dir) }
    end

    def find(date)
      all_sets = PictureSet.all
      ps = all_sets.detect { |set| set.date == date }
      raise ActionController::RoutingError, 'PictureSet not found' unless ps

      index = all_sets.index(ps)
      ps.next = all_sets[index - 1] if index.positive?
      ps.last = all_sets[index + 1]
      ps
    end

    def next_id
      Time.now.getlocal.strftime(DATE_FORMAT)
    end

  end

  def initialize(date: nil)
    @date = date
    @dir = File.join(PictureSet.root, date)
    @animation = "#{date}#{ANIMATION_SUFFIX}"
    @pictures = (1..4).map { |i| { polaroid: "#{date}_#{i}#{POLAROID_SUFFIX}", full: "#{date}_#{i}.jpg" } }
  end

  def to_param
    date
  end

  # names that may be served to guests
  def files
    pictures.flat_map(&:values) << animation
  end

  def convert_to_polaroid(num, angle)
    caption = OPTS.image_caption || date
    # jpeg:size lets ImageMagick decode the 24 MP photo at a reduced size, which keeps the Pi 3 fast
    Syscall.execute("#{IMAGEMAGICK} -define jpeg:size=1200x1200 #{date}_#{num}.jpg " \
                    "-caption '#{caption}' " \
                    "-font '#{OPTS.font}' " \
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
      Syscall.execute("#{IMAGEMAGICK} -delay 60 #{date}_[1-4]#{POLAROID_SUFFIX} #{animation}", dir: dir, timing: true)
    end
  end

  def write_json(caption: OPTS.image_caption)
    File.write(File.join(dir, 'set.json'), JSON.pretty_generate(created_at: Time.now.getlocal.iso8601, caption: caption))
  end

end
