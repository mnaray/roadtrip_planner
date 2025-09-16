class Vehicles::ShowComponent < ApplicationComponent
  def initialize(vehicle:, current_user:)
    @vehicle = vehicle
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: @vehicle.display_name, current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "mb-8" do
          # Breadcrumb
          nav class: "flex mb-4", aria_label: "Breadcrumb" do
            ol class: "flex items-center space-x-4" do
              li do
                link_to garage_path, class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  "My Garage"
                end
              end
              li do
                svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                         class: "w-4 h-4 text-gray-400",
                         fill: "currentColor",
                         fill_rule: "evenodd",
                         clip_rule: "evenodd",
                         viewBox: "0 0 20 20"
              end
              li class: "text-sm font-medium text-gray-900" do
                @vehicle.display_name
              end
            end
          end

          div class: "flex justify-between items-start" do
            div do
              h1 class: "text-3xl font-bold text-gray-900" do
                @vehicle.display_name
              end

              if @vehicle.make_model.present?
                p class: "mt-2 text-lg text-gray-600" do
                  @vehicle.make_model
                end
              end

              div class: "flex items-center space-x-3 mt-4" do
                if @vehicle.is_default?
                  span class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800" do
                    svg_icon path_d: "M5 13l4 4L19 7",
                             class: "w-4 h-4 mr-1",
                             stroke_linecap: "round",
                             stroke_linejoin: "round",
                             stroke_width: "2"
                    span { "Default Vehicle" }
                  end
                end

                span class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800" do
                  @vehicle.vehicle_type.capitalize
                end
              end
            end

            div class: "flex space-x-3" do
              link_to edit_vehicle_path(@vehicle),
                      class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors" do
                svg_icon path_d: "M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7",
                         class: "w-4 h-4 mr-2",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Edit" }
              end

              unless @vehicle.is_default?
                link_to set_default_vehicle_path(@vehicle),
                        method: :patch,
                        class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors" do
                  svg_icon path_d: "M5 13l4 4L19 7",
                           class: "w-4 h-4 mr-2",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "2"
                  span { "Set as Default" }
                end
              end
            end
          end
        end

        div class: "grid grid-cols-1 lg:grid-cols-3 gap-8" do
          # Main content - left side
          div class: "lg:col-span-2 space-y-8" do
            # Vehicle image
            div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
              h2 class: "text-lg font-medium text-gray-900 mb-4" do
                "Vehicle Image"
              end

              if @vehicle.image.attached?
                # TODO: Replace with actual image display once Active Storage is configured
                div class: "bg-gray-100 rounded-lg flex items-center justify-center h-64" do
                  p class: "text-gray-600" do
                    "Image: #{@vehicle.image.filename}"
                  end
                end
              else
                div class: "bg-gray-100 rounded-lg flex items-center justify-center h-64" do
                  div class: "text-center" do
                    svg_icon path_d: vehicle_icon_path(@vehicle.vehicle_type),
                             class: "h-20 w-20 text-gray-400 mx-auto mb-4"
                    p class: "text-gray-500" do
                      "No image uploaded"
                    end
                    link_to edit_vehicle_path(@vehicle),
                            class: "text-blue-600 hover:text-blue-500 text-sm font-medium" do
                      "Add image"
                    end
                  end
                end
              end
            end

            # Vehicle statistics
            render_vehicle_stats
          end

          # Sidebar - right side
          div class: "space-y-6" do
            # Quick actions
            render_quick_actions

            # Usage summary (placeholder for future enhancement)
            render_usage_summary
          end
        end
      end
    end
  end

  private

  def render_vehicle_stats
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
      h2 class: "text-lg font-medium text-gray-900 mb-6" do
        "Vehicle Specifications"
      end

      div class: "grid grid-cols-1 md:grid-cols-2 gap-6" do
        render_stat_item("Engine Volume", format_ccm(@vehicle.engine_volume_ccm), "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z")
        render_stat_item("Horsepower", format_hp(@vehicle.horsepower), "M13 2L3 14h9l-1 8 10-12h-9l1-8z")
        render_stat_item("Torque", format_nm(@vehicle.torque), "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z")
        render_stat_item("Fuel Consumption", format_fuel(@vehicle.fuel_consumption), "M16 4h.01M4 20h16l-4-6H4l-4 6zm4-10h8")
        render_stat_item("Dry Weight", format_kg(@vehicle.dry_weight), "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z")
        render_stat_item("Wet Weight", format_kg(@vehicle.wet_weight), "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z")
        render_stat_item("Passengers", format_count(@vehicle.passenger_count), "M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2")
        render_stat_item("Load Capacity", format_kg(@vehicle.load_capacity), "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z")
      end
    end
  end

  def render_stat_item(label, value, icon_path)
    return unless value.present?

    div class: "flex items-center space-x-3" do
      svg_icon path_d: icon_path,
               class: "w-5 h-5 text-gray-400",
               stroke_linecap: "round",
               stroke_linejoin: "round",
               stroke_width: "2"
      div do
        p class: "text-sm font-medium text-gray-900" do
          value
        end
        p class: "text-xs text-gray-500" do
          label
        end
      end
    end
  end

  def render_quick_actions
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
      h3 class: "text-lg font-medium text-gray-900 mb-4" do
        "Quick Actions"
      end

      div class: "space-y-3" do
        link_to edit_vehicle_path(@vehicle),
                class: "flex items-center w-full px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 rounded-md transition-colors" do
          svg_icon path_d: "M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7",
                   class: "w-4 h-4 mr-3 text-gray-400",
                   stroke_linecap: "round",
                   stroke_linejoin: "round",
                   stroke_width: "2"
          span { "Edit Vehicle" }
        end

        unless @vehicle.is_default?
          link_to set_default_vehicle_path(@vehicle),
                  method: :patch,
                  class: "flex items-center w-full px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 rounded-md transition-colors" do
            svg_icon path_d: "M5 13l4 4L19 7",
                     class: "w-4 h-4 mr-3 text-gray-400",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Set as Default" }
          end
        end

        div class: "border-t border-gray-200 pt-3" do
          link_to @vehicle,
                  method: :delete,
                  data: {
                    confirm: "Are you sure you want to delete #{@vehicle.display_name}? This action cannot be undone.",
                    turbo_method: :delete
                  },
                  class: "flex items-center w-full px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-md transition-colors" do
            svg_icon path_d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                     class: "w-4 h-4 mr-3",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
            span { "Delete Vehicle" }
          end
        end
      end
    end
  end

  def render_usage_summary
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
      h3 class: "text-lg font-medium text-gray-900 mb-4" do
        "Usage Summary"
      end

      p class: "text-sm text-gray-500 text-center py-4" do
        "Vehicle usage statistics will be available once you start using this vehicle in road trips."
      end
    end
  end

  # Formatting helpers
  def format_ccm(value)
    return nil unless value.present? && value > 0
    "#{value} ccm"
  end

  def format_hp(value)
    return nil unless value.present? && value > 0
    "#{value} HP"
  end

  def format_nm(value)
    return nil unless value.present? && value > 0
    "#{value} Nm"
  end

  def format_fuel(value)
    return nil unless value.present? && value > 0
    "#{value} L/100km"
  end

  def format_kg(value)
    return nil unless value.present? && value > 0
    "#{value} kg"
  end

  def format_count(value)
    return nil unless value.present? && value > 0
    value.to_s
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
