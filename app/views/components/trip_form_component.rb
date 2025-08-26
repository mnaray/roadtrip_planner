class TripFormComponent < ApplicationComponent
  def initialize(trip:, action: :new)
    @trip = trip
    @action = action
  end

  def view_template
    render LayoutComponent.new(title: title_text) do
      div(class: "max-w-2xl mx-auto") do
        h1(class: "text-3xl font-bold text-gray-900 mb-8") { title_text }
        
        form_with model: @trip, local: true, class: "space-y-6" do |form|
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Trip Name" }
            input(
              type: "text",
              name: "trip[name]",
              value: @trip.name,
              required: true,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            )
            render_error_for(:name)
          end
          
          div do
            label(class: "block text-sm font-medium text-gray-700 mb-2") { "Description" }
            textarea(
              name: "trip[description]",
              rows: 4,
              class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            ) { @trip.description }
            render_error_for(:description)
          end
          
          div(class: "grid grid-cols-2 gap-4") do
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "Start Date" }
              input(
                type: "date",
                name: "trip[start_date]",
                value: @trip.start_date&.strftime("%Y-%m-%d"),
                required: true,
                class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              )
              render_error_for(:start_date)
            end
            
            div do
              label(class: "block text-sm font-medium text-gray-700 mb-2") { "End Date" }
              input(
                type: "date",
                name: "trip[end_date]",
                value: @trip.end_date&.strftime("%Y-%m-%d"),
                required: true,
                class: "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              )
              render_error_for(:end_date)
            end
          end
          
          div(class: "flex space-x-4") do
            button(
              type: "submit",
              class: "bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            ) { submit_text }
            
            link_to "Cancel", trips_path, 
                    class: "bg-gray-300 text-gray-700 px-6 py-2 rounded-md hover:bg-gray-400"
          end
        end
      end
    end
  end

  private

  def title_text
    @action == :edit ? "Edit Trip" : "New Trip"
  end

  def submit_text
    @action == :edit ? "Update Trip" : "Create Trip"
  end

  def render_error_for(field)
    return unless @trip.errors[field].any?
    
    div(class: "mt-1 text-sm text-red-600") do
      @trip.errors[field].first
    end
  end
end