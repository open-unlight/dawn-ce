# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # イベントクエストフラグ管理クラス
  class EventQuestFlag < Sequel::Model

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    one_to_one :avatar         # アバターと一対一
    one_to_many :event_quest_flag_inventories         # インベントリを複数所持する

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true #, :table => :avatars
      datetime    :created_at
      datetime    :updated_at
    end

    if !(EventQuestFlag.table_exists?)
      EventQuestFlag.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def now_event(r = true)
      ret = nil
      refresh if r
      self.event_quest_flag_inventories.each do |i|
        ret = i if i.event_id == QUEST_EVENT_ID
      end
      ret
    end

    # 削除時の後処理
    before_destroy do
      refresh
    end
  end
end

