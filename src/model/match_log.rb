# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # ゲームセッションログ
  class MatchLog < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE

    # 他クラスのアソシエーション
    many_to_one :channel

    attr_accessor  :a_point, :b_point

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :channel_id#, :table => :channels
      String      :match_name, :text=>true, :default => ""
      integer     :match_rule
      integer     :match_stage
      integer     :a_avatar_id
      integer     :b_avatar_id
      integer     :a_chara_card_id_0
      integer     :a_chara_card_id_1
      integer     :a_chara_card_id_2
      integer     :b_chara_card_id_0
      integer     :b_chara_card_id_1
      integer     :b_chara_card_id_2
      integer     :a_deck_cost
      integer     :b_deck_cost
      integer     :cpu_card_data_id, :default => 0
      integer     :state
      integer     :match_option, :default => 0
      integer     :match_level
      integer     :winner_avatar_id , :index=>true
      integer     :get_bp
      integer     :lose_bp
      integer     :channel_set_rule, :default => CRULE_FREE
      String      :a_remain_hp_set
      String      :b_remain_hp_set
      integer     :turn_num, :default => 0
      integer     :warn, :default => 0
      integer     :watch_mode, :default => 0 # 観戦モード, 0:OFF,1:ON
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :start_at
      datetime    :finish_at
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do

    end

    # DBにテーブルをつくる
    if !(MatchLog.table_exists?)
      MatchLog.create_table
    end

    DB.alter_table :match_logs do
      add_column :watch_mode, :integer, :default => 0 unless Unlight::MatchLog.columns.include?(:watch_mode)  # 新規追加2013/01/07
      add_column :lose_bp, :integer, :default => 0 unless Unlight::MatchLog.columns.include?(:lose_bp)  # 新規追加2013/04/02
      add_column :a_deck_cost, :integer, :default => 0 unless Unlight::MatchLog.columns.include?(:a_deck_cost)  # 新規追加2013/07/16
      add_column :b_deck_cost, :integer, :default => 0 unless Unlight::MatchLog.columns.include?(:b_deck_cost)  # 新規追加2013/07/16
      add_column :channel_set_rule, :integer, :default => CRULE_FREE unless Unlight::MatchLog.columns.include?(:channel_set_rule)  # 新規追加2014/11/13
      add_column :server_type, :integer, :default => 0 unless Unlight::MatchLog.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # 部屋を作る
    def MatchLog::create_room(channel_id, match_name, match_stage, avatar_ids, rule, uid, cpu_card_data_id, server_type, watch_mode = 0, get_bp = 0, channel_rule = CRULE_FREE)
      MatchLog.new do |d|
        d.channel_id = channel_id
        d.match_name = match_name
        d.match_stage = match_stage
        d.match_rule = rule
        d.a_avatar_id = avatar_ids[0]
        d.b_avatar_id = avatar_ids[1]
        d.state = MATCH_OK
        d.cpu_card_data_id = cpu_card_data_id
        d.watch_mode = watch_mode
        d.get_bp = get_bp
        d.channel_set_rule = channel_rule
        d.server_type = server_type
        d.save
        d.set_cache(uid)
      end
    end

    # キャッシュとUIDを結びつける
    def set_cache(uid)
      MatchLog::cache_store.set("#{uid}}", self.id)
      @a_avatar =nil
      @b_avatar =nil
    end

    def a_avatar
      @a_avatar = Avatar[self.a_avatar_id] unless  @a_avatar
      @a_avatar
    end

    def b_avatar
      @b_avatar = Avatar[self.b_avatar_id] unless  @b_avatar
      @b_avatar
    end

    def other_avatar_id(self_id)
      ret = (self_id == self.a_avatar_id) ? self.b_avatar_id : self.a_avatar_id
      ret
    end

    # UIDと結びついたキャッシュを取り出す
    def MatchLog::get_cache(uid)
      if cache_store.get("#{uid}}")
        MatchLog[cache_store.get("#{uid}}")]
      end
    end

    # UIDと結びついたキャッシュを削除
    def MatchLog::delete_cache(uid)
      if cache_store.get("#{uid}}")
        # nilをいれてしまう
        MatchLog::cache_store.set("#{uid}}", nil)
      end
    end

    # マッチ成立
    def match_ok
      self.state = MATCH_OK
      self.save_changes
    end

    # マッチ中断
    def abort
      self.state = MATCH_ABORT
      self.save_changes
    end

    #対戦の開始
    def start_match()
      self.start_at = Time.now.utc
      self.state = MATCH_START
      a_set = self.a_avatar.duel_deck.cards_id
      b_set = self.b_avatar.duel_deck.cards_id
      self.a_chara_card_id_0 = a_set[0] if a_set[0]
      self.a_chara_card_id_1 = a_set[1] if a_set[1]
      self.a_chara_card_id_2 = a_set[2] if a_set[2]
      self.b_chara_card_id_0 = b_set[0] if b_set[0]
      self.b_chara_card_id_1 = b_set[1] if b_set[1]
      self.b_chara_card_id_2 = b_set[2] if b_set[2]

      # 友達なら
      if self.a_avatar.player.friend?(self.b_avatar.player.id)
        self.match_option = Unlight::DUEL_OPTION_FRIEND
      end

      self.save_changes
      @before_bp_a = self.a_avatar.point
      @before_bp_b = self.b_avatar.point

    end

    # 終了処理
    def set_finish( result, turn, state )
      self.refresh
      if self.state == MATCH_START
      # ちゃんと始まっているものを終わりにする
        self.finish_at = Time.now.utc
        self.a_remain_hp_set  = result[0][:remain_hp].join(",")
        self.b_remain_hp_set = result[1][:remain_hp].join(",")
        self.turn_num = turn
        self.state = state
        self.finish_at = Time.now.utc
      end
      if self.get_bp
        case result[0][:result]
        when RESULT_WIN
          self.winner_avatar_id = self.a_avatar_id
          self.get_bp =  Avatar[self.a_avatar_id].point - @before_bp_a if @before_bp_a && Avatar[self.a_avatar_id].point
          self.lose_bp =  Avatar[self.b_avatar_id].point - @before_bp_b if @before_bp_b && Avatar[self.b_avatar_id].point
        when RESULT_LOSE
          self.winner_avatar_id = self.b_avatar_id
          self.get_bp =  Avatar[self.b_avatar_id].point - @before_bp_b if @before_bp_b && Avatar[self.b_avatar_id].point
          self.lose_bp =  Avatar[self.a_avatar_id].point - @before_bp_a if @before_bp_a && Avatar[self.a_avatar_id].point
        end
      end
      self.save_changes
    end

    # 対戦の終了
    def finish_match(result , turn)
      set_finish( result, turn, MATCH_END )
    end

    # 対戦の終了(相手が放棄していた場合)
    def finish_aborted_match(result , turn)
      set_finish( result, turn, MATCH_ABORT_END )
    end

    # 対戦の異常終了
    def abort_match(turn)
      if self.state == MATCH_START
        self.turn_num = turn
        self.state = MATCH_ABORT
        self.finish_at = Time.now.utc
        self.save_changes
      end
    end

    # 対戦の異常終了
    def abort_match(turn)
      if self.state == MATCH_START
        self.turn_num = turn
        self.state = MATCH_ABORT
        self.finish_at = Time.now.utc
        self.save_changes
      end
    end

    def warn_same_ip
      self.warn  = (self.warn|Unlight::M_WARN_SAME_IP)
      self.save_changes
    end
  end
end
