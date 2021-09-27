# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # ゲームセッションログ
  class MatchLog < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE

    # 他クラスのアソシエーション
    many_to_one :channel

    attr_accessor :a_point, :b_point

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

    # 部屋を作る
    def self.create_room(channel_id, match_name, match_stage, avatar_ids, rule, uid, cpu_card_data_id, server_type, watch_mode = 0, get_bp = 0, channel_rule = CRULE_FREE)
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
        d.save_changes
        d.set_cache(uid)
      end
    end

    # キャッシュとUIDを結びつける
    def set_cache(uid)
      MatchLog.cache_store.set("#{uid}}", id)
      @a_avatar = nil
      @b_avatar = nil
    end

    def a_avatar
      @a_avatar ||= Avatar[a_avatar_id]
      @a_avatar
    end

    def b_avatar
      @b_avatar ||= Avatar[b_avatar_id]
      @b_avatar
    end

    def other_avatar_id(self_id)
      self_id == a_avatar_id ? b_avatar_id : a_avatar_id
    end

    # UIDと結びついたキャッシュを取り出す
    def self.get_cache(uid)
      if cache_store.get("#{uid}}")
        MatchLog[cache_store.get("#{uid}}")]
      end
    end

    # UIDと結びついたキャッシュを削除
    def self.delete_cache(uid)
      if cache_store.get("#{uid}}")
        # nilをいれてしまう
        MatchLog.cache_store.set("#{uid}}", nil)
      end
    end

    # マッチ成立
    def match_ok
      self.state = MATCH_OK
      save_changes
    end

    # マッチ中断
    def abort
      self.state = MATCH_ABORT
      save_changes
    end

    # 対戦の開始
    def start_match
      self.start_at = Time.now.utc
      self.state = MATCH_START
      a_set = a_avatar.duel_deck.cards_id
      b_set = b_avatar.duel_deck.cards_id
      self.a_chara_card_id_0 = a_set[0] if a_set[0]
      self.a_chara_card_id_1 = a_set[1] if a_set[1]
      self.a_chara_card_id_2 = a_set[2] if a_set[2]
      self.b_chara_card_id_0 = b_set[0] if b_set[0]
      self.b_chara_card_id_1 = b_set[1] if b_set[1]
      self.b_chara_card_id_2 = b_set[2] if b_set[2]

      # 友達なら
      if a_avatar.player.friend?(b_avatar.player.id)
        self.match_option = Unlight::DUEL_OPTION_FRIEND
      end

      save_changes
      @before_bp_a = a_avatar.point
      @before_bp_b = b_avatar.point
    end

    # 終了処理
    def set_finish(result, turn, state)
      refresh
      if self.state == MATCH_START
        # ちゃんと始まっているものを終わりにする
        self.finish_at = Time.now.utc
        self.a_remain_hp_set = result[0][:remain_hp].join(',')
        self.b_remain_hp_set = result[1][:remain_hp].join(',')
        self.turn_num = turn
        self.state = state
        self.finish_at = Time.now.utc
      end
      if get_bp
        case result[0][:result]
        when RESULT_WIN
          self.winner_avatar_id = a_avatar_id
          self.get_bp = Avatar[a_avatar_id].point - @before_bp_a if @before_bp_a && Avatar[a_avatar_id].point
          self.lose_bp = Avatar[b_avatar_id].point - @before_bp_b if @before_bp_b && Avatar[b_avatar_id].point
        when RESULT_LOSE
          self.winner_avatar_id = b_avatar_id
          self.get_bp = Avatar[b_avatar_id].point - @before_bp_b if @before_bp_b && Avatar[b_avatar_id].point
          self.lose_bp = Avatar[a_avatar_id].point - @before_bp_a if @before_bp_a && Avatar[a_avatar_id].point
        end
      end
      save_changes
    end

    # 対戦の終了
    def finish_match(result, turn)
      set_finish(result, turn, MATCH_END)
    end

    # 対戦の終了(相手が放棄していた場合)
    def finish_aborted_match(result, turn)
      set_finish(result, turn, MATCH_ABORT_END)
    end

    # 対戦の異常終了
    def abort_match(turn)
      if state == MATCH_START
        self.turn_num = turn
        self.state = MATCH_ABORT
        self.finish_at = Time.now.utc
        save_changes
      end
    end

    def warn_same_ip
      self.warn = (self.warn | Unlight::M_WARN_SAME_IP)
      save_changes
    end
  end
end
