# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }
  let!(:avatar) { create :avatar, player: player }
  let(:binder) { player.current_avatar.binder }

  describe 'GET /v1/character_cards' do
    before(:each) do
      create :card_inventory, chara_card_deck_id: binder.id, chara_card_id: 1

      with_player_id(player.id)
      get '/v1/character_cards'
    end

    let(:items) { JSON.parse(last_response.body).fetch('data', []) }

    it { expect(last_response.status).to eq(200) }
    it { expect(items.size).to eq(1) }
    it { expect(items[0]).to have_key('id') }
    it { expect(items[0]).to a_hash_including('deck_id' => binder.id) }
    it { expect(items[0]).to a_hash_including('character_card_id' => 1) }
    it { expect(items[0]).to a_hash_including('position' => 0) }
  end

  describe 'PUT /v1/character_cards/:id/deck' do
    let!(:target_deck) { create :chara_card_deck, avatar: avatar }
    let(:data) { JSON.parse(last_response.body) }

    context 'when move card success' do
      before(:each) do
        inv = create :card_inventory, chara_card_deck_id: binder.id, chara_card_id: 1

        with_player_id(player.id)
        put "/v1/character_cards/#{inv.id}/deck", { index: 1, position: 1 }
      end

      it { expect(last_response.status).to eq(200) }
      it { expect(data).to a_hash_including('deck_id' => target_deck.id) }
      it { expect(data).to a_hash_including('position' => 1) }
    end

    context 'when card deck not found' do
      before(:each) do
        inv = create :card_inventory, chara_card_deck_id: binder.id, chara_card_id: 1

        with_player_id(player.id)
        put "/v1/character_cards/#{inv.id}/deck", { index: 999, position: 1 }
      end

      it { expect(last_response.status).to eq(404) }
    end

    context 'when card inventory not found' do
      before(:each) do
        with_player_id(player.id)
        put '/v1/character_cards/999/deck', { index: 1, position: 1 }
      end

      it { expect(last_response.status).to eq(404) }
    end

    context 'when card deck is full' do
      before(:each) do
        inv = create :card_inventory, chara_card_deck_id: binder.id, chara_card_id: 1
        create_list :card_inventory, 4, chara_card_deck_id: target_deck.id, chara_card_id: 1

        with_player_id(player.id)
        put "/v1/character_cards/#{inv.id}/deck", { index: 1, position: 1 }
      end

      it { expect(last_response.status).to eq(400) }
    end
  end
end
