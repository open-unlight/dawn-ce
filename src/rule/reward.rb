# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

 require 'rule/event/reward_event'

module Unlight

  # ゲームの報酬ルール
  class Reward < BaseEvent

    # GENRE_ODDS = [25, 25, 20, 20, 5, 5] # 合計100
    # どんな種類がまず選ばれるのかの定数
    EXP, GEM, ITEM, OWN_CARD, RANDOM_CARD, RARE_CARD, EVENT_CARD, WEAPON_CARD,  = (0..7).to_a

    attr_accessor  :avatar_id, :final_result
    attr_reader :finished, :challenged,:lose,:total_exp,:total_gems,:add_point

    # コンストラクタ
    def initialize(pl_deck, foe_deck, duel_result, ai_type, duel_bonus = 0,reward_level = 0,wild_items_id = 0)
      super
      create_context                                    # コンテクストの作成

      @pl_deck = pl_deck                                # プレイヤーのデッキ
      @foe_deck = foe_deck                              # 相手のデッキ

      @pl_cc = @pl_deck[rand(pl_deck.size)]             # 自分のキャラカード
      @foe_cc = @foe_deck[rand(foe_deck.size)]          # 相手のキャラカード

      @geted_card = []                                  # 現在のカード

      @selected = :cancel                               # 選択状態
      @finished  = false                                # 終了したか

      @candidate_list = []                              # 候補リスト

      @win_num = 0                                      # 勝利回数

      @duel_result = duel_result                        # 勝敗の保存

      @ai_type = ai_type                                # AIのタイプ

      @win_skip = false                                 # スキップ有効か？(有効な場合は自動で勝利する)

      @initialized = false                              # 最初のカードリストを渡したか？

      @avatar                                           # 自身のアバターID
      @challenged                                       # ハイローを決定した
      @final_result                                     # 最終取得カード
      @channel_rule                                     # チャンネルルール
      @lose = false                                     # 負けたか？
      @deck_exp_pow = 1                                 # デッキ経験値倍率
      @card_bonus_pow = 1                               # カードボーナス倍率

      @tag_item_id = 0                                  # タグのアイテムID

      @current_genre = :none                            # 現在の報酬のタイプ
      @before_genre = []                                # 過去3回の報酬のタイプ
      @before_max = 2                                   # 過去ジャンルの保存数
      @wild_items = []
      ccd = CpuCardData[wild_items_id] unless wild_items_id == 0
      if ccd && WILD_ITEM_GET[duel_result]
        @wild_items =  ccd.treasure_items
      end

      @high_low_result =  [true]


      @exp = 0                  # 結果得られた基本EXP
      @gems = 0                 # 得られた基本GEM
      @add_point = 0            # ハイロー結果から計算した加算するEXPまたはGEM
      @total_exp = 0            # ハイロー後のEXP
      @total_gems = 0           # ハイロー後のGEM
      @first =true
      @reward_level = reward_level
      @duel_bonus = duel_bonus

      # クエストの報酬かを判定
      if reward_level==0
        @step_num = START_END_TABLE[duel_result][0]       # 現在の報酬のステップ値
        @step_min = @step_num                             # 最小のステップ値
        @step_cap = START_END_TABLE[duel_result][1]       # 報酬の限界ステップ
        @genre_odds = GENRE_ODDS.dup
      else
        reward_op = LEVEL_CAP_LOSE[1]
        if duel_result == RESULT_CPU_WIN
          reward_op = LEVEL_CAP_WIN[reward_level] if LEVEL_CAP_WIN[reward_level]
        else
          reward_op = LEVEL_CAP_LOSE[reward_level] if LEVEL_CAP_LOSE[reward_level]
        end
        @step_num = START_END_TABLE[duel_result][0]+reward_op[0]       # 現在の報酬のステップ値
        @step_min = @step_num                             # 最小のステップ値
        @step_cap = START_END_TABLE[duel_result][0]+reward_op[1] > START_END_TABLE[duel_result][1] ? START_END_TABLE[duel_result][1]:START_END_TABLE[duel_result][0]+reward_op[1]
        @genre_odds = GENRE_ODDS_QUEST.dup
      end
      @current_genre_odds = @genre_odds              # 現在の報酬の確率

    end

    def update
      event_resume
    end

    # 報酬のスタート
    def start
      @final_result
    end
    regist_event RewardEvent

    # Guard用アクセサ
    def win_skip
      @win_skip
    end

    def not_win_skip
      !@win_skip
    end

    # ====================================
    # 報酬のフェイズ
    # ===================================
    def init
      @selected = nil
      @finished = false
      @challenged = false
    end
    regist_event InitPhase


    # 候補カードリストを送るフェイズ
    def candidate_cards_list
      # 3ステップ分マイナスが現在のステップなので
      [candidate_cards,bonus_num]
    end
    regist_event CandidateCardsListPhase

    # 基本ダイスを送るフェイズ
    def bottom_dice_num
      @bottom_dice = @result_dice if @bottom_dice && @result_dice
      @bottom_dice||first_bottom_dice_num
    end
    regist_event BottomDiceNumPhase

    # ハイロー選択待ちフェイズ
    def high_low
      @reroll = false
      skip if @win_skip
      @high_low_result
    end
    regist_event HighLowPhase

    # アイテム選択&ゲットカード待ちフェイズ
    def exit
      @first = false
    end
    regist_event ExitPhase

    # ====================================
    # イベント
    # ===================================
   # ハイローアップにチャレンジ
   def up
     result_dice_event
     @challenged = true
     challenge(:up)
   end
   regist_event UpEvent

   # ハイローダウンにチャレンジ
   def down
     result_dice_event
     @challenged = true
     challenge(:down)
   end
   regist_event DownEvent

   # ハイローをスキップ
   def skip
