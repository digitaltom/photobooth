# frozen_string_literal: true

require 'fileutils'

namespace :picture_set do

  desc 'Record a new picture set'
  task record: [:environment] do |_task, _args|
    CaptureJob.perform_now(PictureSet.next_id)
  end

  desc 'Re-create single polaroid images'
  task :recreate_polaroid_images, [:path] => [:environment] do |_task, args|
    ENV['PHOTOBOX_STORAGE'] = args[:path] if args[:path].present?
    PictureSet.all.each do |ps|
      angle = Random.rand(355..365)
      (1..4).each { |num| ps.convert_to_polaroid(num, angle) }
    end
  end

  desc 'Re-create animated gifs'
  task :recreate_animations, [:path] => [:environment] do |_task, args|
    ENV['PHOTOBOX_STORAGE'] = args[:path] if args[:path].present?
    PictureSet.all.each { |ps| ps.create_animation(overwrite: true) }
  end

  desc 'Exports all images into a single directory (without the single polaroids)'
  task :export, %i[output path] => [:environment] do |_task, args|
    ENV['PHOTOBOX_STORAGE'] = args[:path] if args[:path].present?
    puts "copying from #{PictureSet.root} to #{args[:output]}."
    PictureSet.all.each do |ps|
      Dir.chdir(ps.dir) do
        FileUtils.cp(ps.animation, args[:output])
        FileUtils.cp(ps.pictures.map { |p| p[:full] }, args[:output])
      end
    end
  end

end
