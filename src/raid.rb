# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'

module Unlight
  # 引数がある場合にポートを変更する
  opt = OptionParser.new
  opt.on('-p VAL') {|v|
    SV_PORT = v }

  opt.parse! ARGV

  SV_PORT = 12050 unless SV_PORT
  $SERVER_NAME = "RAID_SV#{SV_PORT}"
end
require 'unlight'
require 'protocol/raid_server'


module Unlight
  include Protocol

  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    RaidServer.setup
    EM.start_server "0.0.0.0", SV_PORT, RaidServer
    SERVER_LOG.info("RaidServer Start: port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)
    start_time =Time.now
    tmp_time =Time.now
    # 1/24でメインループを更新
    EM::PeriodicTimer.new(0.3, proc {
                            begin
                              MultiDuel.update
                            rescue =>e
                              SERVER_LOG.fatal("RaidServer: [RAID:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    # 1/10でAIループを更新
    EM::PeriodicTimer.new(1, proc {
                            begin
                              AI.update
                            rescue =>e
                             SERVER_LOG.fatal("RaidServer: [AI:] fatal error #{e}:#{e.backtrace}")
                            end
                          })

    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              RaidServer.check_connection
                            rescue =>e
                             SERVER_LOG.fatal("RaidServer: [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                RaidServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("RaidServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end


