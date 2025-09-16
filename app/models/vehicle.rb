class Vehicle < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  VEHICLE_TYPES = %w[car motorcycle bicycle skateboard scooter other].freeze

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :vehicle_type, presence: true, inclusion: { in: VEHICLE_TYPES }
  validates :make_model, length: { maximum: 200 }, allow_blank: true
  validates :engine_volume_ccm, :horsepower, :torque, :passenger_count,
            numericality: { greater_than: 0, allow_blank: true }
  validates :fuel_consumption, :dry_weight, :wet_weight, :load_capacity,
            numericality: { greater_than: 0.0, allow_blank: true }

  scope :for_user, ->(user) { where(user: user) }
  scope :default_for_user, ->(user) { where(user: user, is_default: true) }

  before_save :ensure_single_default

  def type_icon_class
    case vehicle_type
    when "car" then "fas fa-car"
    when "motorcycle" then "fas fa-motorcycle"
    when "bicycle" then "fas fa-bicycle"
    when "skateboard" then "fas fa-skating"
    when "scooter" then "fas fa-scooter"
    else "fas fa-road"
    end
  end

  def display_name
    name
  end

  def full_description
    parts = [ name ]
    parts << make_model if make_model.present?
    parts.join(" - ")
  end

  def has_fuel_consumption?
    fuel_consumption.present? && fuel_consumption > 0
  end

  private

  def ensure_single_default
    return unless is_default?

    # Remove default from other vehicles of the same user
    Vehicle.where(user: user, is_default: true)
           .where.not(id: id)
           .update_all(is_default: false)
  end
end
