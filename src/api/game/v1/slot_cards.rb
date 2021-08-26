# frozen_string_literal: true

module Game
  module V1
    class SlotCards < Dawn::API::Base
      resource :slot_cards do
        desc 'Get avatar owned slot cards' do
          entity Game::Entities::CardSlotInventory
          is_array true
          success Game::Entities::CardSlotInventory
        end
        get do
          decks = @player.current_avatar.chara_card_decks
          cards =
            Unlight::CharaCardSlotInventory
            .where(chara_card_deck_id: decks.map(&:id), kind: Unlight::SCT_EVENT)
            .all

          present cards, with: Game::Entities::CardSlotInventory
        end
      end
    end
  end
end
