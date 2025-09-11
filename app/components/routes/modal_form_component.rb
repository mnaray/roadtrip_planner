class Routes::ModalFormComponent < ApplicationComponent
  def initialize(route:, road_trip:, current_user:)
    @route = route
    @road_trip = road_trip
    @current_user = current_user
    @is_edit_mode = @route.persisted?
  end

  def view_template
    turbo_frame_tag "modal" do
      div class: "fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity z-50",
          data: { "turbo-temporary": true } do
        div class: "fixed inset-0 z-10 overflow-y-auto" do
          div class: "flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0" do
            div class: "relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6" do
              # Modal header
              div class: "flex items-center justify-between mb-4" do
                h3 class: "text-lg font-semibold text-gray-900" do
                  if @is_edit_mode
                    "Edit Route"
                  else
                    "Add New Route"
                  end
                end

                link_to @road_trip,
                        class: "rounded-md bg-white text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-blue-500",
                        data: { "turbo-frame": "_top" } do
                  span class: "sr-only" do
                    "Close"
                  end
                  svg_icon path_d: "M6 18L18 6M6 6l12 12",
                           class: "h-6 w-6",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "2"
                end
              end

              # Form
              form_with model: [ @road_trip, @route ],
                        local: true,
                        data: { "turbo-frame": @is_edit_mode ? "_top" : "modal" },
                        class: "space-y-4" do |form|
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

                # Only show datetime field in edit mode
                if @is_edit_mode
                  render Shared::DateInputComponent.new(
                    form: form,
                    field: :datetime,
                    label: "Date & Time",
                    required: true
                  )
                end

                # Form actions
                div class: "flex items-center justify-between pt-4" do
                  link_to @road_trip,
                          class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                          data: { "turbo-frame": "_top" } do
                    "Cancel"
                  end

                  form.submit(
                    (@is_edit_mode ? "Update Route" : "Preview on Map"),
                    class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
                  )
                end
              end

              # Helper text for new routes
              unless @is_edit_mode
                div class: "mt-4 p-3 bg-blue-50 rounded-md" do
                  div class: "flex" do
                    svg_icon path_d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
                             class: "h-5 w-5 text-blue-400 mt-0.5 mr-2",
                             fill: "currentColor",
                             fill_rule: "evenodd",
                             clip_rule: "evenodd",
                             viewBox: "0 0 20 20"
                    div class: "text-sm text-blue-700" do
                      "After submitting, you'll see the route on a map and can approve or make changes before adding it to your road trip."
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
