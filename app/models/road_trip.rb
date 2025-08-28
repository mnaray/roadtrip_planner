class RoadTrip < ApplicationRecord
  belongs_to :user
  has_many :routes, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  scope :for_user, ->(user) { where(user: user) }

  def total_distance_placeholder
    routes.count * 100
  end

  def day_count
    return 0 if routes.empty?
    
    sorted_routes = routes.order(:datetime)
    return 1 if sorted_routes.count == 1
    
    start_date = sorted_routes.first.datetime.to_date
    end_date = sorted_routes.last.datetime.to_date
    (end_date - start_date).to_i + 1
  end
end
