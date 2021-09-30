# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 概算ランキングクラス
  class EstimationRanking < Sequel::Model
    many_to_one :avatar # プレイヤーに複数所持される

    RANK_TYPE_ID_OFFSET = [200, 0, 300, 100, 0, 200]

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # キャッシュをON
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    BASE_RANKING_NUM = 100
    def self.reset_table
      cnt = 0
      USE_DB_TYPE[THIS_SERVER].each do |server_type|
        BASE_RANKING_NUM.times do |_i|
          unless EstimationRanking[cnt + 1]
            # TDを作る
            EstimationRanking.new do |e|
              e.rank_type = RANK_TYPE_TD
              e.server_type = server_type
              e.save_changes
            end
          end
          cnt += 1
        end
        BASE_RANKING_NUM.times do |_i|
          unless EstimationRanking[cnt + 1]
            # TQを作る
            EstimationRanking.new do |e|
              e.rank_type = RANK_TYPE_TQ
              e.server_type = server_type
              e.save_changes
            end
          end
          cnt += 1
        end
        BASE_RANKING_NUM.times do |_i|
          unless EstimationRanking[cnt + 1]
            # TEを作る
            EstimationRanking.new do |e|
              e.rank_type = RANK_TYPE_TE
              e.server_type = server_type
              e.save_changes
            end
          end
          cnt += 1
        end
      end
    end

    # 指定したアバターのランキングを取得する
    def self.get_ranking(t, stype, p)
      ret = 0
      if p.positive?
        er = EstimationRanking
             .filter(rank_type: t, server_type: stype)
             .and(Sequel.cast_string(:point) <= p)
             .and(Sequel.cast_string(:point) > 0) # rubocop:disable Style/NumericPredicate
             .order(:rank_index)
             .all
             .first
        # これだと100位以内も101位になるが、本来100位以内のポイントは来ないはずなので（来ても境界に誓いポイント）なので101を返す
        # （100以内を返してしまうと矛盾がおこる）
        if er && er.rank_index > 1 && er.point.positive?
          before = EstimationRanking[er.id - 1]
          if before&.point&.positive? && before.point - er.point != 0
            pt = p - er.point
            r = er.ranking + er.user_num
            ret = (r - pt * er.user_num / (before.point - er.point)).to_i
          else
            ret = 101
          end
        elsif er && er.rank_index == 1
          ret = 101
        end
      end
      ret
    end

    def self.is_reset_table?
      # テーブルが0じゃなければリセット処理済み
      !EstimationRanking.all.empty?
    end

    # 通算Duelランキングを更新する（なるべくSlaveで更新）
    def self.update_total_duel_ranking(server_type)
      reset_table if is_reset_table? == false
      step_sets = create_step(TotalDuelRanking.last_ranking(server_type), 0)
      user_num_sets = create_user_num(TotalDuelRanking.point_avatars(server_type), step_sets)
      create_estimate_rank(RANK_TYPE_TD, step_sets, user_num_sets, server_type)
    end

    # 通算Questランキングを更新する（なるべくSlaveで更新）
    def self.update_total_quest_ranking(server_type)
      reset_table if is_reset_table? == false
      step_sets = create_step(TotalQuestRanking.last_ranking(server_type), 0)
      user_num_sets = create_user_num(TotalQuestRanking.point_avatars(server_type), step_sets)
      create_estimate_rank(RANK_TYPE_TQ, step_sets, user_num_sets, server_type)
    end

    # 通算Questランキングを更新する（なるべくSlaveで更新）
    def self.update_total_event_ranking
      step_sets = create_step(TotalEventRanking.last_ranking(server_type), 0)
      user_num_sets = create_user_num(TotalEventRanking.point_avatars(server_type), step_sets)
      create_estimate_rank(RANK_TYPE_TE, step_sets, user_num_sets, server_type)
    end

    # 最低と最高（101位）のポイントをもらってx分割する
    def self.create_step(s, e)
      # ステップのMAXによって分割数を変化させる（基数が少ないのに割りすぎると制度が落ちる）
      if s < 100
        delimit = 10
      elsif s < 400
        delimit = 20
      elsif s < 1000
        delimit = 40
      else
        delimit = 100
      end
      step = (s - e) / delimit
      step_sets = []
      (delimit - 1).times do |i|
        step_sets << s - (i * step).to_i
      end
      step_sets << 1
      step_sets
    end

    # ステップごとのポイントあたりにどれだけアバターが存在するかを数える
    def self.create_user_num(avatars, step_sets)
      rank_counter = 0
      user_num_set = Array.new(BASE_RANKING_NUM, 0)
      avatars.each do |a|
        unless a[1] >= step_sets[rank_counter]
          while a[1] < step_sets[rank_counter]
            if step_sets[rank_counter + 1].nil?
              break
            else
              rank_counter += 1
            end
          end
        end
        user_num_set[rank_counter] += 1
      end
      # 概算なのでゲームをやってない連中も100位いないに入る可能性があるので100人以上の場合100に調整
      user_num_set[0] = RANKING_COUNT_NUM if user_num_set[0] > RANKING_COUNT_NUM
      user_num_set
    end

    # タイプに合わせて仮想ランキングをつくる
    def self.create_estimate_rank(rank_type, step_sets, user_num_sets, server_type)
      step_unum_sets = []
      BASE_RANKING_NUM.times do |i|
        step_unum_sets << [step_sets[i], user_num_sets[i]] unless (user_num_sets[i]).zero?
      end
      before_er = nil
      c_rank = 1
      c_point = 0

      est_rank_list = EstimationRanking.filter(rank_type: rank_type, server_type: server_type).order(Sequel.asc(:id)).all

      BASE_RANKING_NUM.times do |i|
        e = est_rank_list[i]
        if e
          if step_unum_sets[i]
            e.ranking = c_rank
            e.rank_type = rank_type                # ランキングのタイプ
            e.point = step_unum_sets[i][0]
            c_rank += step_unum_sets[i][1]
            e.user_num = step_unum_sets[i][1]
            e.rank_index = i + 1
          else
            e.ranking = 0
            e.user_num = 0
            e.point = 0
            e.rank_type = rank_type                # ランキングのタイプ
            e.rank_index = 0
          end
          e.save_changes
        end
      end
    end
  end
end
