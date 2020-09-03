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

  $SERVER_NAME = "MATCHING_SV#{SV_PORT}"

  begin
    SV_IP = "0.0.0.0"
  rescue =>e
    SERVER_LOG.fatal("GameServer:IP 未設定")
  end


end

require 'unlight'
require 'protocol/matchserver'

module Unlight

  @@current_time = 0

  include Protocol
  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    MatchServer.setup($SV_ID,SV_IP,SV_PORT)
    EM.start_server "0.0.0.0", SV_PORT, MatchServer
    SERVER_LOG.info("MatchServer Start: port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)
    start_time =Time.now
    tmp_time =Time.now
    # 1/24でメインループを更新
    EM::PeriodicTimer.new(CPU_POP_TIME, proc {
                            begin
                              h = Time.now.utc.hour
                              if @@current_time != h
                                c = CPU_SPAWN_NUM[h]
                                c.times { MatchController.cpu_room_update }
                                @@current_time = h
                              end
                            rescue =>e
                              SERVER_LOG.fatal("MatchServer: [MATCH:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })
    # 1分に一回で起動・停止判定をチェック、ログイン人数の更新
    EM::PeriodicTimer.new(60, proc {
                            begin
                              MatchServer.check_boot
                              MatchServer.update_login_count
                            rescue =>e
                             SERVER_LOG.fatal("MatchServer [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })
    # 1分の間に、定数で指定した回数、ソケットの生き死にをチェック
    EM::PeriodicTimer.new(60/GAME_CHECK_CONNECT_INTERVAL, proc {
                            begin
                              MatchServer.check_connection_sec
                            rescue =>e
                             SERVER_LOG.fatal("MatchServer [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })
    # 5秒に一回ラダーマッチのマッチングを行う
    EM::PeriodicTimer.new( 5, proc {
                            begin
                              MatchServer.radder_match_update
                            rescue =>e
                             SERVER_LOG.fatal("MatchServer [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })
    # RadderMatchにCPUでメインループを更新
    EM::PeriodicTimer.new(RADDER_CPU_POP_TIME, proc {
                            begin
                              MatchController.cpu_radder_match_update if RADDER_CPU_POP_ENABLE && rand(RADDER_CPU_POP_RAND) == 0
                            rescue =>e
                              SERVER_LOG.fatal("MatchServer: [MATCH:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                MatchServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("MatchServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end
