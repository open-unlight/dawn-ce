# frozen_string_literal: true

module Game
  module Entities
    class Deck < Grape::Entity
      root :data

      expose :name, documentation: { example: 'Binder' }
      expose :level, documentation: { type: :number, example: 1 }
      expose :exp, documentation: { type: :number, example: '0' }
      expose :status, documentation: { type: :number, example: '0' }
      expose :cost, documentation: { type: :number, example: 30 }, &:current_cost
      expose :max_cost, documentation: { type: :number, example: 45 }
      expose :is_binder,
             unless: ->(_, options) { options[:binder_id].nil? },
             documentation: { type: :boolean, example: true } do |deck, options|
               # TODO: Ensure the first Deck is Binder
               deck.id == options[:binder_id]
             end
    end
  end
end
