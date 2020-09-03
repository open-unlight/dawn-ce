# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

# 各サーバクラスの親
require 'net/crypt'
require File::expand_path(__FILE__).gsub(/src\/protocol\/ulserver.rb/, "")+"script/constdata_keys.rb"

module Unlight
  module Protocol
    class ULServer < EventMachine::Connection

      # これ以上前に反応していなかった切る
      CONNECT_LIVE_SEC = 3600   # 1時間

      # 何回のコマンドエラーで切断するか
      COMMAND_ERROR_MAX = 3   #

      attr_accessor :player,:last_connect
      # クラスの初期化
      def self.setup
        @@class_name = self.name[19..-1] # 最後のクラス名だけにしている
        SERVER_LOG.info("#{@@class_name}: Start.")
        @@receive_cmd = nil
        @@online_list = { };      # オンラインのリストIDとインスタンスのハッシュ
        @@check_list = Array.new(60){[]} # ソケットのハートビートを60分にいっぺん送るためのリスト
        @check_min                       # 自分が何処に入っているか？
        @error_count = 0                 # 無効なコマンドが送られてきた数
        @db_connect_prev_check_time = nil # 前回のDBとの接続チェック時間
        # 終了のシグナルを受け取った場合
        Signal.trap(:TERM){exit_server}
      end

      # 接続時
      def post_init
        @error_count = 0                 # 無効なコマンドが送られてきた数
        @uid = 0
        # IPを保存
        @ip = ""
        begin
          @ip = get_peername[2 ,6].unpack("nC4")[1..4].join"." if get_peername&&get_peername[2 ,6].unpack("nC4")# 帰ってこない場合あり
        rescue =>e
          SERVER_LOG.fatal("#{@@class_name}: [Got invalid IP] #{e}")
          @ip = "0.0.0.0"
        end
        SERVER_LOG.info("#{@@class_name}: [Connected IP:] #{@ip}")
        @crypt = Crypt::None.new
        @command_list =[]
        @func_list = []
        @@receive_cmd.method_list.each do |c|
          @func_list << method(c)
        end
      end

      # データの受信
      def receive_data data
        a = data2command(data)
        @command_list += a unless a.empty?
        do_command
      end

      # 切断時
      def unbind
        SERVER_LOG.info("#{@@class_name}: [Connection close] #{@ip}")
      end

      # セッションキーを設定して暗号化をONにする
      def set_session_key(sID)
        @crypt = Crypt::XOR.new(sID)
      end

      # セッションキーを解除して暗号化をOFFにする
      def clear_session_key
        @crypt = Crypt::None.new
      end

      # コマンドの実行
      def do_command
        while cmd =@command_list.shift
          if cmd[0] > @func_list.size
            SERVER_LOG.error("#{@@class_name}: [invalid comanndNo.] >> #{cmd[0]}")
            # エラー数をカウントして
            if @error_count > COMMAND_ERROR_MAX
              SERVER_LOG.error("#{@@class_name}: [ErrorMAX disconnect!] >> #{cmd[0]}")
              logout
            else
              @error_count +=1
            end
          else
            begin
              @func_list[cmd[0]].call(cmd[1])
            rescue =>e
              SERVER_LOG.fatal("#{@@class_name}: [docommand:] fatal error #{e}:#{e.backtrace}")
            end
          end
        end
      end

      # コマンドから受信メソッドの配列に登録する
      def init_revceive_command(cmd)
        cmd.each{ |c| @command_method << method(c[0])}
      end


      # データを送る
      def send_data(data)
        d = [data.size].pack('N')
        d << @crypt.encrypt(data)
        d << "\n"
        super(d)
      end


      # 受信コマンド
      # データ形式は
      # ---- Header ------
      # :2byte(lentgh)
      # :2byte(Type)
      # ---- Body -------
      # ---- Tail: -----
      # :2byte(end_marker)

      def data2command(data)
        a = []
        i = 0
        len =0
        # 総サイズを記録
        d_size = data.bytesize
        # 総サイズ分読み込む
        while i < d_size
          # 最初の2バイトを呼んで長さに変換
          len = data[i,2].unpack("n*")[0]
          # もしサイズが０ならば全サイズが長さ,またはnilならば全サイズを入れる（とばすため）
          len = d_size if len == 0||len ==nil
          # 長さの後ろに改行が入っているか？（正しいコマンドかをチェック）
          if data[i+len+2] == "\n"
            d = @crypt.decrypt(data[i+2,len])
            a << [d[0,2].unpack('n')[0], d[2..-1]]
          end
          i += (len+3)
        end
        a
      end

      def method_missing(msg, *arg)
         SERVER_LOG.warn("#{@@class_name}:Command [#{msg}] is Undefined")
      end

    # 子クラスが使用する汎用関数

      # ネゴシエーション（認証済みかを確認）
      def negotiation(id)
        SERVER_LOG.debug("<UID:#{id}>#{@@class_name}: [nego start]")
        begin
          @player = Player[id]
          # 認証済みか
          if @player && @player.login?
            @uid = id
            SERVER_LOG.debug("<UID:#{id}>#{@@class_name}: [login start]")
            # ネゴシエーション用のサインを作る
            @nego_crypt = rand(10000).to_s
            # 暗号化をON
            if BOT_SESSION
              set_session_key(BOT_SESSION_KEY)
            else
              set_session_key(@player.session_key)
            end
            # ネゴシエーションの確認
            nego_cert(@nego_crypt ,"are you ok")
          else
            f_id = 0
            f_id = @player.id if @player
            SERVER_LOG.fatal("<UID:#{id}>#{@@class_name}: [negotiatin fail] :#{f_id}")
            close_connection
            # 不正なアクセスなどをはじく処理
          end
        rescue =>e
          SERVER_LOG.fatal("#{@@class_name}: [negotiatin fatal error] #{e}")
        end
      end

      # ログイン（認証済みであればログイン）
      def login(ok, crypted_sign)
        if @nego_crypt == crypted_sign
          # ログイン済みの場合押し出し処理を行う
          if @player&&@@online_list.include?(@player.id)
            SERVER_LOG.info("<UID:#{@player.id}>#{@@class_name}: [login push out] pushed out")
            pushout
          end
          if @player
            regist_connection
            login_cert(CONSTDATA_ENCRYPTKEY, IMAGEFILE_HASHKEY)
            do_login
          end
        else
          SERVER_LOG.error("#{@@class_name}:[login] fail. not sign confirm.")
          login_fail
          close_connection
        end
      end

      # ログアウト
      def logout()
        if @player
          delete_connection
          do_logout
          SERVER_LOG.info("<UID:#{@player.id}>#{@@class_name}: [LogOut] #{@ip}")
          @player = nil
        end
        close_connection
      end

      def delete_connection
        @@online_list.delete(@player.id) if @player
        @@check_list[@check_min].delete(self) if @check_min
      end

      def regist_connection
        t = Time.now.min
        @check_min = t
        @last_connect = Time.now
        @@check_list[t] << self
        @@online_list[@player.id] = self if @player
      end


      # サーバを終了する
      def self::exit_server
        @@online_list.clone.each_value{|o| o.logout if o}
        SERVER_LOG.fatal("#{@@class_name}: [ShutDown!]")
        exit
      end

      # KeepAlibe信号を返す
      def cs_keep_alive
        sc_keep_alive
        @last_connect = Time.now
        SERVER_LOG.info("<UID:#{@uid}> #{@@class_name} : KeepAlive! #{@last_connect}")
      end

      # コネクションをチェックする分割リストを取得
      def self::set_check_split_list
        @@check_connect_split_list = []
        split_num = 60 / GAME_CHECK_CONNECT_INTERVAL
        60.times do |num|
          idx = num / split_num
          @@check_connect_split_list[idx] = [] unless @@check_connect_split_list[idx]
          @@check_connect_split_list[idx] << num
        end
      end

      # コネクションが生きているか、サーバがらインターバルごとチェックする
      def self::check_connection
        t = Time.now.min
        @@check_list[t].clone.each { |s|
          s.sc_keep_alive
          SERVER_LOG.info("<UID:#{s.player.id}>#{@@class_name}: [keep alive go]") if s.player
        }
        SERVER_LOG.info("#{@@class_name}: [Login Num] #{@@online_list.length}")
      end

      # コネクションが生きているか、サーバがらインターバルごとチェックする(秒チェック版)
      def self::check_connection_sec
        time_now = Time.now
        t = time_now.sec
        check_idx_list = nil
        @@check_connect_split_list.each { |l|
          if l.index(t)
            check_idx_list = l
            break
          end
        }
        check_idx_list.each do |idx|
          @@check_list[idx].clone.each { |s|
            s.sc_keep_alive
            # 最終接続チェック時が設定されていない、最終接続から3分以上経過している場合、切断処理を行う
            if s.last_connect == nil || s.last_connect < time_now - GAME_CHECK_CONNECT_TIME_INTERVAL
              SERVER_LOG.info("<UID:#{s.player.id}>#{@@class_name}: [unbind] last_connect:#{s.last_connect}") if s.player
              s.unbind
            end
            SERVER_LOG.info("<UID:#{s.player.id}>#{@@class_name}: [keep alive go] now:#{time_now}") if s.player
          }
        end
        SERVER_LOG.info("#{@@class_name}: [Login Num] #{@@online_list.length}")
      end

      # ユーザがいない場合、MySQLとのコネクションが切れないようアクセスをしておく
      def self::check_db_connection
        if @@online_list.size <= 0
          # CPUのPlayerデータを取るだけ
          cpu_player = Player[AI_PLAYER_ID]
          SERVER_LOG.info("#{@@class_name}: [#{__method__}] prev check time:#{@db_connect_prev_check_time}")
          @db_connect_prev_check_time = Time.now.utc
        end
      end

    end
  end
