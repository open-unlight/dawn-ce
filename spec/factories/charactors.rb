# frozen_string_literal: true

FactoryBot.define do
  factory :charactor, class: 'Unlight::Charactor' do
    name { Faker::Name.name }
  end
end
