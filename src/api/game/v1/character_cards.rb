# frozen_string_literal: true

module Game
  module V1
    class CharacterCards < Dawn::API::Base
      resource :character_cards do
        desc 'Get avatar owned character cards' do
          entity Game::Entities::CardInventory
          is_array true
          success Game::Entities::CardInventory
        end
        get do
          decks = @player.current_avatar.chara_card_decks
          cards = Unlight::CardInventory.where(chara_card_deck_id: decks.map(&:id)).all

          present cards, with: Game::Entities::CardInventory
        end
      end
    end
  end
end
