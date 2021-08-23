# frozen_string_literal: true

require_relative './unlight'
require 'api/game_api'
require 'rack/cors'

use Rack::Cors do
  allow do
    if ENV['GAME_API_CORS']
      origins ENV['GAME_API_CORS'].split(',').map(&:strip)
    else
      origins '*'
    end

    # TODO: Add POST / PUT / DELETE support in the future
    resource '*', headers: :any, methods: [:get, :options]
  end
end

run GameAPI
