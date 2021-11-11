# frozen_string_literal: true

RSpec.describe Unlight::Avatar do
  subject(:avatar) { create(:avatar) }

  describe '#quest_id_list_str' do
    subject { avatar.quest_id_list_str }

    it { is_expected.to eq('') }

    context 'when has quests' do
      before do
        create(:avatar_quest_inventory, avatar: avatar, quest_id: 1)
        create(:avatar_quest_inventory, avatar: avatar, quest_id: 2)
      end

      it { is_expected.to eq('1,2') }
    end

    context 'when has pending quests' do
      before do
        allow(Time).to receive(:now).and_return(DateTime.parse('2021-11-10').to_time)
        create(:avatar_quest_inventory, avatar: avatar, quest_id: 1, status: Unlight::QS_PENDING, find_at: DateTime.parse('2021-11-11'))
        create(:avatar_quest_inventory, avatar: avatar, quest_id: 2)
      end

      it { is_expected.to eq('0,2') }
    end
  end

  describe '#quest_inventories_list_str' do
    subject { avatar.quest_inventories_list_str }

    it { is_expected.to eq('') }

    context 'when has quests' do
      let!(:item1) { create(:avatar_quest_inventory, avatar: avatar, quest_id: 1) }
      let!(:item2) { create(:avatar_quest_inventory, avatar: avatar, quest_id: 2) }

      it { is_expected.to eq([item1, item2].map(&:id).join(',')) }
    end
  end
end
