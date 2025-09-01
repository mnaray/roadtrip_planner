class Route < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user

  validates :starting_location, presence: true, length: { minimum: 1, maximum: 200 }
  validates :destination, presence: true, length: { minimum: 1, maximum: 200 }
  validates :datetime, presence: true, unless: -> { validation_context == :location_only }
  validate :datetime_not_overlapping_with_other_routes, unless: -> { validation_context == :location_only }
  validate :user_matches_road_trip_user

  before_save :calculate_route_metrics, if: :locations_changed?

  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_datetime, -> { order(:datetime) }

  def duration_hours
    # Return stored duration if available, otherwise default to 2 hours
    # Avoid expensive API calls during validation
    duration || 2.0
  end

  def distance_in_km
    distance || calculate_and_save_route_metrics[:distance]
  end

  private

  def locations_changed?
    starting_location_changed? || destination_changed?
  end

  def calculate_route_metrics
    return unless starting_location.present? && destination.present?

    calculator = RouteDistanceCalculator.new(starting_location, destination)
    result = calculator.calculate

    self.distance = result[:distance]
    self.duration = result[:duration]
  end

  def calculate_and_save_route_metrics
    return { distance: nil, duration: nil } unless starting_location.present? && destination.present?

    # Only calculate if we don't have both values
    if distance.nil? || duration.nil?
      calculate_route_metrics
      save if persisted? && (distance_changed? || duration_changed?)
    end

    { distance: distance, duration: duration }
  end

  def datetime_not_overlapping_with_other_routes
    return unless datetime && road_trip

    # Calculate end time using duration_hours which handles nil values
    # Use a default of 2 hours if duration is not available
    my_duration = duration || 2.0
    end_time = datetime + my_duration.hours

    # Check for overlap: two time ranges [A1,A2] and [B1,B2] overlap if A1 < B2 AND A2 > B1
    # In our case: new route is [datetime, end_time] and existing route is [existing_start, existing_end]
    # They overlap if: datetime < existing_end AND end_time > existing_start
    overlapping_routes = road_trip.routes
                                 .where.not(id: id)
                                 .where(
                                   "? < datetime + (COALESCE(duration, 2.0) * INTERVAL '1 hour') AND ? > datetime",
                                   datetime, end_time
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
