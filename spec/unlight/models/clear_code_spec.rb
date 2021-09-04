# frozen_string_literal: true

RSpec.describe Unlight::ClearCode do
  describe '.get_code' do
    subject(:get_code) { described_class.get_code(type, max) }

    let(:type) { 0 }
    let(:max) { 1 }

    it { is_expected.to be_empty }

    context 'when code available' do
      before { create(:clear_code) }

      it { is_expected.not_to be_empty }
      it { expect { get_code }.to change { described_class.filter(state: Unlight::ClearCode::STATE_UNUSE).count }.by(-1) }
    end
  end

  describe '#done?' do
    subject { code.done? }

    let(:code) { create(:clear_code) }

    it { is_expected.to be_falsy }

    context 'when used' do
      let(:code) { create(:clear_code, state: Unlight::ClearCode::STATE_USED) }

      it { is_expected.to be_truthy }
    end
  end
end
