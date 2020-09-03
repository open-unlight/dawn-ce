# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 再発行テーブル
  class ReissueRequest < Sequel::Model

    RR_ST_START         = 0
    RR_ST_SEND_MAIL     = 1
    RR_ST_SEND_PL_ID    = 2
    RR_ST_PASS_INPUT    = 3
    RR_ST_PASS_REISSUE  = 4
    RR_ST_CREATE_READY  = 5
    RR_ST_CREATE_FINISH = 6
    RR_ST_TIME_UP       = 99

    UNIQ_STR_SPLIT_SET = [8,4,4,4,12] # 32
    UNIQ_STR_USE_STR_PT = '-'

    NEXT_LIMIT_TIME = 60*10 # 10分

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :uniq_str, :index => true
      String      :email, :index => true
      integer     :player_id, :default => 0
      integer     :status, :default => RR_ST_START
      datetime    :limit_at
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる
    if !(ReissueRequest.table_exists?)
      ReissueRequest.create_table
    end

    DB.alter_table :reissue_requests do
      add_column :player_id, :integer, :default => 0 unless Unlight::ReissueRequest.columns.include?(:player_id)  # 新規追加 2016/10/25
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def ReissueRequest::create_request(email,player_id=0)
      rreq = ReissueRequest.new do |r|
        r.uniq_str = get_uniq_str
        r.email = email
        r.player_id = player_id
        r.limit_at = Time.now.utc + NEXT_LIMIT_TIME
        r.save
      end
      rreq
    end

    def ReissueRequest::get_uniq_str()
      used_list = ReissueRequest.all.map { |rr| rr.uniq_str }
      ret = ""
      while ret == ""
        trade_no_list = Digest::MD5.hexdigest(Time.now.to_s+"ReissueRequest"+rand(1024).to_s)
        start_idx = 0
        str = ''
        UNIQ_STR_SPLIT_SET.each_with_index do |num,idx|
          str += UNIQ_STR_USE_STR_PT if UNIQ_STR_USE_STR_PT&&idx>0
          str += trade_no_list[start_idx..(start_idx+num-1)].upcase
          start_idx += num
        end
        ret = str if used_list.include?(str) == false
      end
      ret
    end

    def set_player_id(pl_id)
      self.player_id = pl_id
      self.save_changes
    end

    def update_status(st)
      self.status = st
      self.limit_at = Time.now.utc + NEXT_LIMIT_TIME
      self.save_changes
    end

    def is_time_over?
      self.limit_at < Time.now.utc
    end

  end

end
