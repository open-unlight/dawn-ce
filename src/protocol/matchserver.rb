# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'protocol/ulserver'
require 'protocol/command/command'
require 'controller/match_controller'

include Unlight
module Protocol
  class MatchServer < ULServer
    include MatchController


    attr_accessor :player, :matching, :opponent_player

    # クラスの初期化
    def self::setup(id, ip, port)
      super()
      # コマンドクラスをつくる
      @@receive_cmd=Command.new(self,:Match)
      @@server_channel = nil
       unless self::server_channel
         SERVER_LOG.fatal("#{@@class_name}: not regist Channel!!")
       end
      # コネクションチェック時の分割リスト
      set_check_split_list
      MatchController::init
    end

    # 切断時
    def unbind
      # 例外をrescueしないとAbortするので注意
      begin
        if @player
          delete_connection
          logout
        end
      rescue =>e
        puts e.message
      end
      SERVER_LOG.info("#{@@class_name}: Connection unbind >> #{@ip}")
    end

    def online_list
      @@online_list
    end

    def self::match_list
      @@online_list
    end
    def self::radder_match_update
     MatchController::radder_match_update
    end
    def self::check_boot
     MatchController::check_boot(server_channel)
    end

      # サーバを終了する
    def self::exit_server
      # 自分のチャンネルのステートをOFFにする
      self::server_channel.shut_down
      super
    end

    def self::server_channel
      unless @@server_channel
        @@server_channel = Channel.filter(:host=>SV_IP,:port=>SV_PORT).all.first
        @@server_channel.boot if @@server_channel
      end
      @@server_channel
    end

    def server_channel
      MatchServer::server_channel
    end

    def self::match_channel
     @@server_channel
    end

    def self::update_login_count
      @@server_channel.update_count
    end

  end
end
