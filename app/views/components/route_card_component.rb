class RouteCardComponent < ApplicationComponent
  def initialize(trip:, route:)
    @trip = trip
    @route = route
  end

  def view_template
    div(class: "bg-white rounded-lg shadow-md p-6") do
      div(class: "flex justify-between items-start mb-4") do
        div do
          h3(class: "text-xl font-semibold text-gray-900") do
            link_to @route.name, trip_route_path(@trip, @route), class: "hover:text-blue-600"
          end
          p(class: "text-sm text-gray-500") { "Day #{@route.day_number}" }
          if @route.notes.present?
            p(class: "mt-1 text-gray-600 text-sm") { @route.notes }
          end
        end
        
        div(class: "flex space-x-2") do
          link_to "View", trip_route_path(@trip, @route), 
                  class: "text-blue-600 hover:text-blue-800 text-sm"
          link_to "Edit", edit_trip_route_path(@trip, @route), 
                  class: "text-gray-600 hover:text-gray-800 text-sm"
          if @route.stops.any?
            link_to "Export GPX", export_gpx_trip_route_path(@trip, @route, format: :gpx), 
                    class: "text-green-600 hover:text-green-800 text-sm"
          end
        end
      end
      
      if @route.stops.any?
        div(class: "space-y-2") do
          h4(class: "text-sm font-medium text-gray-700 mb-2") { "Stops (#{@route.stops.count})" }
          div(class: "flex flex-wrap gap-2") do
            @route.ordered_stops.limit(5).each do |stop|
              span(class: "inline-flex items-center px-2 py-1 rounded-full text-xs bg-blue-100 text-blue-800") do
                stop.name
              end
            end
            if @route.stops.count > 5
              span(class: "text-xs text-gray-500") { "+#{@route.stops.count - 5} more" }
            end
          end
        end
      else
        div(class: "text-gray-500 text-sm") do
          p { "No stops added yet" }
          link_to "Add stops", new_trip_route_stop_path(@trip, @route), 
                  class: "text-blue-600 hover:text-blue-800"
        end
      end
      
      if @route.total_distance || @route.estimated_duration_minutes
        div(class: "mt-4 flex space-x-4 text-sm text-gray-600") do
          if @route.total_distance
            span { "#{@route.total_distance} km" }
          end
          if @route.estimated_duration_minutes
            hours = @route.estimated_duration_minutes / 60
            minutes = @route.estimated_duration_minutes % 60
            span { "#{hours}h #{minutes}m" }
          end
        end
      end
    end
  end
end