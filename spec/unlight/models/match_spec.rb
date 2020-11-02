# frozen_string_literal: true

RSpec.describe Unlight::Match do
  let(:channel) { create(:channel) }
  let(:match) { described_class.new(channel, player_id, name, stage, rule) }
  let(:player_id) { create(:player).id }
  let(:name) { Faker::Name.name }
  let(:stage) { Unlight::STAGE_CASTLE }
  let(:rule) { Unlight::RULE_3VS3 }

  describe '.new' do
    subject(:new_match) { described_class.new(channel, player_id, name, stage, rule) }

    it { expect { new_match }.not_to raise_error }
  end

  describe '#cpu?' do
    subject { match.cpu? }

    let(:cpu_card_data_id) { 1 }
    let(:match) { described_class.new(channel, player_id, name, stage, rule, 0, 0, cpu_card_data_id) }

    it { is_expected.to be_truthy }
  end

  describe 'include_player?' do
    subject { match.include_player?(another_player_id) }

    let(:another_player_id) { player_id }

    it { is_expected.to be_truthy }

    context 'when player not joined' do
      let(:another_player_id) { create(:player).id }

      it { is_expected.to be_falsy }
    end
  end

  describe 'enter_player' do
    subject(:enter_player) { match.enter_player(player2) }

    let(:player2) { create(:player) }

    it { expect { enter_player }.to change { match.include_player?(player2.id) }.from(false).to(true) }
  end

  describe 'delete_player' do
    subject(:delete_player) { match.delete_player(player_id) }

    it { is_expected.to be_truthy }
    it { expect { delete_player }.to change { match.include_player?(player_id) }.from(true).to(false) }

    xit 'when player_array is empty'
  end

  describe 'room_info' do
    subject(:room_info) { match.room_info }

    before(:each) { create(:avatar, player_id: player_id) }

    it { expect(room_info[0]).to eq(match.id) }
  end

  describe 'room_info_str' do
    subject(:room_info_str) { match.room_info_str }

    before(:each) { create(:avatar, player_id: player_id) }

    it { is_expected.to start_with(match.id) }
  end
end
