# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

# -*- coding: utf-8 -*-
module Unlight

  # 一人プレイ時デュエル時にEntarantを操作するAIクラス
  class AI < BaseEvent
    attr_accessor  :duel,:entrant, :foe

    @@init = false

    # 現在のAIリスト
    @@current_list=[]

    # すべてのデュエルをアップデート（サーバーから呼ばれます）
    def AI.update
      @@current_list.each{ |a|a.update}
    end

    # 適当なキャラカードを返す
    def AI.chara_card_deck(monster_no=0, pl=nil)
      AI.init
      if monster_no ==0
        CharaCardDeck.get_cpu_deck(rand(4))
      else
        CharaCardDeck.get_cpu_deck(monster_no, pl)
      end
    end

    def AI.init
      unless @@init
        CharaCardDeck.get_cpu_deck(0)
        CharaCardDeck.get_cpu_deck(1)
        CharaCardDeck.get_cpu_deck(2)
        CharaCardDeck.get_cpu_deck(3)
        @@init = true
      end
    end

    def AI.chara_cards_ids(cards)
      ret =[]
      cards.each do |a|
        ret << a.id
      end
      ret.join(",")
    end

    # CPUプレイヤーを返す
    def AI.player
      Player.get_cpu_player
    end

    # コンストラクタ
    def initialize(c, duel, entrant, cards, foeCards,rank=CPU_AI_OLD)
      super
      create_context                                                     # コンテクストの作成

      @duel = duel
      @entrant = entrant
      @cards = cards
      @foeCards = foeCards
      @foe = duel.entrants[0]


      # AIの頭の良さ（試行回数）
      @rank = rank
      # 手札のカードで出すべきかの重み。10でかならず出す。5でたまに出す。1で出さない
      @move_p = 0
      @hand_value = { }         # 出すカードのリスト
      @hand_move_value = { }    # 移動で出す予定のリスト
      @hand_swd_value = { }     # 出す予定の剣リスト
      @hand_arw_value = { }     # 出す予定の銃リスト
      @hand_def_value = { }     # 出す予定の防御カードリスト
      @hand_spc_value = { }     # 出す予定の特殊カードリスト

      @hand_useless_value = { } # 不要カードリスト

      # どのキャラが有利かの重みの保存
      @chara_change_value = []

      # 必殺座の重みの重みの保存
      @chara_feat_value = { }
      @chara_feat_dist_value = { } # 使える必殺技の距離を保存

      add_finish_listener_one_to_one_ai(method(:finish_ai))          # ゲーム終了を監視
      @entrant.start_ok
      @think_num = 0
      @@current_list.push(self)
      regist_event
    end

   # 更新
   def update
     event_resume
   end

    def think
    end
    regist_event OneToOneAi

   # 終了ハンドラ
   def finish_ai(target,ret)
     SERVER_LOG.info("AI: [Destruct]")
     self.remove_all_hook
     self.remove_all_event_listener
     @@current_list.delete(self)
     @duel = nil
     @entrant = nil
     @cards =nil
     @foeCards = nil
     @foe = nil
   end

   # デュエルに対してイベントを登録する
   def regist_event
     # 移動カード提出フェイズの開始
      @duel.add_start_listener_move_card_drop_phase(method(:duel_move_card_drop_handler))
      # 攻撃カード提出フェイズの開始
      @duel.add_start_listener_attack_card_drop_phase(method(:duel_attack_card_phase_handler))
      # 防御カード提出フェイズの開始
      @duel.add_start_listener_deffence_card_drop_phase(method(:duel_deffence_card_phase_handler))
      # キャラカード提出フェイズの開始
      @duel.add_start_listener_chara_change_phase(method(:duel_chara_change_phase_handler))
      # イニシアチブ変更フェイズの開始
      @duel.add_finish_listener_change_initiative_phase(method(:duel_change_initiative_phase_handler))
      # 死亡時キャラカード提出フェイズの開始
      @duel.add_start_listener_dead_chara_change_phase(method(:duel_dead_chara_change_phase_handler))
   end

   # 移動フェイズのハンドラ。移動カードを判定アクションを実行
   def duel_move_card_drop_handler(ret)
     @chara_feat_value = { }
     choice_move_card_action
   end

   # 攻撃フェイズのハンドラ。攻撃カード判定アクションを実行
   def duel_attack_card_phase_handler(ret)
     if @entrant.initiative?
       choice_attack_card_action
     end
   end

   # 防御フェイズのハンドラ。防御カード判定アクションを実行
   def duel_deffence_card_phase_handler(ret)
     if @entrant.not_initiative?
       choice_deffence_card_action
     end
   end

   # キャラ変更フェイズのハンドラ。防御カード判定アクションを実行
   def duel_chara_change_phase_handler(ret)
       choice_chara_card_action
   end

   # キャラ変更フェイズのハンドラ。防御カード判定アクションを実行
   def duel_dead_chara_change_phase_handler(ret)
       choice_chara_card_action
   end

   # イニシアチブ変更フェイズ
   def duel_change_initiative_phase_handler(*arg)
     # CPUの強さがMEDIUMより下なら判定しない
     if @rank < CPU_AI_MEDIUM
       return
     end
     @hand_useless_value = { }
     s = @entrant.cards.size
     # 低い価値のカードを捨て予定カードに含ませる
     @entrant.cards.each do |c|
       @hand_useless_value[c] =  s - c.get_value_max
     end

     # 役がそろっているカードは捨てない
     @chara_feat_value.each do |k, v|
       if v
         v[1].each do |l, w|
           @hand_useless_value[l] = 0 if @hand_value[l]
         end
       end
     end

   end


   # 待機
   def waiting

   end
   regist_event WaitingAction

   # ==============================
   # アクション
   # ==============================

   # 移動カードを選択する
   def choice_move_card
     reset_think_num
   end
   regist_event ChoiceMoveCardAction

   # 攻撃カードを選択する
   def choice_attack_card
     reset_think_num
   end
   regist_event ChoiceAttackCardAction

   # 防御カードを選択する
   def choice_deffence_card
     reset_think_num
   end
   regist_event ChoiceDeffenceCardAction

   #キャラカードの変更を選択する
   def choice_chara_card
     reset_think_num
   end
   regist_event ChoiceCharaCardAction

   # チャンスカードを出す
   def drop_chance_card
     # 判定結果の中から提出するカードを選んで出す
     chance?
     @hand_value.delete_if do |k,v|
       @entrant.move_card_add_action([k.id],[v[1]]) if (@entrant.cards.include?(k) && v[0] >= 10)
     end
   end
   regist_event DropChanceCardAction


   # 移動カードを出す
   def drop_move_card
     # 判定結果の中から提出するカードを選んで出す
     @hand_value.delete_if do |k,v|
       if (@entrant.cards.include?(k) && v[0] >= 9)
         @entrant.move_card_add_action([k.id],[v[1]])
       end
     end
   end
   regist_event DropMoveCardAction

   # ゴミカードを
   def useless_card_mearge
     # 判定結果にゴミカードを混ぜる
     @hand_useless_value.each do |l,w|
       v = 0
       if @hand_value[l]
         v = @hand_value[l][0]
         @hand_value[l][0] = w+v
       else
         @hand_value[l] = [w,true]
       end
     end
   end

   # 攻撃カードを出す
   def drop_attack_card
     # カースカードを出す
     carce?
     useless_card_mearge
     # 判定結果の中から提出するカードを選んで出す
     @hand_value.delete_if do |k,v|
       @entrant.attack_card_add_action([k.id],[v[1]]) if (@entrant.cards.include?(k) && v[0] >= 3)
     end
   end
   regist_event DropAttackCardAction

   # 防御カードを出す
   def drop_deffence_card
     # カースカードを出す
     carce?
     useless_card_mearge
     # 判定結果の中から提出するカードを選んで出す
     @hand_value.delete_if do |k,v|
       @entrant.deffence_card_add_action([k.id],[v[1]]) if (@entrant.cards.include?(k) && v[0] >= 3)
     end
   end
   regist_event DropDeffenceCardAction

   # キャラカードを選択する
   def set_chara_card
     # 判定結果の中から提出するカードを選んで出す
     @entrant.chara_change_action(@chara_change_value.index(@chara_change_value.max))
     @chara_change_value = []
   end
   regist_event SetCharaCardAction

   # 移動終了
   def done_init
     @entrant.init_done_action
     @hand_value = { }
   end
   regist_event DoneInitAction


   # 攻撃終了
   def done_attack
     @entrant.attack_done_action
     @hand_value = { }
   end
   regist_event DoneAttackAction

   # 防御終了
   def done_deffence
     @entrant.deffence_done_action
     @hand_value = { }
   end
   regist_event DoneDeffenceAction

   # ======================
   # 価値判定関数
   # ストールしないようにステップですすむ。
   # ======================
   def reset_think_num
     @think_num = 0
   end
   regist_event ResetThinkNumAction


   def finish_think_num
     @think_num = @rank
   end

   def feat_hand_set(type)
     # フェイズ条件のチェック
     # ここでhand_valueを合成＆書き換え
     @chara_feat_value.each do |k, v|
       if v && Feat::ai_phase_check(k.feat_id, type) && v[2] &&v[2].include?(@entrant.distance)
         v[1].each do |l, w|
           v = 0
           v = @hand_value[l][0] if @hand_value[l]
           @hand_value[l] = [15+v,w[0]]
         end
       end
     end
     @hand_value
   end

   # 現在のフェイズで適応可能なカードを提出する
   def move_feat_hand_set
     feat_hand_set(:move)
   end
   regist_event MoveFeatHandSetAction

   # 現在のフェイズで適応可能なカードを提出する
   def attack_feat_hand_set
     feat_hand_set(:attack)
   end
   regist_event AttackFeatHandSetAction
   # 現在のフェイズで適応可能なカードを提出する
   def deffence_feat_hand_set
     feat_hand_set(:deffence)
   end
   regist_event DeffenceFeatHandSetAction


   # 状況から必殺技発動の可能性をさぐる
   def decision_feat

     # ランクがAI_FEAT_ONより下時は必殺技を勘案しない（マジックナンバーを書き直す）
     if @rank < CPU_AI_FEAT_ON
       finish_think_num
     end

     case @think_num
     when 0
       # 必殺技が状態異常に妨害されていないか？
       if @entrant.current_chara_card.status[Unlight::CharaCardEvent::STATE_SEAL][1] > 0
         finish_think_num
       else
         @think_num +=1
       end
     when 1
       # カード必須条件を計算
       @entrant.current_chara_card.feat_inventories.each do  |f|
         @chara_feat_value[f] = Feat::ai_card_check(@entrant, f.feat_id)
       end
       @think_num +=1
     when 2
       # 必須条件を満たした物がどの距離が必要かをチェック
       @entrant.current_chara_card.feat_inventories.each do  |f|
         @chara_feat_value[f] << Feat::ai_dist_check(f.feat_id, @entrant)  if @chara_feat_value[f]
       end
       @think_num +=1
     when 3
       @think_num +=1
     when 4
       @think_num +=1
       finish_think_num
     end
   end
   regist_event DecisionFeatAction



   # 移動したい距離判定
   def decision_dist
     case @think_num
     when 0
       @entrant.set_direction_action(Entrant::DIRECTION_STAY)
       @move_p = cards_move_points
       @think_num +=1
     when 1
       @swd_p = cards_swd_points
       @think_num +=1
     when 2
       @arw_p = cards_arw_points
       @think_num +=1
     when 3
       if @move_p >0
         if @swd_p>@arw_p
         # 手札のポイントが剣の方多いとき、提出移動カードから剣を取り除く
           @hand_move_value.each do |k,v|
             v[0] = v[0] - @hand_swd_value[k][0]  if @hand_swd_value[k]
             # 進行方向を変えておく
             @entrant.set_direction_action(Entrant::DIRECTION_FORWARD)
           end
         else
         # 手札のポイントが銃の方多いとき、提出移動カードから銃を取り除く
           @hand_move_value.each do |k,v|
             v[0] = v[0] - @hand_arw_value[k][0]  if @hand_arw_value[k]
             # 進行方向を変えておく
             @entrant.set_direction_action(Entrant::DIRECTION_BACKWARD)
           end
         end
       end
       @think_num += 1
     when 4
       # 必殺技がONになる可能性を判断
       @chara_feat_value.each do |k, v|
         if v
           case [v][1]
           when [1]
             @entrant.set_direction_action(Entrant::DIRECTION_FORWARD)
           when [1,2]
             @entrant.set_direction_action(Entrant::DIRECTION_FORWARD)
           when [2,3]
             @entrant.set_direction_action(Entrant::DIRECTION_BACKWARD)
           when [3]
             @entrant.set_direction_action(Entrant::DIRECTION_BACKWARD)
           end
         end
       end
       @think_num += 1
     when 5
       @hand_value = @hand_move_value
       @think_num = @rank
     end
   end
   regist_event DecisionDistAction

   # 攻撃の判定
   def decision_attack
     case @think_num
     when 0
       if @entrant.distance == 1
          cards_swd_points
       else
          cards_arw_points
       end
       @think_num += 1
     when 1
       if @entrant.distance == 1
         @hand_value = @hand_swd_value
       else
         @hand_value = @hand_arw_value
       end
       @think_num = @rank
     end
   end
   regist_event DecisionAttackAction

   # 攻撃の判定
   def decision_deffence
     case @think_num
     when 0
       cards_def_points
       @think_num += 1
     when 1
       @hand_value = @hand_def_value
       @think_num = @rank
     end
   end
   regist_event DecisionDeffenceAction

   # キャラチェンジの判定
   def decision_chara_change
     case @think_num
     when 0
       @think_num += 1
     when 1
       @think_num += 1
     when 2
       @think_num += 1
     when 3
       @think_num += 1
     when 4
       # ヒットポイントが少ない順にする
       @chara_change_value = @entrant.hit_points.map{ |h|
         # ヒットポイント0なら選ばれない
         if h == 0
           0
         else
           100 - h
         end
       }
       @think_num = @rank
     end
   end
   regist_event DecisionCharaChangeAction

   # 手札の移動ポイントを計算
   def cards_move_points
     ret = 0
     @entrant.cards.each do |c|
       if ret > 3
         break
       end
       v = c.get_type_value(ActionCard::MOVE,false)
       if v > 0
         ret += v
         @hand_move_value[c] = [12-ret,false]
       end
       v = c.get_type_value(ActionCard::MOVE,true)
       if v > 0
         ret += v
         @hand_move_value[c] = [12-ret,true]
       end
     end
     ret
   end

   # 手札の剣ポイントを計算
   def cards_swd_points
     ret = 0
     @entrant.cards.each do |c|
       v = c.get_type_value(ActionCard::SWD,false)
       if v > 0
         ret += v
         @hand_swd_value[c] = [5+v,false]
       end
       v = c.get_type_value(ActionCard::SWD,true)
       if v > 0
         ret += v
         @hand_swd_value[c] = [5+v,true]
       end
     end
     ret
   end

   # 手札の銃ポイントを計算
   def cards_arw_points
     ret = 0
     @entrant.cards.each do |c|
       v = c.get_type_value(ActionCard::ARW,false)
       if v > 0
         ret += v
         @hand_arw_value[c] = [5+v,false]
       end
       v = c.get_type_value(ActionCard::ARW,true)
       if v > 0
         ret += v
          @hand_arw_value[c] = [5+v,true]
       end
     end
     ret
   end

   # 手札の防御ポイントを計算
   def cards_def_points
     ret = 0
     @entrant.cards.each do |c|
       v = c.get_type_value(ActionCard::DEF,false)
       if v > 0
         ret += v
         @hand_def_value[c] = [5+v,false]
       end
       v = c.get_type_value(ActionCard::DEF,true)
       if v > 0
         ret += v
         @hand_def_value[c] = [5+v,true]
       end
     end
     ret
   end

   # ======================
   # 状態判定関数
   # ======================
   # ツモっているか？
   def reach?

   end

   # 攻撃可能か？
   def attackable?

   end

   # 自分は瀕死か？
   def dying?
   end

   # 相手は瀕死か？
   def foe_dying?

   end

   # 手札の中で役に関わるカードはあるか。
   def reachable?

   end

   # 次がドローフェイズ？
   def next_draw?

   end

   # 次がドローフェイズ？
   def dead?

   end

   # 十分カードを勘案した？
   def solved?
     ret = @think_num >= @rank
     ret
   end

   # 手札にチャンスカードがある？
   def chance?
     ret = 0
     @entrant.cards.each do |c|
       if (c.event_no > 0 &&c.event_no < 11 )
         ret += 1
         @hand_value[c] = [10,true]
       end
     end
     ret = false if ret == 0
     ret
   end

   # チャンスカードはない？
   def chance_none?
     if chance?
       false
     else
       true
     end
   end

   # 手札にカースカードがある？
   def carce?
     ret = 0
     @entrant.cards.each do |c|
       if (c.event_no > 10)
         ret += 1
         @hand_value[c] = [10,true]
       end
     end
     ret = false if ret == 0
     ret
   end

   # チャンスカードはない？
   def carse_none?
     if carse?
       false
     else
       true
     end
   end


   def wait?
     false
   end

   # ==================
   # 通常関数
   # ==================

   # もらったカードからチャンスカードを探す
   def find_chance_card

   end

   #==================
   # 必殺技検討関数群
   # 手札から可能性があるかをチェックする
   # =================

   # 条件と威力
   module FeatChecker
     def check_feat(feat_no)

     end

     GREATER = 0
     EQUAL   = 1
     SMALLER = 2

     SHORT   = 1
     MIDDLE  = 2
     LONG    = 3

     MOVE    = 0
     ATK     = 1
     DEF     = 2

     # :Cond     必殺技の条件
     # :Distance 可能距離
     # :Pow      評価値（攻撃力と一定ではない。選ばれやすさ）
     FEAT_CONDITION =
       [
        # SMASH
        #    check_feat(@cc.owner.greater_check(FEAT_SMASH,ActionCard::SWD,3)&&(@cc.owner.distance == 1), FEAT_SMASH)
        {
          :Cond => [[ActionCard::SWD, 3, GREATER]],
          :Distance => [SHORT,EQUAL],
          :Pow => 3
        },

        # AIMING
        #    check_feat(@cc.owner.greater_check(FEAT_AIMING,ActionCard::ARW, 4)&&(@cc.owner.distance != 1), FEAT_AIMING)
        {
          :Cond => [[ActionCard::ARW, 4, GREATER],],
          :Distance => [SHORT,EQUAL],
          :Pow => 2
        },

        # STRIKE
        #    check_feat(@cc.owner.greater_check(FEAT_STRIKE,ActionCard::SPC,2) && @cc.owner.greater_check(FEAT_STRIKE,ActionCard::SWD,1) &&(@cc.owner.distance == 1), FEAT_STRIKE)
        {
          :Cond => [[ActionCard::SWD, 1, GREATER],[ActionCard::SPC, 2, GREATER]],
          :Distance => [SHORT,EQUAL],
          :Pow => 3
        },

        # COMBO
        #    check_feat(@cc.owner.search_check(FEAT_COMBO,ActionCard::SWD, 1) && @cc.owner.search_check(FEAT_COMBO,ActionCard::SWD, 2) && @cc.owner.search_check(FEAT_COMBO,ActionCard::SWD, 3) && @cc.owner.distance == 1, FEAT_COMBO)
        {
          :Cond => [[ActionCard::SWD, 1, EQUAL],[ActionCard::SWD, 2, EQUAL],[ActionCard::SWD, 3, EQUAL]],
          :Distance => [SHORT,EQUAL],
          :Pow => 3
        },
        # CHARGE
        #    check_feat(@cc.owner.greater_check(FEAT_CHARGE,ActionCard::ARW,1)&&@cc.owner.greater_check(FEAT_CHARGE,ActionCard::MOVE, 1)&&@cc.owner.distance != 1,FEAT_CHARGE)
        {
          :Cond => [[ActionCard::ARW, 1, GREATER],[ActionCard::MOVE, 1, GREATER]],
          :Distance => [MIDDLE,GREATER],
          :Pow => 3
        },
        # MIRAGE
        #    check_feat(@cc.owner.distance == 3,FEAT_MIRAGE)
        {
          :Distance => [LONG,EQUAL],
          :Pow => 3
        },
        # FRENZY_EYES
        #    check_feat(@cc.owner.greater_check(FEAT_FRENZY_EYES, ActionCard::SPC, 2) && @cc.owner.distance == 1,FEAT_FRENZY_EYES)
        {
          :Cond => [[ActionCard::ARW, 1, GREATER],[ActionCard::MOVE, 1, GREATER]],
          :Distance => [MIDDLE,GREATER],
          :Pow => 3
        },
        # ABYSS
        #    check_feat(@cc.owner.greater_check(FEAT_ABYSS, ActionCard::SPC,4), FEAT_ABYSS)
        {
          :Cond => [[ActionCard::MOVE, 4, GREATER]],
          :Pow => 10
        },

        # RAPID_SWORD
        #    check_feat(@cc.owner.greater_check(FEAT_RAPID_SWORD, ActionCard::SWD, 1) && @cc.owner.greater_check(FEAT_RAPID_SWORD,ActionCard::ARW,1) && @cc.owner.distance == 2, FEAT_RAPID_SWORD)
        {
          :Cond => [[ActionCard::SWD, 1, GREATER],[ActionCard::ARW, 1, GREATER]],
          :Distance => [MIDDLE,EQUAL],
          :Pow => 4
        },
        # ANGER
        #    check_feat(@cc.owner.greater_check(FEAT_ANGER, ActionCard::SWD, 3) && @cc.owner.greater_check(FEAT_ANGER, ActionCard::SPC, 3) &&@cc.owner.distance == 1, FEAT_ANGER)
        {
          :Cond => [[ActionCard::SWD, 3, GREATER],[ActionCard::SPC, 3, GREATER]],
          :Distance => [SHORT,EQUAL],
          :Pow => 10
        },
        # POWER_STOCK
        #    check_feat(!(@cc.owner.greater_check(FEAT_POWER_STOCK,ActionCard::MOVE, 1)) && @cc.owner.greater_check(FEAT_POWER_STOCK, ActionCard::SPC, 2), FEAT_POWER_STOCK)
        {
          :Cond => [[ActionCard::MOVE, 1, SMALLER],[ActionCard::SPC, 2, GREATER]],
          :Pow => 10
        },

        # SHODOW_SHOT
        #    check_feat(@cc.owner.greater_check(FEAT_SHADOW_SHOT, ActionCard::SPC, 1), FEAT_SHADOW_SHOT)
        {
          :Cond => [[ActionCard::SPC, 1, GREATER]],
          :Pow => 10
        },

        # RED_FANG
        #    check_feat(@cc.owner.greater_check(FEAT_RED_FANG, ActionCard::SPC, 3) && @cc.owner.greater_check(FEAT_RED_FANG, ActionCard::SWD, 3) && @cc.owner.distance == 1, FEAT_RED_FANG)
        {
          :Cond => [[ActionCard::SPC, 3, GREATER],[ActionCard::SWD, 3, GREATER]],
          :Distance => [SHORT,EQUAL],
          :Pow => 10
        },

        # BLESSING_BLOOD
        #    check_feat(@cc.owner.greater_check(FEAT_BLESSING_BLOOD,ActionCard::SPC,3) && @cc.owner.greater_check(FEAT_BLESSING_BLOOD,ActionCard::DEF,1), FEAT_BLESSING_BLOOD)
        {
          :Cond => [[ActionCard::SPC, 3, GREATER],[ActionCard::DEF, 1, GREATER]],
          :Pow => 10
        },

        # COUNTER_PREPARATION
        #    check_feat(@cc.owner.greater_check(FEAT_COUNTER_PREPARATION,ActionCard::SPC,2), FEAT_COUNTER_PREPARATION)
        {
          :Cond => [[ActionCard::SPC, 2, GREATER]],
          :Pow => 10
        },

        # KERMIC_TIME
        #    check_feat(@cc.owner.greater_check(FEAT_KARMIC_TIME, ActionCard::SPC, 5), FEAT_KARMIC_TIME)
        {
          :Cond => [[ActionCard::SPC, 5, GREATER]],
          :Pow => 20
        },

        # KERMIC_RING
        #    check_feat(@cc.owner.greater_check(FEAT_KARMIC_RING, ActionCard::SPC, 3), FEAT_KARMIC_RING)
        {
          :Cond => [[ActionCard::SPC, 3, GREATER]],
          :Pow => 10
        },

        # KERMIC_STRING
        #    check_feat(@cc.owner.greater_check(FEAT_KARMIC_STRING, ActionCard::SPC, 1), FEAT_KARMIC_STRING)
        {
          :Cond => [[ActionCard::SPC, 1, GREATER]],
          :Pow => 10
        },

       ]
   end
 end
end
