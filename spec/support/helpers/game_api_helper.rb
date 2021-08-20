# frozen_string_literal: true

require 'api/game_api'

module GameAPIHelper
  def app
    GameAPI
  end

  def with_player_id(player_id, valid: true)
    authenticator = instance_double(Dawn::API::Authenticator)
    allow(authenticator).to receive(:valid?).and_return(valid)
    allow(Dawn::API::Authenticator).to receive(:new).and_return(authenticator)
    header 'Authorization', "DAWN-HMAC-SHA256 PlayerId=#{player_id}&Nonce=TEST&Signature=TEST"
  end

  def with_valid_player_id(player_id)
    with_player_id(player_id)
  end

  def with_invalid_player_id(player_id)
    with_player_id(player_id, valid: false)
  end
end
