class RoadTrips::ShowComponent < ApplicationComponent
  def initialize(road_trip:, routes:, current_user:)
    @road_trip = road_trip
    @routes = routes
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: @road_trip.name, current_user: @current_user) do
      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "flex justify-between items-start mb-8" do
          div do
            # Breadcrumb
            nav class: "flex mb-4", aria_label: "Breadcrumb" do
              ol class: "flex items-center space-x-4" do
                li do
                  link_to road_trips_path, class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
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
                li class: "text-sm font-medium text-gray-900" do
                  @road_trip.name
                end
              end
            end

            h1 class: "text-3xl font-bold text-gray-900" do
              @road_trip.name
            end
          end

          div class: "flex items-center space-x-3" do
            link_to edit_road_trip_path(@road_trip),
                    class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
              svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                       class: "w-4 h-4 mr-1.5",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              "Edit"
            end

            link_to new_road_trip_route_path(@road_trip),
                    class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
              svg_icon path_d: "M12 4v16m8-8H4",
                       class: "w-4 h-4 mr-1.5",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              "Add Route"
            end
          end
        end

        # Trip summary
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8" do
          div class: "grid grid-cols-1 md:grid-cols-3 gap-6" do
            div class: "text-center" do
              div class: "text-2xl font-bold text-blue-600" do
                @routes.count.to_s
              end
              div class: "text-sm text-gray-600" do
                "Routes"
              end
            end

            div class: "text-center" do
              div class: "text-2xl font-bold text-green-600" do
                "#{@road_trip.total_distance} km"
              end
              div class: "text-sm text-gray-600" do
                "Total Distance"
              end
            end

            div class: "text-center" do
              div class: "text-2xl font-bold text-purple-600" do
                @road_trip.day_count.to_s
              end
              div class: "text-sm text-gray-600" do
                "#{'Day'.pluralize(@road_trip.day_count)}"
              end
            end
          end
        end

        # Routes list
        div class: "bg-white rounded-lg shadow-sm border border-gray-200" do
          div class: "px-6 py-4 border-b border-gray-200" do
            h2 class: "text-lg font-semibold text-gray-900" do
              "Routes"
            end
          end

          if @routes.any?
            @routes.each_with_index do |route, index|
              is_last = index == @routes.length - 1
              render_route_row(route, index + 1, is_last)
            end
          else
            div class: "p-12 text-center" do
              svg_icon path_d: "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z",
                       class: "mx-auto h-12 w-12 text-gray-400",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"

              h3 class: "mt-4 text-lg font-medium text-gray-900" do
                "No routes yet"
              end

              p class: "mt-2 text-sm text-gray-500" do
                "Add your first route to get started with this road trip."
              end

              div class: "mt-6" do
                link_to new_road_trip_route_path(@road_trip),
                        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700",
                        data: { "turbo-frame": "modal" } do
                  "Add First Route"
                end
              end
            end
          end
        end
      end

      # Removed modal frame - using dedicated pages instead
    end
  end

  private

  def render_route_row(route, sequence, is_last = false)
    border_class = is_last ? "" : "border-b border-gray-200"
    div class: "#{border_class}" do
      div class: "flex items-center justify-between" do
        # Main clickable area for route content
        link_to route_map_path(route), class: "flex items-center space-x-4 flex-1 p-6 hover:bg-gray-50 no-underline text-inherit transition-colors" do
          # Sequence number
          div class: "flex-shrink-0" do
            span class: "inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-600 text-sm font-medium" do
              sequence.to_s
            end
          end

          # Route details
          div class: "flex-1 min-w-0" do
            div class: "flex items-center space-x-2 mb-1" do
              span class: "text-sm font-semibold text-gray-900 truncate" do
                route.starting_location
              end
              svg_icon path_d: "M17 8l4 4m0 0l-4 4m4-4H3",
                       class: "w-4 h-4 text-gray-400",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              span class: "text-sm font-semibold text-gray-900 truncate" do
                route.destination
              end
            end

            div class: "flex items-center text-xs text-gray-500" do
              svg_icon path_d: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
                       class: "w-3 h-3 mr-1",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              route.datetime.strftime("%B %d, %Y at %l:%M %p")
            end
          end
        end

        # Actions - separate from main clickable area
        div class: "flex items-center space-x-2 px-6 py-6" do
          link_to edit_route_path(route),
                  class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-gray-600" do
            svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                     class: "w-4 h-4",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
          end

          link_to route_path(route),
                  method: :delete,
                  class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-red-600",
                  data: { confirm: "Are you sure you want to delete this route?" } do
            svg_icon path_d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                     class: "w-4 h-4",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
          end
        end
      end
    end
  end
end
