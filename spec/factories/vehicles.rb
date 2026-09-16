FactoryBot.define do
  factory :vehicle do
    association :user
    name { "My Car" }
    vehicle_type { "car" }
    make_model { "Honda Civic" }
    is_default { false }
    engine_volume_ccm { 1800 }
    horsepower { 140 }
    torque { 174 }
    fuel_consumption { 6.5 }
    dry_weight { 1300.0 }
    wet_weight { 1400.0 }
    passenger_count { 5 }
    load_capacity { 500.0 }

    trait :default do
      is_default { true }
    end

    trait :motorcycle do
      vehicle_type { "motorcycle" }
      name { "My Motorcycle" }
      make_model { "Yamaha R1" }
      engine_volume_ccm { 998 }
      horsepower { 200 }
      torque { 112 }
      fuel_consumption { 5.8 }
      dry_weight { 201.0 }
      wet_weight { 199.0 }
      passenger_count { 2 }
      load_capacity { 50.0 }
    end

    trait :bicycle do
      vehicle_type { "bicycle" }
      name { "My Bicycle" }
      make_model { "Trek Mountain Bike" }
      engine_volume_ccm { nil }
      horsepower { nil }
      torque { nil }
      fuel_consumption { nil }
      dry_weight { 15.0 }
      wet_weight { 15.0 }
      passenger_count { 1 }
      load_capacity { 20.0 }
    end
  end
end