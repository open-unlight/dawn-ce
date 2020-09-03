# -*- coding: utf-8 -*-
module Unlight
  # WatchServerコマンド一覧
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
       # ゲームコマンド
       # =========================================
       # Duelのスタート
       [:cs_watch_start,
        [# Name, Type, Size
         ["u_id", :String, 0 ],
        ]
       ],

       # コマンド取得開始
       [:cs_watch_command_get_start,
        [# Name, Type, Size
        ]
       ],

       # 観戦終了
       [:cs_watch_finish,
        [# Name, Type, Size
        ]
       ],

       # クライアントの準備OK
       [:cs_start_ok,
        [# Name, Type, Size
        ]
       ],

       # アバターの持っているアイテムを使用する
       [:cs_avatar_use_item,
        [# Name, Type, Size
         ["inv_id", :int, 4],
        ]
       ],

       # 観戦キャンセル
       [:cs_watch_cancel,
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

       # 観戦キャンセル完了
       [:sc_watch_cancel,
        [# Name, Type, Size
        ]
       ],


       # =========================================
       # ゲームコマンド
       # =========================================
       #

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
         ["start_dialogue_id", :int, 4],
         ["stage", :char, 1],
         ["pl_hp", :String, 0],
         ["foe_hp", :String, 0],
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
         ["gems_pow", :int, 4],
         ["exp_pow", :int, 4],
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
         ["damage", :char, 1],
         ["is_not_hostile", :Boolean, 1],
        ]
       ],

       # パーティダメージイベント
       [:sc_entrant_party_damaged_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["index", :int, 4],
         ["damage", :char, 1],
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

       # キャラカード交換イベント
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
       # Finishイベント
       # =====================
       # WatchDuelFinishEvent
       [:sc_watch_duel_finish_event,
        [# Name, Type, Size
         ["is_end",:Boolean, 1],
         ["winner_name",:String, 0],
        ]
       ],

       # =====================
       # 準備イベント
       # =====================
       [:sc_set_chara_buff_event,
        [# Name, Type, Size
         ["player",:Boolean, 1],
         ["buff_str",:String, 0],
        ]
       ],

       [:sc_reset_deck_num_event,
        [# Name, Type, Size
         ["deck_size",:int, 4],
        ]
       ],

       [:sc_set_initi_and_dist_event,
        [# Name, Type, Size
         ["initi",:Boolean, 1],
         ["dist",:int, 4],
        ]
       ],


       # =====================
       # 退出
       # =====================
       # WatchDuelRoomOut
       [:sc_watch_duel_room_out,
        [# Name, Type, Size
        ]
       ],



     ]
  end
end
