FactoryBot.define do
  factory :road_trip_participant do
    association :road_trip
    association :user
  end
end
