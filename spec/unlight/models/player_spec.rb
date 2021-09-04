# frozen_string_literal: true

RSpec.describe Unlight::Player do
  describe '.logout_all' do
    subject(:logout_all) { described_class.logout_all }

    before { create_list(:player, 5, state: Unlight::ST_LOGIN) }

    it { expect { logout_all }.to change { described_class.filter({ state: Unlight::ST_LOGIN }).count }.by(-5) }
  end

  describe '.state_clear_all' do
    subject(:state_clear_all) { described_class.state_clear_all }

    before { create_list(:player, 5, state: Unlight::ST_LOGIN) }

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
      before { create(:player, name: name) }

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
      before { get_system_player }

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

    before { create_list(:player, 5, state: Unlight::ST_LOGIN_AUTH) }

    it { expect { auth_off_all }.to change { described_class.filter(Sequel.lit("state >= #{Unlight::ST_AUTH}")).count }.by(-5) }
  end

  describe '#login' do
    subject(:login) { player.login(ip, session_key) }

    let(:player) { create(:player, state: Unlight::ST_AUTH) }
    let(:ip) { Faker::Internet.ip_v4_address }
    let(:session_key) { Faker::Crypto.sha1 }

    it { is_expected.to be_truthy }
    it { expect { login }.to(change { player.reload.last_ip }) }
    it { expect { login }.to(change { player.reload.session_key }) }

    context 'when pushout' do
      let(:player) { create(:player, state: Unlight::ST_LOGIN_AUTH) }

      it { is_expected.to be_truthy }
    end

    context 'when comeback' do
      pending 'presents for player if not login in recent days'
    end

    context 'when random sale' do
      pending
    end

    context 'when not under auth state' do
      let(:player) { create(:player) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#logout' do
    subject(:logout) { player.logout }

    let(:player) { create(:player, state: Unlight::ST_LOGIN, login_at: (Time.now - 3600)) }

    it { is_expected.to be_truthy }
    it { expect { logout }.to(change { player.reload.state }) }
    it { expect { logout }.to(change { player.reload.total_time }) }

    context 'when pushout' do
      subject(:pushout) { player.logout(true) }

      it { is_expected.to be_truthy }
      it { expect { pushout }.not_to(change { player.reload.state }) }
      it { expect { pushout }.to(change { player.reload.total_time }) }
    end

    context 'when not login' do
      let(:player) { create(:player, state: Unlight::ST_LOGOUT) }

      it { is_expected.to be_falsy }
    end
  end

  describe '#login_bonus_set' do
    subject { player.login_bonus_set }

    let(:player) { create(:player, login_at: login_at) }
    let(:login_at) { Time.now }

    it { is_expected.to be_falsy }

    context 'when fit offset time' do
      let(:login_at) { Time.now.utc - 60 * 60 * 24 }

      it { is_expected.to be_truthy }
    end
  end

  describe '#update_login_at' do
    subject(:update) { player.update_login_at }

    let(:player) { create(:player) }

    it { expect { update }.to change(player, :login_at) }
  end

  describe '#count_total_time' do
    subject(:count) { player.count_total_time }

    let(:player) { create(:player, logout_at: logout_at, login_at: login_at) }
    let(:logout_at) { nil }
    let(:login_at) { Time.now - 60 * 60 }

    it { expect { count }.to change(player, :total_time) }
  end

  describe '#auth_on' do
    subject(:auth_on) { player.auth_on }

    let(:player) { create(:player) }

    it { expect { auth_on }.to change { player.reload.state }.to(Unlight::ST_AUTH) }
  end

  describe '#auth_off' do
    subject(:auth_off) { player.auth_off }

    let(:player) { create(:player, state: Unlight::ST_AUTH) }

    it { expect { auth_off }.to change { player.reload.state }.to(0) }
  end

  describe '#login?' do
    subject { player.login? }

    let(:player) { create(:player, state: state) }
    let(:state) { 0 }

    it { is_expected.to be_falsy }

    context 'when state is Unlight::ST_LOGIN' do
      let(:state) { Unlight::ST_LOGIN }

      it { is_expected.to be_truthy }
    end
  end

  describe '#auth?' do
    subject { player.auth? }

    let(:player) { create(:player, state: state) }
    let(:state) { 0 }

    it { is_expected.to be_falsy }

    context 'when state is Unlight::ST_AUTH' do
      let(:state) { Unlight::ST_AUTH }

      it { is_expected.to be_truthy }
    end
  end

  describe '#lock' do
    subject(:lock) { player.lock }

    let(:player) { create(:player) }

    it { expect { lock }.to change { player.reload.penalty }.to(Unlight::PN_LOCK) }
  end

  describe '#pass_failed' do
    subject(:lock) { player.pass_failed }

    let(:player) { create(:player) }

    it { expect { lock }.to change { player.reload.penalty }.to(Unlight::PN_PASS_FAIL) }
  end

  describe '#auth_failed' do
    pending
  end

  describe '#same_ip_check' do
    subject(:lock) { player.same_ip_check }

    let(:player) { create(:player) }

    it { expect { lock }.to change { player.reload.penalty }.to(Unlight::PN_SAME_IP) }
  end

  describe '#comeback' do
    subject(:lock) { player.comeback }

    let(:player) { create(:player) }

    it { expect { lock }.to change { player.reload.penalty }.to(Unlight::PN_COMEBACK) }
  end

  describe '#penalty?' do
    subject { player.penalty? }

    let(:player) { create(:player) }

    it { is_expected.to be_falsy }

    context 'when player lock' do
      before { player.lock }

      it { is_expected.to be_truthy }
    end
  end

  describe '#comeback?' do
    subject { player.comeback? }

    let(:player) { create(:player) }

    it { is_expected.to be_falsy }

    context 'when player comeback' do
      before { player.comeback }

      it { is_expected.to be_truthy }
    end
  end

  describe '#current_avatar' do
    subject(:current_avatar) { player.current_avatar }

    let(:player) { create(:player) }

    it { is_expected.to be_a(Unlight::Avatar) }

    context 'when avatar exists' do
      let!(:avatar) { create(:avatar, player_id: player.id) }

      it { is_expected.to eq(avatar) }
    end
  end
end
