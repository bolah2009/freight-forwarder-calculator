source "https://rubygems.org"

rails_version = "~> 7.2.1"

gem "actionpack",    rails_version
gem "actionview",    rails_version
gem "activemodel",   rails_version
gem "activesupport", rails_version
gem "railties",      rails_version

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "rswag-api"
gem "rswag-ui"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "rswag-specs"

  # code QA
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "bundle-audit", require: false
  gem "pry-byebug"
  gem "pry-rails"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :test do
  gem "capybara"
  gem "simplecov", require: false
  gem "simplecov-console", require: false
end

# gem "dockerfile-rails", ">= 1.6", group: :development
gem "ostruct"
