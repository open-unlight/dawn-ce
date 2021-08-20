# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'rack/auth/abstract/handler'

require 'dawn/api/rack/request'

module Dawn
  module API
    module Rack
      # Open Unlight Signature-based Authenticator
      #
      # @since 0.1.0
      class Auth < ::Rack::Auth::AbstractHandler
        # :nodoc:
        def call(env)
          auth = Dawn::API::Rack::Request.new(env)
          return unauthorized unless auth.provided?
          return bad_request unless auth.dawn?
          return unauthorized unless valid?(auth)

          env['REMOTE_USER'] = auth.player_id
          @app.call(env)
        end

        private

        # @see Rack::Auth::AbstractHandler#challenge
        def challenge
          format('DAWN-HMAC-SHA256 realm="%s"', realm)
        end

        # :nodoc:
        def valid?(auth)
          @authenticator.call(
            auth.player_id,
            auth.nonce,
            auth.payload,
            auth.signature
          )
        end
      end
    end
  end
end
