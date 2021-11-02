# frozen_string_literal: true

require 'config'

Config.setup do |config|
  config.const_name = 'Settings'
  config.use_env = true
  config.env_prefix = 'SETTINGS'
  config.env_separator = '__'
  config.env_parse_values = true
end

Config.load_and_set_settings(
  Config.setting_files(Dawn.root.join('config'), Dawn.env)
)
