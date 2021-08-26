# frozen_string_literal: true

module Game
  module Entities
    class CardSlotInventory < Grape::Entity
      root :data

      expose :chara_card_deck_id, as: :deck_id, override: true, documentation: { type: :number, example: 1 }
      expose :card_id, documentation: { type: :number, example: 1 }
      expose :kind, as: :type, override: true, documentation: { type: :number, example: 2 }
      expose :deck_position, documentation: { type: :number, example: '0' }
      expose :card_position, documentation: { type: :number, example: '0' }
    end
  end
end
