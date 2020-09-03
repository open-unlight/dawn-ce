# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class TotalEventRanking < Sequel::Model
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
      integer     :avatar_id,  :index=>true   # :table => :avatars
      String      :name, :default =>""
      integer     :point, :default =>0
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # DBにテーブルをつくる
    if !(TotalEventRanking.table_exists?)
      TotalEventRanking.create_table
    end

    DB.alter_table :total_event_rankings do
      add_column :server_type, :integer, :default => 0 unless Unlight::TotalEventRanking.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def TotalEventRanking::ranking_data
      TotalEventRanking
    end

    def TotalEventRanking::ranking_data_count(server_type)
      TotalEventRanking.filter(:server_type=>server_type).count
    end

    def TotalEventRanking::data_type
      "frog"
    end

    extend TotalRanking

    # 指定したキャラのランキングを取得する
    def TotalEventRanking::get_ranking(a_id, server_type, point = 0)
      index = get_order_ranking_id(server_type).index(a_id)

      lr = last_ranking(server_type)
      # 100番より値が低くて
      if lr >= point && point>0
        ret = {:rank =>EstimationRanking::get_ranking(RANK_TYPE_TE, server_type, point), :arrow=>RANK_NONE,:point=>point}
      elsif index && index < RANKING_COUNT_NUM
        ret = {:rank =>index +1, :arrow=>get_arrow_set(server_type)[index], :point=>point}
      else
        ret = {:rank =>0, :arrow=>RANK_NONE, :point=>point}
      end
      ret
    end

    # ランキング集計
    def TotalEventRanking::start_up(server_type)
      ret = 0
      if TOTAL_EVENT_RANKING_TYPE_FRIEND
        ret = self::start_up_friend(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ACHIEVEMENT
        ret = self::start_up_achievement(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ITEM_NUM
        ret = self::start_up_item_num(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ITEM_POINT
        ret = self::start_up_item_point(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_PRF_ALL_DMG
        ret = self::start_up_prf_all_dmg(server_type)
      end
      ret
    end

    # アイテム個数などでポイント管理するイベント時の処理(フレンド分も換算ver)
    def TotalEventRanking::start_up_friend(server_type)
      set_hash = { }
      hash_clone = { }

      # 特定アイテム分の換算
      av_set = Avatar.join(ItemInventory.filter([[:avatar_item_id , EVENT_WITH_FRIEND_ITEM_ID_RANGE],[:server_type,server_type]]), :avatar_id=>:id).all
      av_set.each {  |av|
        set_hash[ av.player_id ] = { :a_id=>av.values[:avatar_id],:a_name=>av.name, :value=>0 } unless set_hash[ av.player_id ]
        set_hash[ av.player_id ][:value] += EVENT_ITEM_POINTS[av.values[:avatar_item_id]]
        hash_clone[ av.player_id ] = { :a_id=>av.values[:avatar_id],:a_name=>av.name, :value=>0 } unless hash_clone[ av.player_id ]
        hash_clone[ av.player_id ][:value] += EVENT_ITEM_POINTS[av.values[:avatar_item_id]]
      }

      # 計算したポイントを各々のフレンドに加算
      friend_point_hash = { }
      hash_clone.each {  |key,val|
        # フレンド一覧を取得
        links = FriendLink.get_link(key,server_type)
        links.each {  |fl|
          if fl.friend_type == FriendLink::TYPE_FRIEND
            f_p_id = fl.other_id(key)
            if hash_clone[ f_p_id ] != nil && hash_clone[ f_p_id ][:value] > 0
              friend_point_hash[ key ] = 0  unless friend_point_hash[ key ]
              friend_point_hash[ key ] += hash_clone[ f_p_id ][:value]
            end
          end
        }
      }
      friend_point_hash.each { |key,val|
        # フレンド分は調整してから加算
        if set_hash[ key ] != nil
          set_hash[ key ][:value] += val / FRIEND_COEFFICIENT
        end
      }

      ranking_cnt = 0
      set_hash.sort_by{ |key, value| -value[:value]}.each { |key, value|
        TotalEventRanking::update_ranking( value[:a_id], value[:a_name], value[:value], server_type )
        ranking_cnt += 1
        break if ranking_cnt >= RANKING_COUNT_NUM
      }
    end

    # アチーブメントでポイント管理する場合のイベント時の処理
    def TotalEventRanking::start_up_achievement(server_type)
      av_set = Avatar.join(AchievementInventory.filter([[:achievement_id, TOTAL_EVENT_RANKING_ACHIEVEMENT_ID]]).order(Sequel.desc(:progress)).limit(RANKING_COUNT_NUM), :avatar_id=>:id,:server_type=>server_type).all
      av_set.each_with_index do |av,i|
        TotalEventRanking::update_ranking( av.values[:avatar_id], av.values[:name], av.values[:progress], server_type )
      end
    end

    # アイテム個数を換算する場合のイベント時の処理
    def TotalEventRanking::start_up_item_num(server_type)
      ii_set = AvatarItem.join(ItemInventory.filter([[:avatar_item_id,TOTAL_EVENT_RANKING_CNT_ITEM_IDS],[:server_type,server_type]])
                               .select_group(:avatar_item_id).select_append{ count(avatar_item_id).as(cnt)}, :avatar_item_id=>:id).all
      ii_set.each do |ii|
        TotalEventRanking::update_ranking( ii.id, ii.name, ii.values[:cnt], server_type )
      end
    end

    # アイテムポイントを換算する場合のイベント時の処理
    def TotalEventRanking::start_up_item_point(server_type)
      ii_set = AvatarItem.join(ItemInventory.filter([[:avatar_item_id,TOTAL_EVENT_RANKING_POINT_ITEM_IDS],[:server_type,server_type]])
                               .select_group(:avatar_item_id).select_append{ count(avatar_item_id).as(cnt)}, :avatar_item_id=>:id).all

      point = 0
      ii_set.each do |ii|
        point += ii.values[:cnt] * TOTAL_EVENT_RANKING_ITEM_POINT[ii.id]
      end

      TotalEventRanking::update_ranking( 1, QUEST_EVENT_RANKING_NAME, point, server_type )
    end

    # 渦ダメージ合算の場合のイベント時の処理
    def TotalEventRanking::start_up_prf_all_dmg(server_type)
      set_damage = 0
      check_prf_ids = Profound.filter([[:state,[PRF_ST_FINISH,PRF_ST_VANISH,4]],[:server_type,server_type]]).filter{ created_at > TOTAL_EVENT_RANKING_CHECK_PRF_TIME}.all.map { |prf| prf.id }
      if check_prf_ids&&check_prf_ids.size > 0
        pi_set = ProfoundInventory.filter([[:profound_id,check_prf_ids],[:state,PRF_INV_ST_SOLVED]]).filter{ score > 0 }.select_append{ sum(damage_count).as(all_damage) }.all
        if pi_set&&pi_set.size > 0
          set_damage = pi_set.first.values[:all_damage]
        end
      end

      TotalEventRanking::update_ranking( 1, PRF_DMG_EVENT_RANKING_NAME, set_damage, server_type )
    end

    def TotalEventRanking::point_avatars(server_type)
      ret = { }
      if TOTAL_EVENT_RANKING_TYPE_FRIEND
        ret = self::point_avatars_friend(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ACHIEVEMENT
        ret = self::point_avatars_achievement(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ITEM_NUM
        ret = self::point_avatars_item_num(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_ITEM_POINT
        ret = self::point_avatars_item_point(server_type)
      elsif TOTAL_EVENT_RANKING_TYPE_PRF_ALL_DMG
        ret = self::point_avatars_prf_all_dmg(server_type)
      end
      ret
    end

    # アイテム個数などでポイント管理するイベント時の処理(フレンド分も換算ver)
    def TotalEventRanking::point_avatars_friend(server_type)
      set_hash = { }
      hash_clone = { }

      # 特定アイテム分の換算
      av_set = Avatar.join(ItemInventory.filter([[:avatar_item_id , EVENT_WITH_FRIEND_ITEM_ID_RANGE],[:server_type,server_type]]), :avatar_id=>:id).all
      av_set.each {  |av|
        set_hash[ av.player_id ] = { :a_id=>av.values[:avatar_id],:a_name=>av.name, :value=>0 } unless set_hash[ av.player_id ]
        set_hash[ av.player_id ][:value] += EVENT_ITEM_POINTS[av.values[:avatar_item_id]]
        hash_clone[ av.player_id ] = { :a_id=>av.values[:avatar_id],:a_name=>av.name, :value=>0 } unless hash_clone[ av.player_id ]
        hash_clone[ av.player_id ][:value] += EVENT_ITEM_POINTS[av.values[:avatar_item_id]]
      }

      # 計算したポイントを各々のフレンドに加算
      hash_clone.each {  |key,val|
        # フレンド一覧を取得
        links = FriendLink.get_link(key,server_type)
        links.each {  |fl|
          f_p_id = fl.other_id(key)
          if hash_clone[ f_p_id ] != nil &&hash_clone[ f_p_id ][:value] > 0
            # フレンド分は調整してから加算
            if set_hash[ key ] != nil
              set_hash[ key ][:value] += hash_clone[ f_p_id ][:value] / FRIEND_COEFFICIENT
            end
          end
        }
      }

      avatars = { }
      set_hash.sort_by{ |key, value| -value[:value]}.each { |key, value|
        avatars[value[:a_id]] = value[:value]
      }
      avatars
    end

    # アチーブメントでポイント管理する場合のイベント時の処理
    def TotalEventRanking::point_avatars_achievement(server_type)
      av_set = Avatar.join(AchievementInventory.filter([[:achievement_id, TOTAL_EVENT_RANKING_ACHIEVEMENT_ID]]).order(Sequel.desc(:progress)), :avatar_id=>:id,:server_type=>server_type).all
      av_set.each_with_index do |av,i|
        TotalEventRanking::update_ranking( av.values[:avatar_id], av.values[:name], av.values[:progress], server_type)
      end

      avatars = { }
      av_set.each_with_index do |av,i|
        avatars[av.values[:avatar_id]] = av.values[:progress]
      end
      avatars
    end

    # アイテム個数を換算する場合のイベント時の処理
    def TotalEventRanking::point_avatars_item_num
      avatars = { }
      avatars
    end

    # アイテムポイントを換算する場合のイベント時の処理
    def TotalEventRanking::point_avatars_item_point
      avatars = { }
      avatars
    end

    # 渦の総ダメージ換算する場合のイベント時の処理
    def TotalEventRanking::point_avatars_prf_all_dmg
      avatars = { }
      avatars
    end

    initialize_ranking
  end

end
