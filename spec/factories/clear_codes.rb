# frozen_string_literal: true

FactoryBot.define do
  factory :clear_code, class: 'Unlight::ClearCode' do
    code { Faker::Crypto.sha1 }
  end
end
