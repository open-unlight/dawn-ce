# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module DataController

      # ======================================
      # 受信コマンド
      # =====================================

    # アバターの作製報告
    def cs_create_avatar_success()
      SERVER_LOG.info("<UID:#{@uid}>DataServer: [#{__method__}] ")
      # 作製完了したので、アバターデータを取得しなおす
      @player.refresh
      if @player.avatars.size > 0
        @avatar = @player.avatars[0]
      end
    end

      # 他人アバターの情報を要求
      def cs_request_other_avatar_info(id)
        a = CACHE.get("oa#{id}")
        unless a
          a = Avatar[id].get_other_avatar_info_set
          CACHE.set("oa#{id}",a, 300)
        end
        if a
          sc_other_avatar_info(*a)
          SERVER_LOG.info("<UID:#{@uid}>DataServer: [sc_other_avatar_info] #{a[0]}")
        end
      end

      # ストーリー情報を送る
      def cs_request_story_info(rnd0,id,rnd1)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_request_story_info] #{id}");
        story = CharaCardStory[id];
        sc_story_info(id, story.book_type||0,  story.title||"", story.content||"",story.image||"", story.age_no||"", story.version||0) if story
      end

      # フレンド情報のリクエスト
      def cs_request_friends_info
      end

      def cs_request_friend_list(type,offset,count)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [#{__method__}] type:#{type} offset:#{offset} count:#{count}")
        if @player
          ret = @player.get_friend_list_offset_str(type,offset,count)
          sc_friend_list(*ret)
        end
      end

      # 招待
      def cs_friend_invite(uid)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_friend_invite] #{uid}")
        if @player
          @player.invite_friend(uid)
        end
      end

      # カムバック
      def cs_send_comeback_friend(uid)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_friend_comeback] #{uid}")
        if @player
          @player.send_comeback_friend(uid)
        end
      end

      # 自分を招待してくれたひとを更新
      def cs_update_invited_users(users)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_update_invited_users] #{users}")
        u =users.split(",")
        if @player
          @player.update_invited_users(u)
        end
      end

      # 自分を招待してくれたひとを更新
      def cs_update_comeback_send_users(users)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_update_comeback_send_users] #{users}")
        u =users.split(",")
        if @player
          @player.update_comebacked_users(u)
        end
      end

      # そのUIDをもった人はゲームを始めているか？
      def cs_check_exist_player(uid)
        ret = Player.filter({:name=>uid}).all
        if ret.size >0 && ret[0] && ret[0].avatars.size > 0
          sc_exist_player_info(uid,ret[0].id, ret[0].current_avatar.id)
        end
      end

      def cs_request_rank_info(kind, server_type)
        d = @avatar.get_rank(kind, server_type) if @avatar
        sc_update_rank(kind, d[:rank], d[:point]) if d
      end

      def cs_request_ranking_list(kind,offset,count,server_type)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_request_ranking_list],#{kind},#{offset},#{server_type},#{count}")
        case kind
        when RANK_TYPE_TD
          ret = Unlight::TotalDuelRanking.get_ranking_str(server_type, offset, offset+count-1);
          sc_update_total_duel_ranking_list(offset, ret) if ret&&ret.size >1
        when RANK_TYPE_TQ
          ret = Unlight::TotalQuestRanking.get_ranking_str(server_type, offset, offset+count-1);
          sc_update_total_quest_ranking_list(offset, ret) if ret&&ret.size >1
        when RANK_TYPE_WD
          ret = Unlight::WeeklyDuelRanking.get_ranking_str(server_type, offset, offset+count-1);
          sc_update_weekly_duel_ranking_list(offset, ret) if ret&&ret.size >1
        when RANK_TYPE_WQ
          ret = Unlight::WeeklyQuestRanking.get_ranking_str(server_type, offset, offset+count-1);
          sc_update_weekly_quest_ranking_list(offset, ret) if ret&&ret.size >1
        when RANK_TYPE_TE
          ret = Unlight::TotalEventRanking.get_ranking_str(server_type, offset, offset+count-1);
          sc_update_total_event_ranking_list(offset, ret) if ret&&ret.size >1
        when RANK_TYPE_TV
          now = Time.now.utc
          if now < CHARA_VOTE_RANKING_HIDE_TIME
            ret = Unlight::TotalCharaVoteRanking.get_ranking_str(server_type, offset, offset+count-1, false);
            sc_update_total_chara_vote_ranking_list(offset, ret) if ret&&ret.size >1
          end
       end
      end
      # チャンネルリストを取得する
      def cs_request_channel_list_info
        sc_channel_list_info(*Channel.get_channel_list_info(@avatar.server_type)) if @avatar
      end

      # 渦を取得
      def cs_get_profound(hash)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [#{__method__}] hash:#{hash} avatar:#{@avatar}");
        if @avatar
          ret = @avatar.get_profound_from_hash(hash)
          if ret.instance_of?(ProfoundInventory)
            SERVER_LOG.info("<UID:#{@uid}>DataServer: [#{__method__}] success! inv_id:#{ret.id}");
            # 渦情報を送信
            @avatar.send_prf_info(ret,false)
          else
            SERVER_LOG.info("<UID:#{@uid}>DataServer: [#{__method__}] e:#{ret}");
            # 帰ってきたエラーを出す
            sc_error_no(ret)
          end
        end
      end

      # アバター検索
      def cs_find_avatar(avatar_name)
        SERVER_LOG.info("<UID:#{@uid}>DataServer: [cs_find_avatar] #{avatar_name}");
        if @player
          st = @player.server_type
          a = Avatar.filter{ [Sequel.like(:name,"#{avatar_name}%"), player_id > 0, server_type => st] }.all
          ret = []
          a.each do |a|
            if @player.id != a.player_id
              ret << a.player_id
              ret << a.id
            end
          end
          sc_result_avatars_list(ret.join(","))
        end
      end



      def regist_avatar_event
        @avatar.init
        @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
        @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
        @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))
        @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))
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


      # ======================================
      # 送信コマンド
      # =====================================
      # 押し出し関数
      def pushout()
        online_list[@player.id].close_connection
        online_list[@player.id].player = nil
      end

      # ログイン時の処理
      def do_login
        sc_data_version_info(0,
                             0,
                             0,
                             Dialogue.data_version||0,
                             CharaCardStory.data_version||0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,
                             0,

                             )
        if @player.avatars.size > 0
          @avatar = @player.avatars[0]
          @avatar.deck_clean_up_all
          @avatar.quest_all_out
          # していない人セール時間にする
          @avatar.set_one_day_sale_start_check()
          regist_avatar_event
          # お詫びアイテムがあれば配付
          @avatar.get_apology_items
          sc_avatar_info(*@avatar.get_avatar_info_set)
          # アチーブメント情報をあとから送る 2013/01/16 yamagishi
          sc_achievement_info(*@avatar.get_achievement_info_set)
        else
          SERVER_LOG.info("<UID:#{@uid}>DataServer: [regist start]")
          sc_regist_info(REGIST_PARTS.join(","), REGIST_CARDS.join(","))
        end
      end

      # ログアウト時の処理
      def do_logout
        # セットしたイベントをはずす
        if @avatar
          @avatar.remove_all_event_listener
          @avatar.remove_all_hook
          @avatar = nil
        end
        delete_connection
      end
    end

  end
