class RoadTrip < ApplicationRecord
  belongs_to :user
  has_many :routes, dependent: :destroy
  has_many :packing_lists, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  scope :for_user, ->(user) { where(user: user) }

  def total_distance
    routes.sum { |route| route.distance_in_km.to_f }.round(1)
  end

  def day_count
    return 0 if routes.empty?
    return 1 if routes.count == 1

    sorted_routes = routes.order(:datetime)
    start_date = sorted_routes.first.datetime.to_date
    end_date = sorted_routes.last.datetime.to_date
    (end_date - start_date).to_i + 1
  end
end
