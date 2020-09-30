# frozen_string_literal: true

RSpec.describe Unlight::PaymentLog do
  let(:payment) { create(:payment_log) }

  describe '#item_got' do
    subject(:get_item) { payment.item_got }

    it { expect { get_item }.to change(payment, :result).to Unlight::PaymentLog::STATE_END }
  end
end
