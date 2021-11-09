# frozen_string_literal: true

RSpec.describe Unlight::Avatar do
  subject(:avatar) { create(:avatar) }

  describe '#achievement_check' do
    subject(:check) { avatar.achievement_check }

    let(:event) { instance_spy(Unlight::AvatarEvent) }

    before do
      allow(avatar).to receive(:check_new_achievement)
      # TODO: Refactor with service object
      avatar.instance_variable_set(:@event, event)
    end

    it do
      check
      expect(event).to have_received(:update_achievement_info_event).with('', '', '', '', '')
    end

    context 'when achievement inventory is started' do
      let(:achievement) { create(:achievement) }
      let!(:inventory) { create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START) }

      it do
        check
        args = [
          inventory.achievement_id.to_s, Unlight::ACHIEVEMENT_STATE_START.to_s, inventory.progress.to_s, '', inventory.code.to_s
        ]
        expect(event).to have_received(:update_achievement_info_event).with(*args)
      end
    end

    context 'when achievement inventory condition is passed' do
      let(:achievement) { create(:achievement) }
      let!(:inventory) { create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START) }

      before do
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it do
        check
        args = [
          inventory.achievement_id.to_s, Unlight::ACHIEVEMENT_STATE_FINISH.to_s, inventory.progress.to_s, '', inventory.code.to_s
        ]
        expect(event).to have_received(:update_achievement_info_event).with(*args)
      end
    end

    context 'when achievement have items' do
      let(:achievement) { create(:achievement, items: '0/0/0/0') }

      before do
        create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START)
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it do
        check
        expect(event).to have_received(:achievement_clear_event).with(achievement.id, 0, 0, 0, 0)
      end
    end

    context 'when achievement have items but no event' do
      let(:achievement) { create(:achievement, items: '0/0/0/0') }

      before do
        create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START)
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
        avatar.instance_variable_set(:@event, nil)
        allow(avatar).to receive(:write_notice)
      end

      it do
        check
        expect(avatar).to have_received(:write_notice).with(Unlight::NOTICE_TYPE_ACHI_SUCC, "#{achievement.id},0_0_0_0")
      end
    end

    context 'when achievement have selectable items' do
      let(:achievement) { create(:achievement, items: 'S0/0/0/0') }

      before do
        create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START)
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
        allow(avatar).to receive(:write_notice)
      end

      it do
        check
        expect(avatar).to have_received(:write_notice).with(Unlight::NOTICE_TYPE_GET_SELECTABLE_ITEM, achievement.id.to_s)
      end
    end

    context 'when achievement can loop' do
      let(:achievement) { create(:achievement, loop: 5) }

      before do
        create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START)
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
        allow(avatar).to receive(:add_loop_achievement)
      end

      it do
        check
        expect(avatar).to have_received(:add_loop_achievement)
      end
    end

    context 'when achievement loop stop' do
      subject(:check) { avatar.achievement_check(false, nil, 0, true, true) }

      let(:achievement) { create(:achievement, loop: 5) }

      before do
        create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START)
        allow_any_instance_of(Unlight::Achievement).to receive(:cond_check).and_return(true) # rubocop:disable RSpec/AnyInstance
        allow(avatar).to receive(:stop_loop_achievement)
      end

      it do
        check
        expect(avatar).to have_received(:stop_loop_achievement)
      end
    end
  end

  describe '#check_new_achievement' do
    subject(:check) { avatar.check_new_achievement }

    let(:event) { instance_spy(Unlight::AvatarEvent) }

    before do
      # TODO: Refactor with service object
      avatar.instance_variable_set(:@event, event)
    end

    it do
      check
      expect(event).to have_received(:update_achievement_info_event).with('', '', '', '', '')
    end
  end

  describe '#rookie_sale?' do
    subject { avatar.rookie_sale? }

    let(:avatar) { create(:avatar, created_at: DateTime.parse('2021-11-09')) }

    before { allow(Time).to receive(:now).and_return(DateTime.parse('2021-11-10').to_time) }

    it { is_expected.to be_truthy }

    context 'when over 30 days' do
      before { allow(Time).to receive(:now).and_return(DateTime.parse('2021-12-25').to_time) }

      it { is_expected.to be_falsy }
    end

    context 'when created_at is nil' do
      before { allow(avatar).to receive(:created_at).and_return(nil) }

      it { is_expected.to be_falsy }
    end
  end
end
