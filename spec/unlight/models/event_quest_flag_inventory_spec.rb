# frozen_string_literal: true

RSpec.describe Unlight::EventQuestFlagInventory do
  let(:avatar) { create(:avatar) }

  describe '.create_inv' do
    subject(:create_inv) { described_class.create_inv(avatar.id) }

    it { expect { create_inv }.to change(described_class, :count).by(1) }

    # TODO: Configure default event_id and quest_flag from config
    it { is_expected.to have_attributes(event_id: Unlight::QUEST_EVENT_ID, quest_flag: Unlight::QUEST_EVENT_MAP_START) }
  end

  describe '#inc_quest_clear_num' do
    subject(:increment) { inventory.inc_quest_clear_num(amount) }

    let(:inventory) { create(:event_quest_flag_inventory) }
    let(:amount) { 1 }

    it { is_expected.to be_zero }
    it { expect { increment }.to change(inventory, :quest_clear_num).by(1) }
  end

  describe '#inc_quest_map_clear_num' do
    subject(:increment) { inventory.inc_quest_map_clear_num(amount) }

    let(:inventory) { create(:event_quest_flag_inventory, quest_flag: 0, quest_clear_num: 1) }
    let(:amount) { 0 }

    it { is_expected.to eq(-1) }
    it { expect { increment }.not_to change(inventory, :quest_flag) }
    it { expect { increment }.not_to change(inventory, :quest_clear_num) }

    pending 'ensure quest flag has default value'

    context 'when cleared' do
      let(:amount) { 1 }

      it { is_expected.to be_zero }
      it { expect { increment }.to change(inventory, :quest_flag) }
      it { expect { increment }.to change(inventory, :quest_clear_num).to(0) }
    end
  end

  describe '#quest_map_clear' do
    subject(:clear) { inventory.quest_map_clear(map_id) }

    let(:inventory) { create(:event_quest_flag_inventory, quest_flag: 0, quest_clear_num: 1) }
    let(:map_id) { 1 }

    it { is_expected.to be_truthy }
    it { expect { clear }.to change(inventory, :quest_flag).to(map_id) }
    it { expect { clear }.to change(inventory, :quest_clear_num).to(0) }
  end
end
