# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # カードのインベントリクラス
  class AchievementInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :achievement   # キャラカードを複数もてる

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true #, :table => :chara_card_decks
      integer     :achievement_id          #, :table => :chara_cards
      integer     :state, :default => 0, :null =>false
      integer     :progress, :default => 0
      integer     :before_avatar_id, :default => 0
      datetime    :end_at
      String      :code, :default =>""         # 専用コード（置き換え文字列）
      datetime    :created_at
      datetime    :updated_at
    end

   # DBにテーブルをつくる
    if !(AchievementInventory.table_exists?)
      AchievementInventory.create_table
    end


    DB.alter_table :achievement_inventories do
      add_column :progress, :integer, :default => 0 unless Unlight::AchievementInventory.columns.include?(:progress)  # 新規追加2011/07/25
      add_column :before_avatar_id, :integer, :default => 0 unless Unlight::AchievementInventory.columns.include?(:before_avatar_id)  # 新規追加2011/07/25
      add_column :end_at, :datetime unless Unlight::AchievementInventory.columns.include?(:end_at)  # 新規追加 2013/02/25
      add_column :code, String, :default => "" unless Unlight::AchievementInventory.columns.include?(:code)           # 新規追加2015/04/13
    end

    # バリデーションの設定
     validates do
     end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def restart
      SERVER_LOG.info("<>Avatar: achievement inv restart start")

      self.state = ACHIEVEMENT_STATE_START
      self.progress = 0
      self.save_changes
      SERVER_LOG.info("<>Avatar: achievement inv restart end")
    end

    def finish
      self.state = ACHIEVEMENT_STATE_FINISH
      if self.achievement
        self.code = self.achievement.get_code
      end
      self.save_changes
    end

    def failed
      self.state = ACHIEVEMENT_STATE_FAILED
      self.save_changes
    end

    # 終了済みとして、avatar_idをbefore_avatar_idに移す
    def finish_delete
      self.before_avatar_id = self.avatar_id
      self.avatar_id = 0
      # 達成してない場合は、ステータスを失敗に変更しておく
      self.state = ACHIEVEMENT_STATE_FAILED if self.state != ACHIEVEMENT_STATE_FINISH
      self.save_changes
    end

    def is_end
      ret = true
      if self.end_at
        t = Time.now.utc
        ret = self.end_at < t
      end
      ret
    end

    def check_time_over?
      ret = false
      if self.achievement
        ret = self.is_end if self.end_at
        unless ret
          ret = (self.achievement.check_expiration == false)
        end
        if ret
          self.before_avatar_id = self.avatar_id
          self.avatar_id = 0
          self.state = ACHIEVEMENT_STATE_FAILED
          self.save_changes
        end
      end
      ret
    end

    def progress_inheriting
      prev_id = self.achievement.get_inheriting_progress
      if prev_id != 0
        prev_ai = AchievementInventory.filter([:avatar_id => self.avatar_id, :achievement_id => prev_id]).all.first
        self.progress = prev_ai.progress
        self.save_changes
      end
    end

  end

end
