# frozen_string_literal: true

RSpec.describe Unlight::ScenarioFlagInventory do
  let(:inventory) { create(:scenario_flag_inventory) }

  describe '#get_flag' do
    subject { inventory.get_flag }

    it { is_expected.to be_a(Hash) }

    context 'when flag is set' do
      let(:inventory) { create(:scenario_flag_inventory, flags: '{:state=>true}') }

      it { is_expected.to have_key(:state) }
    end
  end

  describe '#set_flag' do
    subject(:set_flag) { inventory.set_flag(key, value) }

    let(:key) { :state }
    let(:value) { true }

    it { expect { set_flag }.to change(inventory, :flags).from('{}').to('{:state=>true}') }
  end
end
