# frozen_string_literal: true

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

end
