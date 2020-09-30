# frozen_string_literal: true

RSpec.describe Unlight::Dialogue do
  describe '.data_version' do
    subject { described_class.data_version }

    it { is_expected.to be_zero }
  end

  describe '.refresh_data_version' do
    subject { described_class.refresh_data_version }

    it { is_expected.to be_zero }

    context 'when new data added' do
      before(:each) { create(:dialogue) }

      after(:each) { described_class.cache_store.set('DialogueVersion', nil) }

      it { is_expected.not_to be_zero }
    end
  end

  describe '#version' do
    subject { dialogue.version }

    let(:dialogue) { create(:dialogue) }

    it { is_expected.not_to be_zero }
  end
end
