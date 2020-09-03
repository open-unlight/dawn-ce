# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'protocol/ulserver'
require 'protocol/command/command'
require 'controller/global_chat_controller'

module Unlight
  module Protocol
    class GlobalChatServer < ULServer
      include GlobalChatController

      attr_accessor :player

      # クラスの初期化
      def self.setup
        super
        # コマンドクラスをつくる
        @@receive_cmd=Command.new(self,:GlobalChat)
        @@online_list = { };      # オンラインのリストIDとインスタンスのハッシュ
        GlobalChatController::init
      end

      def online_list
        @@online_list
      end

      def self::sending_help_list
        GlobalChatController.sending_help_list
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
