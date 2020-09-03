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
  class RewardEvent < EventRule
    dsc       "結果のルール"
    func      :start
    act       :init_phase
    act       :candidate_cards_list_phase
    act       :bottom_dice_num_phase
    act       :high_low_phase
    act       :exit_phase
    goal      ["self", :finished]
    event      :finish
  end


  # ===========================
  # フェイズ定義
  # ===========================

  class InitPhase <EventRule
      dsc        "初期化フェイズ"
      func       :init
      event      :finish
  end

  class CandidateCardsListPhase < EventRule
      dsc        "報酬のスタート"
      guard      ["self",:not_win_skip],["self",:not_reroll?]
      func       :candidate_cards_list
      event      :finish
  end

  class BottomDiceNumPhase <EventRule
    dsc        "基本ダイス数フェイズ"
      func       :bottom_dice_num
      event      :finish
  end

  class HighLowPhase <EventRule
      dsc        "ハイロー待ちフェイズ"
      func       :high_low
      event      :finish
      goal       ["self",:challenged]
      goal       ["self",:first?]
  end

  class ExitPhase <EventRule
      dsc        "カード決定待ちフェイズ"
      func       :exit
      event      :finish
      goal       ["self",:exited?]
  end


  # ===========================
  # イベント定義
  # ===========================

  class UpEvent < EventRule
    dsc       "アップを選択した結果"
    context    ["Reward", :high_low_phase]
    func      :up
    event     :finish
  end

  class DownEvent < EventRule
    dsc       "ダウンを選択した結果"
    context    ["Reward", :high_low_phase]
    func      :down
    event     :finish
  end

  class ResultDiceEvent < EventRule
    dsc       "ダイスの結果"
    func      :result_dice_num
    event     :finish
  end

  class CancelEvent < EventRule
    dsc       "キャンセルを選択した結果"
    context    ["Reward", :exit_phase]
    func      :cancel
    event     :finish
  end

  class RetryRewardEvent < EventRule
    dsc       "報酬ゲームを続ける"
    context    ["Reward", :exit_phase]
    func      :retry_reward
    event     :finish
  end

  class RerollEvent < EventRule
    dsc       "アイテムのリロールを使用"
    context    ["Reward", :exit_phase]
    func      :reroll
    event     :finish
  end

  class AmendEvent < EventRule
    dsc       "ダイス修正アイテムを使用"
    context    ["Reward", :exit_phase]
    func      :amend
    event     :finish
  end

end
