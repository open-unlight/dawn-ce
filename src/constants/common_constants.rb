# -*- coding: utf-8 -*-

#
# クライアント共有定数モジュール
#
module Unlight
  # ============== AVATAR関連定数 ==================
  #                   0   1   2   3   4    5    6    7     8     9    10
  LEVEL_EXP_TABLE = [
    0, # 1
    10,       # 2
    30,       # 3
    60,       # 4
    105,      # 5
    165,      # 6
    240,      # 7
    330,      # 8
    440,      # 9
    570,      # 10
    720,      # 11
    900,      # 12
    1110,     # 13
    1350,     # 14
    1620,     # 15
    1920,     # 16
    2260,     # 17
    2640,     # 18
    3060,     # 19
    3520,     # 20
    4020,     # 21
    4570,     # 22
    5170,     # 23
    5820,     # 24
    6520,     # 25
    7290,     # 26
    8130,    # 27
    9040,    # 28
    10020,   # 29
    11070,   # 30
    12190,   # 31
    13390,   # 32
    14670,   # 33
    16030,   # 34
    17470,   # 35
    18990,   # 36
    20590,   # 37
    22290,   # 38
    24090,    # 39
    25990,    # 40
    27990,    # 41
    30090,    # 42
    32290,    # 43
    34590,    # 44
    37040,    # 45
    39640,    # 46
    42390,    # 47
    45290,    # 48
    48340,    # 49
    51540,    # 50
    54940,    # 51
    58540,    # 52
    62340,    # 53
    66340,    # 54
    70540,    # 55
    75040,    # 56
    79840,    # 57
    84940,    # 58
    90340,    # 59
    96040,    # 60
    102240,    # 61
    108940,    # 62
    116140,    # 63
    123840,    # 64
    132040,    # 65
    140940,    # 66
    150540,    # 67
    160840,    # 68
    171840,    # 69
    183540,    # 70
    195940,    # 71
    209040,    # 72
    222840,    # 73
    237340,    # 74
    252540,    # 75
    268440,    # 76
    285040,    # 77
    302340,    # 78
    320340,    # 79
    339040,    # 80
    358440,    # 81
    378540,    # 82
    399340,    # 83
    420840,    # 84
    443040,    # 85
    465940,    # 86
    489540,    # 87
    513840,    # 88
    538840,    # 89
    564540,    # 90
    590940,    # 91
    618040,    # 92
    645840,    # 93
    674340,    # 94
    703540,    # 95
    733440,    # 96
    764040,    # 97
    795340,    # 98
    827340,    # 99
    860040,    # 100
    893980,    # 101
    929480,    # 102
    967480,    # 103
    1008300,   # 104
    1052050,   # 105
    1098550,   # 106
    1147470,   # 107
    1199320,   # 108
    1253890,   # 109
    1311180,   # 110
    1371190,   # 111
    1433920,   # 112
    1499370,   # 113
    1567530,   # 114
    1638400,   # 115
    1711980,   # 116
    1788270,   # 117
    1867270,   # 118
    1948970,   # 119
    2033370,   # 120
    2120470,   # 121
    2210270,   # 122
    2302750,   # 123
    2397910,   # 124
    2495750,   # 125
    2596270,   # 126
    2699470,   # 127
    2805350,   # 128
    2913900,   # 129
    3025120,   # 130
    3139010,   # 131
    3255570,   # 132
    3374800,   # 133
    3496700,   # 134
    3621250,   # 135
    3748450,   # 136
    3878300,   # 137
    4010800,   # 138
    4145950,   # 139
    4283750,   # 140
    4424200,   # 141
    4567250,   # 142
    4712900,   # 143
    4861150,   # 144
    5012000,   # 145
    5165450,   # 146
    5321500,   # 147
    5480100,   # 148
    5641250,   # 149
    5804950,   # 150
    9999999999, # 151 # 2014/03/03 151にならないよう一時的処置 yamagishi
    # 5971200,   # 151
  ]

  LEVEL_ENG_BOUNUS = [
    0, # 1
    1,        # 2
    0,        # 3
    1,        # 4
    0,        # 5
    1,        # 6
    0,        # 7
    1,        # 8
    0,        # 9
    1,        # 10
    0,        # 11
    0,        # 12
    1,        # 13
    0,        # 14
    0,        # 15
    0,        # 16
    1,        # 17
    0,        # 18
    0,        # 19
    0,        # 20
    1,        # 21
    0,        # 22
    0,        # 23
    0,        # 24
    0,        # 25
    1,        # 26
    0,        # 27
    0,        # 28
    0,        # 29
    0,        # 30
    1,        # 31
    0,        # 32
    0,        # 33
    0,        # 34
    0,        # 35
    1,        # 36
    0,        # 37
    0,        # 38
    0,        # 39
    0,        # 40
    1,        # 41
    0,        # 42
    0,        # 43
    0,        # 44
    0,        # 45
    1,        # 46
    0,        # 47
    0,        # 48
    0,        # 49
    0,        # 50
    1,        # 51
    0,        # 52
    0,        # 53
    0,        # 54
    0,        # 55
    1,        # 56
    0,        # 57
    0,        # 58
    0,        # 59
    0,        # 60
    1,        # 61
    0,        # 62
    0,        # 63
    0,        # 64
    0,        # 65
    1,        # 66
    0,        # 67
    0,        # 68
    0,        # 69
    0,        # 70
    0,        # 71
    0,        # 72
    1,        # 73
    0,        # 74
    0,        # 75
    0,        # 76
    0,        # 77
    0,        # 78
    0,        # 79
    1,        # 80
    0,        # 81
    0,        # 82
    0,        # 83
    0,        # 84
    0,        # 85
    0,        # 86
    0,        # 87
    0,        # 88
    0,        # 89
    1,        # 90
    0,        # 91
    0,        # 92
    0,        # 93
    0,        # 94
    0,        # 95
    0,        # 96
    0,        # 97
    0,        # 98
    0,        # 99
    1,   # 100
    0,   # 101
    0,   # 102
    0,   # 103
    0,   # 104
    0,   # 105
    0,   # 106
    0,   # 107
    0,   # 108
    0,   # 109
    1,   # 110
    0,   # 111
    0,   # 112
    0,   # 113
    0,   # 114
    0,   # 115
    0,   # 116
    0,   # 117
    0,   # 118
    0,   # 119
    1,   # 120
    0,   # 121
    0,   # 122
    0,   # 123
    0,   # 124
    0,   # 125
    0,   # 126
    0,   # 127
    0,   # 128
    0,   # 129
    1,   # 130
    0,   # 131
    0,   # 132
    0,   # 133
    0,   # 134
    0,   # 135
    0,   # 136
    0,   # 137
    0,   # 138
    0,   # 139
    1,   # 140
    0,   # 141
    0,   # 142
    0,   # 143
    0,   # 144
    0,   # 145
    0,   # 146
    0,   # 147
    0,   # 148
    0,   # 149
    1,   # 150
  ]

  LEVEL_FRND_BOUNUS = [
    0, # 1
    1,        # 2
    0,        # 3
    1,        # 4
    0,        # 5
    1,        # 6
    0,        # 7
    1,        # 8
    0,        # 9
    1,        # 10
    0,        # 11
    0,        # 12
    1,        # 13
    0,        # 14
    0,        # 15
    0,        # 16
    1,        # 17
    0,        # 18
    0,        # 19
    0,        # 20
    1,        # 21
    0,        # 22
    0,        # 23
    0,        # 24
    0,        # 25
    1,        # 26
    0,        # 27
    0,        # 28
    0,        # 29
    0,        # 30
    1,        # 31
    0,        # 32
    0,        # 33
    0,        # 34
    0,        # 35
    1,        # 36
    0,        # 37
    0,        # 38
    0,        # 39
    0,        # 40
    1,        # 41
    0,        # 42
    0,        # 43
    0,        # 44
    0,        # 45
    1,        # 46
    0,        # 47
    0,        # 48
    0,        # 49
    0,        # 50
    1,        # 51
    0,        # 52
    0,        # 53
    0,        # 54
    0,        # 55
    1,        # 56
    0,        # 57
    0,        # 58
    0,        # 59
    0,        # 60
    1,        # 61
    0,        # 62
    0,        # 63
    0,        # 64
    0,        # 65
    1,        # 66
    0,        # 67
    0,        # 68
    0,        # 69
    0,        # 70
    0,        # 71
    0,        # 72
    1,        # 73
    0,        # 74
    0,        # 75
    0,        # 76
    0,        # 77
    0,        # 78
    0,        # 79
    1,        # 80
    0,        # 81
    0,        # 82
    0,        # 83
    0,        # 84
    0,        # 85
    0,        # 86
    0,        # 87
    0,        # 88
    0,        # 89
    1,        # 90
    0,        # 91
    0,        # 92
    0,        # 93
    0,        # 94
    0,        # 95
    0,        # 96
    0,        # 97
    0,        # 98
    0,        # 99
    1,   # 100
    0,   # 101
    0,   # 102
    0,   # 103
    0,   # 104
    0,   # 105
    0,   # 106
    0,   # 107
    0,   # 108
    0,   # 109
    1,   # 110
    0,   # 111
    0,   # 112
    0,   # 113
    0,   # 114
    0,   # 115
    0,   # 116
    0,   # 117
    0,   # 118
    0,   # 119
    1,   # 120
    0,   # 121
    0,   # 122
    0,   # 123
    0,   # 124
    0,   # 125
    0,   # 126
    0,   # 127
    0,   # 128
    0,   # 129
    1,   # 130
    0,   # 131
    0,   # 132
    0,   # 133
    0,   # 134
    0,   # 135
    0,   # 136
    0,   # 137
    0,   # 138
    0,   # 139
    1,   # 140
    0,   # 141
    0,   # 142
    0,   # 143
    0,   # 144
    0,   # 145
    0,   # 146
    0,   # 147
    0,   # 148
    0,   # 149
    1,   # 150
  ]

  DECK_LEVEL_EXP_TABLE = [
    0, # 1
    260, # 2
    520, # 3
    780, # 4
    1410, # 5
    1850, # 6
    2380, # 7
    3420, # 8
    4210, # 9
    5120, # 10
    6760, # 11
    8030, # 12
    9480, # 13
    11790, # 14
    13670, # 15
    15760, # 16
    18880, # 17
    21490, # 18
    24360, # 19
    28690, # 20
    32290, # 21
    36260, # 22
    42320, # 23
    47330, # 24
    52860, # 25
    61770, # 26
    68990, # 27
    77060, # 28
    90820, # 29
    101730, # 30
    114060, # 31
    133860, # 32
    149930, # 33
    167860, # 34
    193260, # 35
    214930, # 36
    238460, # 37
    269460, # 38
    296730, # 39
    325860, # 40
    362460, # 41
    395330, # 42
    430060, # 43
    472260, # 44
    510730, # 45
    551060, # 46
    604280, # 47
    651060, # 48
    701060, # 49
    779280, # 50
    843390, # 51
    914560, # 52
    1015060, # 53
    1100890, # 54
    1194060, # 55
    1316560, # 56
    1424390, # 57
    1539560, # 58
    1679170, # 59
    1806560, # 60
    1940060, # 61
    2083340, # 62
    2221730, # 63
    2362560, # 64
    2513170, # 65
    2658890, # 66
    2807060, # 67
    2965000, # 68
    3118060, # 69
    3273560, # 70
    3438840, # 71
    3599230, # 72
    3762060, # 73
    3934670, # 74
    4102390, # 75
    4272560, # 76
    4452500, # 77
    4627560, # 78
    4805060, # 79
    4992340, # 80
    5174730, # 81
    5359560, # 82
    5554170, # 83
    5743890, # 84
    5936060, # 85
    6138000, # 86
    6335060, # 87
    6534560, # 88
    6743840, # 89
    6948230, # 90
    7155060, # 91
    7371670, # 92
    7583390, # 93
    7797560, # 94
    8021500, # 95
    8240560, # 96
    8462060, # 97
    8693340, # 98
    8919730, # 99
    9148560, # 100
    9387170, # 101
    9620890, # 102
    9857060, # 103
    10103000, # 104
    10344060, # 105
    10587560, # 106
    10840840, # 107
    11089230, # 108
    11340060, # 109
    11600670, # 110
    11856390, # 111
    12114560, # 112
    12382500, # 113
    12645560, # 114
    12911060, # 115
    13186340, # 116
    13456730, # 117
    13729560, # 118
    14012170, # 119
    14289890, # 120
    14570060, # 121
    14860000, # 122
    15145060, # 123
    15432560, # 124
    15729840, # 125
    16022230, # 126
    16317060, # 127
    16621670, # 128
    16921390, # 129
    17223560, # 130
    17535500, # 131
    17842560, # 132
    18152060, # 133
    18471340, # 134
    18785730, # 135
    19102560, # 136
    19429170, # 137
    19750890, # 138
    20075060, # 139
    20409000, # 140
    20738060, # 141
    21069560, # 142
    21410840, # 143
    21747230, # 144
    22086060, # 145
    22434670, # 146
    22778390, # 147
    23124560, # 148
    24717600, # 149
    25437490, # 150
    999999999, # 151
  ]

  SC_LEVEL_EXP_TABLE = [
    0, # 001
    10,        # 002
    31,        # 003
    56,        # 004
    97,        # 005
    152,       # 006
    210,       # 007
    271,       # 008
    334,       # 009
    402,       # 010
    493,       # 011
    589,       # 012
    700,       # 013
    818,       # 014
    940,       # 015
    1083,      # 016
    1229,      # 017
    1402,      # 018
    1579,      # 019
    1770,      # 020
    999999999, # ***
  ]
  # CharaCardKind
  CC_KIND_CHARA         = 0
  CC_KIND_MONSTAR       = 1
  CC_KIND_COIN          = 2
  CC_KIND_TIPS          = 3
  CC_KIND_EX_COIN       = 4
  CC_KIND_EX_TIPS       = 5
  CC_KIND_BOSS_MONSTAR  = 6
  CC_KIND_PROFOUND_BOSS = 7
  CC_KIND_REBORN_CHARA  = 8
  CC_KIND_ORB           = 9
  CC_KIND_ARTIFACT     = 10
  CC_KIND_RARE_MONSTER = 11
  CC_KIND_RENTAL       = 12
  CC_KIND_EPISODE      = 13

  # 復活カード chara_card_idのオフセット値
  CC_ID_OFFSET_REBORN = 2000

  # 復活カード charactor_idのオフセット値
  CHARACTOR_ID_OFFSET_REBORN = 4000

  # AvatarPartsType
  APT_B_BODY   = 0
  APT_B_EYE    = 1
  APT_B_MOUTH  = 2
  APT_B_HAIR   = 3

  APT_C_TOP    = 10
  APT_C_BOTTOM = 11
  APT_C_DRESS  = 12
  APT_C_SHOES  = 13

  APT_A_HEAD   = 20
  APT_A_ARAMS  = 21
  APT_A_FACE   = 22

  # AvatarPartsType
  APT_BODY      = 10
  APT_CLOTHES   = 20
  APT_ACCESSORY = 30

  # AvatartPartsInventoryMax
  AP_INV_MAX = 30

  # アバターパーツの状態
  APS_USED      = 0b0001
  APS_ACTIVATED = 0b0010

  # CharaDeckType
  CDT_DUEL     = 0
  CDT_QUEST    = 1

  # CharaDeckStatus
  CDS_NONE    = 0               # 命令なし
  CDS_QUEST   = 1               # クエスト中
  CDS_SERCH   = 2               # 探索中
  CDS_RAID    = 3               # レイド中

  # FriendListの状態
  FR_ST_OTHER_CONFIRM = 0             # 相手の認証待ち
  FR_ST_MINE_CONFIRM  = 1             # 自分の認証待ち
  FR_ST_FRIEND        = 2             # フレンド
  FR_ST_BLOCK         = 3             # ブロックしている
  FR_ST_BLOCKED       = 4             # ブロックされている
  FR_ST_ONLY_SNS      = 5             # SNS上の友人
  FR_ST_LOGIN         = 6             # フレンドでかつログイン

  # 継続使用アイテム
  ITEM_USING_QUEST_MAX_UP   = 0      # クエストのインベントリ数のMAXのアップ中
  ITEM_USING_AP_RECOVERY_UP = 1      # AP回復スピード、上昇中
  ITEM_USING_BINDER_MAX_UP  = 2      # バインダーのカード枚数のマックスを上昇
  ITEM_USING_EXP_UP         = 3      # 獲得経験値UP
  ITEM_USING_PARTS_MAX_UP   = 4      # 獲得経験値UP

  # AvatarLevelUpInfo
  # [LEVEL, TYPE, VALUE]
  AVATAR_LEVEL_UP_INFO = []

  # ランキングのアロー
  RANK_NONE   = 0
  RANK_UP     = 1
  RANK_DOWN   = 2
  RANK_S_UP   = 3
  RANK_S_DOWN = 4

  RANK_TYPE_WD = 0
  RANK_TYPE_TD = 1
  RANK_TYPE_WQ = 2
  RANK_TYPE_TQ = 3
  RANK_TYPE_TE = 4
  RANK_TYPE_TV = 5

  RANK_SUPER_DIFF = 5

  # ============== ショップ関連定数 ==================
  SHOP_ITEM        = 0
  SHOP_PART        = 1
  SHOP_EVENT_CARD  = 2
  SHOP_WEAPON_CARD = 3
  SHOP_CHARA_CARD  = 4

  RM_ITEM_STATE_NORMAL            = 0
  RM_ITEM_STATE_NEW               = 1
  RM_ITEM_STATE_SALE              = 2
  RM_ITEM_STATE_RECOMMENDED       = 3
  RM_ITEM_STATE_NEW_RECOMMENDED   = 4
  RM_ITEM_STATE_SALE_RECOMMENDED  = 5

  # セールタイプ
  SALE_TYPE_ROOKIE  = 0
  SALE_TYPE_TEN     = 1
  SALE_TYPE_FIFTEEN = 2
  SALE_TYPE_TWENTY  = 3
  SALE_TYPE_THIRTY  = 4
  SALE_TYPE_FORTY   = 5
  SALE_TYPE_EVENT   = 6

  # ランダムセール時間
  RANDOM_SALE_TIME = 60 * 60 * 2 # ２時間
  #  RANDOM_SALE_TIME  = 60*3  #3分
  # ランダムセール発生確率 (1/14)
  RANDOM_SALE_PROBABILITY = 14
  # 1日セール時間
  ONE_DAY_SALE_TIME = 60 * 60 * 24 # 1日

  # デッキが含まれるID
  RM_ITEM_DECK_ID = [327, 2207, 3222]
  # デッキ増加アイテムID
  DECK_ITEM_ID = [85, 86, 87]

  # ============== レアカードくじ関連定数 ==================
  LOT_TYPE_BRONZE        = 0
  LOT_TYPE_SILVER        = 1
  LOT_TYPE_GOLD          = 2

  LOT_TIKECT_NUM = [1, 3, 5]

  # チケットの固有アイテム番号
  RARE_CARD_TICKET = 9

  # 複製アイテムの固有アイテム番号
  COPY_TICKET = 10

  #
  # ============== デッキ定数 ==================
  # 各ステージの仕様ACTION_CARDID

  STAGE_DECK = [
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57], # 0:STAGE_CASTLE
    [2, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     32, 34, 35, 36, 37, 38, 39, 40, 42, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 60], # 1:STAGE_FOREST
    [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 36, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 60], # 2:STAGE_ROAD
    [1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 23, 24, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 36, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 53, 54, 55, 56, 57, 59, 60], # 3:STAGE_LAKESIDE
    [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     31, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 48, 49, 50, 52, 53, 54, 55, 56, 57, 60], # 4:STAGE_GRAVE
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58],  # 5:STAGE_VILLAGE
    [1, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 29, 30,
     31, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 58, 59, 60],  # 6:STAGE_WILD
    [1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 46, 47, 48, 49, 50, 51, 54, 55, 56, 57, 59, 60], # 7:STAGE_RUIN
    [3, 4, 5, 9, 10, 11, 12, 13, 14, 15, 18, 19, 20, 23, 24, 25, 26, 27, 28, 29, 30,
     33, 34, 35, 39, 40, 41, 42, 43, 44, 45, 48, 49, 50, 53, 54, 55, 56, 57, 58, 59, 60], # 8:STAGE_TOWN
    [1, 2, 3, 4, 5, 7, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20, 22, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 37, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 52, 55, 56, 57, 58, 59, 60], # 9:STAGE_MOUNTAIN
    [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60], # 10:STAGE_MOON_CASTLE
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 24, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60], # 11:STAGE_MOORLAND
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60],        # 12:STAGE_UBOS
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55,],       # 13:STAGE_STONE
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 29, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 58, 59, 60],     # 14:STAGE_GATE
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 29, 30,
     31, 32, 33, 34, 35, 36, 37, 38, 39, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 58, 59, 60],     # 15:STAGE_THRONE
  ]

  DECK_COST_CORRECTION_CRITERIA = 7
  DECK_COST_CORRECTION_VALUE = 5

  # ステージの種類
  # 0:城ステージ，1:森ステージ,2:街道, 3:湖畔, 4:墓場,  5:村, 6:荒野, 7:遺跡, 8:街, 9:山, 10:幻影城, 11:荒地, 12:ウボス, 13:ストーンヘンジ, 14:凱旋門
  # 15:聖女の玉座
  # クイックマッチでは STAGE_GATE 以降を使用しない(2013/11/05)。マッチで使用可とするステージは GATE より前に挿入すること。
  STAGE_CASTLE, STAGE_FOREST, STAGE_ROAD, STAGE_LAKESIDE, STAGE_GRAVE, STAGE_VILLAGE, STAGE_WILD, STAGE_RUIN, STAG_TOWN, STAGE_MOUNTAIN, STAGE_MOON_CASTLE, STAGE_MOORLAND, STAGE_UBOS, STAGE_STONE, STAGE_GATE, STAGE_THRONE, STAGE_MAX = (0..15).to_a

  CHARA_CARD_DECK_MAX = 3

  # SlotType
  SCT_WEAPON = 0
  SCT_EQUIP  = 1
  SCT_EVENT = 2

  # EventCardColor
  ECC_NONE   = 0                # 属性スロット消費なし
  ECC_WHITE  = 1                # 属性スロットホワイト（幸運系）
  ECC_BLACK  = 2                # 属性スロットブラック（悪運系）
  ECC_RED    = 3                # 属性スロットレッド（近接攻撃系）
  ECC_GREEN  = 4                # 属性スロットグリーン（遠距離攻撃系）
  ECC_BLUE   = 5                # 属性スロットブルー（防御系）
  ECC_YELLOW = 6                # 属性スロットイエロー（特殊系）
  ECC_PURPLE = 7                # 属性スロットパープル（地形・移動系）

  # SlotMax
  SLOT_MAX_WEAPON = 1
  SLOT_MAX_EQUIP  = 1
  SLOT_MAX_EVENT  = 6

  # ============== クエスト関連定数 ==================
  QUEST_LOG_LIMIT = 20

  # 宝箱
  TG_NONE = 0
  TG_CHARA_CARD = 1
  TG_SLOT_CARD = 2
  TG_AVATAR_ITEM = 3
  TG_AVATAR_PART = 4
  TG_GEM = 5
  TG_OWN_CARD = 6
  TG_BONUS_GAME = 7

  # クエストイベントタイプ
  QE_NONE = 0
  QE_DAMAGE = 1
  QE_HEAL = 2

  # クエストタイプ
  QT_ADVENTURE = 0
  QT_TREASURE = 1
  QT_BOSS = 2

  # クエストマップの領域
  QMR_HEX_REALM = 0
  QMR_SHADOW_LAND = 1
  QMR_MOON_LAND = 2
  QMR_ANEMONEA = 3
  QMR_ANGEL_LAND = 4

  # ExShadowLand
  QM_EX_SHADOW_LAND = 101
  QM_EX_MOON_LAND = 102
  QM_EX_ANEMONEA = 103
  QM_EX_ANGEL_LAND = 105
  QM_EX_EVENT_LAND = 107

  # イベントクエスト
  QM_EV_XMAS_LAND = 201
  QM_EV_VALENTINE_LAND = 202
  QM_EV_WHITE_LAND = 203
  QM_EV_CODEX_LAND = 205
  QM_EV_ARK_LAND = 206
  QM_EV_ACOLYTE_LAND = 207
  QM_EV_2NDANNI1_LAND = 211
  QM_EV_2NDANNI2_LAND = 212
  QM_EV_2NDANNI3_LAND = 213
  QM_EV_XMAS2012_LAND = 214
  QM_EV_NEWYEAR2013_LAND = 215
  QM_EV_WHITE2013_LAND = 216
  QM_EV_RARECARD_LAND = 217
  QM_EV_XMAS2013_LAND_A = 219
  QM_EV_XMAS2013_LAND_B = 220
  QM_EV_NEWYEAR2014_LAND = 220
  QM_EV_ACOLYTE2014_LAND = 221
  QM_EV_ABYSS_LAND = 222
  QM_EV_SUMMER2014_LAND = 223
  QM_EV_4th_LAND = 224
  QM_EV_INQUISITOR = 225
  QM_EV_XMAS2014_LAND = 226
  QM_EV_201504_LAND = 227
  QM_EV_201508_LAND = 228
  QM_EV_XMAS2015_LAND = 229
  QM_EV_201601_LAND = 230
  QM_EV_WHITE2016_LAND = 231
  QM_EV_201605_LAND = 232
  QM_EV_201701_LAND = 233
  QM_EV_201702_LAND = 234
  QM_EV_201703_LAND = 235
  QM_EV_201707_LAND = 236

  QM_EV_INFINITE_TOWER = 991 # By_K2 (무한의탑)

  # レアカード取得クエスト
  QM_RARE_LAND = 1000
  QM_RARE_LAND2 = 1001

  # クエストの状態
  QS_NEW = 0                    # 新規
  QS_UNSOLVE = 1                # 未解決
  QS_INPROGRESS = 2             # 進行中
  QS_SOLVED = 3                 # 解決
  QS_PENDING = 4                # 未決（まだ見つけてない）
  QS_FAILED = 5                 # 失敗
  QS_PRESENTED = 6              # プレゼントされた

  # クエスト探索時間
  QFT_SET = [
    0, # 0分
    3 * 60,                  # 3分
    10 * 60,                 # 10分
    30 * 60,                 # 30分
    60 * 60,                 # 1時間
    120 * 60,                # 2時間
    240 * 60,                # 4時間
    480 * 60,                # 8時間
    960 * 60,                # 16時間
    1440 * 60,               # 1日
    4320 * 60,               # 3日
  ]

  # クエストが変化するアバター衣装ID
  QEV_XMAS_PART_ID = 200

  # 変化するクエストのレアリティの下限
  QEV_RARITY = 6

  # クエストの進行度
  #  QP_PROGRESS =

  # クエストの割り当て方式
  QUEST_ALLOC_TYPE_NONE = 0
  QUEST_ALLOC_TYPE_COST = 1

  # トレジャーの割り当て方式
  TREASURE_ALLOC_TYPE_NONE = 0
  TREASURE_ALLOC_TYPE_COST = 1

  # CPUマッチの割り当て方式
  CPU_MATCHING_TYPE_NONE = 0
  CPU_MATCHING_TYPE_COST = 1

  # 2012クリスマスイベントクエストID
  QE_CHRISTMAS2012_START_ID = 20395
  QE_CHRISTMAS2012_END_ID   = 20494

  # 2014クリスマスイベントクエストID
  QE_CHRISTMAS2014_START_ID = 20919
  QE_CHRISTMAS2014_END_ID   = 20946

  # 2015/06イベント、プレゼント不可クエストIDリスト
  #  QUEST_EVENT_QUEST_LIST = Range.new(21064,21074,21088).to_a
  #  QUEST_EVENT_QUEST_LIST = [21125,21126,21127]

  # 2015/12イベント、プレゼント不可クエストIDリスト
  #  QUEST_EVENT_QUEST_LIST = Range.new(21128,21159).to_a

  # プレゼント不可クエストIDリスト
  QUEST_EVENT_QUEST_LIST = [
    21172, 21173, 21174, 21175, 21176, 21177, 21178, 21179, 21180, 21192, 21193, 21194, 21206, 21207, 21208, 21209, 21210, 21211, 21212, 21213, 21214, # 2016/04イベント
    21363, 21364, 21365, 21366, 21367, 21368, 21369, 21370, 21371, 21372, 21373, 21374, 21375, 21376, # 2017/01イベント
    21393, 21394, 21395, 21396, 21397, 21398, 21399, 21400, 21401, 21402, 21403, 21404, 21405, 21406, 21407, 21408, 21409, 21410, 21411, 21412, 21413,   # 2017/04イベント
    21414, 21415, 21416, 21417, 21418, 21419, 21425, 21426, 21427, 21433, 21434, 21435, 21440, 21441, 21442, 21448, 21449, 21450, 21451, 21452, 21453,   # 2017/04イベント
    21454, 21455, 21456, 21457, 21458, 21459, 21460, 21461, 21462, 21463, 21464, 21465, 21466, 21467, 21468, 21469, 21470, 21471, 21472, 21473, 21474,   # 2017/04イベント
    21475, 21476, 21477, 21478, 21479, 21480, 21481, 21482, 21483, 21484, 21485, 21486, 21487, 21488, 21489, 21490, # 2017/06イベント
    21491, 21492, 21493, 21494, 21495, 21496, 21497, 21498, 21499, 21500, 21501, 21502, 21503, 21504, 21505, 21506, 21507, 21508, 21509, 21510, 21511, # 2017/06イベント
    21512, 21513, 21514, 21515, 21516, 21517, 21518, 21519, 21520, 21521, 21522, 21523, 21524, 21525, 21526, 21527, 21528, 21529, 21530, # 2017/06イベント
    21531, 21532, 21533, 21534, 21535, 21536, 21537, 21538, 21539, 21540, 21541, 21542, 21543, 21544, 21545, 21546, 21547, # 2017/07イベント
  ]

  # プレゼントしたアバター名の無効文字
  QUEST_PRESENT_AVATAR_NAME_NIL = 'n'.force_encoding('UTF-8')

  # ============== ログインボーナス関連定数 ==================

  # By_K2 (무한의탑 입장권(기간제))
  TOWER_LOGIN_BONUS_FLAG = false
  TOWER_LOGIN_BONUS = [TG_AVATAR_ITEM, 0, 102]

  # By_K2 (무한의탑 특정 층 보상)
  TOWER_FLOOR_71_REWARD = [TG_AVATAR_ITEM, 0, 39]
  TOWER_FLOOR_61_REWARD = [TG_AVATAR_ITEM, 0, 38]
  TOWER_FLOOR_51_REWARD = [TG_CHARA_CARD, 0, 10012]
  TOWER_FLOOR_41_REWARD = [TG_AVATAR_PART, 0, 152]
  TOWER_FLOOR_31_REWARD = [TG_AVATAR_PART, 0, 153]
  TOWER_FLOOR_21_REWARD = [TG_AVATAR_PART, 0, 154]
  TOWER_FLOOR_11_REWARD = [TG_AVATAR_ITEM, 0, 21]

  # ============== デュエル関連定数 ==================
  # DuelServerState

  DSS_OK = 0                  # 接続可能
  DSS_DOWN = 1                # ダウン中

  # 対戦ルールでの行動力消費
  DUEL_AP  = [2, 5]

  # 対戦ルールでの行動力消費
  FRIEND_DUEL_AP  = [1, 3]

  # 特殊対戦ルールでの行動力消費
  RADDER_DUEL_AP  = [1, 1]

  # 特殊対戦ルールのデッキ経験値倍率
  RADDER_DUEL_DECK_EXP_POW = 3
  # 特殊対戦ルールのカードボーナス倍率
  RADDER_DUEL_CARD_BONUS_POW = 2

  # 対戦ルールでの行動力消費
  DUEL_OPTION_FREE = 0
  DUEL_OPTION_FRIEND = 1

  # DUEL_BONUS
  DUEL_BONUS_FIRST_ATTACK   = 1 # 最初に攻撃をした方にボーナス＋１
  DUEL_BONUS_STRIKE_KILL    = 2 # 一発で倒した場合(星はHPによる)
  DUEL_BONUS_SURVIVER       = 3 # HP１で敵を倒す星は＋３固定(相手キャラが増えれば＋１)
  DUEL_BONUS_FEAT           = 4 # 必殺技を使うゴトに+1
  #  DUEL_BONUS_OVER_KILL      = 5 # HP分マイナスにしたときに（MAXHPによる）

  # 無料デュエル回数
  FREE_DUEL_COUNT = 3

  # クエストプレゼントボーナス（相手がクリアしてくれた時のお返しgem and avatar_item）
  SEND_QUEST_BONUS = [
    { TG_GEM: 5 }, # 0
    { TG_GEM: 10 },        # 1 5
    { TG_GEM: 20 },        # 2 10
    { TG_GEM: 30 },        # 3 10
    { TG_GEM: 50 },        # 4 20
    { TG_GEM: 80 },        # 5 30
    { TG_GEM: 120 },       # 6 40
    { TG_GEM: 180 },       # 7 60
    { TG_GEM: 250 },       # 8 70
    { TG_GEM: 350 },       # 9 100
    { TG_GEM: 500 },       # 10 150
  ]

  # ChannelRules
  CRULE_FREE     = 0
  CRULE_LOW      = 1
  CRULE_HIGH     = 2
  CRULE_NEWBIE   = 3
  CRULE_RADDER   = 4
  CRULE_COST_A   = 5 # CRULE_COST_A 2週間毎に変更
  CRULE_COST_B   = 6 # COST75 未使用
  CRULE_EVENT    = 10

  # ====== MessageDialogue関連 =======
  DUEL_MSGDLG_START            = 0   # XXXさんとの対戦を開始します
  DUEL_MSGDLG_WATCH_START      = 1   # XXXさん対ZZZさんのバトル観戦をします
  DUEL_MSGDLG_DUEL_START       = 2   # Duel スタート
  DUEL_MSGDLG_M_DUEL_START     = 3   # Multi Duel スタート
  DUEL_MSGDLG_INITIATIVE       = 4   # XXXがイニシアチブをとりました
  DUEL_MSGDLG_DISTANCE         = 5   # 距離がXになりました
  DUEL_MSGDLG_CHANGE_CHARA     = 6   # 戦闘キャラを変更しました
  DUEL_MSGDLG_BTL_POINT        = 7   # 攻撃はなし or 攻撃力決定 X
  DUEL_MSGDLG_BTL_RESULT       = 8   # XXXの攻撃はキャンセル
  DUEL_MSGDLG_TURN_END         = 9   # ターン X の終了
  DUEL_MSGDLG_SPECIAL          = 10  # (赤い柘榴の発動内容)
  DUEL_MSGDLG_STATE            = 11  # (付加される状態内容)
  DUEL_MSGDLG_DMG_FOR_BOSS     = 12  # XXXさんが、ZZZにxダメージを与えた
  DUEL_MSGDLG_HEAL_BOSS        = 13  # ZZZがx、回復した
  DUEL_MSGDLG_SUM_DMG_FOR_BOSS = 14  # 皆さんの攻撃でZZZに合計xダメージを与えました
  DUEL_MSGDLG_RAID_SCORE       = 15  # SCORE:XXX
  DUEL_MSGDLG_TRAP             = 16  # XXXにトラップ効果発動
  DUEL_MSGDLG_TRAP_ARLE        = 17  # XXXにトラップ効果発動, 手札を破棄
  DUEL_MSGDLG_TRAP_INSC        = 18  # 結界の効果により、XXXは無敵状態になりました
  DUEL_MSGDLG_LITTLE_PRINCESS  = 19  # リトルプリンセスの効果により、ダメージが無効化された
  DUEL_MSGDLG_CRIMSON_WITCH    = 20  # 深紅の魔女の効果により、ダメージが2倍になった
  DUEL_MSGDLG_AVOID_DAMAGE     = 21  # XXX は Y のダメージを回避しました
  DUEL_MSGDLG_CONSTRAINT       = 22  # XXX は A,B,C禁止状態になりました
  DUEL_MSGDLG_WEAPON_STATUS_UP = 23  # XXX の武器ステータスが向上しました
  DUEL_MSGDLG_SWORD_DEF_UP     = 24  # XXX の近距離における防御性能が向上しました
  DUEL_MSGDLG_ARROW_DEF_UP     = 25  # XXX の遠距離における防御性能が向上しました
  DUEL_MSGDLG_DOLL_ATK         = 26  # ヌイグルミによる追加攻撃
  DUEL_MSGDLG_DOLL_CRASH       = 27  # ヌイグルミ破壊

  # ====== TRAP種別 =======
  TRAP_ARLE = 278
  TRAP_INSC = 279

  #
  # ============== アチーブメント定数 ==================
  #
  # 実績タイプ
  ACHIEVEMENT_TYPE_AVATAR = 0
  ACHIEVEMENT_TYPE_DUEL   = 1
  ACHIEVEMENT_TYPE_QUEST  = 2
  ACHIEVEMENT_TYPE_FRIEND = 3
  ACHIEVEMENT_TYPE_EVENT  = 4

  # 実績の状態
  ACHIEVEMENT_STATE_START  = 0
  ACHIEVEMENT_STATE_FINISH = 1
  ACHIEVEMENT_STATE_FAILED = 2

  # 実績条件タイプ
  ACHIEVEMENT_COND_TYPE_LEVEL             = 0
  ACHIEVEMENT_COND_TYPE_DUEL_WIN          = 1
  ACHIEVEMENT_COND_TYPE_QUEST_CLEAR       = 2
  ACHIEVEMENT_COND_TYPE_FRIEND_NUM        = 3
  ACHIEVEMENT_COND_TYPE_ITEM_NUM          = 4
  ACHIEVEMENT_COND_TYPE_HALLOWEEN         = 5
  ACHIEVEMENT_COND_TYPE_CHARA_CARD        = 6
  ACHIEVEMENT_COND_TYPE_CHARA_CARD_DECK   = 7
  ACHIEVEMENT_COND_TYPE_QUEST_NO_CLEAR    = 8
  ACHIEVEMENT_COND_TYPE_GET_RARE_CARD     = 9
  ACHIEVEMENT_COND_TYPE_DUEL_CLEAR        = 10
  ACHIEVEMENT_COND_TYPE_QUEST_PRESENT     = 11
  ACHIEVEMENT_COND_TYPE_RECORD_CLEAR      = 12
  ACHIEVEMENT_COND_TYPE_ITEM              = 13
  ACHIEVEMENT_COND_TYPE_ITEM_COMPLETE     = 14
  ACHIEVEMENT_COND_TYPE_ITEM_CALC         = 15
  ACHIEVEMENT_COND_TYPE_ITEM_SET_CALC     = 16
  ACHIEVEMENT_COND_TYPE_QUEST_POINT       = 17
  ACHIEVEMENT_COND_TYPE_GET_WEAPON        = 18
  ACHIEVEMENT_COND_TYPE_QUEST_ADVANCE     = 19
  ACHIEVEMENT_COND_TYPE_FIND_PROFOUND     = 20
  ACHIEVEMENT_COND_TYPE_RAID_BATTLE_CNT   = 21
  ACHIEVEMENT_COND_TYPE_MULTI_QUEST_CLEAR = 22
  ACHIEVEMENT_COND_TYPE_INVITE_COUNT      = 23
  ACHIEVEMENT_COND_TYPE_RAID_BOSS_DEFEAT  = 24
  ACHIEVEMENT_COND_TYPE_RAID_ALL_DAMAGE   = 25
  ACHIEVEMENT_COND_TYPE_CREATED_DAYS      = 26
  ACHIEVEMENT_COND_TYPE_EVENT_POINT       = 27
  ACHIEVEMENT_COND_TYPE_EVENT_POINT_CNT   = 28
  ACHIEVEMENT_COND_TYPE_GET_PART          = 29
  ACHIEVEMENT_COND_TYPE_DAILY_CLEAR       = 30
  ACHIEVEMENT_COND_TYPE_OTHER_RAID        = 31
  ACHIEVEMENT_COND_TYPE_USE_ITEM          = 32
  ACHIEVEMENT_COND_TYPE_SELF_RAID         = 33
  ACHIEVEMENT_COND_TYPE_OTHER_DUEL        = 34

  NOTICE_TYPE_LOGIN           = 0
  NOTICE_TYPE_ACHI_SUCC       = 1
  NOTICE_TYPE_ACHI_NEW        = 2
  NOTICE_TYPE_VANISH_PART     = 3
  NOTICE_TYPE_FRIEND_COME     = 4
  NOTICE_TYPE_ITEM_PRESENT    = 5
  NOTICE_TYPE_QUEST_PRESENT   = 6
  NOTICE_TYPE_RETURN_CARD     = 7
  NOTICE_TYPE_INVITE_SUCC     = 8
  NOTICE_TYPE_AD              = 9
  NOTICE_TYPE_QUEST_SUCC      = 10
  NOTICE_TYPE_COMEBK_SUCC     = 11
  NOTICE_TYPE_COMEBKED_SUCC   = 12
  NOTICE_TYPE_SALE_START      = 13
  NOTICE_TYPE_ROOKIE_START    = 14
  NOTICE_TYPE_GET_PROFOUND    = 15
  NOTICE_TYPE_FIN_PRF_WIN     = 16
  NOTICE_TYPE_FIN_PRF_REWARD  = 17
  NOTICE_TYPE_FIN_PRF_RANKING = 18
  NOTICE_TYPE_FIN_PRF_FAILED  = 19
  NOTICE_TYPE_3_ANNIVERSARY   = 20
  NOTICE_TYPE_APOLOGY         = 21
  NOTICE_TYPE_NEW_YEAR        = 22
  NOTICE_TYPE_INVITED_SUCC    = 23
  NOTICE_TYPE_UPDATE_NEWS = 24
  NOTICE_TYPE_CLEAR_CODE               = 25
  NOTICE_TYPE_GET_SELECTABLE_ITEM      = 26

  # end_atを設定する場合のタイプ
  ACHIEVEMENT_END_AT_TYPE_NONE = 0
  ACHIEVEMENT_END_AT_TYPE_DAY  = 1
  ACHIEVEMENT_END_AT_TYPE_HOUR = 2

  # 初心者レコードの開始ＩＤ
  ROOKIE_RECORD_START = 180
  # 初心者用クエストアチーブメント定数
  ROOKIE_QUEST_01     = [[1], [180, 181, 182]]

  # 期間限定クエストアチーブメント定数
  EVENT_QUEST_01  = [[10428, 10429, 10430, 10431, 10432, 21475, 21476, 21477, 21478, 21479, 21480, 21481, 21482, 21483, 21484, 21485, 21486, 21487, 21488, 21489, 21490, 21491, 21492, 21493, 21494, 21495, 21496, 21497, 21498, 21499, 21500, 21501, 21502, 21503, 21504, 21505, 21506, 21507, 21508, 21509, 21510, 21511, 21512, 21513, 21514, 21515, 21516, 21517, 21518, 21519, 21520, 21521, 21522, 21523, 21524, 21525, 21526, 21527, 21528, 21529, 21530], [1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193]] # 2017/06イベント
  EVENT_QUEST_02  = [[21209, 21210, 21211], [957]] # 2016/4イベント
  EVENT_QUEST_03  = [[21212, 21213, 21214], [958]] # 2016/4イベント
  EVENT_QUEST_04  = [[21306, 21307, 21308], [1047]] # 2016/10月イベント
  EVENT_QUEST_05  = [[21315, 21316, 21317], [1048]] # 2016/10月イベント
  EVENT_QUEST_06  = [[21327, 21328, 21329], [1049]] # 2016/10月イベント
  EVENT_QUEST_07  = [[21342, 21343, 21344], [1050]] # 2016/10月イベント
  EVENT_QUEST_08  = [[21360, 21361, 21362], [1051]] # 2016/10月イベント
  EVENT_QUEST_09  = [[21088], [703]] # 2015/6月イベント
  EVENT_QUEST_10  = [[21089, 21090, 21091], [718, 742, 754, 762, 774]] # 2015/08イベント Aクエスト（ルディア）
  EVENT_QUEST_11  = [[21092, 21093, 21094], [722, 734, 738, 766, 770]] # 2015/08イベント Bクエスト（ヴィルヘルム）
  EVENT_QUEST_12  = [[21095, 21096, 21097], [726, 730, 746, 750, 758]] # 2015/08イベント Cクエスト（メリー）
  EVENT_QUEST_13  = [[21125, 21126, 21127], [835]] # 2015/10月イベント
  EVENT_QUEST_14  = [[10388, 10389, 10390, 10391, 10392, 21146, 21147, 21148, 21149, 21150, 21151, 21152, 21153, 21154, 21155, 21156, 21157, 21158, 21159], [863, 864, 865, 866, 867]] # 2016/01イベント
  EVENT_QUEST_15  = [[50000], [788]] # 人気投票クエストレコード1
  EVENT_QUEST_16  = [[50001], [789]] # 人気投票クエストレコード2
  EVENT_QUEST_17  = [[50002], [790]] # 人気投票クエストレコード3
  EVENT_QUEST_18  = [[50003], [791]] # 人気投票クエストレコード4
  EVENT_QUEST_19  = [[50004], [792]] # 人気投票クエストレコード5
  EVENT_QUEST_20  = [[50005], [793]] # 人気投票クエストレコード6
  EVENT_QUEST_21  = [[50006], [794]] # 人気投票クエストレコード7
  EVENT_QUEST_22  = [[50007], [795]] # 人気投票クエストレコード8
  EVENT_QUEST_23  = [[50008], [796]] # 人気投票クエストレコード9
  EVENT_QUEST_24  = [[50009], [797]] # 人気投票クエストレコード10
  EVENT_QUEST_25  = [[21389, 21390, 21391, 21392, 21393, 21394, 21395, 21396, 21397, 21398, 21399, 21400, 21401, 21402, 21403, 21404, 21405, 21406, 21407, 21408, 21409, 21410, 21411, 21412, 21413, 21414, 21415, 21416, 21417, 21418, 21419, 21420, 21421, 21422, 21423, 21424, 21425, 21426, 21427, 21428, 21429, 21430, 21431, 21432, 21433, 21434, 21435, 21436, 21437, 21438, 21439, 21440, 21441, 21442, 21443, 21444, 21445, 21446, 21447, 21448, 21449, 21450, 21451, 21452, 21453, 21454, 21455, 21456, 21457, 21458, 21459, 21460, 21461, 21462, 21463, 21464, 21465, 21466, 21467, 21468, 21469, 21470, 21471, 21472, 21473, 21474], [1149]] # 2017/04イベント
  EVENT_QUEST_26  = [[21451, 21452, 21453], [1162]] # 1162 黒衣の城に現れたシェリの影を倒す
  EVENT_QUEST_27  = [[21454, 21455, 21456], [1163]] # 1163 黒衣の城に現れたフリードリヒの影を倒す
  EVENT_QUEST_28  = [[21457, 21458, 21459], [1164]] # 1164 黒衣の城に現れたスプラートの影を倒す
  EVENT_QUEST_29  = [[21460, 21461, 21462], [1165]] # 1165 黒衣の城に現れたリーズの影を倒す
  EVENT_QUEST_30  = [[21463, 21464, 21465], [1166]] # 1166 黒衣の城に現れたC.C.の影を倒す
  EVENT_QUEST_31  = [[21472, 21473, 21474], [1167]] # 1167 黒衣の城に現れたギュスターヴの影を倒す
  EVENT_QUEST_32  = [[21448, 21449, 21450], [1168]] # 1168 黒衣の城に現れたグリュンワルドの影を倒す
  EVENT_QUEST_33  = [[21466, 21467, 21468], [1169]] # 1169 黒衣の城に現れたタイレルの影を倒す
  EVENT_QUEST_34  = [[21469, 21470, 21471], [1170]] # 1170 黒衣の城に現れたヴィルヘルムの影を倒す
  EVENT_QUEST_35  = [[20999, 21000, 21001, 21002, 21003, 21004, 21005, 21006, 21007, 21008, 21009, 21010, 21011, 21012, 21013, 21014, 21015, 21016, 21017, 21018, 21019, 21020, 21021, 21022, 21023, 21024, 21025, 21026, 21027, 21028, 21029, 21030, 21031], [675, 676, 677]] # 「バックベアード」レコード

  EVENT_QUEST_FRIEND_ACHIEVEMENT_ID = 253

  # 期間限定デュエルアチーブメント定数
  EVENT_DUEL_01  = [[0, 1, 2], [1205]]
  EVENT_DUEL_02  = [[0, 1, 2], [252]]
  EVENT_DUEL_03  = [[0, 1, 2], [140]]
  EVENT_DUEL_04  = [1084, 1085, 1086] # 低レベルアバター（Lv20以下）とデュエルする
  EVENT_DUEL_05  = [1087] # 低レベルアバター（Lv20以下）がデュエルする

  # 低レベルアバター（Lv20以下）
  LOW_AVATAR_DUEL_RECORD_LV = 20

  EVENT_DUEL_3VS3_ACHIEVEMENT_ID = 1183
  EVENT_DUEL_FRIEND_ACHIEVEMENT_ID = 264

  # チャンネルルール依存のレコード定数
  DUEL_RULE_ACHIEVEMENTS = {
    CRULE_FREE => [],
    CRULE_LOW => [],
    CRULE_HIGH => [],
    CRULE_NEWBIE => [],
    CRULE_RADDER => [1002, 1130, 1146],
    CRULE_COST_A => [1001, 1131, 1147],
    CRULE_COST_B => [1001],
    CRULE_EVENT => []
  }

  # 期間限定イベントデュエルアチーブメント定数
  EVENT_CPU_DUEL_01 = [[0], [232, 233, 234]]

  # キャラ人気投票関連アチーブメント定数
  CHATA_VOTE_ACHIEVEMENT_IDS = [302, 303]

  # 週間デュエルアチーブメントID
  WEEK_DUEL_ACHIEVEMENT_IDS  = [288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301]
  # 週間クエストアチーブメントID
  WEEK_QUEST_ACHIEVEMENT_IDS = [429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442]
  # デイリーアチーブメントクリア判定アチーブメントID
  DAILY_ACHIEVEMENT_CLEAR_IDS = [925]

  # デイリーアチーブメントID
  DAILY_ACHIEVEMENT_IDS = [890, 891, 892, 942, 983, 984, 985, 986, 1000, 1001, 1002, 1031, 1032, 1047, 1048, 1049, 1050, 1051, 1080, 1081, 1082, 1083, 1084, 1085, 1086, 1089, 1090, 1091, 1101, 1102, 1103, 1104, 1105, 1129, 1130, 1131, 1145, 1146, 1147, 1149, 1183, 1194, 1205]
  # 出現条件ありのデイリーアチーブメントID
  CONDITIONS_DAILY_ACHIEVEMENT_IDS = {
    #    1046 => [1047,1048,1049,1050,1051]
    1145 => [1146, 1147]
  }

  # 炎の聖女用クエストアチーブメント定数
  GODDESS_OF_FIRE_QUEST_01 = [[973], [415]]
  GODDESS_OF_FIRE_QUEST_02 = [[974], [416]]
  GODDESS_OF_FIRE_QUEST_03 = [[975], [417]]

  # 渦関連レコード
  FIND_PROFOUND_01  = [[1000, 1010, 1012, 1014, 2000, 2001, 3000, 3011], (457..460).to_a]
  FIND_PROFOUND_02  = [[1001, 1011, 1013, 1015, 2002, 2003, 3001, 3012], (461..464).to_a]
  RAID_BTL_CNT_01   = [[1000, 1010, 1012, 1014, 2000, 2001, 3000, 3011], (473..476).to_a]
  RAID_BTL_CNT_02   = [[1001, 1011, 1013, 1015, 2002, 2003, 3001, 3012], (477..480).to_a]
  RAID_BTL_CNT_03   = [1031]
  RAID_BTL_CNT_PRF_IDS = (1001..1004).to_a.concat((2001..2009).to_a.concat((3001..3008).to_a))
  ALL_RAID_BTL_CNT_IDS = (481..485).to_a
  PRF_ALL_DMG_CHECK_IDS = [890, 891, 892, 986, 1090]
  PRF_OTHER_RAID_BTL_CHECK_ID = [782]
  PRF_SELF_PRF_CLEAR_CHECK_ID = [943, 985]

  # 渦イベント関連レコード
  EVENT_PRF_IDS_01 = [2034, 2035, 2036, 2037, 3023, 3024, 3026, 3027]
  EVENT_PRF_SET_01 = [EVENT_PRF_IDS_01, [550, 551, 552]]

  # 招待人数レコード
  INVITE_RECORD_IDS = [490, 491, 492, 689, 690, 691, 692, 693]

  # 2014深淵の書イベントレコード
  EVENT_QUEST_PRESENT_2014_RECORD = [[20835, 20836, 20837, 20838, 20839, 20840, 20841, 20842, 20843, 20844, 20845, 20846, 20847, 20848, 20849, 20850, 20851, 20852, 20853, 20854], (494..498).to_a]

  # 201408イベント関連(加算レコードIDは「イベントランキング定数」に記載)
  EVENT_1408_RECORD_IDS = (529..534).to_a # レコードIDリスト
  # レコード条件クエストID：取得ポイント
  EVENT_1408_QUEST_IDS = {
    20888 => 10, 20889 => 20, 20890 => 30, 20891 => 40, 20892 => 50,
    10351 => 60, 10352 => 70, 10353 => 80, 10354 => 90, 10355 => 100
  }
  # ポイント増加特定キャラIDS
  EVENT_1408_ADD_POINT_CHARA_IDS = [9, 11, 16, 4011, 4016]
  EVENT_1408_POINT_COEFFICIENT   = 2 # 特定キャラの場合2倍

  # 201412イベント関連
  EVENT_201412_RECORD_IDS = { 1 => [629], 2 => [630], 3 => [631] }
  EVENT_201412_CHECK_INTARVAL = 58 * 30 # チェック間隔
  EVENT_201412_RATE = 10 # N分の1

  # 201701イベント関連
  EVENT_201701_RECORD_IDS = { 1 => [1101], 2 => [1102], 3 => [1103], 4 => [1104], 5 => [1105] }

  # パーツ取得チェック
  EVENT_GET_PART_01 = [[555], [696]]
  EVENT_GET_PART_02 = [[640], [860]]
  EVENT_GET_PART_03 = [[641], [861]]

  # アイテム使用レコードチェック
  EVENT_USE_ITEM_RECORD_ID = [[361, 362, 363, 364, 365], [984]]

  # 人気投票イベント
  EVENT_CHARA_VOTE_QUEST_IDS  = (10001..10387).to_a
  EVENT_CHARA_VOTE_RECORD_IDS = [798, 799, 800, 801, 802, 803, 804, 805, 806, 807]

  # 対戦相手カウントレコード
  RECORD_OTHER_AVATAR_DUEL_IDS = [822, 823, 824, 825]
  # 複数のアバターとのDuel記録期間(1ヶ月)
  RECORD_OTHER_AVATAR_DUEL_CACHE_TIME = 60 * 60 * 24 * 30

  # 使用済み含むアイテム所持数チェックレコード
  EVENT_ITEM_FULL_CHECK_IDS = [[379], [851, 852, 853, 854, 855]]

  #
  # ============== エラーコード定数 ==================
  #

  ERROR_AP_LACK                 = 1 # APが足りません
  ERROR_NO_CURRENT_DECK         = 2 # カレントデッキがありません
  ERROR_NO_RULE_MATCH           = 3 # 現在のルールにマッチしていません
  ERROR_GAME_QUIT               = 4 # 相手がゲームを放棄しました。相手をAIに切り替えます
  ERROR_GAME_ABORT              = 5 # ゲームを中断します
  ERROR_NOT_EXIST_INVETORY      = 6 # カードを持っていません

  ERROR_DOUBLE_LOGIN            = 7 # 多重ログインの可能性があります。
  ERROR_LOCK_ACOUNT             = 8 # あなたのアカウントは現在ロックされています。

  ERROR_GAME_NOT_START          = 9 # 相手がゲームを放棄しました。ゲームを中断します

  ERROR_DECK_MAX                = 10 # デッキにこれ以上入れられません
  ERROR_NOT_ENOUGH_COLOR        = 11 # デッキに適合する色スロットがありません
  ERROR_RESTRICT_CHARA          = 12 # このキャラにこのカードは持たせられません
  ERROR_MAX_IN_DECK             = 13 # このカードのデッキ最大数を超えています。
  ERROR_SLOT_MAX                = 14 # カードはこれ以上セット出来ません。
  ERROR_NOT_EXIST_CHARA         = 15 # デッキにキラャ1カードが存在しない
  ERROR_NOT_EXIST_DECK          = 16 # デッキが存在しない
  ERROR_DECK_DUBBLE_CHARA       = 17 # デッキに同じキャラが存在している
  ERROR_DECK_UNKNOWN_CHARA      = 18 # デッキに入れることが出来ないカードが入っている

  ERROR_GEM_DEFICIT             = 20 # GEM不足で購入できません
  ERROR_CANT_EQUIP              = 21 # 装備できませんでした
  ERROR_PARTS_DUPE              = 22 # 取得済みのパーツです

  ERROR_DUEL_CREATE_ROOM        = 25 # ペナルティの為、部屋を作れません
  ERROR_DUEL_JOIN_ROOM          = 26 # ペナルティの為、部屋に入れません
  ERROR_DUEL_CREATE_ROOM_EVENT  = 27 # イベントの為、部屋を作れません
  ERROR_DUEL_JOIN_ROOM_EVENT    = 28 # イベントの為、部屋に入れません

  ERROR_MAX_QUEST               = 30 # クエストが所持MAXに達しているので取得できません
  ERROR_WRONG_QUEST_MAP_NO      = 31 # 不正なクエストマップ番号です
  ERROR_NOT_ENOUGH_LEVEL        = 32 # マップを取得するのにレベルが足りません

  ERROR_QUEST_INV_IS_NONE       = 40 # クエストインベントリが存在しません
  ERROR_QUEST_STATUS_WRONG      = 41 # クエストインベントリは開始できる状態ではない
  ERROR_DECK_IS_ALREADY_QUESTED = 42 # そのデッキはすでにクエストに出ている
  ERROR_NEXT_QUEST_LAMD_WRONG   = 43 # その場所へに到達できない

  ERROR_DUEL_WRONG_ROOM         = 50 # 部屋がない
  ERROR_DUEL_ALREADY_START      = 51 # 部屋はスタート済み
  ERROR_DUEL_SAME_IP            = 52 # 同じIPでは対戦できません
  ERROR_DUEL_RADDER_ERROR       = 53 # スタートできません
  ERROR_DUEL_COST_ERROR         = 54 # コストの限界値を越えています
  ERROR_DUEL_OPPONENT_LOGOUT    = 55 # 相手が離脱している為、ゲームを開始できません

  ERROR_FRIEND_APPLY            = 60 # そのプレイヤーにはフレンド申請出来ません
  ERROR_FRIEND_CONFIRM          = 61 # そのプレイヤーは許可できませんでした
  ERROR_FRIEND_DELETE           = 62 # そのプレイヤーは削除出来ません
  ERROR_FRIEND_OWN_MAX          = 63 # フレンド最大値に達していて、申請できません。
  ERROR_FRIEND_OTHER_MAX        = 64 # 相手のフレンド最大値に達していて申請できません。
  ERROR_BLOCK_APPLY             = 65 # そのプレイヤーはブロック出来ません
  ERROR_BLOCK_MAX               = 66 # ブロック出来る最大数に達しました

  ERROR_DRAW_LOT                = 70 # クジを引くのを失敗
  ERROR_ITEM_NOT_BOSS_FLAG      = 71 # 達成度がMAXに達していないので使えません
  ERROR_ITEM_NOT_EXIST          = 72 # アイテムが存在しない
  ERROR_COPY_CARD               = 73 # カード複製に失敗しました
  ERROR_ITEM_UNABLE_MAP         = 74 # 現在表示しているマップでは使用できません

  ERROR_SEND_QUEST              = 80 # クエストを友人に送るのに失敗しました
  ERROR_SEND_QUEST_WRONG_QUEST  = 81 # クエストを渡すことが出来ません
  ERROR_SEND_QUEST_MAX          = 82 # 送り先のクエストが満杯でした
  ERROR_SEND_QUEST_SAME_IP      = 83 # 同じIPの相手にはクエストを送ることが出来ません。
  ERROR_SEND_QUEST_NOT_SENDER   = 84 # このクエストは、元の持ち主以外に送ることはできません。
  ERROR_SEND_QUEST_EVENT_QUEST  = 85 # このクエストは、送ることが出来ません

  ERROR_EVENT_SERIAL_CODE       = 90 # 無効なシリアルまたはすでに取得済みです。

  ERROR_PRF_BOSS_NOT_EXIST      = 100 # Bossのデッキが存在しない
  ERROR_PRF_DATA_NOT_EXIST      = 101 # 渦Dataが存在しない
  ERROR_PRF_FINISHED            = 102 # 渦戦闘は終了している
  ERROR_PRF_NOT_EXIST           = 103 # 渦が存在しない
  ERROR_PRF_HAVE_MAX_OVER       = 104 # 所持限界に達している
  ERROR_PRF_INV_NOT_EXIST       = 105 # 渦インベントリが存在しない
  ERROR_DECK_IS_ALREADY_USED    = 106 # デッキが使用中
  ERROR_DECK_IS_DIFFERENT       = 107 # 選択してるデッキが違う
  ERROR_PRF_NOT_FINISHED        = 108 # 終了処理が終わってない
  ERROR_PRF_CANT_HASH_COPY      = 109 # 設定上コピーできない
  ERROR_PRF_MEMBER_LIMIT_OVER   = 110 # 人数制限オーバー
  ERROR_PRF_ALREADY_HAD         = 111 # 所持している
  ERROR_PRF_WAS_GIVE_UP         = 112 # ギブアップ済み

  #
  # ============== アクティビティ定数 ==================
  #

  ACTV_START = 1

  #
  # ============== チュートリアル進行定数 ==================
  #
  TUTE_TYPE_START         = 0
  TUTE_TYPE_START_QUEST   = 1
  TUTE_TYPE_START_BATTLE  = 2
  TUTE_TYPE_START_END     = 3

  TUTE_TYPE_BATTLE        = 4
  TUTE_TYPE_CHANGE        = 5
  TUTE_TYPE_HILOW         = 6
  TUTE_TYPE_EVENT         = 7

  TUTE_TYPE_ENTRANCE      = 8
  TUTE_TYPE_QUEST         = 9
  TUTE_TYPE_DECK          = 10
  TUTE_TYPE_DUEL          = 11
  TUTE_TYPE_ITEM          = 12
  TUTE_TYPE_SHOP          = 13

  #
  # ============== クエストプレゼントお返しアイテム ==================
  #
  QUEST_PRESENTS  = [1] # から一つ

  #
  # ============== 渦関係定数 ==================
  #

  # 渦の種類
  PRF_TYPE_EVENT  = 1
  PRF_TYPE_NORMAL = 2
  PRF_TYPE_MMO_EVENT = 3 # 運営が発生させる渦

  # 渦の状態定数
  PRF_ST_UNKNOWN = 0
  PRF_ST_BATTLE  = 1
  PRF_ST_FINISH  = 2
  PRF_ST_VANISH  = 3
  PRF_ST_VAN_DEFEAT = 4

  # 渦インベントリの状態定数
  PRF_INV_ST_NEW        = 0 # 新規
  PRF_INV_ST_UNSOLVE    = 1 # 未解決
  PRF_INV_ST_INPROGRESS = 2 # 進行中
  PRF_INV_ST_SOLVED     = 3 # 解決
  PRF_INV_ST_PENDING    = 4 # 未決（まだ見つけてない）
  PRF_INV_ST_FAILED     = 5 # 失敗
  PRF_INV_ST_PRESENTED  = 6 # プレゼントされた
  PRF_INV_ST_GIVE_UP    = 7 # ギブアップ

  # 報酬の取得状態
  PRF_INV_REWARD_ST_STILL   = 0 # 条件未達成
  PRF_INV_REWARD_ST_READY   = 1 # 取得可能
  PRF_INV_REWARD_ST_ALREADY = 2 # 取得済み

  # 報酬のタイプ
  PRF_TRS_TYPE_RANK     = 0 # ランク報酬
  PRF_TRS_TYPE_DEFEAT   = 1 # 撃破報酬
  PRF_TRS_TYPE_FOUND    = 2 # 発見報酬
  PRF_TRS_TYPE_ALL      = 3 # 参加報酬

  # Hashコピータイプ
  PRF_COPY_TYPE_ALL     = 0 # 制限なし
  PRF_COPY_TYPE_OWNER   = 1 # 発見者のみ
  PRF_COPY_TYPE_FRIENDS = 2 # 発見者＆発見者のFriendのみ

  # 個人所有できる渦の最大数
  PROFOUND_MAX = 10

  # 渦の終了時間ロスタイム
  PRF_CLOSE_LOSS_TIME = 60 * 1 # 1分

  # 渦マップ最大数
  PRF_MAP_ID_MAX = 12
  # 各マップの渦配置最大数
  PRF_POS_IDX_MAX = 10

  # 強制終了時のパターン定数
  PRF_FINISHED_NONE    = 0
  PRF_FINISHED_DEFEAT  = 1 # 撃破
  PRF_FINISHED_TIME_UP = 2 # 時間切れ

  # 渦のメッセージ定数
  PRF_MSGDLG_DAMAGE = 0
  PRF_MSGDLG_REPAIR = 1

  # 渦関連NoticeType
  PRF_NOTICE_TYPES = [
    NOTICE_TYPE_GET_PROFOUND,
    NOTICE_TYPE_FIN_PRF_WIN,
    NOTICE_TYPE_FIN_PRF_REWARD,
    NOTICE_TYPE_FIN_PRF_RANKING,
    NOTICE_TYPE_FIN_PRF_FAILED
  ]

  PRF_SCORE_ADD_BASIS = 100
  PRF_SCORE_RAND_BASIS = 10

  # キャッシュにデータを保存する時間
  PRF_CACHE_TTL = 60 * 60 * 1

  # 渦ボス撃破後の表示時間(10分)
  PRF_LOSSTIME_TTL = 60 * 10

  # 渦のランキング保存時間
  PRF_RANKING_CACHE_TTL = 60 * 1

  # 渦終了ランキングNoticeのCache保存時間(3日)
  PRF_RANK_NOTICE_CACHE_TIME = 60 * 60 * 24 * 3

  # Bossのパラメータ表示開始HP計算係数 半分を切ったら表示開始
  PRF_BOSS_NAME_VIEW_START_HP_VAL = 2

  # 渦参加時の加算スコア
  PRF_JOIN_ADD_SCORE = 0

  # 渦戦闘時のターン数ボーナス係数
  PRF_SCORE_TURN_BUNUS_RATIO = 10
  # 渦戦闘時の最大ターン数ボーナス(10ターン分ボーナス)
  PRF_SCORE_MAX_TURN_BUNUS = 10 * PRF_SCORE_TURN_BUNUS_RATIO

  # ヘルプ送信間隔
  RAID_HELP_SEND_TIME = 10

  # 渦イベント自動発生グループID
  RAID_EVENT_AUTO_CREATE_GROUP_ID = 9999

  # 進行中渦Hashのキャッシュ保持時間(2時間)
  PRF_PLAYING_HASH_CACHE_TTL = 60 * 60 * 2

  #
  # ============== レイド関連定数 ==================
  #
  RAID_FINDER_START_POINT_DEF = 10
  RAID_MEMBER_LIMIT_DEF = 100

  #
  # ============== イベントランキング定数 ==================
  #
  TOTAL_EVENT_RANKING_TYPE_FRIEND         = false # フレンド関連アイテムイベントランキング
  TOTAL_EVENT_RANKING_TYPE_ACHIEVEMENT    = false # レコード加算イベントランキングフラグ
  TOTAL_EVENT_RANKING_TYPE_ITEM_NUM       = false # アイテム個数算イベントランキングフラグ
  TOTAL_EVENT_RANKING_TYPE_ITEM_POINT     = false # アイテムポイントイベントランキングフラグ
  TOTAL_EVENT_RANKING_TYPE_PRF_ALL_DMG    = true  # 渦総合ダメージイベントランキングフラグ

  TOTAL_EVENT_RANKING_ACHIEVEMENT_ID = 528
  TOTAL_EVENT_RANKING_CNT_ITEM_IDS = [227, 228]
  TOTAL_EVENT_RANKING_POINT_ITEM_IDS = [130, 131, 132, 133]
  TOTAL_EVENT_RANKING_ITEM_POINT = { 130 => 1, 131 => 1, 132 => 1, 133 => 50 }

  #
  # ============== キャラ人気投票定数 ==================
  #
  CHARA_VOTE_ITEM_START_ID         = 402
  CHARA_VOTE_ITEM_END_ID           = 477

  CHARA_VOTE_ITEM_ID_LIST = Range.new(CHARA_VOTE_ITEM_START_ID, CHARA_VOTE_ITEM_END_ID).to_a

  #
  # ============== フレンド合算アイテム収集イベント定数 ==================
  #
  EVENT_WITH_FRIEND_ITEM_ID_START = 166
  EVENT_WITH_FRIEND_ITEM_ID_END   = 169
  EVENT_WITH_FRIEND_ITEM_ID_RANGE = Range.new(EVENT_WITH_FRIEND_ITEM_ID_START, EVENT_WITH_FRIEND_ITEM_ID_END)

  EVENT_ITEM_POINTS = { 166 => 1, 167 => 2, 168 => 10, 169 => 50 }
  FRIEND_COEFFICIENT = 10

  #
  # ============== Infectionコラボ定数 ==================
  #
  INFECTION_COLLABO_PRESENTS = [
    { type: TG_AVATAR_ITEM, id: 9, num: 5, sct_type: 0 },
    { type: TG_CHARA_CARD, id: 10011, num: 1, sct_type: 0 },
    { type: TG_AVATAR_PART, id: 428, num: 1, sct_type: 0 },
  ]

  #
  # ============== クランプスクリック定数 ==================
  #
  CLAMPS_CLICK_PRESENT = [
    { type: TG_AVATAR_ITEM, id: 235, num: 1, sct_type: 0 },
  ]

  # ============== キャラクターグループ定数 ==================
  CHARA_GROUP_MEMBERS = {
    'regiment' => [
      1,
      2,
      3,
      4,
      5,
      8,
      10,
      13,
      14,
      24,
      25,
      54,
      58,
      62,
      66
    ],
    'lonsbrough' => [
      3,
      20,
      27,
      48
    ]
  }

  #
  # ============== クエストイベント定数 ==================
  #
  QUEST_TYPE_NORMAL     = 0
  QUEST_TYPE_EVENT      = 1
  QUEST_TYPE_TUTORIAL   = 2
  QUEST_TYPE_CHARA_VOTE = 3

  QUEST_TUTORIAL_ID = 2
  QUEST_TUTORIAL_MAP_START = 2008

  QUEST_EVENT_ID = 9
  QUEST_EVENT_MAP_START = 3026

  QUEST_CHARA_VOTE_ID = 4
  QUEST_CHARA_VOTE_MAP_START = 5000
  QUEST_CHARA_VOTE_MAP_END   = 5006 # キャラ人気投票クエストは初めから全て表示する為

  # クエストボス出現アイテム関連
  QUEST_AREA_MAP_LIST = {
    QUEST_TYPE_NORMAL => [
      [0, 1, 2],
      [3, 4, 5, 6, 7, 8, 9, 10],
      [11, 12, 13, 14, 15, 16, 17, 18],
      [19, 20, 21, 22, 23, 24, 25, 26],
      [27, 28, 29, 30, 31, 32, 33, 34],
      [35],
    ],
    QUEST_TYPE_EVENT => [
      [3026, 3027, 3028, 3029, 3030],
    ],
    QUEST_TYPE_TUTORIAL => [
      [2009, 2010, 2011, 2012, 2013],
    ],
    QUEST_TYPE_CHARA_VOTE => [
      [5001, 5002, 5003, 5004, 5005, 5006, 5007, 5008, 5009, 5010],
    ]
  }

  #
  # ============== 武器合成関連定数 ==================
  #
  WEAPON_TYPE_NORMAL     = 0
  WEAPON_TYPE_MATERIAL   = 1
  WEAPON_TYPE_CMB_WEAPON = 2

  COMB_BASE_TOTAL_MAX = 2
  COMB_ADD_TOTAL_MAX = 20

  COMB_EXP_ITEM_IDS = [5024, 5025, 5026, 5027, 5028, 5029]

  #
  # ============== デバッグコード定数 ==================
  #

  DEBUG_CODE_ENEMY_DAMEGE_10         = 0
  DEBUG_CODE_SELF_DAMAGE_1           = 1
  DEBUG_CODE_SET_LAST_TURN           = 2
  DEBUG_CODE_ALL_HP_REMAIN_1         = 3
  DEBUG_CODE_SELF_ALL_DAMAGE_1       = 4
end
