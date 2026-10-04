# frozen_string_literal: true

# A gallery is a folder in PictureSet.root with the picture sets of one event and its event.yml (caption).
# The file 'active' in PictureSet.root names the gallery that gets new sets and that guests see.
class Gallery

  attr_reader :name, :dir

  class << self

    def all
      Dir.glob(File.join(PictureSet.root, '*/event.yml')).map { |file| new(File.basename(File.dirname(file))) }
         .sort_by(&:name).reverse
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
      base = [Time.now.getlocal.strftime('%Y-%m-%d'), caption.to_s.parameterize.presence].compact.join('-')
      name = base
      name = "#{base}-#{(2..).find { |i| !File.exist?(File.join(PictureSet.root, "#{base}-#{i}")) }}" if
        File.exist?(File.join(PictureSet.root, base))
      gallery = new(name)
      FileUtils.mkdir_p(gallery.dir)
      gallery.caption = caption
      gallery
    end

    # bytes of the data partition
    def disk_usage
      size, used, avail = Syscall.execute("df -B1 --output=size,used,avail #{PictureSet.root.shellescape}")
                                 .lines.last.split.map(&:to_i)
      { size: size, used: used, avail: avail }
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
    (YAML.safe_load_file(event_file) || {})['caption'].to_s
  end

  # ImageMagick reads a file for a caption that starts with @
  def caption=(text)
    text = text.to_s.strip.sub(/\A@+/, '')
    File.write(event_file, { 'caption' => text }.to_yaml)
  end

  def sets_count
    Dir.glob(File.join(dir, "*/*#{PictureSet::ANIMATION_SUFFIX}")).size
  end

  # bytes
  def size
    Syscall.execute("du -sb #{dir.shellescape}").to_i
  end

  private

  def event_file
    File.join(dir, 'event.yml')
  end

end
