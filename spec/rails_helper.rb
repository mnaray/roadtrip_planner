require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'selenium-webdriver'

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
  # But disable for JavaScript tests which run in separate process
  config.use_transactional_fixtures = true

  # Disable transactional fixtures for JavaScript tests since they run in separate process
  config.before(:each, type: :system, js: true) do
    self.use_transactional_tests = false
  end

  # Configure default host for request specs
  config.before(:each, type: :request) do
    host! 'localhost'
    ActionController::Base.allow_forgery_protection = false
  end

  config.after(:each, type: :request) do
    ActionController::Base.allow_forgery_protection = true
  end

  # Configure system tests
  config.before(:each, type: :system) do
    driven_by :rack_test
    Capybara.default_host = 'http://localhost'
    # Minimal wait time - only for true async operations like page loads
    # Synchronous JS calculations don't need any waiting
    Capybara.default_max_wait_time = 2
  end

# Register Chrome driver once
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-extensions')
  options.add_argument('--disable-background-timer-throttling')
  options.add_argument('--disable-backgrounding-occluded-windows')
  options.add_argument('--disable-renderer-backgrounding')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

  # Configure JavaScript tests to use Selenium Chrome headless
  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
    Capybara.default_host = 'http://localhost'
  end

  # Clean database after JavaScript tests since they can't use transactions
  config.after(:each, type: :system, js: true) do
    # Disable foreign key checks temporarily for faster cleanup
    ActiveRecord::Base.connection.execute("SET session_replication_role = replica;")

    # Truncate all tables except schema_migrations and ar_internal_metadata
    ActiveRecord::Base.connection.tables.each do |table|
      next if [ 'schema_migrations', 'ar_internal_metadata' ].include?(table)
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY CASCADE")
    end

    # Re-enable foreign key checks
    ActiveRecord::Base.connection.execute("SET session_replication_role = DEFAULT;")
  end

  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]
  config.filter_rails_from_backtrace!
end