#     puts  "skip"
     @challenged = true
     @win_skip = false
     challenge(:skip)
     update
   end

   # ハイローをキャンセル
   def cancel
     inv_id = []

     # ここでアバターのバインダーにカードを追加
     # まけた、または勝っていない場合
     if @lose
       @final_result = [nil, [], nil, @step_num, inv_id]
     else
       if @avatar
#         puts "cancel !!!!!!!!!!!!!!!!!"
#         puts @candidate_list
#         puts @win_num
         cc = @candidate_list[@win_num]
         cc = @candidate_list.last unless cc # おそらくMAXの時には最後を返す
         @add_point = 0
         case cc[0]
         when EXP
           @add_point = (@exp*((cc[2]-100)*0.01)).truncate
           # SERVER_LOG.info("DuelServer: [reward final result]  EXP!#{@exp}: #{(@exp*((cc[2]-100)*0.01)).truncate} : #{@add_point}")
           # @avatar.set_exp((@exp*((cc[2]-100)*0.01)).truncate)
           # @avatar.set_duel_deck_exp((@exp*((cc[2]-100)*0.01)).truncate*@deck_exp_pow)
           @avatar.set_exp(add_point)
           @avatar.set_duel_deck_exp(add_point*@deck_exp_pow)
           @add_point = add_point
           @total_exp = @exp + add_point
         when GEM
           @add_point = (@gems*((cc[2]-100)*0.01)).truncate
           # SERVER_LOG.info("DuelServer: [reward final result]  GEM!#{@gems}: #{(@gems*((cc[2]-100)*0.01)).truncate} : #{@add_point}")
           # @avatar.set_gems((@gems*((cc[2]-100)*0.01)).truncate)
           @avatar.set_gems(add_point)
           @add_point = add_point
           @total_gems = @gems + add_point
         when ITEM
#           puts "cancel set ITEM!!!!!!!!!!!!!!!!!x#{cc[2]},id:#{cc[1]}"
           cc[2].times do
             @avatar.get_item(cc[1])
           end
         when EVENT_CARD
#           puts "cancel set EVENT CARD!!!!!!!!!!!!!!!!!x#{cc[2]},id:#{cc[1]}"
           cc[2].times do
             @avatar.get_slot_card(SCT_EVENT, cc[1])
           end
         when WEAPON_CARD
#           puts "cancel set WEAPON CARD!!!!!!!!!!!!!!!!!x#{cc[2]},id:#{cc[1]}"
           cc[2].times do
             @avatar.get_slot_card(SCT_WEAPON, cc[1])
           end
         else
 #          puts "cancel set CC!!!!!!!!!!!!!!!!! x#{cc[2]},id:#{cc[1]}"
           add_cards = []
           cc[2].times do
             CardInventory.new do |c|
               c.chara_card_deck_id = @avatar.binder.id
               c.chara_card_id = cc[1]
               c.save
               inv_id << c.id
             end
             add_cards.push(cc[1])
           end
           # 取得したカードに関係しているもののみ、更新チェック 2013/01/16 yamagishi
           @avatar.achievement_check(Achievement::get_card_check_achievement_ids(add_cards),{ :is_update=>true, :list=>add_cards }) if add_cards != []
           # Lv、レアカード作成レコードチェック
           @avatar.get_card_level_record_check(add_cards)
         end
       end
       @final_result = [nil, @candidate_list[@win_num], nil, @step_num, inv_id]
     end

     @selected = :cancel
     @finished = true
     @final_result
   end
   regist_event CancelEvent

   # 報酬ゲームを続ける
   def retry_reward
     # ハイローで失敗しているときはリトライ出来ない
