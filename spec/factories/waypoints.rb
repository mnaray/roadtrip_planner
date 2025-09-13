FactoryBot.define do
  factory :waypoint do
    route
    latitude { 37.7749 } # San Francisco latitude
    longitude { -122.4194 } # San Francisco longitude

    trait :with_position do
      position { 1 }
    end
  end
end
