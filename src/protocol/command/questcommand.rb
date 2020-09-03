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


       # アバターのアップデートをチェック
       [:cs_avatar_update_check,
        [# Name, Type, Size
        ]
       ],

       # アバターがマップからクエストを取得
       [:cs_get_quest,
        [# Name, Type, Size
         ["quest_map_id", :int, 4],
         ["find_time", :int, 4],
        ]
       ],


      # 特定地域のクエストマップを要求
       [:cs_request_quest_map_info,
        [# Name, Type, Size
         ["region",:int, 4],
        ]
       ],

       # アバターの持っているアイテムを使用する
       [:cs_avatar_use_item,
        [# Name, Type, Size
         ["inv_id", :int, 4],
         ["quest_map_no", :int, 4],
        ]
       ],

       # アバターがアイテムを買う
       [:cs_avatar_buy_item,
        [# Name, Type, Size
         ["shop_id", :int, 4],
         ["inv_id", :int, 4],
        ]
       ],

       # 特定ページのログを要求
       [:cs_get_quest_log_page_info,
        [# Name, Type, Size
         ["page",:int, 4],
        ]
       ],

       # ログ内容を要求
       [:cs_get_quest_log_info,
        [# Name, Type, Size
         ["id",:int, 4],
        ]
       ],

       # ログを書き込む
       [:cs_set_quest_log,
        [# Name, Type, Size
         ["content", :String, 0],
        ]
       ],

       # Questを確認した
       [:cs_quest_confirm,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["deck_index",:char, 1],
        ]
       ],

       # Questをスタートした
       [:cs_quest_start,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["deck_index",:char, 1],
        ]
       ],

       # Questを断念した
       [:cs_quest_abort,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["deck_index",:char, 1],
        ]
       ],

       # Questを破棄した
       [:cs_quest_delete,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # Questを進めた
       [:cs_quest_next_land,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["deck_index",:char, 1],
         ["next_no",:char, 1],
        ]
       ],

       # Questが見つかったかのチェック
       [:cs_quest_check_find,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # Questが見つかったかのチェック
       [:cs_send_quest,
        [# Name, Type, Size
         ["avt_id",:int, 4],
         ["inv_id",:int, 4],
        ]
       ],




       # =========================================
       # ゲームコマンド
       # =========================================
       #
#        # 参加カードのセレクト
#        [:cs_select_chara_card,
#         [# Name, Type, Size
#          ["id", :int, 1],
#         ]
#        ],

       # セッションの選択
       [:cs_select_game_session,
        [# Name, Type, Size
         ["id", :int, 1 ],
        ]
       ],

       # アクションカードの情報要求
       [:cs_request_actioncard_info,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # アクションカードのバージョン情報要求
       [:cs_request_actioncard_ver_info,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # クライアントの準備OK
       [:cs_start_ok,
        [# Name, Type, Size
        ]
       ],

       # 移動方向を決定
       [:cs_set_direction,
        [# Name, Type, Size
         ["dir", :char, 1],
        ]
       ],

       # 移動テーブルにカード追加
       [:cs_move_card_add,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
         ["dir", :Boolean, 1],
        ]
       ],

       # テーブルから削除
       [:cs_move_card_remove,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
        ]
       ],

       # イニシアチブ決定
       [:cs_init_done,
        [# Name, Type, Size
         ["card_events", :String, 0],
         ["chara_events", :String, 0],
        ]
       ],

       # 移動決定
       [:cs_move_done,
        [# Name, Type, Size
         ["move", :char, 1],
         ["card_events", :String, 0],
         ["chara_events", :String, 0],
        ]
       ],

       # 攻撃カードをテーブルに追加
       [:cs_attack_card_add,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
         ["dir", :Boolean, 1],
        ]
       ],

       # 攻撃カードをテーブルから削除
       [:cs_attack_card_remove,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
        ]
       ],

       # 防御カードをテーブルに追加
       [:cs_deffence_card_add,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
         ["dir", :Boolean, 1],
        ]
       ],

       # 防御カードをテーブルから削除
       [:cs_deffence_card_remove,
        [# Name, Type, Size
         ["card", :int, 4],
         ["index", :char, 1],
        ]
       ],

       # 攻撃テーブルで回転
       [:cs_card_rotate,
        [# Name, Type, Size
         ["card", :int, 4],
         ["table", :char, 1],
         ["index", :char, 1],
         ["up", :Boolean, 1],
        ]
       ],

       # 攻撃決定、カード
       [:cs_attack_done,
        [# Name, Type, Size
         ["card_events", :String, 0],
         ["chara_events", :String, 0],
        ]
       ],

       # 攻撃決定、カード
       [:cs_deffence_done,
        [# Name, Type, Size
         ["card_events", :String, 0],
         ["chara_events", :String, 0],
        ]
       ],

       # キャラ変更
       [:cs_chara_change,
        [# Name, Type, Size
         ["index", :char, 1],
        ]
       ],

       # =========================================
       # リザルトコマンド
       # =========================================
       # UP
       [:cs_result_up,
        [# Name, Type, Size
        ]
       ],
       [:cs_result_down,
        [# Name, Type, Size
        ]
       ],
       [:cs_result_cancel,
        [# Name, Type, Size
        ]
       ],
       [:cs_retry_reward,
        [# Name, Type, Size
        ]
       ],

       # デバッグコードを送る
       [:cs_debug_code,
        [# Name, Type, Size
         ["code", :char, 1],
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

#        # 行動力を回復
#        [:sc_recovery_energy,
#         [# Name, Type, Size
#          ["energy",:int, 4],
#         ]
#        ],


       # アバターがクエストを取得
       [:sc_get_quest,
        [# Name, Type, Size
         ["inv_id", :int, 4],
         ["quest_id", :int, 4],
         ["find_at", :int, 4],
         ["pow", :int, 4],
         ["state", :char, 1],
         ["ba_name", :String, 0],
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

       # クエスト数の更新をおくる
       [:sc_update_quest_max,
        [# Name, Type, Size
         ["quest_max",:int, 4],
        ]
       ],

       # Gemの更新
       [:sc_update_gems,
        [# Name, Type, Size
         ["gems",:int, 4],
        ]
       ],

       # アイテムゲット
       [:sc_get_item,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["item_id",:int, 4],
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

       # アバターがクエストマップを取得
       [:sc_quest_map_info,
        [# Name, Type, Size
         ["region", :int, 4],
         ["map_list", :String, 0],
        ]
       ],

       # クエストログの情報
       [:sc_quest_log_page_info,
        [# Name, Type, Size
         ["page",:int, 4],
         ["content_ids", :String, 0],
        ]
       ],

       # クエストログの情報
       [:sc_quest_log_info,
        [# Name, Type, Size
         ["id",:int, 4],
         ["content", :String, 0],
        ]
       ],

       # クエストの状態をアップデート
       [:sc_quest_state_update,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["state", :char, 1],
         ["quest_id",:int, 4],
        ]
       ],

       # クエストの探索時間をアップデート
       [:sc_quest_find_at_update,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["find_at",:int, 4],
        ]
       ],

       # クエストのMap進行状態をアップデート
       [:sc_quest_map_progress_update,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["progress", :int, 4],
        ]
       ],

       # クエストキャラデッキの状態をアップデート
       [:sc_deck_state_update,
        [# Name, Type, Size
         ["deck_index",:char, 1],
         ["state", :char, 1],
         ["hp_0", :char, 1],
         ["hp_1", :char, 1],
         ["hp_2", :char, 1],
        ]
       ],

       # クエストが失敗
       [:sc_quest_failed,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # クエストが削除される
       [:sc_quest_deleted,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],

       # クエストで宝箱を手に入れた
       [:sc_quest_treasure_got,
        [# Name, Type, Size
         ["type",:char, 1],
         ["id",:int, 4],
        ]
       ],

       # クエストで宝箱を手に入れた
       [:sc_quest_finish,
        [# Name, Type, Size
         ["result",:char, 1],
         ["id",:int, 4],
        ]
       ],

       # クエストで宝箱を手に入れた
       [:sc_get_quest_treasure,
        [# Name, Type, Size
         ["type",:char, 1],
         ["c_type",:int, 4],
         ["value",:int, 4],
        ]
       ],

       # クエスト進行度がアップデートされた
       [:sc_quest_flag_update,
        [# Name, Type, Size
         ["flag",:int, 4],
        ]
       ],

       # By_K2 (무한의탑 층수 UP)
       [:sc_floor_count_update,
        [# Name, Type, Size
         ["flag",:int, 4],
        ]
       ],

       # クエスト達成度がアップデートされた
       [:sc_quest_clear_num_update,
        [# Name, Type, Size
         ["clear_num",:int, 4],
        ]
       ],

       # AP不足やルール不適合などのエラーコードを返します
       [:sc_error_no,
        [# Name, Type, Size
         ["error_type", :int   , 4],
        ]
       ],

       # イベントクエスト進行度がアップデートされた
       [:sc_event_quest_flag_update,
        [# Name, Type, Size
         ["quest_type",:int, 4],
         ["flag",:int, 4],
        ]
       ],

       # イベントクエスト達成度がアップデートされた
       [:sc_event_quest_clear_num_update,
        [# Name, Type, Size
         ["quest_type",:int, 4],
         ["clear_num",:int, 4],
        ]
       ],



       # =========================================
       # ゲームコマンド
       # =========================================
       #

       # アクションカードの総数を送る
       [:sc_actioncard_length,      # CMD_No, Command
        [# Name, Type, Size
         ["length", :int, 4],
        ]
       ],

       # アクションカード情報を送る
       [:sc_actioncard_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["ut", :char, 1],
         ["uv", :char, 1],
         ["bt", :char, 1],
         ["bv", :char, 1],
         ["en", :char, 1],
         ["image", :String, 0],
         ["caption", :String, 0],
         ["version", :int, 4],
        ]
       ],

       # アクションカードバージョン情報を送る
       [:sc_actioncard_ver_info,
        [# Name, Type, Size
         ["id", :int, 4],
         ["version", :int, 4],
        ]
       ],

       # インフォ
       [:sc_message,
        [# Name, Type, Size
         ["msg", :String, 0],
        ]
       ],

       # インフォ
       [:sc_message_str_data,
        [# Name, Type, Size
         ["str", :String, 0],
        ]
       ],

      # セッションの決定
       [:sc_determine_session,
        [# Name, Type, Size
         ["id", :int, 4],
         ["foe", :String, 0],
         ["player_chara_card_id", :String, 0],
         ["foe_chara_card_id", :String, 0],
         ["start_dialogue", :String, 0],
         ["foe_dialogue", :String, 0],
         ["stage", :char, 1],
         ["pl_hp0", :char, 1],
         ["pl_hp1", :char, 1],
         ["pl_hp2", :char, 1],
         ["foe_hp0", :char, 1],
         ["foe_hp1", :char, 1],
         ["foe_hp2", :char, 1],
        ]
       ],

      # 追加のキャラカードインベントリを送る
       [:sc_chara_card_inventory_info,
        [# Name, Type, Size
         ["inv_id", :String, 0],
         ["card_id", :String, 0],
        ]
       ],


       # ========================
       # ゲーム本編
       # ========================

       # デュエルの開始
       [:sc_one_to_one_duel_start,
        [# Name, Type, Size
         ["deck_size", :char, 1],
         ["player_event_deck_size", :char, 1],
         ["foe_deck_size", :char, 1],
         ["distance", :char, 1],
        ]
       ],

       # デュエルの開始
       [:sc_three_to_three_duel_start,
        [# Name, Type, Size
         ["deck_size", :char, 1],
         ["player_event_deck_size", :char, 1],
         ["foe_event_deck_size", :char, 1],
         ["distance", :char, 1],
         ["multi", :Boolean,1],
        ]
       ],

      # デュエルの終了
      # ゲーム結果結果
       [:sc_one_to_one_duel_finish,
        [# Name, Type, Size
         ["result", :char, 1],
         ["gems", :int, 4],
         ["exp", :int, 4],
         ["exp_bonus", :int, 4],
         ["gems_pow", :int, 4],
         ["exp_pow", :int, 4],
         ["gems_total", :int, 4],
         ["exp_total", :int, 4],
         ["bonus", :Boolean, 1],
         ]
       ],

      # デュエルの終了
      # ゲーム結果結果
       [:sc_three_to_three_duel_finish,
        [# Name, Type, Size
         ["result", :char, 1],
         ["gems", :int, 4],
         ["exp", :int, 4],
         ["bonus", :Boolean, 1],
         ]
       ],

       # ========================
       # DuelPhase
       # ========================

       # ターンのスタート
       [:sc_duel_start_turn_phase,
        [# Name, Type, Size
         ["turn_count", :char, 1],
        ]
       ],

       # 補充フェイズの終了
       [:sc_duel_refill_phase,
        [# Name, Type, Size
         ["list", :String, 0],
         ["dir", :int, 4],
         ["foe_size", :char, 1],
        ]
       ],

       # イベントカード補充フェイズの終了
       [:sc_duel_refill_event_phase,
        [# Name, Type, Size
         ["list", :String, 0],
         ["dir", :int, 4],
         ["foe_size", :char, 1],
        ]
       ],

       # 移動カード提出フェイズの開始
       [:sc_duel_move_card_drop_phase_start,
        [# Name, Type, Size
        ]
       ],

       # 移動カード提出フェイズの終了
       [:sc_duel_move_card_drop_phase_finish,
        [# Name, Type, Size
        ]
       ],

       # 移動フェイズの終了
       [:sc_duel_determine_move_phase,
        [# Name, Type, Size
         ["init", :Boolean,1],
         ["dist", :char,1],
         ["list", :String, 0],
         ["dir", :String, 0],
         ["foe_list", :String, 0],
         ["foe_dir", :String, 0],
         ["pow", :char, 1],
         ["foe_pow", :char, 1],
         ["lock", :Boolean, 1],
         ["foe_lock", :Boolean, 1],
        ]
       ],

       # キャラ変更フェイズの開始
       [:sc_duel_chara_change_phase_start,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["foe", :Boolean, 1],
        ]
       ],

       # キャラ変更フェイズの終了
       [:sc_duel_chara_change_phase_finish,
        [# Name, Type, Size
        ]
       ],

       # 攻撃カード提出フェイズの開始
       [:sc_duel_attack_card_drop_phase_start,
        [# Name, Type, Size
         ["attack", :Boolean,1],
        ]
       ],

       # 攻撃カード提出フェイズの終了
       [:sc_duel_attack_card_drop_phase_finish,
        [# Name, Type, Size
         ["list", :String, 0],
         ["dir", :String, 0],
         ["foe_list", :String, 0],
         ["foe_dir", :String, 0],
         ["lock", :Boolean, 1],
         ["foe_lock", :Boolean, 1],
        ]
       ],

       # 防御カード提出フェイズの開始
       [:sc_duel_deffence_card_drop_phase_start,
        [# Name, Type, Size
         ["deffence", :Boolean,1],
        ]
       ],

       # 防御カード提出フェイズの終了
       [:sc_duel_deffence_card_drop_phase_finish,
        [# Name, Type, Size
         ["list", :String, 0],
         ["dir", :String, 0],
         ["foe_list", :String, 0],
         ["foe_dir", :String, 0],
         ["lock", :Boolean, 1],
         ["foe_lock", :Boolean, 1],
        ]
       ],

       # 戦闘ポイントの結果フェイズの終了
       [:sc_duel_determine_battle_point_phase,
        [# Name, Type, Size
         ["list", :String, 0],
         ["dir", :String, 0],
         ["foe_list", :String, 0],
         ["foe_dir", :String, 0],
         ["lock", :Boolean, 1],
         ["foe_lock", :Boolean, 1],
        ]
       ],

       # 戦闘結果フェイズの終了
       [:sc_duel_battle_result_phase,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["attack_dice", :String, 0],
         ["deffence_dice", :String, 0],
        ]
       ],

       # 死亡キャラ変更フェイズの開始
       [:sc_duel_dead_chara_change_phase_start,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["foe", :Boolean, 1],
         ["list", :String, 0],
         ["foe_list", :String, 0],
        ]
       ],

       # 死亡キャラ変更フェイズの終了
       [:sc_duel_dead_chara_change_phase_finish,
        [# Name, Type, Size
        ]
       ],

       # ターン終了フェイズ
       [:sc_duel_finish_turn_phase,
        [# Name, Type, Size
        ]
       ],


       # =====================
       # アクション
       # =====================
       # 移動方向決定アクション（通信：位置）
       [:sc_entrant_set_direction_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["dir", :char, 1],
        ]
       ],

       # 移動カード追加アクション（通信：位置）
       [:sc_entrant_move_card_add_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :char, 1],
         ["id", :int, 4],
        ]
       ],

      # 移動カードを戻すアクション（通信:位置）
       [:sc_entrant_move_card_remove_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :char, 1],
         ["id", :int, 4],
        ]
       ],

      # カードの回転アクション（通信：位置）
       [:sc_entrant_card_rotate_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["table", :char, 1],
         ["index", :char, 1],
         ["id", :int, 4],
         ["dir",:Boolean, 1],
        ]
       ],

      # カードの回転アクション（通信：位置）
       [:sc_entrant_event_card_rotate_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["table", :char, 1],
         ["index", :char, 1],
         ["id", :int, 4],
         ["dir",:Boolean, 1],
        ]
       ],

      # 戦闘カードの追加アクション（通信：位置）
       [:sc_entrant_battle_card_add_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :char, 1],
         ["id", :int, 4],
        ]
       ],

       # 戦闘カードを戻すアクション(通信:位置)
       [:sc_entrant_battle_card_remove_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :char, 1],
         ["id", :int, 4],
        ]
       ],

       # イニシアチブの決定
       [:sc_entrant_init_done_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # 戦闘の決定
       [:sc_entrant_attack_done_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # 戦闘の決定
       [:sc_entrant_deffence_done_action,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # 移動
       [:sc_entrant_move_action,
        [# Name, Type, Size
         ["dist", :char,1],
        ]
       ],

       # ハイド中の移動
       [:sc_entrant_hide_move_action,
        [# Name, Type, Size
         ["dist", :char, 1],
        ]
       ],

       # キャラカードを変更
       [:sc_entrant_chara_change_action,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["index", :char, 1],
         ["card_id", :int, 4],
         ["weapon_bonus", :String, 0],
        ]
       ],

       # =====================
       # Entrantイベント
       # =====================

       # ダメージイベント
       [:sc_entrant_damaged_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["damage", :int, 4],
         ["is_not_hostile", :Boolean, 1],
        ]
       ],

       # パーティダメージイベント
       [:sc_entrant_party_damaged_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :int, 4],
         ["damage", :int, 4],
         ["is_not_hostile", :Boolean, 1],
        ]
       ],

       # 蘇生イベント
       [:sc_entrant_revive_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :int, 4],
         ["rhp", :int, 4],
        ]
       ],

       # 行動制限イベント
       [:sc_entrant_constraint_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["flag",:int, 4],
        ]
       ],

       # 回復イベント
       [:sc_entrant_healed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["heal", :char, 1],
        ]
       ],

       # パーティ回復イベント
       [:sc_entrant_party_healed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :int, 4],
         ["heal", :char, 1],
        ]
       ],

       # HP変更イベント
       [:sc_entrant_hit_point_changed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["hp", :int, 4],
        ]
       ],

       # 状態回復イベント
       [:sc_entrant_cured_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # 必殺技解除イベント
       [:sc_entrant_sealed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # ポイント更新イベント
       [:sc_entrant_point_update_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["point", :int, 4],
        ]
       ],

       # ポイント上書きイベント
       [:sc_entrant_point_rewrite_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["point", :int, 4],
        ]
       ],

       # イベントカード使用イベント
       [:sc_entrant_use_action_card_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["used_card_id", :int, 4],
        ]
       ],

       # カード破棄イベント
       [:sc_entrant_discard_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["discard_id", :int, 4],
        ]
       ],

       # カード破棄イベント
       [:sc_entrant_discard_table_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["discard_id", :int, 4],
        ]
       ],

       # 特別にカードを配られるイベント
       [:sc_entrant_special_dealed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["size", :int, 4],
        ]
       ],

       # 墓地のカードが配られるイベント
       [:sc_entrant_grave_dealed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["size", :int, 4],
        ]
       ],

       # プレイヤーからプレイヤーへカードが配られるイベント
       [:sc_entrant_steal_dealed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["size", :int, 4],
        ]
       ],

       # 特別にイベントカードを配られるイベント
       [:sc_entrant_special_event_card_dealed_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["size", :int, 4],
        ]
       ],

       # カードの値の変更を通知
       [:sc_entrant_update_card_value_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["id", :int, 4],
         ["u_value", :int, 4],
         ["b_value", :int, 4],
         ["reset", :Boolean, 1],
        ]
       ],

       # 装備カード更新イベント
       [:sc_entrant_update_weapon_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["pl_bonus", :String, 0],
         ["foe_bonus", :String, 0],
        ]
       ],

       # 最大カード数更新イベント
       [:sc_entrant_cards_max_update_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["cards_max", :char, 1],
        ]
       ],

       # トラップ発動イベント
       [:sc_entrant_trap_action_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["kind",:int, 4],
         ["distance", :int, 4],
        ]
       ],

       # トラップ状態遷移イベント
       [:sc_entrant_trap_update_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["kind",:int, 4],
         ["distance", :int, 4],
         ["turn", :int, 4],
         ["visible",:Boolean, 1],
        ]
       ],

       # フィールド状態変更イベント
       [:sc_set_field_status_event,
        [# Name, Type, Size
         ["kind",:int, 4],
         ["pow",:int, 4],
         ["turn", :int, 4],
        ]
       ],

       # ボーナスゲット
       [:sc_duel_bonus_event,
        [# Name, Type, Size
         ["bonus_type",:char, 1],
         ["value",:char, 1],
        ]
       ],

       # 現在ターン数変更
       [:sc_set_turn_event,
        [# Name, Type, Size
         ["turn", :int, 4],
        ]
       ],

       # カードロックイベント
       [:sc_card_lock_event,
        [# Name, Type, Size
         ["id", :int, 4],
        ]
       ],

       # カードロック解除イベント
       [:sc_clear_card_locks_event,
        [# Name, Type, Size
        ]
       ],

       # =====================
       # Deckイベント
       # =====================

       # デッキを初期化
       [:sc_deck_init_event,
        [# Name, Type, Size
         ["deck_size", :char, 1],
        ]
       ],

       # =====================
       # ActionCardイベント
       # =====================

       # チャンスイベント
       [:sc_actioncard_chance_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["list", :String, 0],
         ["dir", :int, 4],
         ["size", :int, 4],
        ]
       ],

       # =====================
       # CharaCardイベント
       # =====================

       # 状態付加ONイベント
       [:sc_buff_on_event,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["index", :int, 4],
         ["buff_id", :int, 4],
         ["value", :int, 4],
         ["turn", :int, 4],
        ]
       ],

       # 状態付加OFFイベント
       [:sc_buff_off_event,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["index", :int, 4],
         ["buff_id", :int, 4],
         ["value", :int, 4],
        ]
       ],

       # 状態付加UPDATEイベント
       [:sc_buff_update_event,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["buff_id", :int, 4],
         ["value", :int, 4],
         ["index", :int, 4],
         ["turn", :int, 4],
        ]
       ],

       # 猫状態UPDATEイベント
       [:sc_cat_state_update_event,
        [# Name, Type, Size
         ["player", :Boolean, 1],
         ["index", :int, 4],
         ["value", :Boolean, 1],
        ]
       ],

       # 必殺技ONイベント
       [:sc_pl_feat_on_event,
        [# Name, Type, Size
         ["feat_id", :int, 4],
        ]
       ],

       # 必殺技OFFイベント
       [:sc_pl_feat_off_event,
        [# Name, Type, Size
         ["feat_id", :int, 4],
        ]
       ],

       # 必殺技変更イベント
       [:sc_entrant_change_feat_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["chara_index", :int, 4],
         ["feat_index", :int, 4],
         ["feat_id", :int, 4],
         ["feat_no", :int, 4],
        ]
       ],

       # 必殺技使用イベント
       [:sc_entrant_use_feat_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["used_feat_id", :int, 4],
        ]
       ],

       # パッシブ使用イベント
       [:sc_entrant_use_passive_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["used_passive_id", :int, 4],
        ]
       ],

       # キャラカード変更イベント
       [:sc_entrant_change_chara_card_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["chara_card_id", :int, 4],
        ]
       ],

       # キャラカード変身イベント
       [:sc_entrant_on_transform_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["transform_type", :int, 4],
        ]
       ],

       # キャラカード変身解除イベント
       [:sc_entrant_off_transform_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
        ]
       ],

       # パッシブスキル発動
       [:sc_entrant_on_passive_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["skill_id",:int, 4],
        ]
       ],

       # パッシブスキル終了
       [:sc_entrant_off_passive_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["skill_id",:int, 4],
        ]
       ],

       # きりがくれ
       [:sc_entrant_on_lost_in_the_fog_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["distance",:int, 4],
         ["truth_distance",:int, 4],
        ]
       ],

       # きりがくれ終了
       [:sc_entrant_off_lost_in_the_fog_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["distance",:int, 4],
        ]
       ],

       # きりがくれライト
       [:sc_entrant_in_the_fog_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["range",:String, 0],
        ]
       ],

       # 技の発動条件を更新
       [:sc_entrant_update_feat_condition_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["chara_index",:int, 4],
         ["feat_index",:int, 4],
         ["condition", :String, 0],
        ]
       ],

       # ヌイグルミセット
       [:sc_entrant_stuffed_toys_set_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["num",:int, 4],
        ]
       ],

       # =====================
       # Rewardイベント
       # =====================
       [:sc_reward_candidate_cards_list,
        [# Name, Type, Size
         ["candidate_list_1", :String, 0],
         ["candidate_list_2", :String, 0],
         ["candidate_list_3", :String, 0],
         ["candidate_list_4", :String, 0],
         ["start_bonus", :int, 4],
        ]
       ],


       # 基本のダイス
       [:sc_bottom_dice_num,
        [# Name, Type, Size
         ["buttom_dice", :String, 0],
        ]
       ],

       # ハイローの結果を返す
       [:sc_high_low_result,
        [# Name, Type, Size
         ["win",:Boolean, 1],
         ["getted_cards", :String, 0],
         ["next_cards", :String, 0],
         ["bonus", :int, 4],
        ]
       ],


       # 結果のダイス
       [:sc_reward_result_dice,
        [# Name, Type, Size
         ["result_dice", :String, 0],
        ]
       ],

       # 報酬の最終結果結果を返す
       [:sc_reward_final_result,
        [# Name, Type, Size
         ["getted_cards", :String, 0],
         ["total_gems", :int, 4],
         ["total_exp", :int, 4],
         ["add_point", :int, 4],
        ]
       ],

       # アイテム使用
       [:sc_use_item,
        [# Name, Type, Size
         ["inv_id",:int, 4],
        ]
       ],
       # アイテム使用
       [:sc_next_success,
        [# Name, Type, Size
         ["next_no",:char, 1],
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

       # アバターパーツを取得
       [:sc_get_part,
        [# Name, Type, Size
         ["inv_id",:int, 4],
         ["part_id",:int, 4],
        ]
       ],

       # 台詞情報を送信
       [:sc_dialogue_info_update,
        [# Name, Type, Size
         ["dialogue",:String, 0],
         ["id",:int, 4],
         ["type",:char, 1],
        ]
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



      ]

  end
end
