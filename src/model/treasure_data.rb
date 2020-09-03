# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUカードデータクラス
  class TreasureData < Sequel::Model(:treasure_datas)
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :default => "treasure"
      integer     :allocation_type, :default => 0 # 新規追加2015/05/15
      String      :allocation_id, :default => ""  # 新規追加2015/05/15
      integer     :treasure_type, :default => 0
      integer     :slot_type, :default => 0
      integer     :value, :default => 0
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(TreasureData.table_exists?)
      TreasureData.create_table
    end

    #   テーブルを変更する（履歴を残せ）
    DB.alter_table :treasure_datas do
      add_column :allocation_type, :integer, :default => 0 unless Unlight::TreasureData.columns.include?(:allocation_type)  # 新規追加 2015/05/15
      add_column :allocation_id, String, :default => "" unless Unlight::TreasureData.columns.include?(:allocation_id)       # 新規追加 2012/05/15
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
      Unlight::TreasureData::refresh_data_version
      Unlight::TreasureData::cache_store.delete("cpu_card_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def TreasureData::data_version
      ret = cache_store.get("TreasureDataVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("TreasureDataVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def TreasureData::refresh_data_version
      m = Unlight::TreasureData.order(:updated_at).last
      if m
        cache_store.set("TreasureDataVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # 宝箱の内容をかえす
    def get_treasure(player)

      case self.allocation_type
      when TREASURE_ALLOC_TYPE_COST

        avatar = player.current_avatar
        deck_cost = avatar.chara_card_decks[avatar.current_deck].current_cost
        cost_conditions = self.allocation_id.split(",").map{ |s| s.scan(/([\d~]+):(\d+)/)[0] }
        cost_conditions.each do |cond|
          range = cond[0].split("~", 2).map{ |n| n.to_i }
          if check_condition(range, deck_cost)
            allocated_td = TreasureData[cond[1].to_i]
            return [allocated_td.treasure_type, allocated_td.slot_type, allocated_td.value]
          end
        end
      else
        return [self.treasure_type, self.slot_type, self.value]
      end
    end

    # value が range の範囲にあるかチェックする
    def check_condition(range, value)
      if range[1] == 0
        return range[0] < value
      else
        return range[0] <= value && value <= range[1]
      end
    end

  end

end
