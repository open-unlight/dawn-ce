# -*- coding: utf-8 -*-
#
# 定数モジュール
#

module Unlight
  # ライブラリのパス
  $:.unshift File.expand_path(File.dirname(__FILE__))
  LIB_PATH = File.dirname(__FILE__).gsub("src/constants","")+'lib'
  # BotTest用セッションキー固定
  BOT_SESSION =false
  BOT_SESSION_KEY = "49c5de87eced403d533526afc6ef0cbe3993efcd"

  # ============== サーバタイプ ==================
  SERVER_SB = 0

  # ============== DB組み合わせタイプ ==================
  USE_DB_TYPE = {
    SERVER_SB => [SERVER_SB],
  }

  #
  # ============== カード種類をON/OFF ==================
  #
  CARD_KIND_ON = true

  # ============== 課金アイテム種別 ==================
  RMI_TYPE_ITEM        = 0
  RMI_TYPE_PARTS       = 1
  RMI_TYPE_EVENT_CARD  = 2
  RMI_TYPE_WEAPON_CARD = 3
  RMI_TYPE_CHARA_CARD  = 4
  RMI_TYPE_DECK        = 5


  # ============== Duelルール関連定数 ==================

  # イニシアチブ待ち時間
  INIT_WAIT_TIME  = 120
  # 移動待ち時間
  MOVE_WAIT_TIME = 120
  # 攻撃待ち時間
  BATTLE_WAIT_TIME = 120
  # 引き分けのターン
  BATTLE_TIMEOUT_TURN = 18
  #
  # 初期の距離
  DEFAULT_DISTANCE = 2

  # 対戦ルールの種類
  # 0:1対1，1:3対3
  RULE_1VS1, RULE_3VS3  = (0..1).to_a


  # 対戦ルールでの必須人数
  DUEL_CARDS_NUM  = [1,3]

  # 対戦の状態
  MATCH_OK,  MATCH_START, MATCH_END, MATCH_ABORT, MATCH_ABORT_END = (0..5).to_a

  # 対戦結果のアラート
  M_WARN_SAME_IP = 1

  # 対戦の結果
  RESULT_WIN       = 0
  RESULT_LOSE      = 1
  RESULT_DRAW      = 2
  RESULT_DEAD_END  = 3           # 行き止まりでクエストクリア
  RESULT_DELETE    = 4           # 削除でクエストクリア
  RESULT_PO_DELETE = 5           # PushOut削除でクエストクリア
  RESULT_TIMEUP    = 6           # レイド戦で指定ターンの終了

  # 移動フェイズに使えないイベントカードのイベントNO
  MOVE_RULE_EVENT_CARD_NO  = [11, 12, 13, 14, 15, 17]

  # 戦闘フェイズに使えないイベントカードのイベントNO
  BATTLE_RULE_EVENT_CARD_NO  = [18]

  # DEAD_END

  # 対戦サーバのデフォルトMAX人数
  DUEL_CHANNEL_MAX = 2000


  # ペナルティのタイプ
  DUEL_PENALTY_TYPE_AI = 0      # 相手が切り替わる
  DUEL_PENALTY_TYPE_ABORT = 1   # 中断になる

  # 中断ペナルティが発生するターン
  DUEL_PENALTY_TURN = 0

  # 観戦機能のON/OFF
  WATCH_MODE_ON = true

  # 観戦機能の設定
  DUEL_WATCH_MODE_OFF = 0
  DUEL_WATCH_MODE_ON  = 1

  # 接続チェックの間隔定数
  GAME_CHECK_CONNECT_INTERVAL = 10  # 10分割する
  # 切断チェック時間間隔
  GAME_CHECK_CONNECT_TIME_INTERVAL = 180  # 最後の接続確認から、3分以上反応がなければ、切断と断定


  # Raid戦時のダメージのスコアMAX値
  RAID_MAX_DAMAGE_SCORE = 100
  # ボーナスのスコア換算時の係数
  RAID_BONUS_SCORE_RATIO = 5

  # ============== EventDuelルール関連定数 ==================

  # プレイヤーマッチ
  PLAYER_MATCH = 0

  # AIのプレイヤーID
  AI_PLAYER_ID = 1

  # チャンネルごとのCPUランク(order順)
  CPU_RANK_TABLE = [1..99, 1..5, 1..3,  1..1]
  CPU_POP_TABLE =  [ false, false, false, false, false, false]

  # CPU部屋が沸くどうかのチェック間隔(s)
  CPU_POP_TIME = 60
  # CPU部屋が沸く数
  CPU_SPAWN_NUM = [
                   5,5,5,5,5,5, # UTC0-5時(9-14)
                   5,5,5,5,10,10, # UTC6-11時(15-20)
                   20,20,20,10,10,10, # UTC12-17時(21-2)
                   5,5,3,3,5,5, # UTC18-23時(3-8)
                  ]

  # 勝利報酬アイテムテーブル(未使用)
  CPU_DUEL_BONUS = [1,
                    1,
                    1,
                    1,
                    1,
                    1,
                    1,
                    1,
                    1,
                    1]


  CPU_AI_OLD = 10
  CPU_AI_MEDIUM = 15
  CPU_AI_FEAT_ON = 20

  # ============== RadderMatchEventDuelルール関連定数 ==================

  # CPURoomが追加される間隔(s)
  RADDER_CPU_POP_TIME = 2

  # CPURoomが追加される確率
  RADDER_CPU_POP_RAND = 90 # 3秒に1度、1/Xの確率で追加

  # CPURoomが1度のタイミングで参加者に追加される確率
  RADDER_CPU_CREATE_RAND = 1 # 待機中プレイヤーに対して、1/Xの確率で戦闘開始

  # on/off
  RADDER_CPU_POP_ENABLE = false

  # ============== クイックマッチで一定時間マッチしない場合CPUとマッチング ==================

  # CPUとマッチする時間(s) a..b : a～b 秒でCPUにマッチ
  MATCHING_TIME_LIMIT = (60..120).to_a

  # ============== レジスト関連定数 ==================
  # 初期から選択可能なパーツID
  REGIST_PARTS = [1,2,3,
                  5,6,7, 10,11,12, 15,16,17,
                  24,25,26,
                  27,28,29, 32,33,34, 37,38,39
                 ]
  # 初期から取得可能なキャラID
