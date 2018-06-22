require 'fileutils'

namespace :picture_set do
  COMBINED_SUFFIX = '_combined.jpg'.freeze
  
  desc "Combine all images into one"
  task :combine_images, [:path] => [:environment] do |task, args|
    path = args[:path]
    path = File.join(Rails.root, 'public', 'picture_sets') if path.blank?
    puts "Using directory #{path}."
    Dir.chdir(path) do
      picture_sets = Dir.glob('*').select {|f| File.directory? f}
      picture_sets.each do |date|
        puts "Processing #{date}..."
        combine_images(date, path)
      end
    end
  end
  
  desc "Remove combined images. Necessary before running combine_images task again."
  task :clean_combine_images, [:path] => [:environment] do |task, args|
    path = args[:path]
    path = File.join(Rails.root, 'public', 'picture_sets') if path.blank?
    puts "Using directory #{path}."
    Dir.chdir(path) do
      picture_sets = Dir.glob('*').select {|f| File.directory? f}
      picture_sets.each do |date|
        Dir.chdir(File.join(path, date)) do
          FileUtils.rm("#{date}#{COMBINED_SUFFIX}", force: true)
        end
      end
    end
  end
  
  desc "Copies all images into one directory (without the single polaroids)"
  task :copy, [:path, :output] => [:environment] do |task, args|
    path = args[:path]
    path = File.join(Rails.root, 'public', 'picture_sets') if path.blank?
    puts "Using directory #{path}."
    Dir.chdir(path) do
      picture_sets = Dir.glob('*').select {|f| File.directory?(f) && f != 'all'}
      picture_sets.each do |date|
        Syscall.execute("cp #{File.join(path, date, "*.jpg")} #{args[:output]}")
        Syscall.execute("cp #{File.join(path, date, "*.gif")} #{args[:output]}")
      rescue => e
        puts e
    end
  end
  
  def combine_images(date, path)
  dir = File.join(path, date)
  begin
  Syscall.execute("time montage -geometry '25%x25%+25+25<' -background '#{OPTS.background_color}' " \
    "-title '#{OPTS.image_caption}' -font '#{OPTS.font}' -fill '#{OPTS.font_color}' " \
    "-pointsize #{OPTS.combined_image_fontsize} -gravity 'Center' #{date}_*.jpg #{date}#{COMBINED_SUFFIX}",
    dir: dir)
  rescue => e
    puts "Can not process #{dir}: #{e}"
  end
end