end

if RUBY_VERSION  == "1.9.2"
#  Dateクラスで重たいmethod_missingを差し替え（クソ重たい処理をクソさぼっているので）
  class Date::Format::Bag
    def method_missing(t, *args, &block)
      t = t.to_s
      set = t.chomp!('=')
      t = t.intern
      ret = nil
      if set
        ret = @elem[t] = args[0]
      else
        ret = @elem[t]
      end
      ret
    end

    def year=(v)
      @elem[:year] = v
    end

    def mon=(v)
      @elem[:mon] = v
    end

    def mday=(v)
      @elem[:mday] = v
    end

    def hour=(v)
      @elem[:hour] = v
    end

    def min=(v)
      @elem[:min] = v
    end

    def sec=(v)
      @elem[:sec] = v
    end

    def _comp=(v)
      @elem[:_comp] = v
    end

    def sec_fraction=(v)
      @elem[:sec_fraction] = v
    end

    def offset=(v)
      @elem[:offset] = v
    end

    def zone=(v)
      @elem[:zone] =v
    end

    def year
      @elem[:year]
    end

    def mon
      @elem[:mon]
    end

    def mday
      @elem[:mday]
    end

    def hour
      @elem[:hour]
    end

    def min
      @elem[:min]
    end

    def sec
      @elem[:sec]
    end

    def sec_fraction
      @elem[:sec_fraction]
    end

    def zone
      @elem[:zone]
    end

    def _comp
      @elem[:_comp]
    end

    def offset
      @elem[:offset]
    end

  end
end
