class Route < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user

  validates :starting_location, presence: true, length: { minimum: 1, maximum: 200 }
  validates :destination, presence: true, length: { minimum: 1, maximum: 200 }
  validates :datetime, presence: true, unless: -> { validation_context == :location_only }
  validate :datetime_not_overlapping_with_other_routes, unless: -> { validation_context == :location_only }
  validate :user_matches_road_trip_user

  before_save :calculate_distance, if: :locations_changed?

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_datetime, -> { order(:datetime) }

  def duration_hours
    2
  end

  def distance_in_km
    distance || calculate_and_save_distance
  end

  private

  def locations_changed?
    starting_location_changed? || destination_changed?
  end

  def calculate_distance
    return unless starting_location.present? && destination.present?
    
    calculator = RouteDistanceCalculator.new(starting_location, destination)
    self.distance = calculator.calculate
  end

  def calculate_and_save_distance
    return nil unless starting_location.present? && destination.present?
    
    calculate_distance
    save if persisted? && distance_changed?
    distance
  end

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
