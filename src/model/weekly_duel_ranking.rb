# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class WeeklyDuelRanking < Sequel::Model
    many_to_one :avatar                   # プレイヤーに複数所持される

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # キャッシュをON
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id, :index=>true # :table => :avatars
      String      :name, :default =>""
      integer     :point, :default =>0
      integer     :arrow, :default =>0
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(WeeklyDuelRanking.table_exists?)
      WeeklyDuelRanking.create_table
    end

    DB.alter_table :weekly_duel_rankings do
      add_column :server_type, :integer, :default => 0 unless Unlight::WeeklyDuelRanking.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # 指定したアバターのランキングを取得する
    def WeeklyDuelRanking::get_ranking(a_id, server_type, cache = true)
      if cache
        ret = cache_store.get("weekly_duel_ranking:#{a_id}_#{server_type}")
      end
      unless ret
        ret = WeeklyDuelRanking.filter([[:avatar_id, a_id],[:server_type,server_type]]).all.first
        cache_store.set("weekly_duel_ranking:#{a_id}_#{server_type}", ret)
      end
      if ret
        ret = {:rank=>ret.id, :arrow =>ret.arrow,:point=>ret.point}
      else
        ret = {:rank=>0, :arrow =>0,:point => 0}
      end
      ret
    end

    # ソート済みのランキングを取得する
    def WeeklyDuelRanking::get_order_ranking(server_type, st_i = 0, end_i= 99)
      ret = cache_store.get("weekly_duel_ranking:all_#{server_type}")
      unless ret
        ret = WeeklyDuelRanking.filter(:server_type=>server_type).filter(Sequel.cast_string(:id) <= 100).all
        cache_store.set("weekly_duel_ranking:all_#{server_type}", ret ,RANK_CACHE_TTL)
        cache_store.set("weekly_duel_ranking:all_id_#{server_type}", ret.map{ |r| r.avatar_id},RANK_CACHE_TTL)
        cache_store.set("weekly_duel_ranking:arrow_#{server_type}", ret.map{ |r| r.arrow},RANK_CACHE_TTL)
      end
      ret[st_i..end_i]
    end

    def WeeklyDuelRanking::create_arrow(old_id_set,id,i)
      # 前回の記録があるならばARROWを作る
      ret = RANK_S_UP
      if old_id_set
        rid = id
        old_rank = old_id_set.index(rid)
        if  old_rank == nil
          ret = RANK_S_UP
        elsif  old_rank == i
          ret = RANK_NONE
        elsif old_rank > i
          if old_rank - i >= RANK_SUPER_DIFF
            ret = RANK_S_UP
          else
            ret = RANK_UP
          end
        elsif old_rank < i
          if i - old_rank  >= RANK_SUPER_DIFF
            ret = RANK_S_DOWN
          else
            ret = RANK_DOWN
          end
        else
          ret = RANK_NONE
        end
      end
      ret
    end

    def WeeklyDuelRanking::get_order_ranking_id(server_type)
      ret = cache_store.get("weekly_duel_ranking:all_id_#{server_type}")
      unless ret
        ret = WeeklyDuelRanking.filter(:server_type=>server_type).filter(Sequel.cast_string(:id) <= 100).map{ |r| r.avatar_id}
        cache_store.set("weekly_duel_ranking:all_id_#{server_type}", ret, RANK_CACHE_TTL)
      end
      ret
    end

   # 指定したアバターのランキングを更新する(外部でかつslaveから更新せよ)
    def WeeklyDuelRanking::update_ranking(server_type)
      before_rank_id_set = get_order_ranking_id(server_type)
      avatars = { }
      ranking = []
      sunday = Date.today - Date.today.wday
      st = Time.utc(sunday.year, sunday.month, sunday.day)
      MatchLog.filter(:server_type=>server_type).filter{finish_at > st }.all do |log|
        if log.winner_avatar_id
          avatars[log.winner_avatar_id] = 0 unless avatars[log.winner_avatar_id]
          avatars[log.winner_avatar_id]+= log.get_bp
        end
      end
      ranking = avatars.to_a.sort { |a, b| b[1] <=>  a[1]  }
      weekly_ranking = WeeklyDuelRanking.filter(:server_type=>server_type).order(Sequel.asc(:id)).all
      (0..99).each do |i|
        if ranking[i]
          if weekly_ranking[i]
            w = weekly_ranking[i]
            w.avatar_id = ranking[i][0]
            w.name = Avatar[ranking[i][0]].name if Avatar[ranking[i][0]]
            w.point = ranking[i][1]
            w.arrow = create_arrow(before_rank_id_set,w.avatar_id,i)
            w.server_type = server_type
            w.save
          else
            WeeklyDuelRanking.new do |w|
              w.avatar_id = ranking[i][0]
              w.name = Avatar[ranking[i][0]].name if Avatar[ranking[i][0]]
              w.point = ranking[i][1]
              w.arrow = create_arrow(before_rank_id_set,w.avatar_id,i)
              w.server_type = server_type
              w.save
            end
          end
        else
          if weekly_ranking[i]
            w = weekly_ranking[i]
            w.avatar_id = 0
            w.name = ""
            w.point = 0
            w.arrow = 0
            w.save
          else
            WeeklyDuelRanking.new do |w|
              w.avatar_id = 0
              w.name = ""
              w.point = 0
              w.arrow = 0
              w.server_type = server_type
              w.save
            end
          end

        end
      end

      # 圏外をゆっくり保存する
      lst = ranking.size-1 > RANK_OUT_LIMIT ? RANK_OUT_LIMIT : ranking.size-1
      if ranking[100..lst]
        ranking[100..lst].each_index do |i|
          if weekly_ranking[i+100]
            w = weekly_ranking[i+100]
            w.avatar_id = ranking[i+100][0]
            w.point = ranking[i+100][1]
            w.server_type = server_type
            w.save
          else
            WeeklyDuelRanking.new do |w|
              w.avatar_id = ranking[i+100][0]
              w.point = ranking[i+100][1]
              w.server_type = server_type
              w.save
            end
          end
          sleep RANK_OUT_SLEEP
        end
      end
      cache_store.delete("weekly_duel_ranking:all_#{server_type}")
      cache_store.delete("weekly_duel_ranking:all_id_#{server_type}")
    end

    # 圏外のアバターも更新する（重たいのでたまに）
    # ポイントをもったすべてのアバターを取る(ソート済みのアバターとポイントのArrayを返す)
    def WeeklyDuelRanking::point_avatars(server_type)
      avatars = { }
      sunday = Date.today - Date.today.wday
      st = Time.utc(sunday.year, sunday.month, sunday.day)
      MatchLog.filter(:server_type=>server_type).filter{finish_at > st }.all do |log|
        if log.winner_avatar_id
          avatars[log.winner_avatar_id] = 0 unless avatars[log.winner_avatar_id]
          avatars[log.winner_avatar_id]+= log.get_bp
        end
      end
      avatars.to_a.sort { |a, b| b[1] <=>  a[1]  } # これをどっか軽量なところに保存したいが・・・・。
    end

    # 100位のポイントを返す
    def WeeklyDuelRanking::last_ranking(server_type)
      weekly_ranking = WeeklyDuelRanking.filter(:server_type=>server_type).order(Sequel.asc(:id)).all
      weekly_ranking[100].point
    end

    # ランキングを文字列で返す（キャッシュつき）
    def WeeklyDuelRanking::get_ranking_str(server_type, st_i = 0, end_i= 99)
      ret = cache_store.get("weekly_duel_ranking:#{st_i}_#{end_i}_#{server_type}_str")
      unless  ret
        set = WeeklyDuelRanking::get_order_ranking(server_type, st_i, end_i)
        ret = []
        if set
          set.each do |s|
            ret << s.name
            ret << s.arrow
            ret << s.point
          end
        end
        ret = ret.join(",")
        cache_store.set("weekly_duel_ranking:#{st_i}_#{end_i}_#{server_type}_str", ret,RANK_CACHE_TTL)
      end
      ret
    end
  end

end
