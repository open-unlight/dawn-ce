# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module ChatController

    CHAT_CHANNEL_NAME  = ["A","B","C","Duel","Watch"]
    CHAT_CHANNEL_DUEL  = 3
    CHAT_CHANNEL_WATCH = 4

      # ======================================
      # 受信コマンド
      # =====================================
      # 全体チャットメッセージ
      def cs_message(msg)
        if @avatar_name
          SERVER_LOG.info("<UID:#{@uid}>ChatServer: [message get] #{@avatar_name}, #{msg.force_encoding("UTF-8")}")
          online_list.each_value{ |v| v.sc_send_message("#{@avatar_name}:#{msg.force_encoding("UTF-8")}",0) if v}
        end
      end

      # ルームチャットメッセージ
      def cs_message_room(msg)
        if @avatar_name
          SERVER_LOG.info("<UID:#{@uid}>ChatServer: [rroom message get] #{@avatar_name}, #{msg.force_encoding("UTF-8")}")
          online_list.each_value{ |v| v.sc_send_message("#{@avatar_name}:#{msg.force_encoding("UTF-8")}",1)if v}
        end
      end

      # チャンネルチャットメッセージ
      def cs_message_channel(msg,channel_id = 0)
        if @avatar_name
          SERVER_LOG.info("<UID:#{@uid}>ChatServer: [channel message get] #{@avatar_name} #{msg.force_encoding("UTF-8")} : #{channel_id}")
          if channel_id < channel_list.size
            channel_list[channel_id].each_value{ |v| v.sc_send_channel_message(0, "#{@avatar_name}:#{msg.force_encoding("UTF-8")}")if v}
          end
        end
      end

      # デュエルチャットメッセージ
      def cs_message_duel(msg,id)
        if @avatar_name
          SERVER_LOG.info("<UID:#{@uid}>ChatServer: [duel message get] #{@avatar_name} #{msg.force_encoding("UTF-8")}")
          a = online_list[id]
          SERVER_LOG.debug("<UID:#{@uid}>ChatServer: [duel message mumumu] #{a}, #{@player}")
          if a&&@player
            a.sc_send_duel_message(@player.id,"#{@avatar_name}:#{msg.force_encoding("UTF-8")}")
            sc_send_duel_message(@player.id,"#{@avatar_name}:#{msg.force_encoding("UTF-8")}")
            channel_list[CHAT_CHANNEL_DUEL].each_value{ |v| v.sc_send_channel_message(0, "#{@avatar_name}:#{msg.force_encoding("UTF-8")}")if v}
          end
        end
      end

      # 観戦者チャットメッセージ
      def cs_message_audience(msg)
        if @avatar_name && @watch_room_id
          SERVER_LOG.info("<UID:#{@uid}>ChatServer: [audience message get] #{@avatar_name} #{msg.force_encoding("UTF-8")} : #{@watch_room_id}")
          channel_list[CHAT_CHANNEL_WATCH][@watch_room_id].each_value{ |v|
            v.sc_send_audience_message(0, "#{@avatar_name}:#{msg.force_encoding("UTF-8")}")if v
          }
        end
      end

      # チャットチャンネルにログイン
      def cs_channel_in(id)
        channel_in(id)
      end

      # チャットチャンネルにログアウト
      def cs_channel_out(id)
        # 全部のチャンネルから抜ける
        channel_all_out()
      end

      # 観戦者チャットチャンネルにログイン
      def cs_audience_channel_in(room_id)
        audience_channel_in(room_id)
      end

      # 観戦者チャットチャンネルにログアウト
      def cs_audience_channel_out
        audience_channel_out(@watch_room_id)
      end

      def pushout()
        if @player
          online_list[@player.id].logout
        end
     end

      def do_login
        if @player
          @avatar_name = @player.avatars[0].name
          @avatar_name.force_encoding("UTF-8");
        end
        # ログインと同時にチャンネル０に入る(仮：本当はチャンネルにはいったときに切り換える)
        channel_in(0)
      end


      def do_logout
        # ログアウトと同時にチャンネル０からでる
        channel_all_out if @player
      end

      def channel_in(id)
        if id < channel_list.size
          channel_all_out
          channel_list[id][@player.id] = online_list[@player.id] if @player
          sc_send_channel_message(id, @avatar_name + CHAT_START_DLG_1+ CHAT_CHANNEL_NAME[id]+ CHAT_START_DLG_2 + CHAT_START_DLG_3 + channel_list[id].size.to_s + CHAT_START_DLG_4) if id < CHAT_CHANNEL_DUEL if @avatar_name

        end
      end

      def channel_out(id)
        # ログアウトと同時にチャンネル０からでる
        SERVER_LOG.debug("<UID:#{@uid}>ChatServer: [channel_list out a]#{@player}")
        if id < channel_list.size
          channel_list[id].delete(@player.id) if @player
        end
        SERVER_LOG.debug("<UID:#{@uid}>ChatServer: [channel_list out b]#{@player}")
      end

      def audience_channel_in(room_id)
        if room_id && room_id != ""
          SERVER_LOG.debug("<UID:#{@uid}>ChatServer: [audience_channel_in] #{room_id}")
          if @player
            @watch_room_id = room_id
            channel_list[CHAT_CHANNEL_WATCH][room_id] = { } unless channel_list[CHAT_CHANNEL_WATCH][room_id]
            channel_list[CHAT_CHANNEL_WATCH][room_id][@player.id] = online_list[@player.id] if @player
          end
        end
      end

      def audience_channel_out(room_id)
        if room_id && room_id != ""
          SERVER_LOG.debug("<UID:#{@uid}>ChatServer: [audience_channel_out] #{room_id}")
          if channel_list[CHAT_CHANNEL_WATCH].key?(room_id)
            channel_list[CHAT_CHANNEL_WATCH][room_id].delete(@player.id) if @player
            channel_list[CHAT_CHANNEL_WATCH].delete(room_id) if channel_list[CHAT_CHANNEL_WATCH][room_id].size <= 0
            @watch_room_id = nil
          end
        end
      end

      def channel_all_out
        channel_list.each_index do |i|
          if i != CHAT_CHANNEL_WATCH
            channel_out(i)
          else
            audience_channel_out(@watch_room_id) if @watch_room_id
          end
        end
      end

    end

end
