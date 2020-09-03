# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'controller/duel_controller'
module Unlight

  module QuestController
  include Unlight::DuelController

      # ======================================
      # 受信コマンド
      # =====================================

      # データの更新を調べる
      def cs_avatar_update_check
        @avatar.update_check if @avatar
      end

      # クエストをマップから取得する
      def cs_get_quest(quest_map_id, time)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [cs_get_quest] #{quest_map_id} time:#{time}");
        if @player
        ret =0
          ret = @player.current_avatar.get_quest(quest_map_id, time)
          if ret>0
            sc_error_no(ret)
          end
        end
      end

      # 指定地域のクエストマップを要求
      def cs_request_quest_map_info(region)
        list = QuestMap.get_quest_map_list(region)
        if list.size > 0
          sc_quest_map_info(region, list.join(","))
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_map_info] #{list.join(",")}")
        end
      end


      # アイテムを使用する
      def cs_avatar_use_item(inv_id,quest_map_no)
        # バトル中は使用できなくすべきか
        if @avatar
          e = @avatar.use_item(inv_id,quest_map_no)
          @reward.update if @reward&&(@reward.finished == false)
          if e >0
            sc_error_no(e)
          else
            it = ItemInventory[inv_id]
            SERVER_LOG.info("<UID:#{@uid}>QuestServer: [avatar_use_item] use_item_id:#{it.avatar_item_id}");
          end
        end
      end

      # アイテムを購入する
      def cs_avatar_buy_item(shop,inv_id)
        @avatar.buy_item(shop, inv_id) if @avatar
      end

      # 特定ページのログ情報を要求
      def cs_get_quest_log_page_info(page)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [cs_get_quest_log_page_info] #{page}")
        sc_quest_log_page_info(page, @avatar.get_quest_log(page)) if @avatar
      end

      # 特定ログを要求
      def cs_get_quest_log_info(id)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [cs_get_quest_log_info] #{id}")
        # 存在しない要求の場合空の内容を返す
        if QuestLog[id]
          sc_quest_log_info(id, QuestLog[id].to_text)
        else
          sc_quest_log_info(id, "")
        end
      end

      # ログを書き込む
      def cs_set_quest_log_info(content)
        id =  @avatar.write_log(content) if @avatar
        sc_quest_log_info(id, QuestLog[id].to_text) if id||id!=0
      end

      # クエストを確認した
      def cs_quest_confirm(id, deckIndex)
        current_inv = AvatarQuestInventory[id]
        # もしNEW状態だったらStateをアップデートする
        @avatar.update_quest_state(current_inv, QS_UNSOLVE, deckIndex) if @avatar&&current_inv
      end

      # クエストが見つかったかをチェック
      def cs_quest_check_find(id)
        # クエストがどうなったかチェック
        @avatar.check_find_quest(id) if @avatar
      end

      # クエストをスタートした
      def cs_quest_start(id, deck_index)
        # もしNEW状態だったらStateをアップデートする
        ret =0
        ret = @avatar.quest_start(id, deck_index) if @avatar

        if ret >0
          if ret == ERROR_QUEST_INV_IS_NONE
            sc_quest_deleted(id)
          end
          sc_error_no(ret)
          SERVER_LOG.error("<UID:#{@uid}>QuestServer: [cs_quest_start] faild, #{id}")
        else
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [quest_use_cards] quest_id#{id},use_cards_id#{@avatar.duel_deck.cards_id(true)}") if @avatar
        end
      end

      # クエストを進行させた
      def cs_quest_next_land(id, deck_index,next_no)
        if @duel
          SERVER_LOG.warn("<UID:#{@uid}>QuestServer: [quest_next_land] FAIL!! @duel is not null!! , #{next_no}")
          return
        end
        ret =ERROR_AP_LACK
        current_inv = AvatarQuestInventory[id]
        if @avatar&&current_inv
          ret = @avatar.next_land(current_inv, deck_index, @current_no, next_no)
          # 空のデッキで対戦しようとしてないかチェック
          ret =ERROR_NOT_EXIST_CHARA  if @avatar.chara_card_decks[deck_index].cards.size <1||@avatar.chara_card_decks[deck_index].cards[0]==nil
        else
          SERVER_LOG.warn("<UID:#{@uid}>QuestServer: [quest_next_land] FAIL!! @avatar is null!! , #{next_no}")
          return
        end
        if ret >0
          # 存在しなかったらクライアントに削除を送る
          if ret == ERROR_QUEST_INV_IS_NONE
            sc_quest_deleted(id)
          else
            sc_error_no(ret)
          end
        else
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [quest_next_land] succsess. inv_id:#{id},next_no:#{next_no}, #{@avatar.get_treasure_bonus_level(current_inv, next_no)}")
          sc_next_success(next_no)
          # 戦闘番号を引いてきて戦闘を起こす
          enemy = @avatar.get_land_enemy(id, next_no)
          @current_no = next_no
          @current_inv_id = id
          @current_deck_index = deck_index

          ai_chara_card_deck = AI.chara_card_deck(enemy, @player)
          if enemy !=0 && ai_chara_card_deck.card_inventories.length>0
            cpu_card_data = CpuCardData[enemy]
            ai_rank = CPU_AI_OLD
            if cpu_card_data && cpu_card_data.ai_rank
              ai_rank = cpu_card_data.ai_rank
            end

            # By_K2 (무한의탑 층수만큼 몬스터 POWER 증가 / 기준 11층 / 10층 이하일경우는 약화)
            hp_up = 0
            ap_up = 0
            dp_up = 0
            now_map_id = current_inv.quest.quest_map_id

            if now_map_id == QM_EV_INFINITE_TOWER
                hp_up = (@avatar.floor_count_check - 1) - 10;
                ap_up = (@avatar.floor_count_check / 5) - 2;
                dp_up = (@avatar.floor_count_check / 5) - 2;
            end

            # 報酬のためにLand番号を覚えておく
            @duel = MultiDuel.new(@player.current_avatar,
                                  AI,
                                  @avatar.chara_card_decks[deck_index],
                                  ai_chara_card_deck,
                                  RULE_3VS3,
                                  0,
                                  :quest_ai,
                                  @avatar.get_land_stage(current_inv, next_no),
                                  @avatar.get_damage_set(current_inv),
                                  [0,0,0],
                                  @avatar.get_treasure_bonus_level(current_inv, next_no),
                                  0,
                                  BATTLE_TIMEOUT_TURN,
                                  ai_rank,
                                  hp_up.to_i,       # By_K2
                                  ap_up.to_i,       # By_K2
                                  dp_up.to_i        # By_K2
                                  )

            do_determine_session(id,
                                 "CPU",
                                 @avatar.chara_card_decks[deck_index].cards_id.join(","),
                                 ai_chara_card_deck.cards_id.join(","),
                                  @avatar.get_land_stage(current_inv, next_no),
                                  @avatar.get_damage_set(current_inv),
                                 )

            set_duel_handler(0, RULE_3VS3)
            # 1の対戦の時はクライアントのキャラチェンジボタンを消す
            if @avatar.chara_card_decks[deck_index].card_inventories.size==1&&ai_chara_card_deck.card_inventories.length==0
              sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, @duel.entrants[@no].distance, false)
            else
              sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, @duel.entrants[@no].distance, true)
            end
            @duel.three_to_three_duel
          else

            # 敵がいないならそのまま進行OKにする
            @avatar.land_clear(current_inv, next_no) if @avatar
            # この地域が最後ならば勝利を送ってクエストを終了
            error_no = @avatar.check_end_position?(current_inv, next_no)
            if error_no == 0
              @avatar.quest_all_clear(current_inv, @current_deck_index,@current_no, true, RESULT_WIN);
              # 勝ちのデータをおくる
              sc_quest_finish(RESULT_WIN,@current_inv_id)
              reset_current_param
            elsif error_no==1
              SERVER_LOG.info("<UID:#{@uid}>QuestServer: [quest win] challenge_next")
            elsif error_no>1
              SERVER_LOG.info("<UID:#{@uid}>QuestServer: [quest error] no #{error_no}")
              if error_no == ERROR_QUEST_INV_IS_NONE
                sc_quest_deleted(@current_inv_id)
              end
              sc_error_no(error_no)
            end
          end
        end
      end

      # クエストを中止した
      def cs_quest_abort(id, deck_index)
        # もしNEW状態だったらStateをアップデートする
        current_inv = AvatarQuestInventory[id]
        if @avatar&&current_inv
          @avatar.quest_all_clear(current_inv, deck_index, @current_no, false, RESULT_DELETE);
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [quest abort] #{@current_no}, #{id}")
          sc_quest_finish(RESULT_LOSE,id)
        end
      end


    # ゲームセッションの決定
    def do_determine_session(id, name,player_chara_id,foe_chara_id, stage, alpha_damege_set, beta_damege_set=[0,0,0])
      current_inv = AvatarQuestInventory[id]

      pl_dialogue_content = ""
      foe_dialogue_content = ""
      if current_inv
        map_id = current_inv.quest.quest_map_id
        land_id = current_inv.quest.get_land_id(@current_no)

        pl_id = CharaCard[player_chara_id.split(",")[0]].parent_id
        foe_id = CharaCard[foe_chara_id.split(",").last].parent_id
        pl_dialogue_content = DialogueWeight::quest_start_dialogue(pl_id, foe_id, map_id, land_id)
        foe_dialogue_content = DialogueWeight::quest_start_dialogue(foe_id, pl_id, map_id, land_id)
      end

      sc_determine_session(-1,
                           name,
                           player_chara_id,
                           foe_chara_id,
                           pl_dialogue_content,
                           foe_dialogue_content,
                           stage,
                           alpha_damege_set[0],
                           alpha_damege_set[1],
                           alpha_damege_set[2],
                           beta_damege_set[0],
                           beta_damege_set[1],
                           beta_damege_set[2]
                           )

    end

    # クエストを消去
    def cs_quest_delete(id)
      current_inv = AvatarQuestInventory[id]
      @avatar.quest_all_clear(current_inv,@current_deck_index||0,@current_no, false, RESULT_DELETE) if @avatar&&current_inv
    end

    # クエストを送る
    def cs_send_quest(a_id, inv_id)
      if @avatar
        e = @avatar.send_quest(a_id, inv_id)
        if e >0
          sc_error_no(e)
        end
      end
    end


      # ======================================
      # 送信コマンド
      # =====================================

      # アバターにイベントを登録
      def regist_avatar_event
        if @avatar
        @avatar.init
        @avatar.add_finish_listener_use_energy_event(method(:use_energy_event_handler))
        @avatar.add_finish_listener_update_energy_max_event(method(:update_energy_max_event_handler))
        @avatar.add_finish_listener_quest_get_event(method(:get_quest_event_handler))
        @avatar.add_finish_listener_get_exp_event(method(:get_exp_event_handler))
        @avatar.add_finish_listener_level_up_event(method(:level_up_event_handler))
        @avatar.add_finish_listener_update_gems_event(method(:update_gems_event_handler))
        @avatar.add_finish_listener_item_get_event(method(:item_get_event_handler))
        @avatar.add_finish_listener_item_use_event(method(:item_use_event_handler))
        @avatar.add_finish_listener_quest_state_update_event(method(:quest_state_update_handler))
        @avatar.add_finish_listener_quest_progress_update_event(method(:quest_progress_update_handler))
        @avatar.add_finish_listener_quest_deleted_event(method(:quest_deleted_handler))
        @avatar.add_finish_listener_quest_deck_state_update_event(method(:quest_deck_state_update_handler))
        @avatar.add_finish_listener_quest_flag_update_event(method(:quest_flag_update_event_handler))

        @avatar.add_finish_listener_floor_count_update_event(method(:floor_count_update_event_handler))     # By_K2

        @avatar.add_finish_listener_quest_clear_num_update_event(method(:quest_clear_num_update_event_handler))

        @avatar.add_finish_listener_event_quest_clear_num_update_event(method(:event_quest_clear_num_update_event_handler))
        @avatar.add_finish_listener_event_quest_flag_update_event(method(:event_quest_flag_update_event_handler))

        @avatar.add_finish_listener_quest_find_at_update_event(method(:quest_find_at_update_event_handler))
        @avatar.add_finish_listener_get_quest_treasure_event(method(:get_quest_treasure_handler))
        @avatar.add_finish_listener_slot_card_get_event(method(:slot_card_get_event_handler))
        @avatar.add_finish_listener_chara_card_get_event(method(:chara_card_get_event_handler))
        @avatar.add_finish_listener_part_get_event(method(:part_get_event_handler))

        @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
        @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
        @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))
        @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))

        @avatar.add_finish_listener_update_combine_weapon_data_event(method(:update_combine_weapon_data_event_handler))
        end

      end

      # 行動力を使用する
      def use_energy_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_use_energy] #{ret}")
        sc_energy_info(ret[0],ret[1])
      end

      # 行動力のMAXが更新
      def update_energy_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_update_energy_max] #{ret}")
        sc_update_energy_max(ret[0])
      end

      # クエストを取得した
      def get_quest_event_handler(target, ret)
        if ret
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_quest] invID:#{ret[0]} questID:#{ret[1]} before avatar name:#{ret[5]}")
          sc_get_quest(ret[0], ret[1], ret[2], ret[3], ret[4], ret[5])
        else
          SERVER_LOG.fatal("<UID:#{@uid}>QuestServer: [sc_get_quest] FATAL ret is nil")
        end
      end

      # クエストの進行度の更新
      def quest_flag_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_flag_update] #{ret}")
        sc_quest_flag_update(ret)
      end

      # By_K2 (무한의탑 층수 UP)
      def floor_count_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_floor_count_update] #{ret}")
        sc_floor_count_update(ret)
      end

      # クエスト達成度の更新
      def quest_clear_num_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_clear_num_update] #{ret}")
        sc_quest_clear_num_update(ret)
      end
      # クエストの探索時間の更新
      def quest_find_at_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_find_at_update] #{ret}")
        sc_quest_find_at_update(ret[0], ret[1])
      end

      # イベントクエスト達成度の更新
      def event_quest_clear_num_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_event_quest_clear_num_update] #{ret}")
        sc_event_quest_clear_num_update(*ret)
      end
      # イベントクエストの進行度の更新
      def event_quest_flag_update_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_event_quest_flag_update] #{ret}")
        sc_event_quest_flag_update(*ret)
      end

      # 経験値獲得
      def get_exp_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_exp] #{ret}")
        sc_get_exp(ret)
      end

      # レベルアップ
      def level_up_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_level_up] #{ret}")
        sc_level_up(ret)
      end

      # Gemの更新
      def update_gems_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_update_gems] #{ret}")
        sc_update_gems(ret)
      end

      # アイテムゲット
      def item_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_item] invID:#{ret[0]} itemID:#{ret[1]}")
        sc_get_item(ret[0], ret[1])
      end

      # パーツゲット
      def part_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_part_item] invID:#{ret[0]} itemID:#{ret[1]}")
        sc_get_part(ret[0], ret[1])
      end

      # スロットカードを取得する
      def slot_card_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_slot_card] invID:#{ret[0]} type:#{ret[1]} cardID:#{ret[2]}")
        sc_get_slot_card(ret[0], ret[1], ret[2])
      end

      # キャラカードを取得する
      def chara_card_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_chara_card] invID:#{ret[0]} cardID:#{ret[1]}")
        sc_get_chara_card(ret[0], ret[1])
      end

      # アイテムを使用した
      def item_use_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_use_item] #{ret}")
        sc_use_item(ret)
      end

      # クエストの状態が更新された
      def quest_state_update_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_state_update] #{ret}")
        sc_quest_state_update(ret[0],ret[1] , ret[2])
      end

      # 行動力のMAXが更新
      def update_quest_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_update_quest_max] #{ret}")
        sc_update_quest_max(ret)
      end

      # クエスト宝箱をゲット
      def get_quest_treasure_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_get_quest_treasure] #{ret}")
        sc_get_quest_treasure(*ret)
      end


      # クエストデッキの状態が更新された
      def quest_deck_state_update_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_deck_state_update] #{ret}")
        sc_deck_state_update(ret[0],ret[1],ret[2],ret[3],ret[4] )
      end

      # クエストの進行状況が更新された
      def quest_progress_update_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_map progress_update] #{ret}")
        sc_quest_map_progress_update(ret[0],ret[1] )
      end

      # クエストが消去された
      def quest_deleted_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_quest_deleted] #{ret}")
        sc_quest_deleted(ret)
      end

      # アチーブメントがクリアされた
      def achievement_clear_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_achievement_clear] #{ret}")
        sc_achievement_clear(*ret)
      end

      # アチーブメントが追加された
      def add_new_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_add_new_achievement] ID: #{ret}")
        sc_add_new_achievement(ret)
      end

      # アチーブメントが追加された
      def delete_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_delete_achievement] ID: #{ret}")
        sc_delete_achievement(ret)
      end

      # アチーブメントが更新された
      def update_achievement_info_event_handler(target,ret)
        sc_update_achievement_info(ret[0],ret[1],ret[2],ret[3],ret[4])
      end

      # 合成武器情報を更新する
      def update_combine_weapon_data_event_handler(target,ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]  #{ret}")
        sc_update_combine_weapon_data(*ret)
      end

      # ======================================
      # 送信コマンド
      # =====================================
      # 押し出し関数
      def pushout()
        online_list[@player.id].player.logout(true)
        online_list[@player.id].logout
      end

      # ログイン時の処理
      def do_login
        if @player.avatars.size > 0
          @avatar = @player.avatars[0]
          reset_current_param
          regist_avatar_event
          sc_actioncard_length(ActionCard.dataset.count)
          @avatar.resend_quest_inventory
        end
      end

      def reset_current_param
        @current_inv_id = 0
        @current_no = nil
        @current_deck_index = nil
      end

      # ログアウト時の処理
      def do_logout
        # クエストの状態を初期状態にする
        if @avatar
          @avatar.remove_all_event_listener
          @avatar.remove_all_hook
          @avatar = nil
        end
        delete_connection
        if @duel
          SERVER_LOG.info("<UID:#{@uid}>QuestServer: [Duel.destruct]")
          @duel.entrants[@no].exit_game
          @duel.entrants[1].exit_game
          @duel.exit_game
          sc_error_no(ERROR_GAME_QUIT)
          @opponent_player.opponent_duel_out if @opponent_player
          @duel = nil
        end

      end

    # 終了時のハンドラ
      # 返値は[alpha, beta, reward]
      def duel_finish_handler(duel, ret)
        @duel = nil
        current_inv = AvatarQuestInventory[@current_inv_id]
        # 結果を送る
        if @avatar&&current_inv
          bonus_on = false
          # 宝箱を調べる
          tr =  @avatar.get_land_treasure(current_inv, @current_no)
          # 宝箱があってかつ中身がボーナスならばボーナスか？
          bonus_on = false
          bonus_on = (Unlight::TreasureData[tr].treasure_type == TG_BONUS_GAME) if tr&&Unlight::TreasureData[tr]

          # ボーナスゲームありならば？
          if bonus_on
            # もしプレイヤーが勝利していた場合報酬へのハンドラを作る
            @reward = duel.result[@no][:reward]
            if @reward&&@player
              # アバターに報酬ゲームを登録
              @avatar.set_reward(@reward)
              @avatar.refresh
              tmp_exp = duel.result[@no][:exp] * (@avatar.exp_pow*0.01)
              tmp_gems = duel.result[@no][:gems] * (@avatar.gem_pow*0.01)
              sc_one_to_one_duel_finish(duel.result[@no][:result],
                                        duel.result[@no][:gems],
                                        duel.entrants[@no].base_exp,
                                        duel.entrants[@no].exp_bonus,
                                        @avatar.gem_pow,
                                        @avatar.exp_pow,
                                        tmp_gems.truncate,
                                        tmp_exp.truncate,
                                        true)
              @avatar.set_exp(tmp_exp)
              @avatar.set_duel_deck_exp(tmp_exp)
              @avatar.set_gems(tmp_gems)
              @reward.send_result_to_avatar(tmp_gems, tmp_exp)

              # レベルが制限を越えた場合、失敗判定に変更
              @avatar.failed_achievement(EVENT_DUEL_05) if @avatar.level > LOW_AVATAR_DUEL_RECORD_LV

              # 報酬ゲームにハンドラ登録
              @reward.add_finish_listener_candidate_cards_list_phase(method(:candidate_cards_list_phase_handler))
              @reward.add_finish_listener_bottom_dice_num_phase(method(:bottom_dice_num_phase_handler))
              @reward.add_finish_listener_high_low_phase(method(:high_low_phase_handler))
              # 結果ダイスのハンドラ
              @reward.add_finish_listener_result_dice_event(method(:reward_result_dice_event_handler))
              # 最終結果のハンドラ
              @reward.add_finish_listener_reward_event(method(:reward_finish_handler))

              # 報酬ゲームのスタート
              @reward.reward_event

            end
          else

            @avatar.refresh
            tmp_exp = duel.result[@no][:exp]*(@avatar.exp_pow*0.01)
            tmp_gems = duel.result[@no][:gems]*(@avatar.gem_pow*0.01)
            sc_one_to_one_duel_finish(duel.result[@no][:result],
                                      duel.result[@no][:gems],
                                      duel.entrants[@no].base_exp,
                                      duel.entrants[@no].exp_bonus,
                                      @avatar.gem_pow,
                                      @avatar.exp_pow,
                                      tmp_gems.truncate,
                                      tmp_exp.truncate,
                                      false)

            # By_K2 (무한의탑 층수+1)
            if duel.result[@no][:result] == RESULT_WIN
                now_map_id = current_inv.quest.quest_map_id
                if now_map_id == QM_EV_INFINITE_TOWER
                    @avatar.floor_count_up
                end
            end

            # 経験値等をおくる
            @avatar.set_exp(tmp_exp)
            @avatar.set_duel_deck_exp(tmp_exp)
            @avatar.set_gems(tmp_gems)

            # レベルが制限を越えた場合、失敗判定に変更
            @avatar.failed_achievement(EVENT_DUEL_05) if @avatar.level > LOW_AVATAR_DUEL_RECORD_LV
          end

          # デュエルを削除する
          duel.entrants[@no].exit_game
          # CPUもexitして置かないとゲームのイベントが外れないので。。
          duel.entrants[1].exit_game
          duel.exit_game

          # 勝ったならばクリア
          if duel.result[@no][:result]==RESULT_WIN
            @avatar.land_clear(current_inv, @current_no) if @avatar
            SERVER_LOG.info("<UID:#{@uid}>QuestServer: [duel land clear] #{@current_no}")
            @avatar.set_damage_set(current_inv, duel.result[@no][:damage])
            # この地域が最後ならば勝利を送ってクエストを終了
            error_no = @avatar.check_end_position?(current_inv, @current_no)

            if error_no == 0
             SERVER_LOG.info("<UID:#{@uid}>QuestServer: [duel finish quest win] #{@current_no}, #{@current_inv_id}")
              @avatar.quest_all_clear(current_inv,@current_deck_index,@current_no, true, duel.result[@no][:result]);
              # 勝ちのデータをおくる
              sc_quest_finish(RESULT_WIN,@current_inv_id)
              SERVER_LOG.info("<UID:#{@uid}>QuestServer: [duel finish quest win] #{current_inv.quest.kind == QT_BOSS}, #{current_inv.quest.kind },#{QT_BOSS}")

              if current_inv.quest.story_no != 0 # もし倒したのがストーリー番号を持っていたらダイアログ情報をわたす
                SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_dialogue_info_update] chara:#{@avatar.chara_card_decks[@current_deck_index].cards.first.charactor_id},map_no#{current_inv.quest.story_no}")
                d_set = DialogueWeight::quest_clear_dialogue(@avatar.chara_card_decks[@current_deck_index].cards.first.parent_id, current_inv.quest.story_no)
                d_set.each do |d|
                  SERVER_LOG.info("<UID:#{@uid}>QuestServer: [sc_dialogue_info_update] #{d}")
                  sc_dialogue_info_update(d[0],d[1],d[2])
                end
              end
              reset_current_param
            elsif error_no == 1
              SERVER_LOG.warn("<UID:#{@uid}>QuestServer: [win next ok] #{error_no}")
            elsif error_no >1
              if error_no == ERROR_QUEST_INV_IS_NONE
                sc_quest_deleted(@current_inv_id)
              end
              SERVER_LOG.error("<UID:#{@uid}>QuestServer: [duel finish quest win. But error] #{error_no}, no:#{@current_no}, inv_id:#{@current_inv_id}")
              sc_error_no(error_no)
            end
          else
            SERVER_LOG.info("<UID:#{@uid}>QuestServer: [duel lose quest failed] #{@current_no}")
            @avatar.quest_all_clear(current_inv,@current_deck_index, @current_no, false, duel.result[@no][:result]);
            # 負け、引き分けの場合はクエストは終了
            sc_quest_finish(RESULT_LOSE,@current_inv_id)
            reset_current_param
          end
        end
    end
  end
end