#  REGIST_CARDS = [1,3,4]#旧版
  REGIST_CARDS = [1,21,31,101,111]        # 新版

  # 初期から取得可能なイベントカードID
#  REGIST_EVENT_CARDS = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38]
  REGIST_EVENT_CARDS = []

  # デフォルトで着ている服
  DEFAULT_CLOTHES = [42,43]

  # ============== キャラカード関連定数 ==================
  # 会話ダイアログのタイプ定数
  DLG_DUEL_START, DLG_DUEL_END, DLG_QUEST_END_CHARA, DLG_QUEST_END_AVATAR, DLG_QUEST_EVENT, DLG_LOBBY, DLG_QUEST_START_CHARA = (0..6).to_a
  # キャラID定数
  CHARA_EVA, CHAR_IZA, CHAR_GRU, CHAR_ABE, CHAR_LEA, CHAR_KRO, CHAR_JEA, CHAR_ARC, CHAR_MAX, CHAR_BLA  = (0..9).to_a

  # ===== 捨てる予定 ========
  # モンスターカード
  MONSTAR_CARD_ID = 1001
  # コインカード
  COIN_CARD_ID = 10001
  # かけらカード
  TIPS_CARD_ID = 10006
  # ボスモンスターカード
  BOSS_MONSTAR_CARD_ID = 20001
  # ===== 捨てる予定 ========

  # コインのセット
  COIN_IRON_ID     = 10001
  COIN_BRONZE_ID   = 10002
  COIN_SILVER_ID   = 10003
  COIN_GOLD_ID     = 10004
  COIN_PLATINUM_ID = 10005

  # EXコインカード
  EX_COIN_CARD_ID = 10011
  # EXかけらカード
  EX_TIPS_CARD_ID = 10012

  # コインのセット
  COIN_SET = [1,COIN_IRON_ID, COIN_BRONZE_ID, COIN_SILVER_ID, COIN_PLATINUM_ID]

  # 汚染イベントカード
  USELESS_EVENT_CARD_ID = 84
  # 剣5銃5イベントカード
  S5A5_EVENT_CARD_ID = 85
  # 回復3イベントカード
  HP5_EVENT_CARD_ID = 86
  # チャンス5イベントカード
  CHANCE5_EVENT_CARD_ID = 87
  # 臨時イベントカードのセット
  SPECIAL_EVENT_CARDS = [USELESS_EVENT_CARD_ID, S5A5_EVENT_CARD_ID, HP5_EVENT_CARD_ID, CHANCE5_EVENT_CARD_ID]

  # 銃1盾1イベントカード
  A1D1_EVENT_CARD_ID = 88
  # 剣1剣1イベントカード
  S1S1_EVENT_CARD_ID = 89
  # 銃1銃1イベントカード
  A1A1_EVENT_CARD_ID = 90
  # 銃1剣1イベントカード
  A1S1_EVENT_CARD_ID = 91
  # 銃1移1イベントカード
  A1M1_EVENT_CARD_ID = 92
  # 銃1特1イベントカード
  A1E1_EVENT_CARD_ID = 93
  # 分解イベントカードのセット
  ARROW_EVENT_CARDS = [A1D1_EVENT_CARD_ID, S1S1_EVENT_CARD_ID, A1A1_EVENT_CARD_ID, A1S1_EVENT_CARD_ID, A1M1_EVENT_CARD_ID, A1E1_EVENT_CARD_ID]
  # 分解カードの作成上限
  ARROW_EVENT_CARDS_MAX = 40

  # フォーカスカード
  FOCUS_EVENT_CARD_MOVE20 = 94

  # 移1イベントカード
  MOVE_EVENT_CARD1 = 95
  # 移2イベントカード
  MOVE_EVENT_CARD2 = 96
  # 移3イベントカード
  MOVE_EVENT_CARD3 = 97
  # 移4イベントカード
  MOVE_EVENT_CARD4 = 98
  # 移5イベントカード
  MOVE_EVENT_CARD5 = 99
  # Jokerイベントカード
  JOKER_EVENT_CARD = 105
  JOKER_EVENT_NO = 19

  # 移動イベントカードのセット
  MOVE_EVENT_CARDS = [MOVE_EVENT_CARD1, MOVE_EVENT_CARD2, MOVE_EVENT_CARD3, MOVE_EVENT_CARD4, MOVE_EVENT_CARD5]

  # 亀用イベントカードセット
  TORTO_EVENT_CARDS = [100, 101, 102, 103, 104]

  # モンスターID
  MONSTAR_ID = 101

  # コインの交換レート
  EX_COIN_RATE = 1
  EX_COIN_GOLD_RATE = 3
  EX_COIN_PLATINUM_RATE = 1

  # ケイオシウム交換レート
  EX_TIPS_RATE = 1

  # ============== アバター関連定数 ==================
  # アバターのパーツの種類定数
  PART_HEAD, PART_HAIR, PART_EYE, PART_BODY, PART_ACCE, PART_SHOES, = (0..5).to_a

  # アバターのアイテムの種類定数
  ITEM_BASIS, ITEM_AUTO_PLAY, ITEM_DUEL, ITEM_SPECIAL, = (0..4).to_a

  # アバターのアイテム状態定数
  ITEM_STATE_NOT_USE, ITEM_STATE_USING, ITEM_STATE_USED = (0..2).to_a

  # アバターのレーティングポイント
  DEFAULT_RATING_POINT = 1500

  # アバターのクエスト所持限界
  QUEST_MAX = 4

  # クエストプレゼント同IP制限保存時間 (8時間)
  QUEST_SEND_SAME_IP_LIMIT = (60*60*8)
  # QUEST_SEND_SAME_IP_LIMIT = 1

  # クエストキャップ
  # locale_constantsに移動！
  # QUEST_CAP = 11

  RANK_ARROW_TTL = 60*60*24           # 何秒間隔でアローを更新すべきか（２４時間前の状態と比べてのランキング変化）

  RANK_CACHE_TTL = 60*5          # 何秒キャッシュするか

  RANK_OUT_LIMIT = 999          # 圏外のアバターをどれだけデータとして取る？
  RANK_OUT_SLEEP = 1            # 圏外のアバターを更新するときにどれくらいゆっくり更新するか？

  # アバターのデッキ所持限界
  DECK_MAX = 11 # Binderの分を含む為、実際は-1

  # ============== プレイヤー関連定数 ==================
  MAX_BLOCK_NUM = 10            # ブロック出来るプレイヤー数

  # プレイヤーの役割定数（追加はいいが変更はダメ）
  # 0:通常プレイヤー, 1:管理者, 2:GM, 3:BL登録プレイヤー,4:CPUプレイヤー
  ROLE_PLAYER, ROLE_ADMIN, ROLE_GM, ROLE_BLPL, ROLE_CPU, ROLE_RSV1, ROLE_RSV2, ROLE_RSV3 = (0..7).to_a

  # テーブル識別列挙
  # 0:手札, 1:移動ドロップテーブル, 2:戦闘ドロップテーブル
  TABLE_HAND, TABLE_MOVE, TABLE_BATTLE = (0..2).to_a

  # プレイヤーの状態定数（追加はいいが変更はダメ）
  # 0:ログアウト中, 1:ログイン, 2:認証中（ログアウト済み）3:認証中（ログイン済み）
  ST_LOGOUT = 0b0000            # 0
  ST_LOGIN  = 0b0001            # 1
  ST_AUTH   = 0b0010            # 2
  ST_LOGIN_AUTH = 0b0011        # 3

  # 所有できるデッキの最大数
  DEFAULT_DECK_NUM = 3

  # 登録の結果定数
  # 0b0001 = 名前, 0b0010=Email, 0b_0100 = PASS,
  RG_NG = {
    :none     => 0b0000,
    :name     => 0b0001,
    :email    => 0b0010,
    :salt     => 0b0100,
  }

  # プレイヤーのペナルティ定数（追加はいいが変更はダメ）
  # 0:なし, 1:警告あり, 255:永久追放
  # これフラグにすべきか？0:bit チャット禁止 3:禁止時間 一時
  # まあ保留
  PN_NONE = 0                   # 0000_0000
  PN_WARN = 1                   # 0000_0001
  PN_PASS_FAIL = 2              # 0000_0010
  PN_LOCK = 128                 # 1000_0000
  PN_SAME_IP = 256              # 0000_0001_0000_0000
  # PN_COMEBACK = 4096            # 0001_0000_0000_0000 # 2012/08/23 カムバックしてきた
  # PN_COMEBACK = 8192            # 0010_0000_0000_0000 # 2013/06/05 カムバックしてきた
  PN_COMEBACK = 16384           # 0100_0000_0000_0000 # 2015/01/07 カムバックしてきた
  PN_2015_NY = 32768            # 1000_0000_0000_0000 # 2015/01/01 新年ログイン

  #プレイヤーの自動セーブ間隔(秒)
  SAVE_INTERVAL = 60*10

  #プレイヤデータのバージョン
  PL_DATA_VER = "0.1"

  # ============== モデル関連定数 ==================
  #
  MODEL_CACHE_INT = 10000000

  # ============== DB関連定数 ==================

  # memcached server
