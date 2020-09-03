# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # パーツのインベントリクラス
  class MonsterTreasureInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :cpu_card_data         # アバターを持つ
    many_to_one :treasure_data    # アバターパーツを持つ

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :cpu_card_data_id, :index=>true
      integer     :treasure_data_id
      integer     :num
      integer     :step
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(MonsterTreasureInventory.table_exists?)
      MonsterTreasureInventory.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    SLOTS2REWARD = [Unlight::Reward::WEAPON_CARD, 0, Unlight::Reward::EVENT_CARD]

    def get_treasure
      ret = { :step=>0,:item=>[0,0,0]}
      t = self.treasure_data
      if t
        case t.treasure_type
        when TG_NONE
        when TG_CHARA_CARD
          ret = { :step=>self.step, :item=>[Unlight::Reward::RANDOM_CARD, t.value,self.num,]}
        when TG_SLOT_CARD
          ret = { :step=>self.step, :item=>[SLOTS2REWARD[t.slot_type], t.value, self.num,]}  unless SLOTS2REWARD[t.slot_type]==0
        when TG_AVATAR_ITEM
          ret = { :step=>self.step, :item=>[Unlight::Reward::ITEM, t.value, self.num,]}
        when TG_AVATAR_PART
        when TG_GEM
        when TG_OWN_CARD
        when TG_BONUS_GAME
        end
      end
      ret
    end
  end
end
