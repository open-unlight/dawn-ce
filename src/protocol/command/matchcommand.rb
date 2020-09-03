# -*- coding: utf-8 -*-
module Unlight
  # GameServerコマンド一覧
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



       # =========================================
       # ロビーコマンド
       # =========================================
       # マッチリストリスト情報要求
       [:cs_request_match_list_info,
       ],

       # クイックスタートユーザーリストに登録
       [:cs_add_quickmatch_list,
        [# Name, Type, Size
         ["rule", :char, 1],
        ]
       ],

       # マッチングキャンセル
       [:cs_quickmatch_cancel,
       ],

       # 新しい部屋を作成
       [:cs_create_room,
        [# Name, Type, Size
         ["name", :String, 0],
         ["stage", :char, 1],
         ["rule", :char, 1],
         ["option", :char, 1],
         ["level", :char, 1],
        ]
       ],

       # 指定した部屋に入室
       [:cs_room_join,
        [# Name, Type, Size
         ["room_id", :String, 0],
        ]
       ],

       # 部屋から出る
       [:cs_room_exit,
        [# Name, Type, Size
        ]
       ],

       # 指定した部屋を削除
       [:cs_room_delete,
        [# Name, Type, Size
         ["room_id", :String, 0],
        ]
       ],

       # マッチング情報要求
       [:cs_request_matching_info,
       ],

       # セッションの選択
       [:cs_select_game_session,
        [# Name, Type, Size
         ["id", :int, 4 ],
        ]
       ],

       # マッチ終了チェック
       [:cs_match_finish,
        [# Name, Type, Size
        ]
       ],

       # アチーブメントがクリアされていないかチェック
       [:cs_achievement_clear_check,
        [# Name, Type, Size
        ]
       ],

       # フレンド情報を問い合せる
       [:cs_room_friend_check,
        [# Name, Type, Size
         ["room_id", :String, 0],
         ["host_avatar_id", :int, 4],
         ["guest_pavatar_id", :int, 4],
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


       # =========================================
       # ロビーコマンド
       # =========================================
       #
#        # チャンネルリストの情報を送る
#        [:sc_channel_list_info,
#         [# Name, Type, Size
#          ["id", :String, 0],
#          ["name", :String, 0],
#          ["rule", :String, 0],
#          ["max", :String, 0],
#          ["caption", :String, 0],
#         ]
#        ],
       # チャンネルから退出成功

       [:sc_channel_join_success,
        [# Name, Type, Size
         ["channel_id", :int, 4],
        ]
       ],
       # チャンネルから退出成功
       [:sc_channel_exit_success,
        [# Name, Type, Size
        ]
       ],

       # ゲームロビーの情報を送る
       [:sc_matching_info,
        [# Name, Type, Size
         ["info", :String, 0],
#          ["name", :String, 0],
#          ["stage", :String, 0],
#          ["rule", :String, 0],
#          ["avatar_name", :String, 0],
#          ["avatar_level", :String, 0],
#          ["avatar_cc", :String, 0],
#          ["avatar_id", :String, 0],
#          ["avatar_comment", :String, 0],
#          ["avatar_point", :String, 0],
#          ["avatar_win", :String, 0],
#          ["avatar_lose", :String, 0],
#          ["avatar_draw", :String, 0]
        ],
         true
       ],

       # ゲームロビーの情報を送る
       [:sc_matching_info_update,
        [# Name, Type, Size
         ["info", :String, 0],
#          ["name", :String, 0],
#          ["stage", :int, 4],
#          ["rule", :int, 4],
#          ["avatar_name", :String, 0],
#          ["avatar_level", :String, 0],
#          ["avatar_cc", :String, 0],
#          ["avatar_id", :String, 0],
#          ["avatar_comment", :String, 0],
#          ["avatar_point", :String, 0],
#          ["avatar_win", :String, 0],
#          ["avatar_lose", :String, 0],
#          ["avatar_draw", :String, 0],
        ]
       ],

       # 製作した部屋のidを送る
       [:sc_create_room_id,
        [# Name, Type, Size
         ["id", :String, 0],
        ]
       ],

       # 部屋から出る
       [:sc_room_exit_success,
        [# Name, Type, Size
        ]
       ],

       # 削除した部屋のidを送る
       [:sc_delete_room_id,
        [# Name, Type, Size
         ["id", :String, 0],
        ]
       ],

       # AP不足やルール不適合などのエラーコードを返します
       [:sc_error_no,
        [# Name, Type, Size
         ["error_type", :int   , 4],
        ]
       ],

       # マッチ成立
       [:sc_match_join_ok,
        [# Name, Type, Size
         ["id", :String, 0],
        ]
       ],

       # クイックマッチ成立
       [:sc_quickmatch_join_ok,
        [# Name, Type, Size
         ["id", :String, 0],
        ]
       ],

       # マッチングリストに登録できたか
       [:sc_quickmatch_regist_ok,
        [# Name, Type, Size

        ]
       ],

       # マッチングキャンセルの成否
       [:sc_quickmatch_cancel,
        [# Name, Type, Size
        ]
       ],

       # updateCount信号
       [:sc_update_count,
        [# Name, Type, Size
         ["count", :int   , 4],
        ]
       ],

       # KeepAlive信号
       [:sc_keep_alive,
        [# Name, Type, Size
        ]
       ],

       # アチーブメント達成
       [:sc_achievement_clear,
        [# Name, Type, Size
         ["achi_id",:int, 4],
         ["item_type",:int, 4],
         ["item_id",:int, 4],
         ["item_num",:int, 4],
         ["slot_type",:int, 4],
        ]
       ],

       # 新しいアチーブメントが追加される
       [:sc_add_new_achievement,
        [# Name, Type, Size
         ["achi_id",:int, 4],
        ]
       ],

       # アチーブメントが削除される
       [:sc_delete_achievement,
        [# Name, Type, Size
         ["achi_id",:int, 4],
        ]
       ],

       # アチーブメント情報をアップデート
       [:sc_update_achievement_info,
        [# Name, Type, Size
         ["achievements", :String, 0],
         ["achievements_state", :String, 0],
         ["achievements_progress", :String, 0],
         ["achievements_end_at", :String, 0],
         ["achievements_code", :String, 0],
        ],
       ],

       # フレンド情報の回答
       [:sc_room_friend_info,
        [# Name, Type, Size
         ["room_id", :String, 0],
         ["host_is_friend", :Boolean, 1],
         ["guest_is_friend", :Boolean, 1],
        ]
       ],

     ]
  end
end
