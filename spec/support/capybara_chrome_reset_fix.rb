# frozen_string_literal: true

require "capybara/selenium/driver"
require "capybara/selenium/driver_specializations/chrome_driver"

# Chrome 158+ rejects the wildcard origin that Capybara 3.40.0 passes to
# `Storage.clearDataForOrigin` in `ChromeDriver#reset!`
# ("invalid argument: * is not a valid URL"), which fails every JS system spec
# in teardown. Fall back to clearing cookies for all origins and the remaining
# storage types for the Capybara server origin.
# Remove once Capybara ships a fix.
module CapybaraChromeResetFix
  private

  def execute_cdp(cmd, params = {})
    super
  rescue Selenium::WebDriver::Error::InvalidArgumentError
    raise unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    types = params[:storageTypes].to_s.split(",")
    super("Network.clearBrowserCookies") if types.delete("cookies")
    return if types.empty?

    [ Capybara.app_host, Capybara.current_session.server&.base_url ].compact.uniq.each do |origin|
      super("Storage.clearDataForOrigin", origin: origin, storageTypes: types.join(","))
    end
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeResetFix)
