# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  let(:player) { create :player, session_key: 'rspec' }

  describe 'GET /v1/avatar' do
    before(:each) do
      create :avatar, name: 'Sheri', gems: 1000, player: player
      with_player_id(player.id)
      get '/v1/avatar'
    end

    let(:data) { JSON.parse(last_response.body).fetch('data', {}) }

    it { expect(last_response.status).to eq(200) }
    it { expect(data).to a_hash_including({ 'name' => 'Sheri' }) }
    it { expect(data).to a_hash_including({ 'gems' => 1000 }) }
    it { expect(data).to a_hash_including({ 'exp' => 0 }) }
    it { expect(data).to a_hash_including({ 'ap' => [5, 5] }) }
  end
end
