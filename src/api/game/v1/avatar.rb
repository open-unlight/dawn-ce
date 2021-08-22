# frozen_string_literal: true

module Game
  module V1
    class Avatar < Dawn::API::Base
      resource :avatar do
        desc 'Get current avatar information' do
          named 'Get avatar'
          success Game::Entities::Avatar
        end
        get do
          avatar = @player.current_avatar
          present avatar, with: Game::Entities::Avatar
        end
      end
    end
  end
end
