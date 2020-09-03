# -*- coding: utf-8 -*-
#
#定数モジュール
#

module Unlight
  # ============== ボーナス関連定数 ==================
  GENRE_ODDS = { :exp =>250,:gem =>250, :item =>200, :own_card =>300, :random_card=>15,:rare_card=>0, :event_card=>200, :weapon_card=>2,:wild_item=>1500}
  GENRE_ODDS_QUEST = { :exp =>300,:gem =>250, :item =>200, :own_card =>100, :random_card=>7,:rare_card=>0, :event_card=>50, :weapon_card=>2,:wild_item=>1500 }
  START_END_TABLE = [
                     [1,  20], # 1VS1 LOSE
                     [21, 50], # 1VS1 WIN
                     [51, 70], # 3VS3 LOSE
                     [71, 100], # 3VS3 WIN
                     [101, 140], # CPU LOSE (枠40)
                     [141, 200], # CPU WIN（枠60）
                    ]
  # 特殊アイテムをゲットできるか
  WILD_ITEM_GET = [
                     false, # 1VS1 LOSE
                     false, # 1VS1 WIN
                     true, # 3VS3 LOSE
                     true, # 3VS3 WIN
                     false, # CPU LOSE (枠40)
                     false, # CPU WIN（枠60）
                  ]

  RESULT_1VS1_LOSE = 0
  RESULT_1VS1_WIN  = 1
  RESULT_3VS3_LOSE = 2
  RESULT_3VS3_WIN  = 3
  RESULT_CPU_LOSE  = 4
  RESULT_CPU_WIN   = 5

  LEVEL_CAP_LOSE = [[0, 0],              # LV0(未使用)すべて幅10
                    [0,10],              # LV1
                    [4,14],              # LV2
                    [8,18],              # LV3
                    [16,26],             # LV4
                    [20,30],             # LV5
                    [24,34],             # LV6
                    [28,38],             # LV7
                    [32,39],             # LV8
                   ]

  LEVEL_CAP_WIN = [ [0,25],              # LV0(未使用)幅25
                    [0,25],              # LV1 幅25
                    [4,29],              # LV2 幅25
                    [8,34],              # LV3
                    [12,37],             # LV4
                    [16,41],             # LV5
                    [20,45],             # LV6
                    [24,45],             # LV7
                    [28,45],             # LV8
                   ]

  # ============== イベントアイテムの設定 ==================

  # # イベントアイテムがでるか
  # EVENT_REWARD_ENABLE = true

  # 出現アイテム
  EVENT_REWARD_ITEM = [
                       [],
                       [],
                       [490],
                       [490],
                       [],
                       [],
                       ]

  # CPUの場合の個数
  EVENT_REWARD_NUM_IDX = 2
  EVENT_REWARD_CPU_NUM = 1

  # 出現ステップ
  EVENT_REWARD_ITEM_STEPS = [6,11,21]
  # 出現ステップに対する個数
  EVENT_REWARD_ITEM_STEP_NUM = [1,2,4]

  #
  EVENT_CHARA_IDS = [1,2,3,4,5,6,7,8,9,10,13,14,17,19,21,22,24,25,26,29,30,31,32,33,35,37,39,40,42,44,46,48,50,52,54,55,56,58,60,62,64,66,68,70,72,74,76,4001,4002,4003,4004,4005,4006,4007,4008,4010,4013,4014,4019,4022,4024,4026,5001]

  # 特定キャラ指定ステップ
  EVENT_CHARA_REWARD_ITEM_STEPS = [6,11,21]
  # 特定キャラ指定ステップに対する個数
  EVENT_CHARA_REWARD_ITEM_STEP_NUM = [1,3,7]

end
