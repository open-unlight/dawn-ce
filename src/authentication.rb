# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

$:.unshift File.expand_path(File.dirname(__FILE__))
require 'rubygems'
require 'eventmachine'


module Unlight
  # 引数がある場合にポートを変更する
  $SV_PORT = 12001
  id = 0
  opt = OptionParser.new

  opt.on('-p VAL') {|v|
    $SV_PORT = v }
  opt.parse! ARGV

  $SERVER_NAME = "AUTH_SV#{$SV_PORT}"

  begin
    SV_IP = `wget -q -O - ipcheck.ieserver.net -T=3`
  rescue =>e
    SERVER_LOG.fatal("GameServer:IP 未設定")
  end

end

require 'unlight'
require 'protocol/authserver'


module Unlight
  include Protocol

  EM.set_descriptor_table_size(10000) # ソケットMaxを設定
  EM.epoll                            # Epollを使用するように設定。
  EM.run do
    AuthServer.setup
    EM.start_server "0.0.0.0", $SV_PORT, AuthServer
     SERVER_LOG.info("AuthServer Start: ip[#{SV_IP}] port[#{$SV_PORT}]")
     EM.set_quantum(10)                # タイマの制度を上げる

    # 1分に一回でソケットの生き死にをチェック
    EM::PeriodicTimer.new(60, proc {
                            begin
                              AuthServer.check_connection
                            rescue =>e
                              SERVER_LOG.fatal("AuthServer: [check_connection:] fatal error #{e}:#{e.backtrace}")
                            end
                          })

    if DB_CONNECT_CHECK
      # 7時間に一回でDBとの接続をチェック
      EM::PeriodicTimer.new(60*60*7, proc {
                              begin
                                AuthServer.check_db_connection
                              rescue =>e
                                SERVER_LOG.fatal("AuthServer: [check_db_connection:] fatal error #{e}:#{e.backtrace}")
                              end
                            })
    end
  end
end
