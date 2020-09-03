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


       # アバター情報要求
       [:cs_request_avater_info,
       ],

       # カード情報を設定
       [:cs_update_card_inventory_info,
        [# Name, Type, Size
         ["inv_id", :int, 4],
         ["index", :int, 4],
         ["position", :int, 4],
        ]
       ],

       # スロットカード情報を設定
       [:cs_update_slot_card_inventory_info,
        [# Name, Type, Size
         ["kind", :char, 1],
         ["inv_id", :int, 4],
         ["index", :char, 1],
         ["deck_position", :char, 1],
         ["card_position", :char, 1],
        ]
       ],

       # デッキ名を設定
       [:cs_update_deck_name,
        [# Name, Type, Size
         ["index", :int, 4],
         ["name", :String, 0],
        ]
       ],
       # 新規にデッキを作成
       [:cs_create_deck,
       ],

       # 新規にデッキを作成
       [:cs_delete_deck,
        [# Name, Type, Size
         ["index", :int, 4],
        ]
       ],

       # アバターを作成する
       [:cs_create_avatar,
        [# Name, Type, Size
         ["name", :String, 0],
         ["parts", :String, 0],
         ["cards", :String, 0],
         ["invite_code", :int, 4],
        ]
       ],

       # アバターの名前をチェックする
       [:cs_check_avatar_name,
        [# Name, Type, Size
         ["name", :String, 0],
        ]
       ],

       # カレントデッキを変更する
       [:cs_update_current_deck_index,
        [# Name, Type, Size
         ["index", :int, 4],
        ]
       ],
       # フレンドリスト要求
       [:cs_request_friend_list,
       ],
       # 合成可能か？要求
       [:cs_request_exchangeable_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["c_id", :int, 4],
        ]
       ],

       # カードの合成
       [:cs_request_exchange,
        [# Name, Type, Size
         ["id", :int, 4],
         ["c_id", :int, 4],
        ]
       ],

       # カードの合成
       [:cs_request_combine,
        [# Name, Type, Size
         ["inv_id_list", :String, 0],
        ]
       ],

       # アバターのアップデートをチェック
       [:cs_avatar_update_check,
        [# Name, Type, Size
        ]
       ],

       # アバターの持っているアイテムを使用する
       [:cs_avatar_use_item,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
       ],

       # ショップ情報要求
       [:cs_request_shop_info,
        [# Name, Type, Size
         ["shop_type", :int, 4],
        ]
       ],

       # アバターがアイテムを買う
       [:cs_avatar_buy_item,
        [# Name, Type, Size
         ["shop_id", :int, 4],
         ["inv_id", :int, 4],
         ["amount", :int, 4],
        ]
       ],

       # アバターがスロットカードを買う
       [:cs_avatar_buy_slot_card,
        [# Name, Type, Size
         ["shop_id", :int, 4],
         ["kind", :int, 4],
         ["inv_id", :int, 4],
         ["amount", :int, 4],
        ]
       ],

       # アバターがキャラカードを買う
       [:cs_avatar_buy_chara_card,
        [# Name, Type, Size
         ["shop_id", :int, 4],
         ["inv_id", :int, 4],
         ["amount", :int, 4],
        ]
       ],


       # アバターがパーツを買う
       [:cs_avatar_buy_part,
        [# Name, Type, Size
         ["shop_id", :int, 4],
         ["inv_id", :int, 4],
        ]
       ],

#        # チャンネルリスト情報要求
#        [:cs_request_channel_list_info,

