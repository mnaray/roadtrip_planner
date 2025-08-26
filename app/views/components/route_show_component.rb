class RouteShowComponent < ApplicationComponent
  def initialize(trip:, route:, stops:)
    @trip = trip
    @route = route
    @stops = stops
  end

  def view_template
    render LayoutComponent.new(title: "#{@route.name} - Day #{@route.day_number}") do
      div(class: "space-y-8") do
        # Breadcrumb
        div(class: "mb-4") do
          link_to "← Back to #{@trip.name}", trip_path(@trip), class: "text-blue-600 hover:text-blue-800"
        end
        
        # Route header
        div(class: "bg-white rounded-lg shadow-md p-6") do
          div(class: "flex justify-between items-start") do
            div do
              h1(class: "text-3xl font-bold text-gray-900") { @route.name }
              p(class: "text-gray-600") { "Day #{@route.day_number} of #{@trip.name}" }
              if @route.notes.present?
                p(class: "mt-2 text-gray-600") { @route.notes }
              end
            end
            
            div(class: "flex space-x-2") do
              link_to "Edit Route", edit_trip_route_path(@trip, @route), class: "btn btn-primary"
              link_to "Add Stop", new_trip_route_stop_path(@trip, @route), class: "btn btn-success"
              if @stops.any?
                link_to "Export GPX", export_gpx_trip_route_path(@trip, @route, format: :gpx), class: "btn btn-secondary"
              end
            end
          end
          
          if @route.total_distance || @route.estimated_duration_minutes
            div(class: "mt-4 flex space-x-4 text-sm text-gray-600") do
              if @route.total_distance
                span(class: "bg-blue-100 text-blue-800 px-2 py-1 rounded") { "#{@route.total_distance} km" }
              end
              if @route.estimated_duration_minutes
                hours = @route.estimated_duration_minutes / 60
                minutes = @route.estimated_duration_minutes % 60
                span(class: "bg-green-100 text-green-800 px-2 py-1 rounded") { "#{hours}h #{minutes}m" }
              end
            end
          end
        end
        
        # Stops section
        div do
          div(class: "flex justify-between items-center mb-6") do
            h2(class: "text-2xl font-bold text-gray-900") { "Stops" }
            span(class: "text-gray-500") { "#{@stops.count} stops planned" }
          end
          
          if @stops.any?
            div(class: "space-y-4") do
              @stops.each_with_index do |stop, index|
                render StopCardComponent.new(trip: @trip, route: @route, stop: stop, index: index)
              end
            end
          else
            div(class: "text-center py-12 bg-white rounded-lg shadow-md") do
              div(class: "text-6xl mb-4") { "📍" }
              h3(class: "text-xl font-semibold text-gray-900 mb-2") { "No stops added yet" }
              p(class: "text-gray-600 mb-6") { "Add your first stop to start building this route!" }
              link_to "Add First Stop", new_trip_route_stop_path(@trip, @route), 
                      class: "bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 inline-block"
            end
          end
        end
      end
    end
  end
end