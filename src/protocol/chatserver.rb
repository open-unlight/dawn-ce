# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'protocol/ulserver'
require 'protocol/command/command'
require 'controller/chat_controller'

module Unlight
  module Protocol
    class ChatServer < ULServer
      include ChatController

      attr_accessor :player,:avatar_name

      # クラスの初期化
      def self.setup
        super
        # コマンドクラスをつくる
        @@receive_cmd=Command.new(self,:Chat)
        @@online_list = { };      # オンラインのリストIDとインスタンスのハッシュ
        @@channel_list = []

        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
        @@channel_list.push({ })
      end

      # チャンネルからプレイヤーを出す
      def self.channel_in_player(channel_id, player_id)
        @@channel_list[channel_id][player_id] = @@online_list[player_id]
      end


      def self.channel_out_player(channel_id,player_id)
        @@channel_list[channel_id].delete(player_id)
      end

      def online_list
        @@online_list
      end

      def channel_list
        @@channel_list
      end


      # 切断時
      def unbind
        # 例外をrescueしないのAbortするので注意
        begin
           if @player
             logout
           end
        rescue =>e
            puts e.message
        end
        SERVER_LOG.info("#{@@class_name}: Connection unbind >> #{@ip}.player#{@player.id}") if @player
      end

    end
  end
end
