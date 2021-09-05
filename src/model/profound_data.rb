# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 渦の元データクラス
  class ProfoundData < Sequel::Model(:profound_datas)
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # 他クラスのアソシエーション
    one_to_many :quests # 複数のクエストデータを保持

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('ProfoundDataVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('ProfoundDataVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = ProfoundData.order(:updated_at).last
      if m
        cache_store.set('ProfoundDataVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
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
    def self.get_max_ttl
      ret = CACHE.get('profound_max_ttl')
      unless ret
        prf_data = ProfoundData.order(Sequel.desc(:ttl)).limit(1).all.first
        ret = prf_data.ttl.to_f * 60 * 60
        CACHE.set('profound_max_ttl', ret, 60 * 60 * 24 * 30) # 1ヶ月
      end
      ret
    end

    def get_boss_data
      boss_data = CpuCardData[core_monster_id]
      boss_data || nil
    end

    def get_boss_name
      boss_data = get_boss_data
      boss_data ? boss_data.name : 'Boss'
    end

    def get_boss_max_hp
      boss_data = get_boss_data
      max_hp = 0
      if boss_data
        boss_data.chara_card_id.split('+').each do |id|
          cc = CharaCard[id.to_i]
          max_hp += cc.hp if cc
        end
      end
      max_hp
    end

    def get_data_csv_str
      ret = ''
      ret << id.to_s << ','
      ret << prf_type.to_s << ','
      ret << '"' << (name || '') << '",'
      ret << rarity.to_s << ','
      ret << level.to_s << ','
      ret << quest_map_id.to_s << ','
      ret << stage.to_s << ','
      boss_data = CpuCardData[core_monster_id]
      boss_name = 'Boss'
      max_hp = 0
      boss_id = 0
      if boss_data
        boss_name = boss_data.name
        boss_data.chara_card_id.split('+').each do |id|
          boss_id = id.to_i if boss_id.zero?
          max_hp += CharaCard[id.to_i].hp if CharaCard[id.to_i]
        end
      end
      ret << boss_id.to_s << ','
      ret << '"' << boss_name << '",'
      ret << max_hp.to_s << ','
      ret << '"' << (caption || '') << '",'
      rank_bonus, all_bonus, defeat_bonus, found_bonus = ProfoundTreasureData.get_level_treasure_list(treasure_level)
      all_bonus_set = []
      all_bonus.each do |b|
        all_bonus_set << "#{b[:type]}_#{b[:id]}_#{b[:num]}_#{b[:sct_type]}"
      end
      all_bonus_set_str = all_bonus_set.empty? ? '' : all_bonus_set.join(',')
      ret << '"' << (all_bonus_set_str || '') << '",'
      ret << member_limit.to_s
      ret
    end
  end
end
