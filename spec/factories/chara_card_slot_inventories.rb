# frozen_string_literal: true

FactoryBot.define do
  factory :chara_card_slot_inventory, class: 'Unlight::CharaCardSlotInventory' do
    deck_position { 0 }
    card_position { 0 }
    kind { Unlight::SCT_EVENT }
  end
end
