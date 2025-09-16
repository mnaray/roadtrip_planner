class Vehicles::EditComponent < ApplicationComponent
  def initialize(vehicle:, current_user:)
    @vehicle = vehicle
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Edit #{@vehicle.display_name}", current_user: @current_user) do
      div class: "max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
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
                "Edit #{@vehicle.display_name}"
              end
            end
          end

          h1 class: "text-3xl font-bold text-gray-900" do
            "Edit #{@vehicle.display_name}"
          end

          p class: "mt-2 text-sm text-gray-600" do
            "Update your vehicle information and specifications."
          end
        end

        # Form
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
          form_with model: @vehicle, local: true, class: "space-y-6" do |form|
            render_basic_info_section(form)
            render_stats_section(form)
            render_form_buttons(form)
          end
        end
      end
    end
  end

  private

  def render_basic_info_section(form)
    div class: "space-y-6" do
      # Vehicle name
      div do
        form.label :name, class: "block text-sm font-medium text-gray-700 mb-2" do
          "Vehicle Name *"
        end
        form.text_field :name,
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                        required: true
        render_field_error(:name)
      end

      # Vehicle type
      div do
        form.label :vehicle_type, class: "block text-sm font-medium text-gray-700 mb-2" do
          "Vehicle Type *"
        end
        form.select :vehicle_type,
                    Vehicle::VEHICLE_TYPES.map { |type| [type.capitalize, type] },
                    {},
                    class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                    required: true
        render_field_error(:vehicle_type)
      end

      # Make and model
      div do
        form.label :make_model, class: "block text-sm font-medium text-gray-700 mb-2" do
          "Make and Model"
        end
        form.text_field :make_model,
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
        render_field_error(:make_model)
      end

      # Current image display
      if @vehicle.image.attached?
        div do
          label class: "block text-sm font-medium text-gray-700 mb-2" do
            "Current Image"
          end
          div class: "mb-2" do
            # TODO: Replace with actual image display once Active Storage is configured
            p class: "text-sm text-gray-600" do
              "Current image: #{@vehicle.image.filename}"
            end
          end
        end
      end

      # Image upload
      div do
        form.label :image, class: "block text-sm font-medium text-gray-700 mb-2" do
          @vehicle.image.attached? ? "Replace Image" : "Vehicle Image"
        end
        form.file_field :image,
                        class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                        accept: "image/*"
        render_field_error(:image)
        p class: "mt-1 text-xs text-gray-500" do
          @vehicle.image.attached? ? "Leave empty to keep current image" : "Optional: Upload a photo of your vehicle"
        end
      end
    end
  end

  def render_stats_section(form)
    div class: "border-t border-gray-200 pt-6" do
      h3 class: "text-lg font-medium text-gray-900 mb-4" do
        "Vehicle Statistics"
      end
      p class: "text-sm text-gray-600 mb-6" do
        "All fields in this section are optional but help with fuel economy calculations and trip planning."
      end

      div class: "grid grid-cols-1 md:grid-cols-2 gap-6" do
        # Engine volume
        div do
          form.label :engine_volume_ccm, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Engine Volume (ccm)"
          end
          form.number_field :engine_volume_ccm,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            min: 1
          render_field_error(:engine_volume_ccm)
        end

        # Horsepower
        div do
          form.label :horsepower, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Horsepower (HP)"
          end
          form.number_field :horsepower,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            min: 1
          render_field_error(:horsepower)
        end

        # Torque
        div do
          form.label :torque, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Torque (Nm)"
          end
          form.number_field :torque,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            min: 1
          render_field_error(:torque)
        end

        # Fuel consumption
        div do
          form.label :fuel_consumption, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Fuel Consumption (L/100km)"
          end
          form.number_field :fuel_consumption,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            step: 0.1,
                            min: 0.1
          render_field_error(:fuel_consumption)
          p class: "mt-1 text-xs text-gray-500" do
            "Used for fuel economy calculations"
          end
        end

        # Dry weight
        div do
          form.label :dry_weight, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Dry Weight (kg)"
          end
          form.number_field :dry_weight,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            step: 0.1,
                            min: 0.1
          render_field_error(:dry_weight)
        end

        # Wet weight
        div do
          form.label :wet_weight, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Wet Weight (kg)"
          end
          form.number_field :wet_weight,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            step: 0.1,
                            min: 0.1
          render_field_error(:wet_weight)
        end

        # Passenger count
        div do
          form.label :passenger_count, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Passenger Count"
          end
          form.number_field :passenger_count,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            min: 1
          render_field_error(:passenger_count)
        end

        # Load capacity
        div do
          form.label :load_capacity, class: "block text-sm font-medium text-gray-700 mb-2" do
            "Load Capacity (kg)"
          end
          form.number_field :load_capacity,
                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                            step: 0.1,
                            min: 0.1
          render_field_error(:load_capacity)
        end
      end
    end
  end

  def render_form_buttons(form)
    div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
      div class: "flex space-x-3" do
        link_to garage_path,
                class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
          "Cancel"
        end

        link_to @vehicle,
                class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
          "View Details"
        end
      end

      form.submit "Update Vehicle",
                  class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
    end
  end

  def render_field_error(field)
    return unless @vehicle.errors[field].any?

    div class: "mt-1 text-sm text-red-600" do
      @vehicle.errors[field].first
    end
  end
end