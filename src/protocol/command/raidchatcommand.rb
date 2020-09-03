# -*- coding: utf-8 -*-
module Unlight
  # RaidChatServerコマンド一覧
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

       # コメントを保存
       [:cs_set_comment,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["comment", :String, 0],
         ["last_id", :int, 4],
        ]
       ],

       # コメントを取得
       [:cs_request_comment,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["last_id", :int, 4],
        ]
       ],

       # ボスHP更新
       [:cs_update_boss_hp,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["now_dmg", :int, 4],
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

       # コメントを送信
       [:sc_update_comment,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["comment", :String, 0],
         ["last_id", :int, 4],
        ],
        true                    # zlib圧縮ON
       ],

       # BossHP更新
       [:sc_send_boss_damage,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["damage", :int, 4],
         ["str_data", :String, 0],
         ["state",  :int, 4],
         ["state_update", :Boolean, 1],
        ]
       ],

       # BossHP更新
       [:sc_update_boss_hp,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["damage", :int, 4],
        ]
       ],

      ]
  end
end
