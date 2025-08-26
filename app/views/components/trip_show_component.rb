class TripShowComponent < ApplicationComponent
  def initialize(trip:, routes:)
    @trip = trip
    @routes = routes
  end

  def view_template
    render LayoutComponent.new(title: @trip.name) do
      div(class: "space-y-8") do
        # Trip header
        div(class: "bg-white rounded-lg shadow-md p-6") do
          div(class: "flex justify-between items-start") do
            div do
              h1(class: "text-3xl font-bold text-gray-900") { @trip.name }
              if @trip.description.present?
                p(class: "mt-2 text-gray-600") { @trip.description }
              end
              p(class: "mt-2 text-sm text-gray-500") do
                "#{@trip.start_date.strftime('%B %d')} - #{@trip.end_date.strftime('%B %d, %Y')}"
              end
            end
            
            div(class: "flex space-x-2") do
              link_to "Edit Trip", edit_trip_path(@trip), 
                      class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
              link_to "Add Route", new_trip_route_path(@trip), 
                      class: "bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
            end
          end
        end
        
        # Routes section
        div do
          h2(class: "text-2xl font-bold text-gray-900 mb-6") { "Daily Routes" }
          
          if @routes.any?
            div(class: "space-y-4") do
              @routes.each do |route|
                render RouteCardComponent.new(trip: @trip, route: route)
              end
            end
          else
            div(class: "text-center py-12 bg-white rounded-lg shadow-md") do
              div(class: "text-6xl mb-4") { "🛣️" }
              h3(class: "text-xl font-semibold text-gray-900 mb-2") { "No routes planned yet" }
              p(class: "text-gray-600 mb-6") { "Add your first route to start planning your journey!" }
              link_to "Add First Route", new_trip_route_path(@trip), 
                      class: "bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 inline-block"
            end
          end
        end
      end
    end
  end
end