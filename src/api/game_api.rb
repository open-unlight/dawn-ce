# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'dawn/api'
require 'api/game/v1'

class GameAPI < Dawn::API::Base
  auth :dawn do |_, _, _, _|
    # TODO: Implement Dawn::API::Authenticator
    true
  end

  version 'v1', using: :path do
    mount Game::V1
  end

  get do
    {
      message: 'Hello World'
    }
  end
end
