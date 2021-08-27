# frozen_string_literal: true

FactoryBot.define do
  factory :chara_card_deck, class: 'Unlight::CharaCardDeck' do
    sequence(:name) { |id| "Deck #{id}" }
  end
end
