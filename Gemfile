# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 4.0.5'

gem 'rails', '~> 8.1'
# asset pipeline (bootstrap css, images)
gem 'sprockets-rails'

gem 'haml'
gem 'turbo-rails'

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
