class Routes::ConfirmPageComponent < ApplicationComponent
  def initialize(route_data:, current_user:, route: nil)
    @route_data = route_data
    @current_user = current_user
    @route = route
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
                "Review Your Route"
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

              # Interactive route map
              div class: "mb-6" do
                h2 class: "text-lg font-semibold text-gray-900 mb-4" do
                  "Route Map"
                end
                div id: "route-map",
                     class: "h-96 bg-gray-100 rounded-lg border border-gray-300 relative",
                     data: {
                       controller: "route-map",
                       route_map_start_location_value: @route_data["starting_location"],
                       route_map_end_location_value: @route_data["destination"]
                     } do
                  # Map will be rendered here by Stimulus controller
                end

                # Map attribution and info
                div class: "mt-2 text-xs text-gray-500" do
                  "Map data © OpenStreetMap contributors"
                end
              end

              # Date/Time selection and approval
              form_with url: approve_route_path, method: :post, local: true, class: "space-y-4" do |form|
                div do
                  form.label :datetime, "Select Date & Time for this Route",
                             class: "block text-sm font-medium text-gray-700 mb-2"

                  form.datetime_local_field :datetime,
                                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500",
                                            required: true,
                                            min: DateTime.now.strftime("%Y-%m-%dT%H:%M"),
                                            value: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M")

                  if @route && @route.errors[:datetime].any?
                    div class: "mt-1 text-sm text-red-600" do
                      @route.errors[:datetime].first
                    end
                  end
                end

                # Action buttons
                div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
                  link_to "Back to Edit",
                          new_road_trip_route_path(@road_trip),
                          class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"

                  form.submit "Add Route to Trip",
                              class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                end
              end

              # Error messages
              if @route && @route.errors.any?
                div class: "mt-4 p-4 bg-red-50 rounded-md" do
                  h3 class: "text-sm font-medium text-red-800 mb-2" do
                    "There were some issues with your route:"
                  end
                  ul class: "list-disc list-inside text-sm text-red-700" do
                    @route.errors.full_messages.each do |message|
                      li { message }
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
end