# CACHE = MemCache.new MEMCACHE_CONFIG, MEMCACHE_OPTIONS
  CACHE = Dalli::Client.new MEMCACHE_CONFIG, MEMCACHE_OPTIONS
  # キャッシュを念のため全削除
  CACHE.flush_all

  #Sqlite3設定のデフォルト
  SQLITE3 =  {
    :DB_File => File.dirname(__FILE__).gsub("src/constants","")+'data/game_dev2.db',
    :LOG_File =>File.dirname(__FILE__).gsub("src/constants","")+'data/db.log',
  }

  case STORE_TYPE
  when :sqlite3
  # ログレベル
    DB_SERVER_LOG = Logger.new(File.dirname(__FILE__).gsub("src/constants","")+"data/#{$SERVER_NAME}_mysqldb.log", 48, 10*1024*1024)
    DB_SERVER_LOG.level = Logger::DEBUG
#    DB = Sequel.connect("sqlite://#{SQLITE3[:DB_File]}", :loggers => [Logger.new(SQLITE3[:LOG_File],3,)])
    DB = Sequel.connect("sqlite://#{SQLITE3[:DB_File]}", :loggers => [DB_SERVER_LOG])
  when :mysql
#    Sequel::MySQL2.default_engine = 'InnoDB'
    DB = Sequel.mysql2(nil,MYSQL_CONFIG)
  end
