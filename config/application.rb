# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
# ActiveRecord only backs Solid Queue and Solid Cable, picture sets live on the filesystem
require 'active_record/railtie'
require 'active_job/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_cable/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsPhotobooth
  class Application < Rails::Application
    config.load_defaults 8.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end

# config/options.yml ('default' merged with the current environment), overridden by config/options-local.yml
OPTS = begin
  load_options = lambda do |file|
    path = Rails.root.join(file)
    options = path.exist? ? YAML.unsafe_load(ERB.new(path.read).result) || {} : {}
    (options['default'] || {}).deep_merge(options[Rails.env] || {})
  end
  ActiveSupport::OrderedOptions.new.merge!(
    load_options.call('config/options.yml').deep_merge(load_options.call('config/options-local.yml')).symbolize_keys
  )
end
