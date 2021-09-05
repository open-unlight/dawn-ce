# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # パーツのインベントリクラス
  class PartInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :avatar         # アバターを持つ
    many_to_one :avatar_part    # アバターパーツを持つ

    plugin :validation_class_methods
    plugin :hook_class_methods

    # バリデーションの設定
    validates do
    end

    # 装備しているか？
    def equiped?
      if avatar_id.zero?
        false
      else
        used & Unlight::APS_USED == Unlight::APS_USED
      end
    end

    # アクティベートされているか
    def activated?
      if avatar_id.zero?
        false
      else
        used & Unlight::APS_ACTIVATED == Unlight::APS_ACTIVATED
      end
    end

    # 装備する
    def equip(saving = true)
      self.used ||= 0
      unless equiped?
        self.used |= Unlight::APS_USED
        activate
        avatar_part.attach(avatar) if avatar && avatar_part
        save_changes if saving
      end
    end

    # 装備を外す
    def unequip(saving = true)
      # 装備していたら外す
      if equiped?
        self.used ^= Unlight::APS_USED
        avatar_part.detach(avatar)
        save_changes if saving
      end
    end

    # アクティベート（タイマーを動かす）
    def activate
      # アクティベート済みでないなら
      unless activated?
        if avatar_part && avatar_part.duration != 0
          self.end_at = Time.now.utc + avatar_part.duration * 60
          self.used |= Unlight::APS_ACTIVATED
        end
      end
    end

    # 機能が消失したか？
    def work_end?
      ret = false
      if end_at
        ret = Time.now.utc > end_at
        if ret
          unequip(false)
          vanish_part
        end
      end
      ret
    end

    # パーツの消滅
    def vanish_part
      self.before_avatar_id = avatar_id
      self.avatar_id = 0
      save_changes
    end

    def get_end_at(now)
      ret = 0
      if end_at
        ret = (end_at - now).to_i
      else
        ret = 0
      end
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