#  DB = Sequel.mysql(nil,MYSQL)

  Sequel.default_timezone = :utc

  # ============== 関連定数 ==================
  unless $SERVER_NAME
    $SERVER_NAME = "none"
  end

  # ログの出力先
  SERVER_LOG = Logger.new(File.dirname(__FILE__).gsub("src/constants","")+"bin/pids/#{$SERVER_NAME}.log", 128, 10*1024*1024)
  # ログレベル
#  SERVER_LOG.level = Logger::DEBUG
  SERVER_LOG.level = Logger::INFO
  #  puts"いまconstantsがDBを初期化"
  #  SERVER_LOG.debug("Avatar: [add_new_achievement] ID: #{a_id}")

end

# sequelの高速化パッチ
class Time
  class << self
    def relaxed_rfc3339(date)
      if /\A\s*
          (-?\d+)-(\d\d)-(\d\d)
          [T ]
          (\d\d):(\d\d):(\d\d)
          (?:\.(\d+))?
          (Z|[+-]\d\d(?::?\d\d)?)?
          \s*\z/ix =~ date
        year = $1.to_i
        mon = $2.to_i
        day = $3.to_i
        hour = $4.to_i
        min = $5.to_i
        sec = $6.to_i
        usec = $7 ? "#{ $7}000000"[0,6].to_i : 0
        if $8
          zone = $8
          if zone == 'Z'
            offset = 0
          elsif zone =~ /^([+-])(\d\d):?(\d\d)?$/
            offset = ($1 == '+' ? 1 : -1) * ($2.to_i * 3600 + ($3 || 0).to_i * 60)
          end
          year, mon, day, hour, min, sec =
            apply_offset(year, mon, day, hour, min, sec, offset)
          t = self.utc(year, mon, day, hour, min, sec, usec)
          t.localtime unless zone =~ /Z|-00:?(00)?/
          t
        else
          self.local(year, mon, day, hour, min, sec, usec)
        end
      end
    end
  end
