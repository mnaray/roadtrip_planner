class User < ApplicationRecord
  has_secure_password
  has_many :road_trips, dependent: :destroy
  has_many :routes, dependent: :destroy
  has_many :road_trip_participants, dependent: :destroy
  has_many :participating_road_trips, through: :road_trip_participants, source: :road_trip
  has_many :vehicles, dependent: :destroy
  has_many :road_trip_vehicles, dependent: :destroy

  validates :username, presence: true,
                      length: { minimum: 3 },
                      uniqueness: { case_sensitive: false }

  validates :password, presence: true,
                      length: { minimum: 8 },
                      format: { with: /\A(?=.*[a-zA-Z])(?=.*\d).*\z/,
                               message: "must contain both letters and numbers" }

  before_save :downcase_username

  def default_vehicle
    vehicles.find_by(is_default: true)
  end

  def has_vehicles?
    vehicles.exists?
  end

  def vehicle_for_road_trip(road_trip)
    road_trip_vehicles.find_by(road_trip: road_trip)&.vehicle
  end

  private

  def downcase_username
    self.username = username.downcase if username.present?
  end
end
