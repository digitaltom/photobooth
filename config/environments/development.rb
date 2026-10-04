# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Reload application code on every request.
  config.enable_reloading = true

  config.log_level = :debug

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # One thread: one camera, a second tap waits until the current set is done.
  config.active_job.queue_adapter = ActiveJob::QueueAdapters::AsyncAdapter.new(min_threads: 1, max_threads: 1)
end
