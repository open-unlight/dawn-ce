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
  # ターン定義
  # ===========================
  class ThreeToThreeDuel < EventRule
    dsc       "3対3のデュエルルール"
    func      :start
    act       :start_turn_phase
    act       :refill_card_phase
    act       :refill_event_card_phase
    act       :move_card_drop_phase
    act       :determine_move_phase
    act       :finish_move_phase
    act       :chara_change_phase
    act       :determine_chara_change_phase
    act       :attack_card_drop_phase
    act       :deffence_card_drop_phase
    act       :determine_battle_point_phase
    act       :battle_result_phase
    act       :damage_phase
    act       :change_initiative_phase
    act       :attack_card_drop_phase
    act       :deffence_card_drop_phase
    act       :determine_battle_point_phase
    act       :battle_result_phase
    act       :damage_phase
    act       :dead_chara_change_phase
    act       :determine_dead_chara_change_phase
    act       :finish_turn_phase
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    goal       ["self",:timeout?]
    duration  :type => :times,:value => BATTLE_TIMEOUT_TURN
    event     :start,:finish
  end

  # ===========================
  # フェイズ定義
  # ===========================

  class StartTurnPhase < EventRule
    dsc        "ターンのスタート"
    guard      ["alpha",:start_ok?],["beta",:start_ok?]
    func       :start_turn
    event      :start, :finish
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    goal       ["alpha",:start_ok?],["beta",:start_ok?]
    duration  :type => :sec,:value => 60
  end

  class RefillCardPhase < EventRule
    dsc        "カードの補充"
    guard      ["alpha",:live?],["beta",:live?]
    func       :refill_card
    event      :finish
  end

  class RefillEventCardPhase < EventRule
    dsc        "イベントカードの補充"
    guard      ["alpha",:live?],["beta",:live?]
    func       :refill_event_card
    event      :finish
  end

  class MoveCardDropPhase < EventRule
    dsc        "移動カードの提出を待つ"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func       :move_card_drop
    goal       ["alpha", :init_done?],["beta", :init_done?]
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    duration   :type => :sec, :value => INIT_WAIT_TIME
    event      :start, :finish
  end

  class DetermineMovePhase < EventRule
    dsc        "移動の決定"
    guard      ["alpha",:live?],["beta",:live?]
    func       :determine_move
    event      :finish
  end

  class FinishMovePhase < EventRule
    dsc        "移動の終了"
    guard      ["alpha",:live?],["beta",:live?]
    func       :finish_move
    event      :finish
  end

  class CharaChangePhase < EventRule
    dsc        "キャラ変更を待つ"
    guard      ["alpha",:current_live?],["beta",:current_live?],["beta",:change_need?]
    guard      ["alpha",:current_live?],["beta",:current_live?],["alpha",:change_need?]
    goal       ["alpha",:change_done?],["beta",:change_done?]
    goal       ["alpha",:current_dead?]
    goal       ["beta",:current_dead?]
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    duration   :type => :sec, :value => BATTLE_WAIT_TIME
    func       :chara_change
    event      :start, :finish
  end

  class DetermineCharaChangePhase < EventRule
    dsc        "キャラ変更を決定"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func       :determine_chara_change
    event      :finish
  end

  class AttackCardDropPhase < EventRule
    dsc        "攻撃カードの提出を待つ"
    func       :battle_card_drop
    guard      ["alpha",:current_live?],["beta",:current_live?]
    goal       ["first_entrant",:attack_done?]
    goal       ["alpha",:not_change_done?]
    goal       ["beta",:not_change_done?]
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    duration   :type => :sec, :value => BATTLE_WAIT_TIME
    event      :start, :finish
  end

  class DeffenceCardDropPhase < EventRule
    dsc        "防御カードの提出を待つ"
    func       :battle_card_drop
    guard      ["alpha",:current_live?],["beta",:current_live?]
    goal       ["second_entrant",:deffence_done?]
    goal       ["alpha",:not_change_done?]
    goal       ["beta",:not_change_done?]
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    duration   :type => :sec, :value => BATTLE_WAIT_TIME
    event      :start, :finish
  end

  class DetermineBattlePointPhase < EventRule
    dsc       "戦闘ポイントの計算"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func       :determine_battle_point
    event      :finish
  end

  class BattleResultPhase < EventRule
    dsc       "戦闘結果"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func      :battle_result
    event     :finish
  end

  class DamagePhase < EventRule
    dsc       "ダメージ適用"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func      :damage
    event     :finish
  end

  class ChangeInitiativePhase < EventRule
    dsc       "攻守の交代"
    guard      ["alpha",:current_live?],["beta",:current_live?]
    func      :change_initiative
    event     :finish
  end

  class DeadCharaChangePhase < EventRule
    dsc        "キャラ変更を待つ"
    guard      ["alpha",:live?],["beta",:live?],["beta",:change_need?]
    guard      ["alpha",:live?],["beta",:live?],["alpha",:change_need?]
    func       :dead_chara_change
    goal       ["alpha", :change_done?],["beta", :change_done?]
    goal       ["alpha",:dead?]
    goal       ["beta",:dead?]
    duration   :type => :sec, :value => BATTLE_WAIT_TIME
    event      :start, :finish
  end

  class DetermineDeadCharaChangePhase < EventRule
    dsc        "キャラ変更を決定"
    guard      ["alpha",:live?],["beta",:live?]
    func       :determine_dead_chara_change
    event      :finish
  end

  class FinishTurnPhase < EventRule
    dsc       "ターンの終了"
    guard      ["alpha",:live?],["beta",:live?]
    func      :finish_turn
    event     :finish
  end


  # ===========================
  # イベント定義
  # ===========================

  class FinishGameEvent < EventRule
    dsc       "ゲームの終了"
    func      :finish_game
    event     :finish
  end
end

