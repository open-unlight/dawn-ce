# frozen_string_literal: true

FactoryBot.define do
  factory :event_quest_flag_inventory, class: 'Unlight::EventQuestFlagInventory' do
    # TODO: Add association
    avatar_id { create(:avatar).id }
    # Defined by Constant
    sequence(:event_id)
  end
end