#     puts "retry event"  if  @high_low_result[0]
     @selected = :retry  if  @high_low_result[0]
     update
   end
   regist_event RetryRewardEvent

   # 報酬ゲームでリロール
   def reroll
     @reroll = true
     ret = true
#     puts "reroll"
     @selected = :reroll
     update
     ret
   end
   regist_event RerollEvent

   # 報酬ゲームでダイスを修正
   def amend(v)
     ret = false
#     puts "amend"
     b_calc = 0
     @bottom_dice.each do |a|
       b_calc += a
     end
     r_calc = 0
     @result_dice.each do |b|
       r_calc += b
     end
     if (b_calc-r_calc).abs <= v
       @selected = :amend
       @win_skip = true
       update
       ret = true
     end
     ret
   end
   regist_event AmendEvent

   # ========================
   # 判定関数
   # =======================
    # アイテム選択＆ゲットカード待ちフェイズ終了か？
    def exited?
      @selected
    end

    def first?
      @first
    end

    def not_first?
      !@first
    end

    def reroll?
      @reroll
    end

    def not_reroll?
      !@reroll
    end

    # 勝敗結果
    def duel_result
      @duel_result
    end


   # 取得カード候補リスト
   def candidate_cards
     ret = []
     if !@initialized
       ret << get_candidate
       ret << get_candidate
       ret << get_candidate
       if CHARA_VOTE_EVENT
         set = get_chara_vote_item_data
         set = get_candidate if set == nil
         ret << set
       # By_K2 (BP 1600 이상인경우 코채에서 승리시 무한의탑 입장권 2장 출현)
       # elsif @card_bonus_pow == RADDER_DUEL_CARD_BONUS_POW && RESULT_3VS3_WIN == duel_result && @avatar.get_bp >= 1600
       #   set = get_tower_item_data
       #   set = get_candidate if set == nil
       #   ret << set
       else
         ret << get_candidate
       end
       @initialized = true
     else
       ret << get_candidate
     end
     @candidate_list += ret
     ret
   end

   # 最初期基本ダイス値
   def first_bottom_dice_num
     @bottom_dice = [rand(6)+1,rand(6)+1]
     @result_dice = @bottom_dice
   end

   # 結果ダイス値
   def result_dice_num
     @result_dice = [rand(6)+1,rand(6)+1]
   end
   regist_event ResultDiceEvent

   # 結果
   def result(selected)
     b_calc = 0
     r_calc = 0
     @bottom_dice.each do |a|
       b_calc += a
     end
     @result_dice.each do |b|
       r_calc += b
     end
#     @bottom_dice = @result_dice
     case selected
     when :up
       b_calc <= r_calc
     when :down
       b_calc >= r_calc
     when :skip
       true
     end
   end

   # 報酬用のキャラカードを新しいものに更新する
   def update_chara_card
     @pl_cc = @pl_deck[rand(@pl_deck.size)]             # 自分のキャラカード
#     @foe_cc = @foe_deck[rand(foe_deck.size)]          # 相手のキャラカード
   end


   # ジャンルを選択する
   def select_genre
     @current_genre_odds = @genre_odds.dup

     # 選ぶことの出来ないジャンルを取り除く
     @before_genre.each do |g|
       @current_genre_odds.delete(g)
     end
     # 確率
     num = 0
     @current_genre_odds.each{ |k,v| num+=v}
     # ランダムの結果
     r = rand(num)
     # 前回の値をいれる一時変数
     b = 0
     @current_genre_odds.each do |k, v|
       ret = k
       # 前回の値と、今の値の間に結果が入っていれば、ジャンル決定
       if r <(b+v)
         @before_genre << k
         @before_genre.shift if @before_genre.size >@before_max
