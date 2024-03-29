# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # カムバックログ
  class ComebackLog < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    many_to_one :channel

    attr_accessor :a_point, :b_point

    # カムバック依頼をする
    def self.comeback(pid, uid)
      if check_already_exist?(pid, uid)
        ret = false
      else
        f_l = ComebackLog.new do |f|
          f.send_player_id = pid
          f.comebacked_player_id = uid
          f.save_changes
        end
        ret = f_l
      end
      ret
    end

    # カムバック済みか？
    def self.check_comebacked?(uid)
      ret = false
      links = ComebackLog.filter({ comebacked_player_id: uid, comebacked: false }).all
      ret = links unless links.empty?
      ret
    end

    # 招待アイテムゲット済みか？
    def self.check_already_comebacked?(uid)
      ret = false
      links = ComebackLog.filter({ comebacked_player_id: uid, comebacked: true }).all
      ret = links unless links.empty?
      ret
    end

    # リンクがすでに存在するかしなかったFalse,存在したらそのリンクを返す
    def self.check_already_exist?(pid, uid)
      ret = false
      links = ComebackLog.filter({ send_player_id: pid, comebacked_player_id: uid }).all
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
