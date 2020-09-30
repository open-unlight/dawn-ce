# frozen_string_literal: true

RSpec.describe Unlight::LotLog do
  let(:player_id) { create(:player).id }
  let(:kind) { 1 }
  let(:item_id) { create(:rare_card_lot).id }

  describe '.create_log' do
    subject(:create_log) { described_class.create_log(player_id, kind, item_id) }

    it { expect { create_log }.to change(described_class, :count).by(1) }
  end
end
