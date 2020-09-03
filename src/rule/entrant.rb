# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

# -*- coding: utf-8 -*-
module Unlight
    POINT_CHECK_MOVE =1
    POINT_CHECK_BATTLE =0

  # 参加者クラス
  class Entrant < BaseEvent
    DEFAULT_CARD_NUM = 5
    DISTANCE_MAX = 3
    POINT_CHECK_MOVE =1
    POINT_CHECK_BATTLE =0
    EVENT_CARD_DRAW_NUM =1

    # 移動方向の列挙
    DIRECTION_PEND         = 2
    DIRECTION_FORWARD      = -1
    DIRECTION_STAY         = 0
    DIRECTION_BACKWARD     = 1
    DIRECTION_CHARA_CHANGE = 3

    # 場の状態
    FIELD_STATUS = {
      "BLANK" => 0,
      "FOG" => 1,     # 霧状態 位置不明
      "AC_LOCK" => 2, # カードロック カードの移動
    }

    attr_accessor :cards_max, :cards, :hit_points, :hit_points_max,
    :distance, :initiative,:exit,:foe, :direction, :result_exp, :result_gems,
    :event_card_draw_num, :chara_change_index, :chara_change_force, :trap,
    :instant_kill_damage, :is_indomitable, :indomitable_dice_damage, :transformable, :is_transforming,
    :is_highgate, :magnification_hurt_const_damage, :magnification_cause_const_damage,
    :field_status, :seconds, :bp_calc_range_free, :determined_damage, :hiding_was_finished,
    :special_gem_bonus_multi, :monitoring
    attr_reader :reward_bonus, :base_exp, :exp_bonus,:before_damage,:damaged_times

    def initialize(c, ccs, wcs, qcs, ecs, dist, d_set, hp_up = 0, ap_up = 0, dp_up = 0, ai = :none)	# By_K2
      super
      share_context(c)
      @chara_cards = ccs                         # 戦闘に使用するキャラカードの配列
      @cards_max = DEFAULT_CARD_NUM              # 所持できるアクションカードの最大数
      @cards = []                                # 現在の所持アクションカード
      @event_cards = ecs                         # 現在の所持イベントカード
      @weapon_cards = wcs                        # 現在の所持武器カード
      @equip_cards = qcs                         # 現在の所持装備カード
      @event_card_draw_num = EVENT_CARD_DRAW_NUM # イベントカードを引く枚数

      @hit_points = []                           # 現在のヒットポイント
      @hit_points_max = []                       # 最大のヒットポイント

      @trap = { }                                # トラップ
      @table_cards_lock = false                  # テーブルカードを開示しない

      @sword_ap = []                             # 近ボーナス
      @sword_dice_bonus = []                     # 近ダイスボーナス
      @sword_dp = []                             # 近防御ボーナス
      @sword_deffence_dice_bonus = []            # 近ダイス防御ボーナス

      @arrow_ap = []                             # 遠ボーナス
      @arrow_dice_bonus = []                     # 遠ダイスボーナス
      @arrow_dp = []                             # 遠防御ボーナス
      @arrow_deffence_dice_bonus = []            # 遠ダイス防御ボーナス
      @magnification_hurt_const_damage = 1       # 自身が受ける固定値ダメージの倍率
      @magnification_cause_const_damage = 1      # 自身が与える固定値ダメージの倍率

      @determined_damage = 0                     # ダメージイベントで確定したダメージ

      @weapon_passives = []                      # 武器がもつパッシブスキル
      @special_gem_bonus_multi = 1                     # 戦闘時特殊行動によるgemボーナス
      @default_weapon_bonus = { }                # 初期の武器ステータスを保持する

      @chara_cards.each_index do |s|
        if @chara_cards[s]                       # 念のためのチェック

		  # By_K2 START (무한의탑 몬스터인 경우 층수만큼 POWER 증가)
		  @chara_cards[s].hp += hp_up;
		  @chara_cards[s].ap += ap_up;
		  @chara_cards[s].dp += dp_up;
		  # By_K2 END

          @hit_points << (@chara_cards[s].hp - (d_set[s] ? d_set[s]:0))         # 現在のヒットポイントを格納
          @hit_points_max << @chara_cards[s].hp                                 # 最大のヒットポイントを格納

          if @weapon_cards[s]
            @sword_ap[s] = 0                                                    # 近ボーナス
            @weapon_cards[s].each { |w| @sword_ap[s] += w.sword_ap(ai) }
            @sword_dice_bonus[s] = 0                                            # 近ダイスボーナス
            @weapon_cards[s].each { |w| @sword_dice_bonus[s] += w.sword_dice_bonus(ai) }
            @sword_dp[s] = 0                                                    # 近防御ボーナス
            @weapon_cards[s].each { |w| @sword_dp[s] += w.sword_dp(ai) }
            @sword_deffence_dice_bonus[s] = 0                                   # 近ダイス防御ボーナス
            @weapon_cards[s].each { |w| @sword_deffence_dice_bonus[s] += w.sword_deffence_dice_bonus(ai) }

            @arrow_ap[s] = 0                                                    # 遠ボーナス
            @weapon_cards[s].each { |w| @arrow_ap[s] += w.arrow_ap(ai) }
            @arrow_dice_bonus[s] = 0                                            # 遠ダイスボーナス
            @weapon_cards[s].each { |w| @arrow_dice_bonus[s] += w.arrow_dice_bonus(ai) }
            @arrow_dp[s] = 0                                                    # 遠防御ボーナス
            @weapon_cards[s].each { |w| @arrow_dp[s] += w.arrow_dp(ai) }
            @arrow_deffence_dice_bonus[s] = 0                                   # 遠ダイス防御ボーナス
            @weapon_cards[s].each { |w| @arrow_deffence_dice_bonus[s] += w.arrow_deffence_dice_bonus(ai) }

            @weapon_cards[s].each { |w|
              @weapon_passives[s] = w.get_passive_id(ai) }
            @chara_cards[s].weapon_passive=(@weapon_passives[s])
          end
          @default_weapon_bonus[s] = weapon_bonus(s)
        end
      end

      @field_status = [] # [power, turn]
      FIELD_STATUS.each_key { |key|
        @field_status << [1, 0]
      }

      @current_chara_card_no = 0     # 現在使用中のキャラカード番号

      @direction = DIRECTION_STAY    # 現在の移動方向
      @move_point = 0                # 現在の移動ポイント

      @start_ok = false              # クライアントの準備はOKか？
      @init_done = false             # イニシアチブ決定
      @move_done = false             # 移動決定
      @distance = dist               # 現在の相手との距離
      @dead     = false              # 生存フラグ

      @table = []                    # フェイズに出したカード
      @attack_done = false           # 攻撃決定
      @deffence_done = false         # 防御決定
      @change_done = true            # キャラ変更決定
      @change_need = false           # キャラ変更が必要か？
      @tmp_power = 0                 # 現在の合計ダイス力
      @tmp_focus = 0                 # 現在のダメージ補正値
      @instant_kill_damage = 0       # 即死技・割合ダメージを受けた際のダメージ量(割合ダメージは本数値から割り引いたダメージとする)
      @is_indomitable = false        # Ex不屈状態
      @is_transforming = false       # 変身状態
      @is_highgate = false           # かばう状態
      @indomitable_dice_damage = 0   # 不屈よりプライオリティの低い攻撃技で、不屈を通ったダイスダメージを保存する。
      @const_damage_guard = false    # 直接ダメージを防ぐ
      @invincible = false            # 直接ダメージとダイスダメージを防ぐ
      @initiative = false            # イニシアチブを取ったか
      @transformable = false         # 死ぬと変身する。(キャラカード差し替え)
      @exit = false                  # ゲームから出たか？
      @bp_calc_unenabled             # 攻撃失敗
      @bp_calc_range_free=false      # 距離を廃したbp計算
      @seconds=false                 # 必ず後攻
      @hiding_was_finished=false     # ハイド終了
      @before_damage=0               # 直前に受けたダメージ
      @damaged_times=0               # ダメージを受けた回数
      @locked_cards_id = []             # 手札内でロックされたカード
      @monitoring = false            # ヒール, 自傷を相手にも適用

      @table_on_list = 0b0    # 戦闘テーブルにおかれたもの有効になっているアクションカードのビット配列
      # 必殺技使用時に有効になってるかどうかを表すビット配列を格納するハッシュ
      @feat_battle_table_on_list = { }
      # 結果もらえるEXP
      @result_exp = 0
      @result_gems = 0

      @base_exp = 0      # 計算前の経験値
      @exp_bonus = 0     # EXPボーナス

      # 経験値の倍率
      @exp_pow  =1

      # ボーナス値による倍率変化
      @exp_bounus_pow  =1
      @gem_bounus_pow  =1
      # 受け取ったボーナスの合計
      @reward_bonus = 0

    end

    def set_foe(f)
      @foe =f
    end

    # 現在のカードの不足分
    def cards_lack_num
      ret = @cards_max - @cards.size
      ret = 0 if ret < 0
      ret
    end

    # デッキ内のキャラカード
    def chara_cards
      @chara_cards
    end

    # 使用中のキャラカード
    def current_chara_card
      @chara_cards[@current_chara_card_no]
    end

    # 使用中のキャラカード番号
    def current_chara_card_no
      @current_chara_card_no
    end

    # 使用中のキャラカードの現在ヒットポイント
    def current_hit_point
      @hit_points[@current_chara_card_no]
    end

    # 使用中のキャラカードの現在ヒットポイント
    def hit_point
      current_hit_point
    end

    # 使用中のキャラカードの現在ヒットポイント
    def current_hit_point=(point)
      @hit_points[@current_chara_card_no] = point
    end

    # 使用中のキャラカードの最大ヒットポイント
    def current_hit_point_max
      @hit_points_max[@current_chara_card_no]
    end

    # indexの装備補正を取得
    def weapon_bonus(i)
      ret = []
      if @weapon_cards[i]
        ret << [@sword_ap[i],@sword_dice_bonus[i],@sword_dp[i],@sword_deffence_dice_bonus[i],
                @arrow_ap[i],@arrow_dice_bonus[i],@arrow_dp[i],@arrow_deffence_dice_bonus[i],
                weapon_passives_str(i)]
      else
        ret << [0, 0, 0, 0, 0, 0, 0, 0, weapon_passives_str(i)]
      end
      ret
    end

    # 武器ステータスを加算する
    def add_current_weapon_bonus(b)
      wb = b[0]
      @sword_ap[@current_chara_card_no] += adjust_weapon_status(@sword_ap[@current_chara_card_no], wb[0])
      @sword_dice_bonus[@current_chara_card_no] += adjust_weapon_status(@sword_dice_bonus[@current_chara_card_no], wb[1])
      @sword_dp[@current_chara_card_no] += adjust_weapon_status(@sword_dp[@current_chara_card_no], wb[2])
      @sword_deffence_dice_bonus[@current_chara_card_no] += adjust_weapon_status(@sword_deffence_dice_bonus[@current_chara_card_no], wb[3])
      @arrow_ap[@current_chara_card_no] += adjust_weapon_status(@arrow_ap[@current_chara_card_no], wb[4])
      @arrow_dice_bonus[@current_chara_card_no] += adjust_weapon_status(@arrow_dice_bonus[@current_chara_card_no], wb[5])
      @arrow_dp[@current_chara_card_no] += adjust_weapon_status(@arrow_dp[@current_chara_card_no], wb[6])
      @arrow_deffence_dice_bonus[@current_chara_card_no] += adjust_weapon_status(@arrow_deffence_dice_bonus[@current_chara_card_no], wb[7])
    end

    # 武器ステの上限下限を超えない加算値に補正する
    def adjust_weapon_status(a, b)
      ret = b
      pt = a + b
      if pt > 9
        ret = 0
      elsif pt < -9
        ret = -9 - a
      end

      ret
    end

    # 武器ステータスを再設定
    def reset_current_weapon_bonus()
      @sword_ap[@current_chara_card_no],
      @sword_dice_bonus[@current_chara_card_no],
      @sword_dp[@current_chara_card_no],
      @sword_deffence_dice_bonus[@current_chara_card_no],
      @arrow_ap[@current_chara_card_no],
      @arrow_dice_bonus[@current_chara_card_no],
      @arrow_dp[@current_chara_card_no],
      @arrow_deffence_dice_bonus[@current_chara_card_no] = [0,0,0,0,0,0,0,0]
      @weapon_cards[@current_chara_card_no] = nil
    end

    def reset_current_default_weapon_bonus()
      @default_weapon_bonus[@current_chara_card_no][0][0,7] = [0,0,0,0,0,0,0,0]
    end

    def set_current_default_weapon_bonus()
      @sword_ap[@current_chara_card_no],
      @sword_dice_bonus[@current_chara_card_no],
      @sword_dp[@current_chara_card_no],
      @sword_deffence_dice_bonus[@current_chara_card_no],
      @arrow_ap[@current_chara_card_no],
      @arrow_dice_bonus[@current_chara_card_no],
      @arrow_dp[@current_chara_card_no],
      @arrow_deffence_dice_bonus[@current_chara_card_no] = @default_weapon_bonus[@current_chara_card_no][0]
    end

    # 有値の武器を持ってるか
    def has_weapon_status()
      ret = false
      unless @weapon_cards[@current_chara_card_no].blank?
        if @sword_ap[@current_chara_card_no] != 0 ||
            @sword_dp[@current_chara_card_no] != 0 ||
            @arrow_ap[@current_chara_card_no] != 0 ||
            @arrow_dp[@current_chara_card_no] != 0
          ret = true
        end
      end
      ret
    end

    # なんらかの武器を持ってるか
    def has_weapon()
      @weapon_cards[@current_chara_card_no].blank? ? false : true
    end

    # 武器の所持がない場合に、あるように見せかける
    def set_dummy_weapon()
      @weapon_cards[@current_chara_card_no] = ["dummy_weapon"] if @weapon_cards[@current_chara_card_no].blank?
    end

    # 使用中の装備補正を返す
    def current_weapon_bonus
      ret = []
      ret = weapon_bonus(@current_chara_card_no)
      ret
    end

    # 使用中のキャラの初期化直後の装備補正を返す
    def current_default_weapon_bonus
     @default_weapon_bonus[@current_chara_card_no]
    end


    # 使用中の装備補正の各要素を返す
    def current_weapon_bonus_at(p)
      current_weapon_bonus[0][p]
    end

    # すべてカードの装備補正を返す
    def weapon_bonuses
      ret = []
      @weapon_cards.each_index do |i|
        ret << weapon_bonus(i)
      end
      ret
    end

    # indexの武器パッシブを取得
    def weapon_passives(i)
      @weapon_passives[i]
    end

    # indexの武器パッシブを連結文字列で取得
    def weapon_passives_str(i)
      ret = ""
      ret = @weapon_passives[i].join('|') if @weapon_passives[i]
      ret
    end

    # 使用中の武器パッシブ
    def current_weapon_passive
      @weapon_passives[@current_chara_card_no]
    end

    # 正体不明を含むすべてのカードの装備補正を返す
    def unknown_weapon_bonuses
      ret = []
      @weapon_cards.each_index do |i|
        if i == @current_chara_card_no
          ret << weapon_bonus(i)
        else
          ret << [0, 0, 0, 0, 0, 0, 0, 0, 0]
        end
      end
      ret
    end

    # キャラカードのヒットポイントの合計
    def total_hit_point
      ret = 0
      @hit_points.each { |h| ret += h }
      ret
    end

    def damage_set
      ret = []
      @hit_points_max.each_index{ |h|
        ret << @hit_points_max[h]-((@hit_points[h]<1)? 1:@hit_points[h])
      }
      ret
    end

    def remain_hp_set
      ret = []
      @hit_points_max.each_index{ |h|
        ret << ((@hit_points[h]<1)? 0:@hit_points[h])
      }
      ret
    end

    # 使用中のキャラカードを指定されたキャラカードIDをもとに更新する。
    def change_current_chara_card(ccId)
      @chara_cards[@current_chara_card_no] = Unlight::CharaCard[ccId]
      @hit_points[@current_chara_card_no] = @chara_cards[@current_chara_card_no].hp
      @hit_points_max[@current_chara_card_no] = @chara_cards[@current_chara_card_no].hp
    end

    def field_status
      @field_status
    end

    # ================================
    # 参加者のアクション
    # ================================

    # 移動方向を設定する
    # 返値:移動方向
    def set_direction(dir)
      if current_chara_card.forbidden_direction?(dir)
        @direction = DIRECTION_PEND
      else
        @direction = dir
      end
    end
    regist_event SetDirectionAction

    # 移動カードのＩＤを受け取ってテーブルにのっける
    # 返値:出したカードのインデックス
    def move_card_add(cards, dir, index=0 )
      return false unless card_is_enabled?(cards[0])
      # 臨時にカードがカースカードなら無視
      return 0 if MOVE_RULE_EVENT_CARD_NO.include?(ActionCard[cards[0]].event_no)
      # 方向が決定していない場合失敗する
      if direction_set?
      # 移動カードテーブルにカードを移動する
        if card_replace(cards, @cards, @table)
          # 移動ができていたらイベントを発行する
          cards.each_index { |i| move_card_rotate(cards[i], dir[i])}
          move_card_add_succes_event(index, cards[0])
          # カードにテーブルにおかれたことを知らせる
          @table.each{ |c| c.droped_event if cards.include?(c.id) }
          point_check(POINT_CHECK_MOVE)
        else
          move_card_add_succes_event(-1,0)
        end
      else
          move_card_add_succes_event(-1,0)
      end
      index
    end
    regist_event MoveCardAddAction

    # 移動カードのＩＤを受け取ってテーブルから除いて手札に戻す
    # 返値:戻したカードのインデックス
    def move_card_remove(cards, index=0)
      if card_replace(cards, @table, @cards)
        point_check(POINT_CHECK_MOVE)
        [index, cards[0]]
      else
        [-1,0]
      end
    end
    regist_event MoveCardRemoveAction

    # 戦闘カードのＩＤを受け取ってテーブルにのっける（方向付き）
    # 返値:出したカードのインデックス
    def battle_card_add(cards, dir, index=0)
      # 無視するカード
      return false unless card_is_enabled?(cards[0])
      return 0 if BATTLE_RULE_EVENT_CARD_NO.include?(ActionCard[cards[0]].event_no)
      if card_replace(cards, @cards, @table)
        cards.each_index { |i| battle_card_rotate(cards[i], dir[i])}
        # 移動ができていたらイベントを発行する
        battle_card_add_succes_event(index, cards[0])
        # カードにテーブルにおかれたことを知らせる
        @table.each{ |c| c.droped_event if cards.include?(c.id) }
        # ポイントに変化があったか再計算
        point_check(POINT_CHECK_BATTLE)
      else
          battle_card_add_succes_event(-1,0)
      end
      index
    end
    regist_event AttackCardAddAction
    regist_event DeffenceCardAddAction


    # 攻撃カードのＩＤを受け取ってテーブルから除いて手札に戻す
    # 返値:戻したカードのインデックス
    def battle_card_remove(cards, index=0)
      if card_replace(cards, @table, @cards)
      # ポイントに変化があったか再計算
        point_check(POINT_CHECK_BATTLE)
        [index, cards[0]]
      else
        [-1,0]
      end
    end
    regist_event AttackCardRemoveAction
    regist_event DeffenceCardRemoveAction

    # 攻撃カードを回転させる
    def battle_card_rotate (id, dir)
      @table.each do |c|
        if c.id == id
          c.up(dir)
          # ポイントに変化があったか再計算
          point_check(POINT_CHECK_BATTLE)
        end
      end
    end
    regist_event AttackCardRotateAction
    regist_event DeffenceCardRotateAction

    # カード回転させる。チェックはしない。
    def battle_card_rotate_silence (id, dir)
      @table.each do |c|
        if c.id == id
          c.up(dir)
        end
      end
    end

    # 移動カードを回転させる
    def move_card_rotate (id, dir)
      @table.each do |c|
        if c.id == id
          c.up(dir)
          point_check(POINT_CHECK_MOVE)
        end
      end
    end
    regist_event MoveCardRotateAction

    # カードを回転させる
    # 返値:戻したカードのテーブル位置とインデックスとIDの配列
    def card_rotate (id, table, index, dir)
      return false unless card_is_enabled?(id)
      case table
      when TABLE_HAND
        @cards.each { |c| c.up(dir) if c.id == id}
      when TABLE_MOVE
        move_card_rotate_action(id, dir)
      when TABLE_BATTLE
        if initiative?
          attack_card_rotate_action(id, dir)
        else
          deffence_card_rotate_action(id, dir)
        end
      end
      [table,index,id,dir]
    end
    regist_event CardRotateAction
    regist_event EventCardRotateAction

    def card_is_enabled?(id)
      !@locked_cards_id.include?(id)
    end

    def get_locked_cards_id
      @locked_cards_id
    end

    def card_lock(id)
      @locked_cards_id << id unless @locked_cards_id.include?(id)
      id
    end
    regist_event CardLockEvent

    def clear_card_locks
      ret = @locked_cards_id.size > 0 ? true : false
      @locked_cards_id = []
      ret
    end
    regist_event ClearCardLocksEvent

    # カードをテーブルに出す
    # 返値:出し終わったテーブル
    def add_table(cards, table)
      card_replace(cards, @cards, table)
      table.each{ |c| c.droped_event if cards.include?(c.id) }
      table
    end
    regist_event AddTableAction

    # 移動（正でで離れる。負で近づく）
    # 返値:新しい距離
    def move(i)
      i = 0 if current_chara_card.is_magnetic? || @foe.current_chara_card.is_magnetic?

      if @direction == DIRECTION_CHARA_CHANGE && @hit_points.select{|v| v > 0}.size > 1
        @change_done = false
        @change_need = true
      elsif @direction == DIRECTION_STAY
        self.healed_event(1);
      end
      mp = (i.abs < DISTANCE_MAX)? i.abs : DISTANCE_MAX
      mp *= i<=>0
      old_distance = @distance
      @distance += mp
      if @distance <= 0
        @distance = 1
      elsif @distance >DISTANCE_MAX
        @distance = DISTANCE_MAX
      end
      move_done
      @move_point = old_distance - @distance

      ret = 0

      if (@field_status[FIELD_STATUS["FOG"]][1] == 0 && @foe.field_status[FIELD_STATUS["FOG"]][1] == 0) ||
          hiding_was_finished || foe.hiding_was_finished
        ret = @distance
      elsif current_chara_card.hiding?
        hide_move_action(@distance)
      end
      ret
    end
    regist_event MoveAction

    # ハイド状態下での移動
    def hide_move(i)
      i
    end
    regist_event HideMoveAction

    # キャラカード変更
    # 返値:新しいキャラカードインデックス
    def chara_change(i = nil)
      SERVER_LOG.info("ENTARANT: CHARA_CHANEGE #{@current_chara_card_no}, #{i}")

      @chara_change_force = true if @transformable
      # 強制キャラチェンジかどうかを調べる1
      i = @chara_change_index if @chara_change_index && i == @current_chara_card_no
      # 強制キャラチェンジかどうかを調べる2
      i = @chara_change_index if @chara_change_force
      # 値がない場合に仮カードを代入
      i = @hit_points.index{|v| v > 0} if i == nil

      if !@change_done && @chara_cards[i] && @hit_points[i] > 0
        # イベントを外してすぐに登録すると2重にイベントが登録されてしまうみたい
        if i != @current_chara_card_no || @transformable
          current_chara_card.remove_event    # イベントを削除
          @current_chara_card_no = i         # 新しいキャラカードの番号に適応
          current_chara_card.init_event      # イベントとフックを登録
        end
        change_done
      end
      @chara_change_index = nil
      @chara_change_force = nil
      @is_transforming = false
      @table_cards_lock = false
      @monitoring = false
      [@current_chara_card_no, current_chara_card.id, current_weapon_bonus]
    end
    regist_event CharaChangeAction

    # ゲームの準備完了
    def start_ok
      @start_ok = true
    end

    # イニシアチフェイズの完了
    def init_done
      @init_done = true
      # 必殺技のONリストをすべて初期化する
      @feat_battle_table_on_list = { }
    end
    regist_event InitDoneAction

    # 移動フェイズの完了
    def move_done
      @move_done = true
      # 必殺技のONリストをすべて初期化する
      @feat_battle_table_on_list = { }
    end
    regist_event MoveDoneAction

    # 戦闘フェイズの完了
    def attack_done
      @attack_done = true
      # 必殺技のONリストをすべて初期化する
      @feat_battle_table_on_list = { }
    end
    regist_event AttackDoneAction

   # 戦闘フェイズの完了
    def deffence_done
      @deffence_done = true
      # 必殺技のONリストをすべて初期化する
      @feat_battle_table_on_list = { }
    end
    regist_event DeffenceDoneAction

   # キャラチェンジフェイズの完了
    def change_done
      @change_done = true
      # 必殺技のONリストをすべて初期化する
      @feat_battle_table_on_list = { }
    end
    regist_event ChangeDoneAction

    # ================================
    # 参加者のイベント
    # ================================

    # 移動カードが実際にテーブルにおかれた場合のイベント
    def move_card_add_succes(index, id)
      [index, id]
    end
    regist_event MoveCardAddSuccesEvent

    # 戦闘カードが実際にテーブルにおかれた場合のイベント
    # 返値:出したカードのインデックス
    def battle_card_add_succes(index, id)
      [index, id]
    end
    regist_event BattleCardAddSuccesEvent

    # ダメージ
    # 返値:ダメージポイント
    def damaged (d,is_not_hostile=false,set_log=true)
      val = d
      if @hit_points[@current_chara_card_no] > 0
        @foe.damaged_event(d) if @monitoring && is_not_hostile
        if (@hit_points[@current_chara_card_no] - val) < 1
          val = @hit_points[@current_chara_card_no]    # 現在のヒットポイント
          # 死んだら一度移動終了ボタンを推したことにする
          init_done_action
          @hit_points[@current_chara_card_no] = 0
          # 生存キャラがある場合にキャラ変更フェイズのフラグを立てる
          if @hit_points.index{|v| v > 0}
            @change_done = false
            @change_need = true
            self.cards_max = self.cards_max + 1
          else
            @dead = true
          end
        else
          @hit_points[@current_chara_card_no] -= val
        end
      else
        val = 0
      end
      unless is_not_hostile
        determine_damage_event(val)
        if val > 0
          @before_damage = val
          @damaged_times += 1
        end
      end
      [val,is_not_hostile,set_log]
    end
    regist_event DamagedEvent

    def determine_damage(d)
      @determined_damage = d
    end
    regist_event DetermineDamageEvent

    # 復活
    def revive(idx, rhp)
      if @hit_points[idx] < 1
        @hit_points[idx] = rhp
      end
      [idx, rhp]
    end
    regist_event ReviveEvent

    # 移動フェイズの行動を幾つか封じる
    def constraint(flag)
      flag
    end
    regist_event ConstraintEvent

    # # カードステータスを刷新する
    # def renovate_card_status(idx, kind, value)
    #   [idx, kind, value]
    # end
    # regist_event RenovateCardStatusEvent

    # レイドボス戦時にダメージをログに保存
    # 返り値：ダメージ
    def set_damage_log(d)
      d
    end
    regist_event SetDamageLogEvent

    # 指定したカードにダメージを与える
    # 返値:カード位置,ダメージポイント
    def party_damaged(idx, d, is_not_hostile=false, set_log=true)
      val = 0
      if @hit_points[idx] > 0
        if (@hit_points[idx] - d) < 1
          val = @hit_points[idx]  # 受けるダメージ
          @hit_points[idx] = 0
          # 生存キャラがある場合にキャラ変更フェイズのフラグを立てる
          if idx == @current_chara_card_no && @hit_points.index{|v| v > 0}
            @change_done = false
            @change_need = true
            self.cards_max = self.cards_max + 1
          elsif @hit_points.index{|v| v > 0}
            self.cards_max = self.cards_max + 1
          else
            @dead = true
          end
        else
          val = d
          @hit_points[idx] -= d
        end
      end
      unless is_not_hostile
        determine_damage_event(val)
        if val > 0
          @before_damage = val
          @damaged_times += 1
        end
      end
      [idx ,val, is_not_hostile, set_log]
    end
    regist_event PartyDamagedEvent

    # 回復
    # 返値:回復ポイント
    def healed (d,set_log=true)
      return [0,set_log] if is_dark?(@current_chara_card_no) # 回復禁止状態をチェックする

      ret = d
      if @hit_points[@current_chara_card_no] > 0 || @transformable
        if (@hit_points[@current_chara_card_no] + d) > current_hit_point_max
          ret = current_hit_point_max - @hit_points[@current_chara_card_no]  # 回復するヒットポイント
          @hit_points[@current_chara_card_no] = current_hit_point_max
        else
          @hit_points[@current_chara_card_no] += d
        end
      else
        ret = 0
      end
      [ret,set_log]
    end
    regist_event HealedEvent

    def is_dark?(idx)
      chara_cards[idx].is_dark?
    end

    # キャラクターのHPを、こそっと変更する
    # HPを変動させたいが、エフェクトは出したくないという特殊な場合用
    def hit_point_changed(pt,set_log=true)
      set_hp = pt > current_hit_point_max ? current_hit_point_max : pt
      @hit_points[@current_chara_card_no] = set_hp
      ret = set_hp
      [ret,set_log]
    end
    regist_event HitPointChangedEvent

    # 指定した位置のカードのHPを回復
    # 返値:カード位置,回復ポイント
    def party_healed (idx, d,set_log=true)
      return [idx, 0, set_log] if is_dark?(idx) # 回復禁止状態をチェックする

      val = 0
      if @hit_points[idx] > 0
        if (@hit_points[idx] + d) > @hit_points_max[idx]
          val = @hit_points_max[idx] - @hit_points[idx]  # 回復するヒットポイント
          @hit_points[idx] = @hit_points_max[idx]
        else
          val = d
          @hit_points[idx] += d
        end
      else
        val = 0
      end
      [idx ,val, set_log]
    end
    regist_event PartyHealedEvent

    # 全ての状態を回復
    # 返値:回復ポイント
    def cured ()
      current_chara_card.cure_status()
    end
    regist_event CuredEvent

    # 全ての必殺技を解除
    # 返値:Boolean
    def sealed ()
      current_chara_card.reset_feats()
      current_chara_card.off_feat_all()
    end
    regist_event SealedEvent

    # カードが配られる
    # 返値:配られたカードの配列
    def dealed(card)
      @cards << card # unless @cards.index{ |d| d.id == card.id}
      card.dealed_event(self) if card
      card
    end
    regist_event DealedEvent

    # イベントカードが使用される（その場で捨てられる）
    # 返値:使用されたアクションカードのid
    def use_action_card(ac)
      bi = @table.index{|a| a.id == ac.id }
      @table.delete_at(bi) if bi
      mi = @table.index{|a| a.id == ac.id }
      @table.delete_at(mi) if mi
      if mi||bi
        ac.throw
      end
      ac.id
    end
    regist_event UseActionCardEvent

    # 手札の強制破棄
    # 返値：捨てられたアクションカードのID
    def discard(ac)
      ret = 0
      # カードが手札に存在するかを調べる
      i = @cards.index{|a| a.id == ac.id }
      # 存在したらそのインデックスを捨てる
      if i
        @cards.delete_at(i)
        ac.throw
        ret = ac.id
      end
      ret
    end
    regist_event DiscardEvent

    # ドロップカードの強制破棄
    # 返値：捨てられたアクションカードのID
    def discard_table(ac)
      ret = 0
      # カードがテーブルに存在するかを調べる
      i = @table.index{|a| a.id == ac.id }
      # 存在したらそのインデックスを捨てる
      if i
        @table.delete_at(i)
        ac.throw
        ret = ac.id
      end
      ret
    end
    regist_event DiscardTableEvent

    # 現在のポイントがアップデートされた
    def point_update
      self.tmp_power
    end
    regist_event PointUpdateEvent

    # 現在のポイントが上書きされた
    # calc_resolv after で最後に更新される値は画面に反映されない
    # 反映するべき場合はこれを用いる。updateのスリム版
    def point_rewrite
      self.tmp_power
    end
    regist_event PointRewriteEvent

    # カードが特別に配られる
    def special_dealed(cards)
      cards
    end
    regist_event SpecialDealedEvent

    # 墓場からカードが配られる
    def grave_dealed(cards)
      cards.each { |c| dealed_event(c)}
      cards
    end
    regist_event GraveDealedEvent
    regist_event StealDealedEvent

    # 装備カードのボーナスを更新
    def update_weapon
      [weapon_bonuses, @foe.unknown_weapon_bonuses]
    end
    regist_event UpdateWeaponEvent

    # イベントカードが特別に配られる
    def special_event_card_dealed(cards)
      cards
    end
    regist_event SpecialEventCardDealedEvent

    # カードの数値が変更される
    def update_card_value(card, reset=false)
      [card.id, card.u_value, card.b_value, reset]
    end
    regist_event UpdateCardValueEvent

    # 偽のダイスを振るイベントを送る
    def dice_roll(dice)
      dice
    end
    regist_event DiceRollEvent

    # 戦闘フェイズ終了時の初期化
    def battle_phase_init
      @table.each{ |c| c.throw}
      @table.clear
      @attack_done = false
      @deffence_done = false
      @bp_calc_unenabled = false
    end
    regist_event BattlePhaseInitEvent

    # 最大カード所持数が更新された
    def cards_max_update
      self.cards_max
    end
    regist_event CardsMaxUpdateEvent

    # デュエルボーナスが発生した
    def duel_bonus(type, pow)
      @reward_bonus += pow
      [type, pow]
    end
    regist_event DuelBonusEvent

    # 特殊メッセージ
    def special_message(mess, arg=nil)
      ret = SPECIAL_MESSAGE_SET[mess]
      ret = ret.gsub("__DAMAGE__",arg.to_s) if arg
      ret
    end
    regist_event SpecialMessageEvent

    # 汎用メッセージ
    def duel_message(mess, arg=nil)
      [mess, arg]
    end
    regist_event DuelMessageEvent

    def attribute_regist_message(mess)
      ATTRIBUTE_REGIST_MESSAGE_SET[mess]
    end
    regist_event AttributeRegistMessageEvent

    # 現在ターン数を変更する
    def set_turn(turn)
      turn
    end
    regist_event SetTurnEvent

    # 移動点に対するフック処理用(単純加算以外)
    def alter_mp
    end
    regist_event AlterMpEvent

    # 移動点の最速評価用
    def mp_evaluation
    end
    regist_event MpEvaluationEvent

    # ================================
    # 計算関数
    # ================================

    # 現在の攻撃ポイント
    def attack_point
      current_chara_card.ap
    end

    # 現在の防御ポイント
    def deffence_point
      current_chara_card.dp
    end

    # 攻撃ポイントの計算
    def bp_calc
      if bp_calc_range_free
        sap = battle_point_calc(ActionCard::SWD, attack_point)
        aap = battle_point_calc(ActionCard::ARW, attack_point)
        self.tmp_power = aap > sap ? aap : sap
      else
        self.tmp_power = battle_point_calc(attack_type, attack_point)
      end
    end
    regist_event BpCalcResolve

    # 防御ポイントの計算
    def dp_calc
      self.tmp_power = battle_point_calc(ActionCard::DEF, deffence_point)
    end
    regist_event DpCalcResolve

    # 移動ポイントの計算
    def mp_calc
      # テーブルカードの移動値を合算する
      self.tmp_power = get_move_table_point
    end
    regist_event MpCalcResolve


    # ================================
    # 判定関数
    # ================================
    # クライアントの準備はOKか
    def start_ok?
      @start_ok
    end

    # 移動方向が決定されているか？
    def direction_set?
      true
    end
    # イニシアチブフェイズが終わったか？
    def init_done?
      @init_done
    end

    # 移動フェイズが終わったか？
    def move_done?
      @move_done
    end

    # 戦闘のフェイズが終わったか？
    def deffence_done?
      @deffence_done
    end

    # 戦闘のフェイズが終わったか？
    def untill_deffence_done?
      !@deffence_done
    end

    # 戦闘のフェイズが終わったか？
    def attack_done?
      @attack_done
    end

    # 戦闘のフェイズが終わったか？
    def untill_attack_done?
      !@attack_done
    end

    # キャラの変更が終わったか？
    def change_done?
      @change_done
    end

    # キャラの変更の強制変更
    def change_done=(d)
      @change_done = d
    end

    # キャラの変更が終わったか？
    def not_change_done?
      !@change_done
    end

    # キャラチェンジが必要か？
    def change_need?
      @change_need
    end

    # キャラチェンジが必要か？
    def change_need=(b)
      @change_need = b
    end

    # 戦闘のフェイズが終わったか？
    def dead?
      total_hit_point < 1
    end

    # 戦闘のフェイズが終わったか？
    def live?
      total_hit_point > 0
    end

    # 戦闘のフェイズが終わったか？
    def current_dead?
      hit_point < 1
    end

    # 戦闘のフェイズが終わったか？
    def current_live?
      hit_point > 0
    end

    # イニシアチブをとっているのか？
    def initiative?
      @initiative
    end

    # イニシアチブをとっているのか？
    def not_initiative?
      !@initiative
    end

    # イニシアチブセット完了通知用
    def set_initiative
    end
    regist_event SetInitiativeEvent

    # 進行方向をゲット
    def get_direction
      case @direction
      when DIRECTION_PEND
        0
      when DIRECTION_FORWARD
        -1
      when DIRECTION_STAY
        0
      when DIRECTION_BACKWARD
        1
      when DIRECTION_CHARA_CHANGE
        0
      end
    end

    # ================================
    # ================================

    # ポイントがアップデートされた
    # 返値 現在のポイント
    def point_check(type = POINT_CHECK_BATTLE, update_skip = false)
      @table_on_list = 0
      if type == POINT_CHECK_BATTLE
        if initiative?
          bp_calc_resolve
        else
          dp_calc_resolve
        end
      else
        mp_calc
      end
      # 有効カードの内容、ポイント、テーブルのサイズが変わっていた場合にポイントをアップデートする
       if (@before_on_cards != self.current_on_card_value)||(@before_point != self.tmp_power)
         point_update_event unless update_skip
       end
      @before_on_cards = self.current_on_card_value unless update_skip
      @before_point = self.tmp_power
    end

    def point_check_silence(type = POINT_CHECK_BATTLE)
      @table_on_list = 0
      if type == POINT_CHECK_BATTLE
        if initiative?
          bp_calc_resolve
        else
          dp_calc_resolve
        end
      else
        mp_calc
      end
      # 有効カードの内容、ポイント、テーブルのサイズが変わっていた場合もポイントをアップデートしない
      @before_on_cards = self.current_on_card_value
      @before_point = self.tmp_power
    end

    def move_point_check

    end

    def move_point_abs
      @move_point.abs
    end

    def tmp_power=(pow)
      @tmp_power = pow
    end

    def tmp_power
      @tmp_power
    end

    def tmp_focus=(focus)
      @tmp_focus = focus
    end

    def tmp_focus
      @tmp_focus
    end

    def damage_pow=(pow)
      @damage_pow = pow
    end

    def damage_pow
      @damage_pow
    end

    def cards_max=(num)
      @cards_max = num
      cards_max_update_event
    end

    def cards_max
      @cards_max
    end

    def move_point=(point)
      @tmp_power = point
    end

    def invincible
      @invincible
    end

    def invincible=(flg)
      @invincible = flg
    end

    def const_damage_guard
      @const_damage_guard
    end

    def const_damage_guard=(flg)
      @const_damage_guard = flg
    end

    def table_cards_lock
      @table_cards_lock
    end

    def table_cards_lock=(flg)
      @table_cards_lock = flg
    end

    # 現在の移動ポイント
    def move_point
      self.tmp_power
    end

    # クライアントに表示する見かけの移動ポイント
    def move_point_appearance(mp)
      @field_status[FIELD_STATUS["FOG"]][1] > 0 ? 0 : mp
    end

    # クライアントに表示する見かけの現在距離
    def distance_appearance
      if @field_status[FIELD_STATUS["FOG"]][1] > 0 || @foe.field_status[FIELD_STATUS["FOG"]][1] > 0
        4
      else
        @distance
      end
    end

    # ポイントの計算
    def battle_point_calc(type, point)
      ret = 0
      # テーブルのったカードをタイプで集計
      ret += get_battle_table_point(type) unless @bp_calc_unenabled
      # テーブルのポイントが１以上ならばまたは0以下でもディフェンスの場合カードのポイントを加算
      if ret > 0 || (type == ActionCard::DEF)
        ret += point
        unless ignore_weapon_status
          if distance == 1
            if type != ActionCard::DEF
              ret += @sword_ap[@current_chara_card_no] if @sword_ap[@current_chara_card_no]
            else
              ret += @sword_dp[@current_chara_card_no] if @sword_dp[@current_chara_card_no]
            end
          else
            if type != ActionCard::DEF
              ret += @arrow_ap[@current_chara_card_no] if @arrow_ap[@current_chara_card_no]
            else
              ret += @arrow_dp[@current_chara_card_no] if @arrow_dp[@current_chara_card_no]
            end
          end
        end
        ret = 0 if ret < 0
      elsif ((ret < 1) && (type != ActionCard::DEF))
        ret = 0
      end
      ret
    end

    # 現在のフェイズ・距離における実質的な武器補正
    def get_effective_weapon_status()
      ret = 0

      return ret if ignore_weapon_status

      if distance == 1
        if self.initiative
          ret = @sword_ap[@current_chara_card_no] if @sword_ap[@current_chara_card_no]
        else
          ret = @sword_dp[@current_chara_card_no] if @sword_dp[@current_chara_card_no]
        end
      else
        if self.initiative
          ret = @arrow_ap[@current_chara_card_no] if @arrow_ap[@current_chara_card_no]
        else
          ret = @arrow_dp[@current_chara_card_no] if @arrow_dp[@current_chara_card_no]
        end
      end

      ret
    end

    # 武器補正を加えたくない場合
    def ignore_weapon_status
      self.bp_calc_range_free || @foe.bp_calc_range_free
    end

    # 計算の無効化
    def bp_calc_unenabled=(unenabled)
      @bp_calc_unenabled = unenabled
    end

    def bp_calc_unenabled?
      @bp_calc_unenabled
    end

    def move_phase_init
      @table.each{ |c| c.throw}
      @table.clear
      @init_done = false
      @move_done = false
      @direction = DIRECTION_PEND
    end
    regist_event MovePhaseInitEvent

    def change_phase_init
      @change_done = true
      @change_need = false
    end

    # テーブルにおいたカードからタイプで移動ポイントを換算する
    def get_move_table_point
      ret = 0
      counter = 0
      @table_on_list = 0
      @table.each do |a|
        tmp = a.move_point
        unless tmp==0
          @table_on_list = @table_on_list | (1 << counter)
          ret += tmp
        end
        counter +=1
      end
      get_move_table_focus_point
      ret
    end

    # テーブルに置いたカードからフォーカスポイントを換算する
    def get_move_table_focus_point
      self.tmp_focus = get_table_max_value(ActionCard::FCS)
      return self.tmp_focus if self.tmp_focus == 0

      counter = 0
      detected = false

      @table.each do |a|
        if a.u_type == ActionCard::FCS
          if a.u_value == self.tmp_focus
            @table_on_list = @table_on_list | (1 << counter)
            break
          end
        end
        counter +=1
      end
    end

    # テーブルにおいたカードからタイプで攻撃ポイントを換算する
    def get_battle_table_point(type)
      ret = 0
      counter = 0
      @table_on_list = 0
      @table.each do  |a|
        tmp = a.battle_point(type)
        if tmp > 0
          # ポイントとして換算したので有効ビットを立てる
          @table_on_list = @table_on_list | (1 << counter)
          ret += tmp
        end
        counter +=1
      end
      get_battle_table_focus_point(type)
      ret
    end

    # テーブルに置かれたカードタイプの配列を返す
    def get_table_card_types
      ret = []
      @table.each do |a|
        ret << (a.up? ? a.u_type : a.b_type)
      end

      ret.uniq
    end

    # 未実装
    def get_battle_table_focus_point(type)
      self.tmp_focus = 0
    end

    # テーブルに置いたカードのうち、該当タイプの枚数を返す
    def get_type_table_count(type)
      ret = 0
      @table.each do |a|
        tmp = a.battle_point(type)
        unless tmp == 0
            ret += 1
        end
       end
      ret
    end

    # テーブルにあるカードのうち、該当タイプの枚数を返す(両面見て判定)
    def get_type_table_count_both_faces(type)
      ret = 0
      @table.each do |a|
        ret += 1 if a.u_type == type || a.b_type == type
       end
      ret
    end

    # テーブルにあるカードのうち、タイプと数値の基準をクリアするカードの枚数を返す
    # typeを指定しない場合はActionCard::BLNK, equal=true の場合完全一致
    def get_type_point_table_count(type, point, equal=false)
      ret = 0

      if equal

        if type == 0
          @table.each do |a|
            ret += 1 if (a.up? && a.u_value == point) || (!a.up? && a.b_value == point)
          end
        else
          @table.each do |a|
            ret += 1 if (a.up? && a.u_type == type && a.u_value == point) || (!a.up? && a.b_type == type && a.b_value == point)
          end
        end

      else

        if type == 0
          @table.each do |a|
            ret += 1 if (a.up? && a.u_value >= point) || (!a.up? && a.b_value >= point)
          end
        else
          @table.each do |a|
            ret += 1 if (a.up? && a.u_type == type && a.u_value >= point) || (!a.up? && a.b_type == type && a.b_value >= point)
          end
        end

      end

      ret
    end

    # テーブルにあるカードのうちpoint以下のカードの枚数
    def get_type_point_below_table_count(type, point)
      ret = 0

      if type.nil?
        @table.each do |a|
          ret += 1 if (a.up? && a.u_value <= point) || (!a.up? && a.b_value <= point)
        end
      else
        @table.each do |a|
          ret += 1 if (a.up? && a.u_type == type && a.u_value <= point) || (!a.up? && a.b_type == type && a.b_value <= point)
        end
      end

      ret
    end

    # テーブルにあるカードのうち、タイプと数値が一致するカードの枚数を返す
    def get_equal_type_point_table_count(type, point)
      ret = 0

      ret
    end

    # 手札にあるカードのうち、該当タイプの枚数を返す(両面見て判定)
    def get_type_cards_count_both_faces(type)
      ret = 0
      @cards.each do |a|
        ret += 1 if a.u_type == type || a.b_type == type
       end
      ret
    end

    # 手札にあるカードのうち、該当タイプのポイントを返す(両面見て判定)
    def get_type_point_cards_both_faces(type)
      ret = 0
      @cards.each do |a|
        if  a.u_type == type
          ret += a.u_value
        elsif a.b_type == type
          ret += a.b_value
        end
       end
      ret
    end

    # テーブルに置いたカードのうち、両端の数値が双方numのカードの枚数を返す
    def get_same_number_both_sides_table_count(num)
      ret = [0, 0, 0]
      @table.each do |a|
        if a.u_value == num && a.b_value == num
          ret[0] += 1
          ret[1] += 1 if a.up? && a.u_type == ActionCard::MOVE || !a.up? && a.b_type == ActionCard::MOVE
          ret[2] += 1 if a.up? && a.u_type == ActionCard::SPC  || !a.up? && a.b_type == ActionCard::SPC
        end
      end
      ret
    end

    # テーブルに置いたカードのうち、該当タイプの最大値を返す
    def get_table_max_value(type)
      ret = 0
      @table.each do |a|
        ret = a.battle_point(type) if ret < a.battle_point(type)
      end
      ret
    end

    # テーブルに置いたカードのうち、タイプA、タイプBの最大同値を返す
    def get_table_max_value_same_arrow_sword(typeA, typeB)
      ret = 0
      swords = []
      @table.each do |a|
        swords << a.battle_point(typeA) if !swords.include?(a.battle_point(typeA))
      end
      @table.each do |a|
        ret = a.battle_point(typeB) if (swords.include?(a.battle_point(typeB)) && ret < a.battle_point(typeB))
      end
      ret
    end

    # タイプとポイントが一致するアクションカードが存在する？
    def search_check(feat_no, type, point, n = 1)
      ret  = false
      counter = 0
      num = 0
      @table.each do |a|
        if a.battle_point(type) == point
          # 有効ビットを立てる
          @feat_battle_table_on_list[feat_no] |= (1 << counter)
          num +=1
        end
        if num >= n
          ret =true
        end
        counter +=1
      end
      ret
    end

    # 提出されている該当タイプのカードの、数値のバリエーションを返す。
    def get_card_points_set(type)
      ret  = Array.new(9,false)
      @table.each do |a|
        ret[a.battle_point(type)-1] = true
      end
      ret
    end

    # 提出されている該当タイプのカードをイベントカードに分解する
    def convert_to_arrow(type)
      ret = []
      @table.each do |a|
        if a.up? && a.u_type == type || !a.up? && a.b_type == type

          u_value = a.up? ? a.u_value : a.b_value
          b_value = a.up? ? a.b_value : a.u_value
          b_type = a.up? ? a.b_type : a.u_type

          (u_value - b_value).times do
            ret << A1A1_EVENT_CARD_ID
          end

          if b_value > u_value
            (b_value - u_value).times do
              ret << S1S1_EVENT_CARD_ID if b_type == ActionCard::SWD
            end
            b_value = u_value
          end

          b_value.times do
            case b_type
            when ActionCard::DEF
              ret << A1D1_EVENT_CARD_ID
            when ActionCard::ARW
              ret << A1A1_EVENT_CARD_ID
            when ActionCard::SWD
              ret << A1S1_EVENT_CARD_ID
            when ActionCard::MOVE
              ret << A1M1_EVENT_CARD_ID
            when ActionCard::SPC
              ret << A1E1_EVENT_CARD_ID
            end
          end
        end
      end
      ret.sort!
    end

    # ポイントが一致するアクションカードが存在する？
    def search_check_wld_card(feat_no, point, n = 1)
      ret  = false
      counter = 0
      num = 0
      @table.each do |a|
        if a.check_exist_wld_card_value?(point)
          @feat_battle_table_on_list[feat_no] |= (1 << counter)
          num +=1
        end
        if num >= n
          ret =true
        end
        counter +=1
      end
      ret
    end

    # 特定タイプカードがポイント以上あるかしらべる
    def greater_check(feat_no,type, point)
      ret  = false
      counter = 0
      value = 0
      @table.each do |a|
        v = a.battle_point(type)
        if v > 0
          value += v
          @feat_battle_table_on_list[feat_no] |= (1 << counter)
        end
        if value >= point
          ret =true
        end
        counter += 1
      end
      ret
    end

    # 特定タイプカードがポイント以下であるかしらべる
    def below_check(feat_no,type, point)
      ret  = true
      counter = 0
      value = 0
      tmp_on_list = 0
      @table.each do |a|
        v = a.battle_point(type)
        if v > 0
          if value + v > point
            ret =false
          end
          value += v
          tmp_on_list |= (1 << counter)
        end
        counter += 1
      end
      if ret
        @feat_battle_table_on_list[feat_no] |= tmp_on_list
      else
        @feat_battle_table_on_list[feat_no] |= tmp_on_list
        @feat_battle_table_on_list[feat_no] ^= tmp_on_list
      end
      ret
    end

    # 特定タイプカードがポイント以上あるかしらべる(フラグ処理しない)
    def greater_check_of_type(type, point)
      ret  = false
      value = 0
      @table.each do |a|
        v = a.battle_point(type)
        value += v if v > 0
        if value >= point
          ret = true
          break
        end
      end
      ret
    end

    # 与えられたタイプの中で一定ポイント以上あるか調べる。
    # 与えられたタイプの中で最高値のタイプを調べる。
    # bp_calcと衝突しないよう、ビットを立てる処理は後ろに分離する。
    def greater_check_type_set(feat_no, typeSigns, point)
      max_value_type = []
      max_value_type = get_max_value_type(typeSigns, point)

      return max_value_type.size != 0
    end

    # on_listを書き換える 距離に対応するカードが意味を持たない場合
    def reset_on_list_by_type_set(feat_no, typeSigns, point, min=false)
      max_value_type = []
      max_value_type = get_max_value_type(typeSigns, point, min)

      return if max_value_type.size == 0

      @table_on_list = 0
      max_value_type.each do |t|
        on_card_by_type(feat_no, t)
      end
    end

    # 与えられたタイプの中で,基準値以上で最も数値の高いタイプの配列を返す
    # min=true の場合、数値の小さいものを選ぶ。
    # 基準値を満たさない場合空配列を返す。typeSignsはtypeの1文字版。S,SAD,EM,etc..
    def get_max_value_type(typeSigns, base_line, min=false)
      result_value_type = []
      value_list = []
      type_list = []

      sign_all = ["S", "A", "E", "D", "M"]
      type_all = [ActionCard::SWD, ActionCard::ARW, ActionCard::SPC, ActionCard::DEF, ActionCard::MOVE]

      total_value = 0
      typeSigns.each_char do |c|
        type = type_all[sign_all.index(c)]
        type_value = table_point_check(type)

        value_list << type_value
        type_list << type

        total_value += type_value
      end

      return [] if total_value < base_line

      result_value = 0
      if !min
        result_value =  value_list.max
      else
        result_value = base_line
        while  result_value <= value_list.max do
          if value_list.include?(result_value)
            break
          else
            result_value += 1
          end
        end
      end
      return [] if result_value == 0

      value_list.each_with_index do |v,i|
        if v == result_value
          result_value_type << type_list[i]
        end
      end

      return result_value_type
    end

    def get_feat_battle_table_on_list()
      @feat_battle_table_on_list
    end

    # 特定の技の有効カードフラグをクリアする
    def clear_feat_battle_table_on_list(feat_no)
      @feat_battle_table_on_list[feat_no] = 0
    end

    # ドロップテーブルにあるカードの枚数をしらべる
    def table_count
      @table.count
    end

    # 特定タイプカードがポイントをしらべる
    def table_point_check(type)
      ret = 0
      @table.each do |a|
        v = a.battle_point(type)
        if v > 0
          ret += v
        end
      end
      ret
    end

    # 特定タイプのカードを全てONにする
    def on_card_by_type(feat_no, type)
    counter = 0
      @table.each do |a|
        @feat_battle_table_on_list[feat_no] |= (1 << counter) if a.battle_point(type) > 0
        counter += 1
      end
    end

    # 現在のONになっているIDを送る
    def current_on_cards
      ids = []
      @table.each{ |c|ids << c.id }
      [ids.join(","),current_on_card_value]
    end

    def current_on_card_value
      ret = 0
      ret = ret | @table_on_list
      @feat_battle_table_on_list.each_value{ |v| ret|=v}
      ret
    end

    def reset_feat_on_cards(feat_id)
      @feat_battle_table_on_list[feat_id] = 0
    end

    # 指定した条件と一致するアクションカードを探す
    def search_move_table(point)
      ret = false
      @move_table.each do |a|
        ret = true if a.move_point == point
      end
      ret
    end

    def attack_type
      if distance == 1
        ActionCard::SWD
      else
        ActionCard::ARW
      end
    end

    def move_table
      @table
    end

    def battle_table
      @table
    end

    def battle_table=(array)
      @table = array
    end


    # カードをIDで指定して移動する
    # 移動が行われていればTrue
    def card_replace(cards,from,dst)
      ret = false
      cards.each do |a|
        ret = from.reject! do |b|
          (b.id == a) && (dst << b)
        end
      end
      dst.uniq!
      ret
    end
    private :card_replace

    def exit_game
      @exit = true
      remove_all_event_listener
      remove_all_hook
      SERVER_LOG.info("Entrant: [exit_game]");
    end

    # トラップ発動エフェクトをクライアントに表示させる
    def trap_action(kind,distance)
      [kind, distance]
    end
    regist_event TrapActionEvent

    # トラップ状態の進行をクライアントに通知する。
    def trap_update(kind, distance, turn, visible)
      [kind, distance, turn, visible]
    end
    regist_event TrapUpdateEvent

    # 攻撃属性の登録
    def dice_attribute_regist
      self.current_chara_card.regist_dice_attribute
    end
    regist_event DiceAttributeRegistEvent

    # フィールドの状態をセット
    def set_field_status(kind, pow, turn)
      @field_status[kind] = [pow, turn]
      [kind, pow, turn]
    end
    regist_event SetFieldStatusEvent

  end

  # 経験値を計算
  def update_exp(result)
    if result == RESULT_WIN
      @base_exp = @result_exp * 1 * @exp_pow
      @exp_bonus = DUEL_BONUS_POW * @reward_bonus
      (@base_exp + @exp_bonus).ceil
    elsif result == RESULT_LOSE
      @base_exp = (@result_exp * 0.3 * @exp_pow).round
      @exp_bonus = 0
      @base_exp.round
    elsif result == RESULT_DRAW
      @base_exp = (@result_exp * 0.5 * @exp_pow).round
      @exp_bonus = 0
      @base_exp.round
    end
  end


  # 獲得ジェムを計算
  def update_gems(result)
    if result == RESULT_WIN
      (@result_gems * 1*(0.4+dice(0.3,4)) * @special_gem_bonus_multi).ceil
    elsif result == RESULT_LOSE
      (@result_gems * 0.3*(0.4+dice(0.3,4)) * @special_gem_bonus_multi).truncate
    elsif result == RESULT_DRAW
       (@result_gems * 0.5*(0.4+dice(0.3,4)) * @special_gem_bonus_multi).round
    end
  end

  def dice(pow, num)
    ret = 0
    num.times { ret+=rand * pow }
    ret
  end

end
