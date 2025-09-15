class Routes::MapComponent < ApplicationComponent
  def initialize(route:, current_user:)
    @route = route
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Route Map", current_user: @current_user) do
      # Leaflet is loaded via importmap and layout

      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "flex justify-between items-start mb-6" do
          div do
            # Breadcrumb
            nav class: "flex mb-2", aria_label: "Breadcrumb" do
              ol class: "flex items-center space-x-4 text-sm" do
                li do
                  link_to road_trips_path, class: "text-blue-600 hover:text-blue-800 font-medium" do
                    "My Road Trips"
                  end
                end
                li do
                  svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                           class: "w-4 h-4 text-gray-400",
                           fill: "currentColor",
                           fill_rule: "evenodd",
                           clip_rule: "evenodd",
                           viewBox: "0 0 20 20"
                end
                li do
                  link_to road_trip_path(@route.road_trip), class: "text-blue-600 hover:text-blue-800 font-medium" do
                    @route.road_trip.name
                  end
                end
                li do
                  svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                           class: "w-4 h-4 text-gray-400",
                           fill: "currentColor",
                           fill_rule: "evenodd",
                           clip_rule: "evenodd",
                           viewBox: "0 0 20 20"
                end
                li class: "text-gray-900 font-medium" do
                  "Route Map"
                end
              end
            end

            h1 class: "text-2xl font-bold text-gray-900" do
              "#{@route.starting_location} → #{@route.destination}"
            end

            p class: "text-sm text-gray-600 mt-1" do
              @route.datetime.strftime("%B %d, %Y at %l:%M %p")
            end
          end

          link_to @route.road_trip,
                  class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
            svg_icon path_d: "M7 16l-4-4m0 0l4-4m-4 4h18",
                     class: "w-4 h-4 mr-1.5",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Back to Road Trip" }
          end
        end

        # Map container
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden" do
          div id: "route-map",
               class: "w-full h-96",
               data: {
                 controller: "route-map",
                 route_map_start_location_value: @route.starting_location,
                 route_map_end_location_value: @route.destination,
                 route_map_waypoints_value: waypoints_json,
                 route_map_avoid_motorways_value: @route.avoid_motorways
               } do
            # Map will be rendered here by Stimulus controller
          end
        end

        # Route information
        div class: "mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
          h2 class: "text-lg font-semibold text-gray-900 mb-4" do
            "Route Information"
          end

          div class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6" do
            div do
              h3 class: "text-sm font-medium text-gray-500 mb-1" do
                "Starting Point"
              end
              p class: "text-lg font-semibold text-gray-900" do
                @route.starting_location
              end
            end

            div do
              h3 class: "text-sm font-medium text-gray-500 mb-1" do
                "Destination"
              end
              p class: "text-lg font-semibold text-gray-900" do
                @route.destination
              end
            end

            div do
              h3 class: "text-sm font-medium text-gray-500 mb-1" do
                "Scheduled Time"
              end
              p class: "text-lg font-semibold text-gray-900" do
                @route.datetime.strftime("%l:%M %p")
              end
              p class: "text-sm text-gray-600" do
                @route.datetime.strftime("%B %d, %Y")
              end
            end

            div do
              h3 class: "text-sm font-medium text-gray-500 mb-1" do
                "Duration"
              end
              p class: "text-lg font-semibold text-gray-900" do
                if @route.current_duration_hours < 1
                  "#{(@route.current_duration_hours * 60).round} minutes"
                else
                  "#{@route.current_duration_hours.round(1)} hours"
                end
              end
              p class: "text-sm text-gray-600" do
                "Travel time"
              end
            end
          end

          # Actions
          div class: "mt-6 pt-6 border-t border-gray-200 flex items-center justify-between" do
            div class: "flex items-center space-x-3" do
              link_to edit_route_path(@route),
                      class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Edit Route" }
              end

              link_to route_export_gpx_path(@route),
                      class: "inline-flex items-center px-3 py-2 border border-green-300 text-sm font-medium rounded-md text-green-700 bg-white hover:bg-green-50 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2" do
                svg_icon path_d: "M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Download GPX" }
              end

              link_to route_fuel_economy_path(@route),
                      class: "inline-flex items-center px-3 py-2 border border-purple-300 text-sm font-medium rounded-md text-purple-700 bg-white hover:bg-purple-50 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2" do
                svg_icon path_d: "M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Fuel Economy" }
              end

              button_to route_path(@route),
                        method: :delete,
                        class: "inline-flex items-center px-3 py-2 border border-red-300 text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2",
                        data: { turbo_confirm: "Are you sure you want to delete this route?" },
                        form: { class: "inline" } do
                svg_icon path_d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Delete Route" }
              end
            end

            p class: "text-xs text-gray-500" do
              "Click and drag on the map to explore the route"
            end
          end
        end
      end

      # Note: Map is handled by the route-map Stimulus controller
    end
  end

  private

  def waypoints_json
    @route.waypoints.order(:position).map do |waypoint|
      {
        latitude: waypoint.latitude.to_f,
        longitude: waypoint.longitude.to_f,
        position: waypoint.position
      }
    end.to_json
  end
end
