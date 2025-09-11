class Routes::FormPageComponent < ApplicationComponent
  def initialize(route:, road_trip:, current_user:)
    @route = route
    @road_trip = road_trip
    @current_user = current_user
    @is_edit_mode = @route.persisted?
  end

  def view_template
    div class: "min-h-screen bg-gray-100" do
      # Navigation
      nav class: "bg-white shadow mb-8" do
        div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" do
          div class: "flex justify-between items-center h-16" do
            div class: "flex items-center" do
              link_to road_trips_path, class: "text-gray-600 hover:text-gray-900 mr-4" do
                "← Back to Road Trips"
              end
              span class: "text-gray-400" do
                "/"
              end
              link_to @road_trip, class: "text-gray-600 hover:text-gray-900 ml-4" do
                @road_trip.name
              end
            end

            if @current_user
              div class: "flex items-center space-x-4" do
                span class: "text-gray-700" do
                  "Logged in as #{@current_user.username}"
                end
                link_to "Logout", logout_path, method: :delete,
                        class: "text-red-600 hover:text-red-900 font-medium"
              end
            end
          end
        end
      end

      # Main content
      div class: "max-w-3xl mx-auto px-4 sm:px-6 lg:px-8" do
        div class: "bg-white shadow rounded-lg p-6" do
          # Form header
          h1 class: "text-2xl font-bold text-gray-900 mb-6" do
            if @is_edit_mode
              "Edit Route"
            else
              "Add New Route to #{@road_trip.name}"
            end
          end

          # Form
          if @is_edit_mode
            form_with model: @route,
                      local: true,
                      class: "space-y-6" do |form|
            # Starting Location
            div do
              form.label :starting_location,
                         class: "block text-sm font-medium text-gray-700 mb-2" do
                "Starting Location"
              end

              form.text_field :starting_location,
                              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                              placeholder: "e.g., San Francisco, CA",
                              required: true,
                              autofocus: !@is_edit_mode

              if @route.errors[:starting_location].any?
                div class: "mt-1 text-sm text-red-600" do
                  @route.errors[:starting_location].first
                end
              end
            end

            # Destination
            div do
              form.label :destination,
                         class: "block text-sm font-medium text-gray-700 mb-2" do
                "Destination"
              end

              form.text_field :destination,
                              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                              placeholder: "e.g., Los Angeles, CA",
                              required: true

              if @route.errors[:destination].any?
                div class: "mt-1 text-sm text-red-600" do
                  @route.errors[:destination].first
                end
              end
            end

            # Date & Time (only for edit mode)
            if @is_edit_mode
              render Shared::DateInputComponent.new(
                form: form,
                field: :datetime,
                label: "Date & Time",
                required: true
              )
            end

              # Form actions
              div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
              link_to @road_trip,
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                "Cancel"
              end

              form.submit(
                (@is_edit_mode ? "Update Route" : "Preview Route on Map"),
                class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
              )
              end
            end
          else
            form_with model: [ @road_trip, @route ],
                      local: true,
                      class: "space-y-6" do |form|
              # Same form fields for new route (non-edit mode)
              # Starting Location
              div do
                form.label :starting_location,
                           class: "block text-sm font-medium text-gray-700 mb-2" do
                  "Starting Location"
                end

                form.text_field :starting_location,
                                class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                                placeholder: "e.g., San Francisco, CA",
                                required: true,
                                autofocus: !@is_edit_mode

                if @route.errors[:starting_location].any?
                  div class: "mt-1 text-sm text-red-600" do
                    @route.errors[:starting_location].first
                  end
                end
              end

              # Destination
              div do
                form.label :destination,
                           class: "block text-sm font-medium text-gray-700 mb-2" do
                  "Destination"
                end

                form.text_field :destination,
                                class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                                placeholder: "e.g., Los Angeles, CA",
                                required: true

                if @route.errors[:destination].any?
                  div class: "mt-1 text-sm text-red-600" do
                    @route.errors[:destination].first
                  end
                end
              end

              # Form actions
              div class: "flex items-center justify-between pt-6 border-t border-gray-200" do
                link_to @road_trip,
                        class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                  "Cancel"
                end

                form.submit(
                  (@is_edit_mode ? "Update Route" : "Preview Route on Map"),
                  class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
                )
              end
            end
          end

          # Helper text for new routes
          unless @is_edit_mode
            div class: "mt-6 p-4 bg-blue-50 rounded-md" do
              div class: "flex" do
                svg_icon path_d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
                         class: "h-5 w-5 text-blue-400 mt-0.5 mr-2",
                         fill: "currentColor",
                         fill_rule: "evenodd",
                         clip_rule: "evenodd",
                         viewBox: "0 0 20 20"
                div class: "text-sm text-blue-700" do
                  "After submitting, you'll see the route on a map and can choose the date and time before adding it to your road trip."
                end
              end
            end
          end
        end
      end
    end
  end
end
