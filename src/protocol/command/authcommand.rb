# -*- coding: utf-8 -*-
module Unlight
# AuthServeコマンド一覧
  class Command
  # 受信コマンド一覧
    # 名称：型：サイズ（0は可変）
    RECEIVE_COMMANDS =
      [
       # プレイヤー登録
       [:register,
        [# Name, Type, Size
         ["name", :String, 0],
         ["email", :String, 0],
         ["salt", :String, 0],
         ["verifire", :String, 0],
         ["server_type", :int, 4],
        ]
       ],
       # 認証問い合わせ
       [:auth_start,
        [ # Name, Type, Size
         ["name", :String, 0],
         ["client_pub_key",:String, 0],
        ]
       ],
       # 認証ゲット
       [:auth_get_matcher,
        [# Name, Type, Size
         ["matcher", :String, 0],
        ]
       ],
       # ログアウト
       [:logout,
       ],

       # OpenSocialAuth
       [:cs_open_social_auth,
        [# Name, Type, Size
         ["user_id", :String, 0],
         ["client_pub_key",:String, 0],
        ]
       ],

       # OpenSocialプレイヤー登録
       [:cs_open_social_register,
        [# Name, Type, Size
         ["use_id", :String, 0],
         ["salt", :String, 0],
         ["verifire", :String, 0],
         ["server_type", :int, 4],
        ]
       ],

       # KeepAlive信号
       [:cs_keep_alive,
       ],

       # OpenSocialプレイヤー再登録
       [:cs_reregister,
        [# Name, Type, Size
         ["use_id", :String, 0],
         ["salt", :String, 0],
         ["verifire", :String, 0],
         ["server_type", :int, 4],
        ]
       ],

       # 自分をインバイトしたユーザの更新
       [:cs_update_invited_user,
        [# Name, Type, Size
         ["users", :String, 0],
        ]
       ],

       # チュートリアルを再生した
       [:cs_update_tuto_play,
        [# Name, Type, Size
         ["type", :char, 1]
        ]
       ],





      ]

    # 送信コマンド一覧
    SEND_COMMANDS   =
      [
       # 登録の結果
       [:regist_result,
        [# Name, Type, Size
         ["result", :int, 4],
        ]
       ],
       # 認証のリターン
       [:auth_return,
        [# Name, Type, Size
         ["salt", :String, 0],
         ["server_pub_key", :String,  0]
        ]
       ],
       # 認証成功
       [:auth_cert,
        [# Name, Type, Size
         ["cert",:String, 0],
         ["uid", :int, 4]
        ]
       ],
       # 認証失敗
       [:auth_fail,      # CMD_No, Command
       ],
       # 人数制限
       [:auth_user_limit,      # CMD_No, Command
       ],
       # ロビー情報を送る
       [:lobby_info,    # CMD_No, Command
        [# Name, Type, Size
         ["ip", :String, 0],
         ["port", :int, 4]
        ]
       ],
       # OpenSocialNotresgit
       [:sc_open_social_not_regist,
        [# Name, Type, Size
        ]
       ],

       # KeepAlive信号
       [:sc_keep_alive,
        [# Name, Type, Size
        ]
       ],

       # AP不足やルール不適合などのエラーコードを返します
       [:sc_error_no,
        [# Name, Type, Size
         ["error_type", :int   , 4],
        ]
       ],

       # 認証失敗
       [:sc_request_reregist,      # 
       ],

      ]
  end
end
