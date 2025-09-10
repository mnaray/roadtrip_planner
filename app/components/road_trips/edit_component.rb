class RoadTrips::EditComponent < ApplicationComponent
  def initialize(road_trip:, current_user:)
    @road_trip = road_trip
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Edit #{@road_trip.name}", current_user: @current_user) do
      div class: "max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "mb-8" do
          # Breadcrumb
          nav class: "flex mb-4", aria_label: "Breadcrumb" do
            ol class: "flex items-center space-x-4" do
              li do
                link_to road_trips_path, class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  "My Road Trips"
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
              li do
                link_to road_trip_path(@road_trip), class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  @road_trip.name
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
                "Edit"
              end
            end
          end

          h1 class: "text-3xl font-bold text-gray-900" do
            "Edit Road Trip"
          end

          p class: "mt-2 text-sm text-gray-600" do
            "Update your road trip details."
          end
        end

        # Form
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
          form_with model: @road_trip, local: true, class: "space-y-6" do |form|
            div do
              form.label :name, class: "block text-sm font-medium text-gray-700 mb-2" do
                "Road Trip Name"
              end

              form.text_field :name,
                              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                              required: true

              if @road_trip.errors[:name].any?
                div class: "mt-1 text-sm text-red-600" do
                  @road_trip.errors[:name].first
                end
              end
            end

            div class: "flex items-center justify-between pt-4" do
              div class: "flex items-center space-x-3" do
                link_to road_trip_path(@road_trip),
                        class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                  "Cancel"
                end

                button_to road_trip_path(@road_trip),
                          method: :delete,
                          class: "inline-flex items-center px-4 py-2 border border-red-300 text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2",
                          data: { turbo_confirm: "Are you sure you want to delete this road trip? All routes will be lost." },
                          form: { class: "inline" } do
                  "Delete Road Trip"
                end
              end

              form.submit "Update Road Trip",
                          class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            end
          end
        end
      end
    end
  end
end
