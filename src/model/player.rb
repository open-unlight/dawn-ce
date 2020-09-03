# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # プレイヤークラス
  class Player < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    one_to_many :avatars

    # 送受信コマンドのスタック
    attr_accessor :send_commamd, :receive_command


    Sequel::Model.plugin :schema
    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :index=>true, :unique=>true
      String      :email
      varchar     :salt, :limit => 64
      varchar     :verifier, :limit => 64
      integer     :role, :default => 0
      integer     :state, :default => 0
      integer     :game_session
      datetime    :login_at
      datetime    :logout_at
      integer     :total_time, :default => 0
      String      :last_ip
      String      :data_ver
      integer     :penalty, :default => 0
      String      :session_key, :limit => 64
      integer     :tutorial, :default => 0
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
       uniqueness_of :name
       length_of :salt, :minimum=>8
     end

    # DBにテーブルをつくる
    if !(Player.table_exists?)
      Player.create_table
    end

    DB.alter_table :players do
      add_column :tutorial, :integer, :default => 0 unless Unlight::Player.columns.include?(:tutorial)  # 新規追加2012/1/11
      add_column :server_type, :integer, :default => 0 unless Unlight::Player.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # ログインしていたプレイヤー全員をログアウト
    def Player.logout_all
      Player.filter({:state=> Unlight::ST_LOGIN}).all{|a| a.logout }
    end

    # すべてのプレイヤーの状態をクリア
    def Player.state_clear_all
      Player.filter(~{:state => Unlight::ST_LOGOUT}).all do |a|
        a.state = Unlight::ST_LOGOUT
        a.save_changes
      end
    end

    # プレイヤーを登録
    def Player.regist(name, email, salt, verifier, server_type)
      ret = RG_NG[:none]
      pl = Player.new
      pl.name = name
      pl.email = email
      pl.salt = salt
      pl.verifier = verifier
      pl.server_type = server_type
      if pl.valid?
        pl.save_changes
        SERVER_LOG.info("Player: registed.:#{name}")
      else
        ret = RG_NG[:none]
        pl.errors.each do |k, v|
          ret |= RG_NG[k]
          SERVER_LOG.warn("Player: can't regist.:#{k} #{v[0]}")
        end
      end
      ret
    end

    # プレイヤーのパスを再登録
    def Player.reregist(name, email, salt, verifier, server_type)
      pl = Player[:name=>name]
      if pl
        pl.email = email
        pl.salt = salt
        pl.verifier = verifier
        pl.save_changes
        pl.server_type = server_type
        SERVER_LOG.info("Player: reregisted.:#{name}")
      end
    end


    # プレイヤーのなかからCPU専用キャラを返す。なければでっち上げる
    def Player.get_cpu_player
      ret= CACHE.get("cpu_player")
      unless ret
        ai = Player.filter({:role=>ROLE_CPU}).all
        if ai.size > 0
          ret = ai[rand(ai.size)]
        else
          ret = Player.create(:name =>"CPU", :role=>ROLE_CPU, :email=>"auto_create_mska@be.to", :salt=>"6600342d86408afb5b82")
          # CPU用のアバターを作る
          Avatar.regist("CPU", ret.id, [], [], ret.server_type)
          ret.save
        end
        CACHE.set("cpu_player", ret)
      end
      ret
    end

    def Player.get_prf_owner_player
      ret = CACHE.get("prf_owner")
      unless ret
        pl = Player.filter({:name=>"prf_owner"}).all
        if pl.size > 0
          ret = pl.first
        else
          ret = Player.create(:name => "prf_owner", :role=>ROLE_ADMIN, :email=>"auto_create_mska@be.to", :salt=>"6600342d86408afb5b82")
          # CPU用のアバターを作る
          Avatar.regist("prf_owner", ret.id, [1], [1], ret.server_type)
          ret.save
        end
        CACHE.set("prf_owner", ret)
      end
      ret
    end

    # ログイン処理
    def login(ip,s_key)
      # 認証中でなければログインできない
      if auth?
        self.last_ip = ip
        self.session_key = s_key
        # ログイン中ならばログイン時間を更新しない
        if login?
          SERVER_LOG.info("Player: Login(pushout) id:#{id}")
        else
          self.state |= Unlight::ST_LOGIN
          SERVER_LOG.info("Player: Login id:#{id}")

          # idが入っていない場合は、アバター自体の作成が完了していない為、判定しない
          if self.current_avatar&&self.current_avatar.id
            # 久しぶりに戻ってきた場合の処理
            if self&&!self.comeback?&&self.comebacked?
              self.comeback_succeed
              # 自分にも追加する
              notice_str = "#{self.current_avatar.name},"
              pre_no_set = []
              COMEBACKED_PRESENTS.each do |pre|
                is_set_pre = true
                case pre[:type]
                when TG_AVATAR_ITEM
                  pre[:num].times { |i|
                    self.current_avatar.get_item(pre[:id])
                  }
                when TG_AVATAR_PART
                  pre[:num].times { |i|
                    if self.current_avatar.get_part(pre[:id],true) == ERROR_PARTS_DUPE
                      is_set_pre = false
                    end
                  }
                when TG_SLOT_CARD
                  pre[:num].times do |i|
                    self.current_avatar.get_slot_card(pre[:sct_type],pre[:id])
                  end
                end
                pre_no_set << "#{pre[:type]}_#{pre[:id]}_#{pre[:num]}_#{pre[:sct_type]}" if is_set_pre
                ret = true
              end
              notice_str += pre_no_set.join(",")
              self.current_avatar.write_notice(NOTICE_TYPE_COMEBKED_SUCC,notice_str)
              self.comeback # ペナルティフラグにカムバックフラグを立てる
            end

            if RANDOM_SALE_FLAG
              # セール発生条件を満たす
              if ! self.current_avatar.is_sale_time && ( self.login_at == nil || self.login_at.yday != Time.now.utc.yday )
                # ランダムで発生
                r = rand(RANDOM_SALE_PROBABILITY)
                if r == 0
                  self.current_avatar.write_notice(NOTICE_TYPE_SALE_START,[SALE_TYPE_TEN,RANDOM_SALE_TIME].join(","))
                  SERVER_LOG.info("Player: RandomSaleStartSet id:#{self.id}")
                end
              end
            end

          end

        end
        self.auth_off
        true
      else
        false
      end
    end

    # ログアウト処理
    def logout(pushout = false)
      # 排他処理の確認
      refresh
      # FrindLinkのキャッシュを削除する
      FriendLink::cache_delete(self.id)

      # ログインしていなければログアウトしない
      if login?
        self.logout_at = Time.now
        count_total_time
        # 押し出しか？（ログアウト処理後ログインにする)
        if pushout
          SERVER_LOG.info("Player: Logout(pushout) id:#{id}")
        else
          self.state &= ~Unlight::ST_LOGIN
          SERVER_LOG.info("Player: Logout id:#{id}")
        end
        self.save_changes
        true
      else
        false
      end
    end

    # ログインボーナスを渡す
    def login_bonus_set
      ret  = false
      refresh
      if self.login_at && (self.login_at.utc + LOGIN_BONUS_OFFSET_TIME).yday != (Time.now.utc + LOGIN_BONUS_OFFSET_TIME).yday || self.login_at.utc + 60*60*24 < Time.now.utc  # 60*60*9時間ずらす
        ret  = true
      else
        ret = false
      end
      self.update_login_at
      ret
    end

    # ログイン時間を更新
    def update_login_at
      self.login_at = Time.now.utc
      self.save_changes
    end

    # トータル接続時間を計算
    def count_total_time
      self.logout_at = Time.now.utc   unless self.logout_at
      self.login_at = self.created_at   unless self.login_at
      self.total_time += (self.logout_at-self.login_at)
    end

    def auth_on
      self.state |= Unlight::ST_AUTH
      self.save_changes
    end

    def auth_off
      self.state &= ~Unlight::ST_AUTH
      self.save_changes
    end

    def Player.auth_off_all
      SERVER_LOG.debug("Player: Auth all off")
      Player.filter("state >= #{Unlight::ST_AUTH}").all do |a|
        a.auth_off
      end
    end


    def login?
      self.state & Unlight::ST_LOGIN != 0
    end

    def auth?
      self.state & Unlight::ST_AUTH != 0
    end

    # ロック処理
    def lock
      self.penalty  = (self.penalty |Unlight::PN_LOCK)
      self.save_changes
    end


    # パス失敗
    def pass_failed
      self.penalty  = (self.penalty |Unlight::PN_PASS_FAIL)
      self.save_changes
    end


    # 認証に失敗
    def auth_failed
    end

    def same_ip_check
      self.penalty  = (self.penalty |Unlight::PN_SAME_IP)
      self.save_changes
    end

    # カムバック
    def comeback
      self.penalty  = (self.penalty |Unlight::PN_COMEBACK)
      self.save_changes
    end

    # ペナルティの状況を確認
    # （今は恒常的なロックのみ
    def penalty?
      if self.penalty & Unlight::PN_LOCK !=0
        true
      else
        false
      end
    end

    # カムバックして来たか
    def comeback?
      if self.penalty & Unlight::PN_COMEBACK !=0
        true
      else
        false
      end
    end

    # 現在使用中のアバターを返す（現在は問答無用で0番）
    def current_avatar
      if @current_avatar
        @current_avatar
      else
        if avatars.size > 0
          @current_avatar = self.avatars[0]
          @current_avatar
        else
          @current_avatar = Avatar.new(:name =>self.name, :player_id=>self.id)
          @current_avatar
        end
      end
    end

    # フレンドリストとステータスをペアで返す
    def get_friend_list_str
      id_set = []
      st_set = []
      av_set = []
      sns_id_set = []
      # ここだけブロックリストも考慮して渡す
      fl_set =  FriendLink::get_all_link(self.id,self.server_type)
      fl_list = []
      other_id_list = []
      fl_set.each do |fl|
        fl_list << fl
        other_id_list << fl.other_id(self.id)
      end
      other_pls = Player.filter([[:id,other_id_list]]).all if other_id_list.size > 0
      pl_cache = { }
      other_pls.each do |opl|
        pl_cache[opl.id] = opl
      end
      fl_list.each do |f|
        unless  pl_cache[f.other_id(self.id)]
          pl_cache[f.other_id(self.id)] = Player[f.other_id(self.id)] unless pl_cache[f.other_id(self.id)]
        end
        pl = pl_cache[f.other_id(self.id)]
        if pl
          av = pl.current_avatar
          id_set << f.other_id(self.id)
          st_set << f.status(self.id)
          sns_id_set << pl.name
          st_set[-1] = FR_ST_LOGIN if (st_set.last == FR_ST_FRIEND) && pl.login?
          if av.id
            av_set << av.id
          else
            av_set << 0
          end
        end
      end
      [id_set.join(","),av_set.join(","),st_set.join(","),sns_id_set.join(",")]
    end

    # フレンドリストとステータスをペアで返す
    def get_friend_list_offset_str(type,offset,count)
      id_set = []
      st_set = []
      av_set = []
      sns_id_set = []
      fl_set = []
      # フレンド数、ブロック数のみ取得
      fl_num = FriendLink::get_link_num(self.id,self.server_type)
      bl_num = FriendLink::get_black_link_num(self.id,self.server_type)
      rq_num = FriendLink::get_request_list_num(self.id,self.server_type)
      case type
      when FriendLink::TYPE_FRIEND
        fl_set = FriendLink::get_link_offset(self.id,offset,count,self.server_type)
      when FriendLink::TYPE_CONFIRM
        fl_set = FriendLink::get_request_list_offset(self.id,offset,count,self.server_type)
      when FriendLink::TYPE_BLOCK
        fl_set = FriendLink::get_black_list_offset(self.id,offset,count,self.server_type)
      end
      if fl_set.size > 0
        other_id_list = fl_set.map { |fl| fl.other_id(self.id) }
        SERVER_LOG.info("DataServer <UID:#{self.id}> [#{__method__}] other_id_list:#{other_id_list}")
        other_pls = Player.filter([[:id,other_id_list]]).all if other_id_list.size > 0
        pl_cache = { }
        other_pls.each { |opl| pl_cache[opl.id] = opl }
        other_avas = Avatar.filter([[:player_id,other_id_list]]).all if other_id_list.size > 0
        ava_cache = { }
        other_avas.each { |oava| ava_cache[oava.player_id] = oava }
        fl_set.each do |f|
          unless  pl_cache[f.other_id(self.id)]
            pl_cache[f.other_id(self.id)] = Player[f.other_id(self.id)] unless pl_cache[f.other_id(self.id)]
          end
          pl = pl_cache[f.other_id(self.id)]
          if pl
            av = (ava_cache[f.other_id(self.id)]) ? ava_cache[f.other_id(self.id)] : pl.current_avatar
            id_set << f.other_id(self.id)
            st_set << f.status(self.id)
            sns_id_set << pl.name
            st_set[-1] = FR_ST_LOGIN if (st_set.last == FR_ST_FRIEND) && pl.login?
            if av.id
              av_set << av.id
            else
              av_set << 0
            end
          end
        end
      end
      [id_set.join(","),av_set.join(","),st_set.join(","),sns_id_set.join(","),type,offset,fl_num,bl_num,rq_num]
    end

    # フレンドリンクを作る（認証前）
    def create_friend_link(o_id)
      f_num = 10
      o_num = 10
      o_p = Player[o_id]
      f_set = FriendLink::get_link(self.id,self.server_type)
      o_set = FriendLink::get_link(o_id,self.server_type)
      f_num = self.current_avatar.friend_max if self.current_avatar.friend_max
      o_num = o_p.current_avatar.friend_max if o_p&&o_p.current_avatar&&o_p.current_avatar.friend_max
      f_ok = f_num > f_set.size
      o_ok = o_num > o_set.size
      return ERROR_FRIEND_OWN_MAX unless f_ok
      return ERROR_FRIEND_OTHER_MAX unless o_ok
      if FriendLink::create_link(self.id, o_id,self.server_type)
        return 0
      else
        return ERROR_FRIEND_APPLY
      end
    end

    # フレンドリンクを認証する
    def confirm_friend_link(o_id)
      FriendLink::change_link_type(self.id,o_id, FriendLink::TYPE_FRIEND, self.server_type)
    end

    # フレンドリンクを削除する
    def delete_friend_link(o_id)
      FriendLink::delete_link(self.id,o_id,self.server_type)
    end

    #  ブロックリンクを作る
    def create_block_link(o_id)
      ret = FriendLink::create_block_link(self.id,o_id,self.server_type)
    end

    # フレンドを招待した
    def invite_friend(uid,check = true)
      InviteLog::invite(self.id, uid, check)
    end

    # フレンドにカムバック依頼を出す
    def send_comeback_friend(uid)
      ComebackLog::comeback(self.id, uid)
    end

    # ログイン成功
    def login_check
      SERVER_LOG.debug("<UID:#{self.id}>#{$SERVER_NAME}: [player.login_check] ")
      # 招待されていた場合すべて招待してくれた人にプレゼントを登録
      self.invite_succeed
      # ログインボーナスをあげる

      # 連続ログイン記録ボーナス

      # 友達レベルアップボーナス
    end

    def invited?
      InviteLog::check_invited?(self.name)#.size > 0
    end
    # フレンドを招待した相手へ登録プレゼント
    def invite_succeed(my_name)
      ret = false
      SERVER_LOG.debug("<UID:#{self.id}>#{$SERVER_NAME}: [player.invite_succeed] ")

      item_counter = 0

      # 自分を招待したプレイヤーのカレントアバターにアイテムをつける
      in_set = InviteLog::check_invited?(self.name)
      if in_set
        in_set.each do |i|
          pl = Player[i.invite_player_id]
          pre_no_set = []
          if pl&&pl.current_avatar&&i.invited == false
            if item_counter < INVITE_MAX
              notice_str = "#{my_name},"
              pre_nums = { }
              INVITE_PRESENTS.each do |pre|
                pl.current_avatar.get_item(pre)
                pre_nums[pre] = 0 unless pre_nums[pre]
                pre_nums[pre] += 1 # 各アイテムの個数を数える
                ret = true
              end
              # NoticeにIDと個数を渡す
              pre_nums.each { |k,i|
                pre_no_set << "#{k}_#{i}"
              }
              notice_str += pre_no_set.join(",")
              SERVER_LOG.info("<UID:#{self.id}>#{$SERVER_NAME}: [player.invite_succeed]#{pl.id}: #{notice_str}")
              pl.current_avatar.write_notice(NOTICE_TYPE_INVITE_SUCC,notice_str)
            end
            item_counter +=1
            i.invited = true
            i.save_changes
            # 招待人数カウントレコード
            pl.current_avatar.achievement_check(INVITE_RECORD_IDS)
          end
        end
      end
      ret
    end

    def comebacked?
      ret = false
      check_date = Time.now
      if COMEBACK_EVENT
        check_date = check_date - COMEBACK_CHECK_PERIOD
        ret = ( self.logout_at != nil ) ? ( self.logout_at < check_date ) : false;
      end
      ret
    end
    # カムバック成功の報酬付与
    def comeback_succeed
      ret = false

      fl_set =  FriendLink::get_link(self.id,self.server_type)
      if fl_set

        # プレイヤーのフレンド全員にアイテムをつける
        fl_set.each do |f|
          if f.friend_type == FriendLink::TYPE_FRIEND
            pl = Player[f.other_id(self.id)]
            pre_no_set = []
            if pl&&pl.current_avatar
              notice_str = "#{self.current_avatar.name},"
              COMEBACK_SEND_PRESENTS.each do |pre|
                pl.current_avatar.get_item(pre)
                pre_no_set << pre.to_s
                ret = true
              end
              notice_str += pre_no_set.join(",")
              SERVER_LOG.info("<UID:#{self.id}>#{$SERVER_NAME}: [player.comeback_succeed]#{pl.id}: #{notice_str}")
              pl.current_avatar.write_notice(NOTICE_TYPE_COMEBK_SUCC,notice_str)
            end
          end
        end
      end
      ret
    end


    def friend?(f_id)
      ret = false
      f_set = FriendLink::get_link(self.id,self.server_type)
      f_set.each {|f|
        # タイプがフレンドで相手が存在するとき
        if f.friend_type == FriendLink::TYPE_FRIEND&&f.other_id(self.id) == f_id
          ret = true
        end
      }
      ret
    end

    def friend_num
      FriendLink::get_link(self.id,self.server_type).length
    end

    def confirmed_friend_num
      ret = 0
      f_set = FriendLink::get_link(self.id,self.server_type)
      f_set.each {|f|
        # タイプがフレンドで相手が存在するとき
        if f.friend_type == FriendLink::TYPE_FRIEND
          ret +=1
        end
      }
      ret
    end

    def update_invited_users(users)
      users.each do |u|
        pls = Player.filter(:name => u).all
        if pls.size >0
          p_id  =  pls.first.id
          t = InviteLog::invite(p_id,self.name)
          SERVER_LOG.info("Player: invited (update).:#{p_id}") if t
        end
      end
    end

    def update_comebacked_users(users)
      users.each do |u|
        pls = Player.filter(:name => u).all
        if pls.size >0
          p_id  =  pls.first.id
          t = ComebackLog::comeback(p_id,self.name)
          SERVER_LOG.info("Player: comebacked (update).:#{p_id}") if t
        end
      end
    end

    def update_played_tutorial(t)
      self.tutorial = t
      self.save_changes
    end

  end

end
