# frozen_string_literal: true

module Game
  module Entities
    class ItemInventory < Grape::Entity
      root :data

      expose :id, documentation: { type: :number, example: 1 }
      expose :avatar_item_id, documentation: { type: :number, example: 1 }
      expose :state, documentation: { type: :number, example: '0' }
    end
  end
end
