# frozen_string_literal: true

FactoryBot.define do
  factory :rare_card_lot, class: 'Unlight::RareCardLot' do
    sequence(:article_id)
    sequence(:order)
    sequence(:rarity)
  end
end
