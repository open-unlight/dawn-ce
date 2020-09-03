# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # キャラクター本体のデータ
  class Achievement < Sequel::Model

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :kind, :default => 0         # 種類
      integer     :cond                        # 条件
      String      :items,:default => ""        # 報酬アイテム
      integer     :prerequisite, :default =>0  # 前提条件
      String      :exclusion, :default =>""    # 排他条件
      integer     :loop, :default =>0          # 繰り返し可能か(1以上で無限)
      String      :caption, :default =>""      # キャプション

      integer     :success_cond, :default =>0  # 達成条件
      String      :explanation, :default =>""  # 説明

      String      :set_loop, :default =>""     # セットループ条件

      String      :set_end_type, :default => "0" # end_at設定タイプ

      datetime    :event_start_at
      datetime    :event_end_at

      integer     :clear_code_type, :default => 0 # クリアコードタイプ0の時なし
      integer     :clear_code_max, :default => 0  # 発行最大数

      datetime    :created_at
      datetime    :updated_at
    end



    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # DBにテーブルをつくる
    if !(Achievement.table_exists?)
      Achievement.create_table
    end

    DB.alter_table :achievements do
      add_column :success_cond, :integer, :default => 0 unless Unlight::Achievement.columns.include?(:success_cond)  # 新規追加2012/06/22
      add_column :explanation, String, :default => "" unless Unlight::Achievement.columns.include?(:explanation)     # 新規追加2012/10/16
      add_column :loop, :integer, :default => 0 unless Unlight::Achievement.columns.include?(:loop)                  # 新規追加2013/01/10
      add_column :set_loop, String, :default => "" unless Unlight::Achievement.columns.include?(:set_loop)           # 新規追加2014/06/13
      add_column :clear_code_type, :integer, :default => 0 unless Unlight::Achievement.columns.include?(:clear_code_type)  # 新規追加2015/04/14
      add_column :clear_code_max, :integer, :default => 0 unless Unlight::Achievement.columns.include?(:clear_code_max)   # 新規追加2015/04/14
      add_column :set_end_type, String, :default => "0" unless Unlight::Achievement.columns.include?(:set_end_type)   # 新規追加2015/11/13
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # クリアしたIDをもらって新しいアチーブメントのリストを返す
    def Achievement::get_new_list(clear_id)
      ret = CACHE.get("achi_new_list#{clear_id}")
      unless ret
        ret = []
        Achievement.all.each { |a|
        if a.check_expiration&&(a.prerequisite == 0||clear_id == a.prerequisite)
          ret.push(a)
        end
        }
        CACHE.set("achi_new_list#{clear_id}",ret)
      end
      ret
    end

    # chara_card_checkのアチーブメントIDを取得(card_idsがある場合、card_idsが関係しているもののみ)
    def Achievement::get_card_check_achievement_ids(card_ids = nil)
      ret = []
      CONDITION_SET.each do |i,value|
        if value[0] == :chara_card_check
          if card_ids == nil
            ret.push(i)
          else
            hit = false
            value[1].each do |v|
              hit = true if card_ids.include?(v[0])
            end
            ret.push(i) if hit
          end
        end
      end
      ret
    end

    # IDからchara_card_checkのアチーブメントか判定
    def Achievement::is_chara_card_check(a_id=0)
      if CONDITION_SET[a_id]
        CONDITION_SET[a_id][0] == :chara_card_check
      else
        false
      end
    end

    # カードレベルチェックレコードチェック
    def Achievement::get_card_level_record(cards)
      clear_record_ids = []
      if cards&&cards.size
        CONDITION_SET.each do |i,cond|
          if cond[0] == :get_card_level_check
            cards.each do |cc|
              # かけらなどのカードは除外
              case cc.kind
              when CC_KIND_CHARA,CC_KIND_BOSS_MONSTAR,CC_KIND_REBORN_CHARA,CC_KIND_EPISODE
                if cond[1][2]
                  if cond[1][0] == 0
                    clear_record_ids.push(i) if cc.rarity >= cond[1][1]
                  else
                    clear_record_ids.push(i) if cc.rarity >= cond[1][1] && cc.level == cond[1][0]
                  end
                else
                  clear_record_ids.push(i) if cc.level == cond[1][0]
                end
              end
              break if clear_record_ids.index(i) != nil
            end
          end
        end
      end
      clear_record_ids
    end

    # end_at指定の入るアチーブメントのリストを返す
    def Achievement::get_set_end_at_record()
      ret = CACHE.get("achi_end_at_list")
      unless ret
        ret = []
        Achievement.all.each { |a|
        if a.set_end_type != "0"
          ret.push(a)
        end
        }
        CACHE.set("achi_end_at_list",ret)
      end
      ret
    end


    # 排他クエスト
    def get_exclusion_list
      if self.exclusion
        self.exclusion.split('+')
      else
        []
      end
    end

    # セットループ
    def get_set_loop_list
      if self.set_loop
        self.set_loop.split('+')
      else
        []
      end
    end

    # 報酬アイテムを返す[type,id,num,slot_type]のArray
    # 0/10/1+1/1/20
    def get_items
      ret = []
      self.items.split("+").each do |i|
        if i[0] != "S"
          ret.push(Array.new())
          i.split("/").each do  |j|
            ret.last.push(j.to_i)
          end
        end
      end
      ret
    end

    def get_selectable_items
      self.items.include?("S")
    end

    def get_selectable_array
      ret = CACHE.get("selectable_items#{self.id}")
      unless ret
        ret = []
        self.items.split("+").each do |ii|
          if ii[0] == "S"
            ii[1..-1].split("|").each do |i|
              ret.push(Array.new())
              i.split("/").each do  |j|
                ret.last.push(j.to_i)
              end
            end
          end
        end
        CACHE.set("selectable_items#{self.id}",ret)
      end
      ret
    end

    # セットするend_atを返す
    def get_end_at
      ret = nil
      now = Time.now.utc
      type,val = self.set_end_type.split(":")
      case type.to_i
        when ACHIEVEMENT_END_AT_TYPE_DAY
        d_time = DateTime.new(now.year,now.month,now.day) + val.to_i
        ret = Time.gm(d_time.year,d_time.month,d_time.day) + LOGIN_BONUS_OFFSET_TIME
        when ACHIEVEMENT_END_AT_TYPE_HOUR
        ret = now + val.to_i * 60
        when ACHIEVEMENT_END_AT_TYPE_NONE
      end
      ret
    end

    # クリアコードを渡す
    def get_code
      Unlight::ClearCode.get_code(clear_code_type,clear_code_max)
    end

    # 条件がクリアされているかのチェック(noがある場合はNOのみ検査する)
    def cond_check(avatar,no = false, inv = nil, card_list = nil, add_point = 0)
      ret = false
      if avatar
        if CONDITION_SET[self.cond] && (CONDITION_SET[self.cond][2] || (no&&no.include?(self.cond)))
          if inv == nil || inv && inv.state == ACHIEVEMENT_STATE_START
            s_cond = (self.success_cond&&self.success_cond > 0) ? self.success_cond : nil
            if CONDITION_SET[self.cond][0] == :chara_card_check
              ret = self.send(CONDITION_SET[self.cond][0], avatar, CONDITION_SET[self.cond][1], inv, s_cond, card_list) if card_list != nil
            elsif CONDITION_SET[self.cond][0] == :event_point_check
              ret = self.send(CONDITION_SET[self.cond][0], avatar, CONDITION_SET[self.cond][1], inv, s_cond, add_point) if add_point > 0
            else
              ret = self.send(CONDITION_SET[self.cond][0], avatar, CONDITION_SET[self.cond][1], inv, s_cond)
            end
          end
        end
      end
      ret
    end

    # 有効期限のチェック
    def check_expiration
      ret = true
      if self.event_start_at
        t = Time.now.utc
        ret =  t > self.event_start_at
      end
      if self.event_end_at
        if ret
          t = Time.now.utc unless t
          ret =  self.event_end_at > t
        end
      end
      ret
    end

    # progressの更新のみを行う
    def progress_update(avatar,no = false, inv = nil)
      if avatar
        if CONDITION_SET[self.cond] && (CONDITION_SET[self.cond][2] || (no&&no.include?(self.cond)))
          if inv
            self.send(CONDITION_SET[self.cond][0], avatar, CONDITION_SET[self.cond][1], inv, self.success_cond)
          end
        end
      end
    end

    # いつでもチェックするか確認
    def is_any_time_check
      CONDITION_SET[self.id][2]
    end

    # 条件のチェック情報
    # 0:CheckType => チェックする種類
    # 1:CondID&Count => チェックする条件IDやカウント
    # 2:AnyTimeCheckFlag => いつでもチェックするかの判定
    CONDITION_SET = {
      0 =>   [],                                                                                                                                # 使用しない
      1 =>   [:level_check, 1,true],                                                                                                            # 1:アバターのレベル1以上
      2 =>   [:level_check, 3,true],                                                                                                            # 2:アバターのレベル3以上
      3 =>   [:level_check, 5,true],                                                                                                            # 3:アバターのレベル5以上
      4 =>   [:level_check, 10,true],                                                                                                           # 4:アバターのレベル10以上
      5 =>   [:level_check, 15,true],                                                                                                           # 5:アバターのレベル15以上
      6 =>   [:level_check, 20,true],                                                                                                           # 6:アバターのレベル20以上
      7 =>   [:level_check, 30,true],                                                                                                           # 7:アバターのレベル1以上
      8 =>   [:level_check, 40,true],                                                                                                           # 8:アバターのレベル1以上
      9 =>   [:level_check, 50,true],                                                                                                           # 9:アバターのレベル1以上
      10 =>  [:level_check, 60,true],                                                                                                           # 10:アバターのレベル1以上
      11 =>  [:level_check, 70,true],                                                                                                           # 11:アバターのレベル1以上
      12 =>  [:level_check, 80,true],                                                                                                           # 12:アバターのレベル1以上
      13 =>  [:level_check, 90,true],                                                                                                           # 13:アバターのレベル1以上
      14 =>  [:level_check, 100,true],                                                                                                          # 14:アバターのレベル1以上
      15 =>  [:level_check, 110,true],                                                                                                          # 15:アバターのレベル1以上
      16 =>  [:level_check, 120,true],                                                                                                          # 16:アバターのレベル1以上
      17 =>  [:level_check, 130,true],                                                                                                          # 17:アバターのレベル1以上
      18 =>  [:level_check, 140,true],                                                                                                          # 18:アバターのレベル1以上
      19 =>  [:level_check, 150,true],                                                                                                          # 19:アバターのレベル1以上
      20 =>  [:duel_win_check, 1,true],                                                                                                         # 20:アバターのレベル150以上
      21 =>  [:duel_win_check, 10,true],                                                                                                        # 21:アバターの対戦勝利数1以上
      22 =>  [:duel_win_check, 30,true],                                                                                                        # 22:アバターの対戦勝利数1以上
      23 =>  [:duel_win_check, 50,true],                                                                                                        # 23:アバターの対戦勝利数1以上
      24 =>  [:duel_win_check, 100,true],                                                                                                       # 24:アバターの対戦勝利数1以上
      25 =>  [:duel_win_check, 250,true],                                                                                                       # 25:アバターの対戦勝利数1以上
      26 =>  [:duel_win_check, 500,true],                                                                                                       # 26:アバターの対戦勝利数1以上
      27 =>  [:duel_win_check, 750,true],                                                                                                       # 27:アバターの対戦勝利数1以上
      28 =>  [:duel_win_check, 1000,true],                                                                                                      # 28:アバターの対戦勝利数1以上
      29 =>  [:duel_win_check, 1500,true],                                                                                                      # 29:アバターの対戦勝利数1以上
      30 =>  [:duel_win_check, 2000,true],                                                                                                      # 30:アバターの対戦勝利数1以上
      31 =>  [:quest_clear_check, 1,true],                                                                                                      # 31:アバターのクエストクリア数1以上
      32 =>  [:quest_clear_check, 3,true],                                                                                                      # 32:アバターのクエストクリア数1以上
      33 =>  [:quest_clear_check, 11,true],                                                                                                     # 33:アバターのクエストクリア数1以上
      34 =>  [:quest_clear_check, 19,true],                                                                                                     # 34:アバターのクエストクリア数1以上
      35 =>  [:quest_clear_check, 27,true],                                                                                                     # 35:アバターのクエストクリア数1以上
      36 =>  [:quest_clear_check, 35,true],                                                                                                     # 36:アバターのクエストクリア数1以上
      37 =>  [:friend_num_check, 1,true],                                                                                                       # 37:アバターの友達数1以上
      38 =>  [:friend_num_check, 5,true],                                                                                                       # 38:アバターの友達数1以上
      39 =>  [:friend_num_check, 10,true],                                                                                                      # 39:アバターの友達数1以上
      40 =>  [:friend_num_check, 30,true],                                                                                                      # 40:アバターの友達数1以上
      41 =>  [:friend_num_check, 50,true],                                                                                                      # 41:アバターの友達数1以上
      42 =>  [:friend_num_check, 100,true],                                                                                                     # 42:アバターの友達数1以上
      43 =>  [:item_num_check, [30,3],true],                                                                                                    # 43:記念コイン5枚
      44 =>  [:item_num_check, [30,5],true],                                                                                                    # 44:記念コイン10枚
      45 =>  [:item_num_check, [30,10],true],                                                                                                   # 45:記念コイン15枚
      46 =>  [:item_num_check, [30,15],true],                                                                                                   # 46:記念コイン20枚
      47 =>  [:item_num_check, [30,25],true],                                                                                                   # 47:記念コイン30枚
      48 =>  [:quest_clear_check, 23,true],                                                                                                     # 48:ウボス討伐
      49 =>  [:halloween_check, [1,2,3],true],                                                                                                  # 49:ハロウィーンイベント（特定レアリティのクエストを所持しているか）
      50 =>  [:halloween_check, [4,5,6],true],                                                                                                  # 50:ハロウィーンイベント（特定レアリティのクエストを所持しているか）
      51 =>  [:halloween_check, [7,8,9],true],                                                                                                  # 51:ハロウィーンイベント（特定レアリティのクエストを所持しているか）
      52 =>  [:chara_card_check, [[181,1]],false],                                                                                              # 52:Lv1ロッソ
      53 =>  [:chara_card_check, [[183,1]],false],                                                                                              # 53:Lv3ロッソ
      54 =>  [:chara_card_check, [[185,1]],false],                                                                                              # 54:Lv5ロッソ
      55 =>  [:chara_card_check, [[1013,3]],false],                                                                                             # 55:Lv1茸ウサギ
      56 =>  [:chara_card_check, [[1014,3],[1023,3]],false],                                                                                    # 56:Lv3茸ウサギ、Lv2狼人
      57 =>  [:chara_card_check, [[1015,3],[1024,3],[1045,3]],false],                                                                           # 57:Lv3茸ウサギ、Lv3狼人、Lv3赤兎
      58 =>  [:chara_card_deck_check, [185, 1024, 1015],true],                                                                                  # 58:ロッソ5・狼3・兎3デッキを組む
      59 =>  [:quest_no_clear_check, 0,false],                                                                                                  # 59:クランプスクエストを1クリア
      60 =>  [:quest_no_clear_check, 2,false],                                                                                                  # 60:クランプスクエストを3クリア
      61 =>  [:quest_no_clear_check, 2,false],                                                                                                  # 61:クランプスクエストを5クリア
      62 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 62:クランプスクエストを10クリア
      63 =>  [:get_rare_card_check, 1,false],                                                                                                   # 63:レアカード1枚獲得
      64 =>  [:get_rare_card_check, 3,false],                                                                                                   # 64:レアカード3枚獲得
      65 =>  [:get_rare_card_check, 5,false],                                                                                                   # 65:レアカード5枚獲得
      66 =>  [:chara_card_check, [[243,1]],false],                                                                                              # 66:Lv3ミリアン
      67 =>  [:duel_clear_check, 5, false],                                                                                                     # 67:デュエル5回以上
      68 =>  [:duel_clear_check, 5, false],                                                                                                     # 68:デュエル10回以上
      69 =>  [:duel_clear_check, 20, false],                                                                                                    # 69:デュエル30回以上
      70 =>  [:duel_clear_check, 30, false],                                                                                                    # 70:デュエル60回以上
      71 =>  [:duel_clear_check, 50, false],                                                                                                    # 71:デュエル110回以上
      72 =>  [:quest_present_check, 10, false],                                                                                                 # 72:クエストを10個プレゼント
      73 =>  [:duel_win_check, 3000,true],                                                                                                      # 73:デュエルで3000勝
      74 =>  [:chara_card_check, [[253,1]],false],                                                                                              # 74:Lv3ウォーケン
      75 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 75:シェリのバレンタイン3クリア
      76 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 76:シェリのバレンタイン8クリア
      77 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 77:シェリのバレンタイン15クリア
      78 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 78:シェリのバレンタイン30クリア
      79 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 79:アインのバレンタイン3クリア
      80 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 80:アインのバレンタイン8クリア
      81 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 81:アインのバレンタイン15クリア
      82 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 82:アインのバレンタイン30クリア
      83 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 83:マルグリッドのバレンタイン3クリア
      84 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 84:マルグリッドのバレンタイン8クリア
      85 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 85:マルグリッドのバレンタイン15クリア
      86 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 86:マルグリッドのバレンタイン30クリア
      87 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 87:ドニタのバレンタイン3クリア
      88 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 88:ドニタのバレンタイン8クリア
      89 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 89:ドニタのバレンタイン15クリア
      90 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 90:ドニタのバレンタイン30クリア
      91 =>  [:chara_card_check, [[273,1]],false],                                                                                              # 91:Lv3パルモ
      92 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 92:エヴァリストのホワイトデー3クリア
      93 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 93:エヴァリストのホワイトデー8クリア
      94 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 94:エヴァリストのホワイトデー15クリア
      95 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 95:エヴァリストのホワイトデー30クリア
      96 =>  [:quest_no_clear_check, 3,false],                                                                                                  # 96:グリュンワルドのホワイトデー3クリア
      97 =>  [:quest_no_clear_check, 5,false],                                                                                                  # 97:グリュンワルドのホワイトデー8クリア
      98 =>  [:quest_no_clear_check, 7,false],                                                                                                  # 98:グリュンワルドのホワイトデー15クリア
      99 =>  [:quest_no_clear_check, 15,false],                                                                                                 # 99:グリュンワルドのホワイトデー30クリア
      100 => [:quest_no_clear_check, 3,false],                                                                                                  # 100:アベルのホワイトデー3クリア
      101 => [:quest_no_clear_check, 5,false],                                                                                                  # 101:アベルのホワイトデー8クリア
      102 => [:quest_no_clear_check, 7,false],                                                                                                  # 102:アベルのホワイトデー15クリア
      103 => [:quest_no_clear_check, 15,false],                                                                                                 # 103:アベルのホワイトデー30クリア
      104 => [:quest_no_clear_check, 3,false],                                                                                                  # 104:xxxのバレンタイン3クリア
      105 => [:quest_no_clear_check, 5,false],                                                                                                  # 105:xxxのバレンタイン8クリア
      106 => [:quest_no_clear_check, 7,false],                                                                                                  # 106:xxxのバレンタイン15クリア
      107 => [:quest_no_clear_check, 15,false],                                                                                                 # 107:xxxのバレンタイン30クリア
      108 => [:record_clear_check, 16, false],                                                                                                  # 108:ホワイトデー関連のレコード計16種をクリア
      109 => [:duel_clear_win_check, 5,false],                                                                                                  # 109:デュエルで5回勝利する
      110 => [:duel_clear_win_check, 5,false],                                                                                                  # 110:デュエルで10回勝利する
      111 => [:duel_clear_win_check, 15,false],                                                                                                 # 111:デュエルで25回勝利する
      112 => [:duel_clear_win_check, 25,false],                                                                                                 # 112:デュエルで50回勝利する
      113 => [:duel_clear_win_check, 50,false],                                                                                                 # 113:デュエルで100回勝利する
      114 => [:duel_clear_win_check, 100,false],                                                                                                # 114:デュエルで200回勝利する
      115 => [:item_check, [101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,128],true], # 115:投票する
      116 => [:chara_card_check, [[283,1]],false],                                                                                              # 116:Lv3アスラ
      117 => [:item_complete_check, [151,152,153,154,155,156,157],true],                                                                        # 117:秘伝書を集める
      118 => [:duel_clear_check, 50, false],                                                                                                    # 118:デュエル50回以上(秘伝書7)
      119 => [:chara_card_check, [[263,1]],false],                                                                                              # 119:Lv3フロレンス
      120 => [:quest_no_clear_check, 99999 ,false],                                                                                             # 120:丘丘人ポイントをカウント
      121 => [:quest_no_clear_check, 10,false],                                                                                                 # 121:小人たちの大行進クエストを10回クリア
      122 => [:quest_no_clear_check, 10,false],                                                                                                 # 122:丘王クエストを10回クリア
      123 => [:quest_no_clear_check, 10,false],                                                                                                 # 123:小人の大宴クエストを10回クリア
      124 => [:chara_card_check, [[293,1]],false],                                                                                              # 124:Lv3ブロウニング
      125 => [:quest_no_clear_check, 3,false],                                                                                                  # 125:コデックスA-1
      126 => [:quest_no_clear_check, 8,false],                                                                                                  # 126:コデックスA-2
      127 => [:quest_no_clear_check, 15,false],                                                                                                 # 127:コデックスA-3
      128 => [:quest_no_clear_check, 30,false],                                                                                                 # 128:コデックスA-4
      129 => [:quest_no_clear_check, 50,false],                                                                                                 # 129:コデックスA-5
      130 => [:quest_no_clear_check, 3,false],                                                                                                  # 130:コデックスB-1
      131 => [:quest_no_clear_check, 8,false],                                                                                                  # 131:コデックスB-2
      132 => [:quest_no_clear_check, 15,false],                                                                                                 # 132:コデックスB-3
      133 => [:quest_no_clear_check, 30,false],                                                                                                 # 133:コデックスB-4
      134 => [:quest_no_clear_check, 50,false],                                                                                                 # 134:コデックスB-5
      135 => [:duel_clear_check, 100, false],                                                                                                   # 135:デュエル100回以上(コデックス)
      136 => [:quest_clear_check, 30,true],                                                                                                     # 136:アスタロト討伐
      137 => [:chara_card_check, [[20007,1]],false],                                                                                            # 137:アスタロト入手
      138 => [:duel_clear_check, 10,false],                                                                                                     # 138:アレクサンドルで10回対戦する
      139 => [:duel_clear_check, 20,false],                                                                                                     # 139:アレクサンドルで20回対戦する
      140 => [:duel_clear_check, 30,false],                                                                                                     # 140:アレクサンドルで30回対戦する
      141 => [:chara_card_check, [[303,1]],false],                                                                                              # 141:Lv3マルセウス
      142 => [:multi_quest_clear_check, 40,false],                                                                                              # 142:アコライトレコード
      143 => [:multi_quest_clear_check, 60,false],                                                                                              # 143:アコライトレコード
      144 => [:multi_quest_clear_check, 4,false],                                                                                               # 144:ブラウクエ
      145 => [:multi_quest_clear_check, 7,false],                                                                                               # 145:ブラウクエ
      146 => [:multi_quest_clear_check, 9,false],                                                                                               # 146:ブラウクエ
      147 => [:multi_quest_clear_check, 15,false],                                                                                              # 147:ルートクエ1
      148 => [:multi_quest_clear_check, 20,false],                                                                                              # 148:ルートクエ2
      149 => [:multi_quest_clear_check, 25,false],                                                                                              # 149:ルートクエ3
      150 => [:multi_quest_clear_check, 4,false],                                                                                               # 150:ルートクエ
      151 => [:multi_quest_clear_check, 7,false],                                                                                               # 151:ルートクエ
      152 => [:multi_quest_clear_check, 9,false],                                                                                               # 152:ルートクエ
      153 => [:multi_quest_clear_check, 15,false],                                                                                              # 153:ブラウクエ1
      154 => [:multi_quest_clear_check, 20,false],                                                                                              # 154:ブラウクエ2
      155 => [:multi_quest_clear_check, 25,false],                                                                                              # 155:ブラウクエ3
      156 => [:chara_card_check, [[323,1]],false],                                                                                              # 156:Lv3リュカ
      157 => [:quest_no_clear_check, 15,false],                                                                                                 # 157:水着イベレコード
      158 => [:quest_no_clear_check, 35,false],                                                                                                 # 158:水着イベレコード
      159 => [:quest_no_clear_check, 50,false],                                                                                                 # 159:水着イベレコード
      160 => [:quest_no_clear_check, 4,false],                                                                                                  # 160:水着イベレコード
      161 => [:quest_no_clear_check, 7,false],                                                                                                  # 161:水着イベレコード
      162 => [:quest_no_clear_check, 9,false],                                                                                                  # 162:水着イベレコード
      163 => [:quest_no_clear_check, 12,false],                                                                                                 # 163:水着イベレコード
      164 => [:quest_no_clear_check, 18,false],                                                                                                 # 164:水着イベレコード
      165 => [:quest_no_clear_check, 4,false],                                                                                                  # 165:水着イベレコード
      166 => [:quest_no_clear_check, 7,false],                                                                                                  # 166:水着イベレコード
      167 => [:quest_no_clear_check, 9,false],                                                                                                  # 167:水着イベレコード
      168 => [:quest_no_clear_check, 12,false],                                                                                                 # 168:水着イベレコード
      169 => [:quest_no_clear_check, 18,false],                                                                                                 # 169:水着イベレコード
      170 => [:chara_card_check, [[333,1]],false],                                                                                              # 170:Lv3ステイシア
      171 => [:item_num_check, [61,5],true],                                                                                                    # 171:鉄の鎖5個
      172 => [:item_num_check, [61,15],true],                                                                                                   # 172:鉄の鎖15個
      173 => [:item_num_check, [61,30],true],                                                                                                   # 173:鉄の鎖30個
      174 => [:item_num_check, [61,50],true],                                                                                                   # 174:鉄の鎖50個
      175 => [:item_num_check, [61,100],true],                                                                                                  # 175:鉄の鎖100個
      176 => [:item_num_check, [62,10],true],                                                                                                   # 176:白金の鎖10個
      177 => [:quest_clear_check, 33,true],                                                                                                     # 177:ブレンダン討伐
      178 => [:quest_clear_check, 33,true],                                                                                                     # 178:ブレンダン討伐(時間制限あり)
      179 => [:chara_card_check, [[343,1]],false],                                                                                              # 179:Lv3ヴォランド
      180 => [:quest_no_clear_check, 1,false],                                                                                                  # 180:初心者用クエストを1回クリア
      181 => [:quest_no_clear_check, 1,false],                                                                                                  # 181:初心者用クエストを2回クリア
      182 => [:quest_no_clear_check, 1,false],                                                                                                  # 182:初心者用クエストを3回クリア
      183 => [:quest_no_clear_check, 5,false],                                                                                                  # 183:2周年レコード5回クリア
      184 => [:quest_no_clear_check, 3,false],                                                                                                  # 184:2周年レコードA3回クリア
      185 => [:quest_no_clear_check, 3,false],                                                                                                  # 185:2周年レコードB3回クリア
      186 => [:quest_no_clear_check, 3,false],                                                                                                  # 186:2周年レコードC3回クリア
      187 => [:quest_no_clear_check, 5,false],                                                                                                  # 187:2周年キャラ個別レコード5回クリア
      188 => [:quest_no_clear_check, 10,false],                                                                                                 # 188:2周年キャラ個別レコード10回クリア
      189 => [:quest_no_clear_check, 15,false],                                                                                                 # 189:2周年キャラ個別レコード15回クリア
      190 => [:quest_no_clear_check, 5,false],                                                                                                  # 190:2周年キャラ個別レコード5回クリア
      191 => [:quest_no_clear_check, 10,false],                                                                                                 # 191:2周年キャラ個別レコード10回クリア
      192 => [:quest_no_clear_check, 15,false],                                                                                                 # 192:2周年キャラ個別レコード15回クリア
      193 => [:quest_no_clear_check, 5,false],                                                                                                  # 193:2周年キャラ個別レコード5回クリア
      194 => [:quest_no_clear_check, 10,false],                                                                                                 # 194:2周年キャラ個別レコード10回クリア
      195 => [:quest_no_clear_check, 15,false],                                                                                                 # 195:2周年キャラ個別レコード15回クリア
      196 => [:quest_no_clear_check, 5,false],                                                                                                  # 196:2周年キャラ個別レコード5回クリア
      197 => [:quest_no_clear_check, 10,false],                                                                                                 # 197:2周年キャラ個別レコード10回クリア
      198 => [:quest_no_clear_check, 15,false],                                                                                                 # 198:2周年キャラ個別レコード15回クリア
      199 => [:quest_no_clear_check, 5,false],                                                                                                  # 199:2周年キャラ個別レコード5回クリア
      200 => [:quest_no_clear_check, 10,false],                                                                                                 # 200:2周年キャラ個別レコード10回クリア
      201 => [:quest_no_clear_check, 15,false],                                                                                                 # 201:2周年キャラ個別レコード15回クリア
      202 => [:quest_no_clear_check, 5,false],                                                                                                  # 202:2周年キャラ個別レコード5回クリア
      203 => [:quest_no_clear_check, 10,false],                                                                                                 # 203:2周年キャラ個別レコード10回クリア
      204 => [:quest_no_clear_check, 15,false],                                                                                                 # 204:2周年キャラ個別レコード15回クリア
      205 => [:quest_no_clear_check, 5,false],                                                                                                  # 205:2周年キャラ個別レコード5回クリア
      206 => [:quest_no_clear_check, 10,false],                                                                                                 # 206:2周年キャラ個別レコード10回クリア
      207 => [:quest_no_clear_check, 15,false],                                                                                                 # 207:2周年キャラ個別レコード15回クリア
      208 => [:quest_no_clear_check, 5,false],                                                                                                  # 208:2周年キャラ個別レコード5回クリア
      209 => [:quest_no_clear_check, 10,false],                                                                                                 # 209:2周年キャラ個別レコード10回クリア
      210 => [:quest_no_clear_check, 15,false],                                                                                                 # 210:2周年キャラ個別レコード15回クリア
      211 => [:quest_no_clear_check, 5,false],                                                                                                  # 211:2周年キャラ個別レコード5回クリア
      212 => [:quest_no_clear_check, 10,false],                                                                                                 # 212:2周年キャラ個別レコード10回クリア
      213 => [:quest_no_clear_check, 15,false],                                                                                                 # 213:2周年キャラ個別レコード15回クリア
      214 => [:quest_no_clear_check, 5,false],                                                                                                  # 214:2周年キャラ個別レコード5回クリア
      215 => [:quest_no_clear_check, 10,false],                                                                                                 # 215:2周年キャラ個別レコード10回クリア
      216 => [:quest_no_clear_check, 15,false],                                                                                                 # 216:2周年キャラ個別レコード15回クリア
      217 => [:quest_no_clear_check, 5,false],                                                                                                  # 217:2周年キャラ個別レコード5回クリア
      218 => [:quest_no_clear_check, 10,false],                                                                                                 # 218:2周年キャラ個別レコード10回クリア
      219 => [:quest_no_clear_check, 15,false],                                                                                                 # 219:2周年キャラ個別レコード15回クリア
      220 => [:quest_no_clear_check, 5,false],                                                                                                  # 220:2周年キャラ個別レコード5回クリア
      221 => [:quest_no_clear_check, 10,false],                                                                                                 # 221:2周年キャラ個別レコード10回クリア
      222 => [:quest_no_clear_check, 15,false],                                                                                                 # 222:2周年キャラ個別レコード15回クリア
      223 => [:quest_no_clear_check, 5,false],                                                                                                  # 223:2周年キャラ個別レコード5回クリア
      224 => [:quest_no_clear_check, 10,false],                                                                                                 # 224:2周年キャラ個別レコード10回クリア
      225 => [:quest_no_clear_check, 15,false],                                                                                                 # 225:2周年キャラ個別レコード15回クリア
      226 => [:quest_no_clear_check, 5,false],                                                                                                  # 226:2周年キャラ個別レコード5回クリア
      227 => [:quest_no_clear_check, 10,false],                                                                                                 # 227:2周年キャラ個別レコード10回クリア
      228 => [:quest_no_clear_check, 15,false],                                                                                                 # 228:2周年キャラ個別レコード15回クリア
      229 => [:quest_no_clear_check, 5,false],                                                                                                  # 229:2周年キャラ個別レコード5回クリア
      230 => [:quest_no_clear_check, 10,false],                                                                                                 # 230:2周年キャラ個別レコード10回クリア
      231 => [:quest_no_clear_check, 15,false],                                                                                                 # 231:2周年キャラ個別レコード15回クリア
      232 => [:duel_clear_check, 1,false],                                                                                                      # 232:ハロウィンレコード1回クリア
      233 => [:duel_clear_check, 4,false],                                                                                                      # 233:ハロウィンレコード4回クリア
      234 => [:duel_clear_check, 5,false],                                                                                                      # 234:ハロウィンレコード5回クリア
      235 => [:chara_card_check, [[353,1]],false],                                                                                              # 235:Lv3CCを入手する
      236 => [:item_calc_check, [[158, 159, 160, 161, 162], 5],true],                                                                           # 236:タグを5個入手
      237 => [:item_calc_check, [[158, 159, 160, 161, 162], 15],true],                                                                          # 237:タグを15個入手
      238 => [:item_calc_check, [[158, 159, 160, 161, 162], 30],true],                                                                          # 238:タグを30個入手
      239 => [:item_set_calc_check, [[158, 159], 1],false],                                                                                     # 239:A・Bタグを1つ入手
      240 => [:item_set_calc_check, [[158, 159, 160, 161], 1],false],                                                                           # 240:A-Dタグを1つ入手
      241 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 2],false],                                                                      # 241:A-Eタグを2つ入手
      242 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 3],false],                                                                      # 242:A-Eタグを3つ入手
      243 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 5],false],                                                                      # 243:A-Eタグを5つ入手
      244 => [:item_set_calc_check, [[160, 161], 1],false],                                                                                     # 244:C・Dタグを1つ入手
      245 => [:item_set_calc_check, [[158, 159, 160, 161], 1],false],                                                                           # 245:A-Dタグを1つ入手
      246 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 2],false],                                                                      # 246:A-Eタグを2つ入手
      247 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 3],false],                                                                      # 247:A-Eタグを3つ入手
      248 => [:item_set_calc_check, [[158, 159, 160, 161, 162], 5],false],                                                                      # 248:A-Eタグを5つ入手
      249 => [:chara_card_check, [[363,1]],false],                                                                                              # 249:Lv3コッブを入手する
      250 => [:chara_card_check, [[373,1]],false],                                                                                              # 250:Lv3イヴリンを入手する
      251 => [:duel_clear_check, 3,false],                                                                                                      # 251:アレクサンドルで3回デュエルする
      252 => [:duel_clear_check, 7,false],                                                                                                      # 252:アレクサンドル以外で7回デュエルする
      253 => [:chara_card_check, [[393,1]],false],                                                                                              # 253:Lv3カレンベルクを入手する
      254 => [:quest_present_check, 1, false],                                                                                                  # 254:星1クエストをプレゼント
      255 => [:quest_present_check, 1, false],                                                                                                  # 255:星2クエストをプレゼント
      256 => [:quest_present_check, 1, false],                                                                                                  # 256:星3クエストをプレゼント
      257 => [:quest_present_check, 1, false],                                                                                                  # 257:星4クエストをプレゼント
      258 => [:quest_present_check, 1, false],                                                                                                  # 258:星5クエストをプレゼント
      259 => [:quest_present_check, 1, false],                                                                                                  # 259:星6クエストをプレゼント
      260 => [:quest_present_check, 1, false],                                                                                                  # 260:星7クエストをプレゼント
      261 => [:quest_present_check, 1, false],                                                                                                  # 261:星8クエストをプレゼント
      262 => [:quest_present_check, 1, false],                                                                                                  # 262:星9クエストをプレゼント
      263 => [:quest_present_check, 1, false],                                                                                                  # 263:星10クエストをプレゼント
      264 => [:duel_clear_check, 1,false],                                                                                                      # 264:フレンドと1vs1デュエルをする
      265 => [:duel_clear_check, 1,false],                                                                                                      # 265:フレンドと3vs3デュエルをする
      266 => [:chara_card_check, [[403,1]],false],                                                                                              # 266:Lv3ネネムを入手する
      267 => [:quest_no_clear_check, 3,false],                                                                                                  # 267:アイザックのホワイトデー3クリア
      268 => [:quest_no_clear_check, 7,false],                                                                                                  # 268:アイザックのホワイトデー8クリア
      269 => [:quest_no_clear_check, 10,false],                                                                                                 # 269:アイザックのホワイトデー15クリア
      270 => [:quest_no_clear_check, 30,false],                                                                                                 # 270:アイザックのホワイトデー30クリア
      271 => [:quest_no_clear_check, 3,false],                                                                                                  # 271:ジェッドのホワイトデー3クリア
      272 => [:quest_no_clear_check, 7,false],                                                                                                  # 272:ジェッドのホワイトデー8クリア
      273 => [:quest_no_clear_check, 10,false],                                                                                                 # 273:ジェッドのホワイトデー15クリア
      274 => [:quest_no_clear_check, 30,false],                                                                                                 # 274:ジェッドのホワイトデー30クリア
      275 => [:quest_no_clear_check, 3,false],                                                                                                  # 275:サルガドのホワイトデー3クリア
      276 => [:quest_no_clear_check, 7,false],                                                                                                  # 276:サルガドのホワイトデー8クリア
      277 => [:quest_no_clear_check, 10,false],                                                                                                 # 277:サルガドのホワイトデー15クリア
      278 => [:quest_no_clear_check, 30,false],                                                                                                 # 278:サルガドのホワイトデー30クリア
      279 => [:record_clear_check, 12,false],                                                                                                   # 279:全てのイベントレコードをクリアする
      280 => [:duel_clear_check, 3,false],                                                                                                      # 280:3回デュエルする
      281 => [:duel_clear_check, 5,false],                                                                                                      # 281:+5回デュエルする
      282 => [:duel_clear_check, 7,false],                                                                                                      # 282:+7回デュエルする
      283 => [:duel_clear_check, 15,false],                                                                                                     # 283:+15回デュエルする
      284 => [:chara_card_check, [[413,1]],false],                                                                                              # 266:Lv3コンラッドを入手する
      285 => [:get_card_level_check, [3,2,false,1] ,false],                                                                                     # 285:Lv3カードを合成する  [Lv,Rarity,レア判定,枚数]
      286 => [:get_card_level_check, [5,2,false,1] ,false],                                                                                     # 286:Lv5カードを合成する  [Lv,Rarity,レア判定,枚数]
      287 => [:get_card_level_check, [0,6,true,1] ,false],                                                                                      # 287:レアカードを合成する [Lv,Rarity,レア判定,枚数]
      288 => [:week_duel_clear_check, 1,false],                                                                                                 # 288:週間Duelレコード：1
      289 => [:week_duel_clear_check, 1,false],                                                                                                 # 289:週間Duelレコード：2
      290 => [:week_duel_clear_check, 1,false],                                                                                                 # 290:週間Duelレコード：3
      291 => [:week_duel_clear_check, 1,false],                                                                                                 # 291:週間Duelレコード：4
      292 => [:week_duel_clear_check, 1,false],                                                                                                 # 292:週間Duelレコード：5
      293 => [:week_duel_clear_check, 1,false],                                                                                                 # 293:週間Duelレコード：6
      294 => [:week_duel_clear_check, 1,false],                                                                                                 # 294:週間Duelレコード：7
      295 => [:week_duel_clear_check, 1,false],                                                                                                 # 295:週間Duelレコード：8
      296 => [:week_duel_clear_check, 1,false],                                                                                                 # 296:週間Duelレコード：9
      297 => [:week_duel_clear_check, 1,false],                                                                                                 # 297:週間Duelレコード：10
      298 => [:week_duel_clear_check, 1,false],                                                                                                 # 298:週間Duelレコード：11
      299 => [:week_duel_clear_check, 1,false],                                                                                                 # 299:週間Duelレコード：12
      300 => [:week_duel_clear_check, 1,false],                                                                                                 # 300:週間Duelレコード：13
      301 => [:week_duel_clear_check, 1,false],                                                                                                 # 301:週間Duelレコード：14
      302 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 1],false],                                                                            # 302:投票券を1個入手
      303 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 10],false],                                                                           # 303:投票券を10個入手
      304 => [:chara_card_check, [[423,1]],false],                                                                                              # 304:Lv3ビアギッテを入手する
      305 => [:quest_no_clear_check, 5,false],                                                                                                  # 305:レアカードクエスト1
      306 => [:quest_no_clear_check, 10,false],                                                                                                 # 306:レアカードクエスト2
      307 => [:quest_no_clear_check, 5,false],                                                                                                  # 307:レアカードクエスト1
      308 => [:quest_no_clear_check, 10,false],                                                                                                 # 308:レアカードクエスト2
      309 => [:quest_no_clear_check, 5,false],                                                                                                  # 309:レアカードクエスト1
      310 => [:quest_no_clear_check, 10,false],                                                                                                 # 310:レアカードクエスト2
      311 => [:quest_no_clear_check, 5,false],                                                                                                  # 311:レアカードクエスト1
      312 => [:quest_no_clear_check, 10,false],                                                                                                 # 312:レアカードクエスト2
      313 => [:quest_no_clear_check, 5,false],                                                                                                  # 313:レアカードクエスト1
      314 => [:quest_no_clear_check, 10,false],                                                                                                 # 314:レアカードクエスト2
      315 => [:quest_no_clear_check, 5,false],                                                                                                  # 315:レアカードクエスト1
      316 => [:quest_no_clear_check, 10,false],                                                                                                 # 316:レアカードクエスト2
      317 => [:quest_no_clear_check, 5,false],                                                                                                  # 317:レアカードクエスト1
      318 => [:quest_no_clear_check, 10,false],                                                                                                 # 318:レアカードクエスト2
      319 => [:quest_no_clear_check, 5,false],                                                                                                  # 319:レアカードクエスト1
      320 => [:quest_no_clear_check, 10,false],                                                                                                 # 320:レアカードクエスト2
      321 => [:quest_no_clear_check, 5,false],                                                                                                  # 321:レアカードクエスト1
      322 => [:quest_no_clear_check, 10,false],                                                                                                 # 322:レアカードクエスト2
      323 => [:quest_no_clear_check, 5,false],                                                                                                  # 323:レアカードクエスト1
      324 => [:quest_no_clear_check, 10,false],                                                                                                 # 324:レアカードクエスト2
      325 => [:quest_no_clear_check, 5,false],                                                                                                  # 325:レアカードクエスト1
      326 => [:quest_no_clear_check, 10,false],                                                                                                 # 326:レアカードクエスト2
      327 => [:quest_no_clear_check, 5,false],                                                                                                  # 327:レアカードクエスト1
      328 => [:quest_no_clear_check, 10,false],                                                                                                 # 328:レアカードクエスト2
      329 => [:quest_no_clear_check, 5,false],                                                                                                  # 329:レアカードクエスト1
      330 => [:quest_no_clear_check, 10,false],                                                                                                 # 330:レアカードクエスト2
      331 => [:quest_no_clear_check, 5,false],                                                                                                  # 331:レアカードクエスト1
      332 => [:quest_no_clear_check, 10,false],                                                                                                 # 332:レアカードクエスト2
      333 => [:quest_no_clear_check, 5,false],                                                                                                  # 333:レアカードクエスト1
      334 => [:quest_no_clear_check, 10,false],                                                                                                 # 334:レアカードクエスト2
      335 => [:quest_no_clear_check, 5,false],                                                                                                  # 335:レアカードクエスト1
      336 => [:quest_no_clear_check, 10,false],                                                                                                 # 336:レアカードクエスト2
      337 => [:quest_no_clear_check, 5,false],                                                                                                  # 337:レアカードクエスト1
      338 => [:quest_no_clear_check, 10,false],                                                                                                 # 338:レアカードクエスト2
      339 => [:quest_no_clear_check, 5,false],                                                                                                  # 339:レアカードクエスト1
      340 => [:quest_no_clear_check, 10,false],                                                                                                 # 340:レアカードクエスト2
      341 => [:quest_no_clear_check, 5,false],                                                                                                  # 341:レアカードクエスト1
      342 => [:quest_no_clear_check, 10,false],                                                                                                 # 342:レアカードクエスト2
      343 => [:quest_no_clear_check, 5,false],                                                                                                  # 343:レアカードクエスト1
      344 => [:quest_no_clear_check, 10,false],                                                                                                 # 344:レアカードクエスト2
      345 => [:record_clear_check, 3,false],                                                                                                    # 345:3つレアカードレコードをクリアする
      346 => [:chara_card_check, [[433,1]],false],                                                                                              # 346:Lv3クーンを入手する
      347 => [:duel_clear_check, 10,false],                                                                                                     # 347:10回デュエルする
      348 => [:quest_no_clear_check, 99999 ,false],                                                                                             # 348:カエル王子ポイントをカウント
      349 => [:quest_no_clear_check, 3,false],                                                                                                  # 349:3pt達成
      350 => [:quest_no_clear_check, 10,false],                                                                                                 # 350:10pt達成
      351 => [:quest_no_clear_check, 20,false],                                                                                                 # 351:20pt達成
      352 => [:quest_no_clear_check, 30,false],                                                                                                 # 352:30pt達成
      353 => [:quest_no_clear_check, 100,false],                                                                                                # 353:100pt達成
      354 => [:chara_card_check, [[443,1]],false],                                                                                              # 354:Lv3シャーロットを入手する
      355 => [:item_set_calc_check, [[163], 3],true],                                                                                           # 355:タリスマンAを3個集める
      356 => [:item_set_calc_check, [[163], 15],true],                                                                                          # 356:タリスマンAを15個集める
      357 => [:item_set_calc_check, [[165], 5],true],                                                                                           # 357:タリスマンCを5個集める
      358 => [:item_set_calc_check, [[165], 20],true],                                                                                          # 358:タリスマンCを20個集める
      359 => [:item_set_calc_check, [[163, 164, 165], 30],true],                                                                                # 359:タリスマンABCを30個ずつ集める
      360 => [:item_set_calc_check, [[164], 3],true],                                                                                           # 360:タリスマンBを3個集める
      361 => [:item_set_calc_check, [[164], 15],true],                                                                                          # 361:タリスマンBを15個集める
      362 => [:item_set_calc_check, [[165], 5],true],                                                                                           # 362:タリスマンCを5個集める
      363 => [:item_set_calc_check, [[165], 20],true],                                                                                          # 363:タリスマンCを20個集める
      364 => [:item_set_calc_check, [[163, 164, 165], 30],true],                                                                                # 364:タリスマンABCを30個ずつ集める
      365 => [:chara_card_check, [[453,1]],false],                                                                                              # 365:Lv3タイレルを入手する
      366 => [:quest_point_check, 10,true],                                                                                                     # 366:クエストポイントを10獲得する
      367 => [:quest_point_check, 50,true],                                                                                                     # 367:クエストポイントを50獲得する
      368 => [:quest_point_check, 100,true],                                                                                                    # 368:クエストポイントを100獲得する
      369 => [:quest_point_check, 300,true],                                                                                                    # 369:クエストポイントを300獲得する
      370 => [:quest_point_check, 500,true],                                                                                                    # 370:クエストポイントを500獲得する
      371 => [:quest_point_check, 700,true],                                                                                                    # 371:クエストポイントを700獲得する
      372 => [:quest_point_check, 1000,true],                                                                                                   # 372:クエストポイントを1000獲得する
      373 => [:quest_point_check, 2000,true],                                                                                                   # 373:クエストポイントを2000獲得する
      374 => [:quest_point_check, 3000,true],                                                                                                   # 374:クエストポイントを3000獲得する
      375 => [:chara_card_check, [[463,1]],false],                                                                                              # 375:Lv3ルディアを入手する
      376 => [:get_weapon_check, 1,false],                                                                                                      # 376:新たに装備カードを1枚取得する
      377 => [:get_weapon_check, 3,false],                                                                                                      # 377:新たに装備カードを3枚取得する
      378 => [:item_num_check, [166,1],true],                                                                                                   # 378:ドールアイ（橙）1個
      379 => [:item_num_check, [166,5],true],                                                                                                   # 379:ドールアイ（橙）5個
      380 => [:item_num_check, [166,15],true],                                                                                                  # 380:ドールアイ（橙）15個
      381 => [:item_num_check, [166,30],true],                                                                                                  # 381:ドールアイ（橙）30個
      382 => [:item_num_check, [166,50],true],                                                                                                  # 382:ドールアイ（橙）50個
      383 => [:item_num_check, [167,1],true],                                                                                                   # 383:ドールアイ（紫）1個
      384 => [:item_num_check, [167,5],true],                                                                                                   # 384:ドールアイ（紫）5個
      385 => [:item_num_check, [167,15],true],                                                                                                  # 385:ドールアイ（紫）15個
      386 => [:item_num_check, [167,30],true],                                                                                                  # 386:ドールアイ（紫）30個
      387 => [:item_num_check, [167,50],true],                                                                                                  # 387:ドールアイ（紫）50個
      388 => [:item_num_check, [168,1],true],                                                                                                   # 388:ドールアイ（金）1個
      389 => [:item_num_check, [168,5],true],                                                                                                   # 389:ドールアイ（金）5個
      390 => [:item_num_check, [168,15],true],                                                                                                  # 390:ドールアイ（金）15個
      391 => [:item_num_check, [168,30],true],                                                                                                  # 391:ドールアイ（金）30個
      392 => [:item_num_check, [168,50],true],                                                                                                  # 392:ドールアイ（金）50個
      393 => [:chara_card_check, [[473,1]],false],                                                                                              # 393:Lv3ヴィルヘルムを入手する
      394 => [:chara_card_check, [[483,1]],false],                                                                                              # 394:Lv3メリーを入手する
      395 => [:item_num_check, [213,5],true],                                                                                                   # 395:A中隊のタグを5個集める
      396 => [:item_num_check, [213,15],true],                                                                                                  # 396:A中隊のタグを15個集める
      397 => [:item_num_check, [213,30],true],                                                                                                  # 397:A中隊のタグを30個集める
      398 => [:item_num_check, [213,50],true],                                                                                                  # 398:A中隊のタグを50個集める
      399 => [:item_num_check, [214,5],true],                                                                                                   # 399:F中隊のタグを5個集める
      400 => [:item_num_check, [214,15],true],                                                                                                  # 400:F中隊のタグを15個集める
      401 => [:item_num_check, [214,30],true],                                                                                                  # 401:F中隊のタグを30個集める
      402 => [:item_num_check, [214,50],true],                                                                                                  # 402:F中隊のタグを50個集める
      403 => [:item_num_check, [215,5],true],                                                                                                   # 403:D中隊のタグを5個集める
      404 => [:item_num_check, [215,15],true],                                                                                                  # 404:D中隊のタグを15個集める
      405 => [:item_num_check, [215,30],true],                                                                                                  # 405:D中隊のタグを30個集める
      406 => [:item_num_check, [215,50],true],                                                                                                  # 406:D中隊のタグを50個集める
      407 => [:item_num_check, [216,5],true],                                                                                                   # 407:E中隊のタグを5個集める
      408 => [:item_num_check, [216,15],true],                                                                                                  # 408:E中隊のタグを15個集める
      409 => [:item_num_check, [216,30],true],                                                                                                  # 409:E中隊のタグを30個集める
      410 => [:item_num_check, [216,50],true],                                                                                                  # 410:E中隊のタグを50個集める
      411 => [:item_calc_check, [[213,214,215,216],15],true],                                                                                   # 411:タグを15個集める
      412 => [:item_calc_check, [[213,214,215,216],30],true],                                                                                   # 412:タグを30個集める
      413 => [:weapon_multi_num_check, [[39,48,63,96],2],true],                                                                                 # 413:39,48,63,96の武器を2個集める
      414 => [:duel_clear_check, 10,false],                                                                                                     # 414:10回デュエルする
      415 => [:quest_no_clear_check, 1,false],                                                                                                  # 415:炎の聖女1をクリア
      416 => [:quest_no_clear_check, 1,false],                                                                                                  # 416:炎の聖女2をクリア
      417 => [:quest_no_clear_check, 1,false],                                                                                                  # 417:炎の聖女3をクリア
      418 => [:chara_card_check, [[493,1]],false],                                                                                              # 418:Lv3ギュスターヴを入手する
      419 => [:item_num_check, [221,3],true],                                                                                                   # 419:レッドチップを3個集める
      420 => [:item_num_check, [221,10],true],                                                                                                  # 420:レッドチップを10個集める
      421 => [:item_num_check, [221,20],true],                                                                                                  # 421:レッドチップを20個集める
      422 => [:item_num_check, [221,30],true],                                                                                                  # 422:レッドチップを30個集める
      423 => [:item_num_check, [221,50],true],                                                                                                  # 423:レッドチップを50個集める
      424 => [:item_num_check, [222,3],true],                                                                                                   # 424:ブルーチップを3個集める
      425 => [:item_num_check, [222,10],true],                                                                                                  # 425:ブルーチップを10個集める
      426 => [:item_num_check, [222,20],true],                                                                                                  # 426:ブルーチップを20個集める
      427 => [:item_num_check, [222,30],true],                                                                                                  # 427:ブルーチップを30個集める
      428 => [:item_num_check, [222,50],true],                                                                                                  # 428:ブルーチップを50個集める
      429 => [:week_quest_clear_check, 1,false],                                                                                                # 429:週間Questレコード：1
      430 => [:week_quest_clear_check, 1,false],                                                                                                # 430:週間Questレコード：2
      431 => [:week_quest_clear_check, 1,false],                                                                                                # 431:週間Questレコード：3
      432 => [:week_quest_clear_check, 1,false],                                                                                                # 432:週間Questレコード：4
      433 => [:week_quest_clear_check, 1,false],                                                                                                # 433:週間Questレコード：5
      434 => [:week_quest_clear_check, 1,false],                                                                                                # 434:週間Questレコード：6
      435 => [:week_quest_clear_check, 1,false],                                                                                                # 435:週間Questレコード：7
      436 => [:week_quest_clear_check, 1,false],                                                                                                # 436:週間Questレコード：8
      437 => [:week_quest_clear_check, 1,false],                                                                                                # 437:週間Questレコード：9
      438 => [:week_quest_clear_check, 1,false],                                                                                                # 438:週間Questレコード：10
      439 => [:week_quest_clear_check, 1,false],                                                                                                # 439:週間Questレコード：11
      440 => [:week_quest_clear_check, 1,false],                                                                                                # 440:週間Questレコード：12
      441 => [:week_quest_clear_check, 1,false],                                                                                                # 441:週間Questレコード：13
      442 => [:week_quest_clear_check, 1,false],                                                                                                # 442:週間Questレコード：14
      443 => [:chara_card_check, [[503,1]],false],                                                                                              # 443:Lv3ユーリカを入手する
      444 => [:find_raid_profound, 1,false],                                                                                                    # 444:レイドボス1の渦を1回発見する
      445 => [:find_raid_profound, 3,false],                                                                                                    # 445:レイドボス1の渦を3回発見する
      446 => [:find_raid_profound, 5,false],                                                                                                    # 446:レイドボス1の渦を5回発見する
      447 => [:find_raid_profound, 1,false],                                                                                                    # 447:レイドボス2の渦を1回発見する
      448 => [:find_raid_profound, 3,false],                                                                                                    # 448:レイドボス2の渦を3回発見する
      449 => [:find_raid_profound, 5,false],                                                                                                    # 449:レイドボス2の渦を5回発見する
      450 => [:find_raid_profound, 1,false],                                                                                                    # 450:レイドボス3の渦を1回発見する
      451 => [:find_raid_profound, 3,false],                                                                                                    # 451:レイドボス3の渦を3回発見する
      452 => [:find_raid_profound, 5,false],                                                                                                    # 452:レイドボス3の渦を5回発見する
      453 => [:raid_btl_cnt, 5,false],                                                                                                          # 452:レイド戦に5回参加する
      454 => [:raid_btl_cnt, 10,false],                                                                                                         # 453:レイド戦に10回参加する
      455 => [:raid_btl_cnt, 30,false],                                                                                                         # 454:レイド戦に30回参加する
      456 => [:raid_btl_cnt, 50,false],                                                                                                         # 455:レイド戦に50回参加する
      457 => [:find_raid_profound, 3,false],                                                                                                    # 457:赤死獣の渦を3回発見する
      458 => [:find_raid_profound, 5,false],                                                                                                    # 458:赤死獣の渦を10回発見する
      459 => [:find_raid_profound, 10,false],                                                                                                   # 459:赤死獣の渦を15回発見する
      460 => [:find_raid_profound, 12,false],                                                                                                   # 460:赤死獣の渦を30回発見する
      461 => [:find_raid_profound, 3,false],                                                                                                    # 461:黒死獣の渦を3回発見する
      462 => [:find_raid_profound, 5,false],                                                                                                    # 462:黒死獣の渦を10回発見する
      463 => [:find_raid_profound, 10,false],                                                                                                   # 463:黒死獣の渦を15回発見する
      464 => [:find_raid_profound, 12,false],                                                                                                   # 464:黒死獣の渦を30回発見する
      465 => [:item_num_check, [223,3],true],                                                                                                   # 465:コアの欠片（緑）を3個集める
      466 => [:item_num_check, [223,10],true],                                                                                                  # 466:コアの欠片（緑）を10個集める
      467 => [:item_num_check, [223,30],true],                                                                                                  # 467:コアの欠片（緑）を30個集める
      468 => [:item_num_check, [223,50],true],                                                                                                  # 468:コアの欠片（緑）を50個集める
      469 => [:item_num_check, [224,3],true],                                                                                                   # 469:コアの欠片（青）を3個集める
      470 => [:item_num_check, [224,10],true],                                                                                                  # 470:コアの欠片（青）を10個集める
      471 => [:item_num_check, [224,30],true],                                                                                                  # 471:コアの欠片（青）を30個集める
      472 => [:item_num_check, [224,50],true],                                                                                                  # 472:コアの欠片（青）を50個集める
      473 => [:raid_btl_cnt, 10,false],                                                                                                         # 473:赤死獣の渦に10回参戦する
      474 => [:raid_btl_cnt, 15,false],                                                                                                         # 474:赤死獣の渦に+15回参戦する
      475 => [:raid_btl_cnt, 25,false],                                                                                                         # 475:赤死獣の渦に+25回参戦する
      476 => [:raid_btl_cnt, 50,false],                                                                                                         # 476:赤死獣の渦に+50回参戦する
      477 => [:raid_btl_cnt, 10,false],                                                                                                         # 477:黒死獣の渦に10回参戦する
      478 => [:raid_btl_cnt, 15,false],                                                                                                         # 478:黒死獣の渦に+15回参戦する
      479 => [:raid_btl_cnt, 25,false],                                                                                                         # 479:黒死獣の渦に+25回参戦する
      480 => [:raid_btl_cnt, 50,false],                                                                                                         # 480:黒死獣の渦に+50回参戦する
      481 => [:raid_btl_cnt, 10,false],                                                                                                         # 481:レイド戦に10回参戦する
      482 => [:raid_btl_cnt, 10,false],                                                                                                         # 482:レイド戦に+10回参戦する
      483 => [:raid_btl_cnt, 10,false],                                                                                                         # 483:レイド戦に+10回参戦する
      484 => [:raid_btl_cnt, 10,false],                                                                                                         # 484:レイド戦に+10回参戦する
      485 => [:raid_btl_cnt, 10,false],                                                                                                         # 485:レイド戦に+10回参戦する
      486 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 5],true],                                                                             # 486:投票券を1個入手
      487 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 10],true],                                                                            # 487:投票券を5個入手
      488 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 30],true],                                                                            # 488:投票券を10個入手
      489 => [:item_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 100],true],                                                                           # 489:投票券を100個入手
      490 => [:invite_count_check,3,false],                                                                                                     # 490:3人招待する
      491 => [:invite_count_check,5,false],                                                                                                     # 491:5人招待する
      492 => [:invite_count_check,10,false],                                                                                                    # 492:10人招待する
      493 => [:chara_card_check, [[513,1]],false],                                                                                              # 493:Lv3リンナエウスを入手する
      494 => [:quest_present_check,  5, false],                                                                                                 # 494:クエストを5個プレゼント//5月イベント
      495 => [:quest_present_check, 10, false],                                                                                                 # 495:クエストを10個プレゼント//5月イベント
      496 => [:quest_present_check, 15, false],                                                                                                 # 496:クエストを15個プレゼント//5月イベント
      497 => [:quest_present_check, 20, false],                                                                                                 # 497:クエストを20個プレゼント//5月イベント
      498 => [:quest_present_check, 35, false],                                                                                                 # 498:クエストを30個プレゼント//5月イベント
      499 => [:chara_card_check, [[2071,1]],false],                                                                                             # 499:地上へ復活したアーチボルトを入手する
      500 => [:chara_card_check, [[2101,1]],false],                                                                                             # 500:地上へ復活したシェリを入手する
      501 => [:item_num_check, [225,5],true],                                                                                                   # 501:コアの欠片（赤）を5個集める
      502 => [:item_num_check, [225,10],true],                                                                                                  # 502:コアの欠片（赤）を10個集める
      503 => [:item_num_check, [225,30],true],                                                                                                  # 503:コアの欠片（赤）を30個集める
      504 => [:item_num_check, [225,50],true],                                                                                                  # 504:コアの欠片（赤）を50個集める
      505 => [:item_num_check, [226,5],true],                                                                                                   # 505:コアの欠片（黄）を5個集める
      506 => [:item_num_check, [226,10],true],                                                                                                  # 506:コアの欠片（黄）を10個集める
      507 => [:item_num_check, [226,30],true],                                                                                                  # 507:コアの欠片（黄）を30個集める
      508 => [:item_num_check, [226,50],true],                                                                                                  # 508:コアの欠片（黄）を50個集める
      509 => [:raid_boss_defeat_check, 10,false],                                                                                               # 509:妖蛆の討伐に10回成功する
      510 => [:raid_boss_defeat_check, 20,false],                                                                                               # 510:妖蛆の討伐に20回成功する
      511 => [:raid_boss_defeat_check, 30,false],                                                                                               # 511:妖蛆の討伐に30回成功する
      512 => [:raid_all_damage_check, 300,false],                                                                                               # 512:レイドボスに合計300ダメージを与える
      513 => [:raid_all_damage_check, 700,false],                                                                                               # 513:レイドボスに合計+700ダメージを与える
      514 => [:raid_all_damage_check, 1000,false],                                                                                              # 514:レイドボスに合計+1000ダメージを与える
      515 => [:chara_card_check, [[523,1]],false],                                                                                              # 515:Lv3ナディーンを入手する
      516 => [:created_days_check, 30,true],                                                                                                    # 516:アバター作製から30日が経過している
      517 => [:created_days_check, 90,true],                                                                                                    # 517:アバター作製から90日が経過している
      518 => [:created_days_check, 180,true],                                                                                                   # 518:アバター作製から180日が経過している
      519 => [:created_days_check, 365,true],                                                                                                   # 519:アバター作製から365日が経過している
      520 => [:item_num_check, [93,3],true],                                                                                                    # 521:イベントアイテムを3個集める
      521 => [:item_num_check, [93,10],true],                                                                                                   # 522:イベントアイテムを10個集める
      522 => [:item_num_check, [93,20],true],                                                                                                   # 523:イベントアイテムを20個集める
      523 => [:item_num_check, [93,30],true],                                                                                                   # 524:イベントアイテムを30個集める
      524 => [:item_num_check, [93,50],true],                                                                                                   # 525:イベントアイテムを50個集める
      525 => [:quest_no_clear_check, 30,false],                                                                                                 # 526:Infectionクエストを30回クリア
      526 => [:chara_card_check, [[2091,1]],false],                                                                                             # 526:地上へ復活したブレイズを入手する
      527 => [:chara_card_check, [[2151,1]],false],                                                                                             # 527:地上へ復活したドニタを入手する
      528 => [:event_point_check, 99999 ,false],                                                                                                # 528:20140820イベント用ポイント加算レコード
      529 => [:event_point_cnt_check, [528,50] ,true],                                                                                          # 529:20140820イベントポイントを50取得する
      530 => [:event_point_cnt_check, [528,300] ,true],                                                                                         # 530:20140820イベントポイントを300取得する
      531 => [:event_point_cnt_check, [528,500] ,true],                                                                                         # 531:20140820イベントポイントを500取得する
      532 => [:event_point_cnt_check, [528,1000] ,true],                                                                                        # 532:20140820イベントポイントを1000取得する
      533 => [:event_point_cnt_check, [528,1500] ,true],                                                                                        # 533:20140820イベントポイントを1500取得する
      534 => [:event_point_cnt_check, [528,2000] ,true],                                                                                        # 534:20140820イベントポイントを2000取得する
      535 => [:chara_card_check, [[533,1]],false],                                                                                              # 535:Lv3ディノを入手する
      536 => [:item_num_check, [227,10],true],                                                                                                  # 536:イベントアイテムを10個集める
      537 => [:item_num_check, [227,30],true],                                                                                                  # 537:イベントアイテムを30個集める
      538 => [:item_num_check, [227,50],true],                                                                                                  # 538:イベントアイテムを50個集める
      539 => [:item_num_check, [227,100],true],                                                                                                 # 539:イベントアイテムを100個集める
      540 => [:item_num_check, [227,150],true],                                                                                                 # 540:イベントアイテムを150個集める
      541 => [:item_num_check, [227,200],true],                                                                                                 # 541:イベントアイテムを200個集める
      542 => [:item_num_check, [227,300],true],                                                                                                 # 542:イベントアイテムを300個集める
      543 => [:item_num_check, [228,10],true],                                                                                                  # 543:イベントアイテムを10個集める
      544 => [:item_num_check, [228,30],true],                                                                                                  # 544:イベントアイテムを30個集める
      545 => [:item_num_check, [228,50],true],                                                                                                  # 545:イベントアイテムを50個集める
      546 => [:item_num_check, [228,100],true],                                                                                                 # 546:イベントアイテムを100個集める
      547 => [:item_num_check, [228,150],true],                                                                                                 # 547:イベントアイテムを150個集める
      548 => [:item_num_check, [228,200],true],                                                                                                 # 548:イベントアイテムを200個集める
      549 => [:item_num_check, [228,300],true],                                                                                                 # 549:イベントアイテムを300個集める
      550 => [:raid_boss_defeat_check, 10,false],                                                                                               # 550:妖蛆の討伐に10回成功する
      551 => [:raid_boss_defeat_check, 20,false],                                                                                               # 551:妖蛆の討伐に20回成功する
      552 => [:raid_boss_defeat_check, 30,false],                                                                                               # 552:妖蛆の討伐に30回成功する
      553 => [:raid_all_damage_check, 100,false],                                                                                               # 553:レイドボスに合計100ダメージを与える
      554 => [:raid_all_damage_check, 500,false],                                                                                               # 554:レイドボスに合計+500ダメージを与える
      555 => [:raid_all_damage_check, 900,false],                                                                                               # 555:レイドボスに合計+900ダメージを与える
      556 => [:chara_card_check, [[2111,1]],false],                                                                                             # 526:地上へ復活したアインを入手する
      557 => [:chara_card_check, [[2121,1]],false],                                                                                             # 527:地上へ復活したベルンハルトを入手する
      558 => [:item_num_check, [233,10],true],                                                                                                  # 536:はちみつを10個集める
      559 => [:item_num_check, [233,30],true],                                                                                                  # 537:はちみつを30個集める
      560 => [:item_num_check, [233,50],true],                                                                                                  # 538:はちみつを50個集める
      561 => [:item_num_check, [233,100],true],                                                                                                 # 539:はちみつを100個集める
      562 => [:item_num_check, [233,150],true],                                                                                                 # 539:はちみつを150個集める
      563 => [:chara_card_check, [[563,1]],false],                                                                                              # 563:Lv3白シアを入手する
      564 => [:quest_no_clear_check, 3,false],                                                                                                  # 564:2014/11イベントAコース、Aクエスト
      565 => [:quest_no_clear_check, 5,false],                                                                                                  # 565:2014/11イベントAコース、Aクエスト
      566 => [:quest_no_clear_check, 7,false],                                                                                                  # 566:2014/11イベントAコース、Aクエスト
      567 => [:quest_no_clear_check, 10,false],                                                                                                 # 567:2014/11イベントAコース、Aクエスト
      568 => [:quest_no_clear_check, 4,false],                                                                                                  # 568:2014/11イベントA1コース、Bクエスト
      569 => [:quest_no_clear_check, 6,false],                                                                                                  # 569:2014/11イベントA1コース、Bクエスト
      570 => [:quest_no_clear_check, 10,false],                                                                                                 # 570:2014/11イベントA1コース、Bクエスト
      571 => [:quest_no_clear_check, 15,false],                                                                                                 # 571:2014/11イベントA1コース、Bクエスト
      572 => [:quest_no_clear_check, 5,false],                                                                                                  # 572:2014/11イベントA1コース、Cクエスト
      573 => [:quest_no_clear_check, 7,false],                                                                                                  # 573:2014/11イベントA1コース、Cクエスト
      574 => [:quest_no_clear_check, 11,false],                                                                                                 # 574:2014/11イベントA1コース、Cクエスト
      575 => [:quest_no_clear_check, 17,false],                                                                                                 # 575:2014/11イベントA1コース、Cクエスト
      576 => [:quest_no_clear_check, 4,false],                                                                                                  # 576:2014/11イベントA2コース、Cクエスト
      577 => [:quest_no_clear_check, 6,false],                                                                                                  # 577:2014/11イベントA2コース、Cクエスト
      578 => [:quest_no_clear_check, 10,false],                                                                                                 # 578:2014/11イベントA2コース、Cクエスト
      579 => [:quest_no_clear_check, 15,false],                                                                                                 # 579:2014/11イベントA2コース、Cクエスト
      580 => [:quest_no_clear_check, 5,false],                                                                                                  # 580:2014/11イベントA2コース、Bクエスト
      581 => [:quest_no_clear_check, 7,false],                                                                                                  # 581:2014/11イベントA2コース、Bクエスト
      582 => [:quest_no_clear_check, 11,false],                                                                                                 # 582:2014/11イベントA2コース、Bクエスト
      583 => [:quest_no_clear_check, 17,false],                                                                                                 # 583:2014/11イベントA2コース、Bクエスト
      584 => [:quest_no_clear_check, 3,false],                                                                                                  # 584:2014/11イベントBコース、Bクエスト
      585 => [:quest_no_clear_check, 5,false],                                                                                                  # 585:2014/11イベントBコース、Bクエスト
      586 => [:quest_no_clear_check, 7,false],                                                                                                  # 586:2014/11イベントBコース、Bクエスト
      587 => [:quest_no_clear_check, 10,false],                                                                                                 # 587:2014/11イベントBコース、Bクエスト
      588 => [:quest_no_clear_check, 4,false],                                                                                                  # 588:2014/11イベントB1コース、Aクエスト
      589 => [:quest_no_clear_check, 6,false],                                                                                                  # 589:2014/11イベントB1コース、Aクエスト
      590 => [:quest_no_clear_check, 10,false],                                                                                                 # 590:2014/11イベントB1コース、Aクエスト
      591 => [:quest_no_clear_check, 15,false],                                                                                                 # 591:2014/11イベントB1コース、Aクエスト
      592 => [:quest_no_clear_check, 5,false],                                                                                                  # 592:2014/11イベントB1コース、Cクエスト
      593 => [:quest_no_clear_check, 7,false],                                                                                                  # 593:2014/11イベントB1コース、Cクエスト
      594 => [:quest_no_clear_check, 11,false],                                                                                                 # 594:2014/11イベントB1コース、Cクエスト
      595 => [:quest_no_clear_check, 17,false],                                                                                                 # 595:2014/11イベントB1コース、Cクエスト
      596 => [:quest_no_clear_check, 4,false],                                                                                                  # 596:2014/11イベントB2コース、Cクエスト
      597 => [:quest_no_clear_check, 6,false],                                                                                                  # 597:2014/11イベントB2コース、Cクエスト
      598 => [:quest_no_clear_check, 10,false],                                                                                                 # 598:2014/11イベントB2コース、Cクエスト
      599 => [:quest_no_clear_check, 15,false],                                                                                                 # 599:2014/11イベントB2コース、Cクエスト
      600 => [:quest_no_clear_check, 5,false],                                                                                                  # 600:2014/11イベントB2コース、Aクエスト
      601 => [:quest_no_clear_check, 7,false],                                                                                                  # 601:2014/11イベントB2コース、Aクエスト
      602 => [:quest_no_clear_check, 11,false],                                                                                                 # 602:2014/11イベントB2コース、Aクエスト
      603 => [:quest_no_clear_check, 17,false],                                                                                                 # 603:2014/11イベントB2コース、Aクエスト
      604 => [:quest_no_clear_check, 3,false],                                                                                                  # 604:2014/11イベントCコース、Cクエスト
      605 => [:quest_no_clear_check, 5,false],                                                                                                  # 604:2014/11イベントCコース、Cクエスト
      606 => [:quest_no_clear_check, 7,false],                                                                                                  # 605:2014/11イベントCコース、Cクエスト
      607 => [:quest_no_clear_check, 10,false],                                                                                                 # 607:2014/11イベントCコース、Cクエスト
      608 => [:quest_no_clear_check, 4,false],                                                                                                  # 608:2014/11イベントC1コース、Aクエスト
      609 => [:quest_no_clear_check, 6,false],                                                                                                  # 609:2014/11イベントC1コース、Aクエスト
      610 => [:quest_no_clear_check, 10,false],                                                                                                 # 610:2014/11イベントC1コース、Aクエスト
      611 => [:quest_no_clear_check, 15,false],                                                                                                 # 611:2014/11イベントC1コース、Aクエスト
      612 => [:quest_no_clear_check, 5,false],                                                                                                  # 612:2014/11イベントC1コース、Bクエスト
      613 => [:quest_no_clear_check, 7,false],                                                                                                  # 613:2014/11イベントC1コース、Bクエスト
      614 => [:quest_no_clear_check, 11,false],                                                                                                 # 614:2014/11イベントC1コース、Bクエスト
      615 => [:quest_no_clear_check, 17,false],                                                                                                 # 615:2014/11イベントC1コース、Bクエスト
      616 => [:quest_no_clear_check, 4,false],                                                                                                  # 616:2014/11イベントC2コース、Bクエスト
      617 => [:quest_no_clear_check, 6,false],                                                                                                  # 617:2014/11イベントC2コース、Bクエスト
      618 => [:quest_no_clear_check, 10,false],                                                                                                 # 618:2014/11イベントC2コース、Bクエスト
      619 => [:quest_no_clear_check, 15,false],                                                                                                 # 619:2014/11イベントC2コース、Bクエスト
      620 => [:quest_no_clear_check, 5,false],                                                                                                  # 620:2014/11イベントC2コース、Aクエスト
      621 => [:quest_no_clear_check, 7,false],                                                                                                  # 621:2014/11イベントC2コース、Aクエスト
      622 => [:quest_no_clear_check, 11,false],                                                                                                 # 622:2014/11イベントC2コース、Aクエスト
      623 => [:quest_no_clear_check, 17,false],                                                                                                 # 623:2014/11イベントC2コース、Aクエスト
      624 => [:duel_clear_check, 3,false],                                                                                                      # 624:コスト55限定で3回デュエル ※ループ
      625 => [:duel_clear_check, 1,false],                                                                                                      # 625:コスト75限定で1回デュエル ※ループ
      626 => [:quest_no_clear_check, 100,false],                                                                                                # 626:2014/11イベント　100回クリア
      627 => [:chara_card_check, [[2131,1]],false],                                                                                             # 627:地上へ復活したフリードリヒを入手する
      628 => [:chara_card_check, [[2171,1]],false],                                                                                             # 628:地上へ復活したベリンダを入手する
      629 => [:quest_present_check, 1, false],                                                                                                  # 629:星1クエストをプレゼント
      630 => [:quest_present_check, 1, false],                                                                                                  # 630:星2クエストをプレゼント
      631 => [:quest_present_check, 1, false],                                                                                                  # 631:星3クエストをプレゼント
      632 => [:quest_no_clear_check, 5,false],                                                                                                  # 632:2014/12イベントクエスト5回クリア
      633 => [:quest_no_clear_check, 10,false],                                                                                                 # 633:2014/12イベントクエスト+10回クリア
      634 => [:quest_no_clear_check, 15,false],                                                                                                 # 634:2014/12イベントクエスト+15回クリア
      635 => [:quest_no_clear_check, 20,false],                                                                                                 # 635:2014/12イベントクエスト+20回クリア
      636 => [:quest_no_clear_check, 50,false],                                                                                                 # 636:2014/12イベントクエスト+50回クリア
      637 => [:chara_card_check, [[573,1]],false],                                                                                              # 637:イデリハLv3カードを取得する
      638 => [:duel_clear_check, 3,false],                                                                                                      # 638:デュエルを3回行う
      639 => [:raid_all_damage_check, 100,false],                                                                                               # 639:レイドボスに合計100ダメージを与える
      640 => [:raid_all_damage_check, 1000,false],                                                                                              # 640:レイドボスに合計+1000ダメージを与える
      641 => [:raid_all_damage_check, 2000,false],                                                                                              # 641:レイドボスに合計+2000ダメージを与える
      642 => [:item_num_check, [223,5],true],                                                                                                   # 642:コアの欠片（緑）を5個集める
      643 => [:item_num_check, [223,30],true],                                                                                                  # 643:コアの欠片（緑）を30個集める
      644 => [:item_num_check, [223,70],true],                                                                                                  # 644:コアの欠片（緑）を70個集める
      645 => [:item_num_check, [223,100],true],                                                                                                 # 645:コアの欠片（緑）を100個集める
      646 => [:item_num_check, [223,150],true],                                                                                                 # 646:コアの欠片（緑）を150個集める
      647 => [:chara_card_check, [[583,1]],false],                                                                                              # 647:シラーリーLv3カードを取得する
      648 => [:quest_clear_check, 2003,true],                                                                                                   # 648:アバターのクエストクリア数1以上
      649 => [:quest_clear_check, 2006,true],                                                                                                   # 649:アバターのクエストクリア数1以上
      650 => [:quest_clear_check, 2008,true],                                                                                                   # 650:アバターのクエストクリア数1以上
      651 => [:item_num_check, [130,10],true],                                                                                                  # 651:イベントアイテムを10個集める
      652 => [:item_num_check, [130,20],true],                                                                                                  # 652:イベントアイテムを30個集める
      653 => [:item_num_check, [130,30],true],                                                                                                  # 653:イベントアイテムを50個集める
      654 => [:item_num_check, [130,50],true],                                                                                                  # 654:イベントアイテムを100個集める
      655 => [:item_num_check, [131,10],true],                                                                                                  # 655:イベントアイテムを10個集める
      656 => [:item_num_check, [131,20],true],                                                                                                  # 656:イベントアイテムを30個集める
      657 => [:item_num_check, [131,30],true],                                                                                                  # 657:イベントアイテムを50個集める
      658 => [:item_num_check, [132,10],true],                                                                                                  # 658:イベントアイテムを10個集める
      659 => [:item_num_check, [132,20],true],                                                                                                  # 659:イベントアイテムを30個集める
      660 => [:item_num_check, [132,30],true],                                                                                                  # 660:イベントアイテムを50個集める
      661 => [:chara_card_check, [[593,1]],false],                                                                                              # 661:クロヴィスLv3カードを取得する
      662 => [:item_num_check, [236,5],true],                                                                                                   # 662:イベントアイテムを5個集める
      663 => [:item_num_check, [236,15],true],                                                                                                  # 663:イベントアイテムを15個集める
      664 => [:item_num_check, [236,30],true],                                                                                                  # 664:イベントアイテムを30個集める
      665 => [:item_num_check, [236,50],true],                                                                                                  # 665:イベントアイテムを50個集める
      666 => [:item_num_check, [236,70],true],                                                                                                  # 666:イベントアイテムを70個集める
      667 => [:chara_card_check, [[603,1]],false],                                                                                              # 667:アリステリアLv3カードを取得する
      668 => [:raid_all_damage_check, 300,false],                                                                                               # 668:レイドボスに合計300ダメージを与える
      669 => [:raid_all_damage_check, 700,false],                                                                                               # 669:レイドボスに合計+700ダメージを与える
      670 => [:raid_all_damage_check, 1000,false],                                                                                              # 670:レイドボスに合計+1000ダメージを与える
      671 => [:quest_no_clear_check, 5,false],                                                                                                  # 671:エヴァR SSクエストを5回クリア
      672 => [:quest_no_clear_check, 10,false],                                                                                                 # 672:エヴァR SSクエストを+10回クリア
      673 => [:quest_no_clear_check, 15,false],                                                                                                 # 673:エヴァR SSクエストを+15回クリア
      674 => [:quest_no_clear_check, 20,false],                                                                                                 # 674:エヴァR SSクエストを+20回クリア
      675 => [:quest_no_clear_check, 3,false],                                                                                                  # 675:「バックベアード」を3回倒す
      676 => [:quest_no_clear_check, 5,false],                                                                                                  # 676:「バックベアード」を+5回倒す
      677 => [:quest_no_clear_check, 7,false],                                                                                                  # 677:「バックベアード」を+7回倒す
      678 => [:chara_card_check, [[613,1]],false],                                                                                              # ヒューゴLv3カードを取得する
      679 => [:quest_clear_check, 2009,true],                                                                                                   # 679:地域クリア
      680 => [:quest_clear_check, 2010,true],                                                                                                   # 680:地域クリア
      681 => [:quest_clear_check, 2011,true],                                                                                                   # 681:地域クリア
      682 => [:quest_clear_check, 2012,true],                                                                                                   # 682:地域クリア
      683 => [:quest_clear_check, 2013,true],                                                                                                   # 683:地域クリア
      684 => [:item_num_check, [170,3],true],                                                                                                   # 684:壊れた注射器を3個集める
      685 => [:item_num_check, [170,10],true],                                                                                                  # 685:壊れた注射器を10個集める
      686 => [:item_num_check, [170,20],true],                                                                                                  # 686:壊れた注射器を20個集める
      687 => [:item_num_check, [170,35],true],                                                                                                  # 687:壊れた注射器を35個集める
      688 => [:item_num_check, [170,50],true],                                                                                                  # 688:壊れた注射器を50個集める
      689 => [:invite_count_check,1,false],                                                                                                     # 690:1人招待する
      690 => [:invite_count_check,2,false],                                                                                                     # 691:2人招待する
      691 => [:invite_count_check,3,false],                                                                                                     # 692:3人招待する
      692 => [:invite_count_check,5,false],                                                                                                     # 693:5人招待する
      693 => [:invite_count_check,10,false],                                                                                                    # 694:10人招待する
      694 => [:chara_card_check, [[623,1]],false],                                                                                              # アリアーヌLv3カードを取得する
      696 => [:get_part_check, 1,false],                                                                                                        # 特定パーツを一つ取得する
      697 => [:quest_clear_check, 3001,true],                                                                                                   # 679:地域クリア
      698 => [:quest_clear_check, 3003,true],                                                                                                   # 680:地域クリア
      699 => [:quest_clear_check, 3005,true],                                                                                                   # 681:地域クリア
      700 => [:item_num_check, [352,10],true],                                                                                                  # 651:イベントアイテムを10個集める
      701 => [:quest_no_clear_check, 5,false],                                                                                                  # 671:イベントクエストをクリア
      702 => [:quest_no_clear_check, 10,false],                                                                                                 # 672:イベントクエストをクリア
      703 => [:quest_no_clear_check, 15,false],                                                                                                 # 673:イベントクエストをクリア
      704 => [:chara_card_check, [[633,1]],false],                                                                                              # グレゴールLv3カードを取得する
      705 => [:item_num_check, [353,5],true],                                                                                                   # 705:サンオイルを5個集める
      706 => [:item_num_check, [353,15],true],                                                                                                  # 706:サンオイルを15個集める
      707 => [:item_num_check, [353,30],true],                                                                                                  # 707:サンオイルを30個集める
      708 => [:item_num_check, [353,50],true],                                                                                                  # 708:サンオイルを50個集める
      709 => [:item_num_check, [93,5],true],                                                                                                    # 709:星の砂を5個集める
      710 => [:item_num_check, [93,15],true],                                                                                                   # 710:星の砂を15個集める
      711 => [:item_num_check, [93,30],true],                                                                                                   # 711:星の砂を30個集める
      712 => [:item_num_check, [93,50],true],                                                                                                   # 712:星の砂を50個集める
      713 => [:duel_clear_check, 4,false],                                                                                                      # 713:アレクサンドル、またはコスト限定チャンネルで4回デュエルを行う
      714 => [:duel_clear_check, 6,false],                                                                                                      # 714:アレクサンドル、またはコスト限定チャンネルで+6回デュエルを行う
      715 => [:duel_clear_check, 9,false],                                                                                                      # 715:アレクサンドル、またはコスト限定チャンネルで+9回デュエルを行う
      716 => [:duel_clear_check, 11,false],                                                                                                     # 716:アレクサンドル、またはコスト限定チャンネルで+11回デュエルを行う 714~716 setloop
      717 => [:chara_card_check, [[643,1]],false],                                                                                              # レタLv3カードを取得する
      718 => [:quest_no_clear_check, 2, false],                                                                                                 # 718:2015/08イベントAコース、Aクエスト
      719 => [:item_num_check, [354,5], true],                                                                                                  # 719:2015/08イベントAコース、アイテム5個
      720 => [:item_num_check, [354,15], true],                                                                                                 # 720:2015/08イベントAコース、アイテム15個
      721 => [:item_num_check, [354,30], true],                                                                                                 # 721:2015/08イベントAコース、アイテム30個
      722 => [:quest_no_clear_check, 2, false],                                                                                                 # 722:2015/08イベントA1コース、Bクエスト
      723 => [:item_num_check, [354,50], true],                                                                                                 # 723:2015/08イベントA1コース、アイテム50個
      724 => [:item_num_check, [354,70], true],                                                                                                 # 724:2015/08イベントA1コース、アイテム70個
      725 => [:item_num_check, [354,90], true],                                                                                                 # 725:2015/08イベントA1コース、アイテム90個
      726 => [:quest_no_clear_check, 2, false],                                                                                                 # 726:2015/08イベントA1コース、Cクエスト
      727 => [:item_num_check, [354,120], true],                                                                                                # 727:2015/08イベントA1コース、アイテム120個
      728 => [:item_num_check, [354,150], true],                                                                                                # 728:2015/08イベントA1コース、アイテム150個
      729 => [:item_num_check, [354,180], true],                                                                                                # 729:2015/08イベントA1コース、アイテム180個
      730 => [:quest_no_clear_check, 2, false],                                                                                                 # 730:2015/08イベントA2コース、Cクエスト
      731 => [:item_num_check, [354,50], true],                                                                                                 # 731:2015/08イベントA2コース、アイテム50個
      732 => [:item_num_check, [354,70], true],                                                                                                 # 732:2015/08イベントA2コース、アイテム70個
      733 => [:item_num_check, [354,90], true],                                                                                                 # 733:2015/08イベントA2コース、アイテム90個
      734 => [:quest_no_clear_check, 2, false],                                                                                                 # 734:2015/08イベントA2コース、Bクエスト
      735 => [:item_num_check, [354,120], true],                                                                                                # 735:2015/08イベントA2コース、アイテム120個
      736 => [:item_num_check, [354,150], true],                                                                                                # 736:2015/08イベントA2コース、アイテム150個
      737 => [:item_num_check, [354,180], true],                                                                                                # 737:2015/08イベントA2コース、アイテム180個
      738 => [:quest_no_clear_check, 2, false],                                                                                                 # 738:2015/08イベントBコース、Bクエスト
      739 => [:item_num_check, [354,5], true],                                                                                                  # 739:2015/08イベントBコース、アイテム5個
      740 => [:item_num_check, [354,15], true],                                                                                                 # 740:2015/08イベントBコース、アイテム15個
      741 => [:item_num_check, [354,30], true],                                                                                                 # 741:2015/08イベントBコース、アイテム30個
      742 => [:quest_no_clear_check, 2, false],                                                                                                 # 742:2015/08イベントB1コース、Aクエスト
      743 => [:item_num_check, [354,50], true],                                                                                                 # 743:2015/08イベントB1コース、アイテム50個
      744 => [:item_num_check, [354,70], true],                                                                                                 # 744:2015/08イベントB1コース、アイテム70個
      745 => [:item_num_check, [354,90], true],                                                                                                 # 745:2015/08イベントB1コース、アイテム90個
      746 => [:quest_no_clear_check, 2, false],                                                                                                 # 746:2015/08イベントB1コース、Cクエスト
      747 => [:item_num_check, [354,120], true],                                                                                                # 747:2015/08イベントB1コース、アイテム120個
      748 => [:item_num_check, [354,150], true],                                                                                                # 748:2015/08イベントB1コース、アイテム150個
      749 => [:item_num_check, [354,180], true],                                                                                                # 749:2015/08イベントB1コース、アイテム180個
      750 => [:quest_no_clear_check, 2, false],                                                                                                 # 750:2015/08イベントB2コース、Cクエスト
      751 => [:item_num_check, [354,50], true],                                                                                                 # 751:2015/08イベントB2コース、アイテム50個
      752 => [:item_num_check, [354,70], true],                                                                                                 # 752:2015/08イベントB2コース、アイテム70個
      753 => [:item_num_check, [354,90], true],                                                                                                 # 753:2015/08イベントB2コース、アイテム90個
      754 => [:quest_no_clear_check, 2, false],                                                                                                 # 754:2015/08イベントB2コース、Aクエスト
      755 => [:item_num_check, [354,120], true],                                                                                                # 755:2015/08イベントB2コース、アイテム120個
      756 => [:item_num_check, [354,150], true],                                                                                                # 756:2015/08イベントB2コース、アイテム150個
      757 => [:item_num_check, [354,180], true],                                                                                                # 757:2015/08イベントB2コース、アイテム180個
      758 => [:quest_no_clear_check, 2, false],                                                                                                 # 758:2015/08イベントCコース、Cクエスト
      759 => [:item_num_check, [354,5], true],                                                                                                  # 759:2015/08イベントCコース、アイテム5個
      760 => [:item_num_check, [354,15], true],                                                                                                 # 760:2015/08イベントCコース、アイテム15個
      761 => [:item_num_check, [354,30], true],                                                                                                 # 761:2015/08イベントCコース、アイテム30個
      762 => [:quest_no_clear_check, 2, false],                                                                                                 # 762:2015/08イベントC1コース、Aクエスト
      763 => [:item_num_check, [354,50], true],                                                                                                 # 763:2015/08イベントC1コース、アイテム50個
      764 => [:item_num_check, [354,70], true],                                                                                                 # 764:2015/08イベントC1コース、アイテム70個
      765 => [:item_num_check, [354,90], true],                                                                                                 # 765:2015/08イベントC1コース、アイテム90個
      766 => [:quest_no_clear_check, 2, false],                                                                                                 # 766:2015/08イベントC1コース、Bクエスト
      767 => [:item_num_check, [354,120], true],                                                                                                # 767:2015/08イベントC1コース、アイテム120個
      768 => [:item_num_check, [354,150], true],                                                                                                # 768:2015/08イベントC1コース、アイテム150個
      769 => [:item_num_check, [354,180], true],                                                                                                # 769:2015/08イベントC1コース、アイテム180個
      770 => [:quest_no_clear_check, 2, false],                                                                                                 # 770:2015/08イベントC2コース、Bクエスト
      771 => [:item_num_check, [354,50], true],                                                                                                 # 771:2015/08イベントC2コース、アイテム50個
      772 => [:item_num_check, [354,70], true],                                                                                                 # 772:2015/08イベントC2コース、アイテム70個
      773 => [:item_num_check, [354,90], true],                                                                                                 # 773:2015/08イベントC2コース、アイテム90個
      774 => [:quest_no_clear_check, 2, false],                                                                                                 # 774:2015/08イベントC2コース、Aクエスト
      775 => [:item_num_check, [354,120], true],                                                                                                # 775:2015/08イベントC2コース、アイテム120個
      776 => [:item_num_check, [354,150], true],                                                                                                # 776:2015/08イベントC2コース、アイテム150個
      777 => [:item_num_check, [354,180], true],                                                                                                # 777:2015/08イベントC2コース、アイテム180個
      778 => [:raid_all_damage_check, 100, false],                                                                                              # 778:レイドボスに合計100ダメージを与える
      779 => [:raid_all_damage_check, 400, false],                                                                                              # 779:レイドボスに合計+400ダメージを与える
      780 => [:raid_all_damage_check, 1500, false],                                                                                             # 780:レイドボスに合計+1500ダメージを与える
      781 => [:daily_record_clear_check, 1, false],                                                                                             # 781:日間クエストレコードとデュエルレコードを両方クリアする
      782 => [:other_raid_btl_cnt, 1, false],                                                                                                   # 782:他人の渦戦に参加する
      783 => [:raid_all_damage_check, 1, false],                                                                                                # 783:レイドボスにダメージを与える
      784 => [:use_item_check, 1, false],                                                                                                       # 784:イベント渦発見アイテムを使用する
      785 => [:self_raid_claer_check, 1, false],                                                                                                # 785:自分で発見した渦の討伐に成功する
      786 => [:chara_card_check, [[2141,1]],false],                                                                                             # 復活マルグリッドカードを取得する
      787 => [:chara_card_check, [[2181,1]],false],                                                                                             # 復活ロッソカードを取得する
      788 => [:quest_no_clear_check, 2, false],                                                                                                 # 788:人気投票イベントクエストレコード1
      789 => [:quest_no_clear_check, 2, false],                                                                                                 # 789:人気投票イベントクエストレコード2
      790 => [:quest_no_clear_check, 2, false],                                                                                                 # 790:人気投票イベントクエストレコード3
      791 => [:quest_no_clear_check, 2, false],                                                                                                 # 791:人気投票イベントクエストレコード4
      792 => [:quest_no_clear_check, 2, false],                                                                                                 # 792:人気投票イベントクエストレコード5
      793 => [:quest_no_clear_check, 2, false],                                                                                                 # 793:人気投票イベントクエストレコード6
      794 => [:quest_no_clear_check, 2, false],                                                                                                 # 794:人気投票イベントクエストレコード7
      795 => [:quest_no_clear_check, 2, false],                                                                                                 # 795:人気投票イベントクエストレコード8
      796 => [:quest_no_clear_check, 2, false],                                                                                                 # 796:人気投票イベントクエストレコード9
      797 => [:quest_no_clear_check, 2, false],                                                                                                 # 797:人気投票イベントクエストレコード10
      798 => [:event_point_check, 99999 ,false],                                                                                                # 798:人気投票イベントポイント加算レコード1
      799 => [:event_point_check, 99999 ,false],                                                                                                # 799:人気投票イベントポイント加算レコード2
      800 => [:event_point_check, 99999 ,false],                                                                                                # 800:人気投票イベントポイント加算レコード3
      801 => [:event_point_check, 99999 ,false],                                                                                                # 801:人気投票イベントポイント加算レコード4
      802 => [:event_point_check, 99999 ,false],                                                                                                # 802:人気投票イベントポイント加算レコード5
      803 => [:event_point_check, 99999 ,false],                                                                                                # 803:人気投票イベントポイント加算レコード6
      804 => [:event_point_check, 99999 ,false],                                                                                                # 804:人気投票イベントポイント加算レコード7
      805 => [:event_point_check, 99999 ,false],                                                                                                # 805:人気投票イベントポイント加算レコード8
      806 => [:event_point_check, 99999 ,false],                                                                                                # 806:人気投票イベントポイント加算レコード9
      807 => [:event_point_check, 99999 ,false],                                                                                                # 807:人気投票イベントポイント加算レコード10
      808 => [:item_num_check, [371,10], true],                                                                                                 # 808 かえるの置物を10個集める
      809 => [:item_num_check, [371,20], true],                                                                                                 # 809 かえるの置物を20集める
      810 => [:item_num_check, [371,30], true],                                                                                                 # 810 かえるの置物を30集める
      811 => [:item_num_check, [372,20], true],                                                                                                 # 811 バンテージを20集める
      812 => [:item_num_check, [372,40], true],                                                                                                 # 812 バンテージを40集める
      813 => [:item_num_check, [372,70], true],                                                                                                 # 813 バンテージを70集める
      814 => [:item_num_check, [372,100], true],                                                                                                # 814 バンテージを100個集める
      815 => [:item_num_check, [372,10], true],                                                                                                 # 815 バンテージを10個集める
      816 => [:item_num_check, [372,20], true],                                                                                                 # 816 バンテージを20集める
      817 => [:item_num_check, [372,30], true],                                                                                                 # 817 バンテージを30集める
      818 => [:item_num_check, [371,20], true],                                                                                                 # 818 かえるの置物を20集める
      819 => [:item_num_check, [371,40], true],                                                                                                 # 819 かえるの置物を40集める
      820 => [:item_num_check, [371,70], true],                                                                                                 # 820 かえるの置物を70集める
      821 => [:item_num_check, [371,100], true],                                                                                                # 821 かえるの置物を100個集める
      822 => [:other_duel_cnt_check, 3, false],                                                                                                 # 822:3人とデュエルをする
      823 => [:other_duel_cnt_check, 5, false],                                                                                                 # 823:5人とデュエルをする
      824 => [:other_duel_cnt_check, 10, false],                                                                                                # 824:10人とデュエルをする
      825 => [:other_duel_cnt_check, 15, false],                                                                                                # 825:15人とデュエルをする
      826 => [:chara_card_check, [[653,1]],false],                                                                                              # エプシロンLv3カードを取得する
      827 => [:quest_clear_check, 3006,true],                                                                                                   # 827:地域1クリア
      828 => [:quest_clear_check, 3007,true],                                                                                                   # 828:地域2クリア
      829 => [:quest_clear_check, 3008,true],                                                                                                   # 829:地域3クリア
      830 => [:quest_clear_check, 3009,true],                                                                                                   # 830:地域4クリア
      831 => [:quest_clear_check, 3010,true],                                                                                                   # 831:地域5クリア
      832 => [:item_num_check, [373,5],true],                                                                                                   # 832:弱ボス撃破アイテム3個取得
      833 => [:item_num_check, [374,5],true],                                                                                                   # 833:中ボス撃破アイテム3個取得
      834 => [:item_num_check, [375,15],true],                                                                                                  # 834:強ボス撃破アイテム10個取得
      835 => [:quest_no_clear_check, 50, false],                                                                                                # 835 ボスクエストクリア
      836 => [:chara_card_check, [[663,1]],false],                                                                                              # ポレットLv3カードを取得する
      837 => [:item_num_check, [377,10], true],                                                                                                 # 837:201511イベントアイテムAを10個集める
      838 => [:item_num_check, [377,40], true],                                                                                                 # 838:201511イベントアイテムAを40個集める
      839 => [:item_num_check, [377,80], true],                                                                                                 # 839:201511イベントアイテムAを80個集める
      840 => [:item_num_check, [377,120], true],                                                                                                # 840:201511イベントアイテムAを120個集める
      841 => [:item_num_check, [377,200], true],                                                                                                # 841:201511イベントアイテムAを200個集める
      842 => [:item_num_check, [378,5], true],                                                                                                  # 842:201511イベントアイテムBを5個集める
      843 => [:item_num_check, [378,20], true],                                                                                                 # 843:201511イベントアイテムBを20個集める
      844 => [:item_num_check, [378,40], true],                                                                                                 # 844:201511イベントアイテムBを40個集める
      845 => [:item_num_check, [378,60], true],                                                                                                 # 845:201511イベントアイテムBを60個集める
      846 => [:item_num_check, [378,100], true],                                                                                                # 846:201511イベントアイテムBを100個集める
      847 => [:raid_all_damage_check, 100, false],                                                                                              # 847:レイドボスに合計100ダメージを与える
      848 => [:raid_all_damage_check, 400, false],                                                                                              # 848:レイドボスに合計+400ダメージを与える
      849 => [:raid_all_damage_check, 1500, false],                                                                                             # 849:レイドボスに合計+1500ダメージを与える
      850 => [:chara_card_check, [[673,1]],false],                                                                                              # ユハニLv3カードを取得する
      851 => [:item_full_num_check, [379,3], false],                                                                                            # 851:201512イベントアイテムAを3個集める
      852 => [:item_full_num_check, [379,10], false],                                                                                           # 852:201512イベントアイテムAを10個集める
      853 => [:item_full_num_check, [379,20], false],                                                                                           # 853:201512イベントアイテムAを20個集める
      854 => [:item_full_num_check, [379,30], false],                                                                                           # 854:201512イベントアイテムAを30個集める
      855 => [:item_full_num_check, [379,50], false],                                                                                           # 855:201512イベントアイテムAを50個集める
      856 => [:item_num_check, [380,5], true],                                                                                                  # 856:201512イベントアイテムBを5個集める
      857 => [:item_num_check, [380,20], true],                                                                                                 # 856:201512イベントアイテムBを20個集める
      858 => [:item_num_check, [380,40], true],                                                                                                 # 856:201512イベントアイテムBを40個集める
      859 => [:item_num_check, [380,60], true],                                                                                                 # 856:201512イベントアイテムBを60個集める
      860 => [:get_part_check, 1,false],                                                                                                        # 特定パーツを一つ取得する
      861 => [:get_part_check, 1,false],                                                                                                        # 特定パーツを一つ取得する
      862 => [:chara_card_check, [[683,1]],false],                                                                                              # ノーラLv3カードを取得する
      863 => [:quest_no_clear_check, 3, false],                                                                                                 # 863:イベントクエストを3回クリア
      864 => [:quest_no_clear_check, 7, false],                                                                                                 # 864:イベントクエストを+7回クリア
      865 => [:quest_no_clear_check, 10, false],                                                                                                # 865:イベントクエストを+10回クリア
      866 => [:quest_no_clear_check, 15, false],                                                                                                # 866:イベントクエストを+15回クリア
      867 => [:quest_no_clear_check, 25, false],                                                                                                # 867:イベントクエストを+25回クリア
      868 => [:item_num_check, [383,1], true],                                                                                                  # 868:201601イベントアイテムBを1個集める
      869 => [:item_num_check, [383,5], true],                                                                                                  # 869:201601イベントアイテムBを5個集める
      870 => [:item_num_check, [383,30], true],                                                                                                 # 870:201601イベントアイテムBを30個集める
      871 => [:item_num_check, [383,50], true],                                                                                                 # 871:201601イベントアイテムBを50個集める
      872 => [:item_num_check, [383,70], true],                                                                                                 # 872:201601イベントアイテムBを70個集める
      873 => [:daily_record_clear_check, 1, false],                                                                                             # 873:日間クエストレコードとデュエルレコードを両方クリアする
      874 => [:chara_card_check, [[693,1]],false],                                                                                              # ラウルLv3カードを取得する
      875 => [:item_num_check, [384,5], true],                                                                                                  # 875:カカオを5個集める
      876 => [:item_num_check, [384,10], true],                                                                                                 # 876:カカオを10個集める
      877 => [:item_num_check, [384,20], true],                                                                                                 # 877:カカオを20個集める
      878 => [:item_num_check, [384,30], true],                                                                                                 # 878:カカオを30個集める
      879 => [:item_num_check, [384,50], true],                                                                                                 # 879:カカオを50個集める
      880 => [:item_num_check, [384,100], true],                                                                                                # 880:カカオを100個集める
      881 => [:item_num_check, [384,150], true],                                                                                                # 881:カカオを150個集める
      882 => [:item_num_check, [384,200], true],                                                                                                # 882:カカオを200個集める
      883 => [:item_num_check, [385,5], true],                                                                                                  # 883:完熟カカオを5個集める
      884 => [:item_num_check, [385,10], true],                                                                                                 # 884:完熟カカオを10個集める
      885 => [:item_num_check, [385,20], true],                                                                                                 # 885:完熟カカオを20個集める
      886 => [:item_num_check, [385,30], true],                                                                                                 # 886:完熟カカオを30個集める
      887 => [:item_num_check, [385,60], true],                                                                                                 # 887:完熟カカオを60個集める
      888 => [:item_num_check, [385,80], true],                                                                                                 # 888:完熟カカオを80個集める
      889 => [:item_num_check, [385,130], true],                                                                                                # 889:完熟カカオを130個集める
      890 => [:raid_all_damage_check, 100, false],                                                                                              # 890:レイドボスに合計100ダメージを与える
      891 => [:raid_all_damage_check, 400, false],                                                                                              # 891:レイドボスに合計+400ダメージを与える
      892 => [:raid_all_damage_check, 1500, false],                                                                                             # 892:レイドボスに合計+1500ダメージを与える
      893 => [:chara_card_check, [[703,1]],false],                                                                                              # ジェミーLv3カードを取得する
      894 => [:item_num_check, [386,5], true],                                                                                                  # 894:201603イベントアイテムを5個集める
      895 => [:item_num_check, [386,10], true],                                                                                                 # 895:201603イベントアイテムを10個集める
      896 => [:item_num_check, [386,20], true],                                                                                                 # 896:201603イベントアイテムを20個集める
      897 => [:item_num_check, [386,30], true],                                                                                                 # 897:201603イベントアイテムを30個集める
      898 => [:item_num_check, [386,40], true],                                                                                                 # 898:201603イベントアイテムを40個集める
      899 => [:item_num_check, [386,50], true],                                                                                                 # 899:201603イベントアイテムを50個集める
      900 => [:item_num_check, [386,60], true],                                                                                                 # 900:201603イベントアイテムを60個集める
      901 => [:item_num_check, [386,70], true],                                                                                                 # 901:201603イベントアイテムを70個集める
      902 => [:item_num_check, [386,80], true],                                                                                                 # 902:201603イベントアイテムを80個集める
      903 => [:item_num_check, [386,90], true],                                                                                                 # 903:201603イベントアイテムを90個集める
      904 => [:item_num_check, [386,100], true],                                                                                                # 904:201603イベントアイテムを100個集める
      905 => [:item_num_check, [386,110], true],                                                                                                # 905:201603イベントアイテムを110個集める
      906 => [:item_num_check, [386,120], true],                                                                                                # 906:201603イベントアイテムを120個集める
      907 => [:item_num_check, [386,130], true],                                                                                                # 907:201603イベントアイテムを130個集める
      908 => [:item_num_check, [386,140], true],                                                                                                # 908:201603イベントアイテムを140個集める
      909 => [:item_num_check, [386,150], true],                                                                                                # 909:201603イベントアイテムを150個集める
      910 => [:item_num_check, [386,160], true],                                                                                                # 910:201603イベントアイテムを160個集める
      911 => [:item_num_check, [386,170], true],                                                                                                # 911:201603イベントアイテムを170個集める
      912 => [:item_num_check, [386,180], true],                                                                                                # 912:201603イベントアイテムを180個集める
      913 => [:item_num_check, [386,190], true],                                                                                                # 913:201603イベントアイテムを190個集める
      914 => [:item_num_check, [386,200], true],                                                                                                # 914:201603イベントアイテムを200個集める
      915 => [:item_num_check, [386,210], true],                                                                                                # 915:201603イベントアイテムを210個集める
      916 => [:item_num_check, [386,220], true],                                                                                                # 916:201603イベントアイテムを220個集める
      917 => [:item_num_check, [386,230], true],                                                                                                # 917:201603イベントアイテムを230個集める
      918 => [:item_num_check, [386,240], true],                                                                                                # 918:201603イベントアイテムを240個集める
      919 => [:item_num_check, [386,250], true],                                                                                                # 919:201603イベントアイテムを250個集める
      920 => [:item_num_check, [386,260], true],                                                                                                # 920:201603イベントアイテムを260個集める
      921 => [:item_num_check, [386,270], true],                                                                                                # 921:201603イベントアイテムを270個集める
      922 => [:item_num_check, [386,280], true],                                                                                                # 922:201603イベントアイテムを280個集める
      923 => [:item_num_check, [386,290], true],                                                                                                # 923:201603イベントアイテムを290個集める
      924 => [:item_num_check, [386,300], true],                                                                                                # 924:201603イベントアイテムを300個集める
      925 => [:daily_record_clear_check, 1, false],                                                                                             # 925:日間クエストレコードとデュエルレコードを両方クリアする
      926 => [:item_num_check, [386,310], true],                                                                                                # 926:201603イベントアイテムを310個集める
      927 => [:item_num_check, [386,320], true],                                                                                                # 927:201603イベントアイテムを320個集める
      928 => [:item_num_check, [386,330], true],                                                                                                # 928:201603イベントアイテムを330個集める
      929 => [:item_num_check, [386,340], true],                                                                                                # 929:201603イベントアイテムを340個集める
      930 => [:item_num_check, [386,350], true],                                                                                                # 930:201603イベントアイテムを350個集める
      931 => [:item_num_check, [386,360], true],                                                                                                # 931:201603イベントアイテムを360個集める
      932 => [:item_num_check, [386,370], true],                                                                                                # 932:201603イベントアイテムを370個集める
      933 => [:item_num_check, [386,380], true],                                                                                                # 933:201603イベントアイテムを380個集める
      934 => [:item_num_check, [386,390], true],                                                                                                # 934:201603イベントアイテムを390個集める
      935 => [:item_num_check, [386,400], true],                                                                                                # 935:201603イベントアイテムを400個集める
      936 => [:duel_clear_check, 5,false],                                                                                                      # 936:5回デュエルする
      937 => [:duel_clear_check, 5,false],                                                                                                      # 937:+5回デュエルする
      938 => [:duel_clear_check, 5,false],                                                                                                      # 938:+5回デュエルする
      939 => [:duel_clear_check, 5,false],                                                                                                      # 939:+5回デュエルする
      940 => [:duel_clear_check, 5,false],                                                                                                      # 940:+5回デュエルする
      941 => [:duel_clear_check, 5,false],                                                                                                      # 941:+5回デュエルする
      942 => [:duel_clear_check, 3,false],                                                                                                      # 942:3回デュエルする(デイリー) 201604マーケ用
      943 => [:self_raid_claer_check, 3, false],                                                                                                # 943:自分で発見した渦の討伐に成功する
      944 => [:chara_card_check, [[713,1]],false],                                                                                              # セルファースLv3カードを取得する
      945 => [:quest_clear_check, 3012,true],                                                                                                   # 845:201604イベント地域1クリア
      946 => [:quest_clear_check, 3013,true],                                                                                                   # 846:201604イベント地域2クリア
      947 => [:quest_clear_check, 3014,true],                                                                                                   # 847:201604イベント地域3クリア
      948 => [:quest_clear_check, 3015,true],                                                                                                   # 848:201604イベント地域4クリア
      949 => [:quest_clear_check, 3016,true],                                                                                                   # 849:201604イベント地域5クリア
      950 => [:item_num_check, [388,15], true],                                                                                                 # 950:201604イベントアイテム1を15個集める
      951 => [:item_num_check, [389,15], true],                                                                                                 # 951:201604イベントアイテム2を15個集める
      952 => [:item_num_check, [390,15], true],                                                                                                 # 952:201604イベントアイテム3を15個集める
      953 => [:item_num_check, [388,30], true],                                                                                                 # 953:201604イベントアイテム1を30個集める
      954 => [:item_num_check, [389,30], true],                                                                                                 # 954:201604イベントアイテム2を30個集める
      955 => [:item_num_check, [390,30], true],                                                                                                 # 955:201604イベントアイテム3を30個集める
      956 => [:quest_no_clear_check, 1, false],                                                                                                 # 956:特定クエストをクリア
      957 => [:quest_no_clear_check, 1, false],                                                                                                 # 957:特定クエストをクリア
      958 => [:quest_no_clear_check, 1, false],                                                                                                 # 958:特定クエストをクリア
      959 => [:chara_card_check, [[723,1]],false],                                                                                              # フィフスLv3カードを取得する
      960 => [:item_num_check, [392,5], true],                                                                                                  # 960:201605イベントアイテムBを5個集める
      961 => [:item_num_check, [392,10], true],                                                                                                 # 961:201605イベントアイテムBを10個集める
      962 => [:item_num_check, [392,15], true],                                                                                                 # 962:201605イベントアイテムBを15個集める
      963 => [:item_num_check, [392,20], true],                                                                                                 # 963:201605イベントアイテムBを20個集める
      964 => [:item_num_check, [392,25], true],                                                                                                 # 964:201605イベントアイテムBを25個集める
      965 => [:item_num_check, [392,40], true],                                                                                                 # 965:201605イベントアイテムBを40個集める
      966 => [:item_num_check, [392,50], true],                                                                                                 # 966:201605イベントアイテムBを50個集める
      967 => [:item_num_check, [392,60], true],                                                                                                 # 967:201605イベントアイテムBを60個集める
      968 => [:item_num_check, [392,70], true],                                                                                                 # 968:201605イベントアイテムBを70個集める
      969 => [:item_num_check, [392,80], true],                                                                                                 # 969:201605イベントアイテムBを80個集める
      970 => [:item_num_check, [392,90], true],                                                                                                 # 970:201605イベントアイテムBを90個集める
      971 => [:item_num_check, [392,100], true],                                                                                                # 971:201605イベントアイテムBを100個集める
      972 => [:item_num_check, [392,120], true],                                                                                                # 972:201605イベントアイテムBを120個集める
      973 => [:chara_card_check, [[733,1]],false],                                                                                              # リカルドLv3カードを取得する
      974 => [:item_num_check, [393,30], true],                                                                                                 # 974:ちまきを30個集める
      975 => [:item_num_check, [393,40], true],                                                                                                 # 975:ちまきを40個集める
      976 => [:item_num_check, [393,70], true],                                                                                                 # 976:ちまきを70個集める
      977 => [:item_num_check, [393,100], true],                                                                                                # 977:ちまきを100個集める
      978 => [:item_num_check, [393,200], true],                                                                                                # 978:ちまきを200個集める
      979 => [:item_num_check, [393,250], true],                                                                                                # 979:ちまきを250個集める
      980 => [:item_num_check, [393,300], true],                                                                                                # 980:ちまきを300個集める
      981 => [:item_num_check, [393,350], true],                                                                                                # 981:ちまきを350個集める
      982 => [:item_num_check, [393,500], true],                                                                                                # 982:ちまきを500個集める
      983 => [:duel_clear_check, 1,false],                                                                                                      # 983:1回デュエルする(デイリー)
      984 => [:use_item_check, 1, false],                                                                                                       # 984:イベント渦発見アイテムを使用する
      985 => [:self_raid_claer_check, 1, false],                                                                                                # 985:自分で発見した渦の討伐に成功する
      986 => [:raid_all_damage_check, 1500, false],                                                                                             # 986:レイドボスに合計1500ダメージを与える
      987 => [:chara_card_check, [[743,1]],false],                                                                                              # マリネラLv3カードを取得する
      988 => [:quest_clear_check, 3017,true],                                                                                                   # 988:イベント地域1をクリア
      989 => [:quest_clear_check, 3018,true],                                                                                                   # 989:イベント地域2をクリア
      990 => [:quest_clear_check, 3019,true],                                                                                                   # 990:イベント地域3をクリア
      991 => [:quest_clear_check, 3020,true],                                                                                                   # 991:イベント地域4をクリア
      992 => [:quest_clear_check, 3021,true],                                                                                                   # 992:イベント地域5をクリア
      993 => [:item_num_check, [394,15], true],                                                                                                 # 993:イベントアイテムAを15個集める
      994 => [:item_num_check, [395,15], true],                                                                                                 # 994:イベントアイテムBを15個集める
      995 => [:item_num_check, [396,15], true],                                                                                                 # 995:イベントアイテムCを15個集める
      996 => [:item_num_check, [394,30], true],                                                                                                 # 996:イベントアイテムAを30個集める
      997 => [:item_num_check, [395,30], true],                                                                                                 # 997:イベントアイテムBを30個集める
      998 => [:item_num_check, [396,30], true],                                                                                                 # 998:イベントアイテムCを30個集める
      999 => [:chara_card_check, [[753,1]],false],                                                                                              # モーガンLv3カードを取得する
      1000 => [:duel_clear_check, 3,false],                                                                                                     # 1000:3vs3デュエルを3回行う
      1001 => [:duel_clear_check, 1,false],                                                                                                     # 1001:コスト限定チャンネルでデュエルを行う
      1002 => [:duel_clear_check, 1,false],                                                                                                     # 1002:アレクサンドルでデュエルを行う
      1003 => [:item_calc_check, [[397,398,399],30],true],                                                                                      # 1003:イベントアイテムを30個集める
      1004 => [:item_calc_check, [[397,398,399],50],true],                                                                                      # 1004:イベントアイテムを50個集める
      1005 => [:item_calc_check, [[397,398,399],100],true],                                                                                     # 1005:イベントアイテムを100個集める
      1006 => [:item_calc_check, [[397,398,399],150],true],                                                                                     # 1006:イベントアイテムを150個集める
      1007 => [:item_calc_check, [[397,398,399],200],true],                                                                                     # 1007:イベントアイテムを200個集める
      1008 => [:item_num_check, [397,3],true],                                                                                                  # 1008:イベントアイテムAを3個集める
      1009 => [:item_num_check, [399,3],true],                                                                                                  # 1009:イベントアイテムCを3個集める
      1010 => [:item_num_check, [397,10],true],                                                                                                 # 1010:イベントアイテムAを10個集める
      1011 => [:item_num_check, [397,20],true],                                                                                                 # 1011:イベントアイテムAを20個集める
      1012 => [:item_num_check, [397,30],true],                                                                                                 # 1012:イベントアイテムAを30個集める
      1013 => [:item_set_calc_check, [[398,399],10],true],                                                                                      # 1013:イベントアイテムB・Cを10個ずつ集める
      1014 => [:item_set_calc_check, [[398,399],20],true],                                                                                      # 1014:イベントアイテムB・Cを20個ずつ集める
      1015 => [:item_set_calc_check, [[398,399],30],true],                                                                                      # 1015:イベントアイテムB・Cを30個ずつ集める
      1016 => [:item_set_calc_check, [[397,398,399],40],true],                                                                                  # 1016:イベントアイテムA・B・Cを40個ずつ集める
      1017 => [:item_set_calc_check, [[397,398,399],50],true],                                                                                  # 1017:イベントアイテムA・B・Cを50個ずつ集める
      1018 => [:item_set_calc_check, [[397,398,399],60],true],                                                                                  # 1018:イベントアイテムA・B・Cを60個ずつ集める
      1019 => [:item_num_check, [398,3],true],                                                                                                  # 1019:イベントアイテムBを3個集める
      1020 => [:item_num_check, [399,3],true],                                                                                                  # 1020:イベントアイテムCを3個集める
      1021 => [:item_num_check, [398,10],true],                                                                                                 # 1021:イベントアイテムBを10個集める
      1022 => [:item_num_check, [398,20],true],                                                                                                 # 1022:イベントアイテムBを20個集める
      1023 => [:item_num_check, [398,30],true],                                                                                                 # 1023:イベントアイテムBを30個集める
      1024 => [:item_set_calc_check, [[397,399],10],true],                                                                                      # 1024:イベントアイテムA・Cを10個ずつ集める
      1025 => [:item_set_calc_check, [[397,399],20],true],                                                                                      # 1025:イベントアイテムA・Cを20個ずつ集める
      1026 => [:item_set_calc_check, [[397,399],30],true],                                                                                      # 1026:イベントアイテムA・Cを30個ずつ集める
      1027 => [:item_set_calc_check, [[397,398,399],40],true],                                                                                  # 1027:イベントアイテムA・B・Cを40個ずつ集める
      1028 => [:item_set_calc_check, [[397,398,399],50],true],                                                                                  # 1028:イベントアイテムA・B・Cを50個ずつ集める
      1029 => [:item_set_calc_check, [[397,398,399],60],true],                                                                                  # 1029:イベントアイテムA・B・Cを60個ずつ集める
      1030 => [:chara_card_check, [[763,1]],false],                                                                                             # ジュディスLv3カードを取得する
      1031 => [:raid_btl_cnt, 1,false],                                                                                                         # 1031:レイド戦に参戦する
      1032 => [:item_later_num_check, [400,10],true],                                                                                           # 1032:新たに月長石10個集める
      1033 => [:item_num_check, [400,15],true],                                                                                                 # 1033:月長石を15個集める
      1034 => [:item_num_check, [400,30],true],                                                                                                 # 1034:月長石を30個集める
      1035 => [:item_num_check, [400,70],true],                                                                                                 # 1035:月長石を70個集める
      1036 => [:item_num_check, [400,100],true],                                                                                                # 1036:月長石を100個集める
      1037 => [:item_num_check, [400,250],true],                                                                                                # 1037:月長石を250個集める
      1038 => [:item_num_check, [400,300],true],                                                                                                # 1038:月長石を300個集める
      1039 => [:item_num_check, [400,350],true],                                                                                                # 1039:月長石を350個集める
      1040 => [:item_num_check, [400,500],true],                                                                                                # 1040:月長石を500個集める
      1041 => [:chara_card_check, [[2231,1]],false],                                                                                            # 復活リーズカードを取得する
      1042 => [:quest_clear_check, 3022,true],                                                                                                  # 1042:201610イベント地域1をクリア
      1043 => [:quest_clear_check, 3023,true],                                                                                                  # 1043:201610イベント地域2をクリア
      1044 => [:quest_clear_check, 3024,true],                                                                                                  # 1044:201610イベント地域3をクリア
      1045 => [:quest_clear_check, 3025,true],                                                                                                  # 1045:201610イベント地域4をクリア
      1046 => [:quest_clear_check, 3026,true],                                                                                                  # 1046:201610イベント地域5をクリア
      1047 => [:quest_no_clear_check, 1, false],                                                                                                # 1047:特定クエストをクリア
      1048 => [:quest_no_clear_check, 1, false],                                                                                                # 1048:特定クエストをクリア
      1049 => [:quest_no_clear_check, 1, false],                                                                                                # 1049:特定クエストをクリア
      1050 => [:quest_no_clear_check, 1, false],                                                                                                # 1050:特定クエストをクリア
      1051 => [:quest_no_clear_check, 1, false],                                                                                                # 1051:特定クエストをクリア
      1052 => [:item_num_check, [401,10], true],                                                                                                # 1052:イベントアイテムを10個集める
      1053 => [:item_num_check, [401,20], true],                                                                                                # 1053:イベントアイテムを20個集める
      1054 => [:item_num_check, [401,30], true],                                                                                                # 1054:イベントアイテムを30個集める
      1055 => [:item_num_check, [401,40], true],                                                                                                # 1055:イベントアイテムを40個集める
      1056 => [:item_num_check, [401,50], true],                                                                                                # 1056:イベントアイテムを50個集める
      1057 => [:item_num_check, [401,60], true],                                                                                                # 1057:イベントアイテムを60個集める
      1058 => [:item_num_check, [401,70], true],                                                                                                # 1058:イベントアイテムを70個集める
      1059 => [:item_num_check, [401,120], true],                                                                                               # 1059:イベントアイテムを120個集める
      1060 => [:chara_card_check, [[543,1]],false],                                                                                             # オウラン茶Lv3カードを取得する
      1061 => [:chara_card_check, [[553,1]],false],                                                                                             # オウラン白黒Lv3カードを取得する
      1062 => [:chara_card_check, [[2161,1]],false],                                                                                            # 復活スプラートカードを取得する
      1063 => [:chara_card_check, [[2001,1]],false],                                                                                            # 復活エヴァリストを取得する
      1064 => [:chara_card_check, [[2011,1]],false],                                                                                            # 復活アイザックを取得する
      1065 => [:chara_card_check, [[2021,1]],false],                                                                                            # 復活グリュンワルドを取得する
      1066 => [:chara_card_check, [[2031,1]],false],                                                                                            # 復活アベルを取得する
      1067 => [:chara_card_check, [[2041,1]],false],                                                                                            # 復活レオンを取得する
      1068 => [:chara_card_check, [[2051,1]],false],                                                                                            # 復活クレーニヒを取得する
      1069 => [:chara_card_check, [[2061,1]],false],                                                                                            # 復活ジェッドを取得する
      1070 => [:item_num_check, [478, 5], true],                                                                                                # 1070:201611イベントアイテムを5個集める
      1071 => [:item_num_check, [478, 15], true],                                                                                               # 1071:201611イベントアイテムを15個集める
      1072 => [:item_num_check, [478, 25], true],                                                                                               # 1072:201611イベントアイテムを25個集める
      1073 => [:item_num_check, [478, 35], true],                                                                                               # 1073:201611イベントアイテムを35個集める
      1074 => [:item_num_check, [478, 50], true],                                                                                               # 1074:201611イベントアイテムを50個集める
      1075 => [:item_num_check, [478, 65], true],                                                                                               # 1075:201611イベントアイテムを65個集める
      1076 => [:item_num_check, [478, 80], true],                                                                                               # 1076:201611イベントアイテムを80個集める
      1077 => [:item_num_check, [478, 100], true],                                                                                              # 1077:201611イベントアイテムを100個集める
      1078 => [:item_num_check, [478, 110], true],                                                                                              # 1078:201611イベントアイテムを110個集める
      1079 => [:item_num_check, [478, 120], true],                                                                                              # 1079:201611イベントアイテムを120個集める
      1080 => [:item_later_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 1], true],                                                                     # 1080:投票券を1個集める
      1081 => [:duel_clear_check, 1,false],                                                                                                     # 1081:3vs3デュエルを行う
      1082 => [:item_later_calc_check, [CHARA_VOTE_ITEM_ID_LIST, 4], true],                                                                     # 1082:投票券を4個集める
      1083 => [:duel_clear_check, 3,false],                                                                                                     # 1083:3vs3デュエルを3回行う
      1084 => [:duel_clear_check, 1,false],                                                                                                     # 1084:低レベルアバター（Lv20以下）とデュエルする 1
      1085 => [:duel_clear_check, 1,false],                                                                                                     # 1085:低レベルアバター（Lv20以下）とデュエルする 2
      1086 => [:duel_clear_check, 1,false],                                                                                                     # 1086:低レベルアバター（Lv20以下）とデュエルする 3
      1087 => [:duel_clear_check, 1,false],                                                                                                     # 1087:低レベルアバター（Lv20以下）がデュエルする
      1088 => [:chara_card_check, [[2251,1]],false],                                                                                            # 復活ウォーケンを取得する
      1089 => [:duel_clear_check, 1,false],                                                                                                     # 1089:3vs3デュエルを行う
      1090 => [:raid_all_damage_check, 10,false],                                                                                             # 1090:レイドボスに合計10ダメージを与える
      1091 => [:item_later_num_check, [479,30],true],                                                                                           # 1091:新たにクリスマスリース30個集める
      1092 => [:item_num_check, [479,15], true],                                                                                                # 1092クリスマスリースを15個集める
      1093 => [:item_num_check, [479,30], true],                                                                                                # 1093クリスマスリースを30個集める
      1094 => [:item_num_check, [479,70], true],                                                                                                # 1094クリスマスリースを70個集める
      1095 => [:item_num_check, [479,100], true],                                                                                                # 1095クリスマスリースを100個集める
      1096 => [:item_num_check, [479,250], true],                                                                                                # 1096クリスマスリースを250個集める
      1097 => [:item_num_check, [479,300], true],                                                                                                # 1097クリスマスリースを300個集める
      1098 => [:item_num_check, [479,350], true],                                                                                                # 1098クリスマスリースを350個集める
      1099 => [:item_num_check, [479,500], true],                                                                                                # 1099クリスマスリースを500個集める
      1100 => [:chara_card_check, [[2191,1]],false],                                                                                            # 復活エイダを取得する
      1101 => [:quest_present_check, 1, false],                                                                                                  # 1101:星1クエストをプレゼント
      1102 => [:quest_present_check, 1, false],                                                                                                  # 1102:星2クエストをプレゼント
      1103 => [:quest_present_check, 1, false],                                                                                                  # 1103:星3クエストをプレゼント
      1104 => [:quest_present_check, 1, false],                                                                                                  # 1104:星4クエストをプレゼント
      1105 => [:quest_present_check, 1, false],                                                                                                  # 1105:星5クエストをプレゼント
      1106 => [:item_num_check, [480,5], true],                                                                                                 # 1106厄難の羽根を005個集める
      1107 => [:item_num_check, [480,10], true],                                                                                                 # 1107厄難の羽根を010個集める
      1108 => [:item_num_check, [480,20], true],                                                                                                 # 1108厄難の羽根を020個集める
      1109 => [:item_num_check, [480,30], true],                                                                                                # 1109厄難の羽根を030個集める
      1110 => [:item_num_check, [480,50], true],                                                                                                # 1110厄難の羽根を050個集める
      1111 => [:item_num_check, [480,70], true],                                                                                                # 1111厄難の羽根を070個集める
      1112 => [:item_num_check, [480,90], true],                                                                                                # 1112厄難の羽根を090個集める
      1113 => [:item_num_check, [480,120], true],                                                                                                # 1113厄難の羽根を120個集める
      1114 => [:item_num_check, [480,150], true],                                                                                                # 1113厄難の羽根を150個集める
      1115 => [:item_num_check, [480,180], true],                                                                                                # 1113厄難の羽根を180個集める
      1116 => [:chara_card_check, [[2211,1]],false],                                                                                            # 復活サルガドを取得する
      1117 => [:item_num_check, [482,5], true],                                                                                                 # 1117バレンタインカードを5個集める
      1118 => [:item_num_check, [482,10], true],                                                                                                 # 1118バレンタインカードを10個集める
      1119 => [:item_num_check, [482,15], true],                                                                                                 # 1119バレンタインカードを15個集める
      1120 => [:item_num_check, [482,30], true],                                                                                                 # 1120バレンタインカードを30個集める
      1121 => [:item_num_check, [482,45], true],                                                                                                 # 1121バレンタインカードを45個集める
      1122 => [:item_num_check, [482,60], true],                                                                                                 # 1122バレンタインカードを60個集める
      1123 => [:item_num_check, [482,75], true],                                                                                                 # 1123バレンタインカードを75個集める
      1124 => [:item_num_check, [482,100], true],                                                                                                 # 1124バレンタインカードを100個集める
      1125 => [:item_num_check, [482,125], true],                                                                                                 # 1125バレンタインカードを125個集める
      1126 => [:item_num_check, [482,150], true],                                                                                                 # 1126バレンタインカードを150個集める
      1127 => [:item_num_check, [482,175], true],                                                                                                 # 1127バレンタインカードを175個集める
      1128 => [:item_num_check, [482,200], true],                                                                                                 # 1128バレンタインカードを200個集める
      1129 => [:duel_clear_check, 2,false],                                                                                                 # 3vs3デュエルを2回行う
      1130 => [:duel_clear_check, 2,false],                                                                                                 # アレクサンドルでデュエルを2回行う
      1131 => [:duel_clear_check, 2,false],                                                                                                 # コスト限定チャンネルでデュエルを2回行う
      1132 => [:chara_card_check, [[2261,1]],false],                                                                                            # 復活フロレンスを取得する
      1133 => [:item_num_check, [490,5], true],                                                                                                  # 1133ホワイトカードを5個集める
      1134 => [:item_num_check, [490,10], true],                                                                                                 # 1134ホワイトカードを10個集める
      1135 => [:item_num_check, [490,15], true],                                                                                                 # 1135ホワイトカードを15個集める
      1136 => [:item_num_check, [490,30], true],                                                                                                 # 1136ホワイトカードを30個集める
      1137 => [:item_num_check, [490,45], true],                                                                                                 # 1137ホワイトカードを45個集める
      1138 => [:item_num_check, [490,60], true],                                                                                                 # 1138ホワイトカードを60個集める
      1139 => [:item_num_check, [490,75], true],                                                                                                 # 1139ホワイトカードを75個集める
      1140 => [:item_num_check, [490,100], true],                                                                                                # 1140ホワイトカードを100個集める
      1141 => [:item_num_check, [490,125], true],                                                                                                # 1141ホワイトカードを125個集める
      1142 => [:item_num_check, [490,150], true],                                                                                                # 1142ホワイトカードを150個集める
      1143 => [:item_num_check, [490,175], true],                                                                                                # 1143ホワイトカードを175個集める
      1144 => [:item_num_check, [490,200], true],                                                                                                # 1144ホワイトカードを200個集める
      1145 => [:duel_clear_check, 2,false],                                                                                                 # 3vs3デュエルを2回行う
      1146 => [:duel_clear_check, 2,false],                                                                                                 # アレクサンドルでデュエルを2回行う
      1147 => [:duel_clear_check, 2,false],                                                                                                 # コスト限定チャンネルでデュエルを2回行う
      1148 => [:chara_card_check, [[2081,1]],false],                                                                                            # マキシマスを取得する
      1149 => [:quest_no_clear_check, 2,false],                                                                                                 # 1149:イベントクエストを2回クリア
      1150 => [:quest_clear_check, 3027,true],                                                                                                   # 1150 哄笑の平原をクリア
      1151 => [:quest_clear_check, 3028,true],                                                                                                   # 1151 不死の森をクリア
      1152 => [:quest_clear_check, 3029,true],                                                                                                   # 1152 瑕瑾の峡谷をクリア
      1153 => [:quest_clear_check, 3030,true],                                                                                                   # 1153 須臾の荒野をクリア
      1154 => [:quest_clear_check, 3031,true],                                                                                                   # 1154 黒衣の城をクリア
      1155 => [:item_num_check, [601,15], true],                                                                                                 # 1155 紫黒の仮面を15個集める
      1156 => [:item_num_check, [602,15], true],                                                                                                 # 1156 青黒の仮面を15個集める
      1157 => [:item_num_check, [603,15], true],                                                                                                 # 1157 金黒の仮面を15個集める
      1158 => [:item_set_calc_check, [[604,605],15],true],                                                                                       # 1158 茶黒の仮面と緑黒の仮面を15個ずつ集める
      1159 => [:item_set_calc_check, [[601,602,603,604,605],20],true],                                                                           # 1159 紫黒・青黒・金黒・茶黒・緑黒の仮面を20個ずつ集める
      1160 => [:item_set_calc_check, [[601,602,603,604,605],25],true],                                                                           # 1160 紫黒・青黒・金黒・茶黒・緑黒の仮面を25個ずつ集める
      1161 => [:item_set_calc_check, [[601,602,603,604,605],30],true],                                                                           # 1161 紫黒・青黒・金黒・茶黒・緑黒の仮面を30個ずつ集める
      1162 => [:quest_no_clear_check, 1, false],                                                                                                 # 1162 黒衣の城に現れたシェリの影を倒す
      1163 => [:quest_no_clear_check, 1, false],                                                                                                 # 1163 黒衣の城に現れたフリードリヒの影を倒す
      1164 => [:quest_no_clear_check, 1, false],                                                                                                 # 1164 黒衣の城に現れたスプラートの影を倒す
      1165 => [:quest_no_clear_check, 1, false],                                                                                                 # 1165 黒衣の城に現れたリーズの影を倒す
      1166 => [:quest_no_clear_check, 1, false],                                                                                                 # 1166 黒衣の城に現れたC.C.の影を倒す
      1167 => [:quest_no_clear_check, 1, false],                                                                                                 # 1167 黒衣の城に現れたギュスターヴの影を倒す
      1168 => [:quest_no_clear_check, 1, false],                                                                                                 # 1168 黒衣の城に現れたグリュンワルドの影を倒す
      1169 => [:quest_no_clear_check, 1, false],                                                                                                 # 1169 黒衣の城に現れたタイレルの影を倒す
      1170 => [:quest_no_clear_check, 1, false],                                                                                                 # 1170 黒衣の城に現れたヴィルヘルムの影を倒す
      1171 => [:chara_card_check, [[2271,1]],false],                                                                                            # 1171パルモ復活を取得する
      1172 => [:item_num_check, [606,5], true],                                                                                                  # 1172翠色の硝子玉を5個集める
      1173 => [:item_num_check, [606,10], true],                                                                                                 # 1173翠色の硝子玉を10個集める
      1174 => [:item_num_check, [606,20], true],                                                                                                 # 1174翠色の硝子玉を20個集める
      1175 => [:item_num_check, [606,30], true],                                                                                                 # 1175翠色の硝子玉を30個集める
      1176 => [:item_num_check, [606,40], true],                                                                                                 # 1176翠色の硝子玉を40個集める
      1177 => [:item_num_check, [606,50], true],                                                                                                 # 1177翠色の硝子玉を50個集める
      1178 => [:item_num_check, [606,70], true],                                                                                                 # 1178翠色の硝子玉を70個集める
      1179 => [:item_num_check, [606,90], true],                                                                                                 # 1179翠色の硝子玉を90個集める
      1180 => [:item_num_check, [606,110], true],                                                                                                # 1180翠色の硝子玉を110個集める
      1181 => [:item_num_check, [606,130], true],                                                                                                # 1181翠色の硝子玉を130個集める
      1182 => [:item_num_check, [606,150], true],                                                                                                # 1182翠色の硝子玉を150個集める
      1183 => [:duel_clear_check, 3,false],                                                                                                      # 3vs3デュエルを3回行う
      1184 => [:quest_no_clear_check, 3, false],                                                                                                 # 1184 イベントクエストを3回クリア
      1185 => [:quest_no_clear_check, 9, false],                                                                                                 # 1185 イベントクエストを+9回クリア
      1186 => [:quest_no_clear_check, 12, false],                                                                                                # 1186 イベントクエストを+12回クリア
      1187 => [:quest_no_clear_check, 15, false],                                                                                                # 1187 イベントクエストを+15回クリア
      1188 => [:quest_no_clear_check, 10, false],                                                                                                # 1188 イベントクエストを+10回クリア
      1189 => [:quest_no_clear_check, 14, false],                                                                                                # 1189 イベントクエストを+14回クリア
      1190 => [:quest_no_clear_check, 18, false],                                                                                                # 1190 イベントクエストを+18回クリア
      1191 => [:quest_no_clear_check, 22, false],                                                                                                # 1191 イベントクエストを+22回クリア
      1192 => [:quest_no_clear_check, 19, false],                                                                                                # 1192 イベントクエストを+19回クリア
      1193 => [:quest_no_clear_check, 28, false],                                                                                                # 1193 イベントクエストを+28回クリア
      1194 => [:duel_clear_check, 1,false],                                                                                                      # 1194 デュエルを行う
      1195 => [:item_num_check, [608,3], true],                                                                                                  # 1195 イベントアイテムを3個集める
      1196 => [:item_num_check, [608,5], true],                                                                                                  # 1196 イベントアイテムを5個集める
      1197 => [:item_num_check, [608,15], true],                                                                                                 # 1197 イベントアイテムを15個集める
      1198 => [:item_num_check, [608,25], true],                                                                                                 # 1198 イベントアイテムを25個集める
      1199 => [:item_num_check, [608,50], true],                                                                                                 # 1199 イベントアイテムを50個集める
      1200 => [:item_num_check, [608,65], true],                                                                                                 # 1200 イベントアイテムを65個集める
      1201 => [:item_num_check, [608,80], true],                                                                                                 # 1201 イベントアイテムを80個集める
      1202 => [:item_num_check, [608,95], true],                                                                                                 # 1202 イベントアイテムを95個集める
      1203 => [:item_num_check, [608,110], true],                                                                                                # 1203 イベントアイテムを110個集める
      1204 => [:item_num_check, [608,125], true],                                                                                                # 1204 イベントアイテムを125個集める
      1205 => [:duel_clear_check, 2,false],                                                                                                      # 1205 デュエルを2回行う
    }
    # キャラカード枚数check、BIT演算用定数
    CHARA_CARD_CHECK_SHIFT_BIT = 8
    CHARA_CARD_CHECK_COMP_NUM  = 0b11111111
    # アイテム個数関連check、BIT演算用定数
    ITEM_SET_CALC_CHECK_SHIFT_BIT = 6
    ITEM_SET_CALC_CHECK_COMP_NUM  = 0b111111

    # レベルチェック
    def level_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.level
      inv.save_changes
      success_cond = v unless success_cond
      avatar.level >= v
    end

    # デュエル勝ち数チェック
    def duel_win_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.win
      inv.save_changes
      success_cond = v unless success_cond
      avatar.win >= v
    end

    # クエストクリアチェック
    def quest_clear_check(avatar, v, inv, success_cond=nil)
      check_flag  = avatar.get_quest_flag(v)
      inv.progress = check_flag
      inv.save_changes
      check_flag >= v
    end

    # フレンド数チェック
    def friend_num_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.player.confirmed_friend_num
      inv.save_changes
      success_cond = v unless success_cond
      avatar.player.confirmed_friend_num >= v
    end

    # 固有アイテム数チェック
    def item_num_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.item_count(v[0])
      inv.save_changes
      success_cond = v[1] unless success_cond
      avatar.item_count(v[0]) >= v[1]
    end

    # 固有アイテム数チェック
    def halloween_check(avatar, v, inv, success_cond=nil)
      r_list = []
      avatar.avatar_quest_inventories.each do |qi|
        if qi.status == QS_NEW||qi.status == QS_UNSOLVE
          r_list << qi.quest.rarity
        end
      end
      r = r_list & v
      inv.progress = r.length
      inv.save_changes
      v.sort! == r.sort!
    end

    # 所持アイテム数チェック
    def item_check(avatar, v, inv, success_cond=nil)
      ret = false
      v.each do |i|
        ret = true if avatar.item_count(i) > 0
      end
      ret
    end

    # アイテムコンプリートチェック
    def item_complete_check(avatar, v, inv, success_cond=nil)
      cnt = 0
      ret = true
      v.each do |i|
        if avatar.item_count(i) == 0
          ret = false
        else
          cnt += 1
        end
      end
      inv.progress = cnt
      inv.save_changes
      ret
    end

    # 複数アイテム集計チェック
    def item_calc_check(avatar, v, inv, success_cond=nil)
      count = 0
      avatar.item_inventories
      v[0].each do |i|
        count += avatar.item_count(i, false)
      end
      inv.progress = count
      inv.save_changes
      count >= v[1]
    end

    # 複数アイテムセット集計チェック
    def item_set_calc_check(avatar, v, inv, success_cond=nil)
      ret = true
      cnt = 0
      v[0].each_with_index do |i,idx|
        num = avatar.item_count(i)
        ret = false if num < v[1]
        num = ITEM_SET_CALC_CHECK_COMP_NUM if num > ITEM_SET_CALC_CHECK_COMP_NUM
        cnt = cnt | (num << (ITEM_SET_CALC_CHECK_SHIFT_BIT*idx))
      end
      inv.progress = cnt
      inv.save_changes
      ret
    end

    # 所持キャラカード数チェック
    def chara_card_check(avatar, v, inv, success_cond=nil, card_list=nil)
      r_list = {}
      ret = 0
      cnt = 0
      card_list[:list].each do |c|
        r_list[c] = 0 unless r_list[c]
        r_list[c] += 1
      end
      if card_list[:is_update] == false
        v.each_with_index do |i,c|
          set_cnt = 0
          if r_list[i[0]]
            if r_list[i[0]] >= i[1]
              ret += 1
            end
            set_cnt = r_list[i[0]]
            set_cnt = i[1] if set_cnt > i[1]
          end
          # 新しいProgress計算式 2013/01/15
          cnt = cnt | (set_cnt << (CHARA_CARD_CHECK_SHIFT_BIT*c))
        end
      else
        v.each_with_index do |i,c|
          set_cnt = 0
          bit_num = inv.progress & (CHARA_CARD_CHECK_COMP_NUM << (CHARA_CARD_CHECK_SHIFT_BIT*c))
          num = bit_num >> (CHARA_CARD_CHECK_SHIFT_BIT*c)
          r_list[i[0]] = 0 unless r_list[i[0]]
          r_list[i[0]] += num
          if r_list[i[0]]
            if r_list[i[0]] >= i[1]
              ret += 1
            end
            set_cnt = r_list[i[0]]
            set_cnt = i[1] if set_cnt > i[1]
          end
          # 新しいProgress計算式 2013/01/15
          cnt = cnt | (set_cnt << (CHARA_CARD_CHECK_SHIFT_BIT*c))
        end
      end
      inv.progress = cnt
      inv.save_changes
      ret == v.length
    end

    # デッキ内容チェック
    def chara_card_deck_check(avatar, v, inv, success_cond=nil)
      ret = false
      avatar.chara_card_decks.each_index do |i|
        unless i == 0
          ret = v == avatar.chara_card_decks[i].cards_id
          break if ret
        end
      end
      ret
    end

    def get_record_clear_quest_no
      ret = 0
      # 初心者レコード
      ret = ROOKIE_QUEST_01[0] if ret == 0 && ROOKIE_QUEST_01[1].include?(self.id)
      # イベントレコード
      ret = EVENT_QUEST_01[0] if ret == 0 && EVENT_QUEST_01[1].include?(self.id)
      ret = EVENT_QUEST_02[0] if ret == 0 && EVENT_QUEST_02[1].include?(self.id)
      ret = EVENT_QUEST_03[0] if ret == 0 && EVENT_QUEST_03[1].include?(self.id)
      ret = EVENT_QUEST_04[0] if ret == 0 && EVENT_QUEST_04[1].include?(self.id)
      ret = EVENT_QUEST_05[0] if ret == 0 && EVENT_QUEST_05[1].include?(self.id)
      ret = EVENT_QUEST_06[0] if ret == 0 && EVENT_QUEST_06[1].include?(self.id)
      ret = EVENT_QUEST_07[0] if ret == 0 && EVENT_QUEST_07[1].include?(self.id)
      ret = EVENT_QUEST_08[0] if ret == 0 && EVENT_QUEST_08[1].include?(self.id)
      ret = EVENT_QUEST_09[0] if ret == 0 && EVENT_QUEST_09[1].include?(self.id)
      ret = EVENT_QUEST_10[0] if ret == 0 && EVENT_QUEST_10[1].include?(self.id)
      ret = EVENT_QUEST_11[0] if ret == 0 && EVENT_QUEST_11[1].include?(self.id)
      ret = EVENT_QUEST_12[0] if ret == 0 && EVENT_QUEST_12[1].include?(self.id)
      ret = EVENT_QUEST_13[0] if ret == 0 && EVENT_QUEST_13[1].include?(self.id)
      ret = EVENT_QUEST_14[0] if ret == 0 && EVENT_QUEST_14[1].include?(self.id)
      ret = EVENT_QUEST_15[0] if ret == 0 && EVENT_QUEST_15[1].include?(self.id)
      ret = EVENT_QUEST_16[0] if ret == 0 && EVENT_QUEST_16[1].include?(self.id)
      ret = EVENT_QUEST_17[0] if ret == 0 && EVENT_QUEST_17[1].include?(self.id)
      ret = EVENT_QUEST_18[0] if ret == 0 && EVENT_QUEST_18[1].include?(self.id)
      ret = EVENT_QUEST_19[0] if ret == 0 && EVENT_QUEST_19[1].include?(self.id)
      ret = EVENT_QUEST_20[0] if ret == 0 && EVENT_QUEST_20[1].include?(self.id)
      ret = EVENT_QUEST_21[0] if ret == 0 && EVENT_QUEST_21[1].include?(self.id)
      ret = EVENT_QUEST_22[0] if ret == 0 && EVENT_QUEST_22[1].include?(self.id)
      ret = EVENT_QUEST_23[0] if ret == 0 && EVENT_QUEST_23[1].include?(self.id)
      ret = EVENT_QUEST_24[0] if ret == 0 && EVENT_QUEST_24[1].include?(self.id)
      ret = EVENT_QUEST_25[0] if ret == 0 && EVENT_QUEST_25[1].include?(self.id)
      ret = EVENT_QUEST_26[0] if ret == 0 && EVENT_QUEST_26[1].include?(self.id)
      ret = EVENT_QUEST_27[0] if ret == 0 && EVENT_QUEST_27[1].include?(self.id)
      ret = EVENT_QUEST_28[0] if ret == 0 && EVENT_QUEST_28[1].include?(self.id)
      ret = EVENT_QUEST_29[0] if ret == 0 && EVENT_QUEST_29[1].include?(self.id)
      ret = EVENT_QUEST_30[0] if ret == 0 && EVENT_QUEST_30[1].include?(self.id)
      ret = EVENT_QUEST_31[0] if ret == 0 && EVENT_QUEST_31[1].include?(self.id)
      ret = EVENT_QUEST_32[0] if ret == 0 && EVENT_QUEST_32[1].include?(self.id)
      ret = EVENT_QUEST_33[0] if ret == 0 && EVENT_QUEST_33[1].include?(self.id)
      ret = EVENT_QUEST_34[0] if ret == 0 && EVENT_QUEST_34[1].include?(self.id)
      ret = EVENT_QUEST_35[0] if ret == 0 && EVENT_QUEST_35[1].include?(self.id)
      # 炎の聖女
      ret = GODDESS_OF_FIRE_QUEST_01[0] if ret == 0 && GODDESS_OF_FIRE_QUEST_01[1].include?(self.id)
      ret = GODDESS_OF_FIRE_QUEST_02[0] if ret == 0 && GODDESS_OF_FIRE_QUEST_02[1].include?(self.id)
      ret = GODDESS_OF_FIRE_QUEST_03[0] if ret == 0 && GODDESS_OF_FIRE_QUEST_03[1].include?(self.id)
      ret
    end

    def get_record_clear_prf_no
      ret = 0
      # ボス討伐チェック
      ret = EVENT_PRF_SET_01[0] if ret == 0 && EVENT_PRF_SET_01[1].include?(self.id)
      ret
    end

    def get_record_part
      ret = 0
      # パーツ取得チェック
      ret = EVENT_GET_PART_01[0] if ret == 0 && EVENT_GET_PART_01[1].include?(self.id)
      ret = EVENT_GET_PART_02[0] if ret == 0 && EVENT_GET_PART_02[1].include?(self.id)
      ret = EVENT_GET_PART_03[0] if ret == 0 && EVENT_GET_PART_03[1].include?(self.id)
      ret
    end

    # クリア条件データを文字列にして返す
    def get_cond_info_str()
      ret = ""
      if CONDITION_SET[self.id]
        # CondType
        case CONDITION_SET[self.id][0]
        when :level_check
          ret << ACHIEVEMENT_COND_TYPE_LEVEL.to_s << ":"
        when :duel_win_check
          ret << ACHIEVEMENT_COND_TYPE_DUEL_WIN.to_s << ":"
        when :quest_clear_check
          ret << ACHIEVEMENT_COND_TYPE_QUEST_CLEAR.to_s << ":"
        when :friend_num_check
          ret << ACHIEVEMENT_COND_TYPE_FRIEND_NUM.to_s << ":"
        when :item_num_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_NUM.to_s << ":"
        when :halloween_check
          ret << ACHIEVEMENT_COND_TYPE_HALLOWEEN.to_s << ":"
        when :chara_card_check
          ret << ACHIEVEMENT_COND_TYPE_CHARA_CARD.to_s << ":"
        when :chara_card_deck_check
          ret << ACHIEVEMENT_COND_TYPE_CHARA_CARD_DECK.to_s << ":"
        when :quest_no_clear_check
          ret << ACHIEVEMENT_COND_TYPE_QUEST_NO_CLEAR.to_s << ":"
        when :get_rare_card_check
          ret << ACHIEVEMENT_COND_TYPE_GET_RARE_CARD.to_s << ":"
        when :duel_clear_check
          ret << ACHIEVEMENT_COND_TYPE_DUEL_CLEAR.to_s << ":"
        when :quest_present_check
          ret << ACHIEVEMENT_COND_TYPE_QUEST_PRESENT.to_s << ":"
        when :record_clear_check
          ret << ACHIEVEMENT_COND_TYPE_RECORD_CLEAR.to_s << ":"
        when :item_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM.to_s << ":"
        when :item_complete_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_COMPLETE.to_s << ":"
        when :item_calc_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_CALC.to_s << ":"
        when :item_set_calc_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_SET_CALC.to_s << ":"
        when :week_duel_clear_check
          ret << ACHIEVEMENT_COND_TYPE_DUEL_CLEAR.to_s << ":"
        when :quest_point_check
          ret << ACHIEVEMENT_COND_TYPE_QUEST_POINT.to_s << ":"
        when :get_weapon_check
          ret << ACHIEVEMENT_COND_TYPE_GET_WEAPON.to_s << ":"
        when :week_quest_clear_check
          ret << ACHIEVEMENT_COND_TYPE_QUEST_ADVANCE.to_s << ":"
        when :find_raid_profound
          ret << ACHIEVEMENT_COND_TYPE_FIND_PROFOUND.to_s << ":"
        when :raid_btl_cnt
          ret << ACHIEVEMENT_COND_TYPE_RAID_BATTLE_CNT.to_s << ":"
        when :multi_quest_clear_check
          ret << ACHIEVEMENT_COND_TYPE_MULTI_QUEST_CLEAR.to_s << ":"
        when :invite_count_check
          ret << ACHIEVEMENT_COND_TYPE_INVITE_COUNT.to_s << ":"
        when :raid_boss_defeat_check
          ret << ACHIEVEMENT_COND_TYPE_RAID_BOSS_DEFEAT.to_s << ":"
        when :raid_all_damage_check
          ret << ACHIEVEMENT_COND_TYPE_RAID_ALL_DAMAGE.to_s << ":"
        when :created_days_check
          ret << ACHIEVEMENT_COND_TYPE_CREATED_DAYS.to_s << ":"
        when :event_point_check
          ret << ACHIEVEMENT_COND_TYPE_EVENT_POINT.to_s << ":"
        when :event_point_cnt_check
          ret << ACHIEVEMENT_COND_TYPE_EVENT_POINT_CNT.to_s << ":"
        when :get_part_check
          ret << ACHIEVEMENT_COND_TYPE_GET_PART.to_s << ":"
        when :daily_record_clear_check
          ret << ACHIEVEMENT_COND_TYPE_DAILY_CLEAR.to_s << ":"
        when :other_raid_btl_cnt
          ret << ACHIEVEMENT_COND_TYPE_OTHER_RAID.to_s << ":"
        when :use_item_check
          ret << ACHIEVEMENT_COND_TYPE_USE_ITEM.to_s << ":"
        when :self_raid_claer_check
          ret << ACHIEVEMENT_COND_TYPE_SELF_RAID.to_s << ":"
        when :other_duel_cnt_check
          ret << ACHIEVEMENT_COND_TYPE_OTHER_DUEL.to_s << ":"
        when :item_full_num_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_NUM.to_s << ":"
        when :item_later_num_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_NUM.to_s << ":"
        when :item_later_calc_check
          ret << ACHIEVEMENT_COND_TYPE_ITEM_CALC.to_s << ":"
        end

        # 条件内容数値
        if CONDITION_SET[self.id][1].instance_of?(Array)
          if CONDITION_SET[self.id][1][0].instance_of?(Array)
            if CONDITION_SET[self.id][0] == :item_calc_check || CONDITION_SET[self.id][0] == :item_set_calc_check || CONDITION_SET[self.id][0] == :item_later_calc_check || CONDITION_SET[self.id][0] == :weapon_multi_num_check
              item_ids = CONDITION_SET[self.id][1][0]
              count = CONDITION_SET[self.id][1][1]
              item_ids.each { |e|
                ret << "#{e},#{count}" << "_"
              }
            else
              CONDITION_SET[self.id][1].each { |e|
                ret << e.join(",") << "_"
              }
            end
            ret.chop!
          else
            if CONDITION_SET[self.id][0] == :event_point_cnt_check
              ret << CONDITION_SET[self.id][1].last.to_s
            else
              ret << CONDITION_SET[self.id][1].join(",")
            end
          end
        else
          if CONDITION_SET[self.id][0] == :quest_no_clear_check
            q_ids = self.get_record_clear_quest_no
            if q_ids != 0
              ret << q_ids.join(",")
            else
              ret << q_ids.to_s
            end
          elsif CONDITION_SET[self.id][0] == :raid_boss_defeat_check
            p_ids = self.get_record_clear_prf_no
            if p_ids != 0
              ret << p_ids.join(",")
            else
              ret << p_ids.to_s
            end
          elsif CONDITION_SET[self.id][0] == :get_part_check
            p_ids = self.get_record_part
            if p_ids != 0
              ret << p_ids.join(",")
            else
              ret << p_ids.to_s
            end
          else
            ret << CONDITION_SET[self.id][1].to_s
          end
        end
      end

      ret
    end

    # データをとる
    def get_data_csv_str()
      ret = ""
      ret << self.id.to_s << ","
      ret << self.kind.to_s << ","
      ret << '"' << (self.caption||"")<< '",'
      ret << '"' << (self.event_end_at&&self.event_end_at.strftime("%a %b %d %H:%M:%S %Z %Y")||"")<< '",'
      ret << self.success_cond.to_s << ","
      ret << '"' << get_cond_info_str << '",'
      exp_str = (self.explanation != nil) ? self.explanation.gsub(/\n/,"") : ""
      ret << '"' << exp_str << '"'<< ','
      ret << "#{self.get_selectable_array}"
      ret
    end

    # クエストクリアチェック
    def quest_no_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      if inv.progress >= (v)
        ret = true
        avatar.achievement_check([345]) if ([306,308,310,312,314,316,318,320,322,324,326,328,330,332,334,336,338,340,342,344]).include?(inv.achievement_id) # レアカードレコードチェック
      end
      ret
    end

    # レアカードを作成時のアチーブメント
    def get_rare_card_check(avatar, v, inv, success_cond=nil)
      ret = false
      if CardInventory.graph(CharaCard, :id=>:chara_card_id).filter(:chara_card_deck_id => Range.new(avatar.binder.id, avatar.binder.id+3)).and(Sequel.cast_string(:card_inventories__created_at) >= self.event_start_at).and([[:chara_cards__rarity , Range.new(6, 10)], [:chara_cards__id , Range.new(1, 1000)]]).all.count >= v
        ret = true
      end
      ret
    end

    # デュエルクリアチェック
    def duel_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= v
        ret = true
      end
      ret
    end

    # デュエル勝利チェック
    def duel_clear_win_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= v
        ret = true
      end
      ret
    end

    # クエストをプレゼントしたときのチェック
    def quest_present_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= v
        ret = true
      end
      ret
    end

    # レコードクリアチェックチェック
    def record_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= v
        ret = true
      end
      ret
    end

    # 取得カードレベルチェック
    def get_card_level_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v[3] unless success_cond
      if inv.progress >= v[3]
        ret = true
      end
      ret
    end

    # 週間デュエルクリアチェック
    def week_duel_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # クエストポイントチェック
    def quest_point_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.quest_point
      inv.save_changes
      success_cond = v unless success_cond
      (inv.progress >= success_cond)
    end

    # 装備カード取得チェック
    def get_weapon_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 装備カード所持チェック
    def weapon_multi_num_check(avatar, v, inv, success_cond=nil)
      ret = false
      cnt_set = []
      weapon_inv_list = avatar.get_some_weapon_list(v[0])
      weapon_inv_list.each do |w_inv|
        cnt_set.push(w_inv.card_id) unless cnt_set.index(w_inv.card_id)
      end
      inv.progress = cnt_set.size
      inv.save_changes
      success_cond = v[1] unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 週間クエストクリアチェック
    def week_quest_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 渦発見チェック
    def find_raid_profound(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # レイド戦参加チェック
    def raid_btl_cnt(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 複数条件のクエストクリアチェック
    def multi_quest_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 招待人数チェック
    def invite_count_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # レイドボスの討伐数チェック
    def raid_boss_defeat_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 累計レイドボス与ダメージ
    def raid_all_damage_check(avatar, v, inv, success_cond=nil)
      ret = false
      set_damage = inv.progress
      dmg = nil
      dmg = ProfoundLog.filter([:avatar_id => avatar.id]).select_append{ sum(damage).as(sum_damage)}.filter{ created_at > inv.created_at}.all.first
      SERVER_LOG.info("<UID:#{avatar.player_id}>Achievement [#{__method__}] dmg:#{dmg[:sum_damage]}") if dmg&&dmg[:sum_damage]
      set_damage = dmg[:sum_damage] if dmg&&dmg[:sum_damage]
      inv.progress = set_damage
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # アバター作製からの日数
    def created_days_check(avatar, v, inv, success_cond=nil)
      ret = false
      now = Time.now.utc
      days = (now - avatar.created_at).divmod(24*60*60).first
      inv.progress = days
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # イベントポイントチェック
    def event_point_check(avatar, v, inv, success_cond=nil, point = 0)
      ret = false
      inv.progress += point
      inv.save_changes
      CACHE.set("achi_check_inv:#{avatar.id}_#{inv.achievement_id}",inv)
      success_cond = v unless success_cond
      # 加算用レコードなので、クリア判定なし
      # if success_cond != -1 && inv.progress >= success_cond
      #   ret = true
      # end
      ret
    end

    # イベントポイントカウントチェック
    def event_point_cnt_check(avatar, v, inv, success_cond=nil)
      ret = false
      check_inv = CACHE.get("achi_check_inv:#{avatar.id}_#{v[0]}")
      unless check_inv
        check_inv = avatar.get_achievement(v[0])
        CACHE.set("achi_check_inv:#{avatar.id}_#{v[0]}",check_inv)
      end
      if check_inv
        inv.progress = check_inv.progress
        inv.save_changes
      end
      success_cond = v[1] unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # パーツ取得チェック
    def get_part_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 日間クエストレコードとデュエルレコードを両方クリアする
    def daily_record_clear_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 他人の渦戦に参加する
    def other_raid_btl_cnt(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # イベント渦発見アイテムを使用する
    def use_item_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 自分で発見した渦の討伐に成功する
    def self_raid_claer_check(avatar, v, inv, success_cond=nil)
      ret = false
      inv.progress +=1
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 別の人物と特定数デュエルする
    def other_duel_cnt_check(avatar, v, inv, success_cond=nil)
      ret = false
      progress = 0
      list = avatar.duel_foe_avatar_get_cache
      progress = list.size if list
      inv.progress = progress
      inv.save_changes
      success_cond = v unless success_cond
      if inv.progress >= success_cond
        ret = true
      end
      ret
    end

    # 固有アイテム数全チェック
    def item_full_num_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.full_item_count(v[0])
      inv.save_changes
      success_cond = v[1] unless success_cond
      avatar.full_item_count(v[0]) >= v[1]
    end


    # 新たに取得した持アイテム数チェック
    def item_later_num_check(avatar, v, inv, success_cond=nil)
      inv.progress = avatar.item_count_later(v[0],inv.created_at)
      inv.save_changes
      success_cond = v[1] unless success_cond
      avatar.item_count_later(v[0],inv.created_at) >= v[1]
    end

    # 複数アイテムの新規取得集計チェック
    def item_later_calc_check(avatar, v, inv, success_cond=nil)
      count = 0
      count += avatar.set_item_count_later(v[0],inv.created_at,true)
      inv.progress = count
      inv.save_changes
      count >= v[1]
    end

    # 引き継ぐAchievementIdの取得 0なら引継ぎなし
    def get_inheriting_progress
      ret = 0
      # 2014/12Eventではクエストプレゼントレコードの継承はなし
      if  CONDITION_SET[self.cond][0] == :invite_count_check ||
          CONDITION_SET[self.cond][0] == :raid_boss_defeat_check ||
          CONDITION_SET[self.cond][0] == :other_duel_cnt_check ||
          CONDITION_SET[self.cond][0] == :item_full_num_check
        ret = self.prerequisite
      end
      ret
    end


    def get_chara_card_progress(avatar, v, inv)
      ret = []
      v.each_with_index do |val,i|
        if inv
          bit_num = inv.progress & (CHARA_CARD_CHECK_COMP_NUM << (CHARA_CARD_CHECK_SHIFT_BIT*i))
          num = bit_num >> (CHARA_CARD_CHECK_SHIFT_BIT*i)
          ret.push(num)
        else
          ret.push(0)
        end
      end
      ret.join(",")
    end

    def get_item_set_calc_check(avatar, v, inv)
      ret = []
      v[0].each_with_index do |i,idx|
        if inv
          bit_num = inv.progress & (ITEM_SET_CALC_CHECK_COMP_NUM << (ITEM_SET_CALC_CHECK_SHIFT_BIT*idx))
          num = bit_num >> (ITEM_SET_CALC_CHECK_SHIFT_BIT*idx)
          ret.push(num)
        else
          ret.push(0)
        end
      end
      ret.join(",")
    end

    def get_progress(avatar,inv=nil)
      ret = nil
      case CONDITION_SET[self.id] && CONDITION_SET[self.id][0]
      when :chara_card_check
        ret = get_chara_card_progress(avatar,CONDITION_SET[self.id][1],inv)
      when :item_set_calc_check
        ret = get_item_set_calc_check(avatar,CONDITION_SET[self.id][1],inv)
      end
      ret
    end

  end

end
