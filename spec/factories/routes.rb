FactoryBot.define do
  factory :route do
    sequence(:starting_location) { |n| "Start City #{n}" }
    sequence(:destination) { |n| "End City #{n}" }
    sequence(:datetime) { |n| n.hours.from_now }
    association :road_trip
    user { road_trip&.user || association(:user) }

    trait :san_francisco_to_la do
      starting_location { "San Francisco, CA" }
      destination { "Los Angeles, CA" }
    end

    trait :chicago_to_denver do
      starting_location { "Chicago, IL" }
      destination { "Denver, CO" }
    end

    trait :tomorrow_morning do
      datetime { 1.day.from_now.change(hour: 8, min: 0) }
    end

    trait :next_week do
      datetime { 1.week.from_now.change(hour: 10, min: 0) }
    end

    trait :with_specific_time do
      transient do
        hours_from_now { 24 }
      end
      datetime { hours_from_now.hours.from_now }
    end
  end
end
