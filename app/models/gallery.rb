# frozen_string_literal: true

# A gallery is a folder in PictureSet.root with the picture sets of one event and its event.yml (caption, created_at).
# The file 'active' in PictureSet.root names the gallery that gets new sets and that guests see.
class Gallery

  attr_reader :name, :dir

  class << self

    def all
      Dir.glob(File.join(PictureSet.root, '*/event.yml')).map { |file| new(File.basename(File.dirname(file))) }
         .sort_by(&:created_at).reverse
    end

    def find(name)
      all.detect { |gallery| gallery.name == name } || raise(ActionController::RoutingError, 'Gallery not found')
    end

    def active
      name = File.read(active_file).strip if File.exist?(active_file)
      gallery = all.detect { |g| g.name == name }
      gallery || all.first&.tap(&:activate!) || migrate
    end

    def create(caption)
      gallery = new(free_name(caption))
      FileUtils.mkdir_p(gallery.dir)
      gallery.write_event('caption' => '', 'created_at' => Time.now.getlocal.iso8601)
      gallery.caption = caption
      gallery
    end

    # device, mount point and bytes of the data partition
    def disk_usage
      source, *bytes = Syscall.execute("df -B1 --output=source,size,used,avail #{PictureSet.root.shellescape}")
                              .lines.last.split
      size, used, avail = bytes.map(&:to_i)
      { path: PictureSet.root.to_s, source: source, size: size, used: used, avail: avail }
    end

    # folder name: the caption, with a number if the folder (or the 'active' file) exists
    def free_name(caption)
      base = slug(caption)
      return base unless File.exist?(File.join(PictureSet.root, base))

      "#{base}-#{(2..).find { |i| !File.exist?(File.join(PictureSet.root, "#{base}-#{i}")) }}"
    end

    def slug(caption)
      caption.to_s.parameterize.presence || 'gallery'
    end

    private

    def active_file
      File.join(PictureSet.root, 'active')
    end

    # first start: the sets from before galleries existed move into the first gallery
    def migrate
      gallery = create(OPTS.image_caption)
      Dir.glob(File.join(PictureSet.root, "*/*#{PictureSet::ANIMATION_SUFFIX}")).each do |animation|
        FileUtils.mv(File.dirname(animation), gallery.dir)
      end
      gallery.activate!
      gallery
    end

  end

  def initialize(name)
    @name = name
    @dir = File.join(PictureSet.root, name)
  end

  def to_param
    name
  end

  def ==(other)
    other.is_a?(Gallery) && other.name == name
  end

  def activate!
    File.write(File.join(PictureSet.root, 'active'), name)
  end

  def caption
    event['caption'].to_s
  end

  # ImageMagick reads a file for a caption that starts with @
  def caption=(text)
    write_event(event.merge('caption' => text.to_s.strip.sub(/\A@+/, '')))
  end

  # galleries from before created_at: the time of the folder
  def created_at
    Time.zone.parse(event['created_at'].to_s) || File.mtime(dir)
  end

  def write_event(data)
    File.write(event_file, data.to_yaml)
  end

  # The folder gets the new caption as its name.
  # ponytail: a capture that runs during the rename writes into the old folder and fails
  def rename(caption)
    self.caption = caption
    return self if name.match?(/\A#{Regexp.escape(Gallery.slug(caption))}(-\d+)?\z/)

    new_name = Gallery.free_name(caption)
    active = self == Gallery.active
    File.rename(dir, File.join(PictureSet.root, new_name))
    gallery = Gallery.new(new_name)
    gallery.activate! if active
    gallery
  end

  def sets_count
    Dir.glob(File.join(dir, "*/*#{PictureSet::ANIMATION_SUFFIX}")).size
  end

  # bytes
  def size
    Syscall.execute("du -sb #{dir.shellescape}").to_i
  end

  private

  def event
    File.exist?(event_file) ? YAML.safe_load_file(event_file) || {} : {}
  end

  def event_file
    File.join(dir, 'event.yml')
  end

end
