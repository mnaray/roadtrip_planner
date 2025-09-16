class RoadTrip < ApplicationRecord
  belongs_to :user
  has_many :routes, dependent: :destroy
  has_many :packing_lists, dependent: :destroy
  has_many :road_trip_participants, dependent: :destroy
  has_many :participants, through: :road_trip_participants, source: :user

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

  def owner?(check_user)
    user == check_user
  end

  def participant?(check_user)
    participants.include?(check_user)
  end

  def can_access?(check_user)
    owner?(check_user) || participant?(check_user)
  end

  def add_participant(new_user)
    return false if new_user == user || participants.include?(new_user)

    participants << new_user
  end

  def remove_participant(participant_user)
    participants.delete(participant_user)
  end

  def participant_count
    participants.count + 1
  end
end
