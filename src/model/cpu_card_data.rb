# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUカードデータクラス
  class CpuCardData < Sequel::Model(:cpu_card_datas)
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    one_to_many :monster_treasure_inventories         # 複数の宝箱をもつ

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :default => "monster"
      integer     :allocation_type, :default => QUEST_ALLOC_TYPE_NONE
      String      :chara_card_id, :default => "1001+1001+1001"
      String      :weapon_card_id, :default => "0+0+0"
      String      :equip_card_id, :default => "0+0+0"
      String      :event_card_id, :default => "1/1/1+1/1/1+1/1/1"
     integer     :ai_rank, :default => CPU_AI_OLD

      integer     :treasure_id#, :table => :avatars
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(CpuCardData.table_exists?)
      CpuCardData.create_table
    end

    # テーブルを変更する（履歴を残せ）
    DB.alter_table :cpu_card_datas do
     add_column :ai_rank, :integer, :default => CPU_AI_OLD unless Unlight::CpuCardData.columns.include?(:ai_rank)  # 新規追加 2013/04/01
     add_column :allocation_type, :integer, :default => QUEST_ALLOC_TYPE_NONE unless Unlight::CpuCardData.columns.include?(:allocation_type)  # 新規追加 2015/2/12
    end

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
      Unlight::CpuCardData::refresh_data_version
      Unlight::CpuCardData::cache_store.delete("cpu_card_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def CpuCardData::data_version
      ret = cache_store.get("CpuCardDataVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("CpuCardDataVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CpuCardData::refresh_data_version
      m = Unlight::CpuCardData.order(:updated_at).last
      if m
        cache_store.set("CpuCardDataVersion", m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # プレイヤー情報を評価しcpuデータを割り付ける idを返す
    def get_allocation_id(player)
      allocation_id = 0
      case self.allocation_type
      when QUEST_ALLOC_TYPE_COST
        cost_conditions = self.chara_card_id.split(",").map{ |s| s.scan(/([\d~]+):(\d+)/)[0] }
        cost_conditions.each do |cond|
          range = cond[0].split("~", 2).map{ |n| n.to_i }
          avatar = player.current_avatar
          if check_condition(range, avatar.chara_card_decks[avatar.current_deck].current_cost)
            allocation_id = cond[1].to_i
            break
          end
        end
        allocation_id = allocation_id > 0 ? allocation_id : self.id
      else
        allocation_id = self.id
      end
      allocation_id
    end

    # value が range の範囲にあるかチェックする
    def check_condition(range, value)
      if range[1] == 0
        return range[0] < value
      else
        return range[0] <= value && value <= range[1]
      end
    end

    # キャラカードのIDをかえす
    def chara_cards_id
      if self.chara_card_id != ""
        self.chara_card_id.split(/\+/).map!{|s|s.to_i}
      else
        1001
      end
    end

    def current_cards_ids
      ret = [-1,-1,-1]
      if self.chara_card_id != ""
        ids = self.chara_card_id.split(/\+/)
        ids.each_index do |i|
          ret[i] = ids[i]
        end
      end
      ret.join(",")
    end

    # 武器カードのIDをかえす
    def weapon_cards_id
      ret = [[],[],[]]
      wcs = self.weapon_card_id.split(/\+/)
      wcs.each_index do |i|
        wcs[i].split(/\//).map!{|s|s.to_i}.each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    # 装備カードのIDをかえす
    def equip_cards_id
      ret = [[],[],[]]
      ecs = self.equip_card_id.split(/\+/)
      ecs.each_index do |i|
        ecs[i].split(/\//).map!{|s|s.to_i}.each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    # イベントカードのIDをかえす
    def event_cards_id
      ret = [[],[],[]]
      ecs = self.event_card_id.split(/\+/)
      ecs.each_index do |i|
        ecs[i].split(/\//).map!{|s|s.to_i}.each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    def treasure_items
      ret = []
      self.monster_treasure_inventories.sort{|a,b| a.step<=>b.step }.each do |mt|
        ret << mt.get_treasure
      end
      ret
    end

  end
end
