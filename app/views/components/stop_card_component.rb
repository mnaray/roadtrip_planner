class StopCardComponent < ApplicationComponent
  def initialize(trip:, route:, stop:, index:)
    @trip = trip
    @route = route
    @stop = stop
    @index = index
  end

  def view_template
    div(class: "bg-white rounded-lg shadow-md p-6") do
      div(class: "flex items-start justify-between") do
        div(class: "flex items-start space-x-4") do
          # Stop number
          div(class: "flex-shrink-0") do
            div(class: "w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-semibold") do
              @index + 1
            end
          end
          
          # Stop details
          div(class: "flex-1") do
            h3(class: "text-lg font-semibold text-gray-900") { @stop.name }
            if @stop.address.present?
              p(class: "text-gray-600 text-sm") { @stop.address }
            end
            p(class: "text-gray-500 text-xs mt-1") do
              "#{@stop.latitude}, #{@stop.longitude}"
            end
            
            if @stop.notes.present?
              p(class: "mt-2 text-gray-600 text-sm") { @stop.notes }
            end
            
            if @stop.arrival_time || @stop.departure_time
              div(class: "mt-2 flex space-x-4 text-xs text-gray-500") do
                if @stop.arrival_time
                  span { "Arrive: #{@stop.arrival_time.strftime('%H:%M')}" }
                end
                if @stop.departure_time
                  span { "Depart: #{@stop.departure_time.strftime('%H:%M')}" }
                end
              end
            end
          end
        end
        
        # Actions
        div(class: "flex space-x-2") do
          link_to "Edit", edit_trip_route_stop_path(@trip, @route, @stop), 
                  class: "text-blue-600 hover:text-blue-800 text-sm"
          button_to "Delete", trip_route_stop_path(@trip, @route, @stop), 
                    method: :delete,
                    confirm: "Are you sure?",
                    class: "text-red-600 hover:text-red-800 text-sm"
        end
      end
    end
  end
end