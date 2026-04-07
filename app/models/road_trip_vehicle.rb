class RoadTripVehicle < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user
  belongs_to :vehicle

  validates :road_trip_id, uniqueness: { scope: :user_id }
  validate :vehicle_belongs_to_user

  private

  def vehicle_belongs_to_user
    return unless vehicle && user

    errors.add(:vehicle, "must belong to the user") unless vehicle.user == user
  end
end
