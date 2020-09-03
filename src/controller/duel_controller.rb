# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # Duel部分のコントローラ
  # Duelが必要な他のコントローラにMIXINして使う
  module DuelController
    # ======================================
    # 受信コマンド
    # =====================================
    # ------- 移動フェイズ -------
    # 移動の決定
    def cs_start_ok
      @duel.entrants[@no].start_ok if @duel
    end

    # 移動の方向を決定する
    def cs_set_direction(dir)
      @duel.entrants[@no].set_direction_action(dir) if @duel
    end

    # 移動のカードをテーブルに出す
    def cs_move_card_add(card, index, dir)
      @duel.entrants[@no].move_card_add_action([card], [dir], index) if @duel
    end

    # 移動カードを元に戻す
    def cs_move_card_remove(card, index)
      @duel.entrants[@no].move_card_remove_action([card],index) if @duel
    end

    # カードだしの終了
    def cs_init_done(card_event, chara_event)
      @duel.entrants[@no].init_done_action if @duel
    end

    # -------- イニシアチブ決定 ---------
    # 移動の決定
    def cs_move_done(m, card_events, chara_events)
      @duel.entrants[@no].move_action(m) if @duel
    end

    # -------- 戦闘フェイズ ---------

    # 攻撃のカードをテーブルに出す
    def cs_attack_card_add(card, index, dir)
      @duel.entrants[@no].attack_card_add_action([card],[dir]) if @duel
    end

    # 攻撃のカードをテーブルから戻す
    def cs_attack_card_remove(card, index)
      @duel.entrants[@no].attack_card_remove_action([card]) if @duel
    end

    # 防御のカードをテーブルに出す
    def cs_deffence_card_add(card, index, dir)
      @duel.entrants[@no].deffence_card_add_action([card],[dir]) if @duel
    end

    # 防御のカードをテーブルから戻す
    def cs_deffence_card_remove(card, index)
      @duel.entrants[@no].deffence_card_remove_action([card]) if @duel
    end

    # 攻撃カードだしの終了
    def cs_attack_done(card_event, chara_event)
      @duel.entrants[@no].attack_done_action if @duel
    end

    # 防御カードだしの終了
    def cs_deffence_done(card_event, chara_event)
      @duel.entrants[@no].deffence_done_action if @duel
    end

    # カードを回転
    def cs_card_rotate(card, table, index, up)
      @duel.entrants[@no].card_rotate_action(card,table,index,up) if @duel
    end

    # ------- キャラ変更フェイズ -------
    # キャラ変更を決定する
    def cs_chara_change(index)
      @duel.entrants[@no].chara_change_action(index) if @duel
    end

    # -------- 報酬判定 ---------
    def cs_result_up
      if @reward&&(@reward.finished == false)
        @reward.update
        @reward.up_event
        @reward.update
      end
    end

    def cs_result_down
      if @reward&&(@reward.finished == false)
        @reward.update
        @reward.down_event
        @reward.update
      end
    end

    def cs_result_cancel
      if @reward&&(@reward.finished == false)
        @reward.update
        @reward.cancel_event
        @reward.update
      end
    end

    def cs_retry_reward
      if @reward&&(@reward.finished == false)
        @reward.update
        @reward.retry_reward_event
        @reward.update
      end
    end

    def cs_avatar_use_item(inv_id)
      if @avatar
        e = @avatar.use_item(inv_id)
        @reward.update if @reward&&(@reward.finished == false)
        if e >0
          sc_error_no(e)
        else
          it = ItemInventory[inv_id]
          SERVER_LOG.info("<UID:#{@uid}>GameServer:[Cl] [cs_use_item_duel_reward] use_item_id:#{it.avatar_item_id}")
        end
      end
    end

    def cs_debug_code(code)
      # 管理者しか実行できない
      unless  @player && @player.role == ROLE_ADMIN
        return
      end
      SERVER_LOG.info("<UID:#{@uid}>GameServer:[Cl] [cs_debug_code] #{code}")
      # コードにあった状況を提供する
      case code
      when DEBUG_CODE_ENEMY_DAMEGE_10
        @duel.entrants[@foe].damaged_event(10) if  @duel && @duel.entrants && @duel.entrants[@foe]
      when DEBUG_CODE_SELF_DAMAGE_1
        @duel.entrants[@no].damaged_event(1)  if  @duel && @duel.entrants && @duel.entrants[@no]
      when DEBUG_CODE_SET_LAST_TURN
        @duel.set_last_turn  if  @duel
      when DEBUG_CODE_ALL_HP_REMAIN_1
        e = @duel.entrants[@no]
        e.chara_cards.each_index do |i|
          e.party_damaged_event(i, e.hit_points[i]-1 ) if  e.hit_points[i]>1
        end
        e = @duel.entrants[@foe]
        e.chara_cards.each_index do |i|
          e.party_damaged_event(i, e.hit_points[i]-1 ) if  e.hit_points[i]>1
        end
      when DEBUG_CODE_SELF_ALL_DAMAGE_1
        @duel.entrants[@no].chara_cards.each_index do |i|
          @duel.entrants[@no].party_damaged_event(i,1)
        end
      end
    end

    # ======================================
    # 送信コマンド
    # =====================================
    # ゲームセッションの決定
    def do_determine_session(id, name,player_chara_id,foe_chara_id)
      dialogue_id,dialogue_content = CharaCard::duel_start_dialogue(player_chara_id, foe_chara_id)
      sc_determine_session(id, name, player_chara_id,  foe_chara_id, dialogue_content, dialogue_id )
      set_message_str_data(DUEL_MSGDLG_START,name.force_encoding("UTF-8"))
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
      @duel.entrants[@no].add_finish_listener_hide_move_action(method(:pl_entrant_hide_move_action_handler))

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
      @duel.entrants[@no].add_finish_listener_sealed_event(method(:plEntrant_sealed_event_handler))
      @duel.entrants[@foe].add_finish_listener_sealed_event(method(:foeEntrant_sealed_event_handler))
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
      @duel.entrants[@no].add_finish_listener_trap_action_event(method(:plEntrant_trap_action_event_handler))
      @duel.entrants[@foe].add_finish_listener_trap_action_event(method(:foeEntrant_trap_action_event_handler))
      @duel.entrants[@no].add_finish_listener_trap_update_event(method(:plEntrant_trap_update_event_handler))
      @duel.entrants[@foe].add_finish_listener_trap_update_event(method(:foeEntrant_trap_update_event_handler))
      @duel.entrants[@no].add_finish_listener_set_field_status_event(method(:plEntrant_set_field_status_event_handler))
      @duel.entrants[@foe].add_finish_listener_set_field_status_event(method(:foeEntrant_set_field_status_event_handler))
      @duel.entrants[@no].add_finish_listener_duel_bonus_event(method(:plEntrant_duel_bonus_event_handler))

      @duel.entrants[@no].add_finish_listener_special_message_event(method(:plEntrant_special_message_event_handler))
      @duel.entrants[@foe].add_finish_listener_special_message_event(method(:foeEntrant_special_message_event_handler))
      @duel.entrants[@no].add_finish_listener_duel_message_event(method(:plEntrant_duel_message_event_handler))
      @duel.entrants[@foe].add_finish_listener_duel_message_event(method(:foeEntrant_duel_message_event_handler))
      @duel.entrants[@no].add_finish_listener_attribute_regist_message_event(method(:plEntrant_attribute_regist_message_event_handler))
      @duel.entrants[@foe].add_finish_listener_attribute_regist_message_event(method(:foeEntrant_attribute_regist_message_event_handler))
      @duel.entrants[@no].add_finish_listener_set_turn_event(method(:plEntrant_set_turn_event_handler))
      @duel.entrants[@foe].add_finish_listener_set_turn_event(method(:foeEntrant_set_turn_event_handler))

      @duel.entrants[@no].add_finish_listener_card_lock_event(method(:plEntrant_card_lock_event_handler))
      @duel.entrants[@no].add_finish_listener_clear_card_locks_event(method(:plEntrant_clear_card_locks_event_handler))

      # ============================
      # デッキイベントのハンドラ
      # ============================
      @duel.deck.add_finish_listener_deck_init_event(method(:deck_init_handler))
      @duel.deck.add_finish_listener_append_joker_card_event(method(:deck_init_handler))

      # =================================
      # アクションカードのハンドラ
      # =================================
      # チャンスカードイベントのハンドラ
      @duel.deck.all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.event_decks[0].all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.event_decks[1].all_cards_add_event_listener(:add_finish_listener_chance_event, method(:action_card_chance_event_handler))
      @duel.event_decks[0].add_finish_listener_create_chance_card_event(method(:chance_card_create_event_handler))
      @duel.event_decks[1].add_finish_listener_create_chance_card_event(method(:chance_card_create_event_handler))
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
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_update_cat_state_event(method(:pl_entrant_cat_state_update_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_update_cat_state_event(method(:foe_entrant_cat_state_update_event_handler)) }

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

      # キャラカード変身イベント
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_change_chara_card_event(method(:pl_entrant_change_chara_card_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_change_chara_card_event(method(:foe_entrant_change_chara_card_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_transform_event(method(:pl_entrant_on_transform_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_transform_event(method(:foe_entrant_on_transform_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_transform_event(method(:pl_entrant_off_transform_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_transform_event(method(:foe_entrant_off_transform_event_handler)) }

      # パッシブスキルのイベントハンドラ
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_on_passive_event(method(:pl_entrant_on_passive_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_on_passive_event(method(:foe_entrant_on_passive_event_handler)) }
      @duel.entrants[@no].chara_cards.each{ |c| c.add_finish_listener_off_passive_event(method(:pl_entrant_off_passive_event_handler)) }
      @duel.entrants[@foe].chara_cards.each{ |c| c.add_finish_listener_off_passive_event(method(:foe_entrant_off_passive_event_handler)) }

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
    def one_to_one_duel_start_handler(duel)
      if duel.turn == 0
        set_message_str_data(DUEL_MSGDLG_DUEL_START)
        set_cache_act_command()
      end
    end

    # スタート時のハンドラ
    def three_to_three_duel_start_handler(duel)
      if duel.turn == 0
        set_message_str_data(DUEL_MSGDLG_M_DUEL_START)
        set_cache_act_command()
      end
    end



    # =========
    # DuelPhase
    # =========
    # ターンスタートのハンドラ
    def duel_start_turn_phase_handler(target, ret)
      sc_duel_start_turn_phase(ret)
      set_cache_act_command(ret)
    end

    # カードが配られた場合のハンドラ
    def duel_refill_card_phase_handler(duel,ret)
      if ret
        size = ret[@foe].size
        sc_duel_refill_phase(ActionCard.array2str(ret[@no]), ActionCard::array2int_dir(ret[@no]), size)
        ac_arr = []
        ret[@no].each { |ac| ac_arr << 0 }
        set_cache_act_command(ac_arr.join(","), 0, size)
      end
    end

    # イベントカードが配られた場合のハンドラ
    def duel_refill_event_card_phase_handler(duel, ret)
      if ret
        ac_arr_str = ActionCard.array2str(ret[@no])
        ac_arr_int_dir = ActionCard::array2int_dir(ret[@no])
        size = ret[@foe].size
        sc_duel_refill_event_phase(ac_arr_str, ac_arr_int_dir, size)
        ac_arr = []
        ret[@no].each { |ac| ac_arr << 0 }
        set_cache_act_command(ac_arr.join(","), 0, size)
      end
    end

    # 移動カード提出フェイズ開始
    def duel_move_card_phase_start_handler(target)
      sc_duel_move_card_drop_phase_start
      set_cache_act_command()
    end

    # 移動カード提出フェイズ終了
    def duel_move_card_phase_finish_handler(target, ret)
      sc_duel_move_card_drop_phase_finish
      set_cache_act_command()
    end


    # 移動の結果がでた時にハンドラ
    def duel_determine_move_phase_handler(target, ret)
      name = (target.initi[0]==@no)? DUEL_NAME_PL : DUEL_NAME_FOE
      set_message_str_data(DUEL_MSGDLG_INITIATIVE,name)

      initi = (target.initi[0]==@no)
      distance = target.first_entrant.distance_appearance
      pl_ac_arr_str = ActionCard::array2str(ret[@no])
      pl_ac_arr_int_dir = ActionCard.array2str_dir(ret[@no])
      foe_ac_arr_str = ActionCard::array2str(ret[@foe])
      foe_ac_arr_int_dir = ActionCard.array2str_dir(ret[@foe])
      pl_locked = duel.entrants[@no].table_cards_lock
      foe_locked = duel.entrants[@foe].table_cards_lock
      determine_move_args = [initi,distance,pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,ret[@no+2],ret[@foe+2],pl_locked,foe_locked]
      sc_duel_determine_move_phase(initi,distance,pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,ret[@no+2],ret[@foe+2],pl_locked,foe_locked)

      set_message_str_data(DUEL_MSGDLG_DISTANCE,target.first_entrant.distance_appearance)

      audience_str_data = [DUEL_MSGDLG_INITIATIVE,DUEL_NAME_WATCH.gsub("__NAME__",target.avatar_names[target.initi[0]].force_encoding("UTF-8"))] if target&&target.avatar_names
      dista_str_data = [DUEL_MSGDLG_DISTANCE,target.first_entrant.distance]
      set_cache_act_command(audience_str_data,determine_move_args,dista_str_data)
    end

    # キャラ変更フェイズ開始
    def duel_chara_change_phase_start_handler(duel)
      pl_change_done = duel.entrants[@no].change_done?
      foe_change_done = duel.entrants[@foe].change_done?
      sc_duel_chara_change_phase_start(pl_change_done,foe_change_done)
      set_cache_act_command(pl_change_done,foe_change_done)
    end

   # キャラ変更フェイズ終了
    def duel_chara_change_phase_finish_handler(duel, ret)
      # フェイズ終了時に変更キャラが選択されてない場合は適当なキャラに変更する
      duel.entrants.each { |e| e.chara_change_action if e.not_change_done? }
      # 敵のキャラチェンジ情報は最後に送る
      foe_current_cc_no = duel.entrants[@foe].current_chara_card_no
      foe_current_cc_id = duel.entrants[@foe].current_chara_card.id
      foe_current_wb_str = duel.entrants[@foe].current_weapon_bonus.join(",")
      sc_entrant_chara_change_action(false, foe_current_cc_no, foe_current_cc_id, foe_current_wb_str)

      set_message_str_data(DUEL_MSGDLG_CHANGE_CHARA)
      sc_duel_chara_change_phase_finish

      # プレイヤーのキャラチェンジ情報を観戦に送る
      pl_current_cc_no = duel.entrants[@no].current_chara_card_no
      pl_current_cc_id = duel.entrants[@no].current_chara_card.id
      pl_current_wb_str = duel.entrants[@no].current_weapon_bonus.join(",")

      pl_cc_data = [pl_current_cc_no, pl_current_cc_id, pl_current_wb_str]
      foe_cc_data = [foe_current_cc_no, foe_current_cc_id, foe_current_wb_str]

      set_cache_act_command(false, pl_cc_data, foe_cc_data)

    end

    # 攻撃カード提出フェイズ開始
    def duel_attack_card_phase_start_handler(duel)
      # 攻撃側と防御側のポイントを送る
      f_on = duel.entrants[@foe].current_on_cards
      p_on = duel.entrants[@no].current_on_cards
      foe_point_check = duel.entrants[@foe].point_check
      pl_point_check = duel.entrants[@no].point_check
      sc_entrant_point_update_event(false,f_on[0],f_on[1],foe_point_check)
      sc_entrant_point_update_event(true,p_on[0],p_on[1],pl_point_check)
      # イニシアチブを伝えて攻撃フェイズを始める
      initi = (duel.initi[0]==@no)
      sc_duel_attack_card_drop_phase_start(initi)
      foe_point_update_arg = [f_on[0],f_on[1],foe_point_check]
      pl_point_update_arg = [p_on[0],p_on[1],pl_point_check]
      set_cache_act_command(foe_point_update_arg, pl_point_update_arg,initi)
    end

    # 防御カード提出フェイズ開始
    def duel_deffence_card_phase_start_handler(duel)
      # 攻撃側と防御側のポイントを送る
      f_on = duel.entrants[@foe].current_on_cards
      p_on = duel.entrants[@no].current_on_cards
      foe_point_check = duel.entrants[@foe].point_check
      pl_point_check = duel.entrants[@no].point_check
      sc_entrant_point_update_event(false,f_on[0],f_on[1],foe_point_check)
      sc_entrant_point_update_event(true,p_on[0],p_on[1],pl_point_check)
      # イニシアチブを伝えて防御フェイズを始める
      initi = (duel.initi[1]==@no)
      sc_duel_deffence_card_drop_phase_start(initi)
      foe_point_update_arg = [f_on[0],f_on[1],foe_point_check]
      pl_point_update_arg = [p_on[0],p_on[1],pl_point_check]
      set_cache_act_command(foe_point_update_arg, pl_point_update_arg,initi)
    end

    # 攻撃カード提出フェイズ終了
    def duel_attack_card_phase_finish_handler(duel, ret)
      f_on = duel.entrants[@foe].current_on_cards
      p_on = duel.entrants[@no].current_on_cards
      foe_point_check = duel.entrants[@foe].point_check
      pl_point_check = duel.entrants[@no].point_check
      sc_entrant_point_update_event(false,f_on[0],f_on[1],foe_point_check)
      sc_entrant_point_update_event(true,p_on[0],p_on[1],pl_point_check)
      pl_ac_arr_str = ActionCard.array2str(ret[@no])
      pl_ac_arr_int_dir = ActionCard.array2str_dir(ret[@no])
      foe_ac_arr_str = ActionCard.array2str(ret[@foe])
      foe_ac_arr_int_dir = ActionCard.array2str_dir(ret[@foe])
      pl_locked = duel.entrants[@no].table_cards_lock
      foe_locked = duel.entrants[@foe].table_cards_lock
      sc_duel_attack_card_drop_phase_finish(pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked)
      foe_point_update_arg = [f_on[0],f_on[1],foe_point_check]
      pl_point_update_arg = [p_on[0],p_on[1],pl_point_check]
      attach_card_drop_finish_args = [pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked]
      set_cache_act_command(foe_point_update_arg, pl_point_update_arg,attach_card_drop_finish_args)
    end

    # 防御カード提出フェイズ終了
    def duel_deffence_card_phase_finish_handler(duel, ret)
      f_on = duel.entrants[@foe].current_on_cards
      p_on = duel.entrants[@no].current_on_cards
      foe_point_check = duel.entrants[@foe].point_check
      pl_point_check = duel.entrants[@no].point_check
      sc_entrant_point_update_event(false,f_on[0],f_on[1],foe_point_check)
      sc_entrant_point_update_event(true,p_on[0],p_on[1],pl_point_check)
      pl_ac_arr_str = ActionCard.array2str(ret[@no])
      pl_ac_arr_int_dir = ActionCard.array2str_dir(ret[@no])
      foe_ac_arr_str = ActionCard.array2str(ret[@foe])
      foe_ac_arr_int_dir = ActionCard.array2str_dir(ret[@foe])
      pl_locked = duel.entrants[@no].table_cards_lock
      foe_locked = duel.entrants[@foe].table_cards_lock
      sc_duel_deffence_card_drop_phase_finish(pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked)
      foe_point_update_arg = [f_on[0],f_on[1],foe_point_check]
      pl_point_update_arg = [p_on[0],p_on[1],pl_point_check]
      deffence_card_drop_finish_args = [pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked]
      set_cache_act_command(foe_point_update_arg, pl_point_update_arg,deffence_card_drop_finish_args)
    end

    # 戦闘ポイント決定フェイズの時のハンドラ
    def duel_det_battle_point_phase_handler(duel, ret)
      set_message_str_data(DUEL_MSGDLG_BTL_POINT,duel.entrants[duel.initi[0]].tmp_power)

      pl_ac_arr_str = ActionCard.array2str(ret[@no])
      pl_ac_arr_int_dir = ActionCard.array2str_dir(ret[@no])
      foe_ac_arr_str = ActionCard.array2str(ret[@foe])
      foe_ac_arr_int_dir = ActionCard.array2str_dir(ret[@foe])
      pl_locked = duel.entrants[@no].table_cards_lock
      foe_locked = duel.entrants[@foe].table_cards_lock
      sc_duel_determine_battle_point_phase(pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked)

      str_data = [DUEL_MSGDLG_BTL_POINT,duel.entrants[duel.initi[0]].tmp_power]
      determine_battle_point_args = [pl_ac_arr_str,pl_ac_arr_int_dir,foe_ac_arr_str,foe_ac_arr_int_dir,pl_locked,foe_locked]
      set_cache_act_command(str_data,determine_battle_point_args)
    end

    # 戦闘の結果がでた時のハンドラ
    def duel_battle_result_phase_handler(duel, ret)
      audience_str_data = [DUEL_MSGDLG_BTL_RESULT,DUEL_NAME_WATCH.gsub("__NAME__",duel.avatar_names[duel.initi[0]].force_encoding("UTF-8"))] if duel&&duel.avatar_names
      if ret[0].size==0
        name = (duel.initi[0]==@no)? DUEL_NAME_PL : DUEL_NAME_FOE
        set_message_str_data(DUEL_MSGDLG_BTL_RESULT,name)
      else
        a = audience_str_data = nil
      end
      initi = (duel.initi[0]==@no)
      ret_str_0 = ret[0].join(",")
      ret_str_1 = ret[1].join(",")
      sc_duel_battle_result_phase(initi,ret_str_0,ret_str_1)
      battle_result_args = [initi,ret_str_0,ret_str_1]

      set_cache_act_command(audience_str_data,battle_result_args)
    end

    # 死亡キャラ変更フェイズ開始
    def duel_dead_chara_change_phase_start_handler(duel)
      pl_change_done = duel.entrants[@no].change_done?;
      foe_change_done = duel.entrants[@foe].change_done?;
      pl_ac_arr_str = ActionCard.array2str(duel.entrants[@no].battle_table)
      foe_ac_arr_str = ActionCard.array2str(duel.entrants[@foe].battle_table)
      sc_duel_dead_chara_change_phase_start(pl_change_done,foe_change_done,pl_ac_arr_str,foe_ac_arr_str)
      set_cache_act_command(pl_change_done,foe_change_done,pl_ac_arr_str,foe_ac_arr_str)
    end

    # 死亡キャラ変更フェイズ終了
    def duel_dead_chara_change_phase_finish_handler(duel, ret)
      # フェイズ終了時に変更キャラが選択されてない場合は適当なキャラに変更する
      duel.entrants.each { |e| e.chara_change_action if e.not_change_done? }
      foe_current_cc_no = duel.entrants[@foe].current_chara_card_no
      foe_current_cc_id = duel.entrants[@foe].current_chara_card.id
      foe_current_wb_str = duel.entrants[@foe].current_weapon_bonus.join(",")
      sc_entrant_chara_change_action(false, foe_current_cc_no, foe_current_cc_id, foe_current_wb_str)
      set_message_str_data(DUEL_MSGDLG_CHANGE_CHARA)
      sc_duel_dead_chara_change_phase_finish

      # プレイヤーの情報
      pl_current_cc_no = duel.entrants[@no].current_chara_card_no
      pl_current_cc_id = duel.entrants[@no].current_chara_card.id
      pl_current_wb_str = duel.entrants[@no].current_weapon_bonus.join(",")

      pl_cc_data = [pl_current_cc_no, pl_current_cc_id, pl_current_wb_str]
      foe_cc_data = [foe_current_cc_no, foe_current_cc_id, foe_current_wb_str]

      set_cache_act_command(pl_cc_data, foe_cc_data)
    end

    # ターン終了のハンドラ
    def duel_finish_turn_phase_handler(duel, ret)
      # 移動ボタンをリセット
      direction = duel.entrants[@no].direction
      sc_entrant_set_direction_action(true, direction)
      set_cache_act_command(direction,ret)
    end

    # ===================
    # EntrantAction
    # ===================
    # 自分が移動方向を決定する
    def pl_entrant_set_direction_action_handler(target, ret)
      sc_entrant_set_direction_action(true, ret)
      set_cache_act_command(ret)
    end

    # 自分が移動カードを出す
    def pl_entrant_move_card_add_action_handler(target, ret)
      return unless ret
      sc_entrant_move_card_add_action(true, ret[0], ret[1])
      set_cache_act_command(ret[0], 0)
    end

    # 敵側が移動カードを出す
    def foe_entrant_move_card_add_action_handler(target, ret)
      return unless ret
      sc_entrant_move_card_add_action(false, ret[0], 0)
      set_cache_act_command(ret[0], 0)
    end

    # 敵側が移動カードを取り除く
    def foe_entrant_move_card_remove_action_handler(target, ret)
      sc_entrant_move_card_remove_action(false, ret[0], 0)
      set_cache_act_command(ret[0], 0)
    end

    # 自分側が移動カードを取り除く
    def pl_entrant_move_card_remove_action_handler(target, ret)
      sc_entrant_move_card_remove_action(true, ret[0],ret[1])
      set_cache_act_command(ret[0], 0)
    end

    # 敵側がカードを回転させる
    def foe_entrant_card_rotate_action_handler(target, ret)
      return unless ret
      sc_entrant_card_rotate_action(false, ret[0], ret[1], 0, ret[3])
      set_cache_act_command(ret[0], ret[1], 0, ret[3])
    end

    # 自分がカードを回転させる
    def pl_entrant_card_rotate_action_handler(target, ret)
      return unless ret
      sc_entrant_card_rotate_action(true, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], 0, ret[3])
    end

    # 敵側がイベントでカードを回転させる
    def foe_entrant_event_card_rotate_action_handler(target, ret)
      return unless ret
      sc_entrant_event_card_rotate_action(false, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3])
    end

    # 自分がイベントでカードを回転させる
    def pl_entrant_event_card_rotate_action_handler(target, ret)
      return unless ret
      sc_entrant_event_card_rotate_action(true, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3])
    end

    # 自分が戦闘カードを出す
    def pl_entrant_battle_card_add_action_handler(target, ret)
      return unless ret
      sc_entrant_battle_card_add_action(true, ret[0], ret[1])
      set_cache_act_command(ret[0], 0)
    end

    # 敵側が戦闘カードを出す
    def foe_entrant_battle_card_add_action_handler(target, ret)
      return unless ret
      sc_entrant_battle_card_add_action(false, ret[0], 0)
      set_cache_act_command(ret[0], 0)
    end

    # 自分が戦闘カードを取り除く
    def pl_entrant_battle_card_remove_action_handler(target, ret)
      sc_entrant_battle_card_remove_action(true, ret[0], ret[1])
      set_cache_act_command(ret[0], 0)
    end

    # 敵側が戦闘カードを取り除く
    def foe_entrant_battle_card_remove_action_handler(target, ret)
      sc_entrant_battle_card_remove_action(false, ret[0], 0)
      set_cache_act_command(ret[0], 0)
    end

    # 自分のキャラカードを変更する
    def pl_entrant_chara_change_action_handler(target, ret)
      sc_entrant_chara_change_action(true, ret[0], ret[1], ret[2].join(","))
      set_cache_act_command(ret[0], ret[1], ret[2].join(","))
    end

    # 相手のキャラカードを変更する
    def foe_entrant_chara_change_action_handler(target, ret)
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def foe_entrant_init_done_action_handler(target, ret)
      sc_entrant_init_done_action(false)
      set_cache_act_command()
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def pl_entrant_init_done_action_handler(target, ret)
      sc_entrant_init_done_action(true)
      set_cache_act_command()
    end

    # 敵側の攻撃フェイズの完了アクション
    def foe_entrant_attack_done_action_handler(target, ret)
      sc_entrant_attack_done_action(false)
      set_cache_act_command()
    end
    # 敵側の防御フェイズの完了アクション
    def foe_entrant_deffence_done_action_handler(target, ret)
      sc_entrant_deffence_done_action(false)
      set_cache_act_command()
    end

    # プレイヤー側の攻撃フェイズの完了アクション
    def pl_entrant_attack_done_action_handler(target, ret)
      sc_entrant_attack_done_action(true);
      set_cache_act_command()
    end

    # プレイヤー側の防御フェイズの完了アクション
    def pl_entrant_deffence_done_action_handler(target, ret)
      sc_entrant_deffence_done_action(true);
      set_cache_act_command()
    end

    # 自分が移動する
    def pl_entrant_move_action_handler(target, ret)
      sc_entrant_move_action(ret)
      set_cache_act_command(ret)
    end

    # ハイド中に自分が移動する
    def pl_entrant_hide_move_action_handler(target, ret)
      sc_entrant_hide_move_action(ret)
      set_cache_act_command(ret)
    end

    # ===================
    # EntrantEvent
    # ===================

    # プレイヤーダメージのイベント
    def plEntrant_damaged_event_handler(target, ret)
      sc_entrant_damaged_event(true,ret[0],ret[1])
      set_cache_act_command(ret)
    end

    # 敵ダメージのハンドラのイベント
    def foeEntrant_damaged_event_handler(target, ret)
      sc_entrant_damaged_event(false,ret[0],ret[1])
      set_cache_act_command(ret)
    end

    # プレイヤーの回復イベント
    def plEntrant_healed_event_handler(target, ret)
      sc_entrant_healed_event(true,ret.first)
      set_cache_act_command(ret.first)
    end

    # 敵の回復イベント
    def foeEntrant_healed_event_handler(target, ret)
      sc_entrant_healed_event(false,ret.first)
      set_cache_act_command(ret.first)
    end

    # プレイヤーのパーティ回復イベント
    def plEntrant_party_healed_event_handler(target, ret)
      sc_entrant_party_healed_event(true, ret[0], ret[1])
      set_cache_act_command( ret[0], ret[1])
    end

    # 敵のパーティ回復イベント
    def foeEntrant_party_healed_event_handler(target, ret)
      sc_entrant_party_healed_event(false, ret[0], ret[1])
      set_cache_act_command(ret[0], ret[1])
    end

    # プレイヤーのパーティ蘇生イベント
    def plEntrant_revive_event_handler(target, ret)
      sc_entrant_revive_event(true, ret[0], ret[1])
      set_cache_act_command( ret[0], ret[1])
    end

    # 敵のパーティ蘇生イベント
    def foeEntrant_revive_event_handler(target, ret)
      sc_entrant_revive_event(false, ret[0], ret[1])
      set_cache_act_command(ret[0], ret[1])
    end

    # プレイヤーの行動制限イベント
    def plEntrant_constraint_event_handler(target, ret)
      sc_entrant_constraint_event(true, ret)
      set_cache_act_command(ret)
    end

    # プレイヤーのHP変更イベント
    def plEntrant_hit_point_changed_event_handler(target, ret)
      sc_entrant_hit_point_changed_event(true,ret.first)
      set_cache_act_command(ret.first)
    end

    # 敵のHP変更イベント
    def foeEntrant_hit_point_changed_event_handler(target, ret)
      sc_entrant_hit_point_changed_event(false,ret.first)
      set_cache_act_command(ret.first)
    end

    # プレイヤーのパーティダメージイベント
    def plEntrant_party_damaged_event_handler(target, ret)
      sc_entrant_party_damaged_event(true, ret[0], ret[1], ret[2])
      set_cache_act_command(ret[0], ret[1], ret[2])
    end

    # 敵のパーティダメージイベント
    def foeEntrant_party_damaged_event_handler(target, ret)
      sc_entrant_party_damaged_event(false, ret[0], ret[1], ret[2])
      set_cache_act_command(ret[0], ret[1], ret[2])
    end

    # プレイヤーの状態回復イベント
    def plEntrant_cured_event_handler(target, ret)
      sc_entrant_cured_event(true)
      set_cache_act_command()
    end

    # 敵の状態回復イベント
    def foeEntrant_cured_event_handler(target, ret)
      sc_entrant_cured_event(false)
      set_cache_act_command()
    end

    # プレイヤーの必殺技解除イベント
    def plEntrant_sealed_event_handler(target, ret)
      sc_entrant_sealed_event(true)
    end

    # 敵の必殺技解除イベント
    def foeEntrant_sealed_event_handler(target, ret)
      sc_entrant_sealed_event(false)
    end

    # プレイヤーアクションカード使用イベント
    def plEntrant_use_action_card_event_handler(target, ret)
      sc_entrant_use_action_card_event(true,ret)
      set_cache_act_command(ret)
    end

    # プレイヤーアクションカード使用イベント
    def foeEntrant_use_action_card_event_handler(target, ret)
      sc_entrant_use_action_card_event(false,ret)
      set_cache_act_command(ret)
    end

    # プレイヤーアクションカード破棄イベント
    def plEntrant_discard_event_handler(target, ret)
      sc_entrant_discard_event(true,ret)
      set_cache_act_command(ret)
    end

    # 敵のアクションカード破棄イベント
    def foeEntrant_discard_event_handler(target, ret)
      sc_entrant_discard_event(false,ret)
      set_cache_act_command(ret)
    end

    # プレイヤーアクションカードをテーブルから破棄するイベント
    def plEntrant_discard_table_event_handler(target, ret)
      sc_entrant_discard_table_event(true,ret)
      set_cache_act_command(ret)
    end

    # 敵のアクションカードをテーブルから破棄するイベント
    def foeEntrant_discard_table_event_handler(target, ret)
      sc_entrant_discard_table_event(false,ret)
      set_cache_act_command(ret)
    end

    # プレイヤーのポイントが更新された場合のイベント
    def plEntrant_point_update_event_handler(target, ret)
      if @duel
        p_on = @duel.entrants[@no].current_on_cards
        if p_on
          sc_entrant_point_update_event(true, p_on[0], p_on[1], ret)
          set_cache_act_command(p_on[0], p_on[1], ret)
        end
      end
    end

    # プレイヤーのポイントが上書きされた場合のイベント
    def plEntrant_point_rewrite_event_handler(target, ret)
      if @duel
        sc_entrant_point_rewrite_event(true, ret)
        set_cache_act_command(ret)
      end
    end

    # 相手のポイントが上書きされた場合のイベント
    def foeEntrant_point_rewrite_event_handler(target, ret)
      if @duel
        sc_entrant_point_rewrite_event(false, ret)
        set_cache_act_command(ret)
      end
    end

    # プレイヤーが特別にカードを配られる場合のイベント
    def plEntrant_special_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = ret.size
      sc_entrant_special_dealed_event(true, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # 敵が特別にカードを配られる場合のイベント
    def foeEntrant_special_dealed_event_handler(target, ret)
      size = ret.size
      sc_entrant_special_dealed_event(false, "", 0, size)
      set_cache_act_command("", 0, size)
    end

    # プレイヤーに墓地のカードが配られる場合のイベント
    def plEntrant_grave_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = ret.size
      sc_entrant_grave_dealed_event(true, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # 敵に墓地のカードが配られる場合のイベント
    def foeEntrant_grave_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = ret.size
      sc_entrant_grave_dealed_event(false, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # プレイヤーに相手の手札のカードが配られる場合のイベント
    def plEntrant_steal_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = ret.size
      sc_entrant_steal_dealed_event(true, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # 敵にプレイヤーの手札のカードが配られる場合のイベント
    def foeEntrant_steal_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = ret.size
      sc_entrant_steal_dealed_event(false, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # プレイヤーが特別にイベントカードを配られる場合のイベント
    def plEntrant_special_event_card_dealed_event_handler(target, ret)
      ac_arr_str = ActionCard::array2str(ret)
      ac_arr_int_dir = ActionCard::array2int_dir(ret)
      size = 0
      sc_entrant_special_event_card_dealed_event(true, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # 敵が特別にイベントカードを配られる場合のイベント
    def foeEntrant_special_event_card_dealed_event_handler(target, ret)
      ac_arr_str = ""
      ac_arr_int_dir = 0
      size = ret.size
      sc_entrant_special_event_card_dealed_event(false, ac_arr_str, ac_arr_int_dir, size)
      set_cache_act_command(ac_arr_str, ac_arr_int_dir, size)
    end

    # プレイヤーのカードの値が変更される場合のイベント
    def plEntrant_update_card_value_event_handler(target, ret)
      sc_entrant_update_card_value_event(true, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3])
    end

    # 敵のカードの値が変更される場合のイベント
    def foeEntrant_update_card_value_event_handler(target, ret)
      sc_entrant_update_card_value_event(false, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3])
    end

    # プレイヤーに仮のダイスが振られるときのイベント
    def plEntrant_dice_roll_event_handler(target, ret)
      arr_str_0 = ret[0].join(",")
      arr_str_1 = ret[1].join(",")
      sc_duel_battle_result_phase(true, arr_str_0, arr_str_1)
      set_cache_act_command(arr_str_0, arr_str_1)
    end

    # 敵に仮のダイスが振られるときのイベント
    def foeEntrant_dice_roll_event_handler(target, ret)
      arr_str_0 = ret[0].join(",")
      arr_str_1 = ret[1].join(",")
      sc_duel_battle_result_phase(false, arr_str_0, arr_str_1)
      set_cache_act_command(arr_str_0, arr_str_1)
    end

    # プレイヤーの装備カードが更新されるときのイベント
    def plEntrant_update_weapon_event_handler(target, ret)
      arr_str_0 = ret[0].join(",")
      arr_str_1 = ret[1].join(",")
      sc_entrant_update_weapon_event(true, arr_str_0, arr_str_1)
      set_cache_act_command(arr_str_0, arr_str_1)
    end

    # プレイヤーの最大カード枚数が更新された場合のイベント
    def plEntrant_cards_max_update_event_handler(target, ret)
      sc_entrant_cards_max_update_event(true,ret)
      set_cache_act_command(ret)
    end

    # プレイヤーの最大カード枚数が更新された場合のイベント
    def plEntrant_duel_bonus_event_handler(target, ret)
      sc_duel_bonus_event(ret[0],ret[1])
      set_cache_act_command(ret[0], ret[1])
     end

    # プレイヤーの特殊メッセージのイベント
    def plEntrant_special_message_event_handler(target, ret)
      sc_message(ret.force_encoding("UTF-8"))
      set_cache_act_command(ret)
    end

    # プレイヤーの特殊メッセージのイベント
    def foeEntrant_special_message_event_handler(target, ret)
      sc_message(ret.force_encoding("UTF-8"))
      set_cache_act_command(ret)
    end

    # プレイヤーの属性抵抗メッセージのイベント
    def plEntrant_attribute_regist_message_event_handler(target, ret)
      sc_message(ret.force_encoding("UTF-8"))
      set_cache_act_command(ret)
    end

    # プレイヤーの属性抵抗メッセージのイベント
    def foeEntrant_attribute_regist_message_event_handler(target, ret)
      sc_message(ret.force_encoding("UTF-8"))
      set_cache_act_command(ret)
    end

    # デュエル中の汎用メッセージ
    def plEntrant_duel_message_event_handler(target, ret)
      case ret[0]
      when DUEL_MSGDLG_WEAPON_STATUS_UP,DUEL_MSGDLG_SWORD_DEF_UP,DUEL_MSGDLG_ARROW_DEF_UP
        set_message_str_data(ret[0], DUEL_NAME_PL)
        set_cache_act_command(ret[0], DUEL_NAME_PL)
      when DUEL_MSGDLG_AVOID_DAMAGE,DUEL_MSGDLG_CONSTRAINT
        set_message_str_data(ret[0], ret[1], DUEL_NAME_PL)
        set_cache_act_command(ret[0], ret[1], DUEL_NAME_PL)
      else
        set_message_str_data(ret[0])
        set_cache_act_command(ret[0])
      end
    end

    # デュエル中の汎用メッセージ
    def foeEntrant_duel_message_event_handler(target, ret)
      case ret[0]
      when DUEL_MSGDLG_WEAPON_STATUS_UP,DUEL_MSGDLG_SWORD_DEF_UP,DUEL_MSGDLG_ARROW_DEF_UP
        set_message_str_data(ret[0], DUEL_NAME_FOE)
        set_cache_act_command(ret[0], DUEL_NAME_FOE)
      when DUEL_MSGDLG_AVOID_DAMAGE,DUEL_MSGDLG_CONSTRAINT
        set_message_str_data(ret[0], ret[1], DUEL_NAME_FOE)
        set_cache_act_command(ret[0], ret[1], DUEL_NAME_FOE)
      else
        set_message_str_data(ret[0])
        set_cache_act_command(ret[0])
      end
    end

    # プレイヤーのトラップ発動イベント
    def plEntrant_trap_action_event_handler(target, ret)
      audience_str_data = ""

      case ret[0]
      when TRAP_ARLE
        set_message_str_data(DUEL_MSGDLG_TRAP_ARLE, DUEL_NAME_PL)
        audience_str_data = [DUEL_MSGDLG_TRAP_ARLE, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@no].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      when TRAP_INSC
        set_message_str_data(DUEL_MSGDLG_TRAP_INSC, DUEL_NAME_PL)
        audience_str_data = [DUEL_MSGDLG_TRAP_INSC, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@no].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      else
        set_message_str_data(DUEL_MSGDLG_TRAP, DUEL_NAME_PL)
        audience_str_data = [DUEL_MSGDLG_TRAP, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@no].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      end

      sc_entrant_trap_action_event(true,ret[0],ret[1])
      set_cache_act_command(audience_str_data, ret)
    end

    # 敵のトラップ発動イベント
    def foeEntrant_trap_action_event_handler(target, ret)
      audience_str_data = ""

      case ret[0]
      when TRAP_ARLE
        set_message_str_data(DUEL_MSGDLG_TRAP_ARLE, DUEL_NAME_FOE)
        audience_str_data = [DUEL_MSGDLG_TRAP_ARLE, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@foe].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      when TRAP_INSC
        set_message_str_data(DUEL_MSGDLG_TRAP_INSC, DUEL_NAME_FOE)
        audience_str_data = [DUEL_MSGDLG_TRAP_INSC, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@foe].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      else
        set_message_str_data(DUEL_MSGDLG_TRAP, DUEL_NAME_FOE)
        audience_str_data = [DUEL_MSGDLG_TRAP, DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[@foe].force_encoding("UTF-8"))] if @duel && @duel.avatar_names
      end

      sc_entrant_trap_action_event(false,ret[0],ret[1])
      set_cache_act_command(audience_str_data, ret)
    end

    # プレイヤーのトラップ遷移イベント
    def plEntrant_trap_update_event_handler(target, ret)
      sc_entrant_trap_update_event(true,ret[0],ret[1],ret[2],ret[3])
      set_cache_act_command(ret)
    end

    # 敵のトラップ遷移イベント
    def foeEntrant_trap_update_event_handler(target, ret)
      sc_entrant_trap_update_event(false,ret[0],ret[1],ret[2],ret[3])
      set_cache_act_command(ret)
    end

    # フィールド状態変更イベント
    def plEntrant_set_field_status_event_handler(target, ret)
      sc_set_field_status_event(ret[0], ret[1], ret[2])
      set_cache_act_command(ret)
    end

    # フィールド状態変更イベント
    def foeEntrant_set_field_status_event_handler(target, ret)
      sc_set_field_status_event(ret[0], ret[1], ret[2])
      set_cache_act_command(ret)
    end

    # 現在ターン数変更のイベント
    def plEntrant_set_turn_event_handler(target, ret)
      sc_set_turn_event(ret)
      set_cache_act_command(ret)
    end

    # 現在ターン数変更のイベント
    def foeEntrant_set_turn_event_handler(target, ret)
      sc_set_turn_event(ret)
      set_cache_act_command(ret)
    end

    # カードロックイベント
    def plEntrant_card_lock_event_handler(target, ret)
      sc_card_lock_event(ret)
      set_cache_act_command(ret)
    end

    # カードロック解除イベント
    def plEntrant_clear_card_locks_event_handler(target, ret)
      sc_clear_card_locks_event()
      set_cache_act_command()
    end

    # =====================
    # DeckEvent
    # =====================

    # デッキの初期化のハンドラ
    def deck_init_handler(target, ret)
     sc_deck_init_event(ret)
     set_cache_act_command(ret)
    end

    # =====================
    # ActionCardEvent
    # =====================
    def action_card_chance_event_handler(target,ret)
      if @duel
        size = ret.size
        if (@duel.entrants[@no]==target.owner)
          ac_arr_str = ActionCard::array2str(ret)
          ac_arr_int_dir = ActionCard::array2int_dir(ret)
          sc_actioncard_chance_event(true, ac_arr_str, ac_arr_int_dir, size)
          set_cache_act_command(true, ac_arr_str, ac_arr_int_dir, size)
        else
          sc_actioncard_chance_event(false, "", 0, size)
          set_cache_act_command(false, "", 0, size)
        end
      end
    end

    def chance_card_create_event_handler(target,ret)
      target.card_add_event_listener(ret, :add_finish_listener_chance_event, method(:action_card_chance_event_handler))
    end

    def action_card_heal_event_handler(target,ret)
    end


    # =====================
    # CharaCardEvent
    # =====================
    # 状態付加ON時のプレイヤー側ハンドラ
    def pl_entrant_buff_on_event_handler(target,ret)
      sc_buff_on_event(ret[0], ret[1], ret[2], ret[3], ret[4])
      name = (ret[0]) ? DUEL_NAME_PL : DUEL_NAME_FOE
      set_message_str_data(DUEL_MSGDLG_STATE,ret[2],name) if duel.entrants[@no].current_chara_card_no == ret[1]
      name_idx = (ret[0]) ? @no : @foe
      audience_str_data = [DUEL_MSGDLG_STATE,ret[2],DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[name_idx].force_encoding("UTF-8"))] if @duel&&@duel.avatar_names
      set_cache_act_command([ret[0], ret[1], ret[2], ret[3], ret[4]],audience_str_data)
    end

    # 状態付加ON時の敵側側ハンドラ
    def foe_entrant_buff_on_event_handler(target,ret)
      sc_buff_on_event(!ret[0], ret[1], ret[2], ret[3], ret[4])
      name = (!ret[0]) ? DUEL_NAME_PL : DUEL_NAME_FOE
      set_message_str_data(DUEL_MSGDLG_STATE,ret[2],name) if duel.entrants[@foe].current_chara_card_no == ret[1]
      name_idx = (!ret[0]) ? @no : @foe
      audience_str_data = [DUEL_MSGDLG_STATE,ret[2],DUEL_NAME_WATCH.gsub("__NAME__",@duel.avatar_names[name_idx].force_encoding("UTF-8"))] if @duel&&@duel.avatar_names
      set_cache_act_command([!ret[0], ret[1], ret[2], ret[3], ret[4]],audience_str_data)
    end

    # 状態付加Off時のプレイヤー側ハンドラ
    def pl_entrant_buff_off_event_handler(target,ret)
      sc_buff_off_event(ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3])
    end

    # 状態付加Off時の敵側側ハンドラ
    def foe_entrant_buff_off_event_handler(target,ret)
      sc_buff_off_event(!ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(!ret[0], ret[1], ret[2], ret[3])
    end

    # 状態付加Update時のプレイヤー側ハンドラ
    def pl_entrant_buff_update_event_handler(target,ret)
      sc_buff_update_event(ret[0], ret[1], ret[2], ret[3], ret[4])
      set_cache_act_command(ret[0], ret[1], ret[2], ret[3], ret[4])
    end

    # 状態付加Update時の敵側側ハンドラ
    def foe_entrant_buff_update_event_handler(target,ret)
      sc_buff_update_event(!ret[0], ret[1], ret[2], ret[3], ret[4])
      set_cache_act_command(!ret[0], ret[1], ret[2], ret[3], ret[4])
    end

    # 猫状態Update時のプレイヤー側ハンドラ
    def pl_entrant_cat_state_update_event_handler(target,ret)
      sc_cat_state_update_event(ret[0], ret[1], ret[2])
      set_cache_act_command(ret[0], ret[1], ret[2])
    end

    # 猫状態Update時の敵側側ハンドラ
    def foe_entrant_cat_state_update_event_handler(target,ret)
      sc_cat_state_update_event(!ret[0], ret[1], ret[2])
      set_cache_act_command(!ret[0], ret[1], ret[2])
    end

    # 必殺技ON時のプレイヤー側ハンドラ
    def pl_entrant_feat_on_event_handler(target,ret)
      sc_pl_feat_on_event(ret)
      # 観戦時はOn/Offしない
      # set_cache_act_command(ret)
    end

    # 必殺技ON時の敵側側ハンドラ
    def foe_entrant_feat_on_event_handler(target,ret)
    end

    # 必殺技Off時のプレイヤー側ハンドラ
    def pl_entrant_feat_off_event_handler(target,ret)
      sc_pl_feat_off_event(ret)
    end

    # 必殺技Off時の敵側側ハンドラ
    def foe_entrant_feat_off_event_handler(target,ret)
    end

    # 必殺技が変更された時のプレイヤー側ハンドラ
    def pl_entrant_change_feat_event_handler(target,ret)
      sc_entrant_change_feat_event(true, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret)
    end

    # 必殺技が変更された時の敵側ハンドラ
    def foe_entrant_change_feat_event_handler(target,ret)
      sc_entrant_change_feat_event(false, ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret)
    end

    # 必殺技が実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_feat_event_handler(target,ret)
      sc_entrant_use_feat_event(true, ret)
      set_cache_act_command(ret)
    end

    # 必殺技が実行された時の敵側ハンドラ
    def foe_entrant_use_feat_event_handler(target,ret)
      sc_entrant_use_feat_event(false, ret)
      set_cache_act_command(ret)
    end

    # パッシブが実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_passive_event_handler(target,ret)
      sc_entrant_use_passive_event(true, ret)
      set_cache_act_command(ret)
    end

    # パッシブが実行された時の敵側ハンドラ
    def foe_entrant_use_passive_event_handler(target,ret)
      sc_entrant_use_passive_event(false, ret)
      # パッシブがCREATEER立った場合
      if ret == Unlight::CharaCardEvent::PASSIVE_CREATOR
        @duel.entrants[@foe].current_chara_card.add_finish_listener_on_buff_event(method(:foe_entrant_buff_on_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_off_buff_event(method(:foe_entrant_buff_off_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_update_buff_event(method(:foe_entrant_buff_update_event_handler))

        @duel.entrants[@foe].current_chara_card.add_finish_listener_on_feat_event(method(:foe_entrant_feat_on_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_off_feat_event(method(:foe_entrant_feat_off_event_handler))
        # 必殺技が使われた時イベント
        @duel.entrants[@foe].current_chara_card.add_finish_listener_use_feat_event(method(:foe_entrant_use_feat_event_handler))
        # パッシブが使われた時イベント
        @duel.entrants[@foe].current_chara_card.add_finish_listener_use_passive_event(method(:foe_entrant_use_passive_event_handler))
        # キャラカード変身イベント
        @duel.entrants[@foe].current_chara_card.add_finish_listener_change_chara_card_event(method(:foe_entrant_change_chara_card_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_on_transform_event(method(:foe_entrant_on_transform_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_stuffed_toys_set_event(method(:foe_entrant_stuffed_toys_set_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_off_transform_event(method(:foe_entrant_off_transform_event_handler))
        # パッシブスキルのイベントハンドラ
        @duel.entrants[@foe].current_chara_card.add_finish_listener_on_passive_event(method(:foe_entrant_on_passive_event_handler))
        @duel.entrants[@foe].current_chara_card.add_finish_listener_off_passive_event(method(:foe_entrant_off_passive_event_handler))
      end
      set_cache_act_command(ret)
    end

    # キャラカードを更新するプレイヤー側ハンドラ 変身用
    def pl_entrant_change_chara_card_event_handler(target,ret)
      sc_entrant_change_chara_card_event(true, ret)
      set_cache_act_command(ret)
    end

    # キャラカードを更新するプレイヤー側ハンドラ 変身用
    def foe_entrant_change_chara_card_event_handler(target,ret)
      sc_entrant_change_chara_card_event(false, ret)
      set_cache_act_command(ret)
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_on_transform_event_handler(target,ret)
      sc_entrant_on_transform_event(ret[0],ret[1])
      set_cache_act_command(ret[0],ret[1])
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_on_transform_event_handler(target,ret)
      sc_entrant_on_transform_event(!ret[0],ret[1])
      set_cache_act_command(!ret[0],ret[1])
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_off_transform_event_handler(target,ret)
      sc_entrant_off_transform_event(ret)
      set_cache_act_command(ret)
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_off_transform_event_handler(target,ret)
      sc_entrant_off_transform_event(!ret)
      set_cache_act_command(!ret)
    end

    # きりがくれプレイヤー側ON
    def pl_entrant_on_lost_in_the_fog_event_handler(target, ret)
      sc_entrant_on_lost_in_the_fog_event(ret[0], ret[1], ret[2])
      set_cache_act_command(ret[0],ret[1],ret[2])
    end

    # きりがくれ的側ON
    def foe_entrant_on_lost_in_the_fog_event_handler(target, ret)
      sc_entrant_on_lost_in_the_fog_event(!ret[0], ret[1], 0)
      set_cache_act_command(!ret[0],ret[1])
    end

    # きりがくれプレイヤー側OFF
    def pl_entrant_off_lost_in_the_fog_event_handler(target, ret)
      sc_entrant_off_lost_in_the_fog_event(ret[0],ret[1])
      set_cache_act_command(ret[0],ret[1])
    end

    # きりがくれ的側OFF
    def foe_entrant_off_lost_in_the_fog_event_handler(target, ret)
      sc_entrant_off_lost_in_the_fog_event(!ret[0],ret[1])
      set_cache_act_command(!ret[0],ret[1])
    end

    # プレイヤー側 霧ライト
    def pl_entrant_in_the_fog_event_handler(target, ret)
      return if ret[1].nil?
      sc_entrant_in_the_fog_event(ret[0], ret[1])
      set_cache_act_command(ret[0],ret[1])
    end

    # 敵側霧ライト
    def foe_entrant_in_the_fog_event_handler(target, ret)
      return if ret[1].nil?
      sc_entrant_in_the_fog_event(!ret[0], ret[1])
      set_cache_act_command(!ret[0],ret[1])
    end

    # 技の発動条件を更新 PL
    def pl_entrant_update_feat_condition_event_handler(target, ret)
      sc_entrant_update_feat_condition_event(ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(ret[0],ret[1],ret[2],ret[3])
    end

    # 技の発動条件を更新 FOE
    def foe_entrant_update_feat_condition_event_handler(target, ret)
      sc_entrant_update_feat_condition_event(!ret[0], ret[1], ret[2], ret[3])
      set_cache_act_command(!ret[0],ret[1],ret[2],ret[3])
    end

    # ヌイグルミセット 自分側
    def pl_entrant_stuffed_toys_set_event_handler(target, ret)
      sc_entrant_stuffed_toys_set_event(ret[0],ret[1])
      set_cache_act_command(ret[0],ret[1])
    end

    # ヌイグルミセット 敵側
    def foe_entrant_stuffed_toys_set_event_handler(target, ret)
      sc_entrant_stuffed_toys_set_event(!ret[0],ret[1])
      set_cache_act_command(!ret[0],ret[1])
    end

    # 必殺技が実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_feat_event_handler(target,ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [CC pl Feat use  id:#{ret}")
      sc_entrant_use_feat_event(true, ret)
      set_cache_act_command(ret)
    end

    # パッシブスキル発動時のプレイヤー側ハンドラ
    def pl_entrant_on_passive_event_handler(target,ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [#{__method__}] #{ret}")
      sc_entrant_on_passive_event(true,ret[1])
      set_cache_act_command(true,ret[1])
    end
    # パッシブスキル発動時の敵側ハンドラ
    def foe_entrant_on_passive_event_handler(target,ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [#{__method__}] #{ret}")
      sc_entrant_on_passive_event(false,ret[1])
      set_cache_act_command(false,ret[1])
    end
    # パッシブスキル終了時のプレイヤー側ハンドラ
    def pl_entrant_off_passive_event_handler(target,ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [#{__method__}] #{ret}")
      sc_entrant_off_passive_event(true,ret[1])
      set_cache_act_command(true,ret[1])
    end
    # パッシブスキル終了時の敵側ハンドラ
    def foe_entrant_off_passive_event_handler(target,ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [#{__method__}] #{ret}")
      sc_entrant_off_passive_event(false,ret[1])
      set_cache_act_command(false,ret[1])
    end

    # =====================
    # RewardEvent
    # =====================
    # 報酬イベントのハンドラ
    # アイテムを使用した
    def item_use_event_handler(target, ret)
      sc_use_item(ret)
    end

    def item_get_event_handler(target, ret)
      sc_get_item(ret[0], ret[1])
    end

    def slot_card_get_event_handler(target, ret)
      sc_get_slot_card(ret[0], ret[1], ret[2])
    end

    # 候補カードのリストを送る
    def candidate_cards_list_phase_handler(target, ret)
      if ret
        ret_a = ret[0][0].join(",")
        ret_b = (ret[0][1] ? ret[0][1].join(","):"")
        ret_c = (ret[0][2] ? ret[0][2].join(","):"")
        ret_d = (ret[0][3] ? ret[0][3].join(","):"")
        sc_reward_candidate_cards_list(ret_a, ret_b, ret_c, ret_d, ret[1])
      end
    end

    # 基本ダイスの結果を送る
    def bottom_dice_num_phase_handler(target, ret)
      if ret
        sc_bottom_dice_num(ret.join(","))
      end
    end

    # ハイローフェイズの結果ハンドラ
    def high_low_phase_handler(target, ret)
      if ret&&ret[3]
        get_card = ret[1] ? ret[1].join(","):""
        next_card =ret[2] ? ret[2].join(","):""
        sc_high_low_result(ret[0], get_card, next_card, ret[3])
      end
    end

    # 報酬ゲームの終了
    def reward_finish_handler(target,ret)
      r = target.final_result
      if r[1]
        get_card =  r[1].join(",")
        sc_chara_card_inventory_info(r[4].join(","), get_card)
      else
        get_card = ""
      end
      sc_reward_final_result(get_card,target.total_gems,target.total_exp,target.add_point)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [duel_high_low_finish] reward_type:#{r[1][0]} reward_id:#{r[1][1]} reward_value:#{r[1][2]} step_num:#{r[3]} inv_id:#{r[4]}")
      @reward = nil
    end

    # 結果ダイスのハンドラ
    def reward_result_dice_event_handler(target,ret)
      sc_reward_result_dice(ret.join(","))
    end

    # ==========
    # 内部用関数
    # ==========
    def set_cache_act_command( *args )
      if @watch_duel
        method = nil
        if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller.first
          method = $3
        end
        @watch_duel.set_cache_act_command(args,method)
      end
    end

    def set_message_str_data(msgId,*args)
      args = [] unless args
      sc_message_str_data("#{msgId}:#{args.join(",")}")
    end

  end

end
