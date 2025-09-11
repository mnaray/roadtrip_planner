class PackingListItems::NewComponent < ApplicationComponent
  def initialize(road_trip:, packing_list:, packing_list_item:, current_user:)
    @road_trip = road_trip
    @packing_list = packing_list
    @packing_list_item = packing_list_item
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Add Item to #{@packing_list.name}", current_user: @current_user) do
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
              li do
                link_to road_trip_packing_lists_path(@road_trip), class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  "Packing Lists"
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
                link_to road_trip_packing_list_path(@road_trip, @packing_list), class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  @packing_list.name
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
                "Add Item"
              end
            end
          end

          h1 class: "text-3xl font-bold text-gray-900" do
            "Add Item to #{@packing_list.name}"
          end

          p class: "mt-2 text-sm text-gray-600" do
            "Add a new item to your packing list with quantity and category."
          end
        end

        # Form
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6" do
          form_with model: [ @road_trip, @packing_list, @packing_list_item ], local: true, class: "space-y-6" do |form|
            # Item name
            div do
              form.label :name, class: "block text-sm font-medium text-gray-700 mb-2" do
                "Item Name"
              end

              form.text_field :name,
                              class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                              placeholder: "e.g., T-shirts, Toothbrush, Phone charger...",
                              required: true

              if @packing_list_item.errors[:name].any?
                div class: "mt-1 text-sm text-red-600" do
                  @packing_list_item.errors[:name].first
                end
              end
            end

            # Quantity and Category row
            div class: "grid grid-cols-1 md:grid-cols-2 gap-6" do
              # Quantity
              div do
                form.label :quantity, class: "block text-sm font-medium text-gray-700 mb-2" do
                  "Quantity"
                end

                form.number_field :quantity,
                                  class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm",
                                  min: 1,
                                  value: @packing_list_item.quantity || 1,
                                  required: true

                if @packing_list_item.errors[:quantity].any?
                  div class: "mt-1 text-sm text-red-600" do
                    @packing_list_item.errors[:quantity].first
                  end
                end
              end

              # Category
              div do
                form.label :category, class: "block text-sm font-medium text-gray-700 mb-2" do
                  "Category"
                end

                form.select :category,
                            [
                              [ "Tools", "tools" ],
                              [ "Clothes", "clothes" ],
                              [ "Hygiene", "hygiene" ],
                              [ "Electronics", "electronics" ],
                              [ "Food", "food" ],
                              [ "Documents", "documents" ],
                              [ "Medicine", "medicine" ],
                              [ "Entertainment", "entertainment" ],
                              [ "Other", "other" ]
                            ],
                            { prompt: "Select a category", selected: @packing_list_item.category },
                            { class: "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm", required: true }

                if @packing_list_item.errors[:category].any?
                  div class: "mt-1 text-sm text-red-600" do
                    @packing_list_item.errors[:category].first
                  end
                end
              end
            end

            div class: "flex items-center justify-between pt-4" do
              link_to road_trip_packing_list_path(@road_trip, @packing_list),
                      class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                "Cancel"
              end

              form.submit "Add Item",
                          class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
            end
          end
        end
      end
    end
  end
end
