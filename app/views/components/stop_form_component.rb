class StopFormComponent < ApplicationComponent
  def initialize(trip:, route:, stop:, action: :new)
    @trip = trip
    @route = route
    @stop = stop
    @action = action
  end

  def view_template
    render LayoutComponent.new(title: title_text) do
      div(class: "max-w-2xl mx-auto") do
        div(class: "mb-4") do
          link_to "← Back to #{@route.name}", trip_route_path(@trip, @route), class: "text-blue-600 hover:text-blue-800"
        end
        
        h1(class: "text-3xl font-bold text-gray-900 mb-8") { title_text }
        
        form_with model: [@trip, @route, @stop], local: true, class: "space-y-6" do |form|
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Stop Name" }
            input(
              type: "text",
              name: "stop[name]",
              value: @stop.name,
              required: true,
              class: "form-input",
              placeholder: "e.g., Golden Gate Bridge, San Francisco"
            )
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Address" }
            input(
              type: "text",
              name: "stop[address]",
              value: @stop.address,
              class: "form-input",
              placeholder: "Full address or location description"
            )
          end
          
          div(class: "grid grid-cols-2 gap-4") do
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Latitude" }
              input(
                type: "number",
                name: "stop[latitude]",
                value: @stop.latitude,
                step: "any",
                required: true,
                class: "form-input",
                placeholder: "37.8199"
              )
            end
            
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Longitude" }
              input(
                type: "number",
                name: "stop[longitude]",
                value: @stop.longitude,
                step: "any",
                required: true,
                class: "form-input",
                placeholder: "-122.4783"
              )
            end
          end
          
          div(class: "grid grid-cols-2 gap-4") do
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Arrival Time" }
              input(
                type: "datetime-local",
                name: "stop[arrival_time]",
                value: datetime_local_value(@stop.arrival_time),
                class: "form-input"
              )
            end
            
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Departure Time" }
              input(
                type: "datetime-local",
                name: "stop[departure_time]",
                value: datetime_local_value(@stop.departure_time),
                class: "form-input"
              )
            end
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Stop Order" }
            input(
              type: "number",
              name: "stop[order]",
              value: @stop.order,
              min: 1,
              class: "form-input"
            )
            p(class: "mt-1 text-sm text-gray-500") { "Leave blank to automatically add at the end" }
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Notes" }
            textarea(
              name: "stop[notes]",
              rows: 3,
              class: "form-input",
              placeholder: "Any additional information about this stop..."
            ) { @stop.notes }
          end
          
          div(class: "flex space-x-4") do
            button(type: "submit", class: "btn btn-primary") { submit_text }
            link_to "Cancel", trip_route_path(@trip, @route), class: "btn btn-secondary"
          end
        end
        
        # Helper text
        div(class: "mt-8 p-4 bg-blue-50 rounded-lg") do
          h3(class: "text-sm font-medium text-blue-900 mb-2") { "💡 Tip: Finding coordinates" }
          p(class: "text-sm text-blue-700") do
            "You can find latitude and longitude coordinates by searching for a location on Google Maps, then right-clicking on the exact spot to copy the coordinates."
          end
        end
      end
    end
  end

  private

  def title_text
    @action == :edit ? "Edit Stop" : "Add Stop"
  end

  def submit_text
    @action == :edit ? "Update Stop" : "Add Stop"
  end

  def datetime_local_value(datetime)
    return nil unless datetime
    datetime.strftime("%Y-%m-%dT%H:%M")
  end
end