FactoryBot.define do
  factory :road_trip do
    sequence(:name) { |n| "Road Trip #{n}" }
    association :user

    trait :with_routes do
      after(:create) do |road_trip|
        create_list(:route, 3, road_trip: road_trip, user: road_trip.user)
      end
    end

    trait :california_coast do
      name { "California Coast Adventure" }
    end

    trait :route_66 do
      name { "Route 66 Journey" }
    end
  end
end
