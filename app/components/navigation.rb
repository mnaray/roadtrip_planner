class Navigation < ApplicationComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def view_template
    nav class: "bg-white/95 backdrop-blur-sm border-b border-gray-200 shadow-sm sticky top-0 z-50" do
      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" do
        div class: "flex justify-between h-16 items-center" do
          # Logo/Brand
          div class: "flex-shrink-0" do
            link_to root_path, class: "text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent hover:from-blue-700 hover:to-purple-700 transition-all" do
              "Roadtrip Planner"
            end
          end

          # Navigation Links
          div class: "flex items-center space-x-4" do
            if @current_user
              # Logged in navigation
              span class: "text-gray-600 text-sm" do
                "Welcome, #{@current_user.username}!"
              end

              button_to logout_path,
                       method: :delete,
                       class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 transition-colors",
                       data: { confirm: "Are you sure you want to log out?" } do
                "Logout"
              end
            else
              # Logged out navigation
              link_to "Login",
                     login_path,
                     class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"

              link_to "Sign Up",
                     register_path,
                     class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
            end
          end
        end
      end
    end
  end
end
