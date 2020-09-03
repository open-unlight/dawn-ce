# -*- coding: utf-8 -*-
module Unlight
  # LobbyServeコマンド一覧
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

       # 作製終了
       [:cs_create_avatar_success,
       ],

       # 他のアバター情報要求
       [:cs_request_other_avatar_info,
        [# Name, Tyep, Size
         ["id", :int, 4],
        ]
       ],
       # ストーリー情報を送る
       [:cs_request_story_info,
        [# Name, Type, Size
         ["ok", :String, 0],
         ["id", :int, 4],
         ["crypted_sign", :String, 0],
        ]
       ],
       # フレンド情報のリクエスト
       [:cs_request_friends_info,
       ],
       # フレンド情報のリクエスト
       [:cs_request_friend_list,
        [# Name, Type, Size
         ["type", :int, 4],
         ["offset", :int, 4],
         ["count", :int, 4],
        ]
       ],
       # フレンドの招待
       [:cs_friend_invite,
        [# Name, Type, Size
         ["uid", :String, 0],
        ]
       ],
       # フレンドへカムバック依頼
       [:cs_send_comeback_friend,
        [# Name, Type, Size
         ["uid", :String, 0],
        ]
       ],
       # プレイヤーが存在するか？
       [:cs_check_exist_player,
        [# Name, Type, Size
         ["uid", :String, 0],
        ]
       ],
       # チャンネルリスト情報要求
       [:cs_request_channel_list_info,
        
       ],

       # 自分のランクをもらう
       [:cs_request_rank_info,
        [# Name, Type, Size
         ["kind", :char, 1],
         ["server_type", :int, 4],
        ]
       ],
       # デュエルランキングのリストをもらう
       [:cs_request_ranking_list,
        [# Name, Type, Size
         ["kind", :char, 1],
         ["offset", :char, 1],
         ["count", :char, 1],
         ["server_type", :int, 4],
        ]
       ],
       # アバター検索
       [:cs_find_avatar,
        [# Name, Type, Size
         ["avatar_name", :String, 0],
        ]
       ],

       # 渦を取得
       [:cs_get_profound,
        [# Name, Type, Size
         ["hash", :String, 0],
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

       # データバージョンを送る
       [:sc_data_version_info,
        [# Name, Type, Size
         ["action_card", :int, 4],
         ["chara_card", :int, 4],
         ["feat", :int, 4],
         ["dialogue", :int, 4],
         ["story", :int, 4],
         ["quest_log", :int, 4],
         ["avatar_item", :int, 4],
         ["avatar_part", :int, 4],
         ["event_card", :int, 4],
         ["weapon_card", :int, 4],
         ["equip_card", :int, 4],
         ["quest", :int, 4],
         ["quest_map", :int, 4],
         ["quest_land", :int, 4],
         ["growth_tree", :int, 4],
        ]
       ],
       # アバター情報を送る
       [:sc_avatar_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["name", :String, 0],
         ["gems", :int, 4],
         ["exp", :int, 4],
         ["level", :int, 4],
         ["energy", :int, 4],
         ["energy_max", :int, 4],
         ["recov_inter", :int, 4],
         ["remain_time", :int, 4],
         ["point", :int, 4],
         ["win", :int, 4],
         ["lose", :int, 4],
         ["draw", :int, 4],
         ["part_num", :int, 4],
         ["part_inv_id", :String, 0],
         ["part_array", :String, 0],
         ["part_used", :String, 0],
         ["part_end_at", :String, 0],
         ["item_num", :int, 4],
         ["item_inv_id", :String, 0],
         ["item_array", :String, 0],
         ["item_state_array", :String, 0],
         ["deck_num", :int, 4],
         ["deck_name", :String, 0],
         ["deck_kind", :String, 0],
         ["deck_level", :String, 0],
         ["deck_exp", :String, 0],
         ["deck_status", :String, 0],
         ["deck_cost", :String, 0],
         ["deck_max_cost", :String, 0],
         ["card_num", :int, 4],
         ["card_inv_id", :String, 0],
         ["card_array", :String, 0],
         ["deck_index", :String, 0],
         ["deck_position", :String, 0],
         ["slots_num", :int, 4],
         ["slot_inv_id", :String, 0],
         ["slot_array", :String, 0],
         ["slot_type", :String, 0],
         ["slot_combined", :String, 0],
         ["slot_combine_data", :String, 0],
         ["slot_deck_index", :String, 0],
         ["slot_deck_position", :String, 0],
         ["slot_card_position", :String, 0],
         ["quest_max", :char, 1],
         ["quest_num", :char, 1],
         ["quest_inv_id", :String, 0],
         ["quest_array", :String, 0],
         ["quest_status", :String, 0],
         ["quest_find_time", :String, 0],
         ["quest_ba_name", :String, 0],
         ["quest_flag", :int, 4],
         ["quest_clear_num", :int, 4],
         ["friend_max", :int, 4],
         ["part_max", :int, 4],
         ["free_duel_count", :char, 1],

         ["exp_pow", :int, 4],
         ["gem_pow", :int, 4],
         ["quest_find_pow", :int, 4],

         ["current_deck", :char, 1],
         ["sale_type", :char, 1],
         ["sale_limit_rest_time", :int, 4],

         ["favorite_chara_id", :int, 4],

         ["floor_count", :int, 4],  # By_K2

         ["event_quest_flag", :int, 4],
         ["event_quest_clear_num", :int, 4],
         ["tutorial_quest_flag", :int, 4],
         ["tutorial_quest_clear_num", :int, 4],
         ["chara_vote_quest_flag", :int, 4],
         ["chara_vote_quest_clear_num", :int, 4],
        ],
        true                    # zlib圧縮ON
       ],

       # アチーブメント情報を送る
       [:sc_achievement_info,
        [# Name, Type, Size
         ["achievements", :String, 0],
         ["achievements_state", :String, 0],
         ["achievements_progress", :String, 0],
         ["achievements_end_at", :String, 0],
         ["achievements_code", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # レジスト情報を送る
       [:sc_regist_info,
        [# Name, Type, Size
         ["parts", :String, 0],
         ["cards", :String, 0],
        ]
       ],


       # 他人のアバター情報を送る
       [:sc_other_avatar_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["name", :String, 0],
         ["level", :int, 4],
         ["setted_part_array", :String, 0],
         ["bp", :int, 4],
        ]
       ],
       # ストーリー情報を送る
       [:sc_story_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["book_type", :int, 4],
         ["title", :String, 0],
         ["content", :String, 0],
         ["image", :String, 0],
         ["age_no", :String, 0],
         ["version", :int, 4],
        ],
        true                    # zlib圧縮ON
       ],

       #フレンドリストのIDを送る
       [:sc_friend_list_info,
        [# Name, Type, Size
         ["id", :String, 0],
         ["avatar_ids", :String, 0],
         ["status", :String, 0],
         ["sns_ids", :String, 0],
        ]
       ],
       #フレンドリストのIDを送る
       [:sc_friend_list,
        [# Name, Type, Size
         ["id", :String, 0],
         ["avatar_ids", :String, 0],
         ["status", :String, 0],
         ["sns_ids", :String, 0],
         ["type", :int, 4],
         ["offset", :int, 4],
         ["fl_num", :int, 4],
         ["bl_num", :int, 4],
         ["rq_num", :int, 4],
        ]
       ],
       # プレイヤーが存在するかの確認
       [:sc_exist_player_info,
        [# Name, Type, Size
         ["uid", :String, 0],
         ["id", :int, 4],
         ["av_id", :int, 4],
        ]
       ],
       # チャンネルリストの情報を送る
       [:sc_channel_list_info,
        [# Name, Type, Size
         ["id", :String, 0],
         ["name", :String, 0],
         ["rule", :String, 0],
         ["max", :String, 0],
         ["host", :String, 0],
         ["port", :String ,0],
         ["duel_host", :String, 0],
         ["duel_port", :String, 0],
         ["chat_host", :String, 0],
         ["chat_port", :String, 0],
         ["watch_host", :String, 0],
         ["watch_port", :String, 0],
         ["state", :String, 0],
         ["caption", :String, 0],
         ["count", :String, 0],
         ["penalty_type", :String, 0],
         ["cost_limit_min", :String, 0],
         ["cost_limit_max", :String, 0],
         ["watch_mode", :String, 0],
        ],
        true
       ],

       # ランクをアップデート
       [:sc_update_rank,
        [# Name, Type, Size
         ["type",:char, 1],
         ["rank",:int, 4],
         ["point",:int, 4],
        ]
       ],
       #トータル デュエルランキングのリストをアップデート
       [:sc_update_total_duel_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],
       # 週刊デュエルランキングのリストをアップデート
       [:sc_update_weekly_duel_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # トータルクエストランキングをアップデート
       [:sc_update_total_quest_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # 週刊クエストランキングをアップデート
       [:sc_update_weekly_quest_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # 週刊クエストランキングをアップデート
       [:sc_update_total_chara_vote_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # 週刊クエストランキングをアップデート
       [:sc_update_total_event_ranking_list,
        [# Name, Type, Size
         ["start", :char, 1],
         ["name_list", :String, 0],
        ],
        true                    # zlib圧縮ON
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
       # 検索結果のアバターリスト
       [:sc_result_avatars_list,
        [# Name, Type, Size
         ["avatars", :String, 0],
        ],
       ],

      ]
  end
end