#        ],

       # リアルマネーアイテム情報の要求
       [:cs_request_real_money_item_info,
        [# Name, Type, Size
        ]
       ],

       # リアルマネーアイテムをチェックの要求
       [:cs_real_money_item_result_check,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # フレンド情報要求
       [:cs_request_friend_info,
       ],

       # フレンド申請
       [:cs_friend_apply,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # フレンド申請許可
       [:cs_friend_confirm,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # フレンド削除
       [:cs_friend_delete,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # レアカードクジをひく
       [:cs_draw_lot,
        [# Name, Type, Size
         ["kind", :char, 1],
        ]
       ],

       # カードを複製する
       [:cs_copy_card,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # パーツのセット
       [:cs_set_avatar_part,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # パーツが消滅していなかチェック
       [:cs_parts_vanish_check,
        [# Name, Type, Size
        ]
       ],
       # パーツを捨てる
       [:cs_part_drop,
        [# Name, Type, Size
         ["invID", :int, 4],
         ]
       ],

       # アチーブメントがクリアされていないかチェック
       [:cs_achievement_clear_check,
        [# Name, Type, Size
         ["notice_check", :Boolean, 1],
        ]
       ],

       # アチーブメントがクリアされていないかチェック
       [:cs_achievement_special_clear_check,
        [# Name, Type, Size
         ["number", :int, 4],
        ]
       ],

       # ロビーニュースを読んだ
       [:cs_notice_clear,
        [# Name, Type, Size
         ["num", :int, 4],
         ["args", :String, 0],
        ]
       ],

       # セール時間情報要求
       [:cs_request_sale_limit_info,
       ],

       # アチーブメント情報の取得
       [:cs_request_achievement_info,
       ],

       # イベントシリアルコード
       [:cs_event_serial_code,
        [# Name, Type, Size
         ["serial", :String, 0],
         ["pass", :String, 0],
        ],
       ],

       # ブロック申請
       [:cs_block_apply,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # 新しい渦のチェック
       [:cs_new_profound_inventory_check,
        [# Name, Type, Size
        ]
       ],

       # 渦を取得
       [:cs_change_favorite_chara_id,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # リザルト画像を変更
       [:cs_change_result_image,
        [# Name, Type, Size
         ["id", :int, 4],
         ["image_no", :int, 4],
        ]
       ],

       # ロビー会話：スタート
       [:cs_lobby_chara_dialogue_start,
        [# Name, Type, Size
        ]
       ],

       # ロビー会話：アップデート
       [:cs_lobby_chara_dialogue_update,
        [# Name, Type, Size
        ]
       ],

       # ロビー会話：選択パネルを選ぶ
       [:cs_lobby_chara_select_panel,
        [# Name, Type, Size
         ["index", :char, 1],
        ]
       ],

       # コラボイベントシリアルコード
       [:cs_infection_collabo_serial_code,
        [# Name, Type, Size
         ["serial", :String, 0],
        ],
       ],

       # クランプスクリック
       [:cs_clamps_click,
        [# Name, Type, Size
        ],
       ],

       # クランプ出現チェック
       [:cs_clamps_appear_check,
        [# Name, Type, Size
        ],
       ],

       # Noticeでの選択アイテムを取得
       [:cs_get_notice_selectable_item,
        [# Name, Type, Size
         ["args", :String, 0],
        ],
       ],

       # ProfoundNoticeのみクリア
       [:cs_profound_notice_clear,
        [# Name, Type, Size
         ["num", :int, 4],
        ]
       ],

       # インベントリ更新終了チェック
       [:cs_inventory_update_check,
        [# Name, Type, Size
        ],
       ],

       # デッキ所持数チェック
       [:cs_deck_max_check,
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
       # ニュースを送る
       [:sc_news,
        [# Name, Type, Size
         ["news", :String, 0],
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

       # アバターを作ることに成功
       [:sc_create_avatar_success,
        [# Name, Type, Size
         ["success", :Boolean, 1],
        ]
       ],
       # アバターの名前をチェックする
       [:sc_check_avatar_name,
        [# Name, Type, Size
         ["code", :int, 4],
        ]
       ],
       # デッキを作成することに成功
       [:sc_create_deck_success,
        [# Name, Type, Size
         ["deck_name", :String, 0],
         ["deck_kind", :int, 4],
         ["deck_level", :int, 4],
         ["deck_exp", :int, 4],
         ["deck_status", :int, 4],
         ["deck_cost", :int, 4],
         ["deck_max_cost", :int, 4],
         ["card_set", :String, 0],
        ]
       ],
       # デッキを消去することに成功
       [:sc_delete_deck_success,
        [# Name, Type, Size
         ["index", :int, 4],
        ]
       ],
       # カレントデッキを変更する
       [:sc_update_current_deck_index,
        [# Name, Type, Size
         ["index", :int, 4],
        ]
       ],

       # キャラカードを更新することに失敗
       [:sc_update_card_inventory_failed,
        [# Name, Type, Size
         ["error_no",:int, 4],
         ["inv_id", :int, 4],
         ["index", :char, 1],
         ["position", :char, 1],
        ]
       ],

       # スロットカードを更新することに失敗
       [:sc_update_slot_card_inventory_failed,
        [# Name, Type, Size
         ["kind", :char, 1],
         ["error_no",:int, 4],
         ["inv_id", :int, 4],
         ["index", :char, 1],
         ["card_position", :char, 1],
         ["deck_position", :char, 1],
        ]
       ],

       # 追加のカード情報を送る
       [:sc_chara_card_inventory_info,
        [# Name, Type, Size
         ["inv_id", :String, 0],
         ["card_id", :String, 0],
        ]
       ],

       # 合成可能かの情報を送る
       [:sc_exchangeble_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["exchageble",:Boolean, 1],
        ]
       ],

       # 合成結果をおくる
       [:sc_exchange_result,
        [# Name, Type, Size
         ["success",:Boolean, 1],
         ["id", :int, 4],
         ["new_inv_id", :int, 4],
         ["lost_inv_id", :String, 0],
        ]
       ],

       # 合成結果をおくる
       [:sc_combine_result,
        [# Name, Type, Size
         ["success",:Boolean, 1],
         ["id", :int, 4],
         ["new_inv_id", :int, 4],
        ]
       ],

       # ログインボーナスをおくる
       [:sc_login_bonus,
        [# Name, Type, Size
         ["type",:int, 4],
         ["slot",:int, 4],
         ["id",:int, 4],
         ["value",:int, 4],
        ]
       ],

       # 行動力をおくる
       [:sc_energy_info,
        [# Name, Type, Size
         ["energy",:int, 4],
         ["remainTime",:int, 4],
        ]
       ],

       # 行動力をおくる
       [:sc_update_energy_max,
        [# Name, Type, Size
         ["energy_max",:int, 4],
        ]
       ],

       # フレンドMAXをおくる
       [:sc_update_friend_max,
        [# Name, Type, Size
         ["friend_max",:int, 4],
        ]
       ],

       # パーツMAXをおくる
       [:sc_update_part_max,
        [# Name, Type, Size
         ["part_max",:int, 4],
        ]
       ],

       # 経験値獲得
       [:sc_get_exp,
        [# Name, Type, Size
         ["exp",:int, 4],
        ]
       ],

       # レベルアップ
       [:sc_level_up,
        [# Name, Type, Size
         ["level",:int, 4],
        ]
       ],

       # デッキ経験値獲得
       [:sc_get_deck_exp,
        [# Name, Type, Size
         ["deck_exp",:int, 4],
        ]
       ],

       # デッキレベルアップ
       [:sc_deck_level_up,
        [# Name, Type, Size
         ["deck_level",:int, 4],
        ]
       ],

       # Gemの更新
       [:sc_update_gems,
        [# Name, Type, Size
         ["gems",:int, 4],
        ]
       ],

       # 勝敗の更新
       [:sc_update_result,
        [# Name, Type, Size
         ["point",:int, 4],
         ["win",:int, 4],
         ["lose",:int, 4],
         ["draw",:int, 4],
        ]
       ],

       # アイテムゲット
       [:sc_get_item,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["item_id",:int, 4],
        ]
       ],

       # アイテム使用
       [:sc_use_item,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # コイン消費
       [:sc_use_coin,
        [# Name, Type, Size
         ["inv_ids",:String, 0],
        ]
       ],

       # スロットカードゲット
       [:sc_get_slot_card,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["kind",:int, 4],
         ["card_id",:int, 4],
        ]
       ],

       # キャラカードゲット
       [:sc_get_chara_card,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["card_id",:int, 4],
        ]
       ],

       # ショップ情報を送る
       [:sc_shop_info,
        [# Name, Type, Size
         ["shop_type", :int, 4],
         ["sale_list", :String, 0],
        ]
       ],

#        # チャンネルリストの情報を送る
#        [:sc_channel_list_info,
#         [# Name, Type, Size
#          ["id", :String, 0],
#          ["name", :String, 0],
#          ["rule", :String, 0],
#          ["max", :String, 0],
#          ["host", :String, 0],
#          ["port", :String ,0],
#          ["duel_host", :String, 0],
#          ["duel_port", :String, 0],
#          ["chat_host", :String, 0],
#          ["chat_port", :String, 0],
#          ["state", :String, 0],
#          ["caption", :String, 0],
#          ["count", :String, 0],
#         ],
#         true
#        ],

       # リアルマネーアイテムの情報を送る
       [:sc_real_money_item_info,
        [# Name, Type, Size
         ["size", :char, 1],
         ["sale_list", :String, 0],
        ]
       ],


       # AP不足やルール不適合などのエラーコードを返します
       [:sc_error_no,
        [# Name, Type, Size
         ["error_type", :int   , 4],
        ]
       ],

       # KeepAlive信号
       [:sc_keep_alive,
        [# Name, Type, Size
        ]
       ],

       # フレンド申請の成功
       [:sc_friend_apply_success,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # フレンドの認証の成功
       [:sc_friend_confirm_success,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # フレンド削除の成功
       [:sc_friend_delete_success,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # レアカードを引くのに成功
       [:sc_draw_rare_card_success,
        [# Name, Type, Size
         ["got_card_kind", :char, 1],
         ["got_id", :int, 4],
         ["got_card_num", :char, 1],
         ["blank_card_kind1", :char, 1],
         ["blank1_id", :int, 4],
         ["blank1_card_num", :char, 1],
         ["blank_card_kind2", :char, 1],
         ["blank2_id", :int, 4],
         ["blank2_card_num", :char, 1],
        ]
       ],

       # カード複製に成功
       [:sc_copy_card_success,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # Activityをおくる
       [:sc_activity_feed,
        [# Name, Type, Size
         ["type", :char, 1],
        ]
       ],

       # フリーデュエルポイントををおくる
       [:sc_free_duel_count_info,
        [# Name, Type, Size
         ["fdc",:char, 1],
        ]
       ],

       # パーツの装備完了
       [:sc_equip_change_succ,
        [# Name, Type, Size
         ["id", :int, 4],
         ["unuse_api", :String, 0],
         ["end_at", :int, 4],
         ["status", :char, 1],
        ]
       ],

       # アバターパーツを取得
       [:sc_get_part,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["part_id",:int, 4],
        ]
       ],

       # 回復時間更新
       [:sc_update_recovery_interval,
        [# Name, Type, Size
         ["rec_time",:int, 4],
        ]
       ],

       # クエスト所持数更新
       [:sc_update_quest_inv_max,
        [# Name, Type, Size
         ["inv_max",:int, 4],
        ]
       ],

       # EXP倍率が更新
       [:sc_update_exp_pow,
        [# Name, Type, Size
         ["exp_pow",:int, 4],
        ]
       ],

       # GEM倍率が更新
       [:sc_update_gem_pow,
        [# Name, Type, Size
         ["gem_pow",:int, 4],
        ]
       ],


       # クエストゲット時間が更新される
       [:sc_update_quest_find_pow,
        [# Name, Type, Size
         ["quest_f_pow",:int, 4],
        ]
       ],

       # パーツが消滅
       [:sc_vanish_part,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["alert",:Boolean, 1],
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
       # ロビーのインフォメーションをアップデート
       [:sc_add_notice,
        [# Name, Type, Size
         ["body", :String, 0],
        ],
       ],

       # セール終了までの時間をアップデート
       [:sc_update_sale_rest_time,
        [# Name, Type, Size
         ["sale_type", :char, 1], # セールタイプも一緒に投げる
         ["rest_time", :int, 4],
        ],
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

       # アチーブメント情報をアップデート
       [:sc_serial_code_success,
        [# Name, Type, Size
         ["getted_itm", :String, 0],
        ],
       ],

       # コラボイベントシリアルコード入力成功
       [:sc_infection_collabo_serial_success,
        [# Name, Type, Size
         ["getted_itm", :String, 0],
        ],
       ],

       # クランプス出現
       [:sc_clamps_appear,
        [# Name, Type, Size
        ],
       ],

       # クランプスクリック成功
       [:sc_clamps_click_success,
        [# Name, Type, Size
         ["getted_itm", :String, 0],
        ],
       ],

       # アチーブメントが完全に削除される
       [:sc_drop_achievement,
        [# Name, Type, Size
         ["achi_id",:int, 4],
        ]
       ],

       # フレンドブロックの成功
       [:sc_friend_block_success,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # お気に入りキャラIDを設定する
       [:sc_change_favorite_chara_id,
        [# Name, Type, Size
         ["chara_id", :int, 4],
        ],
       ],

       # ロビー会話：ダイアログを出す
       [:sc_lobby_chara_dialogue,
        [# Name, Type, Size
         ["lines", :String, 0],
        ],
       ],

       # ロビー会話：選択パネルを出す
       [:sc_lobby_chara_select_panel,
        [# Name, Type, Size
         ["choices", :String, 0],
        ],
       ],

       # 合成武器情報を更新する
       [:sc_update_combine_weapon_data,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["card_id",:int, 4],
         ["base_sap",:char, 1],
         ["base_sdp",:char, 1],
         ["base_aap",:char, 1],
         ["base_adp",:char, 1],
         ["base_max",:int, 1],
         ["add_sap",:char, 1],
         ["add_sdp",:char, 1],
         ["add_aap",:char, 1],
         ["add_adp",:char, 1],
         ["add_max",:int, 4],
         ["passive_id",:String, 0],
         ["restriction", :String, 0],
         ["count_str",:String, 0],
         ["count_max_str",:String, 0],
         ["level",:int, 4],
         ["exp",:int, 4],
         ["psv_num_max",:char, 1],
         ["psv_pass_set",:String, 0],
         ["vani_psv_ids",:String, 0],
        ],
        true                    # zlib圧縮ON
       ],

       # カード情報を設定終了
       [:sc_update_card_inventory_info_finish,
        [# Name, Type, Size
        ]
       ],

       # スロットカード情報を設定終了
       [:sc_update_slot_card_inventory_info_finish,
        [# Name, Type, Size
        ]
       ],

       # スロットカード情報を設定終了
       [:sc_inventory_update_check,
        [# Name, Type, Size
         ["chara_card_inv_info",:Boolean, 1],
         ["slot_card_inv_info",:Boolean, 1],
        ]
       ],

       # デッキ所持数チェック
       [:sc_deck_max_check_result,
        [# Name, Type, Size
         ["ok",:Boolean, 1],
        ]
       ],

      ]
  end
end
