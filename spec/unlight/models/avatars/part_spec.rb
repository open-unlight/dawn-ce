# frozen_string_literal: true

RSpec.describe Unlight::Avatar do
  subject(:avatar) { create(:avatar) }

  describe '#part_list_str' do
    subject { avatar.part_list_str }

    it { is_expected.to eq('') }

    context 'when has parts' do
      before do
        create(:part_inventory, avatar: avatar, avatar_part_id: 1)
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq('1,2') }
    end
  end

  describe '#part_inventories_list_str' do
    subject { avatar.part_inventories_list_str }

    it { is_expected.to eq('') }

    context 'when has parts' do
      let!(:item1) { create(:part_inventory, avatar: avatar, avatar_part_id: 1) }
      let!(:item2) { create(:part_inventory, avatar: avatar, avatar_part_id: 2) }

      it { is_expected.to eq([item1, item2].map(&:id).join(',')) }
    end
  end
end
