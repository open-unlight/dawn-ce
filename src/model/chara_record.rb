# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # キャラクターとのアバターとの関係データ
  class CharaRecord < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # 他クラスのアソシエーション
    many_to_one :charactor # キャラデータを持つ
    many_to_one :avatar # キャラデータを持つ
    many_to_one :chara_card # キャラデータを持つ

    # バリデーションの設定
    validates do
    end

    # インサート時の前処理
    before_create do
      # アバターとキャラが存在するときにはHPに現在の最大カードを保存する
      cc = avatar.max_cc_level_get(charactor_id) if avatar
      if cc
        self.hit_point = cc.hp
        self.chara_card = cc
      end
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end
  end
end
