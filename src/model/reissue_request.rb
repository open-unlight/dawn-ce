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

    UNIQ_STR_SPLIT_SET = [8, 4, 4, 4, 12] # 32
    UNIQ_STR_USE_STR_PT = '-'

    NEXT_LIMIT_TIME = 60 * 10 # 10分

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    validates do
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def self.create_request(email, player_id = 0)
      ReissueRequest.new do |r|
        r.uniq_str = get_uniq_str
        r.email = email
        r.player_id = player_id
        r.limit_at = Time.now.utc + NEXT_LIMIT_TIME
        r.save_changes
      end
    end

    def self.get_uniq_str
      used_list = ReissueRequest.all.map(&:uniq_str)
      ret = ''
      while ret == ''
        trade_no_list = Digest::MD5.hexdigest("#{Time.now}ReissueRequest#{rand(1024)}")
        start_idx = 0
        str = ''
        UNIQ_STR_SPLIT_SET.each_with_index do |num, idx|
          str += UNIQ_STR_USE_STR_PT if UNIQ_STR_USE_STR_PT && idx.positive?
          str += trade_no_list[start_idx..(start_idx + num - 1)].upcase
          start_idx += num
        end
        ret = str if used_list.include?(str) == false
      end
      ret
    end

    def set_player_id(pl_id)
      self.player_id = pl_id
      save_changes
    end

    def update_status(st)
      self.status = st
      self.limit_at = Time.now.utc + NEXT_LIMIT_TIME
      save_changes
    end

    def is_time_over?
      limit_at < Time.now.utc
    end
  end
end
