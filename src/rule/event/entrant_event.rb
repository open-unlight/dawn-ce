# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

# イベント定義
# dsc:
#   説明文
#     "説明"
# context:*
#   実行可能な文脈 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
#     obj, event, ...
# guard:*
#   実行条件 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
#   ["reciver",:method],...<-配列すべてがTrueの時のみTrue
# goal:*
#   終了条件 （登録した条件の一つでも成功すれば成功）。指定なければ必ず終了。Hookの場合は逆に終了しない。
#   ["reciver",:method],...<-配列すべてがTrueの時のみTrue
# type:
#   関数はいつ実行されるのか
#   直ちに実行           type=>:instant < default
#   なにかの前に行われる type=>:before, :obj=>"reciver", :hook=>:method ,:priority =>0
#   なにかの後に行われ   type=>:after, :obj=>"reciver", :hook=>:method,:priority =>0
#   なにかを置き換える   type=>:proxy, :obj=>"reciver", :hook=>:method
#   (priorityは値の低い順に実行される。使用可能なのは整数のみ)
# duration:
#   終了しない場合どれくらい続くか？(Hook系のイベントには使用できない)
#   終わらない       :none <default
#   複数回           type=>:times, value=>x
#   秒               type=>:sec, value=>x
# event: (Hook系のイベントには使用できない)
#   イベントを発行するか？
#   実行前     :start
#   実行後     :finish
#   発行しない :< default
# func:
#   実行関数（hookする関数）
# act:
#   追加実行されるイベント
module Unlight
  # ===========================
  # アクション定義
  # ===========================

  class SetDirectionAction < EventRule
    dsc        "移動方向を設定する"
    context    ["MultiDuel", :move_card_drop_phase]
    guard      ["self",:current_live?]
    func       :set_direction
    event      :finish
  end

  class MoveCardAddAction < EventRule
    dsc        "移動カードをテーブルに出す"
    context    ["MultiDuel", :move_card_drop_phase]
    guard      ["self",:current_live?]
    func       :move_card_add
    event      :finish
  end

  class MoveCardRemoveAction < EventRule
    dsc        "移動カードをテーブルから戻す"
    context    ["MultiDuel", :move_card_drop_phase]
    guard      ["self",:current_live?]
    guard      ["self",:direction_set?]
    func       :move_card_remove
    event      :finish
  end

  class MoveCardRotateAction < EventRule
    dsc        "移動カードをテーブルで回転させる"
    guard      ["self",:current_live?]
    func       :move_card_rotate
    event      :finish
  end

  class AttackCardAddAction < EventRule
    dsc        "攻撃カードをテーブルに出す"
    context    ["MultiDuel", :attack_card_drop_phase]
    guard      ["self",:current_live?]
    guard      ["self",:initiative?]
    func       :battle_card_add
    event      :finish
  end

  class AttackCardRemoveAction < EventRule
    dsc        "攻撃カードをテーブルから戻す"
    context    ["MultiDuel", :attack_card_drop_phase]
    guard      ["self",:current_live?]
    guard      ["self",:initiative?]
    func       :battle_card_remove
    event      :finish
  end

  class AttackCardRotateAction < EventRule
    dsc        "攻撃カードをテーブルで回転させる"
    guard      ["self",:current_live?]
    func       :battle_card_rotate
    event      :finish
  end

  class DeffenceCardAddAction < EventRule
    dsc        "防御カードをテーブルに出す"
    context    ["MultiDuel", :deffence_card_drop_phase]
    guard      ["self",:current_live?]
    guard      ["self",:not_initiative?]
    func       :battle_card_add
    event      :finish
  end

  class DeffenceCardRemoveAction < EventRule
    dsc        "防御カードをテーブルから戻す"
    context    ["MultiDuel", :deffence_card_drop_phase]
    guard      ["self",:current_live?]
    guard      ["self",:not_initiative?]
    func       :battle_card_remove
    event      :finish
  end

  class DeffenceCardRotateAction < EventRule
    dsc        "防御カードをテーブルで回転させる"
    guard      ["self",:current_live?]
    func       :battle_card_rotate
    event      :finish
  end

  class CardRotateAction < EventRule
    dsc        "カードをテーブルで回転させる"
    context    ["MultiDuel", :move_card_drop_phase]
    context    ["MultiDuel", :deffence_card_drop_phase]
    context    ["MultiDuel", :attack_card_drop_phase]
    guard      ["self",:current_live?]
    func       :card_rotate
    event      :finish
  end

  class EventCardRotateAction < EventRule
    dsc        "イベントでカードを回転させる"
    func       :card_rotate
    event      :finish
  end

  class AddTableAction < EventRule
    dsc        "カードをテーブルに出す"
    func       :add_table
    event      :finish
  end

  class CharaChangeAction < EventRule
    dsc        "変更キャラカードを選択する"
    context    ["MultiDuel", :chara_change_phase]
    context    ["MultiDuel", :dead_chara_change_phase]
    func       :chara_change
    event      :finish
  end

  class InitDoneAction < EventRule
    dsc        "イニシアチブフェイズの完了"
    context    ["MultiDuel", :move_card_drop_phase]
    func       :init_done
    event      :finish
  end

  class MoveDoneAction < EventRule
    dsc        "移動決定のボタン押した"
    context    ["MultiDuel", :moving_phase]
    func       :move_done
    event      :finish
  end

  class FinishMovePhaseAction < EventRule
    dsc        "移動フェイズ完了後"
    func       :finish_move_phase
    event      :finish
  end

  class AttackDoneAction < EventRule
    dsc        "攻撃フェイズの完了"
    context    ["MultiDuel", :attack_card_drop_phase]
    guard      ["self",:initiative?]
    func       :attack_done
    event      :finish
  end

  class DeffenceDoneAction < EventRule
    dsc        "防御フェイズの完了"
    context    ["MultiDuel", :deffence_card_drop_phase]
    func       :deffence_done
    event      :finish
  end

  class ChangeDoneAction < EventRule
    dsc        "移動の決定"
    context    ["MultiDuel", :chara_change_phase]
    context    ["MultiDuel", :dead_chara_change_phase]
    func       :change_done
    event      :finish
  end

  class MoveAction < EventRule
    dsc        "移動する"
    func       :move
    event      :finish
  end

  class HideMoveAction < EventRule
    dsc        "移動する"
    func       :hide_move
    event      :finish
  end

  # ===========================
  # イベント定義
  # ===========================

  class MoveCardAddSuccesEvent < EventRule
    dsc        "移動カードをテーブルに出せた"
    func       :move_card_add_succes
    event      :finish
  end

  class BattleCardAddSuccesEvent < EventRule
    dsc        "移動カードをテーブルに出せた"
    func       :battle_card_add_succes
    event      :finish
  end

  class DamagedEvent < EventRule
    dsc        "ダメージをうける"
    func       :damaged
    event      :finish
  end

  class DetermineDamageEvent < EventRule
    dsc        "ダメージをうける"
    func       :determine_damage
    event      :finish
  end

  class ReviveEvent < EventRule
    dsc        "蘇生する"
    func       :revive
    event      :finish
  end

  class ConstraintEvent < EventRule
    dsc        "移動フェイズの行動を制限する"
    func       :constraint
    event      :finish
  end

  class SetDamageLogEvent < EventRule
    dsc        "レイドボス戦時にダメージをログに保存"
    func       :set_damage_log
    event      :finish
  end

  class PartyDamagedEvent < EventRule
    dsc        "指定したカードにダメージを与える"
    func       :party_damaged
    event      :finish
  end

  class HealedEvent < EventRule
    dsc        "ヒットポイントを回復する"
    func       :healed
    event      :finish
  end

  class HitPointChangedEvent < EventRule
    dsc        "ヒットポイントを変更する"
    func       :hit_point_changed
    event      :finish
  end

  class PartyHealedEvent < EventRule
    dsc        "指定したカードのヒットポイントを回復する"
    func       :party_healed
    event      :finish
  end

  class CuredEvent < EventRule
    dsc        "状態異常を回復する"
    func       :cured
    event      :finish
  end

  class SealedEvent < EventRule
    dsc        "必殺技を解除する"
    func       :sealed
    event      :finish
  end

  class UsedCardsEvent < EventRule
    dsc       "カードを使用済みになる"
    func      :used_cards
    event     :finish
  end

  class DealdEvent < EventRule
    dsc       "カードが配られる"
    func      :dealed
    event     :finish
  end

  class UseActionCardEvent <EventRule
    dsc       "アクションカードを使用する"
    func      :use_action_card
    event     :finish
  end

  class DiscardEvent <EventRule
    dsc       "アクションカードを手札から破棄する"
    func      :discard
    event     :finish
  end

  class DiscardTableEvent <EventRule
    dsc       "アクションカードをテーブルから破棄する"
    func      :discard_table
    event     :finish
  end

  class PointUpdateEvent <EventRule
    dsc       "ポイントが更新された"
    func      :point_update
    event     :finish
  end

  class PointRewriteEvent <EventRule
    dsc       "ポイントが上書きされた"
    func      :point_rewrite
    event     :finish
  end

  class SpecialDealedEvent < EventRule
    dsc       "カードが特別に配られる"
    func      :special_dealed
    event     :finish
  end

  class GraveDealedEvent < EventRule
    dsc       "墓場から特別に配られる"
    func      :grave_dealed
    event     :finish
  end

  class StealDealedEvent < EventRule
    dsc       "相手からカードを奪う"
    func      :grave_dealed
    event     :finish
  end

  class SpecialEventCardDealedEvent < EventRule
    dsc       "イベントカードが特別に配られる"
    func      :special_event_card_dealed
    event     :finish
  end

  class UpdateCardValueEvent < EventRule
    dsc        "値の更新を通知"
    func       :update_card_value
    event      :finish
  end

  class DiceRollEvent < EventRule
    dsc       "偽のダイスを振る"
    func      :dice_roll
    event     :finish
  end

  class UpdateWeaponEvent < EventRule
    dsc       "装備カードのボーナスを更新"
    func      :update_weapon
    event     :finish
  end

  class BattlePhaseInitEvent < EventRule
    dsc       "戦闘フェイズの終了時の初期化"
    func      :battle_phase_init
    event     :finish
  end

  class CardsMaxUpdateEvent <EventRule
    dsc       "最大所持カード枚数が更新された"
    func      :cards_max_update
    event     :finish
  end

  class DuelBonusEvent <EventRule
    dsc      "デュエルボーナスが発生した"
    func      :duel_bonus
    event     :finish
  end

  class SpecialMessageEvent <EventRule
    dsc      "特殊メッセージ"
    func      :special_message
    event     :finish
  end

  class DuelMessageEvent <EventRule
    dsc      "汎用メッセージ"
    func      :duel_message
    event     :finish
  end

  class AttributeRegistMessageEvent <EventRule
    dsc      "属性抵抗メッセージ"
    func      :attribute_regist_message
    event     :finish
  end

  class SetTurnEvent <EventRule
    dsc      "現在ターン数を変更する"
    func      :set_turn
    event     :finish
  end


  class MovePhaseInitEvent < EventRule
    dsc       "移動フェイズの終了時の初期化"
    func      :move_phase_init
    event     :finish
  end

  class UpdateTrapEvent < EventRule
    dsc       "トラップのターン数を更新"
    func      :update_trap
    event     :finish
  end

  class TrapActionEvent < EventRule
    dsc        "トラップ発動をクライアントへ通知"
    func       :trap_action
    event      :finish
  end

  class TrapUpdateEvent < EventRule
    dsc        "トラップの状態遷移をクライアントへ通知"
    func       :trap_update
    event      :finish
  end

  class DiceAttributeRegistEvent < EventRule
    dsc       "移動ポイントが計算される"
    func      :dice_attribute_regist
  end

  class SetFieldStatusEvent < EventRule
    dsc       "フィールドの状態が変更される"
    func      :set_field_status
    event     :finish
  end

  class SetInitiativeEvent < EventRule
    dsc       "イニシアチブが決定される"
    func      :set_initiative
    event     :finish
  end

  class CardLockEvent < EventRule
    dsc       "カードロックをクライアントに通知"
    func      :card_lock
    event     :finish
  end

  class ClearCardLocksEvent < EventRule
    dsc       "カードロックの終了をクライアントに通知"
    func      :clear_card_locks
    event     :finish
  end

  # ===========================
  # 計算定義
  # ===========================
  class BpCalcResolve < EventRule
    dsc       "攻撃ポイントが計算される"
    func      :bp_calc
  end

  class DpCalcResolve < EventRule
    dsc       "防御ポイントが計算される"
    func      :dp_calc
  end

  class MpCalcResolve < EventRule
    dsc       "移動ポイントが計算される"
    func      :mp_calc
  end

  class AlterMpEvent < EventRule
    dsc       "移動点加算完了後の上位移動点処理"
    func      :alter_mp
  end

  class MpEvaluationEvent < EventRule
    dsc       "移動点処理完了後「nitiativeセット＆moveアクション」の前に割り込む"
    func      :mp_evaluation
  end

end

