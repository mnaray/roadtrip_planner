class RoadTrips::IndexComponent < ApplicationComponent
  def initialize(owned_road_trips:, participating_road_trips:, current_user:)
    @owned_road_trips = owned_road_trips
    @participating_road_trips = participating_road_trips
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "My Road Trips", current_user: @current_user) do
      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "flex justify-between items-center mb-8" do
          h1 class: "text-3xl font-bold text-gray-900" do
            "My Road Trips"
          end

          link_to new_road_trip_path,
                  class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors" do
            svg_icon path_d: "M12 4v16m8-8H4",
                     class: "w-5 h-5 mr-2",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            "New Road Trip"
          end
        end

        # My Road Trips Section
        if @owned_road_trips.any?
          div class: "mb-8" do
            h2 class: "text-xl font-semibold text-gray-900 mb-4" do
              "My Road Trips"
            end
            div class: "grid gap-6 md:grid-cols-2 lg:grid-cols-3" do
              @owned_road_trips.each do |road_trip|
                render_road_trip_card(road_trip, is_owner: true)
              end
            end
          end
        end

        # Participating Road Trips Section
        if @participating_road_trips.any?
          div class: "mb-8" do
            h2 class: "text-xl font-semibold text-gray-900 mb-4" do
              "Shared with Me"
            end
            div class: "grid gap-6 md:grid-cols-2 lg:grid-cols-3" do
              @participating_road_trips.each do |road_trip|
                render_road_trip_card(road_trip, is_owner: false)
              end
            end
          end
        end

        # Empty state
        unless @owned_road_trips.any? || @participating_road_trips.any?
          render_empty_state
        end
      end
    end
  end

  private

  def render_road_trip_card(road_trip, is_owner: true)
    link_to road_trip_path(road_trip),
            class: "block bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md hover:border-gray-300 transition-all duration-200 overflow-hidden" do
      div class: "p-6 overflow-hidden" do
        # Trip name and stats
        div class: "flex justify-between items-start mb-4 overflow-hidden" do
          h3 class: "text-lg font-semibold text-gray-900 truncate mr-4" do
            road_trip.name
          end

          div class: "flex space-x-2 flex-shrink-0" do
            unless is_owner
              span class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800" do
                "Shared"
              end
            end

            span class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800" do
              "#{road_trip.routes.count} routes"
            end

            span class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800" do
              "#{road_trip.participant_count} #{'participant'.pluralize(road_trip.participant_count)}"
            end
          end
        end

        # Trip metrics
        div class: "space-y-2" do
          div class: "flex items-center text-sm text-gray-600" do
            svg_icon path_d: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
                     class: "w-4 h-4 mr-2",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            "#{road_trip.day_count} #{'day'.pluralize(road_trip.day_count)}"
          end

          div class: "flex items-center text-sm text-gray-600" do
            svg_icon path_d: "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z",
                     class: "w-4 h-4 mr-2",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            "#{road_trip.total_distance} km"
          end
        end

        # Recent routes preview
        if road_trip.routes.any?
          div class: "mt-4 pt-4 border-t border-gray-100" do
            p class: "text-xs text-gray-500 mb-2" do
              "Latest routes:"
            end

            div class: "space-y-2 overflow-hidden" do
              road_trip.routes.ordered_by_datetime.limit(2).each do |route|
                div class: "flex items-center text-sm text-gray-700 leading-relaxed overflow-hidden" do
                  div class: "overflow-hidden max-w-[45%] flex-shrink-0" do
                    span class: "font-medium truncate block" do
                      route.starting_location
                    end
                  end
                  span class: "mx-2 text-gray-400 flex-shrink-0" do
                    "→"
                  end
                  div class: "overflow-hidden max-w-[45%] flex-shrink-0" do
                    span class: "font-medium truncate block" do
                      route.destination
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

  def render_empty_state
    div class: "text-center py-12" do
      svg_icon path_d: "M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z",
               class: "mx-auto h-12 w-12 text-gray-400",
               stroke_linecap: "round",
               stroke_linejoin: "round",
               stroke_width: "2"

      h3 class: "mt-4 text-lg font-medium text-gray-900" do
        "No road trips yet"
      end

      p class: "mt-2 text-sm text-gray-500" do
        "Get started by creating your first road trip adventure!"
      end

      div class: "mt-6" do
        link_to new_road_trip_path,
                class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
          "Create Road Trip"
        end
      end
    end
  end
end
