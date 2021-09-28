# frozen_string_literal: true

FactoryBot.define do
  factory :dialogue, class: 'Unlight::Dialogue' do
    content { Faker::Lorem.sentence }
  end
end
