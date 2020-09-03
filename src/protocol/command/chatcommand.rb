# -*- coding: utf-8 -*-
module Unlight
  # ChatServerコマンド一覧
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

       # チャットメッセージ（ブロードキャスト）
       [:cs_message,
        [# Name, Type, Size
         ["msg", :String, 0],
        ]
       ],

       # チャットメッセージ（ROOM）
       [:cs_message_room,
        [# Name, Type, Size
         ["msg", :String, 0],
         ["room", :int, 4 ],
        ]
       ],

       # 対戦中チャットメッセージ
       [:cs_message_duel,
        [# Name, Type, Size
         ["msg", :String, 0],
         ["room", :int, 4 ],
        ]
       ],

       # チャンネルチャットメッセージ
       [:cs_message_channel,
        [# Name, Type, Size
         ["msg", :String, 0],
         ["channel", :int, 4 ],
        ]
       ],

       # 観戦者チャットメッセージ
       [:cs_message_audience,
        [# Name, Type, Size
         ["msg", :String, 0],
        ]
       ],

       # チャンネルチャットに入る
       [:cs_channel_in,
        [# Name, Type, Size
         ["channel", :int, 4 ],
        ]
       ],

       # チャンネルチャットから出る
       [:cs_channel_out,
        [# Name, Type, Size
         ["channel", :int, 4 ],
        ]
       ],

       # 観戦者チャンネルチャットに入る
       [:cs_audience_channel_in,
        [# Name, Type, Size
         ["room_id", :String, 0 ],
        ]
       ],

       # 観戦者チャンネルチャットから出る
       [:cs_audience_channel_out,
        [# Name, Type, Size
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
       # メッセージを送る
       [:sc_send_message,
        [# Name, Type, Size
         ["msg", :String, 0],
         ["type", :int, 4],
        ]
        ],

       # メッセージを送る
       [:sc_send_duel_message,
        [# Name, Type, Size
         ["avatar_id", :int, 4],
         ["msg", :String, 0],
        ]
        ],
       # メッセージを送る
       [:sc_send_channel_message,
        [# Name, Type, Size
         ["channel_id", :int, 4],
         ["msg", :String, 0],
        ]
        ],

       # メッセージを送る
       [:sc_send_audience_message,
        [# Name, Type, Size
         ["channel_id", :int, 4],
         ["msg", :String, 0],
        ]
        ],

       # KeepAlive信号
       [:sc_keep_alive,
        [# Name, Type, Size
        ]
       ],

      ]
  end
end
