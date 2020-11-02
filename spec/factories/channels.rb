# frozen_string_literal: true

FactoryBot.define do
  factory :channel, class: 'Unlight::Channel' do
    name { Faker::Name.name }
    sequence :order
    rule { Unlight::RULE_3VS3 }
    max { Unlight::DUEL_CHANNEL_MAX }
  end
end
