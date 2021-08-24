# frozen_string_literal: true

module Game
  module Entities
    class CardInventory < Grape::Entity
      root :data

      expose :chara_card_deck_id, as: :deck_id, override: true, documentation: { type: :number, example: 1 }
      expose :chara_card_id, as: :character_card_id, override: true, documentation: { type: :number, example: 1001 }
      expose :position, documentation: { type: :number, example: '0' }
    end
  end
end
