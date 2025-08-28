class SessionsController < ApplicationController
  before_action :require_logout, only: [ :new, :create ]

  def new
    component = ApplicationLayout.new(title: "Login", current_user: current_user) do
      render LoginForm.new
    end
    render component, layout: false
  end

  def create
    user = User.find_by(username: params[:username].downcase)

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back, #{user.username}!"
    else
      flash.now[:alert] = "Invalid username or password"
      flash.now[:username] = params[:username].to_s.strip if params[:username].present?
      component = ApplicationLayout.new(title: "Login", current_user: current_user) do
        render LoginForm.new
      end
      render component, layout: false
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out successfully."
  end
end
