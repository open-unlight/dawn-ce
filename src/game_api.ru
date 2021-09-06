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

    resource '*', headers: :any, methods: %i[get post put delete options]
  end
end

run GameAPI
