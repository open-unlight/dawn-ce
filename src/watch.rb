# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'optparse'
require 'rubygems'
require 'eventmachine'

module Unlight
  # 引数がある場合にポートを変更する
  port = 12004
  id = 0
  opt = OptionParser.new

  opt.on('-p VAL') {|v|
    SV_PORT = v }

  opt.on('-i VAL') {|v|
    $SV_ID = v }

  opt.parse! ARGV

  $SERVER_NAME = "WATCH_SV#{SV_PORT}"

  begin
    SV_IP = "0.0.0.0"
  rescue =>e
    SERVER_LOG.fatal("WatchServer:IP 未設定")
  end

end

require 'unlight'
require 'protocol/watchserver'

module Unlight
  include Protocol

  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    WatchServer.setup($SV_ID, SV_IP, SV_PORT)
    EM.start_server "0.0.0.0", SV_PORT, WatchServer
    SERVER_LOG.info("WatchServer Start: ip[#{SV_IP}] port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)
    start_time =Time.now
    tmp_time =Time.now
    # 1/24でメインループを更新
    EM::PeriodicTimer.new(1, proc {
                            begin
                              WatchServer::all_duel_update
                            rescue =>e
                              SERVER_LOG.fatal("WatchServer: [DUEL:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              WatchServer.check_connection
                            rescue =>e
                              SERVER_LOG.fatal("WatchServer [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                WatchServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("WatchServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end
