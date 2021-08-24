# frozen_string_literal: true

require_relative 'entities'
require_relative 'v1/avatar'
require_relative 'v1/decks'
require_relative 'v1/character_cards'

module Game
  class APIv1 < Dawn::API::Base
    version 'v1', using: :path

    before do
      @player = Unlight::Player[env['REMOTE_USER']]
    end

    mount Game::V1::Avatar
    mount Game::V1::Decks
    mount Game::V1::CharacterCards
  end
end
