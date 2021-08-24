# frozen_string_literal: true

FactoryBot.define do
  factory :avatar, class: 'Unlight::Avatar' do
    sequence(:name) { |id| "#{Faker::Name.name} - #{id}" }
    player
  end
end
