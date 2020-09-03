# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'protocol/ulserver'
require 'protocol/command/command'
require 'controller/raid_chat_controller'

module Unlight
  module Protocol
    class RaidChatServer < ULServer
      include RaidChatController

      attr_accessor :player,:avatar

      # クラスの初期化
      def self.setup
        super
        # コマンドクラスをつくる
        @@receive_cmd=Command.new(self,:RaidChat)
      end

      def online_list
        @@online_list
      end

      # 切断時
      def unbind
        # 例外をrescueしないのAbortするので注意
        begin
           if @player
             logout
             @player = nil
           end
        rescue =>e
          puts e.message
        end
        SERVER_LOG.info("#{@@class_name}: Connection unbind >> #{@ip}.player#{@player.id}") if @player
      end

    end
  end
end
