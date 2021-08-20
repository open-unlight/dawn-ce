# frozen_string_literal: true

require_relative 'v1/avatar'

module Game
  class APIv1 < Dawn::API::Base
    version 'v1', using: :path

    before do
      @player = Unlight::Player[env['REMOTE_USER']]
    end

    mount Game::V1::Avatar
  end
end
