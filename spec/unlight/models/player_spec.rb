# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Unlight::Player do
  describe '.logout_all' do
    subject(:logout_all) { described_class.logout_all }

    before(:each) { create_list(:player, 5, state: Unlight::ST_LOGIN) }

    it { expect { logout_all }.to change { described_class.filter({ state: Unlight::ST_LOGIN }).count }.by(-5) }
  end

  describe '.state_clear_all' do
    subject(:state_clear_all) { described_class.state_clear_all }

    before(:each) { create_list(:player, 5, state: Unlight::ST_LOGIN) }

    xit 'is deprecated method' do
      expect { state_clear_all }.to change { described_class.filter({ state: Unlight::ST_LOGIN }).count }.by(-5)
    end
  end

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

  describe '.reregist' do
    subject(:reregist) do
      described_class.reregist(name, email, salt, verifier, Unlight::SERVER_SB)
    end

    let!(:player) { create(:player, name: 'exist-player') }
    let(:name) { player.name }
    let(:email) { Faker::Internet.email }
    let(:salt) { Faker::Crypto.sha1 }
    let(:verifier) { Faker::Crypto.sha1 }

    it { expect { reregist }.to change { player.reload.salt }.to(salt) }
    it { expect { reregist }.to change { player.reload.verifier }.to(verifier) }

    context 'when player not exists' do
      let(:name) { 'non-exists' }

      it { is_expected.to be_nil }
    end
  end

  shared_examples 'get system player' do
    it { expect { get_system_player }.to change(described_class, :count).by(1) }

    context 'when system player exists' do
      before(:each) { get_system_player }

      it { expect { get_system_player }.not_to change(described_class, :count) }
    end
  end

  describe '.get_cpu_player' do
    subject(:get_system_player) { described_class.get_cpu_player }

    it_behaves_like 'get system player'
  end

  describe '.get_prf_owner_player' do
    subject(:get_system_player) { described_class.get_prf_owner_player }

    it_behaves_like 'get system player'
  end

  describe '.auth_off_all' do
    subject(:auth_off_all) { described_class.auth_off_all }

    before(:each) { create_list(:player, 5, state: Unlight::ST_LOGIN_AUTH) }

    it { expect { auth_off_all }.to change { described_class.filter("state >= #{Unlight::ST_AUTH}").count }.by(-5) }
  end
end
