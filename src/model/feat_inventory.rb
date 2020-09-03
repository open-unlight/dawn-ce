# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 必殺技のインベントリクラス
  class FeatInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :chara_card        # キャラカード複数所持される
    many_to_one :feat   # キャラカードを複数もてる

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :chara_card_id, :index=>true#, :table => :avatars
      integer :feat_id#, :table => :feats
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

    # DBにテーブルをつくる
    if !(FeatInventory.table_exists?)
      FeatInventory.create_table
    end


    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # 全体データバージョンを返す
    def FeatInventory::data_version
      ret = cache_store.get("FeatInventoryVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("FeatInventoryVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def FeatInventory::refresh_data_version
      m = FeatInventory.order(:updated_at).last
      if m
        cache_store.set("FeatInventoryVersion", m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

  end
end
