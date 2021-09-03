# frozen_string_literal: true

require_relative 'entities'
require_relative 'v1/avatar'
require_relative 'v1/decks'
require_relative 'v1/character_cards'
require_relative 'v1/slot_cards'
require_relative 'v1/items'

module Game
  class APIv1 < Dawn::API::Base
    version 'v1', using: :path

    before do
      @player = Unlight::Player[env['REMOTE_USER']]
    end

    desc 'Get game server status'
    get '/status' do
      # TODO: Provide more information about game server
      {
        status: :ok
      }
    end

    mount Game::V1::Avatar
    mount Game::V1::Decks
    mount Game::V1::CharacterCards
    mount Game::V1::SlotCards
    mount Game::V1::Items
  end
end
