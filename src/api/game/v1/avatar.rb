# frozen_string_literal: true

module Game
  module V1
    class Avatar < Dawn::API::Base
      resource :avatar do
        desc 'Get current avatar information'
        get do
          avatar = @player.current_avatar
          # TODO: Use Grape::Entity to create error response
          return error!('Avatar Not Fuond', 404) if avatar.nil?

          {
            data: {
              name: avatar.name,
              gems: avatar.gems,
              exp: avatar.exp,
              ap: [
                avatar.energy,
                avatar.energy_max
              ]
            }
          }
        end
      end
    end
  end
end