#         puts "genre selected!!! #{ret}"
         return ret
       else
         b += v
       end
     end
   end

   # ジャンルの再選択（前回をなしにしてひき直す）
   def reselect_genre
     @before_genre.pop
#     puts "reslected genre !!"
     select_genre
   end

   def win_num
     @win_num
#     (@win_num/3).to_i
   end

   def step_num
     @step_num
#     (@step_num/3).to_i
   end

   def bonus_num
     # 本当は変換が必要。いまのバランスだと
     @step_num-3
   end

   # 取得するものを返す
   def get_candidate
     ret = nil
     done =  false
     g = select_genre

     # イベント用（固定ステップで特定アイテム）
     # SERVER_LOG.info("<UID:#{@avatar.id}> DuelServer: [#{__method__}] step:#{@candidate_list.size}")
     if HIGH_LOW_EVENT_REWARD_ENABLE
       ret = get_event_chara_item
       # SERVER_LOG.info("<UID:#{@avatar.id}> DuelServer: [#{__method__}] ret:#{ret}") if ret
       done = true if ret
     end

     while !done
       case g
       when :exp
         ret = [EXP, 0, RewardData[step_num].exps]
       when :gem
         ret = [GEM, 0, RewardData[step_num].gems]
       when :item
         ret = [ITEM, RewardData[step_num].item_id, RewardData[step_num].item_num]
       when :own_card
         ret = [OWN_CARD, get_own_card_id(RewardData[step_num].own_card_lv), RewardData[step_num].own_card_num*@card_bonus_pow]
       when :random_card
         ret = [RANDOM_CARD, get_random_card_id(RewardData[step_num].random_card_rarity), RewardData[step_num].random_card_num]
       when :rare_card
         ret = [RARE_CARD, get_own_rare_card_id, RewardData[step_num].rare_card_lv]
       when :event_card
         ret = [EVENT_CARD, RewardData[step_num].event_card_id, RewardData[step_num].event_card_num]
       when :weapon_card
         ret = [WEAPON_CARD, RewardData[step_num].weapon_card_id, RewardData[step_num].weapon_card_num]
       when :wild_item
         ret = get_wild_item
       end
#        puts "select genre !!!!!! #{ret}"
       if ret[2] == 0
         g = reselect_genre
       else
         done = true
       end
     end
     @step_num += 1 if @step_num < @step_cap
#     puts "update step_num is #{@step_num}"
     ret
   end

   # WildItemを返す
   def get_wild_item
     ret = [0,0,0]
     # アイテムはハッシュの配列 指定ステップの最大値のアイテムを返す
     @wild_items.each { |w|
#       puts "#step is #{@step_min+w[:step]},#{step_num}"
#       ret = w[:item] if (w[:step]+@step_min) < step_num
       ret = w[:item] if (w[:step]+@step_min) == step_num
     }
     ret
   end

   # 結果でアバターを更新する
   def send_result_to_avatar(gems, exp)
     @gems = @total_gems = gems
     @exp = @total_exp = exp
   end


   # 廃炉ー選択の結果の判定
   def challenge(sym)
     if result(sym)
       @win_num += 1
       geted_card = @candidate_list[@win_num]
       @lose = false
       @high_low_result =  [true, geted_card, @candidate_list.last, bonus_num]
     else
       @lose = true
       @high_low_result =  [false, nil, nil, bonus_num]
     end
   end

   # 自身のカードのIDを1枚返す
   def get_own_card_id(dec)
     ret = 0
     # 取得するキャラカードをデッキ内からランダムで更新
     update_chara_card
     level = 0
#     puts "level1!!!!!!!! : #{level}"
     # レベルを補正する
     level = @pl_cc.level + dec
     if level < 1
       level = 1
     end
