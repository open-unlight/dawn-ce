# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

puts RUBY_VERSION
if RUBY_VERSION == "1.9.2"
  class Date::Format::Bag
    def method_missing(*arg)
    end
  end
end


module Unlight

  module MatchController
    RADDER_DECK_COST_LIMEN  = 5  # コストレベル差の制限
    RADDER_DECK_LV_LIMEN    = 10  # デッキレベル差の制限
    RADDER_BP_LIMEN         = 300 # BP差の制限
    RADDER_WAITING_TIME     = 3   # 最低マッチウィエト回数
    RADDER_MATCH_USER_MIN   = 10  # 入っているユーザーがこのパーセント以下の場合サーバーを閉じる

    # 定期的に_roomの更新情報を送る（変化があれば）
    def update_room

    end

    # コネクションの生存確認（）
    def check_connection
    end


    # サーバのOn/Offの更新
    def self::check_boot(server_channel)

      if server_channel
        server_channel.refresh
        b = server_channel.before_channel
        return unless b          # 自分が最後のチャンネルならなにもしない
        return if server_channel.rule == 0          # ルールがディートならば閉じない
        return if server_channel.rule == 0 # ルールがディートならなにもしない
        # チャンネルがオフの時なら起動チェック、オンの時なら終了チェック
        if server_channel.state == Unlight::DSS_DOWN
          if b.congestion_rate > 90
            server_channel.boot(false)
          end
        else
          # 自分の一つ前のチャンネルが満杯でなく勝つ、自分のところのユーザーが規定より少なかったらシャットダウンする
          if b.congestion_rate < 70 && server_channel.congestion_rate < RADDER_MATCH_USER_MIN
            server_channel.shut_down
          end
        end
      end
    end

    def self::init
      @@radder_match_waiting_list = { }
    end

    def self::radder_match_waiting_list
      @@radder_match_waiting_list
    end

    # ======================================
    # 受信コマンド
    # =====================================

    # 現在いるチャンネルのマッチリストを取得する
    def cs_request_match_list_info
      if server_channel
        if Match.room_size(server_channel) > 0
          sc_matching_info(Match::room_list_info_str(server_channel))
        else
          sc_matching_info("-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1")
        end
      end
    end

    # クイックマッチ用のユーザリストに実際に追加する関数
    def add_quickmatch_list(rule = RULE_3VS3)
      ret = 0
      # すでに登録しているか
      if @@radder_match_waiting_list.key?(@player.id)
        SERVER_LOG.info("<UID:#{@uid}>MatchServer: [cs_add_quickmatch_list] already add list player:#{@player.id},#{@@radder_match_waiting_list}");
        # おかしいので削除の上でキャンセルコマンドを送る

        @@radder_match_waiting_list.delete(@player.id)
        sc_quickmatch_cancel
        ret = ERROR_DUEL_RADDER_ERROR
        return ret
      end
      avatar = @player.current_avatar
      deck = avatar.chara_card_decks[avatar.current_deck]
      # コスト判定か、レベル判定か
      if DUEL_RADDER_MATCH_COST
        check_val = avatar.chara_card_decks[avatar.current_deck].current_cost
      else
        check_val = avatar.chara_card_decks[avatar.current_deck].current_level
      end
      @@radder_match_waiting_list[@player.id] = {:bp=>avatar.point, :check_val=>check_val, :rule =>rule, :started=>false, :waiting_time=>RADDER_WAITING_TIME, :time_limit=>Time.now.utc()+MATCHING_TIME_LIMIT[rand(MATCHING_TIME_LIMIT.size)] }
      return ret
    end


    # クイックマッチ用のユーザーリストに追加
    def cs_add_quickmatch_list( rule )
      # プレイヤーはログインしていないと入れない
      unless @player
        return
      end

      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      if abort_penalty
        sc_error_no(ERROR_DUEL_CREATE_ROOM)
        return
      end

      # カレントデッキがない、カードが入っていないならそもそも入れない
      if @player.current_avatar.duel_deck == nil || @player.current_avatar.duel_deck.cards.size < 1
        sc_error_no(ERROR_NO_CURRENT_DECK)
        return
      end

      # APが存在するか？
      need_ap = RADDER_DUEL_AP[rule]
      unless  need_ap
        sc_error_no(ERROR_NO_RULE_MATCH)
        return
      end

      # ルールに適合した行動力があるか？
      unless  @player.current_avatar.duel_check_energy(need_ap)
        sc_error_no(ERROR_AP_LACK)
        return
      end

      # ルールに適応しているか？
      unless  @player.current_avatar.duel_deck.cards.size == DUEL_CARDS_NUM[RULE_3VS3]  || (!server_channel.is_radder?)
        sc_error_no(ERROR_NO_RULE_MATCH)
        return
      end

      # クイックマッチに登録
      ret = add_quickmatch_list
      # エラーなしならば
      if ret == 0
        sc_quickmatch_regist_ok
      end
    end

     # マッチングのキャンセル
     def cs_quickmatch_cancel
       # プレイヤーはログインしていないと入れない
       unless @player
         return
       end
       if @@radder_match_waiting_list[@player.id]&&@@radder_match_waiting_list[@player.id][:started] == false
         @@radder_match_waiting_list.delete(@player.id)
         sc_quickmatch_cancel
         SERVER_LOG.info("<UID:#{@uid}>MatchServer: [cs_quickmatch_cancel] player:#{@player.id}");
       end
     end


    # マッチングチェック用の関数
     def self::radder_matching_check(list)
       # リストをBP、コストの順でソートしてArrayに変換
       tmp_list =list.sort{ |a,b|
         if  a[1][:bp] == b[1][:bp]

           a[1][:check_val]<=>b[1][:check_val]
         else
           a[1][:bp] <=> b[1][:bp]
         end
       }

       # コスト判定か、レベル判定か
       if DUEL_RADDER_MATCH_COST
         limen_val = RADDER_DECK_COST_LIMEN
       else
         limen_val = RADDER_DECK_LV_LIMEN
       end

       tmp_list.each_with_index do |t,i|
         list[t[0]][:waiting_time] -=1
         unless list[t[0]][:started]||list[t[0]][:waiting_time] > 0
           (tmp_list.size-1-i).times do |ii|
             a = t[0]
             b = tmp_list[ii+i+1][0]
             pa = Player[a]
             pb = Player[b]
             # IPチェック
             ip_check = (Unlight::DUEL_IP_CHECK) ? (pa.last_ip != pb.last_ip) : true;
             # 8時間以内に対戦してる場合、相手に選ばれない
             match_cache1 = CACHE.get( "quickmatch_pair:#{a},#{b}" )
             match_cache2 = CACHE.get( "quickmatch_pair:#{b},#{a}" )

             a_p = list[a]
             b_p = list[b]
             if a_p && b_p && ip_check && !(match_cache1 || match_cache2) || pa.role == ROLE_ADMIN || pb.role == ROLE_ADMIN
               if (a_p[:bp]-b_p[:bp]).abs <= RADDER_BP_LIMEN && (a_p[:check_val] - b_p[:check_val]).abs <= limen_val
                 if a_p[:started] == false && b_p[:started] == false
                   a_p[:started] = b
                   b_p[:started] = a
                 end
                 break
               end
             end
           end
           # 規定時間を経過した
           if Unlight::Protocol::MatchServer::server_channel.is_radder? && Unlight::Protocol::MatchServer::server_channel.cpu_matching_type? != 0
             d = t[1][:time_limit] - Time.now.utc()
             if t[1][:time_limit] - Time.now.utc() < 0
               list[t[0]][:started] = AI_PLAYER_ID if list[t[0]][:started] == false
             end
           end
         end
       end
       cpu_radder_matching_start(@@radder_match_waiting_list,Unlight::Protocol::MatchServer::server_channel,Unlight::Protocol::MatchServer::match_list)
     end

    # マッチングを実際スタートする関数
    def self::radder_matching_start(list,channel,match_list)
      tmp_list = list.clone
      del_list = []
      # ペアを取り出す
      tmp_list.each do |k,v|
        unless v[:started]==false || v[:started] == true
          # すでにDuelを開始しているか？
          unless Match::room_from_player_id(k, channel.id)||Match::room_from_player_id(k, channel.id)
            # 部屋作成及び部屋に強制参加
            if match_list[k]
              room_id = match_list[k].create_quickmatch_room(v[:rule] )
            end
            if match_list[v[:started]] && room_id
              success = match_list[v[:started]].join_quickmatch_room( room_id ) if room_id
            end
            del_list << v[:started]
            del_list << k
            if success
              # 対戦相手をキャッシュに保持しておく
              CACHE.set("quickmatch_pair:#{k},#{v[:started]}", true, Unlight::DUEL_RADDER_LIST_CACHE_TIME )
            else
              # 失敗した場合
              if room_id
                # 作成した部屋を消す
                match_list[k].cs_room_exit if match_list[k]
              end
            end
            tmp_list[v[:started]][:started] = true if tmp_list[v[:started]]
            v[:started] = true
          end
        end
      end

      # マッチングしたユーザーをリストから削除
      del_list.each do |d|
        list.delete(d)
      end

    end

    # CPUマッチングチェック用の関数
     def self::cpu_radder_matching_check(list)
       # リストをBP、コストの順でソートしてArrayに変換
       tmp_list =list.sort{ |a,b|
         if  a[1][:bp] == b[1][:bp]

           a[1][:check_val]<=>b[1][:check_val]
         else
           a[1][:bp] <=> b[1][:bp]
         end
       }

       # 全ての対戦相手にCPUを入れる
       tmp_list.each_with_index do |t,i|
         unless list[t[0]][:started] #list[t[0]][:waiting_time] > 0
           list[t[0]][:started] = AI_PLAYER_ID if list[t[0]][:started] == false
         end
       end
       p tmp_list
     end

    # マッチングを実際スタートする関数
    def self::cpu_radder_matching_start(list,channel,match_list)
      tmp_list = list.clone
      del_list = []
      success = nil
      # CPUとマッチしているプレイヤーをマッチさせるペアを取り出す
      tmp_list.each do |k,v|
        success = nil
        if channel.cpu_matching_type? != 0 || rand(RADDER_CPU_CREATE_RAND) == 0
          if v[:started]==AI_PLAYER_ID
            # すでにDuelを開始しているか？
            unless Match::room_from_player_id(k, channel.id)||Match::room_from_player_id(k, channel.id)
              # CPU部屋を作成
              if channel
                room = self.get_cpu_room(0, 99, Player[k])
                @match = Match.create_room(channel, AI_PLAYER_ID, "R#{room.level} #{room.name}", 0, room.rule, 0, 0, room.cpu_card_data_id)
                # 作った部屋のidを送る
                if @match
                  success = match_list[k].cpu_quickmatch_join( @match.id ) if @match.id
                  info = @match.room_info_str
                  channel.player_list.each{  |p| match_list[p].sc_matching_info_update(info)if match_list[p] }
                end
              end
            end
          end

          if success
            v[:started] = true
            del_list << k
          else
            # 失敗した場合
            if @match && v[:started]==AI_PLAYER_ID
              # 作成した部屋を消す
              match_list[k].cs_room_exit if match_list[k]
            end
          end
        end
      end

      # マッチングしたユーザーをリストから削除
      del_list.each do |d|
        list.delete(d)
      end
    end

    # 一定間隔ごとに呼ばれるクイックマッチの更新
    def self::radder_match_update
      # リストに2人以上いないなら無意味 CPUマッチがある場合は一人でもチェック
      if Unlight::Protocol::MatchServer::server_channel.cpu_matching_type? == 0
        return if @@radder_match_waiting_list.size < 2
      else
        return if @@radder_match_waiting_list.size == 0
      end
      radder_matching_check(@@radder_match_waiting_list)
      radder_matching_start(@@radder_match_waiting_list,Unlight::Protocol::MatchServer::server_channel,Unlight::Protocol::MatchServer::match_list)
    end

    # 一定時間ごとに呼ばれるCPUクイックマッチの更新
    def self::cpu_radder_match_update
      # リストに1人以上いないまたはチャンネルがラダーマッチじゃない
      unless @@radder_match_waiting_list.size > 0 && (Unlight::Protocol::MatchServer::server_channel.is_radder?)
        return
      end
      cpu_radder_matching_check(@@radder_match_waiting_list)
      cpu_radder_matching_start(@@radder_match_waiting_list,Unlight::Protocol::MatchServer::server_channel,Unlight::Protocol::MatchServer::match_list)
    end

    # クイックマッチの部屋を作成する
    def create_quickmatch_room( rule )
      # 部屋を作成
      if server_channel && @match == nil && server_channel.is_radder?
        @match = Match.create_room(server_channel, @player.id, "QuickMatch", rand(STAGE_GATE), rule, 0, 0)
        # 作った部屋のidを送る
        if @match
          sc_create_room_id(@match.id);
          info = @match.room_info_str
          SERVER_LOG.info("<UID:#{@uid}>MatchServer: [create_quickmatch_room] id:#{info}");
        else
          SERVER_LOG.info("<UID:#{@uid}>MatchServer: [create_quickmatch_room] create failed.");
          return
        end
      else
        SERVER_LOG.info("<UID:#{@uid}>MatchServer: [create_quickmatch_room] create failed. not found server_channel or alraedy create.");
        return
      end
      @match.id
    end

    # クイックマッチの部屋に入る
    def join_quickmatch_room( room_id )
      # エラーチェック
      @match = server_channel.room_list[room_id] if server_channel&&@player

      # マッチが存在する？(部屋が存在しない)
      unless @match
        @match = nil
        SERVER_LOG.info("<UID:#{@uid}>MatchServer: [join_quickmatch_room] join faild.");
        return
      end

      ret = false

      # 相手を部屋に入れる
      ok = Match.room_join(server_channel, @match.id, @player.id)  if server_channel&&@player

      if ok
        @opponent_player = online_list[ok[0]]

        # 新しいプレイヤーが入室したことを同じチャンネルのプレイヤーにしらせる
        info = @match.room_info_str

        # 参加者以外に情報を信配
        server_channel.player_list.each{ |p| online_list[p].sc_matching_info_update(info) if online_list[p]}

        # 二人そろったのでデュエルを開始する
        if ok.size == Match::ROOM_CAP
          if online_list[ok[0]]
            @opponent_player = online_list[ok[0]]
            @opponent_player.opponent_player = self
            # 部屋のルールを見て決める
            @match_log =  MatchLog::create_room(server_channel.id, @match.name, @match.stage, @match.avatar_ids, @match.rule, @match.id, @match.cpu_card_data_id, server_channel.server_type, server_channel.watch_mode, 1, server_channel.rule)
            sc_quickmatch_join_ok(@match.id)
            @opponent_player.sc_match_join_ok(@match.id)
            Avatar[@match.avatar_ids[0]].achievement_check([EVENT_DUEL_3VS3_ACHIEVEMENT_ID])
            Avatar[@match.avatar_ids[1]].achievement_check([EVENT_DUEL_3VS3_ACHIEVEMENT_ID])
            ret = true
          else
            sc_error_no(ERROR_DUEL_ALREADY_START);
            @match = nil
            SERVER_LOG.info("<UID:#{@uid}>MatchServer: [join_quickmatch_room] join failed. not found op player");
          end
        else
          sc_error_no(ERROR_DUEL_ALREADY_START);
          @match = nil
          SERVER_LOG.info("<UID:#{@uid}>MatchServer: [join_quickmatch_room] join failed. size error");
        end
      elsif ok == nil
        sc_error_no(ERROR_DUEL_ALREADY_START);
        @match = nil
        SERVER_LOG.info("<UID:#{@uid}>MatchServer: [join_quickmatch_room] join failed. not join.");
      else
        sc_error_no(ERROR_DUEL_SAME_IP)
        @match = nil
        SERVER_LOG.info("<UID:#{@uid}>MatchServer: [join_quickmatch_room] same ip error.");
      end

      ret
    end

    # 新しい部屋を作成
    def cs_create_room(name, stage, rule, option = 0, level = 0)
      # プレイヤーはログインしていないと入れない
      unless @player
        return
      end

      # クイックマッチの部屋で普通の部屋は作れない
      if server_channel.is_radder?
        return
      end

      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      if abort_penalty
        case DUEL_PENALTY
        when DUEL_PENALTY_TYPE_AI
          sc_error_no(ERROR_DUEL_CREATE_ROOM)
          return
        end
      end

      # カレントデッキがない、カードが入っていないならそもそも入れない
      if @player.current_avatar.duel_deck == nil || @player.current_avatar.duel_deck.cards.size < 1
        sc_error_no(ERROR_NO_CURRENT_DECK)
        return
      end

      # APが存在するか？
      need_ap = option == DUEL_OPTION_FREE ? DUEL_AP[rule] : FRIEND_DUEL_AP[rule]
      unless  need_ap
        sc_error_no(ERROR_NO_RULE_MATCH)
        return
      end

      # ルールに適合した行動力があるか？
      unless  @player.current_avatar.duel_check_energy(need_ap)
        sc_error_no(ERROR_AP_LACK)
        return
      end

      # ルールに適応しているか？
      unless  @player.current_avatar.duel_deck.cards.size == DUEL_CARDS_NUM[rule]
        sc_error_no(ERROR_NO_RULE_MATCH)
        return
      end

      if server_channel && @match == nil
        @match = Match.create_room(server_channel, @player.id, name, stage, rule, option, level)
        # 作った部屋のidを送る
        if @match
          sc_create_room_id(@match.id);
          info = @match.room_info_str
          server_channel.player_list.each{  |p| online_list[p].sc_matching_info_update(info)if online_list[p] }
          SERVER_LOG.info("<UID:#{@uid}>GameServer: [create_room] id:#{info}");
        end
      end
    end

    # CPU部屋を更新
    def self::cpu_room_update
      c = Unlight::MatchServer::match_channel
      if c && CPU_POP_TABLE[c.order]
        room = self.get_cpu_room
        @match = Match.create_room(c, AI_PLAYER_ID, "R#{room.level} #{room.name}", 0, room.rule, 0, 0, room.cpu_card_data_id)
        # 作った部屋のidを送る
        if @match
          info = @match.room_info_str
          c.player_list.each{  |p| Unlight::MatchServer::match_list[p].sc_matching_info_update(info)if Unlight::MatchServer::match_list[p] }
        end
      end
    end

    # CPUROOMから1つランダムでかえす
    def self::get_cpu_room(low = 0, high = 99, player=nil)

      case Unlight::MatchServer::match_channel.cpu_matching_type?
      when CPU_MATCHING_TYPE_COST
        avatar = player.current_avatar
        deck_cost = avatar.chara_card_decks[avatar.current_deck].current_cost
        cost_conditions = Unlight::MatchServer::match_channel.cpu_matching_condition?.split(",").map{ |s| s.scan(/([\d~]+):([\d+]+)/)[0] }
        cost_conditions.each do |cond|
          range = cond[0].split("~", 2).map{ |n| n.to_i }
          room_ids = cond[1].split("+").map{ |n| n.to_i }
          SERVER_LOG.info("ids ... #{room_ids}")
          if check_condition(range, deck_cost)
            return CpuRoomData[room_ids[rand(room_ids.size)]]
          end
        end
      else
        o = Unlight::MatchServer::match_channel.order
        rs = CpuRoomData.filter([[:level, 1..99]])
        r = rs.all[rand(rs.count)]
        if r
          return r
        else
          return CpuRoomData[1]
        end
      end
    end

    # value が range の範囲にあるかチェックする
    def self::check_condition(range, value)
      if range[1] == 0
        return range[0] < value
      else
        return range[0] <= value && value <= range[1]
      end
    end

    # プレイヤルームに入る
    def normal_join(room_id)
      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      if abort_penalty
        sc_error_no(ERROR_DUEL_JOIN_ROOM)
        @match = nil
        return
      end

      # カレントデッキがない、カードが入っていないならそもそも入れない
      if @player.current_avatar.duel_deck == nil || @player.current_avatar.duel_deck.cards.size < 1
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end
      # カレントデッキにnilが入ったカードがある
      if @player.current_avatar.duel_deck.cards_invalid?
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end
      option = 0
      if @player.friend?(@match.player_array[0].id)
       option = Unlight::DUEL_OPTION_FRIEND
      end
      need_ap = option == DUEL_OPTION_FREE ? DUEL_AP[@match.rule] : FRIEND_DUEL_AP[@match.rule]
      # ルールに適合した行動力があるか？
      unless  @player.current_avatar.duel_check_energy(need_ap)
        sc_error_no(ERROR_AP_LACK)
        @match = nil
        return
      end
      # ルールに適応しているか？
      unless  @player.current_avatar.duel_deck.cards.size == DUEL_CARDS_NUM[@match.rule]
        sc_error_no(ERROR_NO_RULE_MATCH)
        @match = nil
        return
      end

      SERVER_LOG.info("<UID:#{@uid}>MatchServer: [room_join] @match: #{@match}");

      ok = Match.room_join(server_channel, room_id, @player.id)  if server_channel&&@player

      if ok
        @opponent_player = online_list[ok[0]]
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join ok. ok:#{ok} room_id:#{room_id} player_id:#{@player.id}");

        # 新しいプレイヤーが入室したことを同じチャンネルのプレイヤーにしらせる
        info = @match.room_info_str

        server_channel.player_list.each{ |p| online_list[p].sc_matching_info_update(info)if online_list[p] }
        # サーバにカードを送る
        # 二人そろったのでデュエルを開始する
        if ok.size >= Match::ROOM_CAP
          if online_list[ok[0]]
            @opponent_player = online_list[ok[0]]
            @opponent_player.opponent_player = self
            # 部屋のルールを見て決める
            @match_log =  MatchLog::create_room(server_channel.id, @match.name, @match.stage, @match.avatar_ids, @match.rule, @match.id, @match.cpu_card_data_id, server_channel.server_type, server_channel.watch_mode, 0, server_channel.rule)
            @opponent_player.sc_match_join_ok(@match.id)
            # 3vs3チェック
            if @match.rule == RULE_3VS3
              Avatar[@match.avatar_ids[0]].achievement_check([EVENT_DUEL_3VS3_ACHIEVEMENT_ID])
              Avatar[@match.avatar_ids[1]].achievement_check([EVENT_DUEL_3VS3_ACHIEVEMENT_ID])
            end
            # フレンドレコードチェック
            if option == Unlight::DUEL_OPTION_FRIEND
              Avatar[@match.avatar_ids[0]].achievement_check([EVENT_DUEL_FRIEND_ACHIEVEMENT_ID+@match.rule])
              Avatar[@match.avatar_ids[1]].achievement_check([EVENT_DUEL_FRIEND_ACHIEVEMENT_ID+@match.rule])
            end
          else
            sc_error_no(ERROR_DUEL_ALREADY_START);
            @match = nil
            SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join failed. not found op player");
          end
        else
          sc_error_no(ERROR_DUEL_ALREADY_START);
          @match = nil
          SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join failed. size error");
        end
      elsif ok == nil
        sc_error_no(ERROR_DUEL_ALREADY_START);
        @match = nil
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join failed. not join.");
      else
        sc_error_no(ERROR_DUEL_SAME_IP)
        @match = nil
        SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] same ip error.");
      end

    end

    # CPUルームに入る
    def cpu_join(room_id)
      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      if abort_penalty
        sc_error_no(ERROR_DUEL_CREATE_ROOM)
        return
      end

      # カレントデッキがない、カードが入っていないならそもそも入れない
      if @player.current_avatar.duel_deck == nil || @player.current_avatar.duel_deck.cards.size < 1
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end

      # カレントデッキにnilが入ったカードがある
      if @player.current_avatar.duel_deck.cards_invalid?
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end

      option = 0
      if @player.friend?(@match.player_array[0].id)
       option = Unlight::DUEL_OPTION_FRIEND
      end
      need_ap = option == DUEL_OPTION_FREE ? DUEL_AP[@match.rule] : FRIEND_DUEL_AP[@match.rule]
      # ルールに適合した行動力があるか？
      unless  @player.current_avatar.duel_check_energy(need_ap)
        sc_error_no(ERROR_AP_LACK)
        @match = nil
        return
      end
      # ルールに適応しているか？
      unless  @player.current_avatar.duel_deck.cards.size == DUEL_CARDS_NUM[@match.rule]
        sc_error_no(ERROR_NO_RULE_MATCH)
        @match = nil
        return
      end

      ok = Match.room_join(server_channel, room_id, @player.id)  if server_channel&&@player

      if ok
        # 新しいプレイヤーが入室したことを同じチャンネルのプレイヤーにしらせる
        info = @match.room_info_str
        server_channel.player_list.each{ |p| online_list[p].sc_matching_info_update(info)if online_list[p] }
        # サーバにカードを送る

        # 二人そろったのでデュエルを開始する
        # 部屋のルールを見て決める
        @match_log =  MatchLog::create_room(server_channel.id, @match.name, @match.stage, @match.avatar_ids, @match.rule, @match.id, @match.cpu_card_data_id, server_channel.server_type, server_channel.watch_mode, 0, server_channel.rule)
        sc_match_join_ok(@match.id)

        SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join ok. room_id:#{room_id} player_id:#{@player.id}");
      end
    end

    # QuickMatch専用のCPUルームに入る
    def cpu_quickmatch_join(room_id)
      @match = server_channel.room_list[room_id] if server_channel&&@player
      ret = false

      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      if abort_penalty
        sc_error_no(ERROR_DUEL_CREATE_ROOM)
        ret = false
      end

      # カレントデッキがない、カードが入っていないならそもそも入れない
      if @player.current_avatar.duel_deck == nil || @player.current_avatar.duel_deck.cards.size < 1
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end

      # カレントデッキにnilが入ったカードがある
      if @player.current_avatar.duel_deck.cards_invalid?
        sc_error_no(ERROR_NO_CURRENT_DECK)
        @match = nil
        return
      end

      need_ap = RADDER_DUEL_AP[@match.rule]
      # ルールに適合した行動力があるか？
      unless  @player.current_avatar.duel_check_energy(need_ap)
        sc_error_no(ERROR_AP_LACK)
        @match = nil
        return
      end
      # ルールに適応しているか？
      unless  @player.current_avatar.duel_deck.cards.size == DUEL_CARDS_NUM[@match.rule]
        sc_error_no(ERROR_NO_RULE_MATCH)
        @match = nil
        return
      end

      ok = Match.room_join(server_channel, room_id, @player.id)  if server_channel&&@player

      if ok
        # 新しいプレイヤーが入室したことを同じチャンネルのプレイヤーにしらせる
        info = @match.room_info_str
        server_channel.player_list.each{ |p| online_list[p].sc_matching_info_update(info)if online_list[p] }
        # サーバにカードを送る

        # 二人そろったのでデュエルを開始する
        # 部屋のルールを見て決める
        @match_log =  MatchLog::create_room(server_channel.id, @match.name, @match.stage, @match.avatar_ids, @match.rule, @match.id, @match.cpu_card_data_id, server_channel.server_type, server_channel.watch_mode, 0, server_channel.rule)

        # 入室した部屋のIDを送る
        sc_quickmatch_join_ok(@match.id)
        # 入室成功
        sc_match_join_ok(@match.id)

        SERVER_LOG.info("<UID:#{@uid}>GameServer: [room_join] join ok. room_id:#{room_id} player_id:#{@player.id}");
      end
    end


    # 指定した部屋に入室
    def cs_room_join(room_id)
      # AbortPenaltyがtrueなら入れない
      abort_penalty = CACHE.get( "penalty_id:#{@uid}" )
      abort_penalty = false
      if abort_penalty
        sc_error_no(ERROR_DUEL_JOIN_ROOM)
        return
      end

      # 指定IDのマッチがない、カレントデッキがない、カードが入っていない適応した行動力がない、必須人数でないならそもそも入れない、
      # プレイヤーはログインしていないと入れない
      unless @player
        sc_error_no(ERROR_DUEL_WRONG_ROOM)
        @match = nil
        return
      end

      # エラーチェック
      @match = server_channel.room_list[room_id] if server_channel&&@player

      # マッチが存在する？(部屋が存在しない)
      unless @match
        sc_error_no(ERROR_DUEL_WRONG_ROOM)
        @match = nil
        return
      end

      if @match.cpu?
        cpu_join(room_id)
      else
        normal_join(room_id)
      end
    end

    # 部屋から退出
    def cs_room_exit
      if  @player&&server_channel&&Match.exit_room(server_channel, @player.id)
        # キャッシュに保存されているMatchLogを削除
        MatchLog::delete_cache(@match.id)
        server_channel.player_list.each do |p|
          if @match
            online_list[p].sc_delete_room_id(@match.id) if online_list[p]
          end
        end
        sc_room_exit_success
        # 相手の対戦プレイヤーから自分をぬく中断などで対戦相手が残っているとき
        if @opponent_player
          @opponent_player.opponent_player = nil
          @opponent_player.cs_room_exit
          @opponent_player= nil
        end
      end
      @match = nil
      @match_log = nil
    end

    # マッチの終了
    def cs_match_finish
      if @opponent_player
        @opponent_player.opponent_player = nil
        @opponent_player.cs_room_exit
        @opponent_player= nil
      end
      cs_room_exit
    end

    # 強制部屋削除
    def cs_room_delete(room_id)
      SERVER_LOG.info("<UID:#{@uid}>MatchServer: [#{__method__}] id:#{room_id}")
      if @player&&server_channel
        del_match = server_channel.room_list[room_id] if server_channel&&@player
        # 見つからないのでなにもしない
        return unless del_match
        # 所持していて削除対象の場合、退出する
        if @match && @match.id == del_match.id
          SERVER_LOG.info("<UID:#{@uid}>MatchServer: [#{__method__}] @match:#{@match.id} del_match:#{del_match.id}")
          cs_room_exit
        end
        # 削除する
        Match::delete_room(server_channel,room_id)
      end
    end

      # アチーブメントクリアチェック
      def cs_achievement_clear_check
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_achievement_clear_check]")
        if @avatar
          @avatar.achievement_check
          n = @avatar.get_notice
          sc_add_notice(n) if n!=""&&n!=nil
        end
      end

      # マッチ部屋のひとがフレンドかどうか
      def cs_room_friend_check(room_id, host_avatar_id, guest_avatar_id)
        host_is_friend = host_avatar_id > 0 ? @player.friend?(Avatar[host_avatar_id].player_id) : false
        guest_is_friend = guest_avatar_id > 0 ? @player.friend?(Avatar[guest_avatar_id].player_id) : false
        sc_room_friend_info(room_id, host_is_friend, guest_is_friend)
      end

      def regist_avatar_event
        @avatar.init
        @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
        @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
        @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))
        @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))
      end

      # アチーブメントがクリアされた
      def achievement_clear_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_achievement_clear] #{ret}")
        sc_achievement_clear(*ret)
      end

      # アチーブメントが追加された
      def add_new_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_add_new_achievement] ID: #{ret}")
        sc_add_new_achievement(ret)
      end

      # アチーブメントが追加された
      def delete_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_delete_achievement] ID: #{ret}")
        sc_delete_achievement(ret)
      end

      # アチーブメントが更新された
      def update_achievement_info_event_handler(target,ret)
        sc_update_achievement_info(ret[0],ret[1],ret[2],ret[3],ret[4])
      end


    # 押し出し処理
    def pushout()
      online_list[@player.id].logout
    end

    def do_login
      # サーバーのルールが10番の時アドミン以外入れない
      if server_channel.rule == CRULE_EVENT &&  @player.role != ROLE_ADMIN
        logout
        return
      end

      # ログイン時に自分のチャンネルにJoinする
      server_channel.join_player(@player.id)
      sc_channel_join_success(server_channel.id)

      # 念の為、一度削除する
      @@radder_match_waiting_list.delete(@player.id) if @player

      if @player.avatars.size > 0
        @avatar = @player.avatars[0]
        regist_avatar_event
      end
    end

    # ログアウト時の処理
    def do_logout
      SERVER_LOG.info("<UID:#{@uid}>MatchServer: [Logout]")
      # 対戦相手がいる場合相手から
      if @opponent_player
        @opponent_player.opponent_player = nil
        @opponent_player.cs_room_exit if @opponent_player
        @opponent_player= nil
      end
      cs_room_exit
      # 自分がチャンネルにはいっていたらチャンネルから
      server_channel.exit_player(@player.id) if server_channel&&@player
      @@radder_match_waiting_list.delete(@player.id) if @player

      # 削除する
      sc_channel_exit_success

      # イベントを外す
      if @avatar
        @avatar.remove_all_event_listener
        @avatar.remove_all_hook
      end

    end

    # 相手の中断、ログアウト
    def opponent_duel_out
    end


    # 部屋のログイン人数をアップーデート
    def update_count
      if server_channel
        server_channel.update_count
        server_channel.player_list.each{  |p| online_list[p].sc_update_count(server_channel.player_list.size)if online_list[p] }
      end
    end
  end
end
