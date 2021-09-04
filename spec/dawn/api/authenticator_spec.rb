# frozen_string_literal: true

require 'spec_helper'
require 'dawn/api'

RSpec.describe Dawn::API::Authenticator do
  subject(:authenticator) { described_class.new(player_id, nonce, payload) }

  let(:player_id) { 1 }
  let(:nonce) { '1629444946337' }
  let(:payload) { '' }

  describe '#valid?' do
    before do
      player = instance_double(Unlight::Player, session_key: 'c5e8855ac1104f88ed050a2c1f38f521')
      allow(Unlight::Player).to receive(:[]).with(1).and_return(player)
      allow(Time).to receive(:now).and_return(Time.at(1_629_444_946.337))
    end

    it { is_expected.to be_valid('f69d4e13dc0323f6982da0a8baee89d3aa061648d6523e2c40a9dbac2607869a') }

    context 'when player not exists' do
      before { allow(Unlight::Player).to receive(:[]).with(1).and_return(nil) }

      it { is_expected.not_to be_valid('f69d4e13dc0323f6982da0a8baee89d3aa061648d6523e2c40a9dbac2607869a') }
    end

    context 'when signature expired' do
      before do
        allow(Time).to receive(:now).and_return(Time.at(1_629_434_946.337))
      end

      it { is_expected.not_to be_valid('f69d4e13dc0323f6982da0a8baee89d3aa061648d6523e2c40a9dbac2607869a') }
    end

    context 'when signature create in future' do
      before do
        allow(Time).to receive(:now).and_return(Time.at(1_629_454_946.337))
      end

      it { is_expected.not_to be_valid('f69d4e13dc0323f6982da0a8baee89d3aa061648d6523e2c40a9dbac2607869a') }
    end
  end
end
