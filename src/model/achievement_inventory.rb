# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # カードのインベントリクラス
  class AchievementInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :achievement # キャラカードを複数もてる

    plugin :validation_class_methods
    plugin :hook_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def restart
      SERVER_LOG.info('<>Avatar: achievement inv restart start')

      self.state = ACHIEVEMENT_STATE_START
      self.progress = 0
      save_changes
      SERVER_LOG.info('<>Avatar: achievement inv restart end')
    end

    def finish
      self.state = ACHIEVEMENT_STATE_FINISH
      if achievement
        self.code = achievement.get_code
      end
      save_changes
    end

    def failed
      self.state = ACHIEVEMENT_STATE_FAILED
      save_changes
    end

    # 終了済みとして、avatar_idをbefore_avatar_idに移す
    def finish_delete
      self.before_avatar_id = avatar_id
      self.avatar_id = 0
      # 達成してない場合は、ステータスを失敗に変更しておく
      self.state = ACHIEVEMENT_STATE_FAILED if state != ACHIEVEMENT_STATE_FINISH
      save_changes
    end

    def is_end
      ret = true
      if end_at
        t = Time.now.utc
        ret = end_at < t
      end
      ret
    end

    def check_time_over?
      ret = false
      if achievement
        ret = is_end if end_at
        ret ||= (achievement.check_expiration == false)
        if ret
          self.before_avatar_id = avatar_id
          self.avatar_id = 0
          self.state = ACHIEVEMENT_STATE_FAILED
          save_changes
        end
      end
      ret
    end

    def progress_inheriting
      prev_id = achievement.get_inheriting_progress
      if prev_id != 0
        prev_ai = AchievementInventory.where(avatar_id: avatar_id, achievement_id: prev_id).all.first
        self.progress = prev_ai.progress
        save_changes
      end
    end
  end
end
