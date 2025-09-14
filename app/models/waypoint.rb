class Waypoint < ApplicationRecord
  belongs_to :route

  validates :latitude, presence: true,
                       numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
                        numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :position, presence: true,
                       numericality: { greater_than: 0, only_integer: true }
  validates :position, uniqueness: { scope: :route_id }
  validates :name, length: { maximum: 100 }

  scope :ordered, -> { order(:position) }

  before_validation :set_next_position, unless: -> { position.present? }
  before_validation :set_default_name, unless: -> { name.present? }

  private

  def set_next_position
    last_waypoint = route.waypoints.maximum(:position) if route
    self.position = (last_waypoint || 0) + 1
  end

  def set_default_name
    self.name = "Waypoint #{position}" if position.present?
  end
end
