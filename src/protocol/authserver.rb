# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'protocol/ulserver'
require 'protocol/command/command'
require 'net/srp'

module Unlight
  module Protocol
    class AuthServer < ULServer

      # クラスの初期化
      def self.setup
        super
        Player.auth_off_all
        # コマンドクラスをつくる
        @@receive_cmd=Command.new(self,:Auth)
        # 暗号化クラスを作る
        @@srp = SRP.new()
        @@invited_id_set = []
      end

      # ======================================
      # 受信コマンド
      # =====================================

      # プレイヤーを登録
      def register(name, email, salt, verifire, server_type)
        SERVER_LOG.info("#{@@class_name}: [register] #{name} ,#{salt}, #{verifire}, #{server_type}")
        regist_result(Player.regist(name, email, salt, verifire, server_type))
      end

      # IDからソルトとサーバ公開鍵を返す
      def auth_start(name, client_pub_key)
        # 人数制限チェック
        if SERVER_USER_LIMIT > 0 && @@online_list.size >= SERVER_USER_LIMIT
          SERVER_LOG.error("#{@@class_name}: [auth_fail] user limit over")
          auth_user_limit
        else
          # 認証のスタート
          SERVER_LOG.info("#{@@class_name}: [auth_start] #{name} ,#{client_pub_key} ,#{@@online_list.size}")
          # プレイヤーは登録されているか？
          if @player = Player[:name=>name]
            if @player.penalty?
              # ペナルティではじく
              SERVER_LOG.error("#{@@class_name}: [auth_fail] penalty #{name}")
              sc_error_no(ERROR_LOCK_ACOUNT)
            else
              # 現在認証中
              if @player.auth?
                # エラーを出してはじく
                SERVER_LOG.error("#{@@class_name}: [auth_fail] already Authed #{@player.name}")
                # 失敗のコマンドを送信
                auth_fail
              else
                # 認証中にして認証処理を進める
                @player.auth_on
                @salt = @player.salt
                @rnd =@@srp.rand_hex
                @c_pub = client_pub_key
                @pub = @@srp.get_server_public_key(@rnd, @player.verifier )
                SERVER_LOG.info("#{@@class_name}: [auth_return] #{@salt},#{@pub}")
                auth_return(@salt, @pub)
              end
            end
          else
            # 未登録で認証失敗
            SERVER_LOG.error("#{@@class_name}: [auth_fail] no registration  #{name}")
            auth_fail
          end
        end

      end

      # 認証の判定を行う
      def auth_get_matcher(matcher)
        sess = @@srp.get_session_key(@c_pub, @pub, @player.verifier, @rnd)
        @strong_key = @@srp.get_strong_key(sess)
        m = @@srp.get_matcher(@c_pub, @pub, @player.name, @salt, @strong_key)
        # 認証に成功

        if matcher == m
          # 現在の状態は？
          if @player.auth?
            # 認証中なら
            cert(m)
          else
            SERVER_LOG.info("#{@@class_name}: [auth_fail] no Auth #{@player.name}")
            auth_fail
          end
        else
          # 認証に失敗（パスワードが異なる
          SERVER_LOG.info("#{@@class_name}: [auth_fail] wrong pass #{@player.name}")
          @player.pass_failed
          # 再レジスト要求
          sc_request_reregist
        end
      end


      # OpenSocial用Auth
      def cs_open_social_auth(name, client_pub_key)
        # 認証のスタート
        SERVER_LOG.info("#{@@class_name}: [cs_os_auth_start] #{name} ,#{client_pub_key}")
        # プレイヤーは登録されているか？
        if @player = Player[:name=>name]
          if @player.penalty?
            # ペナルティではじく
            SERVER_LOG.error("#{@@class_name}: [cs_os_auth_fail] penalty #{name}")
            sc_error_no(ERROR_LOCK_ACOUNT)
          else
            # 現在認証中
            if @player.auth?
              # エラーを出してはじく
              SERVER_LOG.error("#{@@class_name}: [cs_os_auth_fail] already Authed #{@player.name}")
              # 失敗のコマンドを送信
              auth_fail
              @player.auth_off
            else
              # 認証中にして認証処理を進める
              @player.auth_on
              @salt = @player.salt
              @rnd =@@srp.rand_hex
              @c_pub = client_pub_key
              @pub = @@srp.get_server_public_key(@rnd, @player.verifier )
              SERVER_LOG.info("#{@@class_name}: [cs_os_auth_return] #{@salt},#{@pub}")
              auth_return(@salt, @pub)
            end
          end
        else
          SERVER_LOG.info("#{@@class_name}: [sc_open_social_not_regist] #{name} ,#{client_pub_key}")
          sc_open_social_not_regist
        end
      end

      # OpenSocialプレイヤーを登録
      def cs_open_social_register(name, salt, verifire, server_type)
        SERVER_LOG.info("#{@@class_name}: [cs_os_register] #{name} ,#{salt}, #{verifire}, #{server_type}")
        regist_result(Player.regist(name, "openplatform@dena.jp", salt, verifire, server_type))
      end

      # OpenSocial用再登録
      def cs_reregister(name, salt, verifire, server_type)
        SERVER_LOG.info("#{@@class_name}: [cs_os_reregister] #{name} ,#{salt}, #{verifire}")
        Player.reregist(name, "openplatform@dena.jp", salt, verifire, server_type)
      end

      # 自分を招待してくれたひとを更新
      def cs_update_invited_user(users)
        u =users.split(",")
        if @player
          SERVER_LOG.info("<UID:#{@player.id}>AUTHServer: [cs_update_invited_users] #{users}")
          a = InviteLog::check_already_invited?(@player.name) # すでに自分がインバイトアイテムをもらっているか？
          t = @player.update_invited_users(u)
        end
      end

      # 自分を招待してくれたひとを更新
      def cs_update_tuto_play(t)
        if @player
          SERVER_LOG.info("<UID:#{@player.id}>AUTHServer: [cs_update_tute_play] #{t}")
          @player.update_played_tutorial(t)
        end
      end

      # ===============================================================
      # 送信コマンド
      # ===============================================================

      # クライアントへ確認コマンドを送る
      def cert(m)
        SERVER_LOG.info("#{@@class_name}: [auth_cert] #{@player.name}")
        auth_cert(@@srp.get_cert(@c_pub,m,@strong_key),@player.id)
        @player.login(@ip, @strong_key)
        if @@online_list.include?(@player.id)
          SERVER_LOG.info("<UID:#{@player.id}>#{@@class_name}: [login push out] pushed out")
          pushout
        end
        if @player
          regist_connection
        end
      end

      # 押し出し関数
      def pushout()
        @@online_list[@player.id].sc_error_no(ERROR_DOUBLE_LOGIN)
        @@online_list[@player.id].player.logout(true)
        @@online_list[@player.id].sc_keep_alive # Zombieだったらここで切れる
        @@online_list[@player.id].player = nil
      end


      # 切断時
      def unbind
        # 例外をrescueしないのAbortするので注意
        begin
           if @player
             @player.auth_off
             @player.logout
             delete_connection
             SERVER_LOG.info("#{@@class_name}: [online num] #{@@online_list.size}")
           end
        rescue =>e
            puts e.message
        end
       SERVER_LOG.info("#{@@class_name}: Connection unbind >> #{@ip}")
      end

      # サーバを終了する
      def self::exit_server
        Player.auth_off_all
        Player.logout_all
        SERVER_LOG.fatal("#{@@class_name}: ShutDown!")
        exit
      end
    end
  end
end
