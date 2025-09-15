class Route < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user
  has_many :waypoints, -> { order(:position) }, dependent: :destroy

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

  # Force recalculation of route metrics including waypoints
  def recalculate_metrics!
    calculate_route_metrics
    save! if persisted?
    { distance: distance, duration: duration }
  end

  # Check if route metrics need recalculation due to waypoint changes
  def metrics_outdated?
    return false unless waypoints.any?
    return true if waypoints_updated_at.nil?

    # Check if any waypoint was updated after the last route metric calculation
    latest_waypoint_update = waypoints.maximum(:updated_at)
    return true if latest_waypoint_update && waypoints_updated_at && latest_waypoint_update > waypoints_updated_at

    false
  end

  # Get current route duration considering if recalculation is needed
  def current_duration_hours
    if metrics_outdated?
      recalculate_metrics!
      duration_hours
    else
      duration_hours
    end
  end

  private

  def locations_changed?
    starting_location_changed? || destination_changed?
  end

  def calculate_route_metrics
    return unless starting_location.present? && destination.present?

    # Include waypoints in calculation if they exist - convert to array for compatibility
    ordered_waypoints = waypoints.ordered.to_a
    calculator = RouteDistanceCalculator.new(starting_location, destination, ordered_waypoints)
    result = calculator.calculate

    self.distance = result[:distance]
    self.duration = result[:duration]
    self.waypoints_updated_at = Time.current if waypoints.any?
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

    # Calculate end time using current duration (accounts for waypoints if present)
    my_duration = current_duration_hours
    my_end_time = datetime + my_duration.hours

    # Check for overlap with other routes, accounting for their waypoints
    # We need to check each route individually to use their current_duration_hours
    overlapping = road_trip.routes.where.not(id: id).any? do |other_route|
      # Calculate other route's actual end time with waypoints
      other_duration = other_route.current_duration_hours
      other_end_time = other_route.datetime + other_duration.hours

      # Check for overlap: two time ranges [A1,A2] and [B1,B2] overlap if A1 < B2 AND A2 > B1
      datetime < other_end_time && my_end_time > other_route.datetime
    end

    if overlapping
      errors.add(:datetime, "overlaps with another route in this road trip")
    end
  end

  def user_matches_road_trip_user
    return unless road_trip && user

    # Allow route creation if user is either the road trip owner or a participant
    unless road_trip.can_access?(user)
      errors.add(:user, "must be the road trip owner or a participant")
    end
  end
end
