class Routes::WaypointsPageComponent < ApplicationComponent
  include Phlex::Rails::Helpers::HiddenFieldTag

  def initialize(route_data:, current_user:)
    @route_data = route_data
    @current_user = current_user
    @road_trip = RoadTrip.find_by(id: route_data["road_trip_id"]) if route_data
  end

  def view_template
    div class: "min-h-screen bg-gray-100" do
      # Navigation
      nav class: "bg-white shadow mb-8" do
        div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" do
          div class: "flex justify-between items-center h-16" do
            div class: "flex items-center" do
              link_to road_trips_path, class: "text-gray-600 hover:text-gray-900 mr-4" do
                "← Back to Road Trips"
              end
              if @road_trip
                span class: "text-gray-400" do
                  "/"
                end
                link_to @road_trip, class: "text-gray-600 hover:text-gray-900 ml-4" do
                  @road_trip.name
                end
              end
            end

            if @current_user
              div class: "flex items-center space-x-4" do
                span class: "text-gray-700" do
                  "Logged in as #{@current_user.username}"
                end
                link_to "Logout", logout_path, method: :delete,
                        class: "text-red-600 hover:text-red-900 font-medium"
              end
            end
          end
        end
      end

      # Main content
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8" do
        if @route_data.nil?
          div class: "bg-white shadow rounded-lg p-6" do
            div class: "text-center" do
              h2 class: "text-xl font-semibold text-gray-900 mb-4" do
                "No Route Data Found"
              end
              p class: "text-gray-600 mb-6" do
                "Please start by creating a new route from your road trip page."
              end
              link_to "Back to Road Trips", road_trips_path,
                      class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700"
            end
          end
        else
          div class: "bg-white shadow rounded-lg overflow-hidden" do
            # Header
            div class: "bg-blue-600 px-6 py-4" do
              h1 class: "text-2xl font-bold text-white" do
                "Set Waypoints for Your Route"
              end
              p class: "text-blue-100 mt-2" do
                "Click on the map to add waypoints that will modify your route. You can skip this step if you don't want to add waypoints."
              end
            end

            # Route details
            div class: "p-6" do
              div class: "mb-6" do
                h2 class: "text-lg font-semibold text-gray-900 mb-4" do
                  "Route Details"
                end

                div class: "bg-gray-50 rounded-lg p-4 space-y-3" do
                  div class: "flex items-start" do
                    svg_icon path_d: "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z",
                             class: "h-5 w-5 text-green-600 mr-3 mt-0.5",
                             fill: "currentColor",
                             viewBox: "0 0 20 20"
                    div do
                      div class: "text-sm text-gray-600" do
                        "Starting Location"
                      end
                      div class: "font-semibold text-gray-900" do
                        @route_data["starting_location"]
                      end
                    end
                  end

                  div class: "flex items-start" do
                    svg_icon path_d: "M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z",
                             class: "h-5 w-5 text-red-600 mr-3 mt-0.5",
                             fill: "currentColor",
                             viewBox: "0 0 20 20"
                    div do
                      div class: "text-sm text-gray-600" do
                        "Destination"
                      end
                      div class: "font-semibold text-gray-900" do
                        @route_data["destination"]
                      end
                    end
                  end
                end
              end

              # Interactive waypoint map
              div class: "mb-6" do
                h2 class: "text-lg font-semibold text-gray-900 mb-4" do
                  "Set Waypoints"
                end

                div class: "mb-4 p-4 bg-blue-50 rounded-lg" do
                  div class: "flex items-start" do
                    svg_icon path_d: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                             class: "h-5 w-5 text-blue-600 mr-3 mt-0.5",
                             fill: "currentColor",
                             viewBox: "0 0 24 24"
                    div class: "text-sm text-blue-800" do
                      p class: "font-semibold mb-2" do
                        "How to use waypoints:"
                      end
                      ul class: "list-disc list-inside space-y-1" do
                        li { "Click on roads on the map to add waypoints" }
                        li { "Waypoints will modify your route to pass through those locations" }
                        li { "Click on a waypoint marker to remove it" }
                        li { "The order of waypoints matters for your route" }
                      end
                    end
                  end
                end

                div id: "waypoints-map",
                     class: "h-96 bg-gray-100 rounded-lg border border-gray-300 relative",
                     data: {
                       controller: "waypoints-map",
                       waypoints_map_start_location_value: @route_data["starting_location"],
                       waypoints_map_end_location_value: @route_data["destination"],
                       waypoints_map_avoid_motorways_value: @route_data["avoid_motorways"] || false
                     } do
                  # Map will be rendered here by Stimulus controller
                end

                # Map attribution and info
                div class: "mt-2 text-xs text-gray-500" do
                  "Map data © OpenStreetMap contributors"
                end
              end

              # Waypoint list
              div class: "mb-6" do
                h3 class: "text-lg font-semibold text-gray-900 mb-4" do
                  "Current Waypoints"
                end
                div id: "waypoints-list", class: "space-y-2" do
                  div class: "text-gray-500 text-sm italic" do
                    "No waypoints set. Click on the map to add waypoints."
                  end
                end
              end

              # Action buttons and form
              form_with url: set_waypoints_path, method: :post, local: true, class: "space-y-4" do |form|
                hidden_field_tag "waypoints", "", id: "waypoints-data"

                div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
                  link_to "Back to Edit Route",
                          new_road_trip_route_path(@road_trip),
                          class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"

                  div class: "space-x-3" do
                    link_to "Skip Waypoints",
                            confirm_route_path,
                            class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"

                    form.submit "Continue with Waypoints",
                                id: "continue-with-waypoints",
                                class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
