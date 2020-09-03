# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # クエストのマップクラス
  class Quest < Sequel::Model
    COLLUMN_PATH = [0b100,0b010,0b001]

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    many_to_one :quest_map          # クエストに複数所持される

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :quest_map_id, :index=>true#, :table => :quest_maps
      String      :name,       :default => ""
      String      :caption,    :default => ""
      integer     :ap,         :default => 0
      integer     :kind,       :default => 0
      integer     :difficulty, :default => 0
      integer     :rarity,     :default => 0
      integer     :story_no,     :default => 0

      integer :quest_land_id_0_0,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_0_0,:default => 0, :null =>false
      integer :quest_land_id_0_1,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_0_1,:default => 0, :null =>false
      integer :quest_land_id_0_2,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_0_2,:default => 0, :null =>false

      integer :quest_land_id_1_0,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_1_0,:default => 0, :null =>false
      integer :quest_land_id_1_1,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_1_1,:default => 0, :null =>false
      integer :quest_land_id_1_2,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_1_2,:default => 0, :null =>false
      integer :quest_land_id_2_0,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_2_0,:default => 0, :null =>false
      integer :quest_land_id_2_1,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_2_1,:default => 0, :null =>false
      integer :quest_land_id_2_2,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_2_2,:default => 0, :null =>false
      integer :quest_land_id_3_0,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_3_0,:default => 0, :null =>false
      integer :quest_land_id_3_1,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_3_1,:default => 0, :null =>false
      integer :quest_land_id_3_2,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_3_2,:default => 0, :null =>false
      integer :quest_land_id_4_0,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_4_0,:default => 0, :null =>false
      integer :quest_land_id_4_1,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_4_1,:default => 0, :null =>false
      integer :quest_land_id_4_2,:default => 0, :null =>false#, :table => :quest_lands,:default => 0, :null =>false
      integer :next_4_2,:default => 0, :null =>false

      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end


    # DBにテーブルをつくる
    if !(Quest.table_exists?)
      Quest.create_table
    end

    # テーブルの変更
    DB.alter_table :quests do
      add_column :story_no, :integer, :default => 0 unless Unlight::Quest.columns.include?(:story_no)  # 新規追加 2013//12/5
    end

    # アップデート後の後理処
    after_save do
      Unlight::Quest::refresh_data_version
    end

    # 全体データバージョンを返す
    def Quest::data_version
      ret = cache_store.get("QuestVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("QuestVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def Quest::refresh_data_version
      m = Unlight::Quest.order(:updated_at).last
      if m
        cache_store.set("QuestVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # 特定マップの特定リアティのマップを返す
    def Quest::get_map_in_reality(m, r, boss = false)
      if boss
        Quest.filter({:quest_map_id=>m,:rarity=>r, :kind=>QT_ADVENTURE..QT_BOSS}).all
      else
        Quest.filter({:quest_map_id=>m,:rarity=>r, :kind=>QT_ADVENTURE..QT_TREASURE}).all
      end
    end

    # 特定マップの特定リアティのマップを返す
    def Quest::get_map_in_boss(m)
      Quest.filter({:quest_map_id=>m, :kind=>QT_BOSS}).all
    end

    # マップデータを配列で返す＜文字列でキャッシュせよ
    def get_land_ids_str
      land_set.join(",")
    end

    def get_land_id(pos)
      land_set[pos]
    end

    # マップデータのつながりを返す。文字列でキャッシュせよ
    def get_nexts_str
      next_set.join(",")
    end

    # 特定場所の地形の敵を引いてくる
    def get_position_enemy(pos)
      ret =0
      land = QuestLand[land_set[pos]]
      if land
        ret =land.monstar_no
      end
      ret
    end

    # 特定の場所の地形から宝箱を引いてくる
    def get_position_treasure(pos)
      ret =0
      land = QuestLand[land_set[pos]]
      if land
        ret =land.treasure_no
      end
      ret
    end

    # 特定の場所の地形からボーナスレベルを引いてこれる
    def get_position_bonus_level(pos)
      ret =0
      land = QuestLand[land_set[pos]]
      if land&&land.treasure_genre==TG_BONUS_GAME
        ret =land.treasure_bonus_level
      end
      ret
    end

    # 特定の場所の地形からステージを
    def get_position_stage(pos)
      ret =0
      land = QuestLand[land_set[pos]]
      if land
        ret =land.stage
      end
      ret
    end

    # 終点のポジション番号を返す
    def get_end_position_set
      ret = []
      land_set.each_index do |i|
        # 地形が存在してかつ道に続きがないならばそこは終点
        if (land_set[i] !=0)&&(next_set[i]==0)
          ret << i
        end
      end
      ret
    end

    # 地形を配列で返す
    def land_set
      [
       quest_land_id_0_0,quest_land_id_0_1,quest_land_id_0_2,
       quest_land_id_1_0,quest_land_id_1_1,quest_land_id_1_2,
       quest_land_id_2_0,quest_land_id_2_1,quest_land_id_2_2,
       quest_land_id_3_0,quest_land_id_3_1,quest_land_id_3_2,
       quest_land_id_4_0,quest_land_id_4_1,quest_land_id_4_2,
      ]
    end

    # 道を配列で返す
    def next_set
      [
       next_0_0,next_0_1,next_0_2,
       next_1_0,next_1_1,next_1_2,
       next_2_0,next_2_1,next_2_2,
       next_3_0,next_3_1,next_3_2,
       next_4_0,next_4_1,next_4_2,
      ]
    end


    # 特定ポイントから特定ポイントへ道があるかのチェック
    def check_road_exist?(dept,dest)
      ret = false
      # 行き先が0列目ならば問答無用でOK
      dest_raw =(dest/3).truncate if dest              # 通信で妖しいのが来たときは落とす
      if dest_raw ==0
        return true
      end
      if dept&&dest              # 通信で妖しいのが来たときは落とす
        dept_raw =(dept/3).truncate
        path = next_set[dept]
        # 一階層上ならば
        if dept_raw+1 == dest_raw
          ret = true if path&COLLUMN_PATH[dest%3]>0
        end
      end
      ret
    end

    # 特定の道の行き先に地形かあるかどうかのチェック
    def check_land_exist?(no)
      ret = true
      path = next_set[no]
      n = []
      n << 0 if path&0b100>0
      n << 1 if path&0b010>0
      n << 2 if path&0b001>0
      raw =(no/3).truncate + 1
      n.each do |i|
        ret = false if land_set[i+raw*3]==0
      end
      ret
    end

    # 特定の場所に帰り着くことができるか？
    def check_next_exist?(no)
      ret = false
      # 行き先が0列目ならば問答無用でOK
      raw =(no/3).truncate
      if raw ==0
        return true
      end
      dept_raw =raw-1
      col = no%3
      ret = true if next_set[0+3*dept_raw]&COLLUMN_PATH[col]>0
      ret = true if next_set[1+3*dept_raw]&COLLUMN_PATH[col]>0
      ret = true if next_set[2+3*dept_raw]&COLLUMN_PATH[col]>0
      ret
    end

    def create_route_array
      [
       [1,2,3],
       next_to_route(0,0,next_0_0),
       next_to_route(0,1,next_0_1),
       next_to_route(0,2,next_0_2),
       next_to_route(1,0,next_1_0),
       next_to_route(1,1,next_1_1),
       next_to_route(1,2,next_1_2),
       next_to_route(2,0,next_2_0),
       next_to_route(2,1,next_2_1),
       next_to_route(2,2,next_2_2),
       next_to_route(3,0,next_3_0),
       next_to_route(3,1,next_3_1),
       next_to_route(3,2,next_3_2),
       next_to_route(4,0,next_4_0),
       next_to_route(4,1,next_4_1),
       next_to_route(4,2,next_4_2),
      ]
    end

    def next_to_route(raw,collumn,n)
      ret = []
      point = (raw+1)*3
      ret << 0+point+1 if n&0b100>0
      ret << 1+point+1 if n&0b010>0
      ret << 2+point+1 if n&0b001>0
      ret
    end

    def check_route(pos)
      @closed = []
      @route_array = create_route_array
      solve([],0,pos+1)
      p @closed
      if @closed.size >0
        true
      else
        false
      end
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
            solve(c,i,goal)
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
     ret = ""
     ret << self.id.to_s << ","
     ret << '"' << (self.name||"") << '",'
     ret << '"' << (self.caption||"")<< '",'
     ret << (self.ap||0).to_s<< ","
     ret << (self.kind||0).to_s << ","
     ret << (self.difficulty||0).to_s << ","
     ret << (self.rarity||0).to_s << ","
     ret << '[' << (self.get_land_ids_str||"") << '],'
     ret << '[' << (self.get_nexts_str||"") << '],'
     ret << (self.quest_map_id||0).to_s << ","
     ret << (self.story_no||0).to_s << ""
     ret
   end
  end
end
