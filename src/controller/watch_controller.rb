# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # Watch部分のコントローラ

  module WatchController
    def self::init
      @@audience_list = { } # 観客リスト
    end

    def self::audience_list
      @@audience_list
    end

    # ======================================
    # 受信コマンド
    # =====================================

    # 観戦開始
    def cs_watch_start(match_uid)
      match_log = MatchLog::get_cache(match_uid)
      # 観戦データを取得する
      watch_data = WatchDuel::get_cache_duel_data(match_uid)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [cs_watch_start] match_uid:#{match_uid} watch_data:#{watch_data} ")

      player_a = Player[watch_data[:pl_id]] if watch_data

      if  player_a&&match_log
        # もし前回のDuelが残っていたらまっさらにする
        if @duel
          @duel.entrants[@no].exit_game
          @duel.entrants[@foe].exit_game
          @duel.exit_game
          @duel = nil
        end

        player_b = Player[watch_data[:foe_id]]

        SERVER_LOG.info("<UID:#{@uid}>WatchServer: [cs_match_start] player_a:#{player_a} player_b:#{player_b}");

        unless player_b
          sc_error_no(ERROR_GAME_QUIT)
          return
        end

        a_avatar = player_a.current_avatar
        b_avatar = player_b.current_avatar
        a_deck   = a_avatar.duel_deck
        b_deck   = b_avatar.duel_deck

        watch_r_duel = WatchRealDuel.new(match_uid,match_log.match_rule,match_log.match_stage,a_deck,b_deck)

        # 部屋のルールを見て決める
        if match_log.cpu_card_data_id == PLAYER_MATCH
          if match_log.match_rule == RULE_1VS1
            SERVER_LOG.info("<UID:#{@uid}>WatchServer: [cs_watch_start] 1");
            # カレントのアバターが持つカレントカードでデュエル開始
            @duel = MultiDuel.new(a_avatar,
                                  b_avatar,
                                  a_deck,
                                  b_deck,
                                  match_log.match_rule,
                                  match_log.get_bp,
                                  :none,
                                  match_log.match_stage,
                                  watch_r_duel.pl_damege,
                                  watch_r_duel.foe_damege
                                  )
            do_determine_session(player_b.id,
                                 a_avatar.name,
                                 b_avatar.name,
                                 a_avatar.duel_deck_mask_cards_id_str,
                                 b_avatar.duel_deck_mask_cards_id_str,
                                 match_log.match_stage,
                                 watch_r_duel.pl_damege.join(","),
                                 watch_r_duel.foe_damege.join(",")
                                 )
            set_duel_handler(0, RULE_1VS1)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, watch_r_duel.dist, false)
            @duel.three_to_three_duel
          elsif match_log.match_rule == RULE_3VS3
            # カレントのアバターが持つカレントデッキでデュエル開始
            @duel = MultiDuel.new(a_avatar,
                                  b_avatar,
                                  a_deck,
                                  b_deck,
                                  match_log.match_rule,
                                  match_log.get_bp,
                                  :none,
                                  match_log.match_stage,
                                  watch_r_duel.pl_damege,
                                  watch_r_duel.foe_damege
                                  )
            do_determine_session(player_b.id,
                                 a_avatar.name,
                                 b_avatar.name,
                                 a_deck.mask_cards_id.join(","),
                                 b_deck.mask_cards_id.join(","),
                                 match_log.match_stage,
                                 watch_r_duel.pl_damege.join(","),
                                 watch_r_duel.foe_damege.join(",")
                                 )
            set_duel_handler(0, RULE_3VS3)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size, @duel.event_decks[@foe].size, watch_r_duel.dist, true)
            @duel.three_to_three_duel
          end
        else
          # CPU戦用にデータを調整
          player_b = AI.player
          b_avatar = player_b.current_avatar
          b_deck = AI.chara_card_deck(match_log.cpu_card_data_id)

          # CPUルールで開始する
          if match_log.match_rule == RULE_1VS1
            # カレントのアバターが持つカレントカードでデュエル開始
            @duel = MultiDuel.new(a_avatar,
                                  b_avatar,
                                  a_deck,
                                  b_deck,
                                  match_log.match_rule,
                                  match_log.get_bp,
                                  :none,
                                  match_log.match_stage,
                                  watch_r_duel.pl_damege,
                                  watch_r_duel.foe_damege
                                  )
            do_determine_session(player_b.id,
                                 a_avatar.name,
                                 b_avatar.name,
                                 a_avatar.duel_deck_mask_cards_id_str,
                                 b_avatar.duel_deck_mask_cards_id_str,
                                 match_log.match_stage,
                                 watch_r_duel.pl_damege.join(","),
                                 watch_r_duel.foe_damege.join(",")
                                 )
            set_duel_handler(0, RULE_1VS1)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, watch_r_duel.dist, false)
            @duel.three_to_three_duel

          elsif match_log.match_rule == RULE_3VS3
            # カレントのアバターが持つカレントデッキでデュエル開始
            @duel = MultiDuel.new(a_avatar,
                                  b_avatar,
                                  a_deck,
                                  b_deck,
                                  match_log.match_rule,
                                  match_log.get_bp,
                                  :none,
                                  match_log.match_stage,
                                  watch_r_duel.pl_damege,
                                  watch_r_duel.foe_damege
                                  )
            do_determine_session(player_b.id,
                                 a_avatar.name,
                                 b_avatar.name,
                                 a_deck.mask_cards_id.join(","),
                                 b_deck.mask_cards_id.join(","),
                                 match_log.match_stage,
                                 watch_r_duel.pl_damege.join(","),
                                 watch_r_duel.foe_damege.join(",")
                                 )
            set_duel_handler(0, RULE_3VS3)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size, @duel.event_decks[@foe].size, watch_r_duel.dist, true)
            @duel.three_to_three_duel
          end
        end

        # 進行用WatchDuelを取得
        @watch_duel = WatchDuel.new(match_uid, true)
        @watch_duel.real_duel_data = watch_r_duel
        @watch_duel.command_idx    = watch_r_duel.cmd_cnt

        # 使用デッキをログに書き出し
        player_deck_cards = a_deck.cards_id(true)
        opponent_player_deck_cards = b_deck.cards_id(true)
        SERVER_LOG.info("<UID:#{@uid}>WatchServer: [duel_use_deck_cards] player_cards#{player_deck_cards},opponent_player_cards#{opponent_player_deck_cards}");

        @@audience_list[@player.id] = self
      end
    end

    # 観戦キャンセル依頼
    def cs_watch_cancel
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}]")
      if @duel == nil
        # Duelの設定がされる前（cs_watch_startに入る前）ならキャンセル
        sc_watch_cancel
      end
    end

    # 観戦コマンド取得開始
    def cs_watch_command_get_start
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}]")
      @watch_duel.watch_start = true if @watch_duel
    end

    # 観戦終了依頼
    def cs_watch_finish
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}]")

      sc_watch_duel_room_out

      release_object
    end

    # ======================================
    # 送信コマンド
    # =====================================

    # ゲームセッションの決定
    def do_determine_session(id, p_name,foe_name,player_chara_id,foe_chara_id,stage,pl_hp,foe_hp)
      dialogue_id,dialogue_content = CharaCard::duel_start_dialogue(player_chara_id, foe_chara_id)
      sc_determine_session(id, foe_name, player_chara_id,  foe_chara_id, dialogue_content, dialogue_id,stage,pl_hp,foe_hp )
      set_message_str_data(DUEL_MSGDLG_WATCH_START,p_name.force_encoding("UTF-8"),foe_name.force_encoding("UTF-8"))
    end

    # デュエルのイベントハンドラをまとめて登録
    def set_duel_handler(no, rule)
      # Noはエントリの番号 0:alpha 1:beta
      @no = no
      @foe = (no==1)? 0:1


      # ============================
      # デュエルのハンドラ
      # ============================
      # 部屋のルールに応じたイベントハンドラを設定
      if rule == RULE_1VS1
        # デュエルの開始の終了を監視
        @duel.add_start_listener_three_to_three_duel(method(:one_to_one_duel_start_handler))
        @duel.add_finish_listener_three_to_three_duel(method(:duel_finish_handler))
      elsif rule == RULE_3VS3
        # デュエルの開始の終了を監視
        @duel.add_start_listener_three_to_three_duel(method(:three_to_three_duel_start_handler))
        @duel.add_finish_listener_three_to_three_duel(method(:duel_finish_handler))
        # キャラ変更フェイズの開始と終了を監視
        @duel.add_start_listener_chara_change_phase(method(:duel_chara_change_phase_start_handler))
        @duel.add_finish_listener_chara_change_phase(method(:duel_chara_change_phase_finish_handler))
        # 死亡キャラ変更フェイズの開始と終了を監視
        @duel.add_start_listener_dead_chara_change_phase(method(:duel_dead_chara_change_phase_start_handler))
        @duel.add_finish_listener_dead_chara_change_phase(method(:duel_dead_chara_change_phase_finish_handler))
        # キャラチェンジ決定のアクション
        @duel.entrants[@no].add_finish_listener_chara_change_action(method(:pl_entrant_chara_change_action_handler))
        @duel.entrants[@foe].add_finish_listener_chara_change_action(method(:foe_entrant_chara_change_action_handler))
      end

      # ============================
      # デュエルフェイズのハンドラ
      # ============================
      # ターン開始フェイズの終了を監視
      @duel.add_finish_listener_start_turn_phase(method(:duel_start_turn_phase_handler))

      # カード補充フェイズの終了を監視
      @duel.add_finish_listener_refill_card_phase(method(:duel_refill_card_phase_handler))
      # イベント補充フェイズの終了を監視
      @duel.add_finish_listener_refill_event_card_phase(method(:duel_refill_event_card_phase_handler))

      # 移動カード提出フェイズの開始と終了を監視
      @duel.add_start_listener_move_card_drop_phase(method(:duel_move_card_phase_start_handler))
      @duel.add_finish_listener_move_card_drop_phase(method(:duel_move_card_phase_finish_handler))

      # 移動決定フェイズの終了を監視
      @duel.add_finish_listener_determine_move_phase(method(:duel_determine_move_phase_handler))


      # 攻撃カード提出フェイズの開始と終了を監視
      @duel.add_start_listener_attack_card_drop_phase(method(:duel_attack_card_phase_start_handler))
      @duel.add_finish_listener_attack_card_drop_phase(method(:duel_attack_card_phase_finish_handler))

      # 防御カード提出フェイズの開始と終了を監視
      @duel.add_start_listener_deffence_card_drop_phase(method(:duel_deffence_card_phase_start_handler))
      @duel.add_finish_listener_deffence_card_drop_phase(method(:duel_deffence_card_phase_finish_handler))

      # 戦闘ポイント決定フェイズの終了を監視
      @duel.add_finish_listener_determine_battle_point_phase(method(:duel_det_battle_point_phase_handler))

      # 戦闘結果フェイズ
      @duel.add_finish_listener_battle_result_phase(method(:duel_battle_result_phase_handler))

      # ターン終了フェイズの終了を監視
      @duel.add_finish_listener_finish_turn_phase(method(:duel_finish_turn_phase_handler))

      # ============================
      # 参加者アクションのハンドラ
      # ============================
      # 参加者の移動カード提出アクションの監視
      @duel.entrants[@no].add_finish_listener_set_direction_action(method(:pl_entrant_set_direction_action_handler))

      @duel.entrants[@no].add_finish_listener_move_card_add_succes_event(method(:pl_entrant_move_card_add_action_handler))
      @duel.entrants[@foe].add_finish_listener_move_card_add_succes_event(method(:foe_entrant_move_card_add_action_handler))

      @duel.entrants[@no].add_finish_listener_move_card_remove_action(method(:pl_entrant_move_card_remove_action_handler))
      @duel.entrants[@foe].add_finish_listener_move_card_remove_action(method(:foe_entrant_move_card_remove_action_handler))

      @duel.entrants[@foe].add_finish_listener_init_done_action(method(:foe_entrant_init_done_action_handler))
      @duel.entrants[@no].add_finish_listener_init_done_action(method(:pl_entrant_init_done_action_handler))

      @duel.entrants[@foe].add_finish_listener_card_rotate_action(method(:foe_entrant_card_rotate_action_handler))
      @duel.entrants[@no].add_finish_listener_card_rotate_action(method(:pl_entrant_card_rotate_action_handler))

      @duel.entrants[@foe].add_finish_listener_event_card_rotate_action(method(:foe_entrant_event_card_rotate_action_handler))
      @duel.entrants[@no].add_finish_listener_event_card_rotate_action(method(:pl_entrant_event_card_rotate_action_handler))

      @duel.entrants[@no].add_finish_listener_battle_card_add_succes_event(method(:pl_entrant_battle_card_add_action_handler))
      @duel.entrants[@foe].add_finish_listener_battle_card_add_succes_event(method(:foe_entrant_battle_card_add_action_handler))

      @duel.entrants[@no].add_finish_listener_attack_card_remove_action(method(:pl_entrant_battle_card_remove_action_handler))
      @duel.entrants[@no].add_finish_listener_deffence_card_remove_action(method(:pl_entrant_battle_card_remove_action_handler))

      @duel.entrants[@foe].add_finish_listener_attack_card_remove_action(method(:foe_entrant_battle_card_remove_action_handler))
      @duel.entrants[@foe].add_finish_listener_deffence_card_remove_action(method(:foe_entrant_battle_card_remove_action_handler))

      @duel.entrants[@foe].add_finish_listener_deffence_done_action(method(:foe_entrant_deffence_done_action_handler))
      @duel.entrants[@foe].add_finish_listener_attack_done_action(method(:foe_entrant_attack_done_action_handler))

      @duel.entrants[@no].add_finish_listener_deffence_done_action(method(:pl_entrant_deffence_done_action_handler))
      @duel.entrants[@no].add_finish_listener_attack_done_action(method(:pl_entrant_attack_done_action_handler))

      @duel.entrants[@no].add_finish_listener_move_action(method(:pl_entrant_move_action_handler))


      # ============================
      # 参加者イベントのハンドラ
      # ============================
      @duel.entrants[@no].add_finish_listener_damaged_event(method(:plEntrant_damaged_event_handler))
      @duel.entrants[@foe].add_finish_listener_damaged_event(method(:foeEntrant_damaged_event_handler))
      @duel.entrants[@no].add_finish_listener_party_damaged_event(method(:plEntrant_party_damaged_event_handler))
      @duel.entrants[@foe].add_finish_listener_party_damaged_event(method(:foeEntrant_party_damaged_event_handler))
      @duel.entrants[@no].add_finish_listener_healed_event(method(:plEntrant_healed_event_handler))
      @duel.entrants[@foe].add_finish_listener_healed_event(method(:foeEntrant_healed_event_handler))
      @duel.entrants[@no].add_finish_listener_party_healed_event(method(:plEntrant_party_healed_event_handler))
      @duel.entrants[@foe].add_finish_listener_party_healed_event(method(:foeEntrant_party_healed_event_handler))
      @duel.entrants[@no].add_finish_listener_revive_event(method(:plEntrant_revive_event_handler))
      @duel.entrants[@foe].add_finish_listener_revive_event(method(:foeEntrant_revive_event_handler))
      @duel.entrants[@no].add_finish_listener_constraint_event(method(:plEntrant_constraint_event_handler))
      @duel.entrants[@no].add_finish_listener_hit_point_changed_event(method(:plEntrant_hit_point_changed_event_handler))
      @duel.entrants[@foe].add_finish_listener_hit_point_changed_event(method(:foeEntrant_hit_point_changed_event_handler))
      @duel.entrants[@no].add_finish_listener_cured_event(method(:plEntrant_cured_event_handler))
      @duel.entrants[@foe].add_finish_listener_cured_event(method(:foeEntrant_cured_event_handler))
      @duel.entrants[@no].add_finish_listener_use_action_card_event(method(:plEntrant_use_action_card_event_handler))
      @duel.entrants[@foe].add_finish_listener_use_action_card_event(method(:foeEntrant_use_action_card_event_handler))
      @duel.entrants[@no].add_finish_listener_discard_event(method(:plEntrant_discard_event_handler))
      @duel.entrants[@foe].add_finish_listener_discard_event(method(:foeEntrant_discard_event_handler))
      @duel.entrants[@no].add_finish_listener_discard_table_event(method(:plEntrant_discard_table_event_handler))
      @duel.entrants[@foe].add_finish_listener_discard_table_event(method(:foeEntrant_discard_table_event_handler))
      @duel.entrants[@no].add_finish_listener_point_update_event(method(:plEntrant_point_update_event_handler))
      @duel.entrants[@no].add_finish_listener_point_rewrite_event(method(:plEntrant_point_rewrite_event_handler))
      @duel.entrants[@foe].add_finish_listener_point_rewrite_event(method(:foeEntrant_point_rewrite_event_handler))
      @duel.entrants[@no].add_finish_listener_special_dealed_event(method(:plEntrant_special_dealed_event_handler))
      @duel.entrants[@foe].add_finish_listener_special_dealed_event(method(:foeEntrant_special_dealed_event_handler))
      @duel.entrants[@no].add_finish_listener_grave_dealed_event(method(:plEntrant_grave_dealed_event_handler))
      @duel.entrants[@foe].add_finish_listener_grave_dealed_event(method(:foeEntrant_grave_dealed_event_handler))
      @duel.entrants[@no].add_finish_listener_steal_dealed_event(method(:plEntrant_steal_dealed_event_handler))
      @duel.entrants[@foe].add_finish_listener_steal_dealed_event(method(:foeEntrant_steal_dealed_event_handler))
      @duel.entrants[@no].add_finish_listener_special_event_card_dealed_event(method(:plEntrant_special_event_card_dealed_event_handler))
      @duel.entrants[@foe].add_finish_listener_special_event_card_dealed_event(method(:foeEntrant_special_event_card_dealed_event_handler))
      @duel.entrants[@no].add_finish_listener_update_card_value_event(method(:plEntrant_update_card_value_event_handler))
      @duel.entrants[@foe].add_finish_listener_update_card_value_event(method(:foeEntrant_update_card_value_event_handler))
      @duel.entrants[@no].add_finish_listener_dice_roll_event(method(:plEntrant_dice_roll_event_handler))
      @duel.entrants[@foe].add_finish_listener_dice_roll_event(method(:foeEntrant_dice_roll_event_handler))
      @duel.entrants[@no].add_finish_listener_update_weapon_event(method(:plEntrant_update_weapon_event_handler))
      @duel.entrants[@no].add_finish_listener_cards_max_update_event(method(:plEntrant_cards_max_update_event_handler))
      @duel.entrants[@no].add_finish_listener_duel_bonus_event(method(:plEntrant_duel_bonus_event_handler))
      @duel.entrants[@no].add_finish_listener_trap_action_event(method(:plEntrant_trap_action_event_handler))
      @duel.entrants[@foe].add_finish_listener_trap_action_event(method(:foeEntrant_trap_action_event_handler))
      @duel.entrants[@no].add_finish_listener_trap_update_event(method(:plEntrant_trap_update_event_handler))
      @duel.entrants[@foe].add_finish_listener_trap_update_event(method(:foeEntrant_trap_update_event_handler))
      @duel.entrants[@no].add_finish_listener_set_field_status_event(method(:plEntrant_set_field_status_event_handler))
      @duel.entrants[@foe].add_finish_listener_set_field_status_event(method(:foeEntrant_set_field_status_event_handler))
      @duel.entrants[@no].add_finish_listener_duel_message_event(method(:plEntrant_duel_message_event_handler))
      @duel.entrants[@foe].add_finish_listener_duel_message_event(method(:foeEntrant_duel_message_event_handler))

      # ============================
      # デッキイベントのハンドラ
      # ============================
      @duel.deck.add_finish_listener_deck_init_event(method(:deck_init_handler))

      # =================================
      # アクションカードのハンドラ
      # =================================
      # チャンスカードイベントのハンドラ
      @duel.deck.all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.event_decks[0].all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.event_decks[1].all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.deck.all_cards_add_event_listener(:add_finish_listener_heal_event, method(:action_card_heal_event_handler))
      @duel.event_decks[0].all_cards_add_event_listener(:add_finish_listener_heal_event, method(:action_card_heal_event_handler))
      @duel.event_decks[1].all_cards_add_event_listener(:add_finish_listener_heal_event, method(:action_card_heal_event_handler))

      # =================================
      # キャラカードのハンドラ
      # =================================
      # 状態付加時イベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_buff_event(method(:pl_entrant_buff_on_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_buff_event(method(:foe_entrant_buff_on_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_buff_event(method(:pl_entrant_buff_off_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_buff_event(method(:foe_entrant_buff_off_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_update_buff_event(method(:pl_entrant_buff_update_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_update_buff_event(method(:foe_entrant_buff_update_event_handler)) }

      # 必殺技のイベントのハンドラ
      # 必殺技のON/OFFのイベント監視
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_feat_event(method(:pl_entrant_feat_on_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_feat_event(method(:foe_entrant_feat_on_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_feat_event(method(:pl_entrant_feat_off_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_feat_event(method(:foe_entrant_feat_off_event_handler)) }
      # 必殺技が変更された時のイベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_change_feat_event(method(:pl_entrant_change_feat_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_change_feat_event(method(:foe_entrant_change_feat_event_handler)) }
      # 必殺技が使われた時イベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_use_feat_event(method(:pl_entrant_use_feat_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_use_feat_event(method(:foe_entrant_use_feat_event_handler)) }
      # パッシブが使われた時イベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_use_passive_event(method(:pl_entrant_use_passive_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_use_passive_event(method(:foe_entrant_use_passive_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_passive_event(method(:pl_entrant_on_passive_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_passive_event(method(:foe_entrant_on_passive_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_passive_event(method(:pl_entrant_off_passive_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_passive_event(method(:foe_entrant_off_passive_event_handler)) }

      # キャラカード変身イベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_change_chara_card_event(method(:pl_entrant_change_chara_card_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_change_chara_card_event(method(:foe_entrant_change_chara_card_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_transform_event(method(:pl_entrant_on_transform_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_transform_event(method(:foe_entrant_on_transform_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_transform_event(method(:pl_entrant_off_transform_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_transform_event(method(:foe_entrant_off_transform_event_handler)) }

      # キャラカードの霧隠れイベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_lost_in_the_fog_event(method(:pl_entrant_on_lost_in_the_fog_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_lost_in_the_fog_event(method(:foe_entrant_on_lost_in_the_fog_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_lost_in_the_fog_event(method(:pl_entrant_off_lost_in_the_fog_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_lost_in_the_fog_event(method(:foe_entrant_off_lost_in_the_fog_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_in_the_fog_event(method(:pl_entrant_in_the_fog_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_in_the_fog_event(method(:foe_entrant_in_the_fog_event_handler)) }

      # 技の発動条件を変更するイベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_update_feat_condition_event(method(:pl_entrant_update_feat_condition_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_update_feat_condition_event(method(:foe_entrant_update_feat_condition_event_handler)) }

      # ヌイグルミをセットするイベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_stuffed_toys_set_event(method(:pl_entrant_stuffed_toys_set_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_stuffed_toys_set_event(method(:foe_entrant_stuffed_toys_set_event_handler)) }
    end

    # =========
    # Duel
    # =========

    # スタート時のハンドラ
    def one_to_one_duel_start_handler(args)
      if duel.turn == 0
        set_message_str_data(DUEL_MSGDLG_DUEL_START)
      end
    end

    # スタート時のハンドラ
    def three_to_three_duel_start_handler(args)
      if duel.turn == 0
        set_message_str_data(DUEL_MSGDLG_M_DUEL_START)
      end
    end

    # =========
    # DuelPhase
    # =========
    # ターンスタートのハンドラ
    def duel_start_turn_phase_handler(args)
      sc_duel_start_turn_phase(args[0])
    end

    # カードが配られた場合のハンドラ
    def duel_refill_card_phase_handler(args)
      if args
        sc_duel_refill_phase(args[0], args[1], args[2])
      end
    end

    # イベントカードが配られた場合のハンドラ
    def duel_refill_event_card_phase_handler(args)
      if args
        sc_duel_refill_event_phase(args[0], args[1], args[2])
      end
    end

    # 移動カード提出フェイズ開始
    def duel_move_card_phase_start_handler(args)
      sc_duel_move_card_drop_phase_start
    end

    # 移動カード提出フェイズ終了
    def duel_move_card_phase_finish_handler(args)
      sc_duel_move_card_drop_phase_finish
    end


    # 移動の結果がでた時にハンドラ
    def duel_determine_move_phase_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")
      set_message_str_data(args[0][0],args[0][1])
      sc_duel_determine_move_phase(args[1][0], args[1][1], args[1][2], args[1][3], args[1][4], args[1][5], args[1][6], args[1][7], args[1][8], args[1][9])
      set_message_str_data(args[2][0],args[2][1])
    end

    # キャラ変更フェイズ開始
    def duel_chara_change_phase_start_handler(args)
      sc_duel_chara_change_phase_start(args[0],args[1])
    end

   # キャラ変更フェイズ終了
    def duel_chara_change_phase_finish_handler(args)
      # フェイズ終了時に変更キャラが選択されてない場合は適当なキャラに変更する
      @duel.entrants.each { |e| e.chara_change_action if e.not_change_done? }
      sc_entrant_chara_change_action(args[0], args[2][0], args[2][1], args[2][2])

      set_message_str_data(DUEL_MSGDLG_CHANGE_CHARA)
      sc_duel_chara_change_phase_finish
    end

    # 攻撃カード提出フェイズ開始
    def duel_attack_card_phase_start_handler(args)
      # 攻撃側と防御側のポイントを送る
      sc_entrant_point_update_event(false,args[0][0],args[0][1],args[0][2])
      sc_entrant_point_update_event(true,args[1][0],args[1][1],args[1][2])
      # イニシアチブを伝えて攻撃フェイズを始める
      sc_duel_attack_card_drop_phase_start(args[2])
    end

    # 防御カード提出フェイズ開始
    def duel_deffence_card_phase_start_handler(args)
      # 攻撃側と防御側のポイントを送る
      sc_entrant_point_update_event(false,args[0][0],args[0][1],args[0][2])
      sc_entrant_point_update_event(true,args[1][0],args[1][1],args[1][2])
      # イニシアチブを伝えて防御フェイズを始める
      sc_duel_deffence_card_drop_phase_start(args[2])
    end

    # 攻撃カード提出フェイズ終了
    def duel_attack_card_phase_finish_handler(args)
      sc_entrant_point_update_event(false,args[0][0],args[0][1],args[0][2])
      sc_entrant_point_update_event(true,args[1][0],args[1][1],args[1][2])
      sc_duel_attack_card_drop_phase_finish(args[2][0],args[2][1],args[2][2],args[2][3],args[2][4],args[2][5])
    end

    # 防御カード提出フェイズ終了
    def duel_deffence_card_phase_finish_handler(args)
      sc_entrant_point_update_event(false,args[0][0],args[0][1],args[0][2])
      sc_entrant_point_update_event(true,args[1][0],args[1][1],args[1][2])
      sc_duel_deffence_card_drop_phase_finish(args[2][0],args[2][1],args[2][2],args[2][3],args[2][4],args[2][5])
    end

    # 戦闘ポイント決定フェイズの時のハンドラ
    def duel_det_battle_point_phase_handler(args)
      set_message_str_data(args[0][0],args[0][1])
      sc_duel_determine_battle_point_phase(args[1][0],args[1][1],args[1][2],args[1][3],args[1][4],args[1][5])
    end

    # 戦闘の結果がでた時のハンドラ
    def duel_battle_result_phase_handler(args)
      set_message_str_data(args[0][0],args[0][1]) if args[0]!=nil
      sc_duel_battle_result_phase(args[1][0],args[1][1],args[1][2])
    end

    # 死亡キャラ変更フェイズ開始
    def duel_dead_chara_change_phase_start_handler(args)
      sc_duel_dead_chara_change_phase_start(args[0],args[1],args[2],args[3])
    end

    # 死亡キャラ変更フェイズ終了
    def duel_dead_chara_change_phase_finish_handler(args)
      # フェイズ終了時に変更キャラが選択されてない場合は適当なキャラに変更する
      @duel.entrants.each { |e| e.chara_change_action if e.not_change_done? }
      sc_entrant_chara_change_action(false, args[1][0],args[1][1],args[1][2])
      set_message_str_data(DUEL_MSGDLG_CHANGE_CHARA)
      sc_duel_dead_chara_change_phase_finish
    end

    # ターン終了のハンドラ
    def duel_finish_turn_phase_handler(args)#
      # 移動ボタンをリセット
      sc_entrant_set_direction_action(true, args[0])
    end

    # ===================
    # EntrantAction
    # ===================
    # 自分が移動方向を決定する
    def pl_entrant_set_direction_action_handler(args)
      sc_entrant_set_direction_action(true, args[0])
    end

    # 自分が移動カードを出す
    def pl_entrant_move_card_add_action_handler(args)
      sc_entrant_move_card_add_action(true, args[0], args[1])
    end

    # 敵側が移動カードを出す
    def foe_entrant_move_card_add_action_handler(args)
      sc_entrant_move_card_add_action(false, args[0], args[1])
    end

    # 敵側が移動カードを取り除く
    def foe_entrant_move_card_remove_action_handler(args)
      sc_entrant_move_card_remove_action(false, args[0], args[1])
    end

    # 自分側が移動カードを取り除く
    def pl_entrant_move_card_remove_action_handler(args)
      sc_entrant_move_card_remove_action(true, args[0],args[1])
    end

    # 敵側がカードを回転させる
    def foe_entrant_card_rotate_action_handler(args)
      sc_entrant_card_rotate_action(false, args[0], args[1], args[2], args[3])
    end

    # 自分がカードを回転させる
    def pl_entrant_card_rotate_action_handler(args)
      sc_entrant_card_rotate_action(true, args[0], args[1], args[2], args[3])
    end

    # 敵側がイベントでカードを回転させる
    def foe_entrant_event_card_rotate_action_handler(args)
      sc_entrant_event_card_rotate_action(false, args[0], args[1], args[2], args[3])
    end

    # 自分がイベントでカードを回転させる
    def pl_entrant_event_card_rotate_action_handler(args)
      sc_entrant_event_card_rotate_action(true, args[0], args[1], args[2], args[3])
    end

    # 自分が戦闘カードを出す
    def pl_entrant_battle_card_add_action_handler(args)
      sc_entrant_battle_card_add_action(true, args[0], args[1])
    end

    # 敵側が戦闘カードを出す
    def foe_entrant_battle_card_add_action_handler(args)
      sc_entrant_battle_card_add_action(false, args[0], args[1])
    end

    # 自分が戦闘カードを取り除く
    def pl_entrant_battle_card_remove_action_handler(args)
      sc_entrant_battle_card_remove_action(true, args[0], args[1])
    end

    # 敵側が戦闘カードを取り除く
    def foe_entrant_battle_card_remove_action_handler(args)
      sc_entrant_battle_card_remove_action(false, args[0], args[1])
    end

    # 自分のキャラカードを変更する
    def pl_entrant_chara_change_action_handler(args)
      sc_entrant_chara_change_action(true, args[0], args[1], args[2])
    end

    # 相手のキャラカードを変更する
    def foe_entrant_chara_change_action_handler(args)
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def foe_entrant_init_done_action_handler(args)
      sc_entrant_init_done_action(false)
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def pl_entrant_init_done_action_handler(args)
      sc_entrant_init_done_action(true)
    end

    # 敵側の攻撃フェイズの完了アクション
    def foe_entrant_attack_done_action_handler(args)
      sc_entrant_attack_done_action(false)
    end

    # 敵側の防御フェイズの完了アクション
    def foe_entrant_deffence_done_action_handler(args)
      sc_entrant_deffence_done_action(false)
    end

    # プレイヤー側の攻撃フェイズの完了アクション
    def pl_entrant_attack_done_action_handler(args)
      sc_entrant_attack_done_action(true);
    end

    # プレイヤー側の防御フェイズの完了アクション
    def pl_entrant_deffence_done_action_handler(args)
      sc_entrant_deffence_done_action(true);
    end

    # 自分が移動する
    def pl_entrant_move_action_handler(args)
      sc_entrant_move_action(args[0])
    end

    # ===================
    # EntrantEvent
    # ===================
    # プレイヤーダメージのイベント
    def plEntrant_damaged_event_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")
      sc_entrant_damaged_event(true,args[0][0],args[0][1])
    end

    # 敵ダメージのハンドラのイベント
    def foeEntrant_damaged_event_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")
      sc_entrant_damaged_event(false,args[0][0],args[0][1])
    end

    # プレイヤーの回復イベント
    def plEntrant_healed_event_handler(args)
      sc_entrant_healed_event(true,args[0])
    end

    # 敵の回復イベント
    def foeEntrant_healed_event_handler(args)
      sc_entrant_healed_event(false,args[0])
    end

    # プレイヤーのパーティ回復イベント
    def plEntrant_party_healed_event_handler(args)
      sc_entrant_party_healed_event(true, args[0], args[1])
    end

    # 敵のパーティ回復イベント
    def foeEntrant_party_healed_event_handler(args)
      sc_entrant_party_healed_event(false, args[0], args[1])
    end

    # プレイヤーのパーティ蘇生イベント
    def plEntrant_revive_event_handler(args)
      sc_entrant_revive_event(true, args[0], args[1])
    end

    # 敵のパーティ蘇生イベント
    def foeEntrant_revive_event_handler(args)
      sc_entrant_revive_event(false, args[0], args[1])
    end

    # プレイヤーの行動制限イベント
    def plEntrant_constraint_event_handler(args)
      sc_entrant_constraint_event(true, args[0])
    end

    # プレイヤーのHP変更イベント
    def plEntrant_hit_point_changed_event_handler(args)
      sc_entrant_hit_point_changed_event(true,args[0])
    end

    # 敵のHP変更イベント
    def foeEntrant_hit_point_changed_event_handler(args)
      sc_entrant_hit_point_changed_event(false,args[0])
    end

    # プレイヤーのパーティダメージイベント
    def plEntrant_party_damaged_event_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")
      sc_entrant_party_damaged_event(true, args[0], args[1], args[2])
    end

    # 敵のパーティダメージイベント
    def foeEntrant_party_damaged_event_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")
      sc_entrant_party_damaged_event(false, args[0], args[1], args[2])
    end

    # プレイヤーの状態回復イベント
    def plEntrant_cured_event_handler(args)
      sc_entrant_cured_event(true)
    end

    # 敵の状態回復イベント
    def foeEntrant_cured_event_handler(args)
      sc_entrant_cured_event(false)
    end

    # プレイヤーアクションカード使用イベント
    def plEntrant_use_action_card_event_handler(args)
      sc_entrant_use_action_card_event(true,args[0])
    end

    # プレイヤーアクションカード使用イベント
    def foeEntrant_use_action_card_event_handler(args)
      sc_entrant_use_action_card_event(false,args[0])
    end

    # プレイヤーアクションカード破棄イベント
    def plEntrant_discard_event_handler(args)
      sc_entrant_discard_event(true,args[0])
    end

    # プレイヤーアクションカード破棄イベント
    def foeEntrant_discard_event_handler(args)
      sc_entrant_discard_event(false,args[0])
    end

    # プレイヤーアクションカード破棄イベント
    def plEntrant_discard_table_event_handler(args)
      sc_entrant_discard_table_event(true,args[0])
    end

    # プレイヤーアクションカード破棄イベント
    def foeEntrant_discard_table_event_handler(args)
      sc_entrant_discard_table_event(false,args[0])
    end

    # プレイヤーのポイントが更新された場合のイベント
    def plEntrant_point_update_event_handler(args)
      if args.length > 0
        sc_entrant_point_update_event(true, args[0], args[1], args[2])
      end
    end

    # プレイヤーのポイントが上書きされた場合のイベント
    def plEntrant_point_rewrite_event_handler(args)
      if @duel
        sc_entrant_point_rewrite_event(true, args[0])
      end
    end

    # 相手のポイントが上書きされた場合のイベント
    def foeEntrant_point_rewrite_event_handler(args)
      if @duel
        sc_entrant_point_rewrite_event(false, args[0])
      end
    end

    # プレイヤーが特別にカードを配られる場合のイベント
    def plEntrant_special_dealed_event_handler(args)
      sc_entrant_special_dealed_event(true, args[0], args[1], args[2])
    end

    # 敵が特別にカードを配られる場合のイベント
    def foeEntrant_special_dealed_event_handler(args)
      sc_entrant_special_dealed_event(false, args[0], args[1], args[2])
    end

    # プレイヤーに墓地のカードが配られる場合のイベント
    def plEntrant_grave_dealed_event_handler(args)
      sc_entrant_grave_dealed_event(true, args[0], args[1], args[2])
    end

    # 敵に墓地のカードが配られる場合のイベント
    def foeEntrant_grave_dealed_event_handler(args)
      sc_entrant_grave_dealed_event(false, args[0], args[1], args[2])
    end

    # プレイヤーに相手の手札のカードが配られる場合のイベント
    def plEntrant_steal_dealed_event_handler(args)
      sc_entrant_steal_dealed_event(true, args[0], args[1], args[2])
    end

    # 敵にプレイヤーの手札のカードが配られる場合のイベント
    def foeEntrant_steal_dealed_event_handler(args)
      sc_entrant_steal_dealed_event(false, args[0], args[1], args[2])
    end

    # プレイヤーが特別にイベントカードを配られる場合のイベント
    def plEntrant_special_event_card_dealed_event_handler(args)
      sc_entrant_special_event_card_dealed_event(true, args[0], args[1], args[2])
    end

    # 敵が特別にイベントカードを配られる場合のイベント
    def foeEntrant_special_event_card_dealed_event_handler(args)
      sc_entrant_special_event_card_dealed_event(false, args[0], args[1], args[2])
    end

    # プレイヤーのカードの値が変更される場合のイベント
    def plEntrant_update_card_value_event_handler(args)
      sc_entrant_update_card_value_event(true, args[0], args[1], args[2], args[3])
    end

    # 敵のカードの値が変更される場合のイベント
    def foeEntrant_update_card_value_event_handler(args)
      sc_entrant_update_card_value_event(false, args[0],args[1], args[2], args[3])
    end

    # プレイヤーに仮のダイスが振られるときのイベント
    def plEntrant_dice_roll_event_handler(args)
      sc_duel_battle_result_phase(true, args[0], args[1])
    end

    # 敵に仮のダイスが振られるときのイベント
    def foeEntrant_dice_roll_event_handler(args)
      sc_duel_battle_result_phase(false, args[0], args[1])
    end

    # プレイヤーの装備カードが更新されるときのイベント
    def plEntrant_update_weapon_event_handler(args)
      sc_entrant_update_weapon_event(true, args[0], args[1])
    end

    # プレイヤーの最大カード枚数が更新された場合のイベント
    def plEntrant_cards_max_update_event_handler(args)
      sc_entrant_cards_max_update_event(true,args[0])
    end

    # プレイヤーの最大カード枚数が更新された場合のイベント
    def plEntrant_duel_bonus_event_handler(args)
      sc_duel_bonus_event(args[0],args[1])
    end

    # プレイヤーの特殊メッセージのイベント
    def plEntrant_special_message_event_handler(args)
      sc_message(args[0].force_encoding("UTF-8"))
    end

    # プレイヤーの特殊メッセージのイベント
    def foeEntrant_special_message_event_handler(args)
      sc_message(args[0].force_encoding("UTF-8"))
    end

    # プレイヤーの属性抵抗メッセージのイベント
    def plEntrant_attribute_regist_message_event_handler(args)
      sc_message(args[0].force_encoding("UTF-8"))
    end

    # プレイヤーの属性抵抗メッセージのイベント
    def foeEntrant_attribute_regist_message_event_handler(args)
      sc_message(args[0].force_encoding("UTF-8"))
    end

    # デュエル中の汎用メッセージ
    def plEntrant_duel_message_event_handler(args)
      case args[0]
      when DUEL_MSGDLG_AVOID_DAMAGE
        set_message_str_data(args[0], args[1], DUEL_NAME_WATCH.gsub("__NAME__", @duel.avatar_names[@no].force_encoding("UTF-8")))
      else
        set_message_str_data(args[0])
      end
    end

    # デュエル中の汎用メッセージ
    def foeEntrant_duel_message_event_handler(args)
      case args[0]
      when DUEL_MSGDLG_AVOID_DAMAGE
        set_message_str_data(args[0], args[1], DUEL_NAME_WATCH.gsub("__NAME__", @duel.avatar_names[@foe].force_encoding("UTF-8")))
      else
        set_message_str_data(args[0])
      end
    end

    # プレイヤーのトラップ発動イベント
    def plEntrant_trap_action_event_handler(args)
      set_message_str_data(args[0][0],args[0][1])
      sc_entrant_trap_action_event(true,args[1][0],args[1][1])
    end

    # 敵のトラップ発動イベント
    def foeEntrant_trap_action_event_handler(args)
      set_message_str_data(args[0][0],args[0][1])
      sc_entrant_trap_action_event(false,args[1][0],args[1][1])
    end

    # プレイヤーのトラップ遷移イベント
    def plEntrant_trap_update_event_handler(args)
      sc_entrant_trap_update_event(true,args[0][0],args[0][1],args[0][2],args[0][3]) if args[0][3]
    end

    # 敵のトラップ遷移イベント
    def foeEntrant_trap_update_event_handler(args)
      sc_entrant_trap_update_event(false,args[0][0],args[0][1],args[0][2],args[0][3]) if args[0][3]
    end

    # フィールド状態変更イベント
    def plEntrant_set_field_status_event_handler(args)
      sc_set_field_status_event(args[0][0], args[0][1], args[0][2])
    end

    # フィールド状態変更イベント
    def foeEntrant_set_field_status_event_handler(args)
      sc_set_field_status_event(args[0][0], args[0][1], args[0][2])
    end

    # 現在ターン数変更のイベント
    def plEntrant_set_turn_event_handler(args)
      sc_set_turn_event(args[0])
    end

    # 現在ターン数変更のイベント
    def foeEntrant_set_turn_event_handler(args)
      sc_set_turn_event(args[0])
    end

    # カードロックイベント
    def plEntrant_card_lock_event_handler(args)
    end

    # カードロック解除イベント
    def plEntrant_clear_card_locks_event_handler(args)
    end

    # =====================
    # DeckEvent
    # =====================

    # デッキの初期化のハンドラ
    def deck_init_handler(args)
      sc_deck_init_event(args[0])
    end

    # =====================
    # ActionCardEvent
    # =====================
    def action_card_chance_event_handler(args)
      if args.length > 0
        sc_actioncard_chance_event(args[0], args[1], args[2], args[3])
      end
    end

    def action_card_heal_event_handler(args)
    end

    # =====================
    # CharaCardEvent
    # =====================
    # 状態付加ON時のプレイヤー側ハンドラ
    def pl_entrant_buff_on_event_handler(args)
      sc_buff_on_event(args[0][0], args[0][1], args[0][2], args[0][3], args[0][4])
      set_message_str_data(args[1][0],args[1][1],args[1][2]) if duel.entrants[@no].current_chara_card_no == args[0][1]
     end

    # 状態付加ON時の敵側側ハンドラ
    def foe_entrant_buff_on_event_handler(args)
      sc_buff_on_event(args[0][0], args[0][1], args[0][2], args[0][3], args[0][4])
      set_message_str_data(args[1][0],args[1][1],args[1][2]) if duel.entrants[@foe].current_chara_card_no == args[0][1]
    end

    # 状態付加Off時のプレイヤー側ハンドラ
    def pl_entrant_buff_off_event_handler(args)
      sc_buff_off_event(args[0], args[1], args[2], args[3])
    end

    # 状態付加Off時の敵側側ハンドラ
    def foe_entrant_buff_off_event_handler(args)
      sc_buff_off_event(args[0], args[1], args[2], args[3])
    end

    # 状態付加Update時のプレイヤー側ハンドラ
    def pl_entrant_buff_update_event_handler(args)
      sc_buff_update_event(args[0], args[1], args[2], args[3], args[4])
    end

    # 状態付加Update時の敵側側ハンドラ
    def foe_entrant_buff_update_event_handler(args)
      sc_buff_update_event(args[0], args[1], args[2], args[3], args[4])
    end

    # 猫状態Update時のプレイヤー側ハンドラ
    def pl_entrant_cat_state_update_event_handler(args)
      sc_cat_state_update_event(args[0], args[1], args[2])
    end

    # 猫状態Update時の敵側側ハンドラ
    def foe_entrant_cat_state_update_event_handler(args)
      sc_cat_state_update_event(args[0], args[1], args[2])
    end

    # 必殺技ON時のプレイヤー側ハンドラ
    def pl_entrant_feat_on_event_handler(args)
    end

    # 必殺技ON時の敵側側ハンドラ
    def foe_entrant_feat_on_event_handler(args)
    end

    # 必殺技Off時のプレイヤー側ハンドラ
    def pl_entrant_feat_off_event_handler(args)
    end

    # 必殺技Off時の敵側側ハンドラ
    def foe_entrant_feat_off_event_handler(args)
    end

    # 必殺技が変更された時のプレイヤー側ハンドラ
    def pl_entrant_change_feat_event_handler(args)
      sc_entrant_change_feat_event(true, args[0][0], args[0][1], args[0][2], args[0][3])
    end

    # 必殺技が変更された時の敵側ハンドラ
    def foe_entrant_change_feat_event_handler(args)
      sc_entrant_change_feat_event(false, args[0][0], args[0][1], args[0][2], args[0][3])
    end

    # 必殺技が実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_feat_event_handler(args)
      sc_entrant_use_feat_event(true, args[0])
    end

    # 必殺技が実行された時の敵側ハンドラ
    def foe_entrant_use_feat_event_handler(args)
      sc_entrant_use_feat_event(false, args[0])
    end

    # パッシブが実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_passive_event_handler(args)
      sc_entrant_use_passive_event(true, args[0])
    end

    # パッシブが実行された時の敵側ハンドラ
    def foe_entrant_use_passive_event_handler(args)
      sc_entrant_use_passive_event(false, args[0])
    end

    # パッシブが実行された時のプレイヤー側ハンドラ
    def pl_entrant_on_passive_event_handler(args)
      sc_entrant_on_passive_event(true, args[1])
    end

    # パッシブが実行された時の敵側ハンドラ
    def foe_entrant_on_passive_event_handler(args)
      sc_entrant_on_passive_event(false, args[1])
    end

    # パッシブが終了した時のプレイヤー側ハンドラ
    def pl_entrant_off_passive_event_handler(args)
      sc_entrant_off_passive_event(true, args[1])
    end

    # パッシブが終了した時の敵側ハンドラ
    def foe_entrant_off_passive_event_handler(args)
      sc_entrant_off_passive_event(false, args[1])
    end

    # キャラカードを更新するプレイヤー側ハンドラ 変身用
    def pl_entrant_change_chara_card_event_handler(args)
      sc_entrant_change_chara_card_event(true, args[0])
    end

    # キャラカードを更新する敵側ハンドラ 変身用
    def foe_entrant_change_chara_card_event_handler(args)
      sc_entrant_change_chara_card_event(false, args[0])
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_on_transform_event_handler(args)
      sc_entrant_on_transform_event(args[0], args[1])
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_on_transform_event_handler(args)
      sc_entrant_on_transform_event(args[0], args[1])
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_off_transform_event_handler(args)
      sc_entrant_off_transform_event(args[0])
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_off_transform_event_handler(args)
      sc_entrant_off_transform_event(args[0])
    end

    # きりがくれプレイヤー側ON
    def pl_entrant_on_lost_in_the_fog_event_handler(args)
      sc_entrant_on_lost_in_the_fog_event(args[0], args[1], 0)
    end

    # きりがくれ的側ON
    def foe_entrant_on_lost_in_the_fog_event_handler(args)
      sc_entrant_on_lost_in_the_fog_event(args[0], args[1], 0)
    end

    # きりがくれプレイヤー側OFF
    def pl_entrant_off_lost_in_the_fog_event_handler(args)
      sc_entrant_off_lost_in_the_fog_event(args[0],args[1])
    end

    # きりがくれ的側OFF
    def foe_entrant_off_lost_in_the_fog_event_handler(args)
      sc_entrant_off_lost_in_the_fog_event(args[0],args[1])
    end

    # プレイヤー側 霧ライト
    def pl_entrant_in_the_fog_event_handler(args)
      sc_entrant_in_the_fog_event(args[0], args[1]) unless args[1].nil?
    end

    # 敵側霧ライト
    def foe_entrant_in_the_fog_event_handler(args)
      sc_entrant_in_the_fog_event(args[0], args[1]) unless args[1].nil?
    end

    # 技の発動条件を更新 PL
    def pl_entrant_update_feat_condition_event_handler(args)
      sc_entrant_update_feat_condition_event(args[0], args[1], args[2], args[3])
    end

    # 技の発動条件を更新 FOE
    def foe_entrant_update_feat_condition_event_handler(args)
      sc_entrant_update_feat_condition_event(args[0], args[1], args[2], args[3])
    end

    # ヌイグルミセット 自分側
    def pl_entrant_stuffed_toys_set_event_handler(args)
      sc_entrant_stuffed_toys_set_event(args[0], args[1])
    end

    # ヌイグルミセット 敵側
    def foe_entrant_stuffed_toys_set_event_handler(args)
      sc_entrant_stuffed_toys_set_event(args[0], args[1])
    end

    # =====================
    # Finish
    # =====================
    def duel_finish_handler(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")

      sc_watch_duel_finish_event(true, args[0])

      release_object
    end

    def duel_abort_finish(args)
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}] args:#{args} ")

      release_object
      # クライアントをリセットさせるコマンドを送る
      sc_error_no(ERROR_GAME_ABORT)
    end

    # =====================
    # 準備関数
    # =====================
    def set_buff_handler(args)
      sc_set_chara_buff_event(args[0],args[1])
    end

    def entrant_move_card_add_action_handler(args)
      sc_entrant_move_card_add_action(args[0], args[1], args[2])
    end

    def entrant_battle_card_add_action_handler(args)
      sc_entrant_battle_card_add_action(args[0], args[1], args[2])
    end

    def set_chara_card_idx_handler(args)
      sc_duel_chara_change_phase_start(args[0][0],args[0][1])
      args[1].each do |prm|
        sc_entrant_chara_change_action(prm[0], prm[1], prm[2], prm[3])
      end
      sc_duel_chara_change_phase_finish
    end

    def reset_deck_num_handler(args)
      sc_reset_deck_num_event(args[0])
    end

    def set_initi_and_dist_handler(args)
      sc_set_initi_and_dist_event(args[0],args[1])
    end

    # ==========
    # 内部用関数
    # ==========
    def set_message_str_data(msgId,*args)
      args = [] unless args
      sc_message_str_data("#{msgId}:#{args.join(",")}")
    end

    def set_message_str_data_handler(args)
      set_message_str_data(args[0],args[1])
    end

    def pushout()
      online_list[@player.id].logout
    end

    def do_login
    end

    # ログアウト時の処理
    def do_logout
      release_object
    end

    # 解放関数
    def release_object
      SERVER_LOG.info("<UID:#{@uid}>WatchServer: [#{__method__}]")
      @@audience_list.delete(@player.id)
      @watch_duel = nil
      if @duel
        @duel.entrants[@no].exit_game
        @duel.entrants[@foe].exit_game
        @duel.exit_game
      end
      @duel = nil
    end

    # 更新関数
    def self::all_duel_update
      if WATCH_MODE_ON
        @@audience_list.each_value { |audience|
          audience.duel_update if audience
        }
      end
    end

    # コマンドを取得し、実行していく
    def duel_update
      if @watch_duel && @watch_duel.watch_start && !@watch_duel.watch_finish && !@watch_duel.update_wait_count
        cmds = @watch_duel.get_next_act_command
        if cmds
          cmds.each do |cmd|
            self.send(cmd[:func], cmd[:args]) if cmd
            # 取得したコマンドが終了コマンドなら抜ける
            break if @watch_duel==nil||@watch_duel.watch_finish
          end
        end
      end
    end
  end
end
