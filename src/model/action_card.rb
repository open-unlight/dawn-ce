# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # アクションカードクラス
  attr_accessor :deck,:owner,:duel
  attr_reader :rewritten

  class ActionCard < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 0:ブランク,1:近接 2:遠距離, 3:防御, 4:移動 5:特殊, 6:イベント, 7:フォーカス
    BLNK, SWD, ARW, DEF, MOVE, SPC, EVT, FCS = (0..7).to_a

    # スキーマの設定
    def self.create_table
      DB.create_table self.implicit_table_name do
        primary_key :id
        integer     :u_type, :default => 0
        integer     :u_value, :default => 1
        integer     :b_type, :default => 0
        integer     :b_value, :default => 1
        integer     :event_no, :default => 0
        String      :caption
        String      :image
        datetime    :created_at
        datetime    :updated_at
      end
    end

    # スキーマの設定
    def self.create_table!
      DB.drop_table self.implicit_table_name
      self.create_table
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる
    if !(DB.table_exists? self.implicit_table_name)
      ActionCard.create_table
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # アップデート後の後理処
    after_save do
      Unlight::ActionCard::refresh_data_version
    end


    # 全体データバージョンを返す
    def ActionCard::data_version
      ret = cache_store.get("ActionCardVersion")
      unless ret
        ret = refresh_data_version
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def ActionCard::refresh_data_version
      m = Unlight::ActionCard.order(:updated_at).last
      if m
        cache_store.set("ActionCardVersion",m.version)
        m.version
      else
        0
      end
    end

    # アクションカードをテキスト化する。デバッグ用
    def ActionCard::cards2str(cards)
      cards.map{ |c| ac2str(c) }.join("")
    end

    def ActionCard::ac2str(ac)
      "【" + ac.id.to_s + ":" + type2str(ac.u_type) + ac.u_value.to_s + "/" + type2str(ac.b_type) + ac.b_value.to_s + "】"
    end

    def ActionCard::type2str(type)
      case type
      when BLNK
        "無"
      when SWD
        "剣"
      when ARW
        "銃"
      when DEF
        "盾"
      when MOVE
        "移"
      when SPC
        "特"
      when EVT
        "イ"
      when FCS
        "フ"
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # 移動ポイント取得
    def move_point
      get_type_value(ActionCard::MOVE, up?)
    end

    # 攻撃ポイント取得
    def battle_point(type)
      get_type_value(type, up?)
    end

    # 近距離攻撃ポイント
    def swd_point
      get_type_value(ActionCard::SWD, up?)
    end

    # 防御ポイント
    def def_point
      get_type_value(ActionCard::DEF, up?)
    end

    # 遠距離攻撃ポイント
    def arw_point
      get_type_value(ActionCard::ARW, up?)
    end

    # 特殊攻撃ポイント
    def spc_point
      get_type_value(ActionCard::SPC, up?)
    end

    # タイプによる攻撃ポイント
    def get_type_value(type, u)
      ret = 0
      if u
        if self.u_type == type
          ret = self.u_value
        end
      elsif self.b_type == type
          ret = self.b_value
      end
      ret
    end

    # そのタイプのvalueが存在するか？（valueが有るときは丁度のみ）
    # 返り値[方向：value]
    # ないときnil
    def get_exist_value?(type, value = nil)
      ret = nil
      if self.u_type == type
        ret = [true,self.u_value]
      elsif self.b_type == type
        ret = [false, self.b_value]
      end

      # valueがあるとき同じでなければNilにする
      if ret && value
        ret = nil unless ret[1] == value
      end
      ret
    end

    # タイプを問わず特定のvalueが存在するか？
    # 返り値[方向：value]
    # ないときnil
    def get_exist_wld_card_value?(value)
      ret = nil
      if self.u_value == value
        ret =  [true, value]
      elsif self.b_value == value
        ret = [false, value]
      end

      # valueがあるとき同じでなければNilにする
      if ret && value
        ret = nil unless ret[1] == value
      end
      ret
    end

    # entrantが使うワイルドカードが存在するかのチェック
    def check_exist_wld_card_value?(value)
      ret = up? ? self.u_value == value : self.b_value == value
      ret
    end

    # カード内の最大ポイントを取得
    def get_value_max(type=nil)
      ret = 0
      if type

        uv = 0
        uv = self.u_value if self.u_type == type
        bv = 0
        bv = self.b_value if self.b_type == type
        if uv > bv
          ret = uv
        else
          ret = bv
        end

      else

        if self.u_value > self.b_value
          ret = self.u_value
        else
          ret = self.b_value
        end

      end
      ret
    end

    # 現在のタイプ
    def current_type
      up?? (self.u_type):(self.b_type)
    end

    # カードが保有するタイプを配列で返す
    def get_types
      ret = []
      ret << self.u_type
      ret << self.b_type if ret[0] != self.b_type
      ret
    end

    # カードの方向を決める
    def up(a)
      @dir = a unless a.nil?
    end

    # カードの方向
    def up?
      @dir.nil? && @dir = true
      @dir
    end

    def rewrite_u_value(v)
      self.u_value = v
      @rewritten = true
      update_card_value if @event
    end

    def rewrite_b_value(v)
      self.b_value = v
      @rewritten = true
      update_card_value if @event
    end

    def refresh_values
      if @rewritten
        self.refresh
        @rewritten = false
        update_card_value(true) if @event
      end
    end

    # カードの配列をIDのカンマ区切りStringにして返す
    def ActionCard::array2str(a)
      ids = []
      a.each do |cc|
        ids << cc.id
      end
      ids.join(",")
    end

    # カードの配列を向きのカンマ区切りStringにして返す
    def ActionCard::array2str_dir(a)
      ids = []
      a.each do |cc|
        ids << (cc.up?)? 0 : 1
      end
      ids.join(",")
    end

    # カードの配列を向きのIntにして返す(32枚まで限定)
    def ActionCard::array2int_dir(a)
      ids = 0
      a.each_index do |i|
        u = (a[i].up?)? 1 : 0
        ids+=(u << i)
      end
      ids
    end

    # デッキカードのインスタンスを初期化してから配列で返す
    def ActionCard::deck_with_context(ctxt, dk, stage)
      # 特定ステージに使用されるカード集める
      d = STAGE_DECK[stage]
      ret  =[]
      d.each do |c|
        begin
          ac = ActionCard[c]
        rescue =>e
          SERVER_LOG.fatal(e.message)
        end

        if ac
          ret << ac
          ac.init_card(dk, ctxt)
        end
      end
      ret
    end

  def ActionCard::get_joker_card(num,ctxt,dk)
    ret = false
    j = EventCard[JOKER_EVENT_CARD]
    if(num < j.max_in_deck)
      ret = ActionCard[j.event_no+num]
      ret.init_card(dk,ctxt)
     end
    ret
  end

    # デッキカードのインスタンスを初期化してから配列で返す
    def ActionCard::event_deck_with_context(ctxt, dk,duel, cards)
      # 特定ステージに使用されるカード集める
      ret = []
      cards.each do |c|
        if c
          ret << c
          c.init_event_card(dk, ctxt, duel)
        end
      end
      ret
    end

    # イベントカートをアクションカードに変換していく
    def ActionCard::event_cards_to_action_cards(cards1, cards2)
      c_num = Hash.new(0)               # 使用済み枚数
      # 与えられたカードが所持制限を超えていないかをチェック
      check_event_card_max(cards1)
      check_event_card_max(cards2)
      # 各カードのEventNumberからActionCardのIDを割り付けていく。
      [get_from_event_card(cards1, c_num),
      get_from_event_card(cards2, c_num)]
    end

    # もらったカードをアクションカードに単に変換
    def ActionCard::get_from_event_card(cards,num)
      ret = []
      cards.each do |c|
        ret << ActionCard[c.event_no+num[c.event_no]]
        # 使用済み枚数はHashに記憶していく
        num[c.event_no]+=1
      end
      ret
    end

    # カードからMAX数を超えていたら超過分を削除
    def ActionCard::check_event_card_max(cards)
      c_num = Hash.new(0)               # 枚数
      cards.reject! do |c|
        c_num[c.event_no]+=1
        c.max_in_deck < c_num[c.event_no]
      end
    end

    # カードの初期化
    def init_card(dk,ctxt)
      @deck = dk                # 所属するデッキ
      @event = ActionCardEvent.new(ctxt,self)
      regist_action_card_event
    end

    # カードの初期化
    def init_event_card(dk,ctxt,duel)
      @duel =duel
      @deck = dk                # 所属するデッキ
      @event = ActionCardEvent.new(ctxt,self)
      regist_action_card_event
    end

    # カードを捨てる
    def throw
      # 再利用されるカードは正常化
      @deck.throw_card(self)
    end

    # イベントの登録
    def regist_action_card_event
      # フックを登録
      if ACTION_EVENT_NO[self.event_no]
        @event.send(ACTION_EVENT_NO[self.event_no][0])
      end
    end

    # イベントを委譲する
    def method_missing(message, *arg)
      @event.send(message, *arg)
    end

    # カードイベントの後処理
    def finalize_event()#
      # 全てのイベントをリムーブする
      @event.remove_all_event_listener
      @event.remove_all_hook
      @event.finalize_event
      @duel = nil
      @deck = nil
      @event = nil
    end

    def joker?
      event_no == JOKER_EVENT_NO
    end
  end

  class ActionCardEvent < BaseEvent

    def initialize(c, ac)
      @ac = ac
      super
      share_context(c)
    end

    def finalize_event
      @owner = nil
      @ac =nil
    end

    # =========================
    # イベント
    # ========================

    # カードが配られた
    def dealed(owner)
      @owner = owner
    end
    regist_event DealedEvent

    # カードを捨てられた
    def throwed
      @ac.refresh_values
    end
    regist_event ThrowedEvent

    # カードが場に出された
    def droped
    end
    regist_event DropedEvent

    def occur_chance
      chance_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurChanceEvent

    def occur_heal
      heal_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurHealEvent

    def occur_damage
      damage_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurDamageEvent

    def occur_cure
      cure_event()
    end
    regist_event OccurCureEvent

    def occur_defeat
    end
    regist_event OccurDefeatEvent

    def occur_curse
      curse_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurCurseEvent

    def occur_idea
    end
    regist_event OccurIdeaEvent

    def occur_chalice
      chalice_event
      chance_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurChaliceEvent

    def occur_poison
      poison_event
      curse_event(ACTION_EVENT_NO[@ac.event_no][1])
    end
    regist_event OccurPoisonEvent


   # チャンスカード発動
   # 返値:配られたカードとオーナー
    def chance(v)
      ret = @ac.duel.deck.draw_cards_event(v).each{ |c| @owner.dealed_event(c) }
      @owner.use_action_card_event(@ac)
      ret
    end
    regist_event ChanceEvent

   # カースカード発動
   # 返値:配られたカードとオーナー
    def curse(v)
      # 手持ちのカードを複製してシャッフル
      aca = @owner.foe.cards.shuffle
      # ダメージの分だけカードを捨てる
      ret = v.times{ |a| @owner.foe.current_chara_card.discard(@owner.foe, aca[a]) if aca[a] }
      @owner.use_action_card_event(@ac)
      ret
    end
    regist_event CurseEvent

   # HP回復イベント
   # 返値:回復値
    def heal(v)
      ret = @owner.healed_event(v) if @owner.current_hit_point < @owner.current_hit_point_max
      @owner.use_action_card_event(@ac)
      ret
    end
    regist_event HealEvent

   # ダメージイベント
   # 返値:ダメージ値
    def damage(v)
      if [71, 2171].include?(@owner.current_chara_card.charactor_id)
        ret = 0
      else
        ret = @owner.damaged_event(v)
        @owner.use_action_card_event(@ac)
      end
      ret
    end
    regist_event DamageEvent

   # ステータス状態回復
   # 返値:成功
    def cure
      ret = @owner.cured_event()
      @owner.use_action_card_event(@ac)
      ret
    end
    regist_event CureEvent


   # 聖杯イベント
   # 返値:なし
    def chalice
      @owner.cured_event()
    end
    regist_event ChaliceEvent

   # 毒杯イベント
   # 返値:なし
    def poison
      @owner.foe.cured_event()
    end
    regist_event PoisonEvent

    def update_card_value(reset=false)
      @owner.update_card_value_event(@ac, reset)
      @owner.foe.update_card_value_event(@ac, reset)
    end

  end

end