##     puts "level2!!!!!!!! : #{level}"
     cid = @pl_cc.kind == CC_KIND_CHARA ? @pl_cc.charactor_id : @pl_cc.base_charactor_id
     if @pl_cc.kind == CC_KIND_RENTAL
       # レンタルカードの場合 GEM男
       ret = rand(5) * 10 + 1
       # レアリティ5以下のノーマルカードを取得
     elsif @pl_cc.rarity <= 5
       # ノーマルカード
       ret = get_search_card_id(@pl_cc.name, level, 1..5, cid)
     elsif dec == 0
       # レアカード
       ret = get_search_tip_id
     else
       # 通常カード
       ret = get_search_card_id(@pl_cc.name, level, 1..5, cid)
     end
     ret
   end

   # 自身のレアカードのIDを1枚返す
   def get_own_rare_card_id
     # 取得するキャラカードをデッキ内からランダムで更新
     update_chara_card
     # レアリティ6~8でレベルが1のレアカードを取得
     if @pl_cc.kind == CC_KIND_RENTAL
       rand(5) * 10 + 1
     else
       cid = @pl_cc.kind == CC_KIND_CHARA ? @pl_cc.charactor_id : @pl_cc.base_charactor_id
       get_search_card_id(@pl_cc.name, 1, 6..8, cid)
     end
   end

   # ランダムにカードのIDを1枚返す
   def get_random_card_id(rare)
     # 取得するキャラカードをデッキ内からランダムで更新
     update_chara_card
     # レアリティ6~8でレベルが1のレアカードを取得
     get_search_card_id(nil, 1, rare)
   end

   # 復活後名前が変わったひと
   RENAME_CHARACTORS = [9]
   # 特定名のキャラクターの特定レベル、特定レアリティのカードをランダムで返す
   def get_search_card_id(n, level, rare, charactor_id=0)
     cid = charactor_id > CHARACTOR_ID_OFFSET_REBORN ? charactor_id - CHARACTOR_ID_OFFSET_REBORN : charactor_id
     name = n && RENAME_CHARACTORS.include?(cid) ? Charactor[cid].name : n
     if name
       cards = CharaCard.filter([[:id, 1..1000],[:rarity , rare], [:name , name], [:level , level], [:charactor_id , cid]])
     else
       cards = CharaCard.filter([[:id, 1..200],[:rarity , rare], [:level , level]])
     end
     r = cards.all[rand(cards.count)]
     if r
       r.id
     else
       1
     end
   end

   HIGH_LOW_RARE_ITEMS=[10006,10007,10008,10009,10010,10017]
   # 欠片カードをランダムで返す
   def get_search_tip_id
     HIGH_LOW_RARE_ITEMS[rand(HIGH_LOW_RARE_ITEMS.size)]
   end

   def get_chara_vote_item_data
     ret = nil
     if RESULT_3VS3_WIN == duel_result || RESULT_3VS3_LOSE == duel_result
       top_cc = @pl_deck[0] # 先頭のキャラカードを取得
       if top_cc.kind == CC_KIND_CHARA
         ret = [ITEM, (CHARA_VOTE_ITEM_START_ID+top_cc.charactor_id-1), 1]
       elsif top_cc.kind == CC_KIND_REBORN_CHARA
         c_id = top_cc.charactor_id - 4000
         ret = [ITEM, (CHARA_VOTE_ITEM_START_ID+c_id-1), 1]
       end
     end
     ret
   end

   # By_K2 (무한의탑 입장권)
   def get_tower_item_data
     ret = nil
     ret = [2, 102, 2]
     ret
   end

   def set_avatar(a)
     @avatar = a
   end

   def set_deck_exp_pow(i = 0)
     @deck_exp_pow = i
   end

   def set_card_bonus_pow(i = 0)
     @card_bonus_pow = i
   end

   def set_channel_rule(r = CRULE_FREE)
     @channel_rule = r
   end

   # イベントアイテムの設定
   def set_event_item(val = 0)
     a = []
     a << {:item=>EVENT_REWARD_ITEM, :step=>EVENT_REWARD_ITEM_STEP }
     # a << {:item=>EVENT_REWARD_ITEM[val % EVENT_REWARD_ITEM.count], :step=>EVENT_REWARD_ITEM_STEP }
     @wild_items = a
   end

   # タグアイテムのIDを設定
   def set_tag_item_id(opponent_id=0)
     if opponent_id > 0
       @tag_item_id = EVENT_REWARD_ITEM[@duel_result][opponent_id.to_s[-1].to_i]
     else
       @tag_item_id = 0
     end
   end

   # イベントアイテム出現条件判定
   def get_event_item_key
     ret = nil
     idx = EVENT_REWARD_ITEM_STEPS.index(@candidate_list.size+1)
     if idx != nil&&EVENT_REWARD_ITEM[@duel_result].size > 0&&@tag_item_id != 0
       item_id = @tag_item_id
       set_item_num = EVENT_REWARD_ITEM_STEP_NUM[idx]
       ret = [2,item_id,set_item_num]
     end
     ret
   end

   # キャラ指定イベントアイテム
   def get_event_chara_item
     ret = nil
     return ret if EVENT_REWARD_ITEM[@duel_result].size == 0

     step = @candidate_list.size+1
     chara_ids = @pl_deck.map{ |c| c.charactor_id }

     if EVENT_CHARA_REWARD_ITEM_STEPS.index(step) && (chara_ids & EVENT_CHARA_IDS).size > 0
       ret = [2, EVENT_REWARD_ITEM[@duel_result][0], EVENT_CHARA_REWARD_ITEM_STEP_NUM[EVENT_CHARA_REWARD_ITEM_STEPS.index(step)]]
     elsif EVENT_REWARD_ITEM_STEPS.index(step)
       ret = [2, EVENT_REWARD_ITEM[@duel_result][0], EVENT_REWARD_ITEM_STEP_NUM[EVENT_REWARD_ITEM_STEPS.index(step)]]
     end
     ret
   end

