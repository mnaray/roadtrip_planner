class RoadTrips::Participants::IndexComponent < ApplicationComponent
  def initialize(road_trip:, current_user:)
    @road_trip = road_trip
    @current_user = current_user
    @is_owner = @road_trip.owner?(@current_user)
  end

  def view_template
    render ApplicationLayout.new(title: "Participants - #{@road_trip.name}", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header with breadcrumb
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
                "Participants"
              end
            end
          end

          # Page header
          div class: "flex justify-between items-center" do
            div do
              h1 class: "text-3xl font-bold text-gray-900" do
                "Participants"
              end
              p class: "mt-1 text-sm text-gray-600" do
                "Manage who can view and collaborate on this road trip"
              end
            end

            # Back button
            link_to road_trip_path(@road_trip),
                    class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
              svg_icon path_d: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
                       class: "w-4 h-4 mr-1.5",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              span { "Back to Trip" }
            end
          end
        end

        # Participants content
        div class: "participants bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden" do
          div class: "px-6 py-4 border-b border-gray-200" do
            div class: "flex items-center justify-between" do
              h2 class: "text-lg font-semibold text-gray-900" do
                "Trip Members"
              end
              div class: "text-sm text-gray-500" do
                participant_count_text
              end
            end
          end

          div class: "p-6" do
            # Owner section
            div class: "mb-6" do
              h3 class: "text-sm font-medium text-gray-900 mb-3" do
                "Owner"
              end
              div class: "flex items-center space-x-3 p-3 rounded-lg bg-blue-50" do
                div class: "flex-shrink-0" do
                  div class: "w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center" do
                    span class: "text-blue-600 font-semibold text-lg" do
                      @road_trip.user.username.first.upcase
                    end
                  end
                end
                div class: "flex-1" do
                  div class: "text-base font-medium text-gray-900" do
                    @road_trip.user.username
                  end
                  div class: "text-sm text-blue-600" do
                    "Trip Owner"
                  end
                end
              end
            end

            # Participants section
            if @road_trip.participants.any?
              div class: "mb-6" do
                h3 class: "text-sm font-medium text-gray-900 mb-3" do
                  "Participants (#{@road_trip.participants.count})"
                end
                div class: "space-y-3" do
                  @road_trip.participants.each do |participant|
                    div class: "flex items-center justify-between p-3 rounded-lg border border-gray-200 hover:bg-gray-50" do
                      div class: "flex items-center space-x-3" do
                        div class: "flex-shrink-0" do
                          div class: "w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center" do
                            span class: "text-gray-600 font-semibold" do
                              participant.username.first.upcase
                            end
                          end
                        end
                        div do
                          div class: "text-base font-medium text-gray-900" do
                            participant.username
                          end
                          div class: "text-sm text-gray-500" do
                            "Participant"
                          end
                        end
                      end

                      # Action buttons
                      div class: "flex items-center space-x-2" do
                        if @is_owner
                          button_to road_trip_participant_path(@road_trip, participant),
                                    method: :delete,
                                    class: "inline-flex items-center px-3 py-1.5 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 rounded-md",
                                    form: { class: "inline" } do
                            svg_icon path_d: "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16",
                                     class: "w-4 h-4 mr-1",
                                     stroke_linecap: "round",
                                     stroke_linejoin: "round",
                                     stroke_width: "2"
                            span { "Remove" }
                          end
                        elsif participant == @current_user
                          button_to leave_road_trip_path(@road_trip),
                                    method: :delete,
                                    class: "inline-flex items-center px-3 py-1.5 text-sm font-medium text-red-600 hover:text-red-700 hover:bg-red-50 rounded-md",
                                    form: { class: "inline" } do
                            svg_icon path_d: "M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1",
                                     class: "w-4 h-4 mr-1",
                                     stroke_linecap: "round",
                                     stroke_linejoin: "round",
                                     stroke_width: "2"
                            span { "Leave" }
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            # Add participant section (only for owner)
            if @is_owner
              div class: "border-t border-gray-200 pt-6" do
                h3 class: "text-lg font-medium text-gray-900 mb-4" do
                  "Add New Participant"
                end

                div class: "bg-gray-50 p-4 rounded-lg" do
                  form_with url: road_trip_participants_path(@road_trip),
                            class: "flex space-x-3",
                            data: { turbo_frame: "_top" } do |form|
                    form.text_field :username,
                                  placeholder: "Enter username",
                                  class: "flex-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                                  required: true

                    form.submit "Add Participant",
                              class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                  end

                  p class: "mt-2 text-xs text-gray-600" do
                    "Enter the exact username of the person you want to add to this road trip."
                  end
                end
              end
            elsif @road_trip.participant?(@current_user)
              # Leave button for participants (at bottom)
              div class: "border-t border-gray-200 pt-6 text-center" do
                button_to leave_road_trip_path(@road_trip),
                          method: :delete,
                          class: "inline-flex items-center px-6 py-3 bg-red-600 text-white text-base font-medium rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2",
                          form: { class: "inline" } do
                  svg_icon path_d: "M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1",
                           class: "w-5 h-5 mr-2",
                           stroke_linecap: "round",
                           stroke_linejoin: "round",
                           stroke_width: "2"
                  span { "Leave Road Trip" }
                end
              end
            end
          end
        end
      end
    end
  end

  private

  def participant_count_text
    total = @road_trip.participants.count + 1 # +1 for owner
    "#{total} #{'member'.pluralize(total)}"
  end
end
