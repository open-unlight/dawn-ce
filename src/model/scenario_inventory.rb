# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # カードのインベントリクラス
  class ScenarioInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :scenario   # キャラカードを複数もてる

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true #, :table => :chara_card_decks
      integer     :scenario_id
      integer     :state
      datetime    :end_at
      datetime    :created_at
      datetime    :updated_at
    end

   # DBにテーブルをつくる
    if !(ScenarioInventory.table_exists?)
      ScenarioInventory.create_table
    end

    DB.alter_table :scenario_inventories do
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

  end

end
