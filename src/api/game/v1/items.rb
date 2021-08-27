# frozen_string_literal: true

module Game
  module V1
    class Items < Dawn::API::Base
      resource :items do
        desc 'Get avatar items' do
          entity Game::Entities::ItemInventory
          is_array true
          success Game::Entities::ItemInventory
        end
        get do
          avatar = @player.current_avatar
          items = Unlight::ItemInventory.where(avatar_id: avatar.id, state: [Unlight::ITEM_STATE_NOT_USE]).all

          present items, with: Game::Entities::ItemInventory
        end
      end
    end
  end
end
