# -*- coding: utf-8 -*-
module Unlight
  # RaidRankServerコマンド一覧
  class Command

    RECEIVE_COMMANDS =
      [
       # ネゴシエーション
       [:negotiation,
        [# Name, Type, Size
         ["uid", :int, 4],
        ]
       ],
       # ログイン
       [:login,
        [# Name, Type, Size
         ["ok", :String, 0],
         ["crypted_sign", :String, 0],
        ]
       ],
       # ログアウト
       [:logout,
       ],

       # KeepAlive信号
       [:cs_keep_alive,
       ],

       # ランキングのリストをもらう
       [:cs_request_ranking_list,
        [# Name, Type, Size
         ["inv_id", :int, 4],
         ["offset", :char, 1],
         ["count", :char, 1],
        ]
       ],

       # 自分のランクをもらう
       [:cs_request_rank_info,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
       ],

       # 渦終了時のランキング取得
       [:cs_get_profound_result_ranking,
        [# Name, Type, Size
         ["prf_id", :int, 4],
        ]
       ],

      ]

    SEND_COMMANDS    =
      [
       # ログイン成功
       [:nego_cert,
        [# Name, Type, Size
         ["crypted_sign", :String, 0],
         ["ok", :String, 0],
        ]
       ],
       # ログイン成功
       [:login_cert,
        [# Name, Type, Size
         ["msg", :String, 0],
         ["hash_key", :String, 0],
        ]
       ],
       # ログイン失敗
       [:login_fail,      # CMD_No, Command
        [# Name, Type, Size
        ]
       ],

       # KeepAlive信号
       [:sc_keep_alive,
        [# Name, Type, Size
        ]
       ],

       # ランキングをアップデート
       [:sc_update_ranking_list,
        [# Name, Type, Size
         ["prf_id",:int, 4],
         ["start", :char, 1],
         ["rank_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # ランクをアップデート
       [:sc_update_rank,
        [# Name, Type, Size
         ["prf_id",:int, 4],
         ["rank",:int, 4],
         ["point",:int, 4],
        ]
       ],

       # 渦の最終ランキングを取得
       [:sc_profound_result_ranking,
        [# Name, Type, Size
         ["result_ranking", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

      ]
  end
end
