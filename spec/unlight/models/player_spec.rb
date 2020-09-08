# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unlight::Player do
  describe '.regist' do
    subject(:regist) do
      described_class.regist(name, email, salt, verifier, Unlight::SERVER_SB)
    end

    let(:name) { Faker::Internet.username }
    let(:email) { Faker::Internet.email }
    let(:salt) { Faker::Crypto.sha1 }
    let(:verifier) { Faker::Crypto.sha1 }

    it { expect { regist }.to change(described_class, :count).by(1) }
    it { is_expected.to eq(Unlight::RG_NG[:none]) }

    context 'when duplicate player name' do
      before(:each) { create(:player, name: name) }

      it { expect { regist }.to change(described_class, :count).by(0) }
      it { is_expected.to eq(Unlight::RG_NG[:name]) }
    end
  end
end
