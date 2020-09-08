# frozen_string_literal: true

FactoryBot.define do
  factory :player, class: 'Unlight::Player' do
    salt { Faker::Crypto.sha1 }
  end
end
