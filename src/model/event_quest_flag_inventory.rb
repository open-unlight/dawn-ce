# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # イベントクエストフラグのインベントリクラス
  class EventQuestFlagInventory < Sequel::Model
    # 他クラスのアソシエーション
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer   :avatar_id,:index => true
      integer   :event_quest_flag_id,:default=>0,:index => true
      integer   :event_id,:index => true
      integer   :quest_flag
      integer   :quest_clear_num, :default => 0
      datetime  :created_at
      datetime  :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(EventQuestFlagInventory.table_exists?)
      EventQuestFlagInventory.create_table
    end

    DB.alter_table :event_quest_flag_inventories do
      add_column :avatar_id, :integer, :index => true unless Unlight::EventQuestFlagInventory.columns.include?(:avatar_id)  # 新規追加2015/05/18
    end

    def EventQuestFlagInventory::create_inv(avatar_id,event_id=QUEST_EVENT_ID,map_start = QUEST_EVENT_MAP_START)
      inv = EventQuestFlagInventory.new do |d|
        d.avatar_id = avatar_id
        d.event_id = event_id
        d.quest_flag = map_start
        d.save
      end
      inv
    end

    # アバターのフラグインベントリリスト取得
    def EventQuestFlagInventory::get_avatar_event(avatar_id)
      self.filter([[:avatar_id,avatar_id]]).all
    end
    # クエスト進行度を増やす
    def inc_quest_clear_num(i)
      self.quest_clear_num = self.quest_clear_num + i
      self.save_changes
      0
    end

    # クエストマップ進行度を増やす
    def inc_quest_map_clear_num(i)
      ret = -1
      map_id = self.quest_flag + i
      if self.quest_flag < map_id
        self.quest_flag = map_id
        self.quest_clear_num  = 0
        ret = 0
      end
      self.save_changes
      ret
    end


    # マップ進行度を更新する
    def quest_map_clear(map_id)
      self.quest_flag = map_id
      self.quest_clear_num = 0
      self.save_changes
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
