# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Server
gem 'eventmachine'

# Database
gem 'mysql2', '~> 0.5.2'
gem 'sequel', '~> 4.0'

# Cache
gem 'dalli'

# API Server
gem 'puma', '>= 5.3.1'
gem 'rack'

# Monitor
gem 'sentry-ruby'

# Utils
gem 'activesupport'
gem 'gmp'
gem 'rake'
gem 'RubyInline', '~>3.12.4'

group :build do
  gem 'RocketAMF', '~>0.2.1'
  gem 'sqlite3'
end

group :development, :test do
  gem 'rubocop', '~> 1.8.1', require: false
  gem 'rubocop-performance', '>= 1.8.1', require: false
  gem 'rubocop-rspec', '>= 2.0.1', require: false
  gem 'rubocop-sequel', '>= 0.1.0', require: false
  gem 'rubocop-thread_safety', '>= 0.4.2', require: false

  gem 'bundler-audit', require: false
  gem 'bundler-leak', require: false
end

group :development do
  gem 'dotenv'

  gem 'overcommit', require: false
end

group :test do
  gem 'rspec', require: false
  gem 'rspec_junit_formatter', require: false

  gem 'cucumber', require: false
  gem 'database_cleaner-sequel', require: false
  gem 'factory_bot', require: false
  gem 'faker', require: false
  gem 'simplecov', '~> 0.17.1', require: false
  gem 'simplecov-cobertura', require: false

  gem 'super_diff', require: false
end
