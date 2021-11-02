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

    context 'with started achievement inventory' do
      let(:achievement) { create(:achievement) }
      let!(:inventory) { create(:achievement_inventory, avatar_id: avatar.id, achievement_id: achievement.id, state: Unlight::ACHIEVEMENT_STATE_START) }

      it do
        check
        args = [
          inventory.achievement_id.to_s, inventory.state.to_s, inventory.progress.to_s, '', inventory.code.to_s
        ]
        expect(event).to have_received(:update_achievement_info_event).with(*args)
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
end
