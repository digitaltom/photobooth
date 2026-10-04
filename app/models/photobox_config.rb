# frozen_string_literal: true

# Writes photobox.yml on the boot partition (FAT, readable from any laptop). OPTS reads it at boot,
# keys in photobox-local.yml next to it win. deploy/image/photobox-network reads the same files.
# Writes replace single lines, so the comments in the file stay.
class PhotoboxConfig

  class << self

    def path
      OPTS.photobox_conf
    end

    def local_path
      path.sub(/\.yml\z/, '-local.yml')
    end

    def admin_password?(password)
      password.present? && ActiveSupport::SecurityUtils.secure_compare(password, OPTS.admin_password.to_s)
    end

    def admin_password=(password)
      write(:admin_password, password)
    end

    def camera_imageformat=(format)
      write(:camera_imageformat, format)
    end

    private

    # the file that has the key, else photobox.yml
    def file_with(key)
      [local_path, path].find { |file| File.exist?(file) && File.read(file).match?(/^#{key}:/) } || path
    end

    def write(key, value)
      file = file_with(key)
      content = File.exist?(file) ? File.read(file) : +''
      line = "#{key}: #{value.to_json}"
      if content.match?(/^#{key}:/)
        content.sub!(/^#{key}:.*$/) { line }
      else
        content << "\n" unless content.empty? || content.end_with?("\n")
        content << "#{line}\n"
      end
      File.write(file, content)
      OPTS[key] = value
    end

  end

end
