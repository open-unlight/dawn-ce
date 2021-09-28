# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # クエストのマップクラス
  class Quest < Sequel::Model
    COLLUMN_PATH = [0b100, 0b010, 0b001]

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # 他クラスのアソシエーション
    many_to_one :quest_map # クエストに複数所持される

    # アップデート後の後理処
    after_save do
      Unlight::Quest.refresh_data_version
    end

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('QuestVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('QuestVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = Unlight::Quest.order(:updated_at).last
      if m
        cache_store.set('QuestVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
    end

    # 特定マップの特定リアティのマップを返す
    def self.get_map_in_reality(m, r, boss = false)
      if boss
        Quest.filter({ quest_map_id: m, rarity: r, kind: QT_ADVENTURE..QT_BOSS }).all
      else
        Quest.filter({ quest_map_id: m, rarity: r, kind: QT_ADVENTURE..QT_TREASURE }).all
      end
    end

    # 特定マップの特定リアティのマップを返す
    def self.get_map_in_boss(m)
      Quest.filter({ quest_map_id: m, kind: QT_BOSS }).all
    end

    # マップデータを配列で返す＜文字列でキャッシュせよ
    def get_land_ids_str
      land_set.join(',')
    end

    def get_land_id(pos)
      land_set[pos]
    end

    # マップデータのつながりを返す。文字列でキャッシュせよ
    def get_nexts_str
      next_set.join(',')
    end

    # 特定場所の地形の敵を引いてくる
    def get_position_enemy(pos)
      ret = 0
      land = QuestLand[land_set[pos]]
      if land
        ret = land.monstar_no
      end
      ret
    end

    # 特定の場所の地形から宝箱を引いてくる
    def get_position_treasure(pos)
      ret = 0
      land = QuestLand[land_set[pos]]
      if land
        ret = land.treasure_no
      end
      ret
    end

    # 特定の場所の地形からボーナスレベルを引いてこれる
    def get_position_bonus_level(pos)
      ret = 0
      land = QuestLand[land_set[pos]]
      if land && land.treasure_genre == TG_BONUS_GAME
        ret = land.treasure_bonus_level
      end
      ret
    end

    # 特定の場所の地形からステージを
    def get_position_stage(pos)
      ret = 0
      land = QuestLand[land_set[pos]]
      if land
        ret = land.stage
      end
      ret
    end

    # 終点のポジション番号を返す
    def get_end_position_set
      ret = []
      land_set.each_index do |i|
        # 地形が存在してかつ道に続きがないならばそこは終点
        if (land_set[i] != 0) && next_set[i].zero?
          ret << i
        end
      end
      ret
    end

    # 地形を配列で返す
    def land_set
      [
        quest_land_id_0_0, quest_land_id_0_1, quest_land_id_0_2,
        quest_land_id_1_0, quest_land_id_1_1, quest_land_id_1_2,
        quest_land_id_2_0, quest_land_id_2_1, quest_land_id_2_2,
        quest_land_id_3_0, quest_land_id_3_1, quest_land_id_3_2,
        quest_land_id_4_0, quest_land_id_4_1, quest_land_id_4_2
      ]
    end

    # 道を配列で返す
    def next_set
      [
        next_0_0, next_0_1, next_0_2,
        next_1_0, next_1_1, next_1_2,
        next_2_0, next_2_1, next_2_2,
        next_3_0, next_3_1, next_3_2,
        next_4_0, next_4_1, next_4_2
      ]
    end

    # 特定ポイントから特定ポイントへ道があるかのチェック
    def check_road_exist?(dept, dest)
      ret = false
      # 行き先が0列目ならば問答無用でOK
      dest_raw = (dest / 3).truncate if dest # 通信で妖しいのが来たときは落とす
      if dest_raw.zero?
        return true
      end

      if dept && dest # 通信で妖しいのが来たときは落とす
        dept_raw = (dept / 3).truncate
        path = next_set[dept]
        # 一階層上ならば
        if dept_raw + 1 == dest_raw
          ret = true if (path & COLLUMN_PATH[dest % 3]).positive?
        end
      end
      ret
    end

    # 特定の道の行き先に地形かあるかどうかのチェック
    def check_land_exist?(no)
      ret = true
      path = next_set[no]
      n = []
      n << 0 if (path & 0b100).positive?
      n << 1 if (path & 0b010).positive?
      n << 2 if (path & 0b001).positive?
      raw = (no / 3).truncate + 1
      n.each do |i|
        ret = false if land_set[i + raw * 3].zero?
      end
      ret
    end

    # 特定の場所に帰り着くことができるか？
    def check_next_exist?(no)
      ret = false
      # 行き先が0列目ならば問答無用でOK
      raw = (no / 3).truncate
      if raw.zero?
        return true
      end

      dept_raw = raw - 1
      col = no % 3
      ret = true if (next_set[0 + 3 * dept_raw] & COLLUMN_PATH[col]).positive?
      ret = true if (next_set[1 + 3 * dept_raw] & COLLUMN_PATH[col]).positive?
      ret = true if (next_set[2 + 3 * dept_raw] & COLLUMN_PATH[col]).positive?
      ret
    end

    def create_route_array
      [
        [1, 2, 3],
        next_to_route(0, 0, next_0_0),
        next_to_route(0, 1, next_0_1),
        next_to_route(0, 2, next_0_2),
        next_to_route(1, 0, next_1_0),
        next_to_route(1, 1, next_1_1),
        next_to_route(1, 2, next_1_2),
        next_to_route(2, 0, next_2_0),
        next_to_route(2, 1, next_2_1),
        next_to_route(2, 2, next_2_2),
        next_to_route(3, 0, next_3_0),
        next_to_route(3, 1, next_3_1),
        next_to_route(3, 2, next_3_2),
        next_to_route(4, 0, next_4_0),
        next_to_route(4, 1, next_4_1),
        next_to_route(4, 2, next_4_2)
      ]
    end

    def next_to_route(raw, _collumn, n)
      ret = []
      point = (raw + 1) * 3
      ret << 0 + point + 1 if (n & 0b100).positive?
      ret << 1 + point + 1 if (n & 0b010).positive?
      ret << 2 + point + 1 if (n & 0b001).positive?
      ret
    end

    def check_route(pos)
      @closed = []
      @route_array = create_route_array
      solve([], 0, pos + 1)
      p @closed
      !@closed.empty?
    end

    def solve(c, pos, goal)
      close = c.clone
      if pos == goal
        close << pos
        @closed << close
      else
        @route_array[pos].each do |i|
          unless close.include?(i)
            c = close.clone
            c << pos # unless close.include?(pos)
            solve(c, i, goal)
          end
        end
      end
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def get_data_csv_str
      ret = ''
      ret << id.to_s << ','
      ret << '"' << (name || '') << '",'
      ret << '"' << (caption || '') << '",'
      ret << (ap || 0).to_s << ','
      ret << (kind || 0).to_s << ','
      ret << (difficulty || 0).to_s << ','
      ret << (rarity || 0).to_s << ','
      ret << '[' << (get_land_ids_str || '') << '],'
      ret << '[' << (get_nexts_str || '') << '],'
      ret << (quest_map_id || 0).to_s << ','
      ret << (story_no || 0).to_s << ''
      ret
    end
  end
end
