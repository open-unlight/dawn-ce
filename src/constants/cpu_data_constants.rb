#
# 定数モジュール
#

module Unlight
  # ==============CPUキャラ定数 ==================
  CPU_CHARA_CARDS = [
    [0000], # Monster No.00 モンスターなし
    [1000],         # Monster No.01 森の小人1体
    [1003],         # Monster No.02 蝙蝠1体
    [1006],         # Monster No.03 大蛙1体
    [1009] # Monster No.04 鬼火1体
  ]

  CPU_WEAPON_CARDS = [
    [[], [], []], # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []] # Monster No.00
  ]

  CPU_EQUIP_CARDS = [
    [[], [], []], # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []],       # Monster No.00
    [[], [], []] # Monster No.00
  ]

  CPU_EVENT_CARDS = [
    [[1, 1, 1, 2, 2, 2], [], []], # Monster No.00
    [[1, 1, 1, 2, 2, 2], [], []],             # Monster No.01
    [[1, 1, 1, 2, 2, 2], [], []],             # Monster No.02
    [[1, 1, 1, 2, 2, 2], [], []],             # Monster No.03
    [[1, 1, 1, 2, 2, 2], [], []] # Monster No.04
  ]

  LAND_TREASURE = [
    [TG_NONE, 0, 0], #  No.00
    [TG_CHARA_CARD, 0, 1],                #  No.00
    [TG_SLOT_CARD, SCT_EVENT, 1],         #  No.00
    [TG_AVATAR_ITEM, 0, 1],               #  No.00
    [TG_AVATAR_PART, 0, 1],               #  No.00
    [TG_GEM, 0, 100] # No.00
  ]

  # 1000000が基数
  MAP_REALITY = [[
    1_000_000, # Reality 1 32%
    679_287,         # Reality 2 26%
    415_285,         # Reality 3 17%
    236_395,         # Reality 4 12%
    115_177,         # Reality 5  6%
    47_563,          # Reality 6  3%
    16_517,          # Reality 7  1%
    4783,           # Reality 8  0.3%
    1132,           # Reality 9  0.1%
    197 # Reality 10 0.02%
  ],
                 [
                   1_000_000, # Reality 1 23%
                   770_500,         # Reality 2 28%
                   491_699,         # Reality 3 20%
                   291_424,         # Reality 4 14%
                   150_330,         # Reality 5  8%
                   66_898,          # Reality 6  4%
                   25_489,          # Reality 7  2%
                   8238,           # Reality 8  1%
                   2206,           # Reality 9  0.17%
                   436             # Reality 10 0.04%
                 ],
                 [
                   1_000_000, # Reality 1 20%
                   802_410,         # Reality 2 24%
                   562_374,         # Reality 3 22%
                   345_860,         # Reality 4 16%
                   187_889,         # Reality 5 10%
                   89_438,          # Reality 6  5%
                   37_028,          # Reality 7  2%
                   13_197,          # Reality 8  1%
                   3941, # Reality 9  0.3%
                   870 # Reality 10 0.08%
                 ],
                 [
                   1_000_000, # Reality 1 13%
                   870_784,         # Reality 2 19%
                   680_091,         # Reality 3 23%
                   448_434,         # Reality 4 19%
                   255_313,         # Reality 5 13%
                   129_128,         # Reality 6  7%
                   57_584,          # Reality 7  4%
                   22_385,          # Reality 8  2%
                   7357, # Reality 9  0.6%
                   1790 # Reality 10 0.18%
                 ],
                 [
                   1_000_000, # Reality 1 9%
                   911_445,         # Reality 2 13%
                   780_759,         # Reality 3 19%
                   587_895,         # Reality 4 23%
                   353_601,         # Reality 5 16%
                   188_855,         # Reality 6 10%
                   89_994,          # Reality 7  5%
                   37_779,          # Reality 8  2%
                   13_507,          # Reality 9  1%
                   3576 # Reality 10 0.35%
                 ],
                 [
                   1_000_000, # Reality 1 8%
                   920_825,          # Reality 2 12%
                   803_982,          # Reality 3 17%
                   631_547,          # Reality 4 21%
                   422_071,          # Reality 5 19%
                   236_721,          # Reality 6 12%
                   119_667,          # Reality 7  7%
                   53_769,           # Reality 8  3%
                   20_697,           # Reality 9  1.5%
                   5901 # Reality 10 0.6%
                 ],
                 [
                   1_000_000, # Reality 1 5%
                   953_251,          # Reality 2 8%
                   869_439,          # Reality 3 12%
                   745_753,          # Reality 4 18%
                   563_219,          # Reality 5 22%
                   341_475,          # Reality 6 16%
                   181_928,          # Reality 7 10%
                   86_796,           # Reality 8  5%
                   35_645,           # Reality 9  2%
                   10_844 # Reality 10 1%

                 ],
                 [
                   1_000_000, # Reality 1 4%
                   957_955,          # Reality 2 8%
                   882_577,          # Reality 3 11%
                   771_336,          # Reality 4 16%
                   607_170,          # Reality 5 20%
                   407_738,          # Reality 6 18%
                   227_588,          # Reality 7 11%
                   114_470,          # Reality 8  6%
                   49_755,           # Reality 9  3%
                   16_021 # Reality 10 2%
                 ],
                 [
                   1_000_000, # Reality 1 2%
                   978_993,          # Reality 2 5%
                   933_241,          # Reality 3 8%
                   851_217,          # Reality 4 12%
                   730_168,          # Reality 5 18%
                   551_528,          # Reality 6 22%
                   334_513,          # Reality 7 16%
                   176_257,          # Reality 8 10%
                   80_517,           # Reality 9  5%
                   27_253            # Reality 10 3%
                 ],
                 [
                   1_000_000, # Reality 1 2%
                   980_995,          # Reality 2 4%
                   939_603,          # Reality 3 7%
                   865_395,          # Reality 4 11%
                   755_882,          # Reality 5 16%
                   594_266,          # Reality 6 20%
                   397_932,          # Reality 7 18%
                   218_422,          # Reality 8 11%
                   104_227,          # Reality 9  7%
                   36_858 # Reality 10 4%
                 ],
                 [
                   1_000_000, # Reality 1 1%
                   992_016,          # Reality 2 2%
                   970_892,          # Reality 3 5%
                   924_886,          # Reality 4 8%
                   842_407,          # Reality 5 12%
                   720_687,          # Reality 6 18%
                   541_055,          # Reality 7 22%
                   322_836,          # Reality 8 16%
                   160_061,          # Reality 9 10%
                   58_828           # Reality 10 6%
                 ]]

  MAP_REALITY_NUM = 1_000_000
end
