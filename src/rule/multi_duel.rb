# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 3対3のデュエル用ルール
  # Todo
  # ・切断による中断
  # ・イベントカードによる効果
  # ・alphaとBetaの削除

  class MultiDuel < BaseEvent
    attr_accessor  :alpha, :beta, :move_timer, :entrants, :deck, :initi, :result, :bp, :tmp_damage, :tmp_dice, :tmp_dice_heads_atk, :tmp_dice_heads_def, :alpha_reward, :beta_reward, :ai_type, :event_decks, :dice_attributes, :profound_id
    attr_reader :turn, :bonus_level, :avatar_names
    # 現在のゲームリスト
    @@current_list=[]
    # すべてのデュエルをアップデート（サーバーから呼ばれます）
   def MultiDuel.update
     @@current_list.each{ |a|a.update}
   end

   # コンストラクタ
   def initialize(pl, foe, deck1, deck2, rule, is_get_bp, ai=:none, stage = 0, hp1_set=[0,0,0], hp2_set= [0,0,0],bonus_level = 0, wild_items_id=0, timeout_turn = BATTLE_TIMEOUT_TURN, ai_rank = CPU_AI_OLD, hp_up = 0, ap_up = 0, dp_up = 0)		# By_K2
     super
     create_context                                                     # コンテクストの作成
     @rule = rule
     @is_get_bp = is_get_bp
     @turn = 0                                                          # 現在のターン数
     @using_cards = []                                                  # 場に存在する使用中のカード
     @ai_type = ai                                                           # CPUかどうか

     @cards1 = []                                                        # プレイヤーキャラカード
     @cards2 = []                                                        # 対戦相手キャラカード
     event_cards1 = []                                                  # プレイヤーが所持するイベントカード
     event_cards2 = []                                                   # 対戦相手が所持するイベントカード
     weapon_cards1 = []                                                   # プレイヤーが所持する武器カード
     weapon_cards2 = []                                                   # 対戦相手が所持する武器カード
     equip_cards1 = []                                                   # プレイヤーが所持する装備カード
     equip_cards2 = []                                                   # 対戦相手が所持する装備カード

     # ルールに応じてデッキからカードを作成
     if @rule == RULE_1VS1
       @cards1 << deck1.cards[0]
       @cards2 << deck2.cards[0]
       event_cards1 << deck1.event_cards[0].flatten
       event_cards2 << deck2.event_cards[0].flatten
       weapon_cards1 << deck1.weapon_cards[0]
       weapon_cards2 << deck2.weapon_cards[0]
       equip_cards1 << deck1.equip_cards[0]
       equip_cards2 << deck2.equip_cards[0]
       # イベントカードデッキが規定枚数以下の場合１のカードをランダムで詰める
       while event_cards1.size < SLOT_MAX_EVENT
         event_cards1 << EventCard::get_random_filler_card()
       end
       while event_cards2.size < SLOT_MAX_EVENT
         event_cards2 << EventCard::get_random_filler_card()
       end

     elsif @rule == RULE_3VS3
       @cards1 = deck1.cards
       @cards2 = deck2.cards
       event_cards1 = deck1.event_cards.flatten
       event_cards2 = deck2.event_cards.flatten
       weapon_cards1 = deck1.weapon_cards
       weapon_cards2 = deck2.weapon_cards
       equip_cards1 = deck1.equip_cards
       equip_cards2 = deck2.equip_cards
       # イベントカードデッキが規定枚数以下の場合１のカードをランダムで詰める
       while event_cards1.size < SLOT_MAX_EVENT*@cards1.size
         event_cards1 << EventCard::get_random_filler_card()
       end
       while event_cards2.size < SLOT_MAX_EVENT*@cards2.size
         event_cards2 << EventCard::get_random_filler_card()
       end
     end

     @cards1.delete(nil)
     @cards2.delete(nil)

     @alpha = Entrant.new(context, @cards1, weapon_cards1, equip_cards1, event_cards1, DEFAULT_DISTANCE, hp1_set,0,0,0,@ai_type)       # 対戦者A (By_K2)
     @beta = Entrant.new(context, @cards2, weapon_cards2, equip_cards2, event_cards2, DEFAULT_DISTANCE, hp2_set, hp_up, ap_up, dp_up, @ai_type)       # 対戦者B (By_K2)
     @alpha.set_foe(@beta)
     @beta.set_foe(@alpha)
     @deck = Deck.new(context,stage)
     @cards1.each_index { |i| @cards1[i].init_card(context, @alpha, @beta, self, i) if @cards1[i] }      # キャラカードを初期化
     @cards1[0].init_event                                               # イベントとフックの登録
     @cards2.each_index { |i| @cards2[i].init_card(context, @beta, @alpha, self, i) if @cards2[i] }      # キャラカードを初期化
     @cards2[0].init_event                                               # イベントとフックの登録

     @avatars = [pl, foe]                                                # アバター
     @avatar_names = [pl.name, foe.name]                                 # アバター名
     @entrants = [@alpha, @beta]                                         #対戦者全員
     @initi = [0,1]                                                     # イニシアチブの結果
     @event_deck1,@event_deck2 = EventDeck.create_decks(context,event_cards1,event_cards2,self) # イベントカードデッキを作る
     @event_decks = [@event_deck1, @event_deck2]                                         #対戦者全員
     add_finish_listener_three_to_three_duel(method(:finish_game))      # ゲーム結果を監視
     @@current_list << self                                             # ゲームリストに追加
     @tmp_damage                                                        # ダメージの一時保管
     @tmp_dice = []                                                     # ダイスの一時保管
     @tmp_dice_heads_atk                                                # 攻撃側ダイスの出目
     @tmp_dice_heads_def                                                # 防御側ダイスの出目
     @dice_attributes = []
     @result = []
     @roll_cancel = false                                               # ダイスロールの中止
     @bp = []

     @battle_timeout_turn = timeout_turn

     @first_attack_bonus_done = false

     # 勝ったときのEXPを計算する
     alpha_exp = 0
     @cards2.each{ |c| alpha_exp +=c.level*EXP_POW}
     @alpha.result_exp = alpha_exp

     beta_exp = 0
     @cards1.each{ |c| beta_exp +=c.level*EXP_POW}
     @beta.result_exp = beta_exp

     @alpha.result_gems = (@cards2.length) * GEM_POW
     @beta.result_gems = (@cards1.length) * GEM_POW

     @ai_rankd = ai_rank
     # AI指定がある場合betaをCPUに任せる
     if @ai_type == :quest_ai
       @ai = AI.new(context, self, @beta, @cards1, @cards2, ai_rank)
       @alpha.result_exp = @alpha.result_exp * 1.0
       @ai.one_to_one_ai
     elsif @ai_type == :duel_ai
       @ai = AI.new(context, self, @alpha, @cards1, @cards2,CPU_AI_FEAT_ON)
       @beta.result_exp = @beta.result_exp * 1.0
       @ai.one_to_one_ai
     elsif @ai_type == :profound_ai
       @ai = AI.new(context, self, @beta, @cards1, @cards2,CPU_AI_FEAT_ON)
       @alpha.result_exp = @alpha.result_exp * 1.0
       @ai.one_to_one_ai
     end

     # クエストボーナスのレベル
     @bonus_level = bonus_level
     # 特別ボーナスアイテムの配列
     @wild_items_id = wild_items_id

   end

   # キャラカードを個別に初期化
   def init_chara_card(card, target, foe, index)
     @cards2[0].finalize_event
     card.init_card(context, target, foe, self, index)
     @cards2[0] = card
     @cards2[0].init_event                                               # イベントとフックの登録
     # refresh_quest_ai
   end

   # 途中でAIに切り替える
   def change_player_to_ai( index )
     SERVER_LOG.info("MultiDuel: [change_player_to_ai]");
     if index == 0
       @ai = AI.new(context, self, @beta, @cards1, @cards2, CPU_AI_FEAT_ON)
     else
       @ai = AI.new(context, self, @alpha, @cards1, @cards2, CPU_AI_FEAT_ON)
     end
     @ai.one_to_one_ai
     @ai_type = :proxy_ai
   end

   def refresh_quest_ai
     @ai.finish_ai(nil,nil) if @ai
     @ai = AI.new(context, self, @beta, @cards1, @cards2, @ai_rank)
     @ai.one_to_one_ai
   end

   # 異常な終了したデータか
   def check_abnormal_end_data(avatar_id)
     ret = false
     # 部屋作成者じゃなく、AbortAI状態で、ターンがほぼ進んでないなら異常と判定
     if @avatars[1].id == avatar_id && @ai_type == :proxy_ai && @turn < 1
       ret = true
     end
     ret
   end

   # 自分をゲームリストから削除する
   def destruct()
     SERVER_LOG.info("MultiDuel: [Destruct]")
     @@current_list.delete(self)
     SERVER_LOG.info("MultiDuel: [Destruct] remain duel.num #{@@current_list.size}")
   end

   def exit_game
     SERVER_LOG.info("MultiDuel:[exit game]#{ @alpha.exit&&@beta.exit}")
     if @alpha.exit&&@beta.exit
       @event_decks.each do |e|
         e.remove_all_event_listener
         e.remove_all_hook
         e.all_cards_remove_all_event_listener
       end
       @deck.all_cards_remove_all_event_listener
       @deck.remove_all_event_listener
       @deck.remove_all_hook
       remove_all_event_listener
       remove_all_hook
       @ai.finish_ai(nil,nil) if @ai
       @avatars = []
       @ai = nil
       @using_cards = []                                                  # 場に存在する使用中のカード
       @cards1.each do |c|
         if c
          c.finalize_event
        end
       end
       @cards2.each do |c|
         if c
          c.finalize_event
        end
       end

       @cards1 = []                                                        # プレイヤーキャラカード
       @cards2 = []                                                        # 対戦相手キャラカード
       @alpha = nil
       @beta = nil
       @entrants = nil
       @deck = nil
       @avatars = []
       @avatar_names = []
       destruct
     end
   end

   def rule
     @rule
   end
   def is_get_bp
     @is_get_bp
   end
   # 先手
   def first_entrant
     @entrants[@initi[0]]
   end
   # 後手
   def second_entrant
     @entrants[@initi[1]]
   end

   # 指定したエントラントのイベントカードデッキを取得する
   def get_event_deck(entrant)
     if @entrants[0] == entrant
       @event_decks[0]
     else
       @event_decks[1]
     end
   end

   # 勝ったほうのBPを返す
   def win_bp
     if (@entrants[0].total_hit_point == @entrants[1].total_hit_point)
       0
     elsif (@entrants[0].total_hit_point > @entrants[1].total_hit_point)
       @avatars[0].point
     else
       @avatars[1].point
     end
   end

   # 負けたほうのBPを返す
   def lose_bp
     if (@entrants[0].total_hit_point == @entrants[1].total_hit_point)
       0
     elsif (@entrants[0].total_hit_point > @entrants[1].total_hit_point)
       @avatars[1].point
     else
       @avatars[0].point
     end
   end

   # 更新
   def update
     event_resume
   end



   # =========== ゲームの実体 ==============
   # スタート
   def start
     @result
   end
   regist_event ThreeToThreeDuel


   # =========== フェイズの実体 ==============

   # ターンの開始
   # 返値:現在のターン
   def start_turn
     # 技を初期化
     first_entrant.sealed
     second_entrant.sealed
     # 最初のターンのみ装備補正を更新
     if @turn == 0
       @alpha.update_weapon_event
       @beta.update_weapon_event
     end
     @turn+= 1
   end
   regist_event StartTurnPhase

   # カードを補充する
   # 返値:配られたカードの配列[alpha, beta]
   def refill_card
     ret = []
     @entrants.each do |a|
       dc = @deck.draw_cards_event(a.cards_lack_num)
       ret << dc
     end
     res = [ret[0].clone, ret[1].clone]
     until ret == [[],[]]
       @alpha.dealed_event(ret[0].shift) if ret[0].size>0
       @beta.dealed_event(ret[1].shift) if ret[1].size>0
     end
     @entrants.each{ |e|
       e.move_phase_init_event
     }

     res
   end
   regist_event RefillCardPhase

   # カードを補充する
   # 返値:配られたカードの配列[alpha, beta]
   def refill_event_card
     ret = []
     @entrants.each_index do |i|
       dc = @event_decks[i].draw_cards_event(@entrants[i].event_card_draw_num)
       ret << dc
     end
     res = [ret[0].clone, ret[1].clone]
     until ret == [[],[]]
       @alpha.dealed_event(ret[0].shift) if ret[0].size>0
       @beta.dealed_event(ret[1].shift) if ret[1].size>0
     end
     res
   end
   regist_event RefillEventCardPhase

   # カードをドロップ
   # 返値:なし
   def move_card_drop

   end
   regist_event MoveCardDropPhase

   # 移動の決定
   # 返値:使用カードの配列
   def determine_move
     ret = []

     det = 0
     @entrants.each do |e|
       # 移動カードを使用中カードから取り除く
       ret << e.move_table.clone
       e.mp_calc_resolve
     end

     @entrants.each { |e| e.alter_mp_event }
     @entrants.each { |e| e.mp_evaluation_event }

     if (@beta.seconds && !@alpha.seconds)
       set_initiative(true)
     elsif (@alpha.seconds && !@beta.seconds)
       set_initiative(false)
     elsif @alpha.move_point.abs > @beta.move_point.abs
       set_initiative(true)
     elsif  @alpha.move_point.abs < @beta.move_point.abs
       set_initiative(false)
     else
       set_initiative(rand(2) == 1)
     end
     a_point = @alpha.get_direction*@alpha.move_point.abs
     b_point = @beta.get_direction*@beta.move_point.abs
     det = a_point + b_point
     ret << @alpha.move_point_appearance(a_point)
     ret << @beta.move_point_appearance(b_point)
     @entrants.each{ |e|
       e.move_action(det)
       e.move_phase_init_event
     }
    ret
   end
   regist_event DetermineMovePhase

   # 移動フェイズ終了
   def finish_move
   end
   regist_event FinishMovePhase

   # キャラ変更
   def chara_change
   end
   regist_event CharaChangePhase

   # キャラ変更の決定
   def determine_chara_change
     @entrants.each do |e|
       # キャラチェンジフェイズの初期化
       e.change_phase_init
       e.battle_phase_init_event
       e.move_phase_init_event
     end
   end
   regist_event DetermineCharaChangePhase

   # 戦闘カードのドロップ
   # 返値:なし
   def battle_card_drop
     ret = []
     ret << @entrants[0].battle_table.clone
     ret << @entrants[1].battle_table.clone
     ret
   end
   regist_event AttackCardDropPhase
   regist_event DeffenceCardDropPhase

   # 戦闘ポイントの決定
   # 返値:使用カードの配列
   def determine_battle_point
     ret = []
     @state = :result
     ret << @entrants[0].battle_table.clone
     ret << @entrants[1].battle_table.clone
     @bp = []
     @entrants[@initi[0]].bp_calc_resolve
     @entrants[@initi[1]].dp_calc_resolve
     @dice_attributes =  @entrants[@initi[0]].dice_attribute_regist_event
     @bp[@initi[0]] = @entrants[@initi[0]].tmp_power
     @bp[@initi[1]] = @entrants[@initi[1]].tmp_power
     ret
   end
   regist_event DetermineBattlePointPhase

   # 戦闘結果
   # 返値:結果のダイスとダメージ
   def battle_result
     ret = []
     d = Array.new(2, 0)
     @initi.each do |i|
       res = []
       @bp[i].times do |b|

         res << rand(6)
       end
       res.each_index { |j| d[i] +=1 if res[j] > 3}
       ret << res
     end
     @tmp_damage = d[@initi[0]] - d[@initi[1]]
     @tmp_dice = ret
     @tmp_dice_heads_atk = d[@initi[0]]
     @tmp_dice_heads_def = d[@initi[1]]
     if @roll_cancel
       ret[1] = []
       @roll_cancel = false
     end
     ret
   end
   regist_event BattleResultPhase

   def roll_cancel=(cancel)
     @roll_cancel = cancel
   end

   # ダメージの適用
   def damage
     ent1 = @entrants[@initi[1]]

     # 一撃死のチェック）
     striked = ((ent1.current_hit_point_max == ent1.current_hit_point)&&(ent1.current_hit_point_max <= @tmp_damage)) ? true:false
     ent1.damaged_event(@tmp_damage ) if @tmp_damage  > 0
     # ファーストアタックか実行済みでなくかつダメージが生じていたら
     if not(@first_attack_bonus_done)&&@tmp_damage  > 0
       @entrants[@initi[0]].duel_bonus_event(DUEL_BONUS_FIRST_ATTACK,1)
       @first_attack_bonus_done = true # 実行済みにする
     end

     # チェック
     if striked
       # 一撃死ならば、ヒットポイントの二分の一切り捨てのボーナス（MAX7くらい？）
       @entrants[@initi[0]].duel_bonus_event(DUEL_BONUS_STRIKE_KILL,(ent1.current_hit_point_max/2).truncate)
     end

     @tmp_damage = 0
     @entrants[@initi[0]].battle_phase_init_event
     @entrants[@initi[1]].battle_phase_init_event
   end
   regist_event DamagePhase

   # 攻守の交代
   # 返値:新しい攻撃順
   def change_initiative
     first_entrant.initiative = false
     second_entrant.initiative = true
     @initi = [@initi[1],@initi[0]]
   end
   regist_event ChangeInitiativePhase

   # キャラ変更
   def dead_chara_change
   end
   regist_event DeadCharaChangePhase

   # キャラ変更の決定
   def determine_dead_chara_change
     @entrants.each do |e|
       e.change_phase_init
       e.battle_phase_init_event
       e.move_phase_init_event
     end
   end
   regist_event DetermineDeadCharaChangePhase

   # ターンの終了
   # 返値:現在のターン
   def finish_turn
     @turn
   end
   regist_event FinishTurnPhase

   # ゲームの終了
   # 返値:参加者の勝敗
   def finish_game(*arg)
     ret  =[]
     SERVER_LOG.info("MultiDuel: [end_game] ai:#{@ai_type}");
     if (@entrants[0].total_hit_point == @entrants[1].total_hit_point) # &&@turn == BATTLE_TIMEOUT_TURN
       @alpha_reward = Reward.new(@alpha.chara_cards,@beta.chara_cards, get_reward_result(RESULT_DRAW),@ai_type,@alpha.reward_bonus,@bonus_level)
       @beta_reward = Reward.new(@beta.chara_cards,@alpha.chara_cards, get_reward_result(RESULT_DRAW),@ai_type,@beta.reward_bonus,@bonus_level)
         ret = [{
                  :result => RESULT_DRAW,
                  :reward =>@alpha_reward,
                  :gems => @alpha.update_gems(RESULT_DRAW),
                  :exp => @alpha.update_exp(RESULT_DRAW),
                  :damage => @alpha.damage_set,
                  :remain_hp => @alpha.remain_hp_set,
                },{
                  :result => RESULT_DRAW,
                  :reward =>@beta_reward,
                  :gems =>@beta.update_gems(RESULT_DRAW),
                  :exp => @beta.update_exp(RESULT_DRAW),
                  :damage => @beta.damage_set,
                  :remain_hp => @beta.remain_hp_set,
                }]
     elsif (@entrants[0].total_hit_point > @entrants[1].total_hit_point)
       if @entrants[0].total_hit_point == 1
         SERVER_LOG.info("MultiDuel: [BONUS SURVIVER]");
         @entrants[0].duel_bonus_event(DUEL_BONUS_SURVIVER,@entrants[1].chara_cards.size+2)
       end
       @alpha_reward = Reward.new(@alpha.chara_cards,@beta.chara_cards, get_reward_result(RESULT_WIN),@ai_type,@alpha.reward_bonus,@bonus_level,@wild_items_id)
       @beta_reward = Reward.new(@beta.chara_cards,@alpha.chara_cards, get_reward_result(RESULT_LOSE),@ai_type,@beta.reward_bonus,@bonus_level)
       ret = [{
                :result => RESULT_WIN,
                :reward =>@alpha_reward,
                :gems => @alpha.update_gems(RESULT_WIN),
                :exp => @alpha.update_exp(RESULT_WIN),
                :damage => @alpha.damage_set,
                :remain_hp => @alpha.remain_hp_set,
              },{
                :result => RESULT_LOSE,
                :reward =>@beta_reward,
                :gems =>@beta.update_gems(RESULT_LOSE),
                :exp => @beta.update_exp(RESULT_LOSE),
                :damage => @beta.damage_set,
                :remain_hp => @beta.remain_hp_set,
                }]
     else
       if @entrants[1].total_hit_point == 1
         SERVER_LOG.info("MultiDuel: [BONUS SURVIVER]");
         @entrants[1].duel_bonus_event(DUEL_BONUS_SURVIVER,@entrants[0].chara_cards.size+2)
       end
       @alpha_reward = Reward.new(@alpha.chara_cards,@beta.chara_cards, get_reward_result(RESULT_LOSE),@ai_type,@alpha.reward_bonus,@bonus_level)
       @beta_reward = Reward.new(@beta.chara_cards,@alpha.chara_cards, get_reward_result(RESULT_WIN),@ai_type,@beta.reward_bonus,@bonus_level,@wild_items_id)
         ret = [{
                  :result => RESULT_LOSE,
                  :reward =>@alpha_reward,
                  :gems =>@alpha.update_gems(RESULT_LOSE),
                  :exp => @alpha.update_exp(RESULT_LOSE),
                  :damage => @alpha.damage_set,
                  :remain_hp => @alpha.remain_hp_set,
                },{
                  :result => RESULT_WIN,
                  :reward =>@beta_reward,
                  :gems => @beta.update_gems(RESULT_WIN),
                  :exp => @beta.update_exp(RESULT_WIN),
                  :remain_hp => @beta.remain_hp_set,
                }]
     end
     if ai_type == :none || ai_type == :proxy_ai
       wp = win_bp
       lp = lose_bp
       @avatars.each_with_index do |a,i|
         a.set_result(ret[i][:result], wp, lp, is_get_bp)
       end
     end

     destruct
     @result = ret
   end

   # =======================================
   # 判定関数
   # =======================================
   def game_end?
     @game_end
   end

   # 共にゲーム開始準備が整っているか
   def game_start_ok?
     ret = false
     if (@alpha&&@alpha.start_ok?)&&(@beta&&@beta.start_ok?)
       ret = true
     end
     ret
   end

   def game_start?

     @turn > 0
   end

   def timeout?
     @turn >= @battle_timeout_turn
   end

   def get_reward_result(r)
     if @ai_type == :none ||@ai_type == :duel_ai||@ai_type == :proxy_ai    # クエスト戦闘でない
       if @rule == RULE_1VS1
         case r
         when RESULT_WIN
           Reward::RESULT_1VS1_WIN
         when RESULT_LOSE
           Reward::RESULT_1VS1_LOSE
         when RESULT_DRAW
           Reward::RESULT_1VS1_LOSE
         end
       elsif @rule == RULE_3VS3
         case r
         when RESULT_WIN
           Reward::RESULT_3VS3_WIN
         when RESULT_LOSE
           Reward::RESULT_3VS3_LOSE
         when RESULT_DRAW
           Reward::RESULT_3VS3_LOSE
         end
       else
         Reward::RESULT_1VS1_LOSE
       end
     else
       case r
       when RESULT_WIN
         Reward::RESULT_CPU_WIN
       when RESULT_LOSE
         Reward::RESULT_CPU_LOSE
       when RESULT_DRAW
        Reward::RESULT_CPU_LOSE
       end
     end
   end

   # ======================================
   # その他の関数
   # ======================================

   # イニシアチブのセット
   # alphaが勝ったかどうかでセットする
   def set_initiative(alpha)
     if alpha
       @initi = [0, 1]
       @alpha.initiative = true
       @beta.initiative = false
     else
       @initi = [1, 0]
       @alpha.initiative = false
       @beta.initiative = true
     end
     @alpha.seconds = false
     @beta.seconds = false
     @alpha.set_initiative_event
     @beta.set_initiative_event
   end

   # ジェムを計算
   def calc_gem

   end

   # ターンを変更する
   def set_turn(v)
     if v <= BATTLE_TIMEOUT_TURN
       @turn = v
       @three_to_three_duel_counter = v
     else
       @turn = BATTLE_TIMEOUT_TURN
       @three_to_three_duel_counter = BATTLE_TIMEOUT_TURN
     end
     @entrants.each{ |e|
       e.set_turn_event(@turn)
     }
   end

   # デバッグコマンドで最終ターンにしてしまう
   def set_last_turn
     @turn = BATTLE_TIMEOUT_TURN - 1
     @three_to_three_duel_counter  = BATTLE_TIMEOUT_TURN - 1
   end

   # レイド戦で強制終了させる際に使用
   def set_over_turn
     @turn = @battle_timeout_turn
     @three_to_three_duel_counter = @battle_timeout_turn
   end

 end
end
