# frozen_string_literal: true

require 'openssl'

module Dawn
  module API
    # The Signature-based authenticator
    #
    # @since 0.1.0
    class Authenticator
      # @param player_id [Fixnum] the player to authenticate
      # @param nonce [String]
      # @param payload [String] the query string and request body
      def initialize(player_id, nonce, payload = '')
        @player_id = player_id
        @nonce = nonce
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

      # Verify signature is valid
      #
      # @param signature [String]
      #
      # @return [TureClass|FalseClass]
      #
      # @since 0.1.0
      def valid?(signature)
        return false if player&.session_key.nil?

        OpenSSL::HMAC
          .hexdigest(
            'SHA256',
            player.session_key,
            "#{@nonce}#{@payload}"
          ) == signature
      end
    end
  end
end
