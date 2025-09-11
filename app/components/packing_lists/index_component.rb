class PackingLists::IndexComponent < ApplicationComponent
  def initialize(road_trip:, packing_lists:, current_user:)
    @road_trip = road_trip
    @packing_lists = packing_lists
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "Packing Lists - #{@road_trip.name}", current_user: @current_user) do
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
                li class: "text-sm font-medium text-gray-900" do
                  "Packing Lists"
                end
              end
            end

            h1 class: "text-3xl font-bold text-gray-900" do
              "Packing Lists"
            end
          end

          div class: "flex items-center space-x-3" do
            link_to new_road_trip_packing_list_path(@road_trip),
                    class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
              svg_icon path_d: "M12 4v16m8-8H4",
                       class: "w-4 h-4 mr-1.5",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              span { "New Packing List" }
            end
          end
        end

        # Packing lists
        div class: "bg-white rounded-lg shadow-sm border border-gray-200" do
          div class: "px-6 py-4 border-b border-gray-200" do
            h2 class: "text-lg font-semibold text-gray-900" do
              "Your Packing Lists"
            end
          end

          if @packing_lists.any?
            @packing_lists.each_with_index do |packing_list, index|
              is_last = index == @packing_lists.length - 1
              render_packing_list_row(packing_list, is_last)
            end
          else
            div class: "p-12 text-center" do
              svg_icon path_d: "M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z",
                       class: "mx-auto h-12 w-12 text-gray-400",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "1.5"

              h3 class: "mt-4 text-lg font-medium text-gray-900" do
                "No packing lists yet"
              end

              p class: "mt-2 text-sm text-gray-500" do
                "Create your first packing list to start organizing your trip essentials."
              end

              div class: "mt-6" do
                link_to new_road_trip_packing_list_path(@road_trip),
                        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700" do
                  "Create First Packing List"
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def render_packing_list_row(packing_list, is_last = false)
    border_class = is_last ? "" : "border-b border-gray-200"
    div class: "#{border_class}" do
      div class: "flex items-center justify-between" do
        # Main clickable area
        link_to road_trip_packing_list_path(@road_trip, packing_list), 
                class: "flex items-center space-x-4 flex-1 p-6 hover:bg-gray-50 no-underline text-inherit transition-colors" do
          
          # List details
          div class: "flex-1 min-w-0" do
            h3 class: "text-lg font-semibold text-gray-900 truncate mb-2" do
              packing_list.name
            end

            div class: "flex items-center space-x-6 text-sm text-gray-500" do
              div class: "flex items-center" do
                svg_icon path_d: "M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z",
                         class: "w-4 h-4 mr-1",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "1.5"
                span { "#{packing_list.total_items_count} items" }
              end

              div class: "flex items-center" do
                svg_icon path_d: "M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
                         class: "w-4 h-4 mr-1 text-green-500",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "1.5"
                span { "#{packing_list.packing_progress}% packed" }
              end
            end
          end

          # Progress bar
          div class: "w-32" do
            div class: "bg-gray-200 rounded-full h-2" do
              div class: "bg-green-500 h-2 rounded-full", style: "width: #{packing_list.packing_progress}%" do
              end
            end
          end
        end

        # Actions
        div class: "flex items-center space-x-2 px-6 py-6" do
          link_to edit_road_trip_packing_list_path(@road_trip, packing_list),
                  class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-gray-600" do
            svg_icon path_d: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
                     class: "w-4 h-4",
                     stroke_linecap: "round",
                     stroke_linejoin: "round",
                     stroke_width: "2"
          end

          button_to road_trip_packing_list_path(@road_trip, packing_list),
                    method: :delete,
                    class: "inline-flex items-center p-1.5 border border-transparent rounded-md text-gray-400 hover:text-red-600",
                    data: { turbo_confirm: "Are you sure you want to delete this packing list?" },
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