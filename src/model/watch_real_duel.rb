# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # デュエルリアルタイム観戦用クラス

  class WatchRealDuel
    attr_reader :pl_deck,:foe_deck,:pl_cards,:foe_cards,:pl_card_idx,:foe_card_idx,:pl_hps,:pl_damege,:foe_hps,:foe_damege,
    :pl_state,:foe_state,:pl_ac,:foe_ac,:pl_table,:foe_table,:pl_initi,:deck_num,:dist,:turn,:phase,:cmd_cnt,:init_commands

    def initialize(match_uid,rule,stage,pl_deck,foe_deck)
      @key            = match_uid
      @rule           = rule
      @stage          = stage
      @pl_deck        = pl_deck
      @foe_deck       = foe_deck
      @override_cards = { }
      @pl_cards       = (@rule == RULE_1VS1) ? [@pl_deck.cards[0]]  : @pl_deck.cards
      @foe_cards      = (@rule == RULE_1VS1) ? [@foe_deck.cards[0]] : @foe_deck.cards
      @pl_card_idx    = 0
      @foe_card_idx   = 0
      @pl_hps         = []
      @pl_max_hps     = []
      @foe_hps        = []
      @foe_max_hps    = []
      @pl_damege      = []
      @foe_damege     = []
      @pl_state       = []
      @foe_state      = []

      pl_deck_ids = []
      foe_deck_ids = []
      @pl_cards.each_index do |s|
        if @pl_cards[s]      # 念のためのチェック
          pl_deck_ids << @pl_cards[s].id
          @pl_hps << @pl_cards[s].hp       # 最大のヒットポイントを格納
          @pl_max_hps << @pl_cards[s].hp   # 最大のヒットポイントを格納
          @pl_damege << 0                  # ダメージ数を保持

          # State配列にカード枚数分、入れる
          @pl_state  << []
        end
      end
      @foe_cards.each_index do |s|
        if @foe_cards[s]      # 念のためのチェック
          foe_deck_ids << @foe_cards[s].id
          @foe_hps << @foe_cards[s].hp     # 最大のヒットポイントを格納
          @foe_max_hps << @foe_cards[s].hp # 最大のヒットポイントを格納
          @foe_damege << 0                 # ダメージ数を保持

          # State配列にカード枚数分、入れる
          @foe_state  << []
        end
      end

      @pl_ac      = []
      @foe_ac     = []
      @pl_table   = []
      @foe_table  = []

      # デッキ枚数を取得
      d = STAGE_DECK[@stage]
      @deck_max   = (d != nil) ? d.size : STAGE_DECK[0].size
      @deck_num   = @deck_max

      @dist       = 2
      @pl_initi   = true
      @turn       = 0
      @phase      = ""
      @phase_args = []
      @log_list   = []

      @cmd_cnt   = 0

      # コマンド取得
      commands = WatchDuel::get_cache_act_command(@key)
      if commands
        commands.each do |cmd|
          if cmd
            func = cmd[:func].gsub(/_handler/,"")
            args = cmd[:args]
            self.send(func, args)
            @cmd_cnt += 1
          end
        end

        # 初期設定コマンドの作成
        @init_commands = []
        make_init_commands
      end

      debug_last_puts(__method__)
    end

    def finalize
      @key            =
      @rule           =
      @stage          =
      @pl_deck        =
      @foe_deck       =
      @pl_cards       =
      @foe_cards      =
      @pl_card_idx    =
      @foe_card_idx   =
      @pl_hps         =
      @pl_max_hps     =
      @foe_hps        =
      @foe_max_hps    =
      @pl_damege      =
      @foe_damege     =
      @pl_state       =
      @foe_state      =
      @pl_ac          =
      @foe_ac         =
      @pl_table       =
      @foe_table      =
      @deck_max       =
      @deck_num       =
      @dist           =
      @pl_initi       =
      @turn           =
      @phase          =
      @phase_args     =
      @log_list       =
      @cmd_cnt        =
      @override_cards =
      @init_commands  = nil
    end

    def get_weapon_bonus(player=true)
      ret = []
      if player
        if @pl_deck.weapon_cards[@pl_card_idx]
          weapon_card = @pl_deck.weapon_cards[@pl_card_idx]

          sword_ap = 0
          weapon_card.each { |w| sword_ap = w.sword_ap }
          sword_dice_bonus = 0
          weapon_card.each { |w| sword_dice_bonus = w.sword_dice_bonus }
          sword_dp = 0
          weapon_card.each { |w| sword_dp = w.sword_dp }
          sword_def_dice_bonus = 0
          weapon_card.each { |w| sword_def_dice_bonus = w.sword_deffence_dice_bonus }

          arrow_ap = 0
          weapon_card.each { |w| arrow_ap = w.arrow_ap }
          arrow_dice_bonus = 0
          weapon_card.each { |w| arrow_dice_bonus = w.arrow_dice_bonus }
          arrow_dp = 0
          weapon_card.each { |w| arrow_dp = w.arrow_dp }
          arrow_def_dice_bonus = 0
          weapon_card.each { |w| arrow_def_dice_bonus = w.arrow_deffence_dice_bonus }

          ret << [sword_ap,sword_dice_bonus,sword_dp,sword_def_dice_bonus,
                  arrow_ap,arrow_dice_bonus,arrow_dp,arrow_def_dice_bonus]
        else
          ret << [0, 0, 0, 0, 0, 0, 0, 0]
        end
      else
        if @foe_deck.weapon_cards[@foe_card_idx]
          weapon_card = @foe_deck.weapon_cards[@foe_card_idx]

          sword_ap = 0
          weapon_card.each { |w| sword_ap = w.sword_ap }
          sword_dice_bonus = 0
          weapon_card.each { |w| sword_dice_bonus = w.sword_dice_bonus }
          sword_dp = 0
          weapon_card.each { |w| sword_dp = w.sword_dp }
          sword_def_dice_bonus = 0
          weapon_card.each { |w| sword_def_dice_bonus = w.sword_deffence_dice_bonus }

          arrow_ap = 0
          weapon_card.each { |w| arrow_ap = w.arrow_ap }
          arrow_dice_bonus = 0
          weapon_card.each { |w| arrow_dice_bonus = w.arrow_dice_bonus }
          arrow_dp = 0
          weapon_card.each { |w| arrow_dp = w.arrow_dp }
          arrow_def_dice_bonus = 0
          weapon_card.each { |w| arrow_def_dice_bonus = w.arrow_deffence_dice_bonus }

          ret << [sword_ap,sword_dice_bonus,sword_dp,sword_def_dice_bonus,
                  arrow_ap,arrow_dice_bonus,arrow_dp,arrow_def_dice_bonus]
        else
          ret << [0, 0, 0, 0, 0, 0, 0, 0]
        end
      end
      ret
    end

    def make_init_commands
      # ステータスの設定
      states = []
      @pl_state.each_with_index do |state,i|
        state.each do |s|
          if s[:id] != 0 && s[:turn] > 0
            set_state = [s[:id],s[:value],s[:turn],i]
            states.push(set_state.join(","))
          end
        end
      end
      if states.length > 0
        cmd = { :func => "set_buff_handler", :args => [true,states.join("_")] }
        @init_commands.push(cmd)
      end
      states = []
      if @pl_stuffed_toy_num && @pl_stuffed_toy_num > 0
        cmd = { :func => "pl_entrant_stuffed_toys_set_event_handler", :args => [true,@pl_stuffed_toy_num] }
        @init_commands.push(cmd)
      end
      @foe_state.each_with_index do |state,i|
        state.each do |s|
          if s[:id] != 0 && s[:turn] > 0
            set_state = [s[:id],s[:value],s[:turn],i]
            states.push(set_state.join(","))
          end
        end
      end
      if states.length > 0
        cmd = { :func => "set_buff_handler", :args => [false,states.join("_")] }
        @init_commands.push(cmd)
      end
      if @foe_stuffed_toy_num && @foe_stuffed_toy_num > 0
        cmd = { :func => "foe_entrant_stuffed_toys_set_event_handler", :args => [false,@foe_stuffed_toy_num] }
        @init_commands.push(cmd)
      end

      # キャラカードの設定
      chara_change_args = []
      if @pl_card_idx != 0
        weapon_bonus = get_weapon_bonus(true)
        chara_change_args << [true,@pl_card_idx,@pl_cards[@pl_card_idx].id,weapon_bonus.join(",")]
      end
      if @foe_card_idx != 0
        weapon_bonus = get_weapon_bonus(false)
        chara_change_args << [false,@foe_card_idx,@foe_cards[@foe_card_idx].id,weapon_bonus.join(",")]
      end
      if chara_change_args.size > 0
        cmd = { :func => "set_chara_card_idx_handler", :args => [[(@pl_card_idx==0),(@foe_card_idx==0)],chara_change_args] }
        @init_commands.push(cmd)
      end

      func = nil
      case @phase
      when :duel_move_card_phase_start then
        func = "entrant_move_card_add_action_handler"
      when :duel_attack_card_phase_start then
        func = "entrant_battle_card_add_action_handler"
      when :duel_deffence_card_phase_start then
        func = "entrant_battle_card_add_action_handler"
      else
        @pl_table  = []
        @foe_table = []
      end

      # 手札を配る
      acs = []
      @pl_ac.each { |ac| acs.push(ac[:id]) }
      @pl_table.each { |ac| acs.push(ac[:id]) } if func != nil
      foe_ac_size = @foe_ac.size
      foe_ac_size += @foe_table.size if func != nil
      cmd = { :func => "duel_refill_card_phase_handler", :args => [acs.join(","),0,foe_ac_size] }
      @init_commands.push(cmd)

      # 提出ターンの場合、場にカードを出す
      if func != nil
        @pl_table.each do |ac|
          cmd = { :func => func, :args => [true,0,0] }
          @init_commands.push(cmd)
        end
        @foe_table.each do |ac|
          cmd = { :func => func, :args => [false,0,0] }
          @init_commands.push(cmd)
        end
      end

      # 山札枚数リセット
      cmd = { :func => "reset_deck_num_handler", :args => [@deck_num] }
      @init_commands.push(cmd)

      # イニシアチブ、距離の設定
      cmd = { :func => "set_initi_and_dist_handler", :args => [@initi,@dist] }
      @init_commands.push(cmd)

      # ターンの設定
      cmd = { :func => "duel_start_turn_phase_handler", :args => [@turn] }
      @init_commands.push(cmd)

      # フェイズの設定
      cmd = { :func => "#{@phase}_handler", :args => @phase_args }
      @init_commands.push(cmd)

      # AC上書き
      @override_cards.each do |id, v|
        cmd = { :func => "foeEntrant_update_card_value_event_handler", :args => [id, v["u_value"], v["b_value"], false]}
        @init_commands.push(cmd)
      end

      # たまっているログをまとめて流す
      if @log_list.length > 0
        @log_list.each do |l|
          type = l[0]
          prm = (l[1] != nil) ? l[1] : []
          cmd = { :func => "set_message_str_data_handler", :args => [type,prm] }
          @init_commands.push(cmd)
        end
      end

    end

    # 状態異常更新チェック
    def state_check(fin_turn=true)
      check_state = []
      if fin_turn
        check_state = [CharaCardEvent::STATE_ATK_UP,
                       CharaCardEvent::STATE_ATK_DOWN,
                       CharaCardEvent::STATE_DEF_UP,
                       CharaCardEvent::STATE_DEF_DOWN,
                       CharaCardEvent::STATE_BERSERK,
                       CharaCardEvent::STATE_STOP,
                       CharaCardEvent::STATE_SEAL,
                       CharaCardEvent::STATE_UNDEAD,
                       CharaCardEvent::STATE_STONE,
                       CharaCardEvent::STATE_MOVE_UP,
                       CharaCardEvent::STATE_MOVE_DOWN,
                       CharaCardEvent::STATE_BIND,
                       CharaCardEvent::STATE_CHAOS,
                       CharaCardEvent::STATE_STIGMATA,
                       CharaCardEvent::STATE_STATE_DOWN,
                       CharaCardEvent::STATE_CURSE,
                       CharaCardEvent::STATE_UNDEAD2,
                       CharaCardEvent::STATE_CONTROL,
                      ]
      else
        check_state = [CharaCardEvent::STATE_POISON,
                       CharaCardEvent::STATE_PARALYSIS,
                       CharaCardEvent::STATE_DEAD_COUNT,
                       CharaCardEvent::STATE_REGENE,
                       CharaCardEvent::STATE_POISON2,
                      ]
      end
      @pl_state[@pl_card_idx].each do |state|
        if check_state.index(state[:id]) != nil && state[:turn] > 0
          state[:turn] -= 1
        end
      end
      @foe_state[@foe_card_idx].each do |state|
        if check_state.index(state[:id]) != nil && state[:turn] > 0
          state[:turn] -= 1
        end
      end
    end

    # デッキ枚数減算
    def decre_deck_num(pl_num=0,foe_num=0)
      @deck_num = @deck_max if (pl_num + foe_num) > @deck_num
      @deck_num -= (pl_num + foe_num)
    end

    # =========
    # Duel
    # =========

    # スタート時のハンドラ
    def one_to_one_duel_start(args)
      @log_list << [DUEL_MSGDLG_DUEL_START,nil]
      debug_puts(__method__)
    end

    # スタート時のハンドラ
    def three_to_three_duel_start(args)
      @log_list << [DUEL_MSGDLG_M_DUEL_START,nil]
      debug_puts(__method__)
    end

    # =========
    # DuelPhase
    # =========
    # ターンスタートのハンドラ
    def duel_start_turn_phase(args)
      # args 0:ターン数:int
      @turn = args[0]
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # カードが配られた場合のハンドラ
    def duel_refill_card_phase(args)
      # args 0:plのAC:String,1:方向:int(BIT演算),2:foeのAC枚数:int
      pl_ac_arr = args[0].split(",")
      pl_ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      args[2].times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      decre_deck_num(pl_ac_arr.size,args[2]) if pl_ac_arr.size > 0 || args[2] > 0
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # イベントカードが配られた場合のハンドラ
    def duel_refill_event_card_phase(args)
      # args 0:plのAC:String,1:方向:int(BIT演算),2:foeのAC枚数:int
      pl_ac_arr = args[0].split(",")
      pl_ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      args[2].times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 移動カード提出フェイズ開始
    def duel_move_card_phase_start(args)
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 移動カード提出フェイズ終了
    def duel_move_card_phase_finish(args)
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end


    # 移動の結果がでた時にハンドラ
    def duel_determine_move_phase(args)
      # args 0:ログ:String,1:Array[0:先行か:Boolean,1:距離:int,2:plの場AC:String,3:plの場AC方向:int(BIT演算),4:foeの場AC:String,5:foeの場AC方向:String,6:plのNUM:int,7:foeのNUM;int],2,ログ:String
      @dist      = args[1][1]
      @pl_table  = []
      @foe_table = []
      @phase = __method__
      @phase_args = args
      @log_list << [args[0][0],[args[0][1]]]
      @log_list << [args[2][0],[args[2][1]]]
      state_check(false)
      debug_puts(__method__)
    end

    # キャラ変更フェイズ開始
    def duel_chara_change_phase_start(args)
      # args 0:plキャラチェンジ:Boolean,1:foeキャラチェンジ:Boolean
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # キャラ変更フェイズ終了
    def duel_chara_change_phase_finish(args)
      # args 0:plが対象か:Boolean,1:plArray[0:選択キャラデッキ内番号:int,1:選択キャラID,2:選択キャラ装備データ:String],2:plArray[0:選択キャラデッキ内番号:int,1:選択キャラID,2:選択キャラ装備データ:String]
      @pl_card_idx = args[1][0]
      @foe_card_idx = args[2][0]
      @phase = __method__
      @phase_args = args
      @log_list << [DUEL_MSGDLG_CHANGE_CHARA,nil]
      debug_puts(__method__)
    end

    # 攻撃カード提出フェイズ開始
    def duel_attack_card_phase_start(args)
      # args 0:foeArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],1:plArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],2:plのターンか
      @pl_initi = args[2]
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 防御カード提出フェイズ開始
    def duel_deffence_card_phase_start(args)
      # args 0:foeArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],1:plArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],2:plのターンか
      @pl_initi = args[2]
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 攻撃カード提出フェイズ終了
    def duel_attack_card_phase_finish(args)
      # args 0:foeArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],1:plArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],2:Array[0:plの場AC:String,1:plの場AC方向:int(BIT演算),2:foeの場AC:String,3:foeの場AC方向:String]
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 防御カード提出フェイズ終了
    def duel_deffence_card_phase_finish(args)
      # args 0:foeArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],1:plArray[0:AClist:String,1:ACONList:int(BIT演算),2:point:int],2:Array[0:plの場AC:String,1:plの場AC方向:int(BIT演算),2:foeの場AC:String,3:foeの場AC方向:String]
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 戦闘ポイント決定フェイズの時のハンドラ
    def duel_det_battle_point_phase(args)
      # args 0:ログ:String,1:Array[0:plの場AC:String,1:plの場AC方向:int(BIT演算),2:foeの場AC:String,3:foeの場AC方向:String]
      @pl_table  = []
      @foe_table = []
      @phase = __method__
      @phase_args = args
      @log_list << [args[0][0],[args[0][1]]]
      debug_puts(__method__)
    end

    # 戦闘の結果がでた時のハンドラ
    def duel_battle_result_phase(args)
      # args 0:ログ:String,1:Array[0:plのターンか:Boolean,1:atkのダイス値:String,1:defのダイス値:String]
      @phase = __method__
      @phase_args = args
      @log_list << [args[0][0],[args[0][1]]] if args[0]!=nil
      debug_puts(__method__)
    end

    # 死亡キャラ変更フェイズ開始
    def duel_dead_chara_change_phase_start(args)
      # args 0:plキャラチェンジ:Boolean,1:foeキャラチェンジ:Boolean
      @phase = __method__
      @phase_args = args
      debug_puts(__method__)
    end

    # 死亡キャラ変更フェイズ終了
    def duel_dead_chara_change_phase_finish(args)
      # args 0:plが対象か:Boolean,1:foe選択キャラデッキ内番号:int,2:foe選択キャラID,3:foe選択キャラ装備データ:String
      @pl_card_idx = args[0][0]
      @foe_card_idx = args[1][0]
      @phase = __method__
      @phase_args = args
      @log_list << [DUEL_MSGDLG_CHANGE_CHARA,nil]
      debug_puts(__method__)
    end

    # ターン終了のハンドラ
    def duel_finish_turn_phase(args)#
      # args 0:距離:int,1:終了ターン:int
      @pl_table  = []
      @foe_table = []
      @phase = __method__
      @phase_args = args
      @log_list << [DUEL_MSGDLG_TURN_END,[args[1]]]
      state_check
      debug_puts(__method__)
    end

    # ===================
    # EntrantAction
    # ===================
    # 自分が移動方向を決定する
    def pl_entrant_set_direction_action(args)
      # args 0:方向:int
      debug_puts(__method__)
    end

    # 自分が移動カードを出す
    def pl_entrant_move_card_add_action(args)
      # args 0:手札のidx:int,1:カードID:int
      if args[0] != -1
        ac = @pl_ac.pop
        @pl_table.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 敵側が移動カードを出す
    def foe_entrant_move_card_add_action(args)
      # args 0:手札のidx:int,1:カードID:int
      if args[0] != -1
        ac = @foe_ac.pop
        @foe_table.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 敵側が移動カードを取り除く
    def foe_entrant_move_card_remove_action(args)
      # args 0:場カードのidx:int,1:カードID:int
      if args[0] != -1
        ac = @foe_table.pop
        @foe_ac.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 自分側が移動カードを取り除く
    def pl_entrant_move_card_remove_action(args)
      # args 0:場カードのidx:int,1:カードID:int
      if args[0] != -1
        ac = @pl_table.pop
        @pl_ac.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 敵側がカードを回転させる
    def foe_entrant_card_rotate_action(args)
      # args 0:回転させるカードの場所:int,1:カードidx:int,2:カードID:int,3:カードを回す方向:Boolean
      debug_puts(__method__)
    end

    # 自分がカードを回転させる
    def pl_entrant_card_rotate_action(args)
      # args 0:回転させるカードの場所:int,1:カードidx:int,2:カードID:int,3:カードを回す方向:Boolean
      debug_puts(__method__)
    end

    # 敵側がイベントでカードを回転させる
    def foe_entrant_event_card_rotate_action(args)
      # args 0:回転させるカードの場所:int,1:カードidx:int,2:カードID:int,3:カードを回す方向:Boolean
      debug_puts(__method__)
    end

    # 自分がイベントでカードを回転させる
    def pl_entrant_event_card_rotate_action(args)
      # args 0:回転させるカードの場所:int,1:カードidx:int,2:カードID:int,3:カードを回す方向:Boolean
      debug_puts(__method__)
    end

    # 自分が戦闘カードを出す
    def pl_entrant_battle_card_add_action(args)
      # args 0:手札のカードidx:int,1:カードid:int
      if args[0] != -1
        ac = @pl_ac.pop
        @pl_table.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 敵側が戦闘カードを出す
    def foe_entrant_battle_card_add_action(args)
      # args 0:手札のカードidx:int,1:カードid:int
      if args[0] != -1
        ac = @foe_ac.pop
        @foe_table.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 自分が戦闘カードを取り除く
    def pl_entrant_battle_card_remove_action(args)
      # args 0:場のカードidx:int,1:カードid:int
      if args[0] != -1
        ac = @pl_table.pop
        @pl_ac.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 敵側が戦闘カードを取り除く
    def foe_entrant_battle_card_remove_action(args)
      # args 0:場のカードidx:int,1:カードid:int
      if args[0] != -1
        ac = @foe_table.pop
        @foe_ac.push(ac) if ac != nil
      end
      debug_puts(__method__)
    end

    # 自分のキャラカードを変更する
    def pl_entrant_chara_change_action(args)
      # args 0:デッキカードidx:int,1:カードid:int,2:装備効果:String
      @pl_card_idx = args[0]
      debug_puts(__method__)
    end

    # 相手のキャラカードを変更する
    def foe_entrant_chara_change_action(args)
      debug_puts(__method__)
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def foe_entrant_init_done_action(args)
      debug_puts(__method__)
    end

    # 敵側のイニシアチブフェイズの完了アクション
    def pl_entrant_init_done_action(args)
      debug_puts(__method__)
    end

    # 敵側の攻撃フェイズの完了アクション
    def foe_entrant_attack_done_action(args)
      debug_puts(__method__)
    end

    # 敵側の防御フェイズの完了アクション
    def foe_entrant_deffence_done_action(args)
      debug_puts(__method__)
    end

    # プレイヤー側の攻撃フェイズの完了アクション
    def pl_entrant_attack_done_action(args)
      debug_puts(__method__)
    end

    # プレイヤー側の防御フェイズの完了アクション
    def pl_entrant_deffence_done_action(args)
      debug_puts(__method__)
    end

    # 自分が移動する
    def pl_entrant_move_action(args)
      # args 0:距離:int
      debug_puts(__method__)
    end

    # ===================
    # EntrantEvent
    # ===================
    # プレイヤーダメージのイベント
    def plEntrant_damaged_event(args)
      # args 0:ダメージ:int
      @pl_hps[@pl_card_idx] -= args[0][0]
      @pl_hps[@pl_card_idx] = 0 if @pl_hps[@pl_card_idx] < 0
      @pl_damege[@pl_card_idx] += args[0][0]
      @pl_damege[@pl_card_idx] = @pl_max_hps[@pl_card_idx] if @pl_damege[@pl_card_idx] > @pl_max_hps[@pl_card_idx]
      debug_puts(__method__)
    end

    # 敵ダメージのハンドラのイベント
    def foeEntrant_damaged_event(args)
      # args 0:ダメージ:int
      @foe_hps[@foe_card_idx] -= args[0][0]
      @foe_hps[@foe_card_idx] = 0 if @foe_hps[@foe_card_idx] < 0
      @foe_damege[@foe_card_idx] += args[0][0]
      @foe_damege[@foe_card_idx] = @foe_max_hps[@foe_card_idx] if @foe_damege[@foe_card_idx] > @foe_max_hps[@foe_card_idx]
      debug_puts(__method__)
    end

    # プレイヤーの回復イベント
    def plEntrant_healed_event(args)
      # args 0:回復ポイント:int
      @pl_hps[@pl_card_idx] += args[0]
      @pl_hps[@pl_card_idx] = 0 if @pl_hps[@pl_card_idx] > @pl_max_hps[@pl_card_idx]
      @pl_damege[@pl_card_idx] -= args[0]
      @pl_damege[@pl_card_idx] = 0 if @pl_damege[@pl_card_idx] < 0
      debug_puts(__method__)
    end

    # 敵の回復イベント
    def foeEntrant_healed_event(args)
      # args 0:回復ポイント:int
      @foe_hps[@foe_card_idx] += args[0]
      @foe_hps[@foe_card_idx] = 0 if @foe_hps[@foe_card_idx] > @foe_max_hps[@foe_card_idx]
      @foe_damege[@foe_card_idx] -= args[0]
      @foe_damege[@foe_card_idx] = 0 if @foe_damege[@foe_card_idx] < 0
      debug_puts(__method__)
    end

    # プレイヤーのパーティ回復イベント
    def plEntrant_party_healed_event(args)
      # args 0:デッキカードidx:int,1:回復ポイント:int
      @pl_hps[args[0]] += args[1]
      @pl_hps[args[0]] = 0 if @pl_hps[args[0]] > @pl_max_hps[args[0]]
      @pl_damege[args[0]] -= args[1]
      @pl_damege[args[0]] = 0 if @pl_damege[args[0]] < 0
      debug_puts(__method__)
    end

    # 敵のパーティ回復イベント
    def foeEntrant_party_healed_event(args)
      # args 0:デッキカードidx:int,1:回復ポイント:int
      @foe_hps[args[0]] += args[1]
      @foe_hps[args[0]] = 0 if @foe_hps[args[0]] > @foe_max_hps[args[0]]
      @foe_damege[args[0]] -= args[1]
      @foe_damege[args[0]] = 0 if @foe_damege[args[0]] < 0
      debug_puts(__method__)
    end

    # プレイヤーのパーティ蘇生イベント
    def plEntrant_revive_event(args)
      # args 0:デッキカードidx:int,1:回復ポイント:int
      @pl_hps[args[0]] = args[1]
      @pl_damege[args[0]] = @pl_max_hps[args[0]] - args[1]
      debug_puts(__method__)
    end

    # 敵のパーティ蘇生イベント
    def foeEntrant_revive_event(args)
      # args 0:デッキカードidx:int,1:回復ポイント:int
      @foe_hps[args[0]] = args[1]
      @foe_damege[args[0]] = @foe_max_hps[args[0]] - args[1]
      debug_puts(__method__)
    end

    # プレイヤーの行動制限イベント
    def plEntrant_constraint_event(args)
      # args ;flag
      debug_puts(__method__)
    end

    # プレイヤーのHP変更イベント
    def plEntrant_hit_point_changed_event(args)
      # args 0:変更後HP:int
      @pl_hps[@pl_card_idx] = args[0]
      @pl_damege[@pl_card_idx] = @pl_max_hps[@pl_card_idx] - args[0]
      debug_puts(__method__)
    end

    # 敵のHP変更イベント
    def foeEntrant_hit_point_changed_event(args)
      # args 0:変更後HP:int
      @foe_hps[@foe_card_idx] = args[0]
      @foe_damege[@foe_card_idx] = @foe_max_hps[@foe_card_idx] - args[0]
      debug_puts(__method__)
    end

    # プレイヤーのパーティダメージイベント
    def plEntrant_party_damaged_event(args)
      # args 0:デッキカードidx:int,1:ダメージ:int
      @pl_hps[args[0]] -= args[1]
      @pl_hps[args[0]] = 0 if @pl_hps[args[0]] < 0
      @pl_damege[args[0]] += args[1]
      @pl_damege[args[0]] = @pl_max_hps[args[0]] if @pl_damege[args[0]] > @pl_max_hps[args[0]]
      debug_puts(__method__)
    end

    # 敵のパーティダメージイベント
    def foeEntrant_party_damaged_event(args)
      # args 0:デッキカードidx:int,1:ダメージ:int
      @foe_hps[args[0]] -= args[1]
      @foe_hps[args[0]] = 0 if @foe_hps[args[0]] < 0
      @foe_damege[args[0]] += args[1]
      @foe_damege[args[0]] = @foe_max_hps[args[0]] if @foe_damege[args[0]] > @foe_max_hps[args[0]]
      debug_puts(__method__)
    end

    # プレイヤーの状態回復イベント
    def plEntrant_cured_event(args)
      @pl_state.each_index do |i|
        @pl_state[i] = []
      end
      debug_puts(__method__)
    end

    # 敵の状態回復イベント
    def foeEntrant_cured_event(args)
      @foe_state.each_index do |i|
        @foe_state[i] = []
      end
      debug_puts(__method__)
    end

    # プレイヤーアクションカード使用イベント
    def plEntrant_use_action_card_event(args)
      # args 0:カードid:int
      if @pl_table.size > 0
        @pl_table.pop
      end
      debug_puts(__method__)
    end

    # 敵アクションカード使用イベント
    def foeEntrant_use_action_card_event(args)
      # args 0:カードid:int
      if @foe_table.size > 0
        @foe_table.pop
      end
      debug_puts(__method__)
    end

    # プレイヤーアクションカード破棄イベント
    def plEntrant_discard_event(args)
      # args 0:カードid:int
      if @pl_ac.size > 0
        @pl_ac.pop
      end
      debug_puts(__method__)
    end

    # 敵のアクションカード破棄イベント
    def foeEntrant_discard_event(args)
      # args 0:カードid:int
      if @foe_ac.size > 0
        @foe_ac.pop
      end
      debug_puts(__method__)
    end

    # プレイヤーアクションカード破棄(fromテーブル)イベント
    def plEntrant_discard_table_event(args)
      # args 0:カードid:int
      if @pl_table.size > 0
        @pl_table.pop
      end
      debug_puts(__method__)
    end

    # 敵のアクションカード破棄(fromテーブル)イベント
    def foeEntrant_discard_table_event(args)
      # args 0:カードid:int
      if @foe_table.size > 0
        @foe_table.pop
      end
      debug_puts(__method__)
    end

    # プレイヤーのポイントが更新された場合のイベント
    def plEntrant_point_update_event(args)
      # args 0:ACList:String,1:ACOnList:int(BIT演算),2:ポイント:int
      debug_puts(__method__)
    end

    # プレイヤーのポイントが更新された場合のイベント
    def plEntrant_point_rewrite_event(args)
      # args 0:ポイント:int
      debug_puts(__method__)
    end

    # 敵のポイントが更新された場合のイベント
    def foeEntrant_point_rewrite_event(args)
      # args 0:ポイント:int
      debug_puts(__method__)
    end

    # プレイヤーが特別にカードを配られる場合のイベント
    def plEntrant_special_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      ac_arr = args[0].split(",")
      ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      decre_deck_num(ac_arr.size) if ac_arr.size > 0
      debug_puts(__method__)
    end

    # 敵が特別にカードを配られる場合のイベント
    def foeEntrant_special_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      args[2].times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      decre_deck_num(args[2]) if args[2] > 0
      debug_puts(__method__)
    end

    # プレイヤーに墓地のカードが配られる場合のイベント
    def plEntrant_grave_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      ac_arr = args[0].split(",")
      ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      debug_puts(__method__)
    end

    # 敵に墓地のカードが配られる場合のイベント
    def foeEntrant_grave_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      args[2].times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      debug_puts(__method__)
    end

    # プレイヤーに相手の手札のカードが配られる場合のイベント
    def plEntrant_steal_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      ac_arr = args[0].split(",")
      ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      args[2].times do
        @foe_ac.pop
      end
      debug_puts(__method__)
    end

    # 敵にプレイヤーの手札のカードが配られる場合のイベント
    def foeEntrant_steal_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      ac_arr = args[0].split(",")
      ac_arr.size.times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      args[2].times do
        @pl_ac.pop
      end
      debug_puts(__method__)
    end

    # プレイヤーが特別にイベントカードを配られる場合のイベント
    def plEntrant_special_event_card_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      ac_arr = args[0].split(",")
      ac_arr.size.times do
        @pl_ac.push({ :id=>0, :dir=>true})
      end
      debug_puts(__method__)
    end

    # 敵が特別にイベントカードを配られる場合のイベント
    def foeEntrant_special_event_card_dealed_event(args)
      # args 0:ACList:String,1:ACの向き:int(BIT演算),2:枚数:int
      args[2].times do
        @foe_ac.push({ :id=>0, :dir=>true})
      end
      debug_puts(__method__)
    end

    # プレイヤーに仮のダイスが振られるときのイベント
    def plEntrant_dice_roll_event(args)
      # args 0:atkのダイス値:String,1:defのダイス値:String
      debug_puts(__method__)
    end

    # 敵に仮のダイスが振られるときのイベント
    def foeEntrant_dice_roll_event(args)
      # args 0:atkのダイス値:String,1:defのダイス値:String
      debug_puts(__method__)
    end

    # プレイヤーの装備カードが更新されるときのイベント
    def plEntrant_update_weapon_event(args)
      # args 0:plの更新パラメータ:String,1:foeの更新パラメータ:String
      debug_puts(__method__)
    end

    # アクションカードの数値が更新されるときのイベント
    def plEntrant_update_card_value_event(args)
      # args 0:id:int, 1:u_val:int, 2:b_val:int, 3:reset:bool
      if args[3]
        @override_cards.delete(args[0]) if @override_cards.key?(args[0])
      else
        @override_cards[args[0]] = { "u_value"=>args[1], "b_value"=>args[2] }
      end
      debug_puts(__method__)
    end

    # アクションカードの数値が更新されるときのイベント
    def foeEntrant_update_card_value_event(args)
      # args 0:id:int, 1:u_val:int, 2:b_val:int, 3:reset:bool
      if args[3]
        @override_cards.delete(args[0]) if @override_cards.key?(args[0])
      else
        @override_cards[args[0]] = { "u_value"=>args[1], "b_value"=>args[2] }
      end
      debug_puts(__method__)
    end

    # プレイヤーの最大カード枚数が更新された場合のイベント
    def plEntrant_cards_max_update_event(args)
      # args 0:カード最大枚数:int
      debug_puts(__method__)
    end

    # プレイヤーのボーナスが変化した際のイベント
    def plEntrant_duel_bonus_event(args)
      # args 0:ボーナスタイプ:int,1:ボーナス値:int
      debug_puts(__method__)
    end

    # プレイヤーの特殊メッセージのイベント
    def plEntrant_special_message_event(args)
      debug_puts(__method__)
    end

    # プレイヤーの特殊メッセージのイベント
    def foeEntrant_special_message_event(args)
      debug_puts(__method__)
    end

    # プレイヤーの汎用メッセージのイベント
    def plEntrant_duel_message_event(args)
      debug_puts(__method__)
    end

    # プレイヤーの汎用メッセージのイベント
    def foeEntrant_duel_message_event(args)
      debug_puts(__method__)
    end

    # プレイヤーのトラップ発動イベント
    def plEntrant_trap_action_event(args)
      debug_puts(__method__)
    end

    # 敵のトラップ発動イベント
    def foeEntrant_trap_action_event(args)
      debug_puts(__method__)
    end

    # プレイヤーのトラップ遷移イベント
    def plEntrant_trap_update_event(args)
      debug_puts(__method__)
    end

    # 敵のトラップ遷移イベント
    def foeEntrant_trap_update_event(args)
      debug_puts(__method__)
    end

    # 現在ターン数変更のイベント
    def plEntrant_set_turn_event(args)
      # args 0:変更ターン値:int
      @turn = args[0]
      debug_puts(__method__)
    end

    # 現在ターン数変更のイベント
    def foeEntrant_set_turn_event(args)
      # args 0:変更ターン値:int
      @turn = args[0]
      debug_puts(__method__)
    end

    # カードロックイベント
    def plEntrant_card_lock_event(args)
      debug_puts(__method__)
    end

    # カードロック解除イベント
    def plEntrant_clear_card_locks_event(args)
      debug_puts(__method__)
    end

    # =====================
    # DeckEvent
    # =====================

    # デッキの初期化のハンドラ
    def deck_init(args)
      # args 0:デッキサイズ:int
      @deck_num += args[0]
      debug_puts(__method__)
    end

    # =====================
    # ActionCardEvent
    # =====================
    def action_card_chance_event(args)
      # args 0:plか:Boolean,1:ACList:String,2:AC方向:int(BIT演算),3:AC枚数:int
      if args[0]
        ac_arr = args[1].split(",")
        ac_arr.size.times do
          @pl_ac.push({ :id=>0, :dir=>true})
        end
      else
        args[3].times do
          @foe_ac.push({ :id=>0, :dir=>true})
        end
      end
      @deck_num = @deck_num < args[3] ? 0 : @deck_num - args[3]
      debug_puts(__method__)
    end

    def action_card_heal_event(args)
      debug_puts(__method__)
    end

    # =====================
    # CharaCardEvent
    # =====================
    # 状態付加ON時のプレイヤー側ハンドラ
    def pl_entrant_buff_on_event(args)
      # args 0:plか:Boolean,,1:index:int,2:状態異常ID:int,3:値:int,4:ターン数:int,5:index:int
      if args[0][0]
        @pl_state[args[0][1]] << {:id=>args[0][2],:value=>args[0][3],:turn=>args[0][4] }
      else
        @foe_state[args[0][1]] << {:id=>args[0][2],:value=>args[0][3],:turn=>args[0][4] }
      end
      @log_list << [args[1][0],[args[1][1],args[1][2]]]
      debug_puts(__method__)
    end

    # 状態付加ON時の敵側側ハンドラ
    def foe_entrant_buff_on_event(args)
      # args 0:plか:Boolean,,1:index:int,2:状態異常ID:int,3:値:int,4:ターン数:int,5:index:int
      if args[0][0]
        @pl_state[args[0][1]] << {:id=>args[0][2],:value=>args[0][3],:turn=>args[0][4] }
      else
        @foe_state[args[0][1]] << {:id=>args[0][2],:value=>args[0][3],:turn=>args[0][4] }
      end
      @log_list << [args[1][0],[args[1][1],args[1][2]]]
      debug_puts(__method__)
    end

    # 状態付加Off時のプレイヤー側ハンドラ
    def pl_entrant_buff_off_event(args)
      # args 0:plか:Boolean,1:index:int,2:状態異常ID:int,3:値:int
      idx = 0
      if args[0]
        @pl_state[args[1]].each_with_index do |s,i|
          idx = i if s[:id] == args[2]
        end
        @pl_state[args[1]].delete_at(idx)
      else
        @foe_state[args[1]].each_with_index do |s,i|
          idx = i if s[:id] == args[2]
        end
        @foe_state[args[1]].delete_at(idx)
      end
      debug_puts(__method__)
    end

    # 状態付加Off時の敵側側ハンドラ
    def foe_entrant_buff_off_event(args)
      # args 0:plか:Boolean,1:index:int,2:状態異常ID:int,3:値:int
      idx = 0
      if args[0]
        @pl_state[args[1]].each_with_index do |s,i|
          idx = i if s[:id] == args[2]
        end
        @pl_state[args[1]].delete_at(idx)
      else
        @foe_state[args[1]].each_with_index do |s,i|
          idx = i if s[:id] == args[2]
        end
        @foe_state[args[1]].delete_at(idx)
      end
      debug_puts(__method__)
    end

    # 状態付加Update時のプレイヤー側ハンドラ
    def pl_entrant_buff_update_event(args)
      # args 0:plか:Boolean,1:状態異常ID:int,2:値:int,3:index
      idx = 0
      if args[0]
        @pl_state[args[3]].each_with_index do |s,i|
          idx = i if s[:id] == args[1]
        end
        if @pl_state[args[3]][idx] != nil
          @pl_state[args[3]][idx][:id]    = args[1]
          @pl_state[args[3]][idx][:value] = args[2]
        end
      else
        @foe_state[args[3]].each_with_index do |s,i|
          idx = i if s[:id] == args[1]
        end
        if @foe_state[args[3]][idx] != nil
          @foe_state[args[3]][idx][:id]    = args[1]
          @foe_state[args[3]][idx][:value] = args[2]
        end
      end
      debug_puts(__method__)
    end

    # 状態付加Update時の敵側側ハンドラ
    def foe_entrant_buff_update_event(args)
      # args 0:plか:Boolean,1:状態異常ID:int,2:値:int,3:index
      idx = 0
      if args[0]
        @pl_state[args[3]].each_with_index do |s,i|
          idx = i if s[:id] == args[1]
        end
        if @pl_state[args[3]][idx] != nil
          @pl_state[args[3]][idx][:id]    = args[1]
          @pl_state[args[3]][idx][:value] = args[2]
        end
      else
        @foe_state[args[3]].each_with_index do |s,i|
          idx = i if s[:id] == args[1]
        end
        if @foe_state[args[3]][idx] != nil
          @foe_state[args[3]][idx][:id]    = args[1]
          @foe_state[args[3]][idx][:value] = args[2]
        end
      end
      debug_puts(__method__)
    end

    # 猫状態Update時のプレイヤー側側ハンドラ
    def pl_entrant_cat_state_update_event(args)
      debug_puts(__method__)
    end

    # 猫状態Update時の敵側側ハンドラ
    def foe_entrant_cat_state_update_event(args)
      debug_puts(__method__)
    end

    # 必殺技ON時のプレイヤー側ハンドラ
    def pl_entrant_feat_on_event(args)
      debug_puts(__method__)
    end

    # 必殺技ON時の敵側側ハンドラ
    def foe_entrant_feat_on_event(args)
      debug_puts(__method__)
    end

    # 必殺技Off時のプレイヤー側ハンドラ
    def pl_entrant_feat_off_event(args)
      debug_puts(__method__)
    end

    # 必殺技Off時の敵側側ハンドラ
    def foe_entrant_feat_off_event(args)
      debug_puts(__method__)
    end

    # 必殺技が変更された時のプレイヤー側ハンドラ
    def pl_entrant_change_feat_event(args)
      # args 0:plか:Boolean,1:必殺技ID:int
      debug_puts(__method__)
    end

    # 必殺技が変更された時の敵側ハンドラ
    def foe_entrant_change_feat_event(args)
      # args 0:plか:Boolean,1:必殺技ID:int
      debug_puts(__method__)
    end

    # 必殺技が実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_feat_event(args)
      # args 0:plか:Boolean,1:必殺技ID:int
      debug_puts(__method__)
    end

    # 必殺技が実行された時の敵側ハンドラ
    def foe_entrant_use_feat_event(args)
      # args 0:plか:Boolean,1:必殺技ID:int
      debug_puts(__method__)
    end

    # パッシブが実行された時のプレイヤー側ハンドラ
    def pl_entrant_use_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # パッシブが実行された時の敵側ハンドラ
    def foe_entrant_use_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # パッシブが実行された時のプレイヤー側ハンドラ
    def pl_entrant_on_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # パッシブが実行された時の敵側ハンドラ
    def foe_entrant_on_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # パッシブが終了した時のプレイヤー側ハンドラ
    def pl_entrant_off_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # パッシブが終了した時の敵側ハンドラ
    def foe_entrant_off_passive_event(args)
      # args 0:plか:Boolean,1:パッシブID:int
      debug_puts(__method__)
    end

    # キャラカードを更新する。変身用。
    def pl_entrant_change_chara_card_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # キャラカードを更新する。変身用。
    def foe_entrant_change_chara_card_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_on_transform_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_on_transform_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # キャラカード変身時のプレイヤー側ハンドラ
    def pl_entrant_off_transform_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # キャラカード変身時の敵側側ハンドラ
    def foe_entrant_off_transform_event(args)
      # args 0:plか:Boolean
      debug_puts(__method__)
    end

    # きりがくれプレイヤー側ON
    def pl_entrant_on_lost_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:distance:int, 2:真のdistance:int
      debug_puts(__method__)
    end

    # きりがくれ的側ON
    def foe_entrant_on_lost_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:distance:int, 2:真のdistance:int
      debug_puts(__method__)
    end

    # きりがくれプレイヤー側OFF
    def pl_entrant_off_lost_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:distance:int
      debug_puts(__method__)
    end

    # きりがくれ的側OFF
    def foe_entrant_off_lost_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:distance:int
      debug_puts(__method__)
    end

    # プレイヤー側 霧ライト
    def pl_entrant_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:range:String
      debug_puts(__method__)
    end

    # 敵側霧ライト
    def foe_entrant_in_the_fog_event(args)
      # args 0:plか:Boolean, 1:range:String
      debug_puts(__method__)
    end

    # フィールド状態変更イベント
    def plEntrant_set_field_status_event(args)
      # args 0:kind:int, 1:pow:int, 2:turn:int
      debug_puts(__method__)
    end

    # フィールド状態変更イベント
    def foeEntrant_set_field_status_event(args)
      # args 0:kind:int, 1:pow:int, 2:turn:int
      debug_puts(__method__)
    end

    # 技の発動条件を更新 PL
    def pl_entrant_update_feat_condition_event(args)
      # args 0:plか:Boolean, 1:chara_index:int, 3:feat_index:int, 4:condition
      debug_puts(__method__)
    end

    # 技の発動条件を更新 FOE
    def foe_entrant_update_feat_condition_event(args)
      # args 0:plか:Boolean, 1:chara_index:int, 3:feat_index:int, 4:condition
      debug_puts(__method__)
    end

    # 自身の周囲にヌイグルミ
    def pl_entrant_stuffed_toys_set_event(args)
      # args 0:plか:Boolean, 1:num:int
      @pl_stuffed_toy_num = args[1]
      debug_puts(__method__)
    end

    # 自身の周囲にヌイグルミ
    def foe_entrant_stuffed_toys_set_event(args)
      # args 0:plか:Boolean, 1:num:int
      @foe_stuffed_toy_num = args[1]
      debug_puts(__method__)
    end

    def debug_puts(method)
      return

      puts "******************** #{method} ********************"
      pl_deck_ids = []
      foe_deck_ids = []
      @pl_cards.each_index do |s|
        if @pl_cards[s]      # 念のためのチェック
          pl_deck_ids << @pl_cards[s].id
        end
      end
      @foe_cards.each_index do |s|
        if @foe_cards[s]      # 念のためのチェック
          foe_deck_ids << @foe_cards[s].id
        end
      end
      puts "pl_deck_ids    :#{pl_deck_ids}"
      puts "foe_deck_ids   :#{foe_deck_ids}"
      puts "pl_card_idx    :#{@pl_card_idx}"
      puts "foe_card_idx   :#{@foe_card_idx}"
      puts "pl_hps         :#{@pl_hps}"
      puts "foe_hps        :#{@foe_hps}"
      puts "pl_max_hps     :#{@pl_max_hps}"
      puts "foe_max_hps    :#{@foe_max_hps}"
      puts "pl_state       :#{@pl_state}"
      puts "foe_state      :#{@foe_state}"
      puts "pl_ac_size     :#{@pl_ac.size}"
      puts "foe_ac_size    :#{@foe_ac.size}"
      puts "pl_table_size  :#{@pl_table.size}"
      puts "foe_table_size :#{@foe_table.size}"
      puts "pl_initi       :#{@pl_initi}"
      puts "turn           :#{@turn}"
      puts "phase          :#{@phase}"
      puts "******************** #{method} ********************"
    end

    def debug_last_puts(method)
      return

      puts "******************** #{method} ********************"
      if @pl_cards
        pl_deck_ids = []
        @pl_cards.each_index do |s|
          if @pl_cards[s]      # 念のためのチェック
            pl_deck_ids << @pl_cards[s].id
          end
        end
      end
      if @foe_cards
        foe_deck_ids = []
        @foe_cards.each_index do |s|
          if @foe_cards[s]      # 念のためのチェック
            foe_deck_ids << @foe_cards[s].id
          end
        end
      end
      puts "pl_deck_ids    :#{pl_deck_ids}"      if pl_deck_ids
      puts "foe_deck_ids   :#{foe_deck_ids}"     if foe_deck_ids
      puts "pl_card_idx    :#{@pl_card_idx}"     if @pl_card_idx
      puts "foe_card_idx   :#{@foe_card_idx}"    if @foe_card_idx
      puts "pl_hps         :#{@pl_hps}"          if @pl_hps
      puts "foe_hps        :#{@foe_hps}"         if @foe_hps
      puts "pl_max_hps     :#{@pl_max_hps}"      if @pl_max_hps
      puts "foe_max_hps    :#{@foe_max_hps}"     if @foe_max_hps
      puts "pl_damege      :#{@pl_damege}"       if @pl_damege
      puts "foe_damege     :#{@foe_damege}"      if @foe_damege
      puts "pl_state       :#{@pl_state}"        if @pl_state
      puts "foe_state      :#{@foe_state}"       if @foe_state
      puts "pl_ac_size     :#{@pl_ac.size}"      if @pl_ac
      puts "foe_ac_size    :#{@foe_ac.size}"     if @foe_ac
      puts "pl_table_size  :#{@pl_table.size}"   if @pl_table
      puts "foe_table_size :#{@foe_table.size}"  if @foe_table
      puts "deck_max       :#{@deck_max}"        if @deck_max
      puts "deck_num       :#{@deck_num}"        if @deck_num
      puts "distance       :#{@dist}"            if @dist
      puts "pl_initi       :#{@pl_initi}"        if @pl_initi
      puts "stage          :#{@stage}"           if @stage
      puts "turn           :#{@turn}"            if @turn
      puts "phase          :#{@phase}"           if @phase
      puts "phase_args     :#{@phase_args}"      if @phase_args
      puts "******************** #{method} ********************"

    end

  end

end
