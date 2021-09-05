# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUカードデータクラス
  class TreasureData < Sequel::Model(:treasure_datas)
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
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

    # アップデート後の後理処
    after_save do
      Unlight::TreasureData.refresh_data_version
      Unlight::TreasureData.cache_store.delete("cpu_card_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('TreasureDataVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('TreasureDataVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = Unlight::TreasureData.order(:updated_at).last
      if m
        cache_store.set('TreasureDataVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
    end

    # 宝箱の内容をかえす
    def get_treasure(player)
      case allocation_type
      when TREASURE_ALLOC_TYPE_COST

        avatar = player.current_avatar
        deck_cost = avatar.chara_card_decks[avatar.current_deck].current_cost
        cost_conditions = allocation_id.split(',').map { |s| s.scan(/([\d~]+):(\d+)/)[0] }
        cost_conditions.each do |cond|
          range = cond[0].split('~', 2).map(&:to_i)
          if check_condition(range, deck_cost)
            allocated_td = TreasureData[cond[1].to_i]
            return [allocated_td.treasure_type, allocated_td.slot_type, allocated_td.value]
          end
        end
      else
        [treasure_type, slot_type, value]
      end
    end

    # value が range の範囲にあるかチェックする
    def check_condition(range, value)
      if (range[1]).zero?
        range[0] < value
      else
        range[0] <= value && value <= range[1]
      end
    end
  end
end
