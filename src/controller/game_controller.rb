# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'controller/duel_controller'

module Unlight
  module GameController
    include Unlight::DuelController

    # ======================================
    # 受信コマンド
    # =====================================

    def cs_match_start(match_uid)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [cs_match_start] #{match_uid}");
      @match_log = MatchLog::get_cache(match_uid)

      if  @player&&@match_log&&@duel == nil
        @opponent_player = online_list[@match_log.b_avatar.player_id]
        if @opponent_player
          @opponent_player.oppnent_event_destructor
          @opponent_player.opponent_player = self
          @opponent_player.match_log = @match_log
          # 相手にwatch_duelがあったら初期化
          if @opponent_player.watch_duel
            @opponent_player.watch_duel.clear_duel_data
            @opponent_player.watch_duel.all_clear_add_command
            @opponent_player.watch_duel = nil
          end
        else
          sc_error_no(ERROR_DUEL_OPPONENT_LOGOUT)
          return
        end

        if @opponent_player.player.last_ip == @player.last_ip
          @opponent_player.player.same_ip_check
          @player.same_ip_check
          @match_log.warn_same_ip
          SERVER_LOG.info("<UID:#{@uid}>GameServer: [warn] same IP");
        end

        if @match_log.cpu_card_data_id == PLAYER_MATCH
          if @match_log.match_rule == RULE_1VS1

            # カレントのアバターが持つカレントカードでデュエル開始
            @duel = MultiDuel.new(@player.current_avatar, @opponent_player.player.current_avatar, @player.current_avatar.duel_deck, @opponent_player.player.current_avatar.duel_deck,@match_log.match_rule,@match_log.get_bp, :none, @match_log.match_stage)
            @opponent_player.duel = @duel
            do_determine_session(@opponent_player.player.id, @opponent_player.player.current_avatar.name, @player.current_avatar.duel_deck_cards_id_str, @opponent_player.player.current_avatar.duel_deck_mask_cards_id_str)
            @opponent_player.do_determine_session(@player.id,@player.current_avatar.name, @opponent_player.player.current_avatar.duel_deck_cards_id_str, @player.current_avatar.duel_deck_mask_cards_id_str)
            set_duel_handler(0, RULE_1VS1)
            @opponent_player.set_duel_handler(1, RULE_1VS1)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, @duel.entrants[@no].distance, false)
            @opponent_player.sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@foe].size,@duel.event_decks[@no].size,@duel.entrants[@foe].distance, false)
            @match_log.start_match()
            @duel.three_to_three_duel
          elsif @match_log.match_rule == RULE_3VS3
            # カレントのアバターが持つカレントデッキでデュエル開始
            @duel = MultiDuel.new(@player.current_avatar, @opponent_player.player.current_avatar, @player.current_avatar.duel_deck, @opponent_player.player.current_avatar.duel_deck, @match_log.match_rule, @match_log.get_bp, :none, @match_log.match_stage)
            @opponent_player.duel = @duel
            do_determine_session(@opponent_player.player.id,@opponent_player.player.current_avatar.name, @player.current_avatar.duel_deck.cards_id.join(","), @opponent_player.player.current_avatar.duel_deck.mask_cards_id.join(","))
            @opponent_player.do_determine_session(@player.id,@player.current_avatar.name, @opponent_player.player.current_avatar.duel_deck.cards_id.join(","), @player.current_avatar.duel_deck.mask_cards_id.join(","))
            set_duel_handler(0, RULE_3VS3)
            @opponent_player.set_duel_handler(1, RULE_3VS3)
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size, @duel.event_decks[@foe].size, @duel.entrants[@no].distance, true)
            @opponent_player.sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@foe].size, @duel.event_decks[@no].size, @duel.entrants[@foe].distance, true)
            @match_log.start_match()
            @duel.three_to_three_duel
          end
        else
          # CPUルールで開始する
          if @match_log.match_rule == RULE_1VS1
            # カレントのアバターが持つカレントカードでデュエル開始
            @duel = MultiDuel.new(AI, @opponent_player.player.current_avatar, AI.chara_card_deck(@match_log.cpu_card_data_id), @opponent_player.player.current_avatar.duel_deck,@match_log.match_rule, 0, :duel_ai, @match_log.match_stage, [0,0,0],[0,0,0],0,@match_log.cpu_card_data_id)
            @opponent_player.duel = @duel
            @opponent_player.do_determine_session(AI_PLAYER_ID, "CPU", @opponent_player.player.current_avatar.duel_deck_cards_id_str, AI.chara_card_deck(@match_log.cpu_card_data_id).mask_cards_id.join(","))
            @opponent_player.set_duel_handler(1, RULE_1VS1)
            @opponent_player.sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@foe].size,@duel.event_decks[@no].size,@duel.entrants[@foe].distance, false)
            @match_log.start_match()
            @duel.three_to_three_duel
          elsif @match_log.match_rule == RULE_3VS3

            # カレントのアバターが持つカレントデッキでデュエル開始
            @duel = MultiDuel.new(AI, @opponent_player.player.current_avatar, AI.chara_card_deck(@match_log.cpu_card_data_id), @opponent_player.player.current_avatar.duel_deck, @match_log.match_rule, 0, :duel_ai, @match_log.match_stage, [0,0,0],[0,0,0],0,@match_log.cpu_card_data_id)
            @opponent_player.duel = @duel
            @opponent_player.do_determine_session(AI_PLAYER_ID, "CPU", @opponent_player.player.current_avatar.duel_deck.cards_id.join(","), AI.chara_card_deck(@match_log.cpu_card_data_id).mask_cards_id.join(","))
            @opponent_player.set_duel_handler(1, RULE_3VS3)
            @opponent_player.sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@foe].size, @duel.event_decks[@no].size, @duel.entrants[@foe].distance, true) if @duel&&@foe
            @match_log.start_match()
            @duel.three_to_three_duel
          end
        end

        # 観戦用データをキャッシュに保存
        @watch_duel = WatchDuel.new(match_uid,false,@player.id,@opponent_player.player.id) if WATCH_MODE_ON && @match_log.watch_mode == DUEL_WATCH_MODE_ON

        # 使用デッキをログに書き出し
        player_deck_cards = @player.current_avatar.duel_deck.cards_id(true)
        opponent_player_deck_cards = @opponent_player.player.current_avatar.duel_deck.cards_id(true)
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [duel_use_deck_cards] player_cards#{player_deck_cards},opponent_player_cards#{opponent_player_deck_cards}");
      end
    end

    # アクションカードのデータのリクエスト
    def cs_request_actioncard_info(id)
      a = ActionCard[id]||ActionCard[1]
      sc_actioncard_info(a.id, a.u_type, a.u_value, a.b_type, a.b_value, a.event_no, a.image||"", a.caption||"", a.version||0)
    end

    # アクションカードのバージョンデータのリクエスト
    def cs_request_actioncard_ver_info(id)
      a = ActionCard[id]||ActionCard[1]
      sc_actioncard_info(a.id, a.version||0)
    end

    # アチーブメントがクリアされた
    def achievement_clear_event_handler(target, ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [sc_achievement_clear] #{ret}")
      sc_achievement_clear(*ret)
    end

    # アチーブメントが追加された
    def add_new_achievement_event_handler(target, ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [sc_add_new_achievement] ID: #{ret}")
      sc_add_new_achievement(ret)
    end

    # アチーブメントが追加された
    def delete_achievement_event_handler(target, ret)
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [sc_delete_achievement] ID: #{ret}")
      sc_delete_achievement(ret)
    end

    # アチーブメントが更新された
    def update_achievement_info_event_handler(target,ret)
      sc_update_achievement_info(ret[0],ret[1],ret[2],ret[3],ret[4])
    end

    # アチーブメントを完全削除
    def drop_achievement_event_handler(target, ret)
      SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_drop_achievement] ID: #{ret}")
      sc_drop_achievement(ret)
    end

    # 終了時のハンドラ
    # 返値は[alpha, beta, reward]
    def duel_finish_handler(duel, ret)
      opponent_player = @opponent_player
      @duel = nil
      @opponent_player = nil

      # もしプレイヤーが勝利していた場合報酬へのハンドラを作る
      @reward = duel.result[@no][:reward]
      if @reward&&@player
        @avatar.refresh

        tmp_exp = duel.result[@no][:exp] * @avatar.exp_pow*0.01
        tmp_gems = duel.result[@no][:gems] * @avatar.gem_pow*0.01

        # 結果を送る
        sc_one_to_one_duel_finish(duel.result[@no][:result],
                                  duel.result[@no][:gems],
                                  duel.entrants[@no].base_exp,
                                  duel.entrants[@no].exp_bonus,
                                  @avatar.gem_pow,
                                  @avatar.exp_pow,
                                  tmp_gems.truncate,
                                  tmp_exp.truncate,
                                  true)
        use_ap = DUEL_AP[duel.rule]
        use_ap = @match_log.match_option == DUEL_OPTION_FRIEND ? FRIEND_DUEL_AP[duel.rule] : DUEL_AP[duel.rule]if @match_log
        # ラダーマッチの時のAP消費量
        use_ap = RADDER_DUEL_AP[duel.rule] if duel.is_get_bp ==1 || @match_log.cpu_card_data_id != PLAYER_MATCH if @match_log

        is_free_count = @player.current_avatar.duel_energy_use(use_ap)
        # フリーデュエルポイントを使用している場合、人気投票にポイント加算
        @avatar.achievement_check(EVENT_CHARA_VOTE_RECORD_IDS,nil,@avatar.duel_deck.current_chara_cost) if is_free_count
        # アバターに報酬ゲームを登録
        @avatar.set_reward(@reward, duel.is_get_bp, @match_log.channel_set_rule)

        # radder_matchの時のみ、BPの更新
        # イベントデュエルに勝利したときのレコード用処理
        @avatar.set_special_result(duel.result[@no][:result]) if @match_log && @match_log.cpu_card_data_id != 0

        prev_level = @avatar.level

        @avatar.set_exp(tmp_exp)
        @avatar.set_duel_deck_exp(tmp_exp, duel.is_get_bp)
        @avatar.set_gems(tmp_gems)

        # 低レベルアバターとデュエル
        if @match_log && @match_log.cpu_card_data_id == PLAYER_MATCH
          if opponent_player && opponent_player.player && opponent_player.player.current_avatar && opponent_player.player.current_avatar.level <= LOW_AVATAR_DUEL_RECORD_LV
            @avatar.achievement_check(EVENT_DUEL_04)
          end
        end
        # 低レベルアバターがデュエル
        if prev_level <= LOW_AVATAR_DUEL_RECORD_LV
          if @match_log && @match_log.cpu_card_data_id == PLAYER_MATCH
            @avatar.achievement_check(EVENT_DUEL_05,nil,0,true,(@avatar.level > LOW_AVATAR_DUEL_RECORD_LV))
          else
            @avatar.failed_achievement(EVENT_DUEL_05) if @avatar.level > LOW_AVATAR_DUEL_RECORD_LV
          end
        else
          @avatar.failed_achievement(EVENT_DUEL_05) if @avatar.level > LOW_AVATAR_DUEL_RECORD_LV
        end

        # 週間レコードクリアチェック (プレイヤー同士の対戦のみ)
        @avatar.week_record_clear_check(WEEK_DUEL_ACHIEVEMENT_IDS) if @match_log && @match_log.cpu_card_data_id == PLAYER_MATCH
        # チャンネルルール別レコードチェック (プレイヤー同士の対戦のみ)
        @avatar.achievement_check(DUEL_RULE_ACHIEVEMENTS[@match_log.channel_set_rule]) if @match_log && DUEL_RULE_ACHIEVEMENTS[@match_log.channel_set_rule].size > 0 && @match_log.cpu_card_data_id == PLAYER_MATCH
        # 対戦相手カウントレコードチェック
        @avatar.achievement_check(RECORD_OTHER_AVATAR_DUEL_IDS)

        @reward.send_result_to_avatar(tmp_gems, tmp_exp)

        if @match_log && HIGH_LOW_EVENT_REWARD_ENABLE
          if @match_log.cpu_card_data_id == PLAYER_MATCH
            @reward.set_tag_item_id(@match_log.a_avatar_id) if @foe == 0
            @reward.set_tag_item_id(@match_log.b_avatar_id) if @no == 0
          else
            @reward.set_tag_item_id()
          end
        end

        # スロットカード取得
        @avatar.add_finish_listener_slot_card_get_event(method(:slot_card_get_event_handler))

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

      # ログを記録
      if duel.ai_type == :proxy_ai
        @match_log.finish_aborted_match(duel.result, duel.turn) if @match_log
      else
        @match_log.finish_match(duel.result, duel.turn) if @match_log
      end

      # 勝者を観戦データに保存 0:player_a 1:player_b 2:引き分け
      if @watch_duel
        player_ids = @watch_duel.get_cache_duel_data
        winner = ""
        if RESULT_WIN == duel.result[@no][:result]
          if @player
            winner = @player.current_avatar.name
          else
            pl = Player[player_ids[:pl_id]] if player_ids&&player_ids[:pl_id]
            winner = pl.current_avatar.name if pl
          end
        elsif RESULT_LOSE == duel.result[@no][:result]
          if opponent_player&&opponent_player.player
            winner = opponent_player.player.current_avatar.name
          else
            pl = Player[player_ids[:foe_id]] if player_ids&&player_ids[:foe_id]
            winner = pl.current_avatar.name if pl
          end
        end
        @watch_duel.set_cache_finish_command(winner)
      end
      @watch_duel = nil

      # デュエルを削除する
      duel.entrants[@no].exit_game
      # AIの時相手を削除する
      unless  duel.ai_type == :none ||  duel.ai_type == :proxy_ai
        duel.entrants[@foe].exit_game if duel.entrants
      end
      duel.exit_game
      @match_log = nil
    end

    # アバターイベントの設定
    def regist_avatar_event
      @avatar = @player.current_avatar unless @avatar
      @avatar.init unless @avatar.event
      # アチーブメントのハンドラ関係追加
      @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
      @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
      @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))
      @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))
      @avatar.add_finish_listener_drop_achievement_event(method(:drop_achievement_event_handler))
      # アバターのアイテム使用にハンドラ登録
      @avatar.add_finish_listener_item_use_event(method(:item_use_event_handler))
      @avatar.add_finish_listener_item_get_event(method(:item_get_event_handler))
    end

    # アバターイベントの解除
    def remove_avatar_event
      # セットしたイベントをはずす
      if @avatar
        @avatar.remove_all_event_listener
        @avatar.remove_all_hook
        @avatar = nil
      end
    end

    # =========================================================================================================

    def pushout()
      online_list[@player.id].logout
    end

    def do_login
      # アバターにイベントをセットする
      regist_avatar_event
    end

    # ログアウト時の処理
    def do_logout
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [Logout]")

      # 相手がいる場合、ペナルティ
      # デュエルを削除する
      if @duel
        channel = Channel::channel_list[@match_log.channel_id]
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [Abort Game] turn #{@duel.turn} ,PenaltyType:#{channel.penalty_type}")

        # 一時的にペナルティは、他人の部屋に入れなくなる
        case channel.penalty_type

        when DUEL_PENALTY_TYPE_ABORT
          # 部屋に入れない時間をmemcacheにセット　（アドミンの場合ペナルティが付かない）
          CACHE.set( "penalty_id:#{@uid}", true, Unlight::DUEL_ABORT_PENALTY_TIME ) if  @player && @player.role != ROLE_ADMIN
          SERVER_LOG.info("<UID:#{@uid}>GameServer: [Set Penalty Memcache UID:#{@uid}]")
          # ログを記録
          @match_log.abort_match(@duel.turn) if @match_log
          SERVER_LOG.info("<UID:#{@uid}>GameServer: [Duel.destruct]")
          @duel.entrants[@no].exit_game
          @opponent_player.oppnent_event_destructor if @opponent_player
          @duel.exit_game
          @opponent_player = nil
          @duel = nil
          @match_log = nil
          if @watch_duel
            @watch_duel.set_cache_abort_command
            @watch_duel.clear_duel_data
          end
          @watch_duel = nil
        when DUEL_PENALTY_TYPE_AI
          if @duel.game_start_ok? && @duel.ai_type == :none && @duel.turn >= DUEL_PENALTY_TURN
            @opponent_player.opponent_duel_out if @opponent_player
            SERVER_LOG.info("<UID:#{@uid}>GameServer: [Abort Game]")
            ai_index = ( @no == 0 ) ? 1 : 0
            @duel.change_player_to_ai( ai_index )
            # ペナルティの記述
            # 一時的にペナルティは、部屋が作れなくなるのみに
            # APを減らす
            use_ap = DUEL_AP[@duel.rule]
            use_ap = @match_log.match_option == DUEL_OPTION_FRIEND ? FRIEND_DUEL_AP[duel.rule] : DUEL_AP[duel.rule]if @match_log
            # ラダーマッチの時のAP消費量
            use_ap = RADDER_DUEL_AP[@duel.rule] if @duel.is_get_bp ==1
            @player.current_avatar.duel_energy_use(use_ap)
            # 部屋を入れない時間をmemcacheにセット
            CACHE.set( "penalty_id:#{@uid}", true, Unlight::DUEL_ABORT_PENALTY_TIME )  if  @player && @player.role != ROLE_ADMIN
            SERVER_LOG.info("<UID:#{@uid}>GameServer: [Set Penalty Memcache UID:#{@uid}]")
          else
            # 切断回数チェック、ペナルティ設定（クイックマッチの時のみ）
            check_zero_turn_cut if @player && @player.role != ROLE_ADMIN && @duel && @duel.is_get_bp ==1
            # ログを記録
            @match_log.abort_match(@duel.turn) if @match_log
            SERVER_LOG.info("<UID:#{@uid}>GameServer: [Duel.destruct]")
            @duel.entrants[@no].exit_game
            @duel.entrants[@foe].exit_game
            @duel.exit_game if @duel
            error_code = @duel.game_start_ok? ? ERROR_GAME_ABORT : ERROR_GAME_NOT_START
            @opponent_player.oppnent_event_destructor(error_code) if @opponent_player
            @duel = nil
            @opponent_player = nil
            @match_log = nil
            if @watch_duel
              @watch_duel.set_cache_abort_command
              @watch_duel.clear_duel_data
            end
            @watch_duel = nil
          end
        end
      end

      # アバターのイベントをはずす
      remove_avatar_event
    end

    # 0ターン切断をした回数をチェック
    def check_zero_turn_cut(cnt=0)
      cnt = CACHE.get("zero_turn_cut_cnt_player_id:#{@uid}")
      cnt = 0 unless cnt
      cnt += 1
      if cnt >= DUEL_ABORT_CNT_NUM
        CACHE.set( "penalty_id:#{@uid}", true, DUEL_CNT_ABORT_PENALTY_TIME)
        cnt = 0
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [#{__method__}] set zero turn cut penalty.")
      end
      CACHE.set("zero_turn_cut_cnt_player_id:#{@uid}",cnt,DUEL_ABORT_CNT_REC_TIME)
    end

    # 自分のEntrantのイベントをはずす
    def oppnent_event_destructor(e=ERROR_GAME_ABORT)
      if @duel
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [Opponent event destrubtor] start(remain_duel) e:#{e}")
        @duel.entrants[@no].exit_game if @duel.entrants && @duel.entrants[@no]
        # クライアントをリセットさせるコマンドを送る
        sc_error_no(e)
        @duel = nil
        @match_log = nil
        if @watch_duel
          @watch_duel.set_cache_abort_command
          @watch_duel.clear_duel_data
        end
        @watch_duel = nil
      end
    end

    # 相手の中断、ログアウト
    def opponent_duel_out
      SERVER_LOG.info("<UID:#{@uid}>GameServer: [Oponet duel out]")
      if @duel
        sc_error_no(ERROR_GAME_QUIT)
      end
    end
  end
end
