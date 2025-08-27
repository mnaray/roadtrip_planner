class HomePage < Phlex::HTML
  def view_template
    render ApplicationLayout.new(title: "Roadtrip Planner") do
      render WelcomeSection.new
    end
  end
end
