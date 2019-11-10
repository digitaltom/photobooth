# frozen_string_literal: true

source 'https://rubygems.org'

gem 'rails', '~> 5.2'
# angular-rails-templates currently only works with sprocket-rails 2
gem 'sprockets-rails'

gem 'angular-rails-templates'
gem 'angular_rails_csrf'
gem 'haml'

source 'https://rails-assets.org' do
  gem 'rails-assets-angular'
  gem 'rails-assets-angular-route'
  gem 'rails-assets-lazysizes'
end

gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use Puma as the app server
gem 'puma'

# file upload + qrcode
gem 'config-parser'

group :development do
  gem 'awesome_print'
end

group :development, :test do
  gem 'byebug'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :development, :production do
  # gpio, architecture + root dependant -> do not include in test
  gem 'pi_piper', require: false
end

group :test do
  gem 'capybara', '< 3.16' # capybara >= 3.16 requires ruby 2.4
  gem 'capybara-selenium'
  gem 'coveralls', require: false
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
  gem 'webdrivers', '= 4.1.2' # webdrivers 4.1.3 require rubyzi 2.0 which requires ruby 2.4
end
