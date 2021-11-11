# Unlight
# Copyright (c) 2019 CPA
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

require 'bundler'

$LOAD_PATH.unshift Bundler.root.join('src')
$LOAD_PATH.unshift Bundler.root.join('lib')
d = File.dirname(__FILE__).gsub!('src', '')
ENV['INLINEDIR'] = "#{d}lib/ruby_inline"

require 'rubygems'
require 'sequel'
require 'logger'
require 'dalli'
require 'sentry-ruby'

require 'active_support'
require 'active_support/core_ext/object/blank'

Sequel::Model.require_valid_table = false
Sequel::Model.plugin :json_serializer

require 'dawn'

# TODO: Refactor to Dawn::AppLoader
# Initialize Extensions
require_relative '../config/initializers/config'
require_relative '../config/initializers/sentry'
# TODO: Require necessary library for Game / API mode
require_relative '../config/initializers/oj'
require_relative '../config/initializers/pagy'
require_relative '../config/initializers/logger'

# db_config.rb
module Unlight
  # Memcache Server
  MEMCACHE_CONFIG = (ENV['MEMCACHED_HOST'] || 'localhost:11211')
  MEMCACHE_OPTIONS = {
    timeout: 1,
    namespace: 'unlight'
  }
end

if File.exist?("#{File.dirname(__FILE__)}/server_ip.rb")
  require 'server_ip'
end

# Dawn
require 'dawn/database'

# 定数
require 'constants/common_constants'
require 'constants/reward_constants'
require 'constants/cpu_data_constants'
require 'constants/constants'
require 'constants/locale_constants'

# ルール
require 'rule/context'
require 'rule/context_value'
require 'rule/event/event'

require 'rule/event/entrant_event'
require 'rule/event/multi_duel_event'
require 'rule/event/chara_card_event'
require 'rule/event/deck_event'
require 'rule/event/action_card_event'
require 'rule/event/avatar_event'
require 'rule/event/reward_event'
require 'rule/event/ai_event'

require 'rule/deck'
require 'rule/event_deck'
require 'rule/reward'
require 'rule/entrant'
require 'rule/multi_duel'

# Model
require 'model/action_card'
require 'model/card_inventory'
require 'model/channel'
require 'model/chara_card'
require 'model/chara_card_requirement'
require 'model/chara_card_slot_inventory'
require 'model/chara_card_deck'
require 'model/chara_card_story'
require 'model/chara_record'
require 'model/cpu_card_data'
require 'model/cpu_room_data'
require 'model/dialogue'
require 'model/dialogue_weight'
require 'model/equip_card'
require 'model/event_card'
require 'model/feat'
require 'model/passive_skill'
require 'model/passive_skill_inventory'
require 'model/feat_inventory'
require 'model/friend_link'
require 'model/invite_log'
require 'model/comeback_log'
require 'model/item_inventory'
require 'model/lot_log'
require 'model/match'
require 'model/match_log'
require 'model/monster_treasure_inventory'
require 'model/part_inventory'
require 'model/payment_log'
require 'model/player'
require 'model/quest'
require 'model/achievement'
require 'model/achievement_inventory'
require 'model/quest_clear_log'
require 'model/quest_land'
require 'model/quest_log'
require 'model/quest_map'
require 'model/rare_card_lot'
require 'model/real_money_item'
require 'model/shop'
require 'model/treasure_data'
require 'model/weapon_card'
require 'model/avatar_item'
require 'model/avatar_part'
require 'model/avatar_quest_inventory'
require 'model/charactor'
require 'model/avatar'
require 'model/total_ranking'
require 'model/weekly_duel_ranking'
require 'model/total_duel_ranking'
require 'model/weekly_quest_ranking'
require 'model/total_quest_ranking'
require 'model/total_chara_vote_ranking'
require 'model/total_event_ranking'
require 'model/estimation_ranking'
require 'model/avatar_notice'
require 'model/avatar_apology'
require 'model/reward_data'
require 'model/event_serial'
require 'model/clear_code'
require 'model/infection_collabo_serial'
require 'model/watch_duel'
require 'model/watch_real_duel'
require 'model/profound_data'
require 'model/profound'
require 'model/profound_inventory'
require 'model/profound_log'
require 'model/profound_comment'
require 'model/profound_treasure_data'
require 'model/scenario'
require 'model/scenario_inventory'
require 'model/scenario_flag_inventory'
require 'model/event_quest_flag'
require 'model/event_quest_flag_inventory'
require 'model/combine_case'
require 'model/reissue_request'
require 'rule/ai'

# メモリリークチェック用関数
module Unlight
end
