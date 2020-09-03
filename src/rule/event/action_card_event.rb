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
  #     実行条件 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
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

  # ====================
  # イベント
  # ====================

  # 追加したら以下の参照番号を付加すること
  ACTION_EVENT_NO =[
                    nil,                          # 0
                    [:occur_chance_event, 1],     # 1 チャンスカードx1
                    [:occur_chance_event, 2],     # 2 チャンスカードx2
                    [:occur_chance_event, 3],     # 3 チャンスカードx3
                    [:occur_chance_event, 4],     # 4 チャンスカードx4
                    [:occur_chance_event, 5],     # 5 チャンスカードx5
                    [:occur_heal_event, 1],       # 6 HP回復x1
                    [:occur_heal_event, 2],       # 7 HP回復x2
                    [:occur_heal_event, 3],       # 8 HP回復x3
                    [:occur_cure_event],          # 9 パラメーター異常回復
                    [:occur_quick_event],         # 10 必ずイニシアチブを取る
                    [:occur_curse_event, 1],      # 11 カースカードx1
                    [:occur_curse_event, 2],      # 12 カースカードx2
                    [:occur_curse_event, 3],      # 13 カースカードx3
                    [:occur_curse_event, 4],      # 14 カースカードx4
                    [:occur_curse_event, 5],      # 15 カースカードx5
                    [:occur_chalice_event, 1],    # 16 聖杯カード1
                    [:occur_poison_event, 1],     # 17 毒杯カード1
                    nil,                          # 18 ?
                    [:occur_damage_event, 2],     # 19 ウイルス
                   ]

  class DealedEvent < EventRule
    dsc        "カードが配られた"
    func       :dealed
  end

  class ThrowedEvent < EventRule
    dsc        "カードがすてられた"
    func       :throwed
  end

  class DropedEvent < EventRule
    dsc        "カードが場に出された"
    func       :droped
  end

  class OccurChanceEvent < EventRule
    dsc        "チャンスカード起動"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_chance
  end

  class OccurHealEvent < EventRule
    dsc        "HP回復イベント"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_heal
  end

  class OccurDamageEvent < EventRule
    dsc        "ダメージイベント"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_damage
  end

  class OccurCureEvent < EventRule
    dsc        "状態回復イベント"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_cure
  end

  class OccurCurseEvent < EventRule
    dsc        "カースカード起動"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_curse
  end

  class OccurChaliceEvent < EventRule
    dsc        "聖杯イベント"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_chalice
  end

  class OccurPoisonEvent < EventRule
    dsc        "毒杯イベント"
    type       :type=>:after, :obj=>"self", :hook=>:droped_event
    func       :occur_poison
  end

  class OccurDefeatEvent < EventRule
    dsc        "しまったカード 手札を３枚捨てる"
    context    ["Duel", :move_card_drop]
    context    ["Duel", :battle_card_drop]
    func       :occur_defeat
  end

  class OccurIdeaEvent < EventRule
    dsc        "気転カード 捨てカードから一枚拾うことができる"
    context    ["Duel", :move_card_drop]
    context    ["Duel", :battle_card_drop]
    func       :idea
    event      :start
  end

  class ChanceEvent < EventRule
    dsc        "チャンス！ 3枚追加ドロー"
    func       :chance
    event      :finish
  end

  class HealEvent < EventRule
    dsc        "ヒール！ HP回復"
    func       :heal
    event      :finish
  end

  class DamageEvent < EventRule
    dsc        "ダメージ！"
    func       :damage
    event      :finish
  end

  class CureEvent < EventRule
    dsc        "キュア！ 状態異常回復"
    func       :cure
    event      :finish
  end

  class CurseEvent < EventRule
    dsc        "呪い！ カード破棄"
    func       :curse
    event      :finish
  end

  class ChaliceEvent < EventRule
    dsc        "聖杯！ 状態異常回復とカードドロー"
    func       :chalice
    event      :finish
  end

  class PoisonEvent < EventRule
    dsc        "毒杯！ 状態異常解除とカード破棄"
    func       :poison
    event      :finish
  end

end
