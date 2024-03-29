# frozen_string_literal: true

FactoryBot.define do
  factory :real_money_item, class: 'Unlight::RealMoneyItem' do
    name { Faker::Name.name }
  end
end
