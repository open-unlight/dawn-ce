# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # イベントカードクラス
  class EquipCard < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # アップデート後の後理処
    after_save do
      Unlight::EquipCard.refresh_data_version
      Unlight::EquipCard.cache_store.delete("equip_card:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('EquipCardVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('EquipCardVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = Unlight::EquipCard.order(:updated_at).last
      if m
        cache_store.set('EquipCardVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
    end

    # キャラで使えるかチェック
    def check_using_chara(chara_no)
      ret = true
      unless restriction_charas.empty?
        ret = restriction_charas.include?(chara_no)
      end
      ret
    end

    # キャラ制限のリストを返す
    def restriction_charas
      ret = EquipCard.cache_store.get("equip_card:restricrt:#{id}")
      unless ret
        ret = restriction.split('|')
        EquipCard.cache_store.set("equip_card:restricrt:#{id}", ret)
      end
      ret
    end
  end
end
