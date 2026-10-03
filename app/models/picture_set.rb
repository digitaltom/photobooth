# frozen_string_literal: true

# A picture set is a folder with 4 photos, their polaroids, the animated GIF and set.json.
# The gallery reads the filesystem, there is no database.
class PictureSet

  DATE_FORMAT = '%Y-%m-%d_%H-%M-%S'
  POLAROID_SUFFIX = '_polaroid.png'
  ANIMATION_SUFFIX = '_animation.gif'
  FRAME_SUFFIX = '_frame.gif'
  IMAGEMAGICK = system('command -v magick > /dev/null') ? 'magick' : 'convert'
  # The 4 polaroids already render in parallel on the 4 cores of the Pi 3, so one thread each.
  # Over the memory limit ImageMagick swaps pixels to a temp file: slower, but no out-of-memory on 1 GB RAM.
  MAGICK_ENV = "env MAGICK_THREAD_LIMIT=1 MAGICK_MEMORY_LIMIT=#{OPTS.imagemagick_memory_limit} " \
               "MAGICK_MAP_LIMIT=#{OPTS.imagemagick_map_limit}".freeze

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

    # ImageMagick runs in the set folder, so a font file in the repo needs an absolute path
    def font
      path = Rails.root.join(OPTS.font)
      path.file? ? path.to_s : OPTS.font
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

  # the folder name is the capture time
  def taken_at
    Time.strptime(date, DATE_FORMAT)
  end

  def to_param
    date
  end

  # names that may be served to guests
  def files
    pictures.flat_map(&:values) << animation
  end

  # Writes the polaroid PNG and its GIF frame for the animation.
  def convert_to_polaroid(num, angle)
    caption = OPTS.image_caption || date
    # jpeg:size makes libjpeg decode the photo at the smallest 1/2, 1/4 or 1/8 scale that is still >= 600x400,
    # for example 6000x4000 at 1/8 (750x500). -define and -caption are read settings: both must stand before the input file.
    # png:compression-level=1: 40 % less CPU, 18 % larger files.
    # The GIF frame gets its 256 colors here, while the camera takes the next photo, not after the last photo.
    Syscall.execute("#{MAGICK_ENV} #{IMAGEMAGICK} -define jpeg:size=600x400 -caption '#{caption}' #{date}_#{num}.jpg " \
                    "-font '#{PictureSet.font}' " \
                    '-scale 600 ' \
                    '-bordercolor Snow ' \
                    '-density 100 ' \
                    '-gravity center ' \
                    "-pointsize #{OPTS.image_fontsize} " \
                    "-polaroid -#{angle} " \
                    '-trim +repage ' \
                    '-define png:compression-level=1 -define png:compression-filter=0 ' \
                    "+write #{date}_#{num}#{POLAROID_SUFFIX} " \
                    "#{date}_#{num}#{FRAME_SUFFIX}", dir: dir, timing: true)
  end

  # Merge all polaroid previews to an animated gif
  def create_animation(overwrite: false)
    if !overwrite && File.exist?(File.join(dir, animation))
      Rails.logger.info "Skipping for existing animation #{dir}"
    else
      Rails.logger.info "Creating animation for #{dir}"
      frames = (1..4).map { |i| File.join(dir, "#{date}_#{i}#{FRAME_SUFFIX}") }
      # older sets have no frames: then ImageMagick reduces the colors of the polaroids here
      suffix = frames.all? { |f| File.exist?(f) } ? FRAME_SUFFIX : POLAROID_SUFFIX
      Syscall.execute("#{MAGICK_ENV} #{IMAGEMAGICK} -delay 60 #{date}_[1-4]#{suffix} #{animation}", dir: dir, timing: true)
      FileUtils.rm_f(frames)
    end
  end

  def write_json(caption: OPTS.image_caption)
    File.write(File.join(dir, 'set.json'), JSON.pretty_generate(created_at: Time.now.getlocal.iso8601, caption: caption))
  end

end
