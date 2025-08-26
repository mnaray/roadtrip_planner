class TripsIndexComponent < ApplicationComponent
  def initialize(trips:)
    @trips = trips
  end

  def view_template
    render LayoutComponent.new(title: "All Road Trips") do
      div(class: "space-y-6") do
        header(class: "text-center") do
          h1(class: "text-4xl font-bold text-gray-900") { "Your Road Trips" }
          p(class: "mt-2 text-gray-600") { "Plan amazing adventures with multiple routes and stops" }
        end
        
        if @trips.any?
          div(class: "grid gap-6 md:grid-cols-2 lg:grid-cols-3") do
            @trips.each do |trip|
              render TripCardComponent.new(trip: trip)
            end
          end
        else
          div(class: "text-center py-12") do
            div(class: "text-6xl mb-4") { "🗺️" }
            h2(class: "text-2xl font-semibold text-gray-900 mb-2") { "No trips yet" }
            p(class: "text-gray-600 mb-6") { "Start planning your first road trip adventure!" }
            link_to "Create Your First Trip", new_trip_path, 
                    class: "bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 inline-block"
          end
        end
      end
    end
  end
end