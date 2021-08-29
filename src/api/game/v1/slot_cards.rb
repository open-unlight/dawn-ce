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

        params do
          requires :id, type: Integer, desc: 'Slot Card Inventory ID'
        end
        route_param :id do
          desc 'Chage character card slot in deck' do
            consumes ['application/x-www-form-urlencoded']
            success Game::Entities::CardSlotInventory
          end
          params do
            requires :index, type: Integer, desc: 'Deck Index'
            requires :deck_position, type: Integer, desc: 'CharacterCard position in deck'
            requires :card_position, type: Integer, desc: 'SlotCard position in CharacterCard'
          end
          put '/deck' do
            avatar = @player.current_avatar
            inv = Unlight::CharaCardSlotInventory[params[:id]]

            # TODO: Replace with service object
            Unlight::CACHE.set("update_slot_card_inventory_info_#{@player.id}", true, 60 * 60 * 1)
            # TODO: Ensure event card exists
            begin
              code, inv = avatar.update_slot_card_deck(params[:id], params[:index], inv&.kind, params[:deck_position], params[:card_position])
              case code
              when nil
                return error!({ message: 'Deck not found', code: code }, 404)
              when Unlight::ERROR_NOT_ENOUGH_COLOR
                return error!({ message: 'Color slot not enough', code: code }, 400)
              when Unlight::ERROR_SLOT_MAX
                return error!({ message: 'Slot not enough', code: code }, 400)
              when Unlight::ERROR_NOT_EXIST_CHARA
                return error!({ message: 'CharacterCard not exists', code: code }, 404)
              when 0
                # No Errors
              else
                return error!({ message: 'Unable to update card', code: code, with: Game::Entities::Error }, 400)
              end
            rescue StandardError => e
              raise unless e.message == 'wrong card inventory id'

              # TODO: Refactor to use error code
              return error!({ message: 'Card not found', code: code }, 404)
            end

            Unlight::CACHE.delete("update_slot_card_inventory_info_#{@player.id}")
            # TODO: Reuse `inventory` when move card deck
            present inv, with: Game::Entities::CardSlotInventory
          end
        end
      end
    end
  end
end
