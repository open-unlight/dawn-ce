# frozen_string_literal: true

FactoryBot.define do
  factory :achievement_inventory, class: 'Unlight::AchievementInventory' do
    association :avatar
    association :achievement
  end
end
