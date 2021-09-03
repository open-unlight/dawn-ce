# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'dawn/api'
require 'api/game/v1'

class GameAPI < Dawn::API::Base
  desc 'Get game server status'
  get '/status' do
    # TODO: Provide more information about game server
    {
      status: :ok
    }
  end

  auth :dawn, { realm: 'Game API' } do |player_id, nonce, payload, signature|
    Dawn::API::Authenticator.new(player_id, nonce, payload).valid?(signature)
  end

  version 'v1', using: :path do
    mount Game::APIv1
  end
end
