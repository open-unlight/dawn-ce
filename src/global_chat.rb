# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'optparse'
require 'rubygems'
require 'eventmachine'

module Unlight
  port = 12020
  id = 0
  # 引数がある場合にポートを変更する
  opt = OptionParser.new

  opt.on('-p VAL') {|v|
    SV_PORT = v }

  opt.parse! ARGV
  $SERVER_NAME = "GLOBAL_CHAT_SV#{SV_PORT}"
  begin
    SV_IP = `wget -q -O - ipcheck.ieserver.net -T=3`
  rescue =>e
    SERVER_LOG.fatal("GlobalChatServer:IP 未設定")
  end


end
require 'unlight'
require 'protocol/globalchatserver'

module Unlight
  include Protocol

  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    GlobalChatServer.setup
    EM.start_server "0.0.0.0", SV_PORT, GlobalChatServer
    SERVER_LOG.info("GlobalChatServer Start: ip[#{SV_IP}] port[#{SV_PORT}]")
    # タイマの制度を上げる
    EM.set_quantum(10)
    # 1/24でメインループを更新
    EM::PeriodicTimer.new(RAID_HELP_SEND_TIME, proc {
                            begin
                              GlobalChatServer.sending_help_list
                            rescue =>e
                              SERVER_LOG.fatal("GlobalChatServer: [sending_help_list:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              GlobalChatServer.check_connection
                            rescue =>e
                              SERVER_LOG.fatal("GlobalChatServer: [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                                   })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                GlobalChatServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("GlobalChatServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end

    if PRF_AUTO_CREATE_EVENT_FLAG
      EM::PeriodicTimer.new(PRF_AUTO_CREATE_INTERVAL, proc {
                              begin
                                GlobalChatController::auto_create_prf
                              rescue =>e
                                SERVER_LOG.fatal("GlobalChatServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })

      EM::PeriodicTimer.new(PRF_AUTO_HELP_INTERVAL, proc {
                              begin
                                GlobalChatController::auto_prf_send_help
                              rescue =>e
                                SERVER_LOG.fatal("GlobalChatServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end
