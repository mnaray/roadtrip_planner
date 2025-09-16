class Vehicles::IndexComponent < ApplicationComponent
  def initialize(vehicles:, default_vehicle:, current_user:)
    @vehicles = vehicles
    @default_vehicle = default_vehicle
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "My Garage", current_user: @current_user) do
      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "flex justify-between items-center mb-8" do
          h1 class: "text-3xl font-bold text-gray-900" do
            "My Garage"
          end

          link_to new_vehicle_path,
                  class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors" do
            svg_icon path_d: "M12 4v16m8-8H4",
                     class: "w-5 h-5 mr-2",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Add Vehicle" }
          end
        end

        if @vehicles.any?
          # Default vehicle notice
          if @default_vehicle
            div class: "mb-6 bg-blue-50 border-l-4 border-blue-400 p-4" do
              div class: "flex" do
                svg_icon path_d: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "h-5 w-5 text-blue-400 mr-3 flex-shrink-0 mt-0.5",
                         fill: "currentColor"
                div class: "ml-3" do
                  p class: "text-sm text-blue-700" do
                    span class: "font-medium" do
                      @default_vehicle.display_name
                    end
                    span { " is your default vehicle and will be automatically selected for new road trips." }
                  end
                end
              end
            end
          end

          # Vehicles grid
          div class: "grid gap-6 md:grid-cols-2 lg:grid-cols-3" do
            @vehicles.each do |vehicle|
              render_vehicle_card(vehicle, is_default: vehicle == @default_vehicle)
            end
          end
        else
          render_empty_state
        end
      end
    end
  end

  private

  def render_vehicle_card(vehicle, is_default: false)
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow duration-200 overflow-hidden" do
      # Image section
      div class: "aspect-w-16 aspect-h-9 bg-gray-100" do
        if vehicle.image.attached?
          img src: url_for(vehicle.image),
              class: "w-full h-48 object-cover",
              alt: "#{vehicle.display_name} image"
        else
          div class: "flex items-center justify-center h-48 text-gray-400" do
            svg_icon path_d: vehicle_icon_path(vehicle.vehicle_type),
                     class: "h-16 w-16"
          end
        end
      end

      div class: "p-6" do
        # Header with name and badges
        div class: "flex justify-between items-start mb-4" do
          div do
            h3 class: "text-lg font-semibold text-gray-900" do
              vehicle.display_name
            end
            if vehicle.make_model.present?
              p class: "text-sm text-gray-600 mt-1" do
                vehicle.make_model
              end
            end
          end

          div class: "flex flex-col space-y-2" do
            if is_default
              span class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800" do
                svg_icon path_d: "M5 13l4 4L19 7",
                         class: "w-3 h-3 mr-1",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Default" }
              end
            end

            span class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800" do
              vehicle.vehicle_type.capitalize
            end
          end
        end

        # Quick stats
        if vehicle.fuel_consumption.present? || vehicle.passenger_count.present?
          div class: "space-y-2 mb-4" do
            if vehicle.fuel_consumption.present?
              div class: "flex items-center text-sm text-gray-600" do
                svg_icon path_d: "M16 4h.01M4 20h16l-4-6H4l-4 6zm4-10h8",
                         class: "w-4 h-4 mr-2",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "#{vehicle.fuel_consumption}L/100km" }
              end
            end

            if vehicle.passenger_count.present?
              div class: "flex items-center text-sm text-gray-600" do
                svg_icon path_d: "M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2",
                         class: "w-4 h-4 mr-2",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "#{vehicle.passenger_count} passengers" }
              end
            end
          end
        end

        # Action buttons
        div class: "flex justify-between items-center" do
          div class: "flex space-x-2" do
            link_to edit_vehicle_path(vehicle),
                    class: "text-blue-600 hover:text-blue-500 text-sm font-medium" do
              span { "Edit" }
            end

            link_to vehicle_path(vehicle),
                    class: "text-green-600 hover:text-green-500 text-sm font-medium" do
              span { "View" }
            end
          end

          div class: "flex space-x-2" do
            unless is_default
              link_to set_default_vehicle_path(vehicle),
                      method: :patch,
                      class: "text-gray-600 hover:text-gray-500 text-sm font-medium" do
                span { "Set Default" }
              end
            end

            link_to vehicle_path(vehicle),
                    method: :delete,
                    data: {
                      confirm: "Are you sure you want to delete #{vehicle.display_name}?",
                      turbo_method: :delete
                    },
                    class: "text-red-600 hover:text-red-500 text-sm font-medium" do
              span { "Delete" }
            end
          end
        end
      end
    end
  end

  def render_empty_state
    div class: "text-center py-12" do
      svg_icon path_d: "M19 7h-3V6a4 4 0 00-8 0v1H5a1 1 0 00-1 1v11a3 3 0 003 3h10a3 3 0 003-3V8a1 1 0 00-1-1zM10 6a2 2 0 014 0v1h-4V6zm8 13a1 1 0 01-1 1H7a1 1 0 01-1-1V9h2v1a1 1 0 002 0V9h4v1a1 1 0 002 0V9h2v10z",
               class: "mx-auto h-12 w-12 text-gray-400",
               fill: "currentColor"

      h3 class: "mt-4 text-lg font-medium text-gray-900" do
        "No vehicles in your garage yet"
      end

      p class: "mt-2 text-sm text-gray-500" do
        "Add your first vehicle to start tracking fuel economy and vehicle details for your road trips."
      end

      div class: "mt-6" do
        link_to new_vehicle_path,
                class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
          span { "Add Your First Vehicle" }
        end
      end
    end
  end

  def vehicle_icon_path(vehicle_type)
    case vehicle_type
    when "car" then "M16 4h.01M4 20h16l-4-6H4l-4 6zm4-10h8"
    when "motorcycle" then "M5 21h14v-2a2 2 0 00-2-2H7a2 2 0 00-2 2v2zM12 7V3m0 0l-3 3m3-3l3 3"
    when "bicycle" then "M12 14l9-5-9-5-9 5 9 5zm0 7l-5.6-3.2a1 1 0 01-.4-.8V10l6 3.4 6-3.4v6.5a1 1 0 01-.4.8L12 21z"
    when "skateboard" then "M16 6l-4 14-4-14"
    when "scooter" then "M5 21h14v-2a2 2 0 00-2-2H7a2 2 0 00-2 2v2z"
    else "M3 21h18v-2H3v2zm3-18h12v12H6V3z"
    end
  end
end
