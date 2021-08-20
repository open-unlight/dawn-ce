# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'openssl'

module Dawn
  module API
    # The Signature-based authenticator
    #
    # @since 0.1.0
    class Authenticator
      # @since 0.1.0
      MAX_SIGNATURE_VALID_TIME = 60

      # @param player_id [Fixnum] the player to authenticate
      # @param nonce [String] the request generated timestamp
      # @param payload [String] the query string and request body
      def initialize(player_id, nonce, payload = '')
        @player_id = player_id
        @nonce = nonce
        @timestamp = Time.at(nonce.to_f / 1000)
        @payload = payload
      end

      # @return [Unlight::Player]
      #
      # @todo Allow change resource owner object type
      #
      # @since 0.1.0
      def player
        @player = Unlight::Player[@player_id]
      end

      # Calculate Signature
      #
      # @return [String] signatured value
      #
      # @since 0.1.0
      def signature
        OpenSSL::HMAC
          .hexdigest(
            'SHA256',
            player.session_key,
            "#{@nonce}#{@payload}"
          )
      end

      # Verify signature expired
      #
      # @return [TrueClass|FalseClass]
      #
      # @since 0.1.0
      def expired?
        return true if @timestamp > Time.now

        Time.now - @timestamp > MAX_SIGNATURE_VALID_TIME
      end

      # Verify signature is valid
      #
      # @param provided_signature [String]
      #
      # @return [TureClass|FalseClass]
      #
      # @since 0.1.0
      def valid?(provided_signature)
        return false if player&.session_key.nil?
        return false if expired?

        provided_signature == signature
      end
    end
  end
end
