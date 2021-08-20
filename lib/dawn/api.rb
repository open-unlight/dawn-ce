# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'rack/cors'
require 'grape'

require 'dawn/api/base'
require 'dawn/api/rack/auth'

module Dawn
  # API Provider
  #
  # @since 0.1.0
  module API
    Grape::Middleware::Auth::Strategies.add(:dawn, Dawn::API::Rack::Auth)
  end
end
