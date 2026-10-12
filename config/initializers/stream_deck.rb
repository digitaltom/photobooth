# frozen_string_literal: true

# server only: no device polling in rails runner, rake or the console
Rails.application.config.after_initialize do
  StreamDeck.start if defined?(Rails::Server)
end
