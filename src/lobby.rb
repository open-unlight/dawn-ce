# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'optparse'
require 'rubygems'
require 'eventmachine'

module Unlight
  port = 12003
  id = 0
  # 引数がある場合にポートを変更する
  opt = OptionParser.new

  opt.on('-p VAL') {|v|
    SV_PORT = v }

  opt.parse! ARGV
  $SERVER_NAME = "LOBBY_SV#{SV_PORT}"

  begin
    SV_IP = "0.0.0.0"
  rescue =>e
    SERVER_LOG.fatal("GameServer:IP 未設定")
  end

end
require 'unlight'
require 'protocol/lobbyserver'

module Unlight
  include Protocol

  port = 12002
  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    LobbyServer.setup
    EM.start_server "0.0.0.0", SV_PORT, LobbyServer
    SERVER_LOG.info("LobbyServer Start: port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)

    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              LobbyServer.check_connection
                            rescue =>e
                              SERVER_LOG.fatal("LobbyServer: [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                LobbyServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("LobbyServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end


