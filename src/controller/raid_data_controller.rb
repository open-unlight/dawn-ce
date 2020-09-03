# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module RaidDataController

    # ======================================
    # 受信コマンド
    # =====================================
    # アイテムを使用する
    def cs_avatar_use_item(inv_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}]")
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

    def cs_request_notice
      if @avatar
        # 新規のものがあるかもチェック
        @avatar.new_profound_check # フレンドが取得した新規渦を自分にも追加
        @avatar.new_profound_inventory_check # 追加した新規渦の情報をNoticeに追加
        n = @avatar.get_profound_notice
      end
      sc_add_notice(n) if n!=""&&n!=nil
    end

    def cs_request_update_inventory(id_list_str)
      str_list = id_list_str.split(",")
      id_list = []
      str_list.each { |s| id_list << s.to_i }
      if @avatar
        new_ids = @avatar.new_profound_check
        id_list = id_list.concat(new_ids)
        @avatar.resend_profound_inventory(id_list)
      end
    end

    def cs_give_up_profound(inv_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidServer: [#{__method__}] inv_id:#{inv_id}")
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
      if @avatar
        inv_list = ProfoundInventory::get_avatar_check_list(@avatar.id)
        inv_list.each do |inv|
          vanished = @avatar.is_vanished_profound(inv)
          is_reward = @avatar.check_profound_reward(inv)
          # 報酬配布があった場合、渦情報をクライアントに送る
          @avatar.send_prf_info(inv, false) if is_reward&&!vanished
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

    # ボスHPの更新
    def cs_update_boss_hp(prf_id,now_dmg)
      if @avatar
        prf = Profound[prf_id]
        view_start_dmg = (prf) ? prf.param_view_start_damage : 0
        boss_damage,send_log_data = ProfoundLog::get_now_damage(@avatar.id,prf_id,view_start_dmg,now_dmg)
        prev_view_flag = send_log_data.first[:name_view] if send_log_data && send_log_data.size > 0
        send_log_data.each do |data|
          state_update = false
          msg_type = (data[:log].avatar_id != 0) ? PRF_MSGDLG_DAMAGE : PRF_MSGDLG_REPAIR
          msg_data = []
          if msg_type == PRF_MSGDLG_DAMAGE
            msg_data << data[:log].avatar_name.force_encoding("UTF-8")
            boss_name = data[:log].boss_name.force_encoding("UTF-8")
            msg_data << boss_name
          else
            boss_name = data[:log].avatar_name.force_encoding("UTF-8")
            msg_data << boss_name
          end
          msg_data << data[:log].damage.to_s.force_encoding("UTF-8")

          # 表示状態変更チェック
          state_update = true if prev_view_flag == false && data[:name_view] == true
          sc_send_boss_damage(prf_id,data[:log].damage,"#{prf_id}:#{msg_type}:#{msg_data.join(",")}",prf.state,state_update)

          prev_view_flag = data[:name_view]
        end
        sc_update_boss_hp(prf_id,boss_damage)
      end
    end

    # 渦を取得
    def cs_get_profound(hash)
      SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] hash:#{hash} avatar:#{@avatar}");
      if @avatar
        ret = @avatar.get_profound_from_hash(hash)
        if ret.instance_of?(ProfoundInventory)
          SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] success! inv_id:#{ret.id}");
          # 渦情報を送信
          @avatar.send_prf_info(ret,false)
        else
          SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] e:#{ret}");
          # 帰ってきたエラーを出す
          sc_error_no(ret)
        end
      end
    end


    def cs_request_ranking_list(inv_id, offset, count)
      @rank_prf_inv = ProfoundInventory[inv_id] if !@rank_prf_inv || @rank_prf_inv.id != inv_id
      if @rank_prf_inv
        @rank_prf_inv.init_ranking
        ret = @rank_prf_inv.get_ranking_str(offset,offset+count-1)
        sc_update_ranking_list(@rank_prf_inv.profound_id, offset, ret) if ret&&ret.size >1
      end
    end

    def cs_request_rank_info(inv_id)
      d = @avatar.get_profound_rank(inv_id) if @avatar
      sc_update_rank(d[:prf_id], d[:ret][:rank], d[:ret][:score]) if d&&d[:prf_id] != 0
    end

    # レイドHashのコピー許可
    def cs_request_profound_hash(prf_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] prf_id:#{prf_id}")
      if @avatar
        permission = false
        prf = Profound[prf_id]
        if prf
          owner_id = prf.found_avatar_id
          if owner_id == @avatar.id
            permission = true
          else
            if prf.copy_type == PRF_COPY_TYPE_ALL
              permission = true
            else
              if prf.copy_type == PRF_COPY_TYPE_FRIENDS
                owner_ava = Avatar[owner_id]
                if owner_ava
                  fl = FriendLink::check_already_exist?(owner_ava.player_id,@avatar.player_id,@avatar.server_type)
                  permission = true if fl != false && fl.size > 0 &&fl.first.friend_type == FriendLink::TYPE_FRIEND
                end
              end
            end
          end
        end
        if permission
          sc_get_profound_hash(prf_id,prf.profound_hash,prf.copy_type,prf.set_defeat_reward)
        else
          sc_error_no(ERROR_PRF_CANT_HASH_COPY)
        end
      end
    end

    # レイド設定を変更
    def cs_change_profound_config(prf_id,type,set_defeat_reward)
      SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] prf_id:#{prf_id} type:#{type} set_defeat_reward:#{set_defeat_reward}")
      prf = Profound[prf_id]
      if prf
        prf.change_copy_type(type)
        prf.change_set_defeat_reward(set_defeat_reward)
      end
    end

    # フレンドも渦に追加する
    def cs_send_profound_friend(prf_id)
      prf = Profound[prf_id]
      if @avatar&&prf
        @avatar.send_profound_friends(prf)
      end
    end

    # 渦関連Noticeのみ削除
    def cs_profound_notice_clear(n)
      if @avatar
        @avatar.profound_notice_clear(n)
      end
    end

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
      end
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

    def pushout()
      online_list[@player.id].player.logout(true)
      online_list[@player.id].logout
    end

    def do_login
      if @player.avatars.size > 0
        @avatar = @player.current_avatar
        regist_avatar_event
        @avatar.new_profound_check
        @avatar.resend_profound_inventory
      end
    end

    def do_logout
      uid = @uid
      # イベントを外す
      if @avatar
        @avatar.remove_all_event_listener
        @avatar.remove_all_hook
        @avatar = nil
      end

      # 残っている場合消す
      @rank_prf_inv = nil

      delete_connection
    end
  end
end
