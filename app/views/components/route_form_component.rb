class RouteFormComponent < ApplicationComponent
  def initialize(trip:, route:, action: :new)
    @trip = trip
    @route = route
    @action = action
  end

  def view_template
    render LayoutComponent.new(title: title_text) do
      div(class: "max-w-2xl mx-auto") do
        div(class: "mb-4") do
          link_to "← Back to #{@trip.name}", trip_path(@trip), class: "text-blue-600 hover:text-blue-800"
        end
        
        h1(class: "text-3xl font-bold text-gray-900 mb-8") { title_text }
        
        form_with model: [@trip, @route], local: true, class: "space-y-6" do |form|
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Route Name" }
            input(
              type: "text",
              name: "route[name]",
              value: @route.name,
              required: true,
              class: "form-input"
            )
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Day Number" }
            input(
              type: "number",
              name: "route[day_number]",
              value: @route.day_number,
              required: true,
              min: 1,
              class: "form-input"
            )
          end
          
          div(class: "grid grid-cols-2 gap-4") do
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Total Distance (km)" }
              input(
                type: "number",
                name: "route[total_distance]",
                value: @route.total_distance,
                step: 0.1,
                class: "form-input"
              )
            end
            
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Estimated Duration (minutes)" }
              input(
                type: "number",
                name: "route[estimated_duration_minutes]",
                value: @route.estimated_duration_minutes,
                class: "form-input"
              )
            end
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Notes" }
            textarea(
              name: "route[notes]",
              rows: 3,
              class: "form-input"
            ) { @route.notes }
          end
          
          div(class: "flex space-x-4") do
            button(type: "submit", class: "btn btn-primary") { submit_text }
            link_to "Cancel", trip_path(@trip), class: "btn btn-secondary"
          end
        end
      end
    end
  end

  private

  def title_text
    @action == :edit ? "Edit Route" : "New Route"
  end

  def submit_text
    @action == :edit ? "Update Route" : "Create Route"
  end
end