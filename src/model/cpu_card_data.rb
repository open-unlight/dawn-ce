# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUカードデータクラス
  class CpuCardData < Sequel::Model(:cpu_card_datas)
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    one_to_many :monster_treasure_inventories # 複数の宝箱をもつ

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods

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
      Unlight::CpuCardData.refresh_data_version
      Unlight::CpuCardData.cache_store.delete("cpu_card_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('CpuCardDataVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('CpuCardDataVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = Unlight::CpuCardData.order(:updated_at).last
      if m
        cache_store.set('CpuCardDataVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
    end

    # プレイヤー情報を評価しcpuデータを割り付ける idを返す
    def get_allocation_id(player)
      allocation_id = 0
      case allocation_type
      when QUEST_ALLOC_TYPE_COST
        cost_conditions = chara_card_id.split(',').map { |s| s.scan(/([\d~]+):(\d+)/)[0] }
        cost_conditions.each do |cond|
          range = cond[0].split('~', 2).map(&:to_i)
          avatar = player.current_avatar
          if check_condition(range, avatar.chara_card_decks[avatar.current_deck].current_cost)
            allocation_id = cond[1].to_i
            break
          end
        end
        allocation_id = id unless allocation_id.positive?
      else
        allocation_id = id
      end
      allocation_id
    end

    # value が range の範囲にあるかチェックする
    def check_condition(range, value)
      if (range[1]).zero?
        range[0] < value
      else
        range[0] <= value && value <= range[1]
      end
    end

    # キャラカードのIDをかえす
    def chara_cards_id
      if chara_card_id == ''
        1001
      else
        chara_card_id.split('+').map!(&:to_i)
      end
    end

    def current_cards_ids
      ret = [-1, -1, -1]
      if chara_card_id != ''
        ids = chara_card_id.split('+')
        ids.each_index do |i|
          ret[i] = ids[i]
        end
      end
      ret.join(',')
    end

    # 武器カードのIDをかえす
    def weapon_cards_id
      ret = [[], [], []]
      wcs = weapon_card_id.split('+')
      wcs.each_index do |i|
        wcs[i].split('/').map!(&:to_i).each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    # 装備カードのIDをかえす
    def equip_cards_id
      ret = [[], [], []]
      ecs = equip_card_id.split('+')
      ecs.each_index do |i|
        ecs[i].split('/').map!(&:to_i).each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    # イベントカードのIDをかえす
    def event_cards_id
      ret = [[], [], []]
      ecs = event_card_id.split('+')
      ecs.each_index do |i|
        ecs[i].split('/').map!(&:to_i).each do |c|
          ret[i] << c if c != 0
        end
      end
      ret
    end

    def treasure_items
      ret = []
      monster_treasure_inventories.sort_by(&:step).each do |mt|
        ret << mt.get_treasure
      end
      ret
    end
  end
end
