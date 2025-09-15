class AboutPage < ApplicationComponent
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "About - Roadtrip Planner", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12" do
        # Page header
        div class: "text-center mb-12" do
          h1 class: "text-4xl md:text-5xl font-bold mb-6 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent" do
            "About Roadtrip Planner"
          end
          p class: "text-xl text-gray-600 max-w-2xl mx-auto leading-relaxed" do
            "Your collaborative companion for planning and organizing memorable road trips with friends and family"
          end
        end

        # Main content
        div class: "bg-white/70 backdrop-blur-sm rounded-2xl shadow-lg border border-white/20 p-8 md:p-12" do
          # What the app is section
          div class: "mb-10" do
            h2 class: "text-2xl font-semibold text-gray-800 mb-4" do
              "What is Roadtrip Planner?"
            end
            p class: "text-gray-700 text-lg leading-relaxed" do
              "Roadtrip Planner is a collaborative web application that helps you organize and plan road trips from start to finish. Whether you're planning a weekend getaway or a cross-country adventure, you can work together with friends and family to keep track of routes, destinations, and everything you need to bring along."
            end
          end

          # Features section
          div class: "mb-10 pt-4" do
            h2 class: "text-2xl font-semibold text-gray-800 mb-6" do
              "Main Features"
            end
            ul class: "space-y-3 text-gray-700 list-disc list-inside" do
              li do
                "Collaborate with friends and family by sharing trips and managing participants"
              end
              li do
                "Plan interactive routes with custom waypoints by clicking directly on the map"
              end
              li do
                "Choose more cost efficient routes with highway and toll avoidance options"
              end
              li do
                "Calculate fuel costs in real-time with the built-in fuel economy calculator"
              end
              li do
                "Organize packing lists with categories, checkboxes, and progress tracking"
              end
              li do
                "Export route data for GPS devices and navigation apps"
              end
            end
          end

          # Getting started section
          div class: "mb-8 pt-4" do
            h2 class: "text-2xl font-semibold text-gray-800 mb-6" do
              "Getting Started"
            end
            if @current_user
              div class: "bg-green-50 border border-green-200 rounded-lg p-6" do
                p class: "text-green-800 mb-4" do
                  "You're already signed in! Here's how to start planning:"
                end
                ol class: "space-y-3 text-green-700" do
                  li class: "flex items-start" do
                    span class: "bg-green-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0" do
                      "1"
                    end
                    span do
                      "Click on \"My Road Trips\" in the navigation to view your trips or create a new one"
                    end
                  end
                  li class: "flex items-start" do
                    span class: "bg-green-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0" do
                      "2"
                    end
                    span do
                      "Start adding destinations to your route and create packing lists to stay organized"
                    end
                  end
                end
              end
            else
              div class: "bg-blue-50 border border-blue-200 rounded-lg p-6" do
                p class: "text-blue-800 mb-4" do
                  "Ready to start planning your next adventure?"
                end
                ol class: "space-y-3 text-blue-700" do
                  li class: "flex items-start" do
                    span class: "bg-blue-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0" do
                      "1"
                    end
                    span do
                      "Create a free account by clicking \"Sign Up\" in the navigation"
                    end
                  end
                  li class: "flex items-start" do
                    span class: "bg-blue-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-semibold mr-3 mt-0.5 flex-shrink-0" do
                      "2"
                    end
                    span do
                      "Create your first road trip and start adding destinations and packing items"
                    end
                  end
                end
              end
            end
          end
        end

        # Call to action
        div class: "text-center mt-8" do
          if @current_user
            link_to road_trips_path,
                   class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white transition-all duration-300 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full hover:from-blue-700 hover:to-purple-700 hover:shadow-lg hover:scale-105 focus:outline-none focus:ring-4 focus:ring-blue-300" do
              "View My Road Trips"
            end
          else
            div class: "flex flex-col sm:flex-row gap-4 justify-center items-center" do
              link_to register_path,
                     class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white transition-all duration-300 bg-gradient-to-r from-blue-600 to-purple-600 rounded-full hover:from-blue-700 hover:to-purple-700 hover:shadow-lg hover:scale-105 focus:outline-none focus:ring-4 focus:ring-blue-300" do
                "Get Started"
              end
              link_to login_path,
                     class: "inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-blue-600 transition-all duration-300 bg-white border-2 border-blue-600 rounded-full hover:bg-blue-50 focus:outline-none focus:ring-4 focus:ring-blue-300" do
                "Sign In"
              end
            end
          end
        end
      end
    end
  end
end
