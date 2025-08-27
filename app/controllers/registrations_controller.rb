class RegistrationsController < ApplicationController
  before_action :require_logout, only: [ :new, :create ]

  def new
    @user = User.new
    component = ApplicationLayout.new(title: "Sign Up", current_user: current_user) do
      render RegistrationForm.new(@user)
    end
    render component, layout: false
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome! Your account has been created successfully."
    else
      component = ApplicationLayout.new(title: "Sign Up", current_user: current_user) do
        render RegistrationForm.new(@user)
      end
      render component, layout: false
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
