# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Reload application code on every request.
  config.enable_reloading = true

  config.log_level = :debug
  config.assets.quiet = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.logger = Logger.new($stdout)
  config.action_mailer.smtp_settings = {
    address: OPTS.mail_settings['address'],
    port: OPTS.mail_settings['port'],
    user_name: OPTS.mail_settings['user_name'],
    password: OPTS.mail_settings['password'],
    authentication: OPTS.mail_settings['authentication'],
    enable_starttls_auto: OPTS.mail_settings['enable_starttls_auto']
  }
end
