require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'

# Load support files
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
  
  # Use transactional fixtures for fast, isolated tests
  config.use_transactional_fixtures = true
  
  # Configure default host for request specs
  config.before(:each, type: :request) do
    host! 'localhost'
    ActionController::Base.allow_forgery_protection = false
  end
  
  config.after(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = true
  end
  
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.filter_rails_from_backtrace!
end