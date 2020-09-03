# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # パーツのインベントリクラス
  class ItemInventory < Sequel::Model

   # 他クラスのアソシエーション
    many_to_one :avatar         # アバターを持つ
    many_to_one :avatar_item    # アバターアイテムを持つ

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :avatar_id, :index=>true #, :table => :avatars
      integer :avatar_item_id#, :table => :avatar_items
      integer     :state, :default => 0 #   ITEM_STATE_NOT_USE
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :use_at
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(ItemInventory.table_exists?)
      ItemInventory.create_table
    end

    # テーブルを変更する（履歴を残せ）
    DB.alter_table :item_inventories do
      add_column :server_type, :integer, :default => 0 unless Unlight::ItemInventory.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # アイテム使用時の処理
    def use(avt,quest_map_no=0)

      ret = ERROR_ITEM_NOT_EXIST
      # 重たい処理が走るとアイテムが何度も使えるので最初に
      if self.state == ITEM_STATE_NOT_USE
        if self.avatar_item.duration > 0
          self.state = ITEM_STATE_USING   # 使用中
          self.use_at = Time.now.utc      # 使用時間
        else
          self.state = ITEM_STATE_USED    # 使用した
          self.use_at = Time.now.utc      # 使用時間
        end
        self.save_changes
        ret = self.avatar_item.use(avt,quest_map_no)
        if ret != 0
          self.state = ITEM_STATE_NOT_USE   # 未使用に戻す
          self.save_changes
        end
      end
      ret
    end
  end
end
