# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

  # イベント定義
  # dsc:
  #   説明文
  #     "説明"
  # context:*
  #   実行可能な文脈
  #     ["obj", :event], ...
  # guard:*
  #   実行条件 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
  #   ["reciver",:method],...
  # goal:*
  #   終了条件 （登録した条件の一つでも成功すれば成功）。指定なければ必ず終了。Hookの場合は逆に終了しない。
  #   ["reciver",:method],...
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
  # event:
  #   イベントを発行するか？
  #   実行前     :start     (add_start_listener_xxx(method:yyyy), 返値:target)
  #   実行後     :finish    (add_finish_listener_xxx(method:yyyy),返値:taeget,ret)
  #   発行しない :< default
  # func:
  #   実行関数（hookする関数）
  # act:
  #   追加実行されるイベント

module Unlight

  AI_WAIT_TIME = 1

  # ===========================
  # 更新関数定義
  # ===========================
  class OneToOneAi < EventRule
    dsc       "1対１のデュエルのCPU戦"
    func      :think
    goal       ["entrant",:dead?]
    event     :start,:finish
  end

  # ===========================
  # 判断定義
  # ===========================

  class WaitingAction < EventRule
    dsc        "ターンの切れ目で待つ"
    func       :waiting
    goal       ["self",:wait?]
    duration   :type => :sec, :value => AI_WAIT_TIME
  end

  class ChoiceMoveCardAction < EventRule
    dsc        "移動カードの選択"
    func       :choice_move_card
    act        :waiting_action
    act        :drop_chance_card_action # チャンスカードを問答無用で出す
    act        :decision_feat_action    # 必殺技が使えるかどうかの判定
    act        :reset_think_num_action
    act        :decision_dist_action
    act        :waiting_action
    act        :move_feat_hand_set_action # 可能ならば移動必殺技を突っ込む
    act        :drop_move_card_action
    act        :waiting_action
    act        :waiting_action
    act        :done_init_action
    goal       ["entrant", :init_done?]
  end

  class ChoiceAttackCardAction < EventRule
    dsc        "攻撃カードの選択"
    guard      ["entrant",:initiative?]
    goal       ["entrant", :untill_attack_done?]
    func       :choice_attack_card
    act        :waiting_action
    act        :decision_attack_action
    act        :attack_feat_hand_set_action # 可能ならば攻撃必殺技を突っ込む
    act        :drop_attack_card_action
    act        :waiting_action
    act        :done_attack_action
    goal       ["entrant",:not_initiative?]
    goal       ["entrant", :attack_done?]
  end

  class ChoiceDeffenceCardAction < EventRule
    dsc        "防御カードの選択"
    guard      ["entrant",:not_initiative?]
    goal       ["entrant", :untill_deffence_done?]
    func       :choice_deffence_card
    act        :waiting_action
    act        :decision_deffence_action
    act        :deffence_feat_hand_set_action # 可能ならば攻撃必殺技を突っ込む
    act        :drop_deffence_card_action
    act        :waiting_action
    act        :done_deffence_action
    goal       ["entrant",:initiative?]
    goal       ["entrant", :deffence_done?]
  end

  class ChoiceCharaCardAction < EventRule
    dsc        "キャラカードの選択"
    guard      ["entrant",:change_need?]
    func       :choice_chara_card
    act        :waiting_action
    act        :decision_chara_change_action
    act        :set_chara_card_action
    goal       ["entrant",:change_done?]
  end

  class DropChanceCardAction < EventRule
    dsc        "チャンスのカードの提出"
    func       :drop_chance_card
    goal       ["self",:chance_none?]
  end

  class DropMoveCardAction < EventRule
    dsc        "移動のカードの提出"
    func       :drop_move_card
  end

  class DropAttackCardAction < EventRule
    dsc        "攻撃のカードの提出"
    func       :drop_attack_card
  end

  class DropDeffenceCardAction < EventRule
    dsc        "防御のカードの提出"
    func       :drop_deffence_card
  end

  class SetCharaCardAction < EventRule
    dsc        "キャラのカードの提出"
    func       :set_chara_card
  end

  class DoneInitAction < EventRule
    dsc        "移動の終了"
    func       :done_init
  end

  class DoneAttackAction < EventRule
    dsc        "攻撃の終了"
    func       :done_attack
  end

  class DoneDeffenceAction < EventRule
    dsc        "防御の終了"
    func       :done_deffence
  end

  class MoveFeatHandSetAction < EventRule
    dsc        "移動フェイズの必殺技をカードをセット"
    func       :move_feat_hand_set
  end

  class AttackFeatHandSetAction < EventRule
    dsc        "攻撃フェイズの必殺技をカードをセット"
    func       :attack_feat_hand_set
  end

  class DeffenceFeatHandSetAction < EventRule
    dsc        "防御フェイズの必殺技をカードをセット"
    func       :deffence_feat_hand_set
  end



  class ResetThinkNumAction < EventRule
    dsc        "防御フェイズの必殺技をカードをセット"
    func       :reset_think_num
  end

  # ===========================
  # 判定定義
  # ===========================
  class DecisionFeatAction < EventRule
    dsc        "使用できる必殺技の判定"
    func       :decision_feat
    goal       ["self", :solved?]
  end


  class DecisionDistAction < EventRule
    dsc        "移動したい距離の判定"
    func       :decision_dist
    goal       ["self", :solved?]
  end

  class DecisionAttackAction < EventRule
    dsc        "攻撃カードの判定"
    func       :decision_attack
    goal       ["self", :solved?]
  end

  class DecisionDeffenceAction < EventRule
    dsc        "防御カードの判定"
    func       :decision_deffence
    goal       ["self", :solved?]
  end

  class DecisionCharaChangeAction < EventRule
    dsc        "キャラカードの判定"
    func       :decision_chara_change
    goal       ["self", :solved?]
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

