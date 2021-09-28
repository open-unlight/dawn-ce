# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # イベントクエストフラグのインベントリクラス
  class EventQuestFlagInventory < Sequel::Model
    # 他クラスのアソシエーション
    plugin :validation_class_methods
    plugin :hook_class_methods

    def self.create_inv(avatar_id, event_id = QUEST_EVENT_ID, map_start = QUEST_EVENT_MAP_START)
      EventQuestFlagInventory.new do |d|
        d.avatar_id = avatar_id
        d.event_id = event_id
        d.quest_flag = map_start
        d.save_changes
      end
    end

    # アバターのフラグインベントリリスト取得
    def self.get_avatar_event(avatar_id)
      filter([[:avatar_id, avatar_id]]).all
    end

    # クエスト進行度を増やす
    def inc_quest_clear_num(i)
      self.quest_clear_num = quest_clear_num + i
      save_changes
      0
    end

    # クエストマップ進行度を増やす
    def inc_quest_map_clear_num(i)
      ret = -1
      map_id = quest_flag + i
      if quest_flag < map_id
        self.quest_flag = map_id
        self.quest_clear_num = 0
        ret = 0
      end
      save_changes
      ret
    end

    # マップ進行度を更新する
    def quest_map_clear(map_id)
      self.quest_flag = map_id
      self.quest_clear_num = 0
      save_changes
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end
  end
end
