# frozen_string_literal: true

FactoryBot.define do
  factory :avatar, class: 'Unlight::Avatar' do
    name { Faker::Name.name }
    player
  end
end
