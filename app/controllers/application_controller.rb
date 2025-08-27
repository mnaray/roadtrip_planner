class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def index
    render json: { 
      message: "Welcome to Roadtrip Planner!", 
      status: "Running",
      timestamp: Time.current
    }
  end
end