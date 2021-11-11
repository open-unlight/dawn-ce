# frozen_string_literal: true

RSpec.describe Unlight::Avatar do
  subject(:avatar) { create(:avatar) }

  describe '#item_list_str' do
    subject { avatar.item_list_str }

    it { is_expected.to eq('') }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1)
        create(:item_inventory, avatar: avatar, avatar_item_id: 2)
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq('1,2') }
    end
  end

  describe '#item_state_list_str' do
    subject { avatar.item_state_list_str }

    it { is_expected.to eq('') }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1)
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USING)
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq('0,1') }
    end
  end

  describe '#item_inventories_list_str' do
    subject { avatar.item_inventories_list_str }

    it { is_expected.to eq('') }

    context 'when has items' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: 1) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: 2) }

      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq([item1, item2].map(&:id).join(',')) }
    end
  end
end
