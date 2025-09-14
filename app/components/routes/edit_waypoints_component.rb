class Routes::EditWaypointsComponent < ApplicationComponent
  include Phlex::Rails::Helpers::HiddenFieldTag

  def initialize(route:, waypoints:, current_user:)
    @route = route
    @waypoints = waypoints
    @current_user = current_user
    @road_trip = route.road_trip
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
        div class: "bg-white shadow rounded-lg overflow-hidden" do
          # Header
          div class: "bg-blue-600 px-6 py-4" do
            h1 class: "text-2xl font-bold text-white" do
              "Edit Waypoints for Route"
            end
            p class: "text-blue-100 mt-2" do
              "Add, remove, or reposition waypoints to customize your route"
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
                      @route.starting_location
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
                      @route.destination
                    end
                  end
                end
              end
            end

            # Instructions
            div class: "mb-4 p-4 bg-blue-50 rounded-lg" do
              div class: "flex items-start" do
                svg_icon path_d: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "h-5 w-5 text-blue-600 mr-3 mt-0.5",
                         fill: "currentColor",
                         viewBox: "0 0 24 24"
                div class: "text-sm text-blue-800" do
                  p class: "font-semibold mb-2" do
                    "How to edit waypoints:"
                  end
                  ul class: "list-disc list-inside space-y-1" do
                    li { "Click on the map to add new waypoints" }
                    li { "Click on existing waypoint markers to remove them" }
                    li { "Waypoints will modify your route to pass through those locations" }
                    li { "The order of waypoints matters for your route" }
                  end
                end
              end
            end

            # Interactive waypoint map
            div class: "mb-6" do
              h2 class: "text-lg font-semibold text-gray-900 mb-4" do
                "Edit Waypoints"
              end

              div id: "edit-waypoints-map",
                   class: "h-96 bg-gray-100 rounded-lg border border-gray-300 relative",
                   data: {
                     controller: "edit-waypoints-map",
                     edit_waypoints_map_start_location_value: @route.starting_location,
                     edit_waypoints_map_end_location_value: @route.destination,
                     edit_waypoints_map_existing_waypoints_value: existing_waypoints_json
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
              div class: "text-sm text-gray-600 mb-2" do
                "Drag waypoints to reorder their sequence"
              end
              div id: "waypoints-list",
                   class: "space-y-2",
                   data: {
                     controller: "sortable-waypoints"
                   } do
                if @waypoints.empty?
                  div class: "text-gray-500 text-sm italic" do
                    "No waypoints set. Click on the map to add waypoints."
                  end
                else
                  @waypoints.each do |waypoint|
                    div class: "flex items-center justify-between p-3 bg-gray-50 rounded-md hover:bg-gray-100 transition-colors",
                         data: {
                           sortable_waypoints_target: "item",
                           waypoint_id: waypoint.id,
                           position: waypoint.position,
                           latitude: waypoint.latitude.to_f,
                           longitude: waypoint.longitude.to_f,
                           name: waypoint.name.presence || "Waypoint #{waypoint.position}"
                         },
                         draggable: true do
                      div class: "flex items-center flex-1" do
                        # Drag handle
                        div class: "mr-3 text-gray-400 hover:text-gray-600 cursor-move" do
                          svg_icon path_d: "M10 6h4v1H10V6zM10 8h4v1H10V8zM10 10h4v1H10v-1zM8 6H6v1h2V6zM8 8H6v1h2V8zM8 10H6v1h2v-1z",
                                   class: "w-4 h-4",
                                   viewBox: "0 0 20 20"
                        end
                        div class: "w-6 h-6 bg-orange-500 text-white text-xs rounded-full flex items-center justify-center mr-3 waypoint-position-badge" do
                          waypoint.position.to_s
                        end
                        div class: "flex-1" do
                          div class: "flex items-center mb-1" do
                            input type: "text",
                                  value: waypoint.name.presence || "Waypoint #{waypoint.position}",
                                  class: "waypoint-name-input text-sm font-medium text-gray-900 bg-transparent border-none outline-none focus:bg-white focus:border focus:border-blue-300 focus:rounded px-2 py-1 -ml-2",
                                  placeholder: "Waypoint name",
                                  maxlength: 100
                          end
                          div class: "text-xs text-gray-600 waypoint-coordinates" do
                            "#{waypoint.latitude.to_f.round(6)}, #{waypoint.longitude.to_f.round(6)}"
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            # Action buttons and form
            form_with url: update_route_waypoints_path(@route), method: :patch, local: true, class: "space-y-4" do |form|
              hidden_field_tag "waypoints", "", id: "waypoints-data"

              div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
                link_to "Cancel",
                        @road_trip,
                        class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"

                form.submit "Save Waypoints",
                            id: "save-waypoints",
                            class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              end
            end
          end
        end
      end
    end
  end

  private

  def existing_waypoints_json
    @waypoints.map do |waypoint|
      {
        id: waypoint.id,
        latitude: waypoint.latitude.to_f,
        longitude: waypoint.longitude.to_f,
        position: waypoint.position,
        name: waypoint.name.presence || "Waypoint #{waypoint.position}"
      }
    end.to_json
  end
end
