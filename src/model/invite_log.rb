# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # ゲームセッションログ
  class InviteLog < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    many_to_one :channel

    attr_accessor  :a_point, :b_point

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :invite_player_id, :index=>true#, :table => :players
      String      :invited_user_id, :index=>true
      Boolean     :invited,:default =>false
      integer     :sns_log_id, :index=>true
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる
    if !(InviteLog.table_exists?)
      InviteLog.create_table
    end
    DB.alter_table :invite_logs do
      add_column :sns_log_id, :integer unless Unlight::InviteLog.columns.include?(:sns_log_id)  # 新規追加 2012/09/27
    end

    # 招待する
    def InviteLog::invite(pid, uid,check = true)
      if check_already_exist?(pid, uid) && check
        ret = false
      else
        f_l = InviteLog.new do |f|
          f.invite_player_id = pid
          f.invited_user_id = uid
          f.save
        end
        ret = f_l
      end
      ret
    end

    # 後から招待情報を更新する（ニコニコ用）
    def InviteLog::invite_after_update(pid, uid, log_id)
      exist = false
      links =  InviteLog.filter({:invited_user_id =>uid}).all
      exist = links if links.size >= 3

      if exist
        ret = false
      else
        f_l = InviteLog.new do |f|
          f.invite_player_id = pid
          f.invited_user_id = uid
          f.sns_log_id = log_id
          f.save
        end
        ret = f_l
      end
      ret
    end

    # 招待済みか？
    def InviteLog::check_invited?(uid)
      ret = false
      links =  InviteLog.filter({ :invited_user_id =>uid,:invited=>false}).all
      ret = links if links.size > 0
      ret
    end

    # 招待アイテムゲット済みか？
    def InviteLog::check_already_invited?(uid)
      ret = false
      links =  InviteLog.filter({ :invited_user_id =>uid,:invited=>true}).all
      ret = links if links.size > 0
      ret
    end

    # リンクがすでに存在するかしなかったFalse,存在したらそのリンクを返す
    def InviteLog::check_already_exist?(pid, uid)
      return true if Player[:name=>uid]
      ret = false
      links =  InviteLog.filter({:invite_player_id=>pid,:invited_user_id =>uid}).all
      ret = links if links.size > 0
      ret
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end


  end

end