#    # プレイヤーカードを一枚返す（IDの配列で）
#    def p_one
#      if @pl_cc.rarity <= 5
#        [@pl_cc.id]
#      else
#        get_search_card(@pl_cc.name,@pl_cc.level, 1..5 )
#      end
#    end

#    # プレイヤーカードを二枚返す（IDの配列で）
#    def p_two
#      if @pl_cc.rarity <= 5
#        id = @pl_cc.id
#      else
#        id = get_search_card(@pl_cc.name,@pl_cc.level,1..5)[0]
#      end
#      [id, id]
#    end

#    # プレイヤーカードを４枚返す（IDの配列で）
#    def p_four
#      if @pl_cc.rarity <= 5
#        id = @pl_cc.id
#      else
#        id = get_search_card(@pl_cc.name,@pl_cc.level,1..5)[0]
#      end
#      [id, id, id, id]
#    end

#    # プレイヤーカードを８枚返す（IDの配列で）
#    def p_eight
#      if @pl_cc.rarity <= 5
#        id = @pl_cc.id
#      else
#        id = get_search_card(@pl_cc.name,@pl_cc.level,1..5)[0]
#      end
#      [id, id, id, id, id, id, id, id]
#    end

#    # 対戦相手のカードを一枚返す（IDの配列で）
#    def f_one
#      if @foe_cc.rarity <= 5
#        [@foe_cc.id]
#      else
#        get_search_card(@foe_cc.name,@foe_cc.level, 1..5 )
#      end
#    end

#    # レアリティ2以下のカードをランダムで1枚返す（IDの配列で）
#    def q_first
#       cards = CharaCard.filter([[:rarity , 1..2], [:level , 1], [~:name, @pl_cc.name]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id]
#      else
#        p_one
#      end
#    end

#    # レアリティ3から４のカードをランダム1枚返す（IDの配列で）
#    def q_second
#      cards = CharaCard.filter([[:rarity , 3..4], [:level , 1], [~:name, @pl_cc.name]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id]
#      else
#        p_two
#      end
#    end

#    # レアリティ５のカードをランダム1枚返す（IDの配列で）
#    def q_third
#      cards = CharaCard.filter([[:rarity , 5], [:level , 1], [~:name, @pl_cc.name]])
#  #    p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id]
#      else
#        p_eight
#      end
#    end

#    # プレイヤーカードのレアカードを（レアリティ値6から8）をランダムで返す
#    def r_one
#      cards = CharaCard.filter([[:rarity , 6..8], [:name , @pl_cc.name], [:level , 1]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id]
#      else
#        p_eight
#      end
#    end

#    # プレイヤーカードのレアカードを（レアリティ値6から8）をランダムで2枚返す
#    def r_two
#      cards = CharaCard.filter([[:rarity , 6..8], [:name , @pl_cc.name], [:level , 1]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id, r.id]
#      else
#        p_eight
#      end
#    end

#    # プレイヤーカードのレアカードを（レアリティ値6から8）をランダムで3枚返す
#    def r_three
#      cards = CharaCard.filter([[:rarity , 6..8], [:name , @pl_cc.name], [:level , 1]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        [r.id, r.id, r.id]
#      else
#        p_eight
#      end
#    end

#    # あるキャラクターの特定レベル、特定レアリティのカードをランダムで返す
#    def get_search_card(name, level, rare)
#      cards = CharaCard.filter([[:rarity , rare], [:name , name], [:level , level]])
# #     p cards.all
#      r = cards.all[rand(cards.count)]
#      if r
#        r.id
#      else
#        q_first
#      end
#    end


 end
end
