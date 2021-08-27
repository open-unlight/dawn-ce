# frozen_string_literal: true

module Game
  module Entities
    class Error < Grape::Entity
      expose :message, documentation: { example: 'Avatar not found!' }
      expose :code, documentation: { type: :number, example: 1 }
    end
  end
end
