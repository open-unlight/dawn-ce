# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # プレイヤークラス
  class FriendLink < Sequel::Model
    TYPE_CONFIRM = 0
    TYPE_FRIEND  = 1
    TYPE_BLOCK   = 2

    # プラグインの設定
    plugin :schema
    plugin :hook_class_methods

    Sequel::Model.plugin :schema
    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :relating_player_id, :index=>true#, :table => :players
      integer     :related_player_id, :index=>true#, :table => :players
      integer     :friend_type, :default => Unlight::FriendLink::TYPE_CONFIRM
      Boolean     :invated,:default =>false
      integer     :server_type, :default => 0,:index => true # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    def validate
      super
    end

    # DBにテーブルをつくる
    if !(FriendLink.table_exists?)
      FriendLink.create_table
    end

    # テーブルを変更する（履歴を残せ）
    DB.alter_table :friend_links do
      add_column :server_type, :integer, :default => 0 unless Unlight::FriendLink.columns.include?(:server_type)  # 新規追加 2016/11/24
    end
    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # リンクのキャッシュ
    @@link_cache = [ ]

    # リンクをゲット出来る(リンクを五分間キャッシュする)
    def FriendLink::get_link(p_id,server_type)
      link = CACHE.get( "friend_link_get:#{p_id}")
      unless
        link = FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{:related_player_id =>p_id})).exclude(:friend_type => TYPE_BLOCK).filter(:server_type=>server_type).all
        CACHE.set("friend_link_get:#{p_id}",link,300)
      end
      link
    end

    # リンクをゲット出来る
    def FriendLink::get_all_link(p_id,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{ :related_player_id =>p_id})).filter(:server_type=>server_type).all
    end

    # BlackListゲット出来る
    def FriendLink::get_black_list(p_id,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{ :related_player_id =>p_id})).filter(:friend_type => TYPE_BLOCK).filter(:server_type=>server_type).all
    end

    # RequestListゲット出来る
    def FriendLink::get_request_list(p_id,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{ :related_player_id =>p_id})).filter(:friend_type => TYPE_CONFIRM).filter(:server_type=>server_type).all
    end

    # リンクをゲット出来る
    def FriendLink::get_link_offset(p_id,offset,count,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{:related_player_id =>p_id})).filter(:friend_type => TYPE_FRIEND).filter(:server_type=>server_type).order(Sequel.asc(:id)).limit(count,offset).all
    end

    def FriendLink::get_link_num(p_id,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{:related_player_id =>p_id})).filter(:friend_type => TYPE_FRIEND).filter(:server_type=>server_type).order(Sequel.asc(:id)).count
    end

    # BlackListゲット出来る
    def FriendLink::get_black_list_offset(p_id,offset,count,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{ :related_player_id =>p_id})).filter(:friend_type => TYPE_BLOCK).filter(:server_type=>server_type).order(Sequel.asc(:id)).limit(count,offset).all
    end

    def FriendLink::get_black_link_num(p_id,server_type)
      FriendLink.filter(:relating_player_id=>p_id).filter(:friend_type => TYPE_BLOCK).filter(:server_type=>server_type).order(Sequel.asc(:id)).count
    end

    # RequestedListゲット出来る
    def FriendLink::get_request_list_offset(p_id,offset,count,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{:related_player_id =>p_id})).filter(:friend_type => TYPE_CONFIRM).filter(:server_type=>server_type).order(Sequel.asc(:id)).limit(count,offset).all
    end

    def FriendLink::get_request_list_num(p_id,server_type)
      FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{:related_player_id =>p_id})).filter(:friend_type => TYPE_CONFIRM).filter(:server_type=>server_type).order(Sequel.asc(:id)).count
    end

    # キャッシュを削除する（ログアウト時に仕様：リークになるので）
    def FriendLink::cache_delete(p_id)
      @@link_cache[p_id] = nil
    end

    # キャッシュのアップデート
    def FriendLink::cache_update(p_id,server_type)
      @@link_cache[p_id] = FriendLink.filter(Sequel.|({:relating_player_id=>p_id},{ :related_player_id =>p_id})).filter(:server_type=>server_type).all
    end

    # リンクを作る
    def FriendLink::create_link(p_a, p_b,server_type)
      if p_a==p_b||check_already_exist?(p_a, p_b,server_type)
        false
      else
        f_l = FriendLink.new do |f|
          f.relating_player_id = p_a
          f.related_player_id = p_b
          f.server_type = server_type
          f.save
        end
        CACHE.delete("friend_link_get:#{p_a}")
        CACHE.delete("friend_link_get:#{p_b}")
        f_l
      end
    end

    # ブロックリンクを作る
    def FriendLink::create_block_link(p_a, p_b,server_type)
      ret = []
      ret << 0
      # すでに自分がブロックされていたら抜ける
      a = FriendLink.filter(Sequel.&({:relating_player_id=>p_b},{ :related_player_id =>p_a},{ :friend_type =>TYPE_BLOCK})).filter(:server_type=>server_type).all
      unless a.size == 0
        ret[0] = ERROR_BLOCK_APPLY
        return ret
      end
      # ブロックは10人しか出来ない
      b = FriendLink.filter(Sequel.&({:relating_player_id=>p_a},{ :friend_type =>TYPE_BLOCK})).filter(:server_type=>server_type).all
      unless b.size < MAX_BLOCK_NUM
        ret[0] = ERROR_BLOCK_MAX
        return ret
      end
      delete_link(p_a, p_b, server_type)
      ret << FriendLink.new do |f|
        f.relating_player_id = p_a
        f.related_player_id = p_b
        f.friend_type = TYPE_BLOCK
        f.server_type = server_type
        f.save
      end
      CACHE.delete("friend_link_get:#{p_a}")
      CACHE.delete("friend_link_get:#{p_b}")
      ret
    end

    # リンクをタイプを変更（成功True,失敗False）
    def FriendLink::change_link_type(p_a, p_b, type, server_type)
      ret = false
      if p_a!=p_b
        links = check_already_exist?(p_a, p_b, server_type)
        if links&&links.size >0
          links.each do |li|
            li.change_type(type)
            ret =true
          end
        end
      end
      ret
    end


    # リンクを削除
    def FriendLink::delete_link(p_a, p_b, server_type)
        ret = false
      if p_a!=p_b
        links = check_already_exist?(p_a, p_b, server_type)
        if links&&links.size >0
          links.each do |li|
            li.destroy
            ret =true
          end
          CACHE.delete("friend_link_get:#{p_a}")
          CACHE.delete("friend_link_get:#{p_b}")
        end
      end
      ret
    end

    # タイプ変更
    def change_type(t)
      a_id = self.relating_player_id
      b_id = self.related_player_id
      self.friend_type = t
      self.save_changes
      CACHE.delete("friend_link_get:#{a_id}")
      CACHE.delete("friend_link_get:#{b_id}")
    end


    # リンクがすでに存在するかしなかったFalse,存在したらそのリンクを返す
    def FriendLink::check_already_exist?(p_a, p_b,server_type)
      ret = false
      links =  FriendLink.filter(Sequel.&({:relating_player_id=>p_a},{ :related_player_id =>p_b})).filter(:server_type=>server_type).all
      links =  FriendLink.filter(Sequel.&({:relating_player_id=>p_b},{ :related_player_id =>p_a})).filter(:server_type=>server_type).all if links.size==0
      ret = links if links.size>0
      ret
    end


    # 比較演算子をオーバライド
    def ==(f_link)
      ret = false
      if f_link.kind_of?(FriendLink)
        ret = true if f_link.relating_player_id == self.relating_player_id && f_link.related_player_id == self.related_player_id
        ret = true if f_link.relating_player_id == self.related_player_id && f_link.related_player_id == self.relating_player_id
      end
      ret
    end

    def status(me_id)
      begin
        refresh
      rescue =>e
        SERVER_LOG.fatal("FriendLink: errot link is deleted.")
        return 0
      end
      case self.friend_type
      when TYPE_CONFIRM
        if me_id == self.relating_player_id
          ret = FR_ST_OTHER_CONFIRM
        else
          ret = FR_ST_MINE_CONFIRM
        end
      when TYPE_FRIEND
        ret = FR_ST_FRIEND
      when TYPE_BLOCK
        if me_id == self.relating_player_id
          ret = FR_ST_BLOCK
        else
          ret = FR_ST_BLOCKED
        end
      end
      ret
    end

    def other_id(me_id)
      if me_id == self.relating_player_id
        ret = self.related_player_id
      else
        ret = self.relating_player_id
      end
     ret
   end

    # p_idにother_p_idがBlockされてるか
    def FriendLink::is_blocked(p_id,other_p_id,server_type)
      ret = false
      list = self::get_black_list(p_id,server_type)
      list.each do |l|
        if l.relating_player_id == other_p_id || l.related_player_id == other_p_id
          ret = true
          break
        end
      end
      ret
    end
  end
end
