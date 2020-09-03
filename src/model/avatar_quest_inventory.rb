# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # アバターの保持クエスト
  class AvatarQuestInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :avatar               # アバターに複数所持される
    many_to_one :quest                # クエストに複数所持される

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true #, :table => :avatars
      integer     :quest_id #, :table => :quests
      integer     :status
      integer     :progress, :default => 0
      integer     :deck_index , :default => 1
      integer     :hp0, :default => 0
      integer     :hp1, :default => 0
      integer     :hp2, :default => 0
      integer     :before_avatar_id #, :table => :avatars
      datetime    :find_at
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

   # DBにテーブルをつくる
    if !(AvatarQuestInventory.table_exists?)
      AvatarQuestInventory.create_table
    end

    DB.alter_table :avatar_quest_inventories do
     add_column :before_avatar_id, :integer, :default => 0 unless Unlight::AvatarQuestInventory.columns.include?(:before_avatar_id)  # 新規追加2012/01/13
    end

    def clear_land(no)
      self.progress|=(1<<no)
      self.save_changes
    end

    def land_cleared?(no)
      (self.progress&(1<<no))>0
    end

    def clear_all(succ = true)
      if succ
        self.status = QS_SOLVED
      else
        self.status = QS_FAILED
      end
      self.before_avatar_id = self.avatar_id
      self.avatar_id = 0
      SERVER_LOG.info("QUEST_INV: [clear_all]inv_id:#{self.id},succ #{succ}")
      self.save_changes
    end

    def get_damage_set
      [self.hp0, self.hp1, self.hp2]
    end

    # キャラクタのダメージ量をセットする
    def set_damage_set(set)
      self.hp0 = set[0] if set[0]
      self.hp1 = set[1] if set[1]
      self.hp2 = set[2] if set[2]
      self.save_changes
    end

    def restart_quest
      self.progress = 0
      self.save_changes
    end

    # キャラクタの回復量をセットする
    def damage_heal(set)
        if set[0]
          self.hp0 = self.hp0-set[0]
          self.hp0 = 0 if self.hp0 < 0
        end
        if set[1]
          self.hp1 = self.hp1-set[1]
          self.hp1 = 0 if self.hp1 < 0
        end
        if set[2]
          self.hp2 = self.hp2-set[2]
          self.hp2 = 0 if self.hp2 < 0
        end
      self.save_changes

    end

    def damaged?
      refresh
      (self.hp0+ self.hp1+ self.hp2)>0
    end

    # 見つかる時間を保存
    def set_find_time(time,pow=100)
      if QFT_SET[time]
        self.find_at = Time.now.utc+QFT_SET[time]*pow/100
      else
        self.find_at = Time.now.utc+QFT_SET[10]*pow/100
      end
      self.save_changes
    end

    # 発見されたか？
    def quest_find?
      ret = Time.now.utc > self.find_at
      if ret
        self.status = QS_NEW
        self.save_changes
      end
      ret
    end

    # 発見時間を分単位で進める（目標時間を縮める）
    def shorten_find_time(min)
        self.find_at = self.find_at-(min*60)
        self.save_changes
    end

    # 別のアバターに送る
    def send_avatar(a_id)
      self.before_avatar_id = self.avatar_id
      self.avatar_id = a_id
      self.status = QS_PRESENTED
      self.save_changes
    end

    def unsolved?
      (self.status == QS_UNSOLVE||self.status == QS_NEW||self.status == QS_PRESENTED)
    end

    def presented?
      self.avatar_id != self.before_avatar_id
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
