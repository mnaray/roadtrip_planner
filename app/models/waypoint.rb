class Waypoint < ApplicationRecord
  belongs_to :route

  validates :latitude, presence: true,
                       numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
                        numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :position, presence: true,
                       numericality: { greater_than: 0, only_integer: true }
  validates :position, uniqueness: { scope: :route_id }

  scope :ordered, -> { order(:position) }

  before_validation :set_next_position, unless: -> { position.present? }

  # Trigger route recalculation when waypoints change
  after_create :invalidate_route_metrics
  after_update :invalidate_route_metrics, if: :saved_change_to_position_or_coordinates?
  after_destroy :invalidate_route_metrics

  private

  def saved_change_to_position_or_coordinates?
    saved_change_to_position? || saved_change_to_latitude? || saved_change_to_longitude?
  end

  def invalidate_route_metrics
    return unless route

    # Mark route metrics as outdated by clearing waypoints_updated_at
    # This will trigger recalculation on next access
    route.update_columns(waypoints_updated_at: nil) if route.persisted?
  end

  def set_next_position
    last_waypoint = route.waypoints.maximum(:position) if route
    self.position = (last_waypoint || 0) + 1
  end
end
