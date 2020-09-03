# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 必殺技のインベントリクラス
  class PassiveSkillInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :chara_card        # キャラカード複数所持される
    many_to_one :passive_skill   # キャラカードを複数もてる

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :chara_card_id, :index=>true#, :table => :avatars
      integer :passive_skill_id#, :table => :passive_skills
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

    # DBにテーブルをつくる
    if !(PassiveSkillInventory.table_exists?)
      PassiveSkillInventory.create_table
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
    def PassiveSkillInventory::data_version
      ret = cache_store.get("PassiveSkillInventoryVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("PassiveSkillInventoryVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def PassiveSkillInventory::refresh_data_version
      m = PassiveSkillInventory.order(:updated_at).last
      if m
        cache_store.set("PassiveSkillInventoryVersion", m.version)
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
