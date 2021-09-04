# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }
  let(:avatar) { create :avatar, player: player }

  describe 'GET /v1/items' do
    let(:state) { Unlight::ITEM_STATE_NOT_USE }
    let(:items) { JSON.parse(last_response.body).fetch('data', []) }

    before do
      create :item_inventory, avatar_id: avatar.id, avatar_item_id: 1, state: state

      with_player_id(player.id)
      get '/v1/items'
    end

    it { expect(last_response.status).to eq(200) }
    it { expect(items.size).to eq(1) }
    it { expect(items[0]).to have_key('id') }
    it { expect(items[0]).to a_hash_including('avatar_item_id' => 1) }
    it { expect(items[0]).to a_hash_including('state' => 0) }

    context 'when avatar item is using' do
      let(:state) { Unlight::ITEM_STATE_USING }

      it { expect(last_response.status).to eq(200) }
      it { expect(items.size).to eq(0) }
    end

    context 'when avatar item is used' do
      let(:state) { Unlight::ITEM_STATE_USED }

      it { expect(last_response.status).to eq(200) }
      it { expect(items.size).to eq(0) }
    end
  end
end
