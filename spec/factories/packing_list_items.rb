FactoryBot.define do
  factory :packing_list_item do
    sequence(:name) { |n| "Item #{n}" }
    quantity { 1 }
    category { "other" }
    packed { false }
    optional { false }
    association :packing_list

    trait :packed do
      packed { true }
    end

    trait :unpacked do
      packed { false }
    end

    trait :optional do
      optional { true }
    end

    trait :required do
      optional { false }
    end

    trait :clothes_item do
      name { "T-shirt" }
      category { "clothes" }
      quantity { 3 }
    end

    trait :electronics_item do
      name { "Phone charger" }
      category { "electronics" }
      quantity { 1 }
    end

    trait :hygiene_item do
      name { "Toothbrush" }
      category { "hygiene" }
      quantity { 1 }
    end

    trait :tools_item do
      name { "Screwdriver set" }
      category { "tools" }
      quantity { 1 }
    end
  end
end
