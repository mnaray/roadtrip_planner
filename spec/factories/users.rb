FactoryBot.define do
  factory :user do
    username { Faker::Internet.unique.username(specifier: 3..20, separators: %w[_ -]) }
    password { Faker::Internet.password(min_length: 8) }
    password_confirmation { password }
  end

  factory :invalid_user, class: 'User' do
    username { nil }
    password { nil }
    password_confirmation { nil }
  end
end
