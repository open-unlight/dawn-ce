# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }

  describe 'GET /v1/slot_cards' do
    before(:each) do
      create :avatar, player: player
      create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

      with_player_id(player.id)
      get '/v1/slot_cards'
    end

    let(:items) { JSON.parse(last_response.body).fetch('data', []) }
    let(:binder) { player.current_avatar.binder }

    it { expect(last_response.status).to eq(200) }
    it { expect(items.size).to eq(1) }
    it { expect(items[0]).to a_hash_including('deck_id' => binder.id) }
    it { expect(items[0]).to a_hash_including('type' => 2) }
    it { expect(items[0]).to a_hash_including('card_id' => 1) }
    it { expect(items[0]).to a_hash_including('deck_position' => 0) }
    it { expect(items[0]).to a_hash_including('card_position' => 0) }
  end
end
