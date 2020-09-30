# frozen_string_literal: true

FactoryBot.define do
  factory :scenario_flag_inventory, class: 'Unlight::ScenarioFlagInventory' do
    # TODO: Add association
    avatar_id { create(:avatar).id }
  end
end
