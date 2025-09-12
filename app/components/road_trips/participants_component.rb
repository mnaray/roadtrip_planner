class RoadTrips::ParticipantsComponent < ApplicationComponent
  def initialize(road_trip:, current_user:)
    @road_trip = road_trip
    @current_user = current_user
    @is_owner = @road_trip.owner?(@current_user)
  end

  def view_template
    div class: "bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden mb-8" do
      div class: "px-6 py-4 border-b border-gray-200" do
        h2 class: "text-lg font-semibold text-gray-900" do
          "Participants"
        end
      end

      div class: "p-6" do
        # Owner info
        div class: "mb-4" do
          div class: "flex items-center justify-between mb-2" do
            div class: "flex items-center space-x-3" do
              div class: "flex-shrink-0" do
                div class: "w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center" do
                  span class: "text-blue-600 font-semibold" do
                    @road_trip.user.username.first.upcase
                  end
                end
              end
              div do
                div class: "text-sm font-medium text-gray-900" do
                  @road_trip.user.username
                end
                div class: "text-xs text-gray-500" do
                  "Owner"
                end
              end
            end
          end
        end

        # Participants list
        if @road_trip.participants.any?
          div class: "mb-4 space-y-2" do
            @road_trip.participants.each do |participant|
              div class: "flex items-center justify-between py-2" do
                div class: "flex items-center space-x-3" do
                  div class: "flex-shrink-0" do
                    div class: "w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center" do
                      span class: "text-gray-600 font-semibold" do
                        participant.username.first.upcase
                      end
                    end
                  end
                  div do
                    div class: "text-sm font-medium text-gray-900" do
                      participant.username
                    end
                    div class: "text-xs text-gray-500" do
                      "Participant"
                    end
                  end
                end

                # Remove button for owner or leave button for participants
                if @is_owner
                  button_to road_trip_participant_path(@road_trip, participant),
                            method: :delete,
                            class: "inline-flex items-center px-2 py-1 text-xs font-medium text-red-600 hover:text-red-700",
                            data: { turbo_confirm: "Remove #{participant.username} from this road trip?" },
                            form: { class: "inline" } do
                    "Remove"
                  end
                elsif participant == @current_user
                  button_to road_trip_leave_path(@road_trip),
                            method: :delete,
                            class: "inline-flex items-center px-2 py-1 text-xs font-medium text-red-600 hover:text-red-700",
                            data: { turbo_confirm: "Leave this road trip?" },
                            form: { class: "inline" } do
                    "Leave"
                  end
                end
              end
            end
          end
        end

        # Add participant form (only for owner)
        if @is_owner
          div class: "border-t pt-4" do
            h3 class: "text-sm font-medium text-gray-900 mb-3" do
              "Add Participant"
            end

            form_with url: road_trip_participants_path(@road_trip),
                      class: "flex space-x-3",
                      data: { turbo_frame: "_top" } do |form|
              form.text_field :username,
                            placeholder: "Enter username",
                            class: "flex-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                            required: true

              form.submit "Add User",
                        class: "inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            end
          end
        elsif @road_trip.participant?(@current_user)
          # Leave button for participants (shown at bottom)
          div class: "border-t pt-4" do
            button_to road_trip_leave_path(@road_trip),
                      method: :delete,
                      class: "inline-flex items-center px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2",
                      data: { turbo_confirm: "Are you sure you want to leave this road trip?" },
                      form: { class: "inline" } do
              "Leave Road Trip"
            end
          end
        end
      end
    end
  end
end