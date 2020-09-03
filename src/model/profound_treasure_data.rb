# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 渦専用報酬
  class ProfoundTreasureData < Sequel::Model(:profound_treasure_datas)
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :level                                        # 報酬のレベル
      integer     :prf_trs_type,  :default => PRF_TRS_TYPE_RANK # 渦報酬のタイプ
      integer     :rank_min,      :default => 0                 # ランク指定の最低値
      integer     :rank_max,      :default => 0                 # ランク指定の最大値
      integer     :treasure_type, :default => 0                 # 報酬アイテムのタイプ
      integer     :treasure_id,   :default => 0                 # 報酬アイテムのID
      integer     :slot_type,     :default => 0                 # 報酬アイテムのSlotタイプ
      integer     :value,         :default => 0                 # 報酬アイテムの値（個数等）
      datetime    :created_at
      datetime    :updated_at
    end

    # DBにテーブルをつくる
    if !(ProfoundTreasureData.table_exists?)
      ProfoundTreasureData.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def ProfoundTreasureData::get_level_treasure_list(lv)
      ret = CACHE.get("prf_level_#{lv}_treasure_list")
      unless ret
        list = ProfoundTreasureData.filter([:level => lv]).order(:prf_trs_type,:rank_min).all
        rank_bonus = { }
        all_bonus = []
        defeat_bonus = []
        found_bonus = []
        list.each do |l|
          set_data = {
            :type     => l.treasure_type,
            :id       => l.treasure_id,
            :num      => l.value,
            :sct_type => l.slot_type
          }
          case l.prf_trs_type
          when PRF_TRS_TYPE_RANK
            for rank in l.rank_min..l.rank_max
              rank_bonus[rank] = [] unless rank_bonus[rank]
              rank_bonus[rank] << set_data
            end
          when PRF_TRS_TYPE_DEFEAT
            defeat_bonus << set_data
          when PRF_TRS_TYPE_FOUND
            found_bonus << set_data
          when PRF_TRS_TYPE_ALL
            all_bonus << set_data
          end
        end
        ret = [rank_bonus,all_bonus,defeat_bonus,found_bonus]
        CACHE.set("prf_level_#{lv}_treasure_list",ret,60*60*24)
      end
      ret
    end

  end

end
