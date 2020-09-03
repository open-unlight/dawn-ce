# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # デュエル観戦用クラス
  # Todo
  # ・コマンドをキャッシュに保存
  # ・キャッシュからコマンドを取得

  class WatchDuel
    attr_accessor :watch_start,:command_idx,:real_duel_data
    attr_reader :watch_finish

    WATCH_DATA_CACHE_TIME = (60*60*2)             # 観戦データを保存する時間
    COMMAND_CACHE_TIME    = (60*60*2)             # コマンドを保存する時間
    UPDATE_COMMAND_MAX    = 10                    # updateで一度に取得する最大コマンド数
    COMMAND_WAIT_SET_CNT  = 3                     # 待機時間を加算する取得コマンド数
    COMMAND_ACT_WAIT_CNT  = 1                     # 取得後のコマンドを(COMMAND_WAIT_SET_CNT)分取得した際に発生する待機時間

    DUEL_FINISH_FUNC_STR = "duel_finish_handler"  # Duel終了Command
    DUEL_ABORT_FUNC_STR  = "duel_abort_finish"    # Duel強制終了Command

    def initialize(match_uid, is_watch, pl_id=0, foe_id=0)
      @key = match_uid      # match_uidをkeyにしてキャッシュ操作する
      @act_command = []     # コマンドを保存していく配列を初期化
      @command_idx = 0      # コマンドを進行していくインデックス(観戦時に使用)
      @wait_count = 0       # 待機カウント
      @watch_start  = false # 観戦開始判定
      @watch_finish = false # 観戦終了判定
      @real_duel_data = nil # リアルタイムのDuel状況

      # 観戦希望ならコマンド取得、保存ならデータをキャッシュに保存
      if is_watch == true
        @act_command = WatchDuel::get_cache_act_command(@key)
        SERVER_LOG.info("WatchServer: [WatchDuel.#{__method__}] key:#{@key}")
      else
        self.set_cache_duel_data(match_uid, pl_id, foe_id)
        SERVER_LOG.info("GameServer: [WatchDuel.#{__method__}] key:#{@key}")
      end
    end

    # キャッシュからDuelデータを取得
    def WatchDuel::get_cache_duel_data(key)
      CACHE.get("watch_duel:#{key}")
    end

    # キャッシュから実行コマンド一覧を取得
    def WatchDuel::get_cache_act_command(key)
      CACHE.get("watch_duel_command:#{key}")
    end

    # キャッシュにDuelデータを保存
    def set_cache_duel_data(match_uid, pl_id, foe_id)
      # キャッシュ保存用データ
      set_data = {
        :pl_id => pl_id,
        :foe_id => foe_id
      }
      CACHE.set("watch_duel:#{@key}", set_data, WATCH_DATA_CACHE_TIME)
      # コマンドをクリアしておく
      self.all_clear_add_command
    end

    # キャッシュからDuelデータを取得
    def get_cache_duel_data
      WatchDuel::get_cache_duel_data(@key)
    end

    # キャッシュから実行コマンド一覧を取得
    def get_cache_act_command
      WatchDuel::get_cache_act_command(@key)
    end

    # 保存形式にコマンド履歴を変換
    def convert_commands(commands)
      ret = (commands) ? commands.join("-") : ""
      ret
    end

    # 受け取ったコマンドを配列に保存
    def make_set_act_command( method=nil, args=nil )
      if @act_command && method
        if @act_command.length > 0
          if @act_command.first[:func] != DUEL_ABORT_FUNC_STR
            # コマンド配列の末尾が終了なら一度抜く
            pop_command = @act_command.pop if @act_command[-1][:func] == DUEL_FINISH_FUNC_STR
            # コマンドを追加
            @act_command.push({:func => method, :args => args })
            # 抜いた場合、入れなおす
            @act_command.push(pop_command) if pop_command != nil
          end
        else
          # 最初なのでそのまま追加
          @act_command.push({:func => method, :args => args })
        end
      end
    end

    # 実行コマンドを保存
    def set_cache_act_command( args=nil, method=nil )
      method = parse_caller(caller.first) unless method
      make_set_act_command(method,args)
      CACHE.set("watch_duel_command:#{@key}", @act_command, COMMAND_CACHE_TIME)
    end

    # 終了コマンドを保存
    def set_cache_finish_command(*args)
      make_set_act_command(DUEL_FINISH_FUNC_STR,args)
      CACHE.set("watch_duel_command:#{@key}", @act_command, COMMAND_CACHE_TIME)
    end

    # 異常終了コマンドを保存
    def set_cache_abort_command
      @act_command = [{:func => DUEL_ABORT_FUNC_STR, :args => nil }]
      CACHE.set("watch_duel_command:#{@key}", @act_command, COMMAND_CACHE_TIME)
    end

    # 呼び出しもと関数名を取得
    def parse_caller(at)
      ret = ""
      if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
        ret = $3
      end
      ret
    end

    # 待機時間の更新
    def update_wait_count
      @wait_count -= 1 if @wait_count > 0
      (@wait_count > 0)
    end

    # 次のコマンドを取得
    def get_next_act_command(get_cnt=UPDATE_COMMAND_MAX)
      # 常に更新していく
      @act_command = get_cache_act_command
      ret = get_finish_command                          # 終了コマンドを優先して取得
      ret = get_init_commands if @real_duel_data != nil # 初期設定コマンドを優先して取得
      if ret==nil && @act_command && get_cnt > 0
        ret = []
        cnt = 0
        get_cnt.times {
          if @act_command.length > @command_idx
            ret.push(@act_command[@command_idx])
            @command_idx += 1
            cnt += 1
            if cnt >= COMMAND_WAIT_SET_CNT
              @wait_count += COMMAND_ACT_WAIT_CNT
              cnt = 0
            end
          end
        }
      end
      ret
    end

    # 次のコマンドを取得
    def get_next_act_command_all
      # 常に更新していく
      @act_command = get_cache_act_command
      ret = get_finish_command # 終了コマンドを優先して取得
      if ret==nil && @act_command && get_cnt > 0
        ret = []
        if @act_command.length > @command_idx
          ret.push(@act_command[@command_idx])
          @command_idx += 1
        end
      end
      ret
    end

    # 終了コマンドがあれば取得
    def get_finish_command
      ret = nil
      # コマンド履歴の先頭が戦闘終了コマンドか
      if @act_command && @act_command.length > 0 && @act_command.first[:func]==DUEL_ABORT_FUNC_STR
        ret = [@act_command.first]
        @watch_finish = true
      end
      ret
    end

    # 初期設定コマンドがあれば取得
    def get_init_commands
      ret = nil
      if @real_duel_data.init_commands && @real_duel_data.init_commands.length> 0
        ret = @real_duel_data.init_commands
      end
      # 取得してしまったら、データを消してしまう
      @real_duel_data.finalize
      @real_duel_data = nil
      ret
    end

    # キャッシュに保存したデータを削除
    def clear_duel_data
      CACHE.set("watch_duel:#{@key}", nil, 1)
    end

    # キャッシュに保存した履歴をすべて削除
    def all_clear_add_command
      CACHE.set("watch_duel_command:#{@key}", nil, 1)
    end

  end
end
