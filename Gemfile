# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 4.0.5'

gem 'rails', '~> 8.1'
# angular-rails-templates requires sprockets
gem 'sprockets-rails'

gem 'angular_rails_csrf'
gem 'angular-rails-templates'
gem 'haml'

# Use Puma as the app server
gem 'puma'

group :development do
  gem 'awesome_print'
end

group :development, :test do
  gem 'debug'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :development, :production do
  # gpio, architecture + root dependant -> do not include in test
  gem 'pi_piper', require: false
end

group :test do
  gem 'capybara'
  gem 'cuprite'
  gem 'rspec-rails'
  gem 'simplecov', require: false
end
