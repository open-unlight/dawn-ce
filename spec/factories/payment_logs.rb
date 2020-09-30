# frozen_string_literal: true

FactoryBot.define do
  factory :payment_log, class: 'Unlight::PaymentLog' do
    player
    real_money_item
    payment_id { Faker::Crypto.md5 }
  end
end
