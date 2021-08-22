# frozen_string_literal: true

module Game
  module Entities
    class Avatar < Grape::Entity
      root :data

      expose :name, documentation: { example: 'Sheri' }
      expose :gems, documentation: { type: :number, example: 100 }
      expose :exp, documentation: { type: :number, example: 100 }
      expose :ap, documentation: { type: :array, items: { type: :number }, example: [5, 5] } do |avatar|
        [avatar.energy, avatar.energy_max]
      end
    end
  end
end
