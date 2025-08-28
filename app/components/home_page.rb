class HomePage < Phlex::HTML
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Roadtrip Planner", current_user: @current_user) do
      render WelcomeSection.new(current_user: @current_user)
    end
  end
end
