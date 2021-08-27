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

        params do
          requires :id, type: Integer, desc: 'Character Card Inventory ID'
        end
        route_param :id do
          desc 'Chage character card deck' do
            consumes ['application/x-www-form-urlencoded']
            success Game::Entities::CardInventory
          end
          params do
            requires :index, type: Integer, desc: 'Deck Index'
            requires :position, type: Integer, desc: 'Position in deck'
          end
          put '/deck' do
            avatar = @player.current_avatar

            # TODO: Replace with service object
            Unlight::CACHE.set("update_card_inventory_info_#{@player.id}", true, 60 * 60 * 1)
            code = avatar.update_chara_card_deck(params[:id], params[:index], params[:position])
            case code
            when Unlight::ERROR_NOT_EXIST_DECK
              return error!({ message: 'Deck not found', code: code }, 404)
            when Unlight::ERROR_NOT_EXIST_INVETORY
              return error!({ message: 'Card not found', code: code }, 404)
            when 0
              # No Errors
            else
              return error!({ message: 'Unable to update card', code: code, with: Game::Entities::Error }, 400)
            end

            Unlight::CACHE.delete("update_card_inventory_info_#{@player.id}")
            # TODO: Reuse `inventory` when move card deck
            present Unlight::CardInventory[params[:id]], with: Game::Entities::CardInventory
          end
        end
      end
    end
  end
end
