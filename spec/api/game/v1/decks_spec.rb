# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }

  describe 'GET /v1/decks' do
    before(:each) do
      # TODO: Player regist should not be dependency
      avatar = build :avatar, player: player
      Unlight::Avatar.regist(avatar.name, player.id, [], [])

      with_player_id(player.id)
      get '/v1/decks'
    end

    let(:items) { JSON.parse(last_response.body).fetch('data', []) }

    it { expect(last_response.status).to eq(200) }
    it { expect(items.size).to eq(4) }
    it { expect(items[0]).to a_hash_including('name' => 'Binder') }
    it { expect(items[0]).to a_hash_including('level' => 1) }
    it { expect(items[0]).to a_hash_including('exp' => 0) }
    it { expect(items[0]).to a_hash_including('status' => 0) }
    it { expect(items[0]).to a_hash_including('cost' => 0) }
    it { expect(items[0]).to a_hash_including('max_cost' => 45) }
    it { expect(items[0]).to a_hash_including('is_binder' => true) }

    it { expect(items[1]).to a_hash_including('is_binder' => false) }
  end
end
