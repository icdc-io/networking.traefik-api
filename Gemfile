source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "~>3.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.1.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use Puma as the app server
gem "puma", "~> 6.6.1"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.4.4", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"

gem "fileutils", "1.7.0"
gem "haikunator"
gem "json2yaml"
gem "json-jwt"
gem "jwt"
gem "rbac-ruby", "1.0.1"
gem "rest-client"
gem "rubyzip"
gem "sidekiq", "< 7.0.0"
gem "sidekiq-cron", "< 1.8"

# Remove lines below after fixing mail gem
# https://stackoverflow.com/questions/70500220/rails-7-ruby-3-1-loaderror-cannot-load-such-file-net-smtp
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv-rails", "~> 3.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "rspec-rails", "~> 6.1"

  gem "bullet", "~> 6.1"

  gem "concurrent-ruby", "1.3.4"
end

group :development do
  gem "listen", "~> 3.3"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem "spring"

  gem "rubocop-factory_bot",   "~> 2.27", require: false
  gem "rubocop-performance",   "~> 1.25", require: false
  gem "rubocop-rails",         "~> 2.33", require: false
  gem "rubocop-rails-omakase", "~> 1.1",  require: false
  gem "rubocop-rspec",         "~> 3.6",  require: false
  gem "rubocop-rspec_rails",   "~> 2.31", require: false

  gem "reek", "~> 6.5", require: false

  gem "brakeman", "~> 7.1", require: false
end

group :test do
  gem "rspec_junit_formatter", "~> 0.6.0"

  gem "simplecov",           "~> 0.22.0", require: false
  gem "simplecov-cobertura", "~> 3.0",    require: false

  gem "rspec-sidekiq", "~> 5.2"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "tzinfo-data"
