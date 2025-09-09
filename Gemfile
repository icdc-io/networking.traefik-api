source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~> 3.2.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 8.0.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
# Use Puma as the app server
gem "puma", "~> 7.0.2"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "~> 1.18", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors", "~> 3.0"

gem "fileutils",   "~> 1.7"
gem "haikunator",  "~> 1.1"
gem "json2yaml",   "~> 0.0.3"
gem "rbac-ruby",   "1.0.1"
gem "rest-client", "~> 2.1"
gem "rubyzip",     "~> 3.1"

gem "sidekiq",      "~> 8.0"
gem "sidekiq-cron", "~> 2.3"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri windows]

  gem "dotenv-rails",      "~> 3.1"
  gem "factory_bot_rails", "~> 6.5"
  gem "rspec-rails",       "~> 8.0"

  gem "bullet", "~> 8.0"
end

group :development do
  gem "listen", "~> 3.9"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem "spring"

  gem "rubocop-factory_bot",   "~> 2.27", require: false
  gem "rubocop-performance",   "~> 1.26", require: false
  gem "rubocop-rails",         "~> 2.33", require: false
  gem "rubocop-rails-omakase", "~> 1.1",  require: false
  gem "rubocop-rspec",         "~> 3.7",  require: false
  gem "rubocop-rspec_rails",   "~> 2.31", require: false

  gem "reek", "~> 6.5", require: false

  gem "brakeman", "~> 7.1", require: false
end

group :test do
  gem "rspec_junit_formatter", "~> 0.6.0"

  gem "simplecov",           "~> 0.22.0", require: false
  gem "simplecov-cobertura", "~> 3.1",    require: false

  gem "rspec-sidekiq", "~> 5.2"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]
