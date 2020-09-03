# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module RaidChatController
    # コメントを保存
    def cs_set_comment(prf_id,comment,last_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidChatServer: [#{__method__}] prf_id:#{prf_id}")
      if @avatar
        ProfoundComment::set_comment(prf_id,@avatar.id,@avatar.name,comment)
        ret,new_last_id = ProfoundComment::get_comment(prf_id,last_id)
        set_comments = []
        ret.each do |pc|
        set_comments << "#{pc[:a_name]}:#{pc[:comment]}"
        end
        sc_update_comment(prf_id,set_comments.join(",").force_encoding("UTF-8"),new_last_id) if set_comments.size > 0
      end
    end

    # コメントを更新
    def cs_request_comment(prf_id,last_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidChatServer: [#{__method__}] prf_id:#{prf_id} last_id:#{last_id}")
      ret,new_last_id = ProfoundComment::get_comment(prf_id,last_id)
      set_comments = []
      ret.each do |pc|
        set_comments << "#{pc[:a_name]}:#{pc[:comment]}"
      end
      sc_update_comment(prf_id,set_comments.join(",").force_encoding("UTF-8"),new_last_id) if set_comments.size > 0
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

    def pushout()
      online_list[@player.id].player.logout(true)
      online_list[@player.id].logout
    end

    def do_login
      if @player.avatars.size > 0
        @avatar = @player.current_avatar
      end
    end

    def do_logout
      delete_connection
    end

  end

end
