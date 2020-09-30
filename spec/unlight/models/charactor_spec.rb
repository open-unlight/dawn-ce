# frozen_string_literal: true

RSpec.describe Unlight::Charactor do
  describe '.initialize_charactor_param' do
    subject { described_class.initialize_charactor_param }

    it { is_expected.to be_empty }

    context 'when charactor exists' do
      before(:each) { create(:charactor) }

      it { is_expected.not_to be_empty }
    end
  end

  describe '.attribute' do
    subject { described_class.attribute(id) }

    let(:id) { 1 }

    it { is_expected.to eq([]) }

    context 'when charactor exists' do
      let!(:charactor) { create(:charactor, chara_attribute: 'A,B') }

      let(:id) { charactor.id }

      before(:each) { described_class.initialize_charactor_param }

      it { is_expected.to be_a(Array) }
      it { is_expected.to eq(%w[A B]) }
    end
  end

  describe '#get_data_csv_str' do
    subject { charactor.get_data_csv_str }

    let(:charactor) { create(:charactor) }

    it { is_expected.to be_a(String) }

    pending 'verify csv string format'
  end
end
