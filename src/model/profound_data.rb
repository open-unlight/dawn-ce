# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 渦の元データクラス
  class ProfoundData < Sequel::Model(:profound_datas)
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    one_to_many :quests         # 複数のクエストデータを保持

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :prf_type                                                 # 渦の種類
      String      :name                                                     # 渦の名前
      integer     :rarity                                                   # レアリティ
      integer     :level                                                    # レベル
      String      :ttl                                                      # 発生から消滅までの時間
      integer     :core_monster_id                                          # ボスモンスターのID
      integer     :quest_map_id                                             # 所属クエストID
      integer     :group_id                                                 # 所属グループID
      integer     :treasure_level                                           # 報酬レベル
      integer     :stage                                                    # ステージID
      integer     :finder_start_point,:default=>RAID_FINDER_START_POINT_DEF # 発見者開始ポイント
      integer     :member_limit,:default=>RAID_MEMBER_LIMIT_DEF             # ステージID
      String      :caption, :default=>""                                    # 簡易説明
      datetime    :created_at
      datetime    :updated_at
    end

    # DBにテーブルをつくる
    if !(ProfoundData.table_exists?)
      ProfoundData.create_table
    end

    #   テーブルを変更する（履歴を残せ）
    DB.alter_table :profound_datas do
      add_column :member_limit,:integer,:default => RAID_MEMBER_LIMIT_DEF unless Unlight::ProfoundData.columns.include?(:member_limit) # 新規追加 2015/05/25
    end

    # 全体データバージョンを返す
    def ProfoundData::data_version
      ret = cache_store.get("ProfoundDataVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("ProfoundDataVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def ProfoundData::refresh_data_version
      m = ProfoundData.order(:updated_at).last
      if m
        cache_store.set("ProfoundDataVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # 渦時間の最大を取得
    def ProfoundData::get_max_ttl
      ret = CACHE.get("profound_max_ttl")
      unless ret
        prf_data = ProfoundData.order(Sequel.desc(:ttl)).limit(1).all.first
        ret = prf_data.ttl.to_f*60*60
        CACHE.set("profound_max_ttl",ret,60*60*24*30) # 1ヶ月
      end
      ret
    end

    def get_boss_data
      boss_data = CpuCardData[self.core_monster_id]
      (boss_data) ? boss_data : nil
    end

    def get_boss_name
      boss_data = self.get_boss_data
      (boss_data) ? boss_data.name : "Boss"
    end

    def get_boss_max_hp
      boss_data = self.get_boss_data
      max_hp = 0
      if boss_data
        boss_data.chara_card_id.split("+").each { |id|
          cc = CharaCard[id.to_i]
          max_hp += cc.hp if cc
        }
      end
      max_hp
    end

    def get_data_csv_str
      ret = ""
      ret << self.id.to_s << ","
      ret << self.prf_type.to_s << ","
      ret << '"' << (self.name||"") << '",'
      ret << self.rarity.to_s << ","
      ret << self.level.to_s << ","
      ret << self.quest_map_id.to_s << ","
      ret << self.stage.to_s << ","
      boss_data = CpuCardData[self.core_monster_id]
      boss_name = "Boss"
      max_hp = 0
      boss_id = 0
      if boss_data
        boss_name = boss_data.name
        boss_data.chara_card_id.split("+").each { |id|
          boss_id = id.to_i if boss_id == 0
          max_hp += CharaCard[id.to_i].hp if CharaCard[id.to_i]
        }
      end
      ret << boss_id.to_s << ','
      ret << '"' << boss_name << '",'
      ret << max_hp.to_s << ','
      ret << '"' << (self.caption||"") << '",'
      rank_bonus,all_bonus,defeat_bonus,found_bonus = ProfoundTreasureData::get_level_treasure_list(self.treasure_level)
      all_bonus_set = []
      all_bonus.each do |b|
        all_bonus_set << "#{b[:type]}_#{b[:id]}_#{b[:num]}_#{b[:sct_type]}"
      end
      all_bonus_set_str = (all_bonus_set.size > 0) ? all_bonus_set.join(",") : ""
      ret << '"' << (all_bonus_set_str||"") << '",'
      ret << self.member_limit.to_s
      ret
    end
  end
end
