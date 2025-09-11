class Routes::ConfirmRouteComponent < ApplicationComponent
  def initialize(route_data:, current_user:, route: nil)
    @route_data = route_data
    @current_user = current_user
    @route = route # Only present if there were validation errors
  end

  def view_template
    render ApplicationLayout.new(title: "Confirm Route", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "text-center mb-8" do
          h1 class: "text-3xl font-bold text-gray-900 mb-2" do
            "Review Your Route"
          end

          p class: "text-lg text-gray-600" do
            "#{@route_data['starting_location']} → #{@route_data['destination']}"
          end
        end

        div class: "grid grid-cols-1 lg:grid-cols-3 gap-8" do
          # Map container
          div class: "lg:col-span-2" do
            div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-4" do
              div class: "h-96 bg-gray-100 rounded-md flex items-center justify-center" do
                render_map_placeholder
              end
            end
          end

          # Approval form
          div class: "lg:col-span-1" do
            div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
              h2 class: "text-lg font-semibold text-gray-900 mb-4" do
                "Approve Route"
              end

              p class: "text-sm text-gray-600 mb-6" do
                "If the route looks correct, choose a date and time to add it to your road trip."
              end

              form_with url: approve_route_path,
                        method: :post,
                        local: true,
                        class: "space-y-4" do |form|
                # Create a temporary form object to pass to our component
                temp_form_object = OpenStruct.new(
                  errors: @route&.errors || {},
                  datetime: 1.hour.from_now
                )
                temp_form = ActionView::Helpers::FormBuilder.new(:route, temp_form_object, self, {})

                div do
                  form.label :datetime,
                             class: "block text-sm font-medium text-gray-700 mb-2" do
                    "Date & Time"
                  end

                  form.datetime_local_field :datetime,
                                            class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                                            required: true,
                                            value: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M"),
                                            placeholder: "DD/MM/YYYY HH:MM"

                  # Display format hint for users
                  p class: "mt-1 text-xs text-gray-500" do
                    "Format: DD/MM/YYYY HH:MM"
                  end

                  if @route&.errors&.[](:datetime)&.any?
                    div class: "mt-1 text-sm text-red-600" do
                      @route.errors[:datetime].first
                    end
                  end
                end

                # Display validation errors if any
                if @route&.errors&.any?
                  div class: "p-3 bg-red-50 border border-red-200 rounded-md" do
                    h4 class: "text-sm font-medium text-red-800 mb-1" do
                      "Please fix the following:"
                    end
                    ul class: "text-sm text-red-700 list-disc list-inside" do
                      @route.errors.full_messages.each do |message|
                        li { message }
                      end
                    end
                  end
                end

                div class: "space-y-3" do
                  form.submit "Add to Road Trip",
                              class: "w-full inline-flex justify-center items-center px-4 py-2 bg-green-600 text-white text-sm font-medium rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"

                  link_to new_road_trip_route_path(RoadTrip.find(@route_data["road_trip_id"])),
                          class: "w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                          data: { "turbo-frame": "modal" } do
                    "Edit Route"
                  end

                  link_to road_trips_path,
                          class: "w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                    "Cancel"
                  end
                end
              end

              # Route details
              div class: "mt-6 pt-6 border-t border-gray-200" do
                h3 class: "text-sm font-semibold text-gray-900 mb-3" do
                  "Route Details"
                end

                div class: "space-y-2 text-sm" do
                  div do
                    span class: "text-gray-500" do
                      "From: "
                    end
                    span class: "text-gray-900 font-medium" do
                      @route_data["starting_location"]
                    end
                  end

                  div do
                    span class: "text-gray-500" do
                      "To: "
                    end
                    span class: "text-gray-900 font-medium" do
                      @route_data["destination"]
                    end
                  end

                  div do
                    span class: "text-gray-500" do
                      "Est. Duration: "
                    end
                    span class: "text-gray-900 font-medium" do
                      "2 hours"
                    end
                  end

                  div do
                    span class: "text-gray-500" do
                      "Est. Distance: "
                    end
                    span class: "text-gray-900 font-medium" do
                      "120 miles"
                    end
                  end
                end
              end
            end
          end
        end

        # Modal frame for edit form
        turbo_frame_tag "modal"
      end
    end
  end

  private

  def render_map_placeholder
    div class: "text-center" do
      svg_icon path_d: "M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7",
               class: "mx-auto h-12 w-12 text-gray-400 mb-4",
               stroke_linecap: "round",
               stroke_linejoin: "round",
               stroke_width: "2"

      div class: "text-gray-600" do
        p class: "font-medium mb-1" do
          "Route Preview"
        end
        p class: "text-sm" do
          "Map integration with Leaflet.js will be implemented"
        end
        p class: "text-xs text-gray-500 mt-2" do
          "This would show the actual route from #{@route_data['starting_location']} to #{@route_data['destination']}"
        end
      end
    end
  end
end