end

module Sequel
  def self.string_to_datetime(string)
    begin
      if datetime_class == DateTime
        DateTime.parse(string, convert_two_digit_years)
      elsif datetime_class.respond_to?(:relaxed_rfc3339)
        datetime_class.relaxed_rfc3339(string) || datetime_class.parse(string)
      else
        datetime_class.parse(string)
      end
    rescue => e
      raise convert_exception_class(e, InvalidValue)
    end
  end
end

# 新しい物が頭に追加される順序付きハッシュ
class OrderHash < Hash
  def initialize
    @keys = Array.new
    attr_accessor = @keys
  end

  #superとして、Hash#[]=を呼び出す
  def []=(key, value)
    super(key, value)
    unless @keys.include?(key)
      @keys.unshift(key)
    end
  end

  def clear
    @keys.clear
    super
  end

  def delete(key)
    if @keys.include?(key)
      @keys.delete(key)
      super(key)
    elsif
      yield(key)
    end
  end

  def each
    @keys.each{ |k|
      arr_tmp = Array.new
      arr_tmp << k
      arr_tmp << self[k]
      yield(arr_tmp)
    }
    return self
  end

  def each_pair
    @keys.each{ |k|
      yield(k, self[k])
    }
    return self
  end

  def reject!(&block)
    del = ""
     @keys.each{ |k|
             del = k if yield(k, self[k])
     }
    @keys.delete(del)
    return super &block
  end

  def each_value
    @keys.each{ |k|
      yield(self[k])
    }
    return self
  end

  def map
    arr_tmp = Array.new
    @keys.each{ |k|
      arg_arr = Array.new
      arg_arr << k
      arg_arr << self[k]
      arr_tmp << yield(arg_arr)
    }
    return arr_tmp
  end

  def sort_hash(&block)
    if block_given?
      arr_tmp = self.sort(&block)
    elsif
      arr_tmp = self.sort
    end
    hash_tmp = OrderHash.new
    arr_tmp.each{ |item|
      hash_tmp[item[0]] = item[1]
    }
    return hash_tmp
  end


end
