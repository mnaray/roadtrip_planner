class TripCardComponent < ApplicationComponent
  def initialize(trip:)
    @trip = trip
  end

  def view_template
    div(class: "bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow") do
      div(class: "flex justify-between items-start mb-4") do
        h3(class: "text-xl font-semibold text-gray-900") do
          link_to @trip.name, trip_path(@trip), class: "hover:text-blue-600"
        end
        div(class: "text-sm text-gray-500") do
          duration_text
        end
      end
      
      if @trip.description.present?
        p(class: "text-gray-600 mb-4") { truncate(@trip.description, length: 100) }
      end
      
      div(class: "flex justify-between items-center text-sm text-gray-500 mb-4") do
        span { "#{@trip.start_date.strftime('%b %d')} - #{@trip.end_date.strftime('%b %d, %Y')}" }
        span { "#{@trip.routes.count} #{'route'.pluralize(@trip.routes.count)}" }
      end
      
      div(class: "flex space-x-2") do
        link_to "View", trip_path(@trip), 
                class: "flex-1 text-center bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700"
        link_to "Edit", edit_trip_path(@trip), 
                class: "flex-1 text-center bg-gray-300 text-gray-700 py-2 px-4 rounded hover:bg-gray-400"
      end
    end
  end

  private

  def duration_text
    days = (@trip.end_date - @trip.start_date).to_i + 1
    "#{days} #{'day'.pluralize(days)}"
  end
  
  def truncate(text, length:)
    return text if text.length <= length
    "#{text[0...length]}..."
  end
end