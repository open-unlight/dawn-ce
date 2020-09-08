# frozen_string_literal: true

require 'factory_bot'

FactoryBot.define do
  # For Sequel
  to_create { |instance| instance.save }
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end
