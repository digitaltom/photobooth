# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 4.2'
gem 'sqlite3'
# angular-rails-templates currently only works with sprocket-rails 2
gem 'sprockets-rails', '~> 3.2.1'

gem 'angular-rails-templates'
gem 'angular_rails_csrf'
gem 'haml'

source 'https://rails-assets.org' do
  gem 'rails-assets-angular', '1.7.5'
  gem 'rails-assets-angular-route', '1.7.5'
  gem 'rails-assets-lazysizes', '4.1.4'
end

gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use Puma as the app server
gem 'puma'
gem 'quiet_assets'

# file upload + qrcode
gem 'config-parser'

group :development do
  gem 'awesome_print'
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop', require: false
end

group :development, :production do
  # gpio, architecture + root dependant -> do not include in test
  gem 'pi_piper', require: false
end

group :test do
  gem 'capybara'
  gem 'capybara-selenium'
  gem 'chromedriver-helper'
  gem 'coveralls', require: false
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
