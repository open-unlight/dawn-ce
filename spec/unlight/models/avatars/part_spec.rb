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

  describe '#parts_end_at_list_str' do
    subject { avatar.parts_end_at_list_str }

    it { is_expected.to eq('') }

    context 'when has parts' do
      before do
        allow(Time).to receive(:now).and_return(DateTime.parse('2021-11-10').to_time)
        create(:part_inventory, avatar: avatar, avatar_part_id: 1, end_at: DateTime.parse('2021-11-11'))
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq('86400,0') }
    end
  end

  describe '#part_used_list_str' do
    subject { avatar.part_used_list_str }

    it { is_expected.to eq('') }

    context 'when has parts' do
      before do
        create(:part_inventory, avatar: avatar, avatar_part_id: 1, used: 1)
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq('1,0') }
    end
  end

  describe '#setted_parts_id_list' do
    subject { avatar.setted_parts_id_list }

    it { is_expected.to be_empty }

    context 'when has parts' do
      before do
        create(:part_inventory, avatar: avatar, avatar_part_id: 1, used: Unlight::APS_USED)
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq([1]) }
    end
  end

  describe '#setted_parts_list_str' do
    subject { avatar.setted_parts_list_str }

    it { is_expected.to eq('') }

    context 'when has parts' do
      before do
        create(:part_inventory, avatar: avatar, avatar_part_id: 1, used: Unlight::APS_USED)
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq('1') }
    end
  end

  describe '#get_equiped_parts_list' do
    subject { avatar.get_equiped_parts_list }

    it { is_expected.to be_empty }

    context 'when has parts' do
      let(:part) { create(:avatar_part) }

      before do
        create(:part_inventory, avatar: avatar, avatar_part_id: part.id, used: Unlight::APS_USED)
        create(:part_inventory, avatar: avatar, avatar_part_id: 2)
      end

      it { is_expected.to eq([part]) }
    end
  end
end
