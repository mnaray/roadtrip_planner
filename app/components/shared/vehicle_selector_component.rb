class Shared::VehicleSelectorComponent < ApplicationComponent
  def initialize(form:, user:, selected_vehicle: nil, field_name: :vehicle_id)
    @form = form
    @user = user
    @selected_vehicle = selected_vehicle
    @field_name = field_name
  end

  def view_template
    return render_no_vehicles_message unless @user.has_vehicles?

    div class: "space-y-3" do
      @form.label @field_name, class: "block text-sm font-medium text-gray-700" do
        "Vehicle Selection"
      end

      @form.select @field_name,
                   options_for_select(vehicle_options, selected_value),
                   { prompt: "Select a vehicle (optional)" },
                   class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"

      p class: "text-xs text-gray-500" do
        "Choose which vehicle you'll be using for this trip. This helps with fuel economy calculations."
      end

      # Link to add vehicles if user has few vehicles
      if @user.vehicles.count < 3
        div class: "mt-2" do
          link_to new_vehicle_path,
                  target: "_blank",
                  class: "text-sm text-blue-600 hover:text-blue-500 font-medium" do
            svg_icon path_d: "M12 4v16m8-8H4",
                     class: "w-4 h-4 inline mr-1",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Add another vehicle to your garage" }
          end
        end
      end
    end
  end

  private

  def render_no_vehicles_message
    div class: "bg-blue-50 border border-blue-200 rounded-md p-4" do
      div class: "flex items-start" do
        svg_icon path_d: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                 class: "h-5 w-5 text-blue-400 mt-0.5 mr-3 flex-shrink-0",
                 fill: "currentColor"
        div do
          h4 class: "text-sm font-medium text-blue-800 mb-2" do
            "No vehicles in your garage"
          end
          p class: "text-sm text-blue-700 mb-3" do
            "Add vehicles to your garage to enable fuel economy calculations and better trip planning."
          end
          link_to new_vehicle_path,
                  target: "_blank",
                  class: "inline-flex items-center px-3 py-2 border border-transparent text-xs font-medium rounded text-blue-700 bg-blue-100 hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
            svg_icon path_d: "M12 4v16m8-8H4",
                     class: "w-4 h-4 mr-1",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Add your first vehicle" }
          end
        end
      end
    end
  end

  def vehicle_options
    @user.vehicles.order(:name).map do |vehicle|
      display_text = vehicle.display_name
      display_text += " (#{vehicle.make_model})" if vehicle.make_model.present?
      display_text += " - Default" if vehicle.is_default?
      [display_text, vehicle.id]
    end
  end

  def selected_value
    return @selected_vehicle.id if @selected_vehicle
    return @user.default_vehicle.id if @user.default_vehicle
    nil
  end
end