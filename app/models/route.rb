class Route < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user

  validates :starting_location, presence: true, length: { minimum: 1, maximum: 200 }
  validates :destination, presence: true, length: { minimum: 1, maximum: 200 }
  validates :datetime, presence: true, unless: -> { validation_context == :location_only }
  validate :datetime_not_overlapping_with_other_routes, unless: -> { validation_context == :location_only }
  validate :user_matches_road_trip_user

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_datetime, -> { order(:datetime) }

  def duration_hours
    2
  end

  private

  def datetime_not_overlapping_with_other_routes
    return unless datetime && road_trip

    overlapping_routes = road_trip.routes
                                 .where.not(id: id)
                                 .where(
                                   "datetime BETWEEN ? AND ? OR datetime + INTERVAL '2 hours' BETWEEN ? AND ?",
                                   datetime, datetime + duration_hours.hours,
                                   datetime, datetime + duration_hours.hours
                                 )

    if overlapping_routes.exists?
      errors.add(:datetime, "overlaps with another route in this road trip")
    end
  end

  def user_matches_road_trip_user
    return unless road_trip && user

    if road_trip.user_id != user_id
      errors.add(:user, "must match the road trip's user")
    end
  end
end
