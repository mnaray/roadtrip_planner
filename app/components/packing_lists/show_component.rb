class PackingLists::ShowComponent < ApplicationComponent
  def initialize(road_trip:, packing_list:, packing_list_items:, current_user:)
    @road_trip = road_trip
    @packing_list = packing_list
    @packing_list_items = packing_list_items
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: @packing_list.name, current_user: @current_user) do
      div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header
        div class: "flex justify-between items-start mb-8" do
          div do
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
                li class: "text-sm font-medium text-gray-900" do
                  @packing_list.name
                end
              end
            end

            h1 class: "text-3xl font-bold text-gray-900" do
              @packing_list.name
            end

            # Visibility and ownership info
            div class: "mt-2 flex items-center space-x-4 text-sm text-gray-600" do
              div class: "flex items-center" do
                if @packing_list.private?
                  svg_icon path_d: "M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88",
                           class: "w-4 h-4 mr-1 text-gray-500",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "1.5"
                  span { "Private list" }
                else
                  svg_icon path_d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z",
                           class: "w-4 h-4 mr-1 text-blue-500",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "1.5"
                  span { "Public list" }
                end
              end

              unless @packing_list.owned_by?(@current_user)
                div class: "flex items-center border-l border-gray-300 pl-4" do
                  svg_icon path_d: "M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z",
                           class: "w-4 h-4 mr-1",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "1.5"
                  span { "Created by #{@packing_list.user.username}" }
                end
              end
            end
          end

          div class: "flex items-center space-x-3" do
            if @packing_list.owned_by?(@current_user)
              link_to edit_road_trip_packing_list_path(@road_trip, @packing_list),
                      class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Edit" }
              end

              link_to new_road_trip_packing_list_packing_list_item_path(@road_trip, @packing_list),
                      class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                svg_icon path_d: "M12 4v16m8-8H4",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Add Item" }
              end
            else
              # For read-only access, just show a back button
              link_to road_trip_packing_lists_path(@road_trip),
                      class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
                svg_icon path_d: "M10.5 19.5L3 12m0 0l7.5-7.5M3 12h18",
                         class: "w-4 h-4 mr-1.5",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                span { "Back to Lists" }
              end
            end
          end
        end

        # Packing summary
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8" do
          div class: "grid grid-cols-1 md:grid-cols-3 gap-6" do
            div class: "text-center" do
              div class: "text-2xl font-bold text-blue-600" do
                @packing_list.total_items_count.to_s
              end
              div class: "text-sm text-gray-600" do
                "Total Items"
              end
            end

            div class: "text-center" do
              div class: "text-2xl font-bold text-green-600" do
                @packing_list.packed_items_count.to_s
              end
              div class: "text-sm text-gray-600" do
                "Items Packed"
              end
            end

            div class: "text-center" do
              div class: "text-2xl font-bold text-purple-600" do
                "#{@packing_list.packing_progress}%"
              end
              div class: "text-sm text-gray-600" do
                "Progress"
              end
            end
          end

          div class: "mt-6" do
            div class: "bg-gray-200 rounded-full h-3" do
              div class: "bg-green-500 h-3 rounded-full transition-all duration-300", style: "width: #{@packing_list.packing_progress}%" do
              end
            end
          end
        end

        # Items grouped by category
        div class: "space-y-6" do
          if @packing_list_items.any?
            grouped_items = @packing_list.items_by_category
            grouped_items.each do |category, items|
              render_category_section(category, items)
            end
          else
            div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center" do
              svg_icon path_d: "M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z",
                       class: "mx-auto h-12 w-12 text-gray-400",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "1.5"

              h3 class: "mt-4 text-lg font-medium text-gray-900" do
                "No items yet"
              end

              p class: "mt-2 text-sm text-gray-500" do
                "Add your first item to this packing list."
              end

              div class: "mt-6" do
                link_to new_road_trip_packing_list_packing_list_item_path(@road_trip, @packing_list),
                        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700" do
                  "Add First Item"
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def render_category_section(category, items)
    div class: "bg-white rounded-lg shadow-sm border border-gray-200" do
      div class: "px-6 py-4 border-b border-gray-200" do
        h2 class: "text-lg font-semibold text-gray-900 capitalize" do
          category
        end
      end

      items.each_with_index do |item, index|
        is_last = index == items.length - 1
        render_item_row(item, is_last)
      end
    end
  end

  def render_item_row(item, is_last = false)
    border_class = is_last ? "" : "border-b border-gray-200"
    div class: "#{border_class} px-6 py-4" do
      div class: "flex items-center justify-between" do
        div class: "flex items-center space-x-4" do
          # Checkbox (only interactive for owned lists)
          if @packing_list.owned_by?(@current_user)
            button_to toggle_packed_road_trip_packing_list_packing_list_item_path(@road_trip, @packing_list, item),
                      method: :patch,
                      class: "flex-shrink-0",
                      form: { class: "inline" } do
              if item.packed?
                svg_icon path_d: "M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "w-6 h-6 text-green-500 hover:text-green-600",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
              else
                svg_icon path_d: "M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "w-6 h-6 text-gray-300 hover:text-gray-400",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
              end
            end
          else
            # Static checkbox for read-only lists
            div class: "flex-shrink-0" do
              if item.packed?
                svg_icon path_d: "M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "w-6 h-6 text-green-500",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
              else
                svg_icon path_d: "M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "w-6 h-6 text-gray-300",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
              end
            end
          end

          # Item details
          div class: "flex-1" do
            div class: "flex items-center space-x-2" do
              text_classes = []
              text_classes << (item.packed? ? "line-through" : "")
              text_classes << (item.optional? ? "text-gray-400" : (item.packed? ? "text-gray-500" : "text-gray-900"))
              text_classes << "font-medium"

              span class: "text-base #{text_classes.join(' ')}" do
                item.name
              end
              if item.quantity > 1
                span class: "inline-flex items-center px-2 py-1 text-xs font-medium bg-gray-100 text-gray-800 rounded-full" do
                  "×#{item.quantity}"
                end
              end
              if item.optional?
                span class: "inline-flex items-center px-2 py-1 text-xs font-medium bg-yellow-100 text-yellow-800 rounded-full" do
                  "Optional"
                end
              end
            end
          end
        end

        # Actions (only for owned lists)
        div class: "flex items-center space-x-2" do
          if @packing_list.owned_by?(@current_user)
            link_to edit_road_trip_packing_list_packing_list_item_path(@road_trip, @packing_list, item),
                    class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-gray-600" do
              svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                       class: "w-4 h-4",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
            end

            button_to road_trip_packing_list_packing_list_item_path(@road_trip, @packing_list, item),
                      method: :delete,
                      class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-red-600",
                      data: { turbo_confirm: "Are you sure you want to delete this item?" },
                      form: { class: "inline" } do
              svg_icon path_d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                       class: "w-4 h-4",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
            end
          end
        end
      end
    end
  end
end
