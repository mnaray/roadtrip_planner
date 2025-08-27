source "http://rubygems.org"

ruby "3.2.3"

# Rails framework
gem "rails", "~> 8.0.0"

# Database
gem "pg", "~> 1.1"

# Server
gem "puma", ">= 5.0"

# Asset pipeline
gem "sprockets-rails"

# JavaScript bundling
gem "importmap-rails"

# CSS bundling
gem "stimulus-rails"
gem "turbo-rails"

# JSON APIs
gem "jbuilder"

# Boot large ruby/rails apps faster
gem "bootsnap", require: false

# Image processing for Active Storage
gem "image_processing", "~> 1.2"

group :development, :test do
  # Debugging
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing framework
  gem "rspec-rails"
end

group :development do
  # Web console for better debugging
  gem "web-console"
end