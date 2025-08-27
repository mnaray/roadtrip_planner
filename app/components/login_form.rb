class LoginForm < ApplicationComponent
  def initialize(username: nil)
    @username = username
  end

  def view_template
    flash_alert = defined?(helpers.flash) && helpers.flash[:alert] ? helpers.flash[:alert] : nil

    div class: "min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8",
        **flash_alert_data(flash_alert) do
      div class: "max-w-md w-full space-y-8" do
        div do
          h2 class: "mt-6 text-center text-3xl font-extrabold text-gray-900" do
            "Sign in to your account"
          end
          p class: "mt-2 text-center text-sm text-gray-600" do
            "Don't have an account? "
            link_to "Sign up", register_path, class: "font-medium text-blue-600 hover:text-blue-500"
          end
        end

        # Flash messages will now be shown as popup

        form_with url: login_path, local: true, class: "mt-8 space-y-6" do |form|
          div class: "space-y-4" do
            div do
              form.label :username, class: "block text-sm font-medium text-gray-700 mb-1" do
                "Username"
              end
              form.text_field :username,
                             required: true,
                             autofocus: true,
                             value: @username,
                             class: "appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm",
                             placeholder: "Enter your username"
            end

            div do
              form.label :password, class: "block text-sm font-medium text-gray-700 mb-1" do
                "Password"
              end
              form.password_field :password,
                                 required: true,
                                 class: "appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm",
                                 placeholder: "Enter your password"
            end
          end

          div do
            form.submit "Sign In",
                       class: "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
          end
        end
      end
    end
  end

  private

  def flash_alert_data(alert)
    alert ? { "data-flash-alert" => alert } : {}
  end
end
