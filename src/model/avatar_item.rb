# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # アバターアイテムクラス
  class AvatarItem < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    ITEM_DURATION_BASE = 60     # Durationの単位は分

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name
      integer     :item_no
      integer     :kind
      String      :sub_kind,:default => "" # Kindで指定している箇所以下のウィンドウに出したい場合の指定 [+]で分ける
      integer     :duration, :default => 0 # 分
      String      :cond, :default => ""    # kind毎に異なる用途に使える設定値
      String      :image, :default => ""
      integer     :image_frame, :default => 0
      String      :effect_image, :default => ""
      String      :caption, :default => ""
      datetime    :created_at
      datetime    :updated_at
    end
    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(AvatarItem.table_exists?)
      AvatarItem.create_table
    end

    DB.alter_table :avatar_items do
      add_column :sub_kind, String, :default => "" unless Unlight::AvatarItem.columns.include?(:sub_kind)  # 新規追加2014/01/14
      add_column :cond, String, :default => "" unless Unlight::AvatarItem.columns.include?(:cond)  # 新規追加2015/09/15
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
    end

    # 全体データバージョンを返す
    def AvatarItem::data_version
      ret = cache_store.get("AvatarItemVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("AvatarItemVersion", ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def AvatarItem::refresh_data_version
      m = Unlight::AvatarItem.order(:updated_at).last
      if m
        cache_store.set("AvatarItemVersion",m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # ===============================
    # アイテム種別
    # 必要となるオブジェクトが種別によってきまる
    # 0:Avatarのみ
    # 1:Rewardのみ
    # 2:AutoPlayとAvatar

    # アイテムの効果、使用関数とValueのペア
    ITEM_EFFECTS = {
      0   => [:heal_ap,3],                               # 0:回復ポーション
      1   => [:heal_ap,10],                              # 1:ハイポーション
      2   => [:heal_ap,999],                             # 2:グレートポーション
      3   => [:reward_dice_reroll],                      # 3:ラッキークローバー
      4   => [:reward_dice_amend,1],                     # 4:ホワイトヒース1
      5   => [:reward_dice_amend,3],                     # 5:ホワイトヒース3
      6   => [:reward_dice_amend,5],                     # 6:ホワイトヒース5
      7   => [:reward_dice_amend,12],                    # 7:スキップスター
      8   => [:ticket_use,1],                            # 8:ガチャチケット
      9   => [:ticket_use,1],                            # 9:コピーチケット
      10  => [:quest_time_go,60*3],                      # 10:時の砂時計      （探索中のクエストの時間を進める）（3時間）
      11  => [:quest_time_go,60*24*3],                   # 11:超刻の砂時計    （探索中のクエストの時間を進める）（3日）
      12  => [:quest_chara_heal,1],                      # 12:ヒールハーブ1   （探索中のキャラのHPを1回復させる）
      13  => [:quest_chara_heal,3],                      # 13:ヒールハーブ3   （探索中のキャラのHPを3回復させる）
      14  => [:quest_chara_heal,5],                      # 14:ヒールハーブ5   （探索中のキャラのHPを5回復させる）
      15  => [:quest_chara_heal,10],                     # 15:ヒールハーブ10  （探索中のキャラのHPを10回復させる）
      16  => [:quest_chara_all_heal],                    # 16:エリクシール    （探索中のキャラのHPを全回復させる）
      17  => [:quest_max_up,1],                          # 17:探索力アップの本（探索クエストのMAX増やす)
      18  => [:quest_max_up,2],                          # 18:探索力アップの本  （一時的に追加の探索クエストを増やす）
      19  => [:quest_max_up,3],                          # 19:探索力アップの本 （一時的に追加の探索クエストを増やす）
      20  => [:quest_restart],                           # 20:モーフィアスの扉（クエストを最初からやり直せる）
      21  => [:quest_skip,10],                           # 21:トロイメライの扉
      22  => [:quest_map_skip],                          # 22:墓標の旗
      23  => [:quest_get_boss],                          # 23:妖魔のコンパス
      24  => [:friend_max_up,1],                         # 24:ホワイトクッキー
      25  => [:friend_max_up,1],                         # 25:バレンタインチョコ
      26  => [:friend_max_up,5],                         # 26:人形の日記帳
      27  => [:friend_max_up,10],                        # 27:追憶の日記帳
      28  => [:friend_max_up,1],                         # 28:コンペイトウ
      29  => [:not_use,0],                               # 29:一周年記念コイン
      30  => [:get_ex_shadow_land,0],                    # 30:ExShadowLand通行証1
      31  => [:get_ex_shadow_land,5],                    # 31:ExShadowLand通行証2
      32  => [:get_ex_shadow_land,10],                   # 32:ExShadowLand通行証3
      33  => [:get_ex_moon_land,0],                      # 33:ExMoonLand通行証1
      34  => [:get_ex_moon_land,5],                      # 34:ExMoonLand通行証2
      35  => [:get_ex_moon_land,10],                     # 35:ExMoonLand通行証3
      36  => [:part_max_up,5],                           # 36:クローゼット5
      37  => [:heal_ap_force,50],                        # 37:キノコエキス
      38  => [:ap_max_up,1],                             # 38:神薬
      39  => [:reset_result,1],                          # 39:青き浄化の炎
      40  => [:reset_bp,1],                              # 40:赤き浄化の炎
      41  => [:part_max_up,10],                          # 41:クローゼット10
      42  => [:get_ev_xmas_land,0],                      # 42:xmaxland通行証
      43  => [:get_ev_valentine_land,0],                 # 43:valentineland通行証
      44  => [:get_ev_white_land,0],                     # 44:whitedayland通行証
      45  => [:ap_max_up,5],                             # 45:至宝の神薬5
      46  => [:get_ex_anemonea,0],                       # 46:ExAnemonea通行証1
      47  => [:get_ex_anemonea,5],                       # 47:ExAnemonea通行証2
      48  => [:get_ex_anemonea,10],                      # 48:ExAnemonea通行証3
      49  => [:part_max_up,1],                           # 49:クローゼット1
      50  => [:get_ev_codex_land,0],                     # 50:コデックスの欠片
      51  => [:get_ev_ark_land,0],                       # 51:聖櫃
      52  => [:get_gems,500],                            # 52:500GEM小切手
      53  => [:get_gems,1000],                           # 53:1000GEM小切手
      54  => [:get_gems,3000],                           # 54:3000GEM
      55  => [:get_gems,5000],                           # 55:5000GEM
      56  => [:get_gems,10000],                          # 56:10000GEM
      57  => [:get_ev_acolyte_land,0],                   # 57:アコライト通行証0分
      58  => [:get_ev_acolyte_land,7],                   # 58:アコライト通行証8時間
      59  => [:get_ev_acolyte_land,10],                  # 59:アコライト通行証3日
      60  => [:not_use,0],                               # 60:フレンドイベント(1P)
      61  => [:not_use,0],                               # 61:フレンドイベント(5P)
      62  => [:get_ev_land,[QM_EV_2NDANNI1_LAND, 0]],    # 62:２周年イベントクエランド1
      63  => [:get_ev_land,[QM_EV_2NDANNI2_LAND, 0]],    # 63:２周年イベントクエランド2
      64  => [:get_ev_land,[QM_EV_2NDANNI3_LAND, 0]],    # 64:２周年イベントクエランド3
      65  => [:get_ev_land,[QM_EX_ANGEL_LAND, 0]],       # 65:EXAngelLand通行証1
      66  => [:get_ev_land,[QM_EX_ANGEL_LAND, 5]],       # 66:EXAngelLand通行証2
      67  => [:get_ev_land,[QM_EX_ANGEL_LAND, 10]],      # 67:EXAngelLand通行証3
      68  => [:get_ev_land,[QM_EV_XMAS2012_LAND, 0]],    # 68:2012XMAXLand通交証
      69  => [:get_ev_land,[QM_EV_NEWYEAR2013_LAND, 0]], # 69:2013NewyearLand
      70  => [:get_ev_land,[QM_EV_WHITE2013_LAND, 0]],   # 70:2013WhiteLand
      71  => [:get_ev_land,[QM_EV_RARECARD_LAND, 0]],    # 71:RarecardLand
      72  => [:get_ev_land,[QM_EX_EVENT_LAND, 0]],       # 72:ExEventLand通行証1
      73  => [:get_ev_land,[QM_EX_EVENT_LAND, 5]],       # 73:ExEventLand通行証2
      74  => [:get_ev_land,[QM_EX_EVENT_LAND, 10]],      # 74:ExEventLand通行証3
      75  => [:get_ev_land,[QM_EV_XMAS2013_LAND_A, 0]],  # 75:2013XMAXLand_A
      76  => [:get_ev_land,[QM_EV_XMAS2013_LAND_B, 0]],  # 76:2013XMAXLand_B
      77  => [:get_ev_land,[QM_EV_ACOLYTE2014_LAND, 0]], # 77:トランプ
      78  => [:find_group_profound,[100,0]],             # 78:α型渦探知機1
      79  => [:find_group_profound,[200,0]],             # 79:α型渦探知機2
      80  => [:find_group_profound,[300,0]],             # 80:α型渦探知機3
      81  => [:get_ev_land,[QM_RARE_LAND, 0]],           # 81:ムネメの栞（R1）
      82  => [:find_group_profound,[400,0]],             # 82:α型渦探知機4
      83  => [:find_group_profound,[500,0]],             # 83:α型渦探知機5
      84  => [:get_new_deck,0],                          # 84:デッキ追加（Lv 1）
      85  => [:get_new_deck,114060],                     # 85:デッキ追加（Lv 31）
      86  => [:get_new_deck,1316560],                    # 86:デッキ追加（Lv 56）
      87  => [:get_ev_land,[QM_EV_ABYSS_LAND, 0]],       # 87:深淵の書（2014/5月イベント用）
      88  => [:find_group_profound,[106,0]],             # 88:ダウジングロッド1
      89  => [:find_group_profound,[206,0]],             # 89:ダウジングロッド2
      90  => [:find_group_profound,[306,0]],             # 90:ダウジングロッド3
      91  => [:find_group_profound,[306,0]],             # 91:ダウジングロッド4
      92  => [:not_use,0],                               # 92:星の砂(201407EventItem)
      93  => [:get_ev_land,[QM_EV_SUMMER2014_LAND, 0]],  # 93:ヨーヨー（2014/8月イベント用）
      94  => [:find_group_profound,[106,0]],             # 94:ペンデュラム1
      95  => [:find_group_profound,[206,0]],             # 95:ペンデュラム2
      96  => [:find_group_profound,[206,0]],             # 96:ペンデュラム3
      97  => [:find_group_profound,[306,0]],             # 97:ペンデュラム4
      98  => [:find_group_profound,[306,0]],             # 98:ペンデュラム5
      99  => [:get_ev_land,[QM_RARE_LAND2, 0]],          # 99:ムネメの栞（R2）
      100 => [:not_use,0],                               # 100:投票券
      101 => [:not_use,0],                               # 101:投票券
      102 => [:not_use,0],                               # 102:投票券
      103 => [:not_use,0],                               # 103:投票券
      104 => [:not_use,0],                               # 104:投票券
      105 => [:not_use,0],                               # 105:投票券
      106 => [:not_use,0],                               # 106:投票券
      107 => [:not_use,0],                               # 107:投票券
      108 => [:not_use,0],                               # 108:投票券
      109 => [:not_use,0],                               # 109:投票券
      110 => [:not_use,0],                               # 110:投票券
      111 => [:not_use,0],                               # 111:投票券
      112 => [:not_use,0],                               # 112:投票券
      113 => [:not_use,0],                               # 113:投票券
      114 => [:not_use,0],                               # 114:投票券
      115 => [:not_use,0],                               # 115:投票券
      116 => [:not_use,0],                               # 116:投票券
      117 => [:not_use,0],                               # 117:投票券
      118 => [:not_use,0],                               # 118:投票券
      119 => [:not_use,0],                               # 119:投票券
      120 => [:not_use,0],                               # 120:投票券
      121 => [:not_use,0],                               # 121:投票券
      122 => [:not_use,0],                               # 122:投票券
      123 => [:not_use,0],                               # 123:投票券
      124 => [:not_use,0],                               # 124:投票券
      125 => [:not_use,0],                               # 125:投票券
      126 => [:not_use,0],                               # 126:投票券
      127 => [:not_use,0],                               # 127:投票券
      128 => [:event_quest_map_skip],                    # 128:古びた討魔の証
      129 => [:not_use,0],                               # 129:魔除けの仮面（青）
      130 => [:not_use,0],                               # 130:魔除けの仮面（赤）
      131 => [:not_use,0],                               # 131:魔除けの仮面（白）
      132 => [:not_use,0],                               # 132:聖杯のかけら
      133 => [:get_gems,1],                              # 133:妖精のブロック（黄）
      134 => [:get_gems,50],                             # 134:妖精のブロック（緑）
      135 => [:get_gems,100],                            # 135:妖精のブロック（青）
      136 => [:get_gems,200],                            # 136:妖精のブロック（赤）
      137 => [:get_gems,500],                            # 137:妖精のブロック（紫）
      138 => [:friend_max_up,10],                        # 138:チョコレート
      139 => [:reward_dice_amend,3],                     # 139:エヴァリストのクッキー
      140 => [:reward_dice_amend,3],                     # 140:グリュンワルドのクッキー
      141 => [:reward_dice_amend,3],                     # 141:アベルのクッキー
      142 => [:reward_dice_amend,3],                     # 142:リーズのクッキー
      143 => [:reward_dice_amend,3],                     # 143:イデリハのクッキー
      144 => [:reward_dice_amend,3],                     # 144:ディノのクッキー
      145 => [:reward_dice_amend,3],                     # 145:アイザックのクッキー
      146 => [:reward_dice_amend,3],                     # 146:ブレイズのクッキー
      150 => [:not_use,0],                               # 150:秘伝書の断片1
      151 => [:not_use,0],                               # 151:秘伝書の断片2
      152 => [:not_use,0],                               # 152:秘伝書の断片3
      153 => [:not_use,0],                               # 153:秘伝書の断片4
      154 => [:not_use,0],                               # 154:秘伝書の断片5
      155 => [:not_use,0],                               # 155:秘伝書の断片6
      156 => [:not_use,0],                               # 156:秘伝書の断片7
      157 => [:not_use,0],                               # 157:A中隊のタグ
      158 => [:not_use,0],                               # 158:B中隊のタグ
      159 => [:not_use,0],                               # 159:C中隊のタグ
      160 => [:not_use,0],                               # 160:D中隊のタグ
      161 => [:not_use,0],                               # 161:E中隊のタグ
      162 => [:not_use,0],                               # 162:タリスマンA
      163 => [:not_use,0],                               # 163:タリスマンB
      164 => [:not_use,0],                               # 164:タリスマンC
      165 => [:not_use,0],                               # 165:ドールアイ（橙）
      166 => [:not_use,0],                               # 166:ドールアイ（紫）
      167 => [:not_use,0],                               # 167:ドールアイ（金）
      168 => [:not_use,0],                               # 168:ドールアイ（虹）
      169 => [:not_use,0],                               # 169:
      170 => [:reward_dice_amend,3],                     # 170:投票券
      171 => [:reward_dice_amend,3],                     # 171:投票券
      172 => [:reward_dice_amend,3],                     # 172:投票券
      173 => [:reward_dice_amend,3],                     # 173:投票券
      174 => [:reward_dice_amend,3],                     # 174:投票券
      175 => [:reward_dice_amend,3],                     # 175:投票券
      176 => [:reward_dice_amend,3],                     # 176:投票券
      177 => [:reward_dice_amend,3],                     # 177:投票券
      178 => [:reward_dice_amend,3],                     # 178:投票券
      179 => [:reward_dice_amend,3],                     # 179:投票券
      180 => [:reward_dice_amend,3],                     # 180:投票券
      181 => [:reward_dice_amend,3],                     # 181:投票券
      182 => [:reward_dice_amend,3],                     # 182:投票券
      183 => [:reward_dice_amend,3],                     # 183:投票券
      184 => [:reward_dice_amend,3],                     # 184:投票券
      185 => [:reward_dice_amend,3],                     # 185:投票券
      186 => [:reward_dice_amend,3],                     # 186:投票券
      187 => [:reward_dice_amend,3],                     # 187:投票券
      188 => [:reward_dice_amend,3],                     # 188:投票券
      189 => [:reward_dice_amend,3],                     # 189:投票券
      190 => [:reward_dice_amend,3],                     # 190:投票券
      191 => [:reward_dice_amend,3],                     # 191:投票券
      192 => [:reward_dice_amend,3],                     # 192:投票券
      193 => [:reward_dice_amend,3],                     # 193:投票券
      194 => [:reward_dice_amend,3],                     # 194:投票券
      195 => [:reward_dice_amend,3],                     # 195:投票券
      196 => [:reward_dice_amend,3],                     # 196:投票券
      197 => [:reward_dice_amend,3],                     # 197:投票券
      198 => [:reward_dice_amend,3],                     # 198:投票券
      199 => [:reward_dice_amend,3],                     # 199:投票券
      200 => [:reward_dice_amend,3],                     # 200:投票券
      201 => [:reward_dice_amend,3],                     # 201:投票券
      202 => [:reward_dice_amend,3],                     # 202:投票券
      203 => [:reward_dice_amend,3],                     # 203:投票券
      204 => [:reward_dice_amend,3],                     # 204:投票券
      205 => [:reward_dice_amend,3],                     # 205:投票券
      206 => [:reward_dice_amend,3],                     # 206:投票券
      207 => [:reward_dice_amend,3],                     # 207:投票券
      208 => [:reward_dice_amend,3],                     # 208:投票券
      209 => [:reward_dice_amend,3],                     # 209:投票券
      210 => [:reward_dice_amend,3],                     # 210:投票券
      211 => [:reward_dice_amend,3],                     # 211:投票券
      212 => [:not_use,0],                               # 212:A中隊のタグ
      213 => [:not_use,0],                               # 213:F中隊のタグ
      214 => [:not_use,0],                               # 214:D中隊のタグ
      215 => [:not_use,0],                               # 215:E中隊のタグ
      216 => [:find_group_profound,[0,0]],               # 216:鋼鉄の歯車1
      217 => [:find_group_profound,[0,0]],               # 217:鋼鉄の歯車2
      218 => [:find_group_profound,[0,0]],               # 218:鋼鉄の歯車3
      219 => [:find_group_profound,[0,0]],               # 219:鋼鉄の歯車4
      220 => [:not_use,0],                               # 220:レッドチップ
      221 => [:not_use,0],                               # 221:ブルーチップ
      222 => [:not_use,0],                               # 222:コアの欠片（緑）
      223 => [:not_use,0],                               # 223:コアの欠片（青）
      224 => [:not_use,0],                               # 224:コアの欠片（赤）
      225 => [:not_use,0],                               # 225:コアの欠片（黄）
      226 => [:not_use,0],                               # 226:白真珠
      227 => [:not_use,0],                               # 227:黒真珠
      228 => [:not_use,0],                               # 228:ヴォランドのパネル
      229 => [:not_use,0],                               # 229:コッブのパネル
      230 => [:get_ev_land,[QM_EV_4th_LAND, 0]],         # 230:かぼちゃのたね
      231 => [:find_group_profound,[103,0]],             # 231:かぼちゃ
      232 => [:get_gems,4],                              # 232:アニバーサリーコイン 4GEM
      233 => [:get_ev_land,[QM_EV_INQUISITOR, 0]],       # 233:ケイオシウムカウンター
      234 => [:get_ev_land,[QM_EV_XMAS2014_LAND, 0]],    # 234:プレゼントボックス2014
      235 => [:not_use,0],                               # 235:ピンクのリボン
      236 => [:get_ev_land,[QM_EV_201504_LAND, 0]],      # 236:2015年4月イベントクエスト取得アイテム
      250 => [:find_group_profound,[9999,0]],            # 250: 渦探索アイテム1
      251 => [:find_group_profound,[9999,1]],            # 251: 渦探索アイテム2
      252 => [:find_group_profound,[9999,2]],            # 252: 渦探索アイテム3
      253 => [:find_group_profound,[9999,3]],            # 253: 渦探索アイテム4
      254 => [:find_group_profound,[9999,4]],            # 254: 渦探索アイテム5
      255 => [:find_group_profound,[9999,5]],            # 255: 渦探索アイテム6
      256 => [:find_group_profound,[9999,6]],            # 256: 渦探索アイテム7
      257 => [:find_group_profound,[9999,7]],            # 257: 渦探索アイテム8
      258 => [:find_group_profound,[9999,8]],            # 258: 渦探索アイテム9
      259 => [:find_group_profound,[9999,9]],            # 259: 渦探索アイテム10
      260 => [:not_use,0],                               # 260:
      300 => [:reward_dice_amend,3],                     # 301:投票券
      301 => [:reward_dice_amend,3],                     # 302:投票券
      302 => [:reward_dice_amend,3],                     # 303:投票券
      303 => [:reward_dice_amend,3],                     # 304:投票券
      304 => [:reward_dice_amend,3],                     # 305:投票券
      305 => [:reward_dice_amend,3],                     # 306:投票券
      306 => [:reward_dice_amend,3],                     # 307:投票券
      307 => [:reward_dice_amend,3],                     # 308:投票券
      308 => [:reward_dice_amend,3],                     # 309:投票券
      309 => [:reward_dice_amend,3],                     # 310:投票券
      310 => [:reward_dice_amend,3],                     # 311:投票券
      311 => [:reward_dice_amend,3],                     # 312:投票券
      312 => [:reward_dice_amend,3],                     # 313:投票券
      313 => [:reward_dice_amend,3],                     # 314:投票券
      314 => [:reward_dice_amend,3],                     # 315:投票券
      315 => [:reward_dice_amend,3],                     # 316:投票券
      316 => [:reward_dice_amend,3],                     # 317:投票券
      317 => [:reward_dice_amend,3],                     # 318:投票券
      318 => [:reward_dice_amend,3],                     # 319:投票券
      319 => [:reward_dice_amend,3],                     # 320:投票券
      320 => [:reward_dice_amend,3],                     # 321:投票券
      321 => [:reward_dice_amend,3],                     # 322:投票券
      322 => [:reward_dice_amend,3],                     # 323:投票券
      323 => [:reward_dice_amend,3],                     # 324:投票券
      324 => [:reward_dice_amend,3],                     # 325:投票券
      325 => [:reward_dice_amend,3],                     # 326:投票券
      326 => [:reward_dice_amend,3],                     # 327:投票券
      327 => [:reward_dice_amend,3],                     # 328:投票券
      328 => [:reward_dice_amend,3],                     # 329:投票券
      329 => [:reward_dice_amend,3],                     # 330:投票券
      330 => [:reward_dice_amend,3],                     # 331:投票券
      331 => [:reward_dice_amend,3],                     # 332:投票券
      332 => [:reward_dice_amend,3],                     # 333:投票券
      333 => [:reward_dice_amend,3],                     # 334:投票券
      334 => [:reward_dice_amend,3],                     # 335:投票券
      335 => [:reward_dice_amend,3],                     # 336:投票券
      336 => [:reward_dice_amend,3],                     # 337:投票券
      337 => [:reward_dice_amend,3],                     # 338:投票券
      338 => [:reward_dice_amend,3],                     # 339:投票券
      339 => [:reward_dice_amend,3],                     # 340:投票券
      340 => [:reward_dice_amend,3],                     # 341:投票券
      341 => [:reward_dice_amend,3],                     # 342:投票券
      342 => [:reward_dice_amend,3],                     # 343:投票券
      343 => [:reward_dice_amend,3],                     # 344:投票券
      344 => [:reward_dice_amend,3],                     # 345:投票券
      345 => [:reward_dice_amend,3],                     # 346:投票券
      346 => [:reward_dice_amend,3],                     # 347:投票券
      347 => [:reward_dice_amend,3],                     # 348:投票券
      348 => [:reward_dice_amend,3],                     # 349:投票券
      349 => [:reward_dice_amend,3],                     # 350:投票券
      350 => [:reward_dice_amend,3],                     # 351:投票券
      351 => [:not_use,0],                               # 352:道化師の鼻
      352 => [:not_use,0],                               # 353:日焼け止め
      353 => [:not_use,0],                               # 354:コアのかけら（8月イベントアイテム）
      354 => [:get_ev_land,[QM_EV_201508_LAND, 0]],      # 355:不気味な種（8月イベントアイテム）
      355 => [:find_group_profound,[106,0]],             # 356:ダウジングロッド1
      356 => [:find_group_profound,[206,0]],             # 357:ダウジングロッド2
      357 => [:find_group_profound,[206,0]],             # 358:ダウジングロッド3
      358 => [:find_group_profound,[306,0]],             # 359:ダウジングロッド4
      359 => [:find_group_profound,[306,0]],             # 360:ダウジングロッド5
      360 => [:find_group_profound,[106,0]],             # 361:ペンデュラム1
      361 => [:find_group_profound,[206,0]],             # 362:ペンデュラム2
      362 => [:find_group_profound,[206,0]],             # 363:ペンデュラム3
      363 => [:find_group_profound,[306,0]],             # 364:ペンデュラム4
      364 => [:find_group_profound,[306,0]],             # 365:ペンデュラム5
      365 => [:find_group_profound,[105,0]],             # 366:β型渦探知機1
      366 => [:find_group_profound,[205,0]],             # 367:β型渦探知機2
      367 => [:find_group_profound,[205,0]],             # 368:β型渦探知機3
      368 => [:find_group_profound,[305,0]],             # 369:β型渦探知機4
      369 => [:find_group_profound,[305,0]],             # 370:β型渦探知機5
      370 => [:not_use,0],                               # 371:かえるの置き物
      371 => [:not_use,0],                               # 372:バンテージ
      372 => [:not_use,0],                               # 373:15/10イベ弱ボス撃破
      373 => [:not_use,0],                               # 374:15/10イベ中ボス撃破
      374 => [:not_use,0],                               # 375:15/10イベ強ボス撃破
      375 => [:event_quest_get_boss],                    # 376:妖魔のコンパス（イベント）
      376 => [:not_use,0],                               # 377:15/11A
      377 => [:not_use,0],                               # 378:15/11B
      378 => [:get_ev_land,[QM_EV_XMAS2015_LAND, 0]],    # 379:プレゼントボックス2015
      379 => [:not_use,0],                               # 380:15/12B
      380 => [:not_use,0],                               # 381:ビクトリーコイン
      381 => [:get_ev_land,[QM_EV_201601_LAND, 0]],      # 382:16/01:イベントアイテムA
      382 => [:not_use,0],                               # 383:16/01:イベントアイテムB
      383 => [:not_use,0],                               # 384:16/02:イベントアイテムA
      384 => [:not_use,0],                               # 385:16/02:イベントアイテムB
      385 => [:not_use,0],                               # 386:16/03:イベントアイテムA
      386 => [:get_ev_land,[QM_EV_WHITE2016_LAND, 0]],   # 387:16/03:イベントアイテムB
      387 => [:not_use,0],                               # 388:16/04:イベントアイテム1
      388 => [:not_use,0],                               # 389:16/04:イベントアイテム2
      389 => [:not_use,0],                               # 390:16/04:イベントアイテム3
      390 => [:get_ev_land,[QM_EV_201605_LAND, 0]],      # 391:16/05:イベントアイテムA
      391 => [:not_use,0],                               # 392:16/05:イベントアイテムB
      392 => [:not_use,0],                               # 393:ちまき
      393 => [:not_use,0],                               # 394:16/07:イベントアイテムA
      394 => [:not_use,0],                               # 395:16/07:イベントアイテムB
      395 => [:not_use,0],                               # 396:16/07:イベントアイテムC
      396 => [:not_use,0],                               # 397:16/08:イベントアイテムA
      397 => [:not_use,0],                               # 398:16/08:イベントアイテムB
      398 => [:not_use,0],                               # 399:16/08:イベントアイテムC
      399 => [:not_use,0],                               # 400:16/09:イベントアイテム
      400 => [:not_use,0],                               # 401:16/10:イベントアイテム
      401 => [:reward_dice_amend,3],                               # 402:16/11:エヴァリスト投票券
      402 => [:reward_dice_amend,3],                               # 403:16/11:アイザック投票券
      403 => [:reward_dice_amend,3],                               # 404:16/11:グリュンワルド投票券
      404 => [:reward_dice_amend,3],                               # 405:16/11:アベル投票券
      405 => [:reward_dice_amend,3],                               # 406:16/11:レオン投票券
      406 => [:reward_dice_amend,3],                               # 407:16/11:クレーニヒ投票券
      407 => [:reward_dice_amend,3],                               # 408:16/11:ジェッド投票券
      408 => [:reward_dice_amend,3],                               # 409:16/11:アーチボルト投票券
      409 => [:reward_dice_amend,3],                               # 410:16/11:マックス投票券
      410 => [:reward_dice_amend,3],                               # 411:16/11:ブレイズ投票券
      411 => [:reward_dice_amend,3],                               # 412:16/11:シェリ投票券
      412 => [:reward_dice_amend,3],                               # 413:16/11:アイン投票券
      413 => [:reward_dice_amend,3],                               # 414:16/11:ベルンハルト投票券
      414 => [:reward_dice_amend,3],                               # 415:16/11:フリードリヒ投票券
      415 => [:reward_dice_amend,3],                               # 416:16/11:マルグリッド投票券
      416 => [:reward_dice_amend,3],                               # 417:16/11:ドニタ投票券
      417 => [:reward_dice_amend,3],                               # 418:16/11:スプラート投票券
      418 => [:reward_dice_amend,3],                               # 419:16/11:ベリンダ投票券
      419 => [:reward_dice_amend,3],                               # 420:16/11:ロッソ投票券
      420 => [:reward_dice_amend,3],                               # 421:16/11:エイダ投票券
      421 => [:reward_dice_amend,3],                               # 422:16/11:メレン投票券
      422 => [:reward_dice_amend,3],                               # 423:16/11:サルガド投票券
      423 => [:reward_dice_amend,3],                               # 424:16/11:レッドグレイヴ投票券
      424 => [:reward_dice_amend,3],                               # 425:16/11:リーズ投票券
      425 => [:reward_dice_amend,3],                               # 426:16/11:ミリアン投票券
      426 => [:reward_dice_amend,3],                               # 427:16/11:ウォーケン投票券
      427 => [:reward_dice_amend,3],                               # 428:16/11:フロレンス投票券
      428 => [:reward_dice_amend,3],                               # 429:16/11:パルモ投票券
      429 => [:reward_dice_amend,3],                               # 430:16/11:アスラ投票券
      430 => [:reward_dice_amend,3],                               # 431:16/11:ブロウニング投票券
      431 => [:reward_dice_amend,3],                               # 432:16/11:マルセウス投票券
      432 => [:reward_dice_amend,3],                               # 433:16/11:ルート投票券
      433 => [:reward_dice_amend,3],                               # 434:16/11:リュカ投票券
      434 => [:reward_dice_amend,3],                               # 435:16/11:ステイシア投票券
      435 => [:reward_dice_amend,3],                               # 436:16/11:ヴォランド投票券
      436 => [:reward_dice_amend,3],                               # 437:16/11:C.C.投票券
      437 => [:reward_dice_amend,3],                               # 438:16/11:コッブ投票券
      438 => [:reward_dice_amend,3],                               # 439:16/11:イヴリン投票券
      439 => [:reward_dice_amend,3],                               # 440:16/11:ブラウ投票券
      440 => [:reward_dice_amend,3],                               # 441:16/11:カレンベルク投票券
      441 => [:reward_dice_amend,3],                               # 442:16/11:ネネム投票券
      442 => [:reward_dice_amend,3],                               # 443:16/11:コンラッド投票券
      443 => [:reward_dice_amend,3],                               # 444:16/11:ビアギッテ投票券
      444 => [:reward_dice_amend,3],                               # 445:16/11:クーン投票券
      445 => [:reward_dice_amend,3],                               # 446:16/11:シャーロット投票券
      446 => [:reward_dice_amend,3],                               # 447:16/11:タイレル投票券
      447 => [:reward_dice_amend,3],                               # 448:16/11:ルディア投票券
      448 => [:reward_dice_amend,3],                               # 449:16/11:ヴィルヘルム投票券
      449 => [:reward_dice_amend,3],                               # 450:16/11:メリー投票券
      450 => [:reward_dice_amend,3],                               # 451:16/11:ギュスターヴ投票券
      451 => [:reward_dice_amend,3],                               # 452:16/11:ユーリカ投票券
      452 => [:reward_dice_amend,3],                               # 453:16/11:リンナエウス投票券
      453 => [:reward_dice_amend,3],                               # 454:16/11:ナディーン投票券
      454 => [:reward_dice_amend,3],                               # 455:16/11:ディノ投票券
      455 => [:reward_dice_amend,3],                               # 456:16/11:オウラン投票券
      456 => [:reward_dice_amend,3],                               # 457:16/11:ノイクローム投票券
      457 => [:reward_dice_amend,3],                               # 458:16/11:イデリハ投票券
      458 => [:reward_dice_amend,3],                               # 459:16/11:シラーリー投票券
      459 => [:reward_dice_amend,3],                               # 460:16/11:クロヴィス投票券
      460 => [:reward_dice_amend,3],                               # 461:16/11:アリステリア投票券
      461 => [:reward_dice_amend,3],                               # 462:16/11:ヒューゴ投票券
      462 => [:reward_dice_amend,3],                               # 463:16/11:アリアーヌ投票券
      463 => [:reward_dice_amend,3],                               # 464:16/11:グレゴール投票券
      464 => [:reward_dice_amend,3],                               # 465:16/11:レタ投票券
      465 => [:reward_dice_amend,3],                               # 466:16/11:エプシロン投票券
      466 => [:reward_dice_amend,3],                               # 467:16/11:ポレット投票券
      467 => [:reward_dice_amend,3],                               # 468:16/11:ユハニ投票券
      468 => [:reward_dice_amend,3],                               # 469:16/11:ノエラ投票券
      469 => [:reward_dice_amend,3],                               # 470:16/11:ラウル投票券
      470 => [:reward_dice_amend,3],                               # 471:16/11:ジェミー投票券
      471 => [:reward_dice_amend,3],                               # 472:16/11:セルファース投票券
      472 => [:reward_dice_amend,3],                               # 473:16/11:ベロニカ投票券
      473 => [:reward_dice_amend,3],                               # 474:16/11:リカルド投票券
      474 => [:reward_dice_amend,3],                               # 475:16/11:マリネラ投票券
      475 => [:reward_dice_amend,3],                               # 476:16/11:モーガン投票券
      476 => [:reward_dice_amend,3],                               # 477:16/11:ジュディス投票券
      477 => [:reward_dice_amend,3],                               # 478:16/11:イベントアイテム
      478 => [:not_use,0],                                         # 479:16/12:イベントアイテム
      479 => [:not_use,0],                                         # 480:17/01:イベント収集アイテム
      480 => [:get_ev_land,[QM_EV_201701_LAND, 0]],                # 481:17/01:イベントクエスト取得アイテム
      481 => [:not_use,0],                                         # 482:17/02:イベント収集アイテム
      482 => [:get_ev_land,[QM_EV_201702_LAND, 0]],                # 483:17/02:イベントクエスト取得アイテム
      483 => [:reward_dice_amend,3],                               # 484:17/02:イベントアイテム ホワイトヒース3
      484 => [:reward_dice_amend,3],                               # 485:17/02:イベントアイテム ホワイトヒース3
      485 => [:reward_dice_amend,3],                               # 486:17/02:イベントアイテム ホワイトヒース3
      486 => [:reward_dice_amend,3],                               # 487:17/02:イベントアイテム ホワイトヒース3
      487 => [:reward_dice_amend,3],                               # 488:17/02:イベントアイテム ホワイトヒース3
      488 => [:reward_dice_amend,3],                               # 489:17/02:イベントアイテム ホワイトヒース3
      489 => [:not_use,0],                                         # 490:17/02:イベント収集アイテム
      490 => [:get_ev_land,[QM_EV_201703_LAND, 0]],                # 491:17/02:イベントクエスト取得アイテム
      491 => [:reward_dice_amend,3],                               # 492:17/02:イベントアイテム ホワイトヒース3
      492 => [:reward_dice_amend,3],                               # 493:17/02:イベントアイテム ホワイトヒース3
      493 => [:reward_dice_amend,3],                               # 494:17/02:イベントアイテム ホワイトヒース3
      494 => [:reward_dice_amend,3],                               # 495:17/02:イベントアイテム ホワイトヒース3
      495 => [:reward_dice_amend,3],                               # 496:17/02:イベントアイテム ホワイトヒース3
      496 => [:reward_dice_amend,3],                               # 497:17/02:イベントアイテム ホワイトヒース3
      600 => [:not_use,0],                                         # 490:17/04:イベント収集アイテム
      601 => [:not_use,0],                                         # 490:17/04:イベント収集アイテム
      602 => [:not_use,0],                                         # 490:17/04:イベント収集アイテム
      603 => [:not_use,0],                                         # 490:17/04:イベント収集アイテム
      604 => [:not_use,0],                                         # 490:17/04:イベント収集アイテム
      605 => [:reward_dice_amend,3],                               # 605:翠色の硝子玉
      606 => [:get_ev_land,[QM_EV_201707_LAND, 0]],                # 481:17/07:イベントクエスト取得アイテム
      607 => [:not_use,0],                                         # 482:17/07:イベント収集アイテム
    }

    # クエストマップNoを参照するメソッドリスト
    USE_QUEST_MAP_NO_METHOD = [:quest_get_boss,:event_quest_get_boss,:quest_map_skip,:event_quest_map_skip]

    # アイテムを使う。種類によって呼び出す関数を変えるOKの場合0失敗の場合エラーコードを返す(-1はエラーコードなし)

    def use(avatar,quest_map_no)
      ret = false
      @owner = avatar
      if avatar
        if ITEM_EFFECTS[self.item_no]
          # 1があるとき引数となる値があるので渡す
          if ITEM_EFFECTS[self.item_no][1]
            ret = self.send(ITEM_EFFECTS[self.item_no][0],ITEM_EFFECTS[self.item_no][1])
          elsif USE_QUEST_MAP_NO_METHOD.include?(ITEM_EFFECTS[self.item_no][0])
            ret = self.send(ITEM_EFFECTS[self.item_no][0],quest_map_no)
          else
            ret = self.send(ITEM_EFFECTS[self.item_no][0])
          end
        end
      end
      ret
    end

    # 行動力回復
    def heal_ap(v)
      if @owner
        if @owner.recovery_energy(v)
          0
        else
          -1
        end
      else
        -1
      end
    end

    # 限界を突破して行動力回復
    def heal_ap_force(v)
      if @owner
        if @owner.recovery_energy_force(v)
          0
        else
          -1
        end
      else
        -1
      end
    end

    # AP上限+1
    def ap_max_up(v)
      if @owner
        @owner.inc_ap_max(v)
      else
        -1
      end
    end

    # 報酬ゲームリロール
    def reward_dice_reroll
      if @owner && @owner.get_reward && @owner.get_reward.lose

        if @owner.get_reward.reroll_event
          0
        else
          -1
        end
      else
        -1
      end
    end

    # 報酬ゲームのダイスを補正
    def reward_dice_amend(v)
      if @owner && @owner.get_reward && @owner.get_reward.lose
        if @owner.get_reward.amend_event(v)
          0
        else
          -1
        end
      else
        -1
      end
    end

    # チケットを追買う
    def ticket_use(v)
        0
    end

    # 使用不可アイテム
    def not_use(v)
        -1
    end

    # クエスト探索の時間を進める
    def quest_time_go(v)
      if @owner && @owner.quest_pending?
        @owner.quest_time_go(v)
      else
        -1
      end
    end

    # 現在の進行中のクエストでHPを全回復させる
    def quest_chara_all_heal
      if @owner && @owner.quest_inprogress? && @owner.quest_dameged?
        @owner.quest_chara_all_heal
      else
        -1
      end
    end

    # 現在の進行中のクエストでHPを回復させる
    def quest_chara_heal(v)
      if @owner&&@owner.quest_inprogress?  && @owner.quest_dameged?
        @owner.quest_chara_heal(v)
      else
        -1
      end
    end

    # クエストMAXを増やす
    def quest_max_up(v)
      if @owner
        -1
      else
        -1
      end
    end

    # フレンドMAXを増やす
    def friend_max_up(v)
      if @owner
        @owner.inc_friend_max(v)
      else
        -1
      end
    end

    # パーツMAXを増やす
    def part_max_up(v)
      if @owner
        @owner.inc_part_max(v)
      else
        -1
      end
    end

    # クエストをリスタート
    def quest_restart()
      if @owner&&@owner.quest_progress_and_start?
        @owner.quest_restart
      else
        -1
      end
    end

    # クエストの進行度を増やす
    def quest_skip(v)
      if @owner && !@owner.quest_clear_capaciry? && @owner.quest_flag_capaciry?
        @owner.inc_quest_clear_num(v)
      else
        -1
      end
    end

    # クエストのマップ進行度を増やす
    def quest_map_skip(v)
      return ERROR_ITEM_UNABLE_MAP if v >= QUEST_TUTORIAL_MAP_START # 通常クエスト画面じゃない場合はエラー
      if @owner && @owner.quest_flag_capaciry?
        @owner.inc_quest_map_clear_num(1) # 1しか進ませない
      else
        -1
      end
    end

    # イベントクエストのマップ進行度を増やす
    def event_quest_map_skip(v)
      return ERROR_ITEM_UNABLE_MAP if v < QUEST_EVENT_MAP_START || v >= QUEST_CHARA_VOTE_MAP_START # イベントクエスト画面じゃない場合はエラー
      if @owner && @owner.quest_flag_capaciry?(QUEST_EVENT_MAP_START)
        @owner.inc_event_quest_map_clear_num(1) # 1しか進ませない
      else
        -1
      end
    end

    # 現在のクエストのボスをランダムに獲得
    def quest_get_boss(v)
      return ERROR_ITEM_UNABLE_MAP if v >= QUEST_TUTORIAL_MAP_START # 通常クエスト画面じゃない場合はエラー
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_boss_quest(v)
      else
        if @owner.quest_inventory_capacity?
          ERROR_MAX_QUEST
        elsif @owner.quest_flag_capaciry?
          ERROR_ITEM_NOT_BOSS_FLAG
        else
          -1
        end
      end
    end

    # イベントクエストのボスをランダムに獲得
    def event_quest_get_boss(v)
      return ERROR_ITEM_UNABLE_MAP if v < QUEST_EVENT_MAP_START || v >= QUEST_CHARA_VOTE_MAP_START # イベントクエスト画面じゃない場合はエラー
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_boss_quest(v)
      else
        if @owner.quest_inventory_capacity?
          ERROR_MAX_QUEST
        elsif @owner.quest_flag_capaciry?
          ERROR_ITEM_NOT_BOSS_FLAG
        else
          -1
        end
      end
    end

    # EXShadowLandのクエストを獲得
    def get_ex_shadow_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EX_SHADOW_LAND, v)
      else
        -1
      end
    end

    # EXMoonLandのクエストを獲得
    def get_ex_moon_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EX_MOON_LAND, v)
      else
        -1
      end
    end

    # EXAnemoneaのクエストを獲得
    def get_ex_anemonea(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EX_ANEMONEA, v)
      else
        -1
      end
    end

    # EXXmasLandのクエストを獲得
    def get_ev_xmas_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_XMAS_LAND, v)
      else
        -1
      end
    end

    # EXValentineLandのクエストを獲得
    def get_ev_valentine_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_VALENTINE_LAND, v)
      else
        -1
      end
    end

    # EXWhiteLandのクエストを獲得
    def get_ev_white_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_WHITE_LAND, v)
      else
        -1
      end
    end

    # EXCodexLandのクエストを獲得
    def get_ev_codex_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_CODEX_LAND, v)
      else
        -1
      end
    end

    # EXArkLandのクエストを獲得
    def get_ev_ark_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_ARK_LAND, v)
      else
        -1
      end
    end

    # EXAcolyteLandのクエストを獲得
    def get_ev_acolyte_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(QM_EV_ACOLYTE_LAND, v)
      else
        -1
      end
    end

    # EventLandのクエストを獲得
    def get_ev_land(v)
      if @owner && not(@owner.quest_inventory_capacity?)
        @owner.get_ex_quest(v[0], v[1])
      else
        -1
      end
    end

    # 勝敗をリセットする
    def reset_result(v)
      if @owner
        @owner.reset_result
      else
        -1
      end
    end

    # BPをリセットする
    def reset_bp(v)
      if @owner
        @owner.reset_bp
      else
        -1
      end
    end

    # GEM獲得
    def get_gems(v)
      if @owner
        @owner.set_gems(v)
      else
        -1
      end
    end

    # 渦を探し出す
    def find_map_profound(v)
      if @owner
        # 渦所持数をチェック
        if @owner.get_prf_inv_num < PROFOUND_MAX
          pr = Profound::get_new_profound_for_map(@owner.id,v[0],@owner.server_type,v[1])
          if pr
            inv = @owner.get_profound(pr, true)
            (inv.instance_of?(ProfoundInventory)) ? 0 : -1
          else
            ERROR_PRF_DATA_NOT_EXIST
          end
        else
          ERROR_PRF_HAVE_MAX_OVER
        end
      else
        -1
      end
    end
    # 渦を探し出す
    def find_group_profound(v)
      if @owner
        # 渦所持数をチェック
        if @owner.get_prf_inv_num < PROFOUND_MAX
          pr = Profound::get_new_profound_for_group(@owner.id,v[0],@owner.server_type,v[1])
          if pr
            inv = @owner.get_profound(pr, true)
            (inv.instance_of?(ProfoundInventory)) ? 0 : -1
          else
            ERROR_PRF_DATA_NOT_EXIST
          end
        else
          ERROR_PRF_HAVE_MAX_OVER
        end
      else
        -1
      end
    end

    # 新しいデッキ獲得
    def get_new_deck(v)
      if @owner
        @owner.create_deck(v)
      else
        -1
      end
    end

  end
end
