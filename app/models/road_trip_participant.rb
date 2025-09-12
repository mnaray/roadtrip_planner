class RoadTripParticipant < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user
end
