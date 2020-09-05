# Unlight
# Copyright (c) 2019 CPA
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'optparse'
require 'rubygems'
require 'eventmachine'

module Unlight
  port = 12070
  id = 0
  # 引数がある場合にポートを変更する
  opt = OptionParser.new

  opt.on('-p VAL') { |v|
    SV_PORT = v
}

  opt.parse! ARGV

  SV_IP = ENV['HOSTNAME']
  $SERVER_NAME = "RAIDRANK_SV#{SV_PORT}"
end

require 'unlight'
require 'protocol/raidrankserver'

module Unlight
  include Protocol

  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    RaidRankServer.setup
    EM.start_server "0.0.0.0", SV_PORT, RaidRankServer
    SERVER_LOG.info("RaidRankServer Start: ip[#{SV_IP}] port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)
    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              RaidRankServer.check_connection
                            rescue => e
                              SERVER_LOG.fatal("RaidRankServer: [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60 * 60 * 7, proc {
                              begin
                                RaidRankServer.check_db_connection
                              rescue => e
                                SERVER_LOG.fatal("RaidRankServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end
