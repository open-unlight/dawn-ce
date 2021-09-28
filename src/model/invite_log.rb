# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # ゲームセッションログ
  class InviteLog < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    many_to_one :channel

    attr_accessor :a_point, :b_point

    # 招待する
    def self.invite(pid, uid, check = true)
      if check_already_exist?(pid, uid) && check
        ret = false
      else
        f_l = InviteLog.new do |f|
          f.invite_player_id = pid
          f.invited_user_id = uid
          f.save_changes
        end
        ret = f_l
      end
      ret
    end

    # 後から招待情報を更新する（ニコニコ用）
    def self.invite_after_update(pid, uid, log_id)
      exist = false
      links = InviteLog.filter({ invited_user_id: uid }).all
      exist = links if links.size >= 3

      if exist
        ret = false
      else
        f_l = InviteLog.new do |f|
          f.invite_player_id = pid
          f.invited_user_id = uid
          f.sns_log_id = log_id
          f.save_changes
        end
        ret = f_l
      end
      ret
    end

    # 招待済みか？
    def self.check_invited?(uid)
      ret = false
      links = InviteLog.filter({ invited_user_id: uid, invited: false }).all
      ret = links unless links.empty?
      ret
    end

    # 招待アイテムゲット済みか？
    def self.check_already_invited?(uid)
      ret = false
      links = InviteLog.filter({ invited_user_id: uid, invited: true }).all
      ret = links unless links.empty?
      ret
    end

    # リンクがすでに存在するかしなかったFalse,存在したらそのリンクを返す
    def self.check_already_exist?(pid, uid)
      return true if Player[name: uid]

      ret = false
      links = InviteLog.filter({ invite_player_id: pid, invited_user_id: uid }).all
      ret = links unless links.empty?
      ret
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
