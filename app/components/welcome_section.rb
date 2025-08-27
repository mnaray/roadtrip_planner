class WelcomeSection < Phlex::HTML
  def view_template
    div style: "text-align: center; padding: 50px;" do
      h1 { "Hello from roadtrip_planner!" }
      p { "Welcome to your new Rails 8 application running in Docker!" }
      p { "Rails version: #{Rails.version}" }
      p { "Ruby version: #{RUBY_VERSION}" }
    end
  end
end