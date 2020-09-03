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

       # アバターの持っているアイテムを使用する
       [:cs_avatar_use_item,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
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

       # Noticeをチェック
       [:cs_request_notice,
        [# Name, Type, Size
        ]
       ],

       # 更新されたInventoryを取得
       [:cs_request_update_inventory,
        [# Name, Type, Size
         ["inv_id_list", :String, 0],
        ]
       ],

       # GiveUp
       [:cs_give_up_profound,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
       ],

       # CheckVanish
       [:cs_check_vanish_profound,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
       ],

       [:cs_check_profound_reward,
        [# Name, Type, Size
        ]
       ],

       # ボスHP更新
       [:cs_update_boss_hp,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["now_dmg", :int, 4],
        ]
       ],

       # デッキ変更
       [:cs_update_current_deck_index,
        [# Name, Type, Size
         ["index", :int, 4],
        ]
       ],

       # 渦を取得
       [:cs_get_profound,
        [# Name, Type, Size
         ["hash", :String, 0],
        ]
       ],

       # 渦のHashを取得
       [:cs_request_profound_hash,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # 渦の設定を変更
       [:cs_change_profound_config,
        [# Name, Type, Size
         ["id", :int, 4],
         ["type", :int, 4],
         ["set_defeat_reward", :Boolean, 1],
        ]
       ],

       # フレンドにも渦を追加する
       [:cs_send_profound_friend,
        [# Name, Type, Size
         ["prf_id", :int, 4],
        ]
       ],

       # ProfoundNoticeのみクリア
       [:cs_profound_notice_clear,
        [# Name, Type, Size
         ["num", :int, 4],
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

       # AP不足やルール不適合などのエラーコードを返します
       [:sc_error_no,
        [# Name, Type, Size
         ["error_type", :int   , 4],
        ]
       ],

       # 渦インベントリ情報の再送信
       [:sc_resend_profound_inventory,
        [# Name, Type, Size
         ["data_id", :int, 4],
         ["hash", :String, 0],
         ["close_at", :String, 0],
         ["created_at", :String, 0],
         ["state", :int, 4],
         ["map_id", :int, 4],
         ["pos_idx", :int, 4],
         ["copy_type", :int, 4],
         ["set_defeat_reward", :Boolean, 1],
         ["now_damage", :int, 4],
         ["finder_id", :int, 4],
         ["finder_name", :String, 0],
         ["inv_id", :int, 4],
         ["profound_id", :int, 4],
         ["deck_id", :int, 4],
         ["chara_card_dmg_1", :int, 4],
         ["chara_card_dmg_2", :int, 4],
         ["chara_card_dmg_3", :int, 4],
         ["damage_count", :int, 4],
         ["inv_state", :int, 4],
         ["deck_status", :int, 4],
        ]
       ],

       # 渦インベントリ情報の再送信完了
       [:sc_resend_profound_inventory_finish,
        [# Name, Type, Size
        ]
       ],

       # デッキ変更完了
       [:sc_update_current_deck_index,
        [# Name, Type, Size
         ["index", :int, 4],
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

       # アイテム使用
       [:sc_use_item,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # インフォメーションをアップデート
       [:sc_add_notice,
        [# Name, Type, Size
         ["body", :String, 0],
        ],
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

       # 渦のHashを取得
       [:sc_get_profound_hash,
        [# Name, Type, Size
         ["prf_id", :int, 4],
         ["hash", :String, 0],
         ["copy_type", :int, 4],
         ["set_defeat_reward", :Boolean, 1],
        ]
       ],

      ]
  end
end
