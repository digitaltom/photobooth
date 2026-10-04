# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['PHOTOBOX_STORAGE'] ||= File.expand_path('fixtures/filesystem', __dir__)
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'capybara/cuprite'

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [2360, 1640], # iPad Air 4 resolution
                                     # English UI, also on a desktop with a German LANG
                                     browser_options: { 'no-sandbox' => nil, 'accept-lang' => 'en' })
end

Capybara.javascript_driver = :cuprite
RSpec::Matchers.define_negated_matcher :exclude, :include
# capybara cheat sheet: https://gist.github.com/zhengjia/428105

RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
  config.include ActiveSupport::Testing::TimeHelpers

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.after type: :feature, js: true do
    Capybara.reset_sessions!
  end
end
