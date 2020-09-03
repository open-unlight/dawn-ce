# -*- coding: utf-8 -*-
#
#定数モジュール
#

module Unlight
  # ==============CPUキャラ定数 ==================
  CPU_CHARA_CARDS = [
                     [0000],         # Monster No.00 モンスターなし
                     [1000],         # Monster No.01 森の小人1体
                     [1003],         # Monster No.02 蝙蝠1体
                     [1006],         # Monster No.03 大蛙1体
                     [1009],         # Monster No.04 鬼火1体
                ]

  CPU_WEAPON_CARDS = [
                      [[],[],[]],       # Monster No.00
                      [[],[],[]],       # Monster No.00
                      [[],[],[]],       # Monster No.00
                      [[],[],[]],       # Monster No.00
                      [[],[],[]],       # Monster No.00
                     ]

  CPU_EQUIP_CARDS = [
                     [[],[],[]],       # Monster No.00
                     [[],[],[]],       # Monster No.00
                     [[],[],[]],       # Monster No.00
                     [[],[],[]],       # Monster No.00
                     [[],[],[]],       # Monster No.00
                    ]

  CPU_EVENT_CARDS = [
                     [[1,1,1,2,2,2],[],[]],             # Monster No.00
                     [[1,1,1,2,2,2],[],[]],             # Monster No.01
                     [[1,1,1,2,2,2],[],[]],             # Monster No.02
                     [[1,1,1,2,2,2],[],[]],             # Monster No.03
                     [[1,1,1,2,2,2],[],[]],             # Monster No.04
                    ]

  LAND_TREASURE = [
                   [TG_NONE, 0, 0],                      #  No.00
                   [TG_CHARA_CARD, 0, 1],                #  No.00
                   [TG_SLOT_CARD, SCT_EVENT, 1],         #  No.00
                   [TG_AVATAR_ITEM, 0, 1],               #  No.00
                   [TG_AVATAR_PART, 0, 1],               #  No.00
                   [TG_GEM, 0, 100],                     # No.00
                  ]

  # 1000000が基数
  MAP_REALITY=[[
                1000000,        # Reality 1 32%
                679287,         # Reality 2 26%
                415285,         # Reality 3 17%
                236395,         # Reality 4 12%
                115177,         # Reality 5  6%
                47563,          # Reality 6  3%
                16517,          # Reality 7  1%
                4783,           # Reality 8  0.3%
                1132,           # Reality 9  0.1%
                197,            # Reality 10 0.02%
               ],
               [
                1000000,        # Reality 1 23%
                770500,         # Reality 2 28%
                491699,         # Reality 3 20%
                291424,         # Reality 4 14%
                150330,         # Reality 5  8%
                66898,          # Reality 6  4%
                25489,          # Reality 7  2%
                8238,           # Reality 8  1%
                2206,           # Reality 9  0.17%
                436             # Reality 10 0.04%
               ],
               [
                1000000,        # Reality 1 20%
                802410,         # Reality 2 24%
                562374,         # Reality 3 22%
                345860,         # Reality 4 16%
                187889,         # Reality 5 10%
                89438,          # Reality 6  5%
                37028,          # Reality 7  2%
                13197,          # Reality 8  1%
                3941,           # Reality 9  0.3%
                870,            # Reality 10 0.08%
                ],
               [
                1000000,        # Reality 1 13%
                870784,         # Reality 2 19%
                680091,         # Reality 3 23%
                448434,         # Reality 4 19%
                255313,         # Reality 5 13%
                129128,         # Reality 6  7%
                57584,          # Reality 7  4%
                22385,          # Reality 8  2%
                7357,           # Reality 9  0.6%
                1790,           # Reality 10 0.18%
                ],
               [
                1000000,        # Reality 1 9%
                911445,         # Reality 2 13%
                780759,         # Reality 3 19%
                587895,         # Reality 4 23%
                353601,         # Reality 5 16%
                188855,         # Reality 6 10%
                89994,          # Reality 7  5%
                37779,          # Reality 8  2%
                13507,          # Reality 9  1%
                3576,           # Reality 10 0.35%
                ],
               [
                1000000,         # Reality 1 8%
                920825,          # Reality 2 12%
                803982,          # Reality 3 17%
                631547,          # Reality 4 21%
                422071,          # Reality 5 19%
                236721,          # Reality 6 12%
                119667,          # Reality 7  7%
                53769,           # Reality 8  3%
                20697,           # Reality 9  1.5%
                5901,            # Reality 10 0.6%
                ],
               [
                1000000,         # Reality 1 5%
                953251,          # Reality 2 8%
                869439,          # Reality 3 12%
                745753,          # Reality 4 18%
                563219,          # Reality 5 22%
                341475,          # Reality 6 16%
                181928,          # Reality 7 10%
                86796,           # Reality 8  5%
                35645,           # Reality 9  2%
                10844,           # Reality 10 1%

               ],
               [
                1000000,         # Reality 1 4%
                957955,          # Reality 2 8%
                882577,          # Reality 3 11%
                771336,          # Reality 4 16%
                607170,          # Reality 5 20%
                407738,          # Reality 6 18%
                227588,          # Reality 7 11%
                114470,          # Reality 8  6%
                49755,           # Reality 9  3%
                16021,           # Reality 10 2%
                ],
               [
                1000000,         # Reality 1 2%
                978993,          # Reality 2 5%
                933241,          # Reality 3 8%
                851217,          # Reality 4 12%
                730168,          # Reality 5 18%
                551528,          # Reality 6 22%
                334513,          # Reality 7 16%
                176257,          # Reality 8 10%
                80517,           # Reality 9  5%
                27253            # Reality 10 3%
                ],
               [
                1000000,         # Reality 1 2%
                980995,          # Reality 2 4%
                939603,          # Reality 3 7%
                865395,          # Reality 4 11%
                755882,          # Reality 5 16%
                594266,          # Reality 6 20%
                397932,          # Reality 7 18%
                218422,          # Reality 8 11%
                104227,          # Reality 9  7%
                36858,           # Reality 10 4%
                ],
               [
                1000000,         # Reality 1 1%
                992016,          # Reality 2 2%
                970892,          # Reality 3 5%
                924886,          # Reality 4 8%
                842407,          # Reality 5 12%
                720687,          # Reality 6 18%
                541055,          # Reality 7 22%
                322836,          # Reality 8 16%
                160061,          # Reality 9 10%
                58828,           # Reality 10 6%
               ],

              ]

  MAP_REALITY_NUM = 1000000



end

