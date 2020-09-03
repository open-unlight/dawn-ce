# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # シナリオフラグインベントリクラス
  class ScenarioFlagInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :avatar        # デッキに複数所持される
    many_to_one :scenario   # キャラカードを複数もてる

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true #, :table => :chara_card_decks
      String      :flags, :default => "{}"
      datetime    :created_at
      datetime    :updated_at
    end

   # DBにテーブルをつくる
    if !(ScenarioFlagInventory.table_exists?)
      ScenarioFlagInventory.create_table
    end

    DB.alter_table :scenario_flag_inventories do
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

    def set_flag(key, value)
      if @flag_hash || self.get_flag
        unless @flag_hash[key] == value
          @flag_hash[key] = value
          self.flags = @flag_hash.to_s
        end
     end
    end

    def get_flag
      @flag_hash = eval(self.flags||"{}")
    end
  end
end
