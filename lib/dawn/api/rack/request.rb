# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'rack/auth/abstract/request'

module Dawn
  module API
    module Rack
      # Open Unlight Signature-based Request Handler
      #
      # @since 0.1.0
      class Request < ::Rack::Auth::AbstractRequest
        # Ensure request use DAWN-HMAC-SHA256 as authorization
        #
        # @return [TrueClass|Flass]
        #
        # @since 0.1.0
        def dawn?
          scheme == 'dawn-hmac-sha256' && player_id
        end

        # Cerdentials
        #
        # Decoded with Player ID, Signature and Nonce
        #
        # @return [Hash] cerdentials
        #
        # @since 0.1.0
        def credentials
          @credentials ||= ::Rack::Utils.parse_query(params)
        end

        # Player ID
        #
        # @return [Fixnum] the player_id to authorize
        #
        # @since 0.1.0
        def player_id
          credentials['PlayerId'].to_i
        end

        # Nonce
        #
        # @return [String]
        #
        # @since 0.1.0
        def nonce
          credentials['Nonce']
        end

        # Payload
        #
        # The content to signature
        #
        # @return [String]
        #
        # @since 0.1.0
        def payload
          @payload ||=
            begin
              body = request.body.read
              request.body.rewind
              "#{request.query_string}#{body}"
            end
        end

        # Signature
        #
        # @return [String]
        #
        # @since 0.1.0
        def signature
          credentials['Signature']
        end
      end
    end
  end
end
