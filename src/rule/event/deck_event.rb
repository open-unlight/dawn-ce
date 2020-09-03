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
require 'rule/event/event'
require 'constants'

module Unlight

  # ===========================
  # イベント定義
  # ===========================

  class DrawCardsEvent < EventRule
    dsc       "カードをデッキから引く"
    func      :draw_cards
    event     :finish
  end

  class DrawLowCardsEvent < EventRule
    dsc       "値の小さなカードをデッキから引く"
    func      :draw_low_cards
    event     :finish
  end

  class DeckInitEvent < EventRule
    dsc       "デッキの再シャッフル"
    guard     ["self", :empty?]
    func      :deck_init
    event     :finish
  end

  class CreateChanceCardEvent < EventRule
    dsc       "チャンスカードを新規作成する"
    func      :create_chance_card
    event     :finish
  end

  class AppendJokerCardEvent < EventRule
    dsc       "ジョーカーカードを追加"
    func      :append_joker_card
    event     :finish
  end

end
