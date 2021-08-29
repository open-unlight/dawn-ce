# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }
  let!(:avatar) { create :avatar, player: player }
  let(:binder) { player.current_avatar.binder }

  describe 'GET /v1/slot_cards' do
    before(:each) do
      create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

      with_player_id(player.id)
      get '/v1/slot_cards'
    end

    let(:items) { JSON.parse(last_response.body).fetch('data', []) }

    it { expect(last_response.status).to eq(200) }
    it { expect(items.size).to eq(1) }
    it { expect(items[0]).to a_hash_including('deck_id' => binder.id) }
    it { expect(items[0]).to a_hash_including('type' => 2) }
    it { expect(items[0]).to a_hash_including('card_id' => 1) }
    it { expect(items[0]).to a_hash_including('deck_position' => 0) }
    it { expect(items[0]).to a_hash_including('card_position' => 0) }
  end

  describe 'PUT /v1/slot_cards/:id/deck' do
    let!(:target_deck) { create :chara_card_deck, avatar: avatar }
    let(:character_card) { instance_double(Unlight::CharaCard) }
    let(:event_card) { instance_double(Unlight::EventCard, color: 0) }
    let(:data) { JSON.parse(last_response.body) }

    before(:each) do
      # TODO: Avoid to mock all instances
      allow_any_instance_of(Unlight::CharaCardDeck).to receive(:cards).and_return([character_card]) # rubocop:disable RSpec/AnyInstance
      allow(Unlight::EventCard).to receive(:[]).with(1).and_return(event_card)
    end

    context 'when equip card success' do
      before(:each) do
        create :card_inventory, chara_card_deck_id: target_deck.id, chara_card_id: 1
        inv = create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

        with_player_id(player.id)
        put "/v1/slot_cards/#{inv.id}/deck", { index: 1, deck_position: 0, card_position: 1 }
      end

      it { expect(last_response.status).to eq(200) }
      it { expect(data).to a_hash_including('deck_id' => target_deck.id) }
      it { expect(data).to a_hash_including('deck_position' => 0) }
      it { expect(data).to a_hash_including('card_position' => 1) }
    end

    context 'when card deck not found' do
      before(:each) do
        inv = create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

        with_player_id(player.id)
        put "/v1/slot_cards/#{inv.id}/deck", { index: 999, deck_position: 0, card_position: 1 }
      end

      it { expect(last_response.status).to eq(404) }
    end

    context 'when card inventory not found' do
      before(:each) do
        with_player_id(player.id)
        put '/v1/slot_cards/999/deck', { index: 1, deck_position: 0, card_position: 1 }
      end

      it { expect(last_response.status).to eq(404) }
    end

    context 'when slot is full' do
      before(:each) do
        # TODO: Avoid to mock all instances
        allow_any_instance_of(Unlight::CharaCardDeck).to receive(:event_cards).and_return([[0] * 100]) # rubocop:disable RSpec/AnyInstance

        create :card_inventory, chara_card_deck_id: target_deck.id, chara_card_id: 1
        inv = create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

        with_player_id(player.id)
        put "/v1/slot_cards/#{inv.id}/deck", { index: 1, deck_position: 0, card_position: 1 }
      end

      it { expect(last_response.status).to eq(400) }
    end

    context 'when color slot not enough' do
      let(:event_card) { instance_double(Unlight::EventCard, color: 1) }

      before(:each) do
        allow(character_card).to receive(:slot_color_num).and_return(1)

        create :card_inventory, chara_card_deck_id: target_deck.id, chara_card_id: 1
        inv = create :chara_card_slot_inventory, chara_card_deck_id: binder.id, card_id: 1

        with_player_id(player.id)
        put "/v1/slot_cards/#{inv.id}/deck", { index: 1, deck_position: 0, card_position: 1 }
      end

      it { expect(last_response.status).to eq(400) }
    end
  end
end
