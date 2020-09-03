# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'controller/duel_controller'
module Unlight

  module RaidController
    include Unlight::DuelController

    # ======================================
    # 受信コマンド
    # =====================================
    # アイテムを使用する
    def cs_avatar_use_item(inv_id)
      # バトル中は使用できなくすべきか
      if @avatar
        e = @avatar.use_item(inv_id)
        @reward.update if @reward&&(@reward.finished == false)
        if e >0
          sc_error_no(e)
        else
          it = ItemInventory[inv_id]
          SERVER_LOG.info("<UID:#{@uid}>RaidServer: [avatar_use_item] use_item_id:#{it.avatar_item_id}");
        end
      end
    end

    # ボス戦開始
    def cs_boss_duel_start(inv_id,turn,use_ap)
      if @player&&@avatar&&@duel == nil
        # 必要なものをそろえる
        err,set_data = @avatar.profound_start_set_up(inv_id,use_ap)
        if err == 0
          @prf_inv        = set_data[:inv]
          prf_data        = set_data[:data]
          boss_deck       = set_data[:boss_deck]
          avatar_deck_idx = set_data[:deck_idx]
          avatar_deck     = set_data[:avatar_deck]
          stage           = set_data[:stage]
          @boss_name      = set_data[:boss_name]

          # 現在ダメージを取得
          deck_damages = @prf_inv.get_chara_cards_damages
          boss_damage,@get_log_id = ProfoundLog::get_start_boss_damage(@prf_inv.profound_id)
          @set_heal_log_ids = nil

          @duel = MultiDuel.new(@player.current_avatar,
                                AI,
                                avatar_deck,
                                boss_deck,
                                RULE_3VS3,
                                0,
                                :profound_ai,
                                stage,
                                deck_damages,
                                boss_damage,
                                0,
                                0,
                                turn
                                )
          # 相手のカードの状態異常をターン制から、時間制に変更
          @duel.beta.chara_cards.each{ |c| c.status_update = false }
          do_determine_session(-1,
                               "Boss",
                               avatar_deck.cards_id.join(","),
                               boss_deck.cards_id.join(","),
                               stage,
                               deck_damages,
                               boss_damage,
                               )
          @duel.profound_id = @prf_inv.profound_id
          set_duel_handler(0, RULE_3VS3)
          regist_raid_event
          # 1の対戦の時はクライアントのキャラチェンジボタンを消す
          if avatar_deck.card_inventories.size==1&&boss_deck.card_inventories.length==0
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, @duel.entrants[@no].distance, false)
          else
            sc_three_to_three_duel_start(@duel.deck.size, @duel.event_decks[@no].size,@duel.event_decks[@foe].size, @duel.entrants[@no].distance, true)
          end
          @duel.three_to_three_duel

          @finished_duel_type = PRF_FINISHED_NONE
          @avatar.profound_duel_start(@prf_inv,use_ap,avatar_deck_idx)
          SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] inv_id:#{inv_id} turn:#{turn} use_ap:#{use_ap}");
          send_score
        else
          SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] boss duel failed. error code:#{err}");
          sc_error_no(err)
        end
      else
        SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] not finished duel.");
        sc_error_no(ERROR_PRF_NOT_FINISHED)
      end
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] *****************");
    end

    # ゲームセッションの決定
    def do_determine_session(id, name,player_chara_id,foe_chara_id, stage, alpha_damege_set, beta_damege_set=[0,0,0])
      sc_determine_session(id,
                           name,
                           player_chara_id,
                           foe_chara_id,
                           "",
                           stage,
                           alpha_damege_set[0],
                           alpha_damege_set[1],
                           alpha_damege_set[2],
                           beta_damege_set[0],
                           beta_damege_set[1],
                           beta_damege_set[2],
                           )
    end

    def cs_request_notice
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}]")
      if @avatar
        # 新規のものがあるかもチェック
        @avatar.new_profound_inventory_check
        n = @avatar.get_profound_notice
      end
      sc_add_notice(n) if n!=""&&n!=nil
    end

    def cs_request_update_inventory(id_list_str)
      str_list = id_list_str.split(",")
      id_list = []
      str_list.each { |s| id_list << s.to_i }
      @avatar.resend_profound_inventory(id_list) if @avatar
    end

    def cs_give_up_profound(inv_id)
      if @avatar
        prf_inv = ProfoundInventory[inv_id]
        if prf_inv
          err = @avatar.profound_duel_finish(prf_inv,true)
          if err == 0
            @avatar.send_prf_info(prf_inv)
          else
            sc_error_no(err)
          end
        end
      end
    end

    def cs_check_vanish_profound(inv_id)
      if @avatar
        prf_inv = ProfoundInventory[inv_id]
        if prf_inv
          # 渦消失チェック
          @avatar.profound_vanish_check(prf_inv)
        end
      end
    end

    # 報酬配布があるか確認
    def cs_check_profound_reward()
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}]")
      if @avatar
        btl_inv_list = ProfoundInventory::get_avatar_battle_list(@avatar.id)
        btl_inv_list.each do |inv|
          is_reward = @avatar.check_profound_reward(inv)
          # 報酬配布があった場合、渦情報をクライアントに送る
          @avatar.send_prf_info(inv, false) if is_reward
        end
      end
    end

    # カレントデッキを変更する
    def cs_update_current_deck_index(index)
      if @avatar
        @avatar.update_current_deck_index(index)
        sc_update_current_deck_index(index)
      end
    end

    # ======================================
    # 送信コマンド
    # =====================================


    # ======================================
    # イベント関連送信コマンド
    # =====================================
    # アバターに対するイベント
    def regist_avatar_event
      if @avatar
        @avatar.init
        @avatar.add_finish_listener_send_profound_info_event(method(:send_profound_info_event_handler))
        @avatar.add_finish_listener_resend_profound_inventory_event(method(:resend_profound_inventory_event_handler))
        @avatar.add_finish_listener_resend_profound_inventory_finish_event(method(:resend_profound_inventory_finish_event_handler))
        @avatar.add_finish_listener_item_use_event(method(:item_use_event_handler))
        @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
        @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
        @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))
        @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))
        @avatar.add_finish_listener_update_combine_weapon_data_event(method(:update_combine_weapon_data_event_handler))
      end
    end
    # Raid専用Duelイベント
    def regist_raid_event
      if @duel
        # 開始と同時にBuffを設定する
        if @duel.rule == RULE_1VS1
          @duel.add_start_listener_three_to_three_duel(method(:send_boss_buff_handler))
        elsif @duel.rule == RULE_3VS3
          @duel.add_start_listener_three_to_three_duel(method(:send_boss_buff_handler))
        end

        @duel.add_start_listener_start_turn_phase(method(:reset_buff_data_handler))           # ターン開始フェイズ開始と共に状態異常を更新
        @duel.beta.add_finish_listener_damaged_event(method(:damage_log_handler))             # ダメージ保存
        @duel.beta.add_finish_listener_party_damaged_event(method(:party_damage_log_handler)) # ダメージ保存
        @duel.beta.add_finish_listener_healed_event(method(:heal_log_handler))                # 回復保存
        @duel.beta.add_finish_listener_party_healed_event(method(:party_heal_log_handler))    # 回復保存
        # 状態付加時イベント(状態異常を与えるのはPlayerだから付与のみAlphaにセットする)
        @duel.beta.add_finish_listener_cured_event(method(:reset_boss_buff_handler))
        @duel.alpha.chara_cards.each{ |c| c.add_finish_listener_on_buff_event(method(:set_boss_buff_handler)) }
        @duel.beta.chara_cards.each{ |c| c.add_finish_listener_off_buff_event(method(:unset_boss_buff_handler)) }
        # プレイヤー側のボーナスにスコア用ハンドラを追加する
        @duel.alpha.add_finish_listener_duel_bonus_event(method(:duel_bonus_handler)) # デュエルボーナスをSocreに追加する

        # パッシブスキルのイベントハンドラ
        @duel.beta.chara_cards.each{ |c| c.add_finish_listener_on_rage_against_event(method(:boss_on_rage_against_event_handler)) }
      end
    end

    # アチーブメントがクリアされた
    def achievement_clear_event_handler(target, ret)
      sc_achievement_clear(*ret)
    end

    # アチーブメントが追加された
    def add_new_achievement_event_handler(target, ret)
      sc_add_new_achievement(ret)
    end

    # アチーブメントが追加された
    def delete_achievement_event_handler(target, ret)
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

    # パッシブスキル発動時のボス側ハンドラ
    def boss_on_rage_against_event_handler(target,ret)
      sc_raid_rage_info(ret.join(","))
    end

    # 渦情報イベント
    def send_profound_info_event_handler(target,ret)
      sc_resend_profound_inventory(*ret)
    end

    # 渦インベントリー情報を送信
    def resend_profound_inventory_event_handler(target,ret)
      sc_resend_profound_inventory(*ret)
    end

    # 渦インベントリー情報送信完了
    def resend_profound_inventory_finish_event_handler(target,ret)
      sc_resend_profound_inventory_finish()
    end

    # アイテムを使用した
    def item_use_event_handler(target, ret)
      sc_use_item(ret)
    end

    # 各フェイズ関数をオーバーライドし、終了チェックを行う
    def duel_start_turn_phase_handler(target, ret)
      send_damage_handler
      boss_duel_finish_check
      super(target,ret)
    end
    def duel_refill_card_phase_handler(duel,ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_refill_event_card_phase_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_move_card_phase_finish_handler(target, ret)
      send_damage_handler
      boss_duel_finish_check
      super(target,ret)
    end
    def duel_determine_move_phase_handler(target, ret)
      send_damage_handler
      boss_duel_finish_check
      super(target,ret)
    end
    def duel_attack_card_phase_finish_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_deffence_card_phase_finish_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_det_battle_point_phase_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_battle_result_phase_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end
    def duel_finish_turn_phase_handler(duel, ret)
      send_damage_handler
      boss_duel_finish_check
      super(duel,ret)
    end

    def boss_duel_finish_check
      if @avatar&&@duel
        if @prf_inv
          if @prf_inv.profound.is_defeat?
            @finished_duel_type = PRF_FINISHED_DEFEAT
          elsif @avatar.is_vanished_profound(@prf_inv)
            @finished_duel_type = PRF_FINISHED_TIME_UP
          end
        else
          @finished_duel_type = PRF_FINISHED_TIME_UP
        end
        if @finished_duel_type != PRF_FINISHED_NONE
          @duel.set_over_turn
          @duel.beta.current_hit_point = 0
          if @finished_duel_type == PRF_FINISHED_TIME_UP
            if @prf_inv
              prf_name = @prf_inv.profound.p_data.name.force_encoding("UTF-8")
              boss_name = @prf_inv.profound.p_data.get_boss_name.force_encoding("UTF-8")
              @avatar.write_notice(NOTICE_TYPE_FIN_PRF_FAILED, [@prf_inv.profound.id,prf_name,boss_name].join(","))
            end
          end
        end
      end
    end

    # スコアを送る
    def send_score
      if @avatar&&@prf_inv
        SERVER_LOG.info("<UID:#{@uid}>RaidServer:send_score #{@prf_inv.score}")
        sc_raid_score_update(@prf_inv.score)
      end
    end


    # ボーナスゲット時のハンドラ
    def duel_bonus_handler(target, ret)
      if @avatar&&@prf_inv
        @prf_inv.update_score(ret.last*RAID_BONUS_SCORE_RATIO) # retのlastがボーナス量
        send_score
      end
    end

    # ダメージ送信ハンドラ
    def send_damage_handler
      if @avatar&&@prf_inv
        # ダメージ
        prf_log = ProfoundLog::get_profound_damage_log(@prf_inv.profound_id,@avatar.id,@get_log_id)
        if prf_log&&prf_log.size > 0
          add_damage = 0
          b_name = @boss_name[@duel.beta.current_chara_card_no].force_encoding("UTF-8")
          prf_log.each do |pl|
            if pl.avatar_id > 0
              a_name = pl.avatar_name.force_encoding("UTF-8")
              dmg = pl.damage.to_s.force_encoding("UTF-8")
              add_damage += pl.damage
            else
              if @set_heal_log_ids == nil || @set_heal_log_ids.index(pl.id) == nil
                point = pl.damage.to_s.force_encoding("UTF-8")
                add_damage -= pl.damage
              end
            end
            @get_log_id = pl.id
          end
          if add_damage > 0
            @duel.beta.damaged_event(add_damage,false,false)
            set_message_str_data(DUEL_MSGDLG_SUM_DMG_FOR_BOSS,b_name,add_damage)
          elsif add_damage < 0
            add_heal = add_damage.abs # - の状態なので、絶対値で回復ポイントに変換
            @duel.beta.healed_event(add_heal,false)
            set_message_str_data(DUEL_MSGDLG_HEAL_BOSS,b_name,add_heal)
          end
        end
      end
    end

    def reset_buff_data_handler(target)
      if @avatar&&@prf_inv
        # 状態異常
        cc = @duel.beta.current_chara_card
        # 一度リセット
        cc.cure_status
        sc_entrant_cured_event(false)
        # 状態異常
        buffs = @prf_inv.profound.get_boss_buff
        now = Time.now.utc
        if buffs
          buffs.each do |b_id,v|
            if @prf_inv.profound.check_non_limit_buff(b_id) || now <= v[:limit]
              cc.set_state_raid(cc.status[b_id],v[:value],v[:turn])
              sc_buff_on_event(false,0,b_id,v[:value],v[:turn])
              limit_time = (v[:limit] - now).to_i
              sc_add_buff_limit(b_id,v[:value],v[:turn],limit_time)
            else
              cc.set_state_raid(cc.status[b_id],v[:value],0)
              @prf_inv.profound.unset_boss_buff(b_id,v[0])
            end
          end
        end
      end
    end

    # ダメージ保存ハンドラ
    def damage_log_handler(target,ret)
      set_damage_log(ret.first) if ret.last # 引数の最後にログ保存フラグをセットしてある
    end
    def party_damage_log_handler(target,ret)
      set_damage_log(ret[1]) if ret.first == 0 && ret.last # 引数の最後にログ保存フラグをセットしてある
    end
    def set_damage_log(ret)
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] #{ret} #{@avatar} #{@avatar.event}")
      if @avatar&&@prf_inv&&ret > 0&&@finished_duel_type == PRF_FINISHED_NONE
        SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] prf_id:#{@prf_inv.profound_id}")
        # 撃破したか
        now_all_damage = ProfoundLog::get_all_damage(@prf_inv.profound_id)
        if ! @prf_inv.profound.is_defeat? && now_all_damage+ret >= @duel.beta.current_chara_card.hp
          SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] defeat_update!!!!!!!")
          # 渦を終了状態に 先に変更
          @prf_inv.profound.finish
          # ダメージ更新、撃破記録
          @prf_inv.update_defeat(ret,@duel.turn)
          # 渦に撃破者のアバターIDを記録
          @prf_inv.profound.set_defeat_avatar_id(@avatar.id)
          send_score

          # 撃破したのでイベントレコードチェック 2014/06/12
          if EVENT_PRF_SET_01[0].include?(@prf_inv.profound.p_data.id) && @prf_inv.score > 0
            @avatar.achievement_check(EVENT_PRF_SET_01[1])
          end
        else
          # 与ダメージを更新
          @prf_inv.update_damage_count(ret,@duel.turn)
          send_score
        end
        # ログに保存
        chara_no = @duel.beta.current_chara_card_no
        boss_name = @boss_name[chara_no]
        atk_chara = @duel.alpha.current_chara_card.charactor_id
        ProfoundLog::set_damage(@prf_inv.profound_id,@avatar.id,@avatar.name,chara_no,ret,boss_name,atk_chara)
        # パラメータ表示チェック
        if @prf_inv.profound.state == PRF_ST_UNKNOWN
          if @duel.beta.total_hit_point <= @prf_inv.profound.param_view_start_damage
            @prf_inv.profound.battle
          end
        end
      end
    end

    # 回復保存ハンドラ
    def heal_log_handler(target,ret)
      set_heal_log(ret.first) if ret.last
    end
    def party_heal_log_handler(target,ret)
      set_heal_log(ret[1]) if ret.first == 0 && ret.last
    end
    def set_heal_log(ret)
      if @avatar&&@prf_inv&&ret > 0
        pl = ProfoundLog::set_damage(@prf_inv.profound_id,0,@boss_name[@duel.beta.current_chara_card_no],@duel.beta.current_chara_card_no,ret)
        # 保存したログIDを保持
        @set_heal_log_ids = [] unless @set_heal_log_ids
        @set_heal_log_ids.push(pl.id)
      end
    end

    # 状態異常の初期設定
    def send_boss_buff_handler(duel)
      if @prf_inv
        buffs = @prf_inv.profound.get_boss_buff
        if buffs
          cc = @duel.beta.current_chara_card
          now = Time.now.utc
          buffs.each do |b_id,v|
            if @prf_inv.profound.check_non_limit_buff(b_id) || now <= v[:limit]
              cc.set_state_raid(cc.status[b_id],v[:value],v[:turn])
              sc_buff_on_event(false,0,b_id,v[:value],v[:turn])
              limit_time = (v[:limit] - now).to_i
              sc_add_buff_limit(b_id,v[:value],v[:turn],limit_time)
            else
              cc.set_state_raid(cc.status[b_id],v[:value],0) # レイドの場合、勝手に消えないので消す
              @prf_inv.profound.unset_boss_buff(b_id,v[:value])
            end
          end
        end
      end
    end

    # 状態異常付加
    def set_boss_buff_handler(target, ret)
      if @prf_inv&&ret[0] == false
        b_id,buff = @prf_inv.profound.set_boss_buff(ret[2],ret[3],ret[4])
        now = Time.now.utc
        limit_time = (buff[:limit] - now).to_i
        sc_add_buff_limit(b_id,buff[:value],buff[:turn],limit_time)
      end
    end
    # 状態異常解除
    def unset_boss_buff_handler(target, ret)
      if @prf_inv
        buffs = @prf_inv.profound.unset_boss_buff(ret[1])
      end
    end
    def reset_boss_buff_handler(target, ret)
      if @prf_inv
        @prf_inv.profound.reset_boss_buff
      end
    end
    # 状態異常更新
    def update_boss_buff_handler(target, ret)
    end

    # 終了時のハンドラ
    # 返値は[alpha, beta, reward]
    def duel_finish_handler(duel, ret)
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] #{ret}")
      # 相手のカードの状態異常を時間制から、ターン制に変更
      duel.entrants[@foe].chara_cards.each{ |c| c.status_update = true }
      @duel = nil
      if @avatar&&@prf_inv
        case @finished_duel_type
        when PRF_FINISHED_NONE
          if duel.beta.total_hit_point <= 0
            # 死んでいるのに撃破が着いていない場合、ここでつける（同時にダメージを与えた場合ここにくるのは運になる）
            if ! @prf_inv.profound.is_defeat?
              # 渦を終了状態に 先に変更
              @prf_inv.profound.finish
              # 撃破を記録
              @prf_inv.update_defeat()
              # 渦に撃破者のアバターIDを記録
              @prf_inv.profound.set_defeat_avatar_id(@avatar.id)
            end
            result = RESULT_WIN
          elsif duel.alpha.total_hit_point <= 0
            result = RESULT_LOSE
          else
            result = RESULT_TIMEUP
          end
        when PRF_FINISHED_DEFEAT
          result = RESULT_WIN
          # 死んでるのにInventoryが撃破状態になってないなら変更
          if @prf_inv.profound.is_defeat? && !@prf_inv.is_solve?
            @prf_inv.solve
          end
        when PRF_FINISHED_TIME_UP
          result = RESULT_TIMEUP
        end

        @avatar.refresh
        tmp_exp = duel.result[@no][:exp]*(@avatar.exp_pow*0.01)
        tmp_gems = duel.result[@no][:gems]*(@avatar.gem_pow*0.01)

        sc_one_to_one_duel_finish(result,
                                  duel.result[@no][:gems],
                                  duel.entrants[@no].base_exp,
                                  duel.entrants[@no].exp_bonus,
                                  @avatar.gem_pow,
                                  @avatar.exp_pow,
                                  tmp_gems.truncate,
                                  tmp_exp.truncate,
                                  false)
        # 経験値等をおくる
        @avatar.set_exp(tmp_exp, false)
        @avatar.set_duel_deck_exp(tmp_exp)
        @avatar.set_gems(tmp_gems, false)

        # レベルが制限を越えた場合、失敗判定に変更
        @avatar.failed_achievement(EVENT_DUEL_05) if @avatar.level > LOW_AVATAR_DUEL_RECORD_LV

        # 使用した合成武器のパッシブ使用回数を減らす
        @avatar.combine_weapon_passive_cnt_update

        # デュエルを削除する
        duel.entrants[@no].exit_game
        # CPUもexitして置かないとゲームのイベントが外れないので。。
        duel.entrants[1].exit_game
        duel.exit_game

        # 発見者のアバターIDを確保
        finder_id = @prf_inv.profound.found_avatar_id

        # 渦戦闘終了処理
        if @prf_inv && result == RESULT_WIN
          # 勝利告知は撃破ユーザが行う
          @prf_inv.boss_battle_finish if @prf_inv.defeat
          err = @avatar.profound_duel_finish(@prf_inv) if @avatar
          # 渦の待機時間を変更
          @prf_inv.profound.set_losstime if @prf_inv.defeat
          if err != 0
            SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] boss duel finish failed. error code:#{err}");
            sc_error_no(err)
          end

          # レコードチェック
          if @avatar.id == finder_id
            # 発見者が撃破した場合
            @avatar.achievement_check(PRF_SELF_PRF_CLEAR_CHECK_ID)
          else
            # 発見者が別の場合、発見者のレコードチェック
            finder_avatar = Avatar[finder_id]
            finder_avatar.achievement_check(PRF_SELF_PRF_CLEAR_CHECK_ID) if finder_avatar
          end
        end
        # 報酬チェック＆あるなら配布
        @avatar.check_profound_reward(@prf_inv)
        # 戦闘終了後必ず渦情報を送る
        @avatar.send_prf_info(@prf_inv)

        # イベントレコードチェック
        if @avatar
          @avatar.achievement_check(PRF_ALL_DMG_CHECK_IDS)
          # 他人の渦参加チェック
          if finder_id != @avatar.id&&@prf_inv.score > 0
            @avatar.achievement_check(PRF_OTHER_RAID_BTL_CHECK_ID)
          end
        end

        # 使用済みのものをクリア
        SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] boss duel finish. inv:#{@prf_inv}");
        @prf_inv = nil
        @boss_name = nil
        @use_ap = nil
      end
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] *****************");
    end

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
        regist_avatar_event
      end
    end

    # ログアウト時の処理
    def do_logout
      uid = @uid

      # イベントを外す
      if @avatar
        @avatar.remove_all_event_listener
        @avatar.remove_all_hook
      end

      # 渦戦闘が終了（撃破）していて、勝利処理がされていないなら処理
      if @prf_inv
        if @prf_inv.profound.is_defeat?
          # 念のため、ダメージ計算
          all_damage = ProfoundLog::get_all_damage(@prf_inv.profound_id)
          if all_damage >= @prf_inv.profound.p_data.get_boss_max_hp
            # 勝利告知は撃破ユーザが行う
            defeat_avatar = Avatar[@prf_inv.profound.defeat_avatar_id] if @prf_inv.profound.defeat_avatar_id != 0
            if defeat_avatar
              @prf_inv.boss_battle_finish
              err = defeat_avatar.profound_duel_finish(@prf_inv) if defeat_avatar
              # 渦の待機時間を変更
              @prf_inv.profound.set_losstime
            end
          end
        end

        # 使用した合成武器のパッシブ使用回数を減らす
        @avatar.combine_weapon_passive_cnt_update
        # イベントレコードチェック
        @avatar.achievement_check(PRF_ALL_DMG_CHECK_IDS) if @avatar
      end

      delete_connection
      # 残っている場合消す
      if @duel
        SERVER_LOG.info("<UID:#{@uid}>RaidServer: [Duel.destruct]")
        @duel.entrants[@no].exit_game
        # CPUもexitして置かないとゲームのイベントが外れないので。。
        @duel.entrants[1].exit_game
        @duel.exit_game
        sc_error_no(ERROR_GAME_QUIT)
        @opponent_player.opponent_duel_out if @opponent_player
        @duel = nil
      end

      # イベント等は先に外し、最後にAvatarにNilを入れる
      @avatar = nil

      @prf_inv = nil
      @boss_name = nil
      @use_ap = nil
      @set_heal_log_ids = nil
      @finished_duel_type = nil
    end
  end
end
