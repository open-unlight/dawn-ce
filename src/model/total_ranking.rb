# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  module TotalRanking

    def self.included(base) # :nodoc:
      base.extend initialize_ranking
    end

    def initialize_ranking
      @ranking_all = "total_#{data_type}_ranking:all"
      @ranking_all_id = "total_#{data_type}_ranking:all_id"
      @ranking_all_id_before = "total_#{data_type}_ranking:all_id_before"
      @total_ranking_str_set = { }
      @ranking_arrow = "total_#{data_type}_ranking:arrow"
      sv_types = []
      case THIS_SERVER
      when SERVER_SB then
        sv_types << SERVER_SB
      end

      sv_types.each do |server_type|
        all_cache_delete(server_type)
        get_order_ranking(server_type)
      end

      nil
    end

    # ソート済みのランキングを取得する
    def get_order_ranking(server_type = SERVER_SB, st_i = 0, end_i= 99, cache = true)
      ret = nil
      ret = CACHE.get("#{@ranking_all}_#{server_type}")
      unless ret
        ret = ranking_data.filter(:server_type=>server_type).order(Sequel.desc(:point)).limit(RANKING_COUNT_NUM).all
        CACHE.set("#{@ranking_all}_#{server_type}", ret, RANK_CACHE_TTL)
        CACHE.set("#{@ranking_all_id}_#{server_type}", ret.map{ |r| r.avatar_id}, RANK_CACHE_TTL)
        create_arrow(server_type)
      end
      ret[st_i..end_i]
    end

    def create_arrow(server_type)
      # 前回の記録があるならばARROWを作る
      before = CACHE.get("#{@ranking_all_id_before}_#{server_type}")
      if before
        arrow_set = []
        a_id_set = CACHE.get("#{@ranking_all_id}_#{server_type}")
        a_id_set = ranking_data.filter(:server_type=>server_type).order(Sequel.desc(:point)).limit(RANKING_COUNT_NUM).all.map{ |r| r.avatar_id} unless a_id_set
        a_id_set.each_index {|i|
          rid = a_id_set[i]
          old_rank = before.index(rid)
          if  old_rank == nil
            arrow_set << RANK_S_UP
          elsif  old_rank == i
            arrow_set << RANK_NONE
          elsif old_rank > i
            if ((old_rank - i) >= RANK_SUPER_DIFF)
              arrow_set << RANK_S_UP
            else
              arrow_set << RANK_UP
            end
          elsif old_rank < i
            if i - old_rank  >= RANK_SUPER_DIFF
              arrow_set << RANK_S_DOWN
            else
              arrow_set << RANK_DOWN
            end
          else
            arrow_set << RANK_NONE
          end
        }
        CACHE.set("#{@ranking_arrow}_#{server_type}", arrow_set, RANK_CACHE_TTL)
      else
        CACHE.set("#{@ranking_arrow}_#{server_type}", [], RANK_CACHE_TTL)
      end
    end

    def get_arrow_set(server_type)
      ret = CACHE.get("#{@ranking_arrow}_#{server_type}")
      unless ret
        all_cache_delete(server_type)
        get_order_ranking(server_type, 0, 99)
        create_arrow(server_type)
        ret = CACHE.get("#{@ranking_arrow}_#{server_type}")
      end
      ret
    end

    def get_order_ranking_id(server_type)
      ret = CACHE.get("#{@ranking_all_id}_#{server_type}")
      unless ret
        ret = ranking_data.filter(:server_type=>server_type).order(Sequel.desc(:point)).limit(RANKING_COUNT_NUM).all.map{ |r| r.avatar_id}
        CACHE.set("#{@ranking_all_id}_#{server_type}", ret, RANK_CACHE_TTL)
        create_arrow(server_type)
      end
      ret
    end

    # 指定したアバターのランキングを更新して現在のランクを返す
    def update_ranking(a_id, a_name, a_point, server_type)
      lr = last_ranking(server_type)
      r = ranking_data.filter(:server_type=>server_type).filter(:avatar_id =>a_id).all.first
      if lr < a_point
        # すでに登録済みな
        if r
        # 新規なら
        elsif lr == 0
          r = ranking_data.new
        else
          # いっぱいならケツと交換
          r = ranking_data.filter(:server_type=>server_type).order(Sequel.desc(:point)).limit(RANKING_COUNT_NUM).all.last
        end
        r.avatar_id = a_id
        r.name = a_name
        r.point = a_point
        r.server_type = server_type
        r.save
        all_cache_delete(server_type)
      elsif r                   # すでにあるものがランキング外に落ちるときはポイントをいれるだけ
        r.point = a_point
        r.server_type = server_type
        r.save
        all_cache_delete(server_type)
      end
      ranking_data.get_ranking(a_id, server_type, a_point)
    end

    # 100位のアバターのポイントを返す
    def last_ranking(server_type)
      if ranking_data_count(server_type) < RANKING_COUNT_NUM
        0
      else
        ranking_data.filter(:server_type=>server_type).min(:point)||0
      end
    end

    # キャッシュを削除（矢印作成のために前のランキングを残す）
    def all_cache_delete(server_type)
      b = CACHE.get("#{@ranking_all_id_before}_#{server_type}")
      unless b&&b.size>0
        CACHE.set("#{@ranking_all_id_before}_#{server_type}", CACHE.get("#{@ranking_all_id}_#{server_type}"), RANK_ARROW_TTL)
      end
      CACHE.delete("#{@ranking_all}_#{server_type}")
      CACHE.delete("#{@ranking_all_id}_#{server_type}")
      @total_ranking_str_set.each do |k, v|
        CACHE.delete(k)
      end
    end

    # ランキングを文字列で返す（キャッシュつき）
    def get_ranking_str(server_type=SERVER_SB, st_i = 0, end_i= 99, cache = true)
      ret = nil
      if cache
        ret = CACHE.get("total_#{data_type}_ranking:#{st_i}_#{end_i}_#{server_type}_str")
      end
      unless  ret
        set = ranking_data::get_order_ranking(server_type, st_i, end_i, cache)
        arrow_set = get_arrow_set(server_type)
        ret = []
        if set
          set.each_index do |i|
            ret << set[i].name
            ret << arrow_set[i+st_i]
            ret << set[i].point
          end
        end
        ret = ret.join(",")
        CACHE.set( "total_#{data_type}_ranking:#{st_i}_#{end_i}_#{server_type}_str", ret, RANK_CACHE_TTL)
        @total_ranking_str_set["total_#{data_type}_ranking:#{st_i}_#{end_i}_#{server_type}_str"] = true
      end
      ret
    end

    def arrow_cache_delete(server_type)
      CACHE.delete("#{@ranking_all_id_before}_#{server_type}")
    end
  end
end
