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

  describe '#item_inventories' do
    subject { avatar.item_inventories }

    it { is_expected.to be_empty }

    context 'when has items' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: 1) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED) }

      it { is_expected.to include(item1) }
      it { is_expected.not_to include(item2) }
    end
  end

  describe '#unused_item_inventories' do
    subject { avatar.unused_item_inventories }

    it { is_expected.to be_empty }

    context 'when has items' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: 1) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USING) }
      let!(:item3) { create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED) }

      it { is_expected.to include(item1) }
      it { is_expected.to include(item2) }
      it { is_expected.not_to include(item3) }
    end
  end

  describe '#full_item_inventories' do
    subject { avatar.full_item_inventories }

    it { is_expected.to be_empty }

    context 'when has items' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: 1) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED) }

      it { is_expected.to include(item1) }
      it { is_expected.to include(item2) }
    end
  end

  describe '#items_num' do
    subject { avatar.items_num }

    it { is_expected.to be_zero }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1)
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USING)
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq(2) }
    end
  end

  describe '#tickets' do
    subject { avatar.tickets }

    it { is_expected.to be_empty }

    context 'when has tickets' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: Unlight::RARE_CARD_TICKET) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: Unlight::RARE_CARD_TICKET, state: Unlight::ITEM_STATE_USED) }

      it { is_expected.to include(item1) }
      it { is_expected.not_to include(item2) }
    end
  end

  describe '#copy_tickets' do
    subject { avatar.copy_tickets }

    it { is_expected.to be_empty }

    context 'when has copy tickets' do
      let!(:item1) { create(:item_inventory, avatar: avatar, avatar_item_id: Unlight::COPY_TICKET) }
      let!(:item2) { create(:item_inventory, avatar: avatar, avatar_item_id: Unlight::COPY_TICKET, state: Unlight::ITEM_STATE_USED) }

      it { is_expected.to include(item1) }
      it { is_expected.not_to include(item2) }
    end
  end

  describe '#item_count' do
    subject { avatar.item_count(1) }

    it { is_expected.to be_zero }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1)
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq(1) }
    end
  end

  describe '#item_count_later' do
    subject { avatar.item_count_later(1, DateTime.parse('2021-11-01')) }

    it { is_expected.to be_zero }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, created_at: DateTime.parse('2020-10-11'))
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, created_at: DateTime.parse('2021-11-11'))
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq(1) }
    end
  end

  describe '#set_item_count_later' do
    subject { avatar.set_item_count_later([1, 2], DateTime.parse('2021-11-01').to_time) }

    it { is_expected.to be_zero }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, created_at: DateTime.parse('2021-11-11'))
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, created_at: DateTime.parse('2021-11-11'))
        create(:item_inventory, avatar: avatar, avatar_item_id: 2, created_at: DateTime.parse('2021-10-11'))
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq(2) }
    end
  end

  describe '#full_item_count' do
    subject { avatar.full_item_count(1) }

    it { is_expected.to be_zero }

    context 'when has items' do
      before do
        create(:item_inventory, avatar: avatar, avatar_item_id: 1)
        create(:item_inventory, avatar: avatar, avatar_item_id: 1, state: Unlight::ITEM_STATE_USED)
      end

      it { is_expected.to eq(2) }
    end
  end
end
