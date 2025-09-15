FactoryBot.define do
  factory :packing_list do
    sequence(:name) { |n| "Packing List #{n}" }
    association :road_trip
    association :user
    visibility { 'private' }

    trait :with_items do
      after(:create) do |packing_list|
        create_list(:packing_list_item, 5, packing_list: packing_list)
      end
    end

    trait :clothes_list do
      name { "Clothes & Accessories" }
    end

    trait :electronics_list do
      name { "Electronics & Gadgets" }
    end

    trait :public_list do
      visibility { 'public' }
    end

    trait :private_list do
      visibility { 'private' }
    end
  end
end
