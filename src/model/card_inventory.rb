# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # カードのインベントリクラス
  class CardInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :chara_card_deck        # デッキに複数所持される
    many_to_one :chara_card   # キャラカードを複数もてる


    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer   :chara_card_deck_id#, :table => :chara_card_decks
      integer   :chara_card_id#, :table => :chara_cards
      integer   :position, :default => 0, :null =>false
      integer   :before_deck_id#, :table => :chara_card_decks
      datetime  :created_at
      datetime  :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(CardInventory.table_exists?)
      CardInventory.create_table
    end

    DB.alter_table :card_inventories do
     add_column :before_deck_id, :integer, :default => 0 unless Unlight::CardInventory.columns.include?(:before_deck_id)  # 新規追加2011/07/25
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def delete_from_deck
      self.before_deck_id = self.chara_card_deck_id
      self.chara_card_deck_id = 0
      self.save_changes
    end


    # CPU用のキャラカードインベントリを作る
    def CardInventory.create_cpu_card(no, deck_id)
      no = 0 unless CpuCardData[no]
      if no != 0
        CpuCardData[no].chara_cards_id.each_index do |i|
          CardInventory.new do |c|
            c.chara_card_deck_id = deck_id
            c.chara_card_id = CpuCardData[no].chara_cards_id[i]
            c.position = i
            c.save
          end
        end
      end
    end

    # CPU用のキャラカードインベントリを更新する
    def CardInventory.update_cpu_card(no, deck_id)
      no = 0 unless CpuCardData[no]
      if no != 0
        CpuCardData[no].chara_cards_id.each_index do |i|
          CardInventory.new do |c|
            c.chara_card_deck_id = deck_id
            c.chara_card_id = CpuCardData[no].chara_cards_id[i]
            c.position = i
            c.save
          end
        end
      end
    end


  end

end
