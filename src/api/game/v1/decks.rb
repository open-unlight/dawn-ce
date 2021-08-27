# frozen_string_literal: true

module Game
  module V1
    class Decks < Dawn::API::Base
      resource :decks do
        desc 'Get avatar decks' do
          entity Game::Entities::Deck
          is_array true
          success Game::Entities::Deck
        end
        get do
          avatar = @player.current_avatar
          decks = Unlight::CharaCardDeck.eager(:card_inventories).where(avatar_id: avatar.id).all
          position = decks.map(&:id)

          present decks, with: Game::Entities::Deck, binder_id: decks.first&.id, position: position
        end
      end
    end
  end
end
