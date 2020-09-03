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
  # 状態イベント
  # ====================

  # 追加したら以下の参照番号を付加すること
  # イベントの起動チェック関数を列挙する
  CHARA_PASSIVE_SKILL_EVENT_NO =[
                    [],
                                 # 0
                    [
                     :check_additional_draw_passive_event,
                     :finish_additional_draw_passive_event,
                    ],
                                 # 1 追加ドロー
                    [
                     :check_indomitable_mind_passive_event,
                     :check_indomitable_mind_passive_change_event,
                     :use_indomitable_mind_passive_damage_event,
                     :finish_indomitable_mind_passive_event,
                     :finish_indomitable_mind_passive_dead_chara_change_event,
                    ],
                                 # 2 不屈
                    [
                     :check_drain_soul_passive_event,
                     :finish_drain_soul_passive_event,
                    ],
                                 # 3 精神の器
                    [
                     :check_sealing_attack_passive_event,
                     :check_sealing_attack_passive_change_event,
                     :finish_sealing_attack_passive_event,
                    ],
                                 # 4 剣聖
                    [
                     :check_instant_kill_guard_passive_start_turn_event,
                    ],
                                 # 5 千古不朽
                    [
                     :check_rage_against_passive_start_event,
                     :check_rage_against_passive_chara_change_event,
                     :check_rage_against_passive_dead_change_event,
                     :finish_rage_against_passive_event
                    ],
                                 # 6 レイジ
                    [
                     :check_creator_passive_start_turn_event,
                     :check_creator_passive_chara_change_event,
                     :check_creator_passive_dead_chara_change_event,
                     :use_creator_passive_damage_event,
                     :use_creator_passive_determine_move_phase_event,
                     :use_creator_passive_move_phase_event,
                     :use_creator_passive_determine_bp_phase_event,
                     :use_creator_passive_battle_result_phase_event,
                     :finish_creator_passive_chara_change_event,
                     :finish_creator_passive_dead_chara_change_event,
                     :finish_creator_passive_finish_turn_event,
                    ],
                                 # 7 創造主
                    [
                     :check_bounce_back_passive_event,
                     :check_bounce_back_passive_change_event,
                     :use_bounce_back_passive_damage_event,
                     :finish_bounce_back_passive_event,
                     :finish_bounce_back_passive_dead_chara_change_event,
                    ],
                                 # 8 バウンスバック
                    [
                     :check_linkage_passive_start_turn_event,
                     :check_linkage_passive_chara_change_event,
                     :check_linkage_passive_dead_chara_change_event,
                    ],
                                 # 9 リンケージ
                    [
                     :use_liberation_passive_event,
                     :finish_liberation_passive_event,
                     :finish_liberation_passive_dead_chara_change_event,
                    ],
                                 # 10 リベレーション
                    [
                     :check_harden_passive_event,
                     :use_harden_passive_damage_event,
                     :finish_harden_passive_event,
                     :finish_harden_passive_dead_chara_change_event,
                    ],
                                 # 11 ハーデン
                    [
                     :check_absorp_passive_event,
                     :use_absorp_passive_damage_event,
                     :finish_absorp_passive_event,
                     :finish_absorp_passive_dead_chara_change_event,
                    ],
                                 # 12 アブソープ
                    [
                     :check_moondog_passive_event,
                     :check_moondog_passive_change_event,
                     :use_moondog_passive_event,
                     :finish_moondog_passive_event,
                    ],
                                 # 13 幻月
                    [
                     :check_jump_passive_event,
                     :use_jump_passive_damage_before_event,
                     :use_jump_passive_damage_after_event,
                     :use_jump_passive_det_bp_event,
                     :use_jump_passive_battle_result_before_event,
                     :use_jump_passive_battle_result_after_event,
                     :finish_jump_passive_event,
                    ],
                                 # 14 跳躍
                    [
                     :check_protection_aim_passive_event,
                     :check_protection_aim_passive_change_event,
                     :use_protection_aim_passive_event,
                     :finish_protection_aim_passive_event,
                    ],
                                 # 15 プロテクションエイム
                    [
                     :check_mistake_passive_event,
                     :use_mistake_passive_damage_event,
                     :finish_mistake_passive_event,
                     :finish_mistake_passive_dead_chara_change_event,
                    ],
                                 # 16 C・ミステイク
                    [
                     :check_status_resistance_passive_event,
                    ],
                                 # 17 スライムカバー
                    [
                     :check_senkou_passive_event,
                     :use_senkou_passive_event,
                     :finish_senkou_passive_event,
                     :finish_senkou_passive_dead_chara_change_event,
                    ],
                                 # 18 潜行する災厄
                    [
                     :check_hate_passive_event,
                     :use_hate_passive_event,
                     :use_hate_passive_damage_event,
                     :finish_hate_passive_event,
                     :finish_hate_passive_dead_chara_change_event,
                    ],
                                 # 19 果てる路
                    [
                     :check_little_princess_passive_event,
                     :check_little_princess_change_passive_event,
                     :use_little_princess_passive_event,
                     :finish_little_princess_passive_event,
                     :finish_little_princess_passive_dead_chara_change_event,
                    ],
                                 # 20 リトルプリンセス
                    [
                     :check_crimson_witch_passive_event,
                     :check_crimson_witch_change_passive_event,
                     :use_crimson_witch_passive_event,
                     :finish_crimson_witch_passive_event,
                     :finish_crimson_witch_passive_dead_chara_change_event,
                    ],
                                 # 21 深紅の魔女
                    [
                     :check_aegis_passive_event,
                     :check_aegis_passive_change_event,
                     :use_aegis_passive_event,
                     :finish_aegis_passive_event,
                     :finish_aegis_passive_dead_chara_change_event,
                    ],
                                 # 22 イージス
                    [
                     :check_ocean_passive_event,
                     :check_ocean_passive_change_event,
                     :check_ocean_passive_dead_change_event,
                     :finish_ocean_passive_event,
                    ],
                                 # 23 溟海符
                    [
                     :check_resist_skylla_passive_event,
                    ],
                                 # 24 状態抵抗 スキュラ
                    [
                     :check_night_fog_passive_event,
                     :use_night_fog_passive_event,
                     :use_night_fog_passive_damage_event,
                     :finish_night_fog_passive_event,
                     :finish_night_fog_passive_dead_chara_change_event,
                    ],
                                 # 25 立ち込める夜霧
                    [
                     :check_double_boddy_passive_event,
                     :check_double_boddy_passive_change_event,
                     :use_double_boddy_passive_event,
                     :finish_double_boddy_passive_event,
                     :finish_double_boddy_passive_dead_chara_change_event,
                    ],
                                 # 26 2つの身体(パッシブ)
                    [
                     :check_wit_passive_event,
                     :use_wit_passive_draw_event,
                     :use_wit_passive_event,
                     :finish_wit_passive_event,
                    ],
                                 # 27 機知
                    [
                     :check_curse_care_passive_event,
                     :check_curse_care_passive_change_event,
                     :use_curse_care_passive_event,
                     :recover_curse_care_passive_det_bp_bf_event,
                     :recover_curse_care_passive_det_bp_af_event,
                     :recover_curse_care_passive_damage_bf_event,
                     :recover_curse_care_passive_damage_af_event,
                     :recover_curse_care_passive_last_event,
                     :finish_curse_care_passive_event,
                     :finish_curse_care_passive_dead_chara_change_event,
                    ],
                                 # 28 修羅
                    [
                     :check_white_light_passive_event,
                     :finish_white_light_passive_event,
                    ],
                                 # 29 白晄
                    [
                     :check_carapace_break_passive_event,
                     :check_carapace_break_change_passive_event,
                     :check_carapace_break_dead_change_passive_event,
                     :use_carapace_break_passive_event,
                     :finish_carapace_break_passive_event,
                     :finish_carapace_break_passive_dead_chara_change_event,
                    ],
                                 # 30 甲羅割り
                    [
                     :check_carapace_passive_event,
                     :use_carapace_passive_event,
                     :finish_carapace_passive_event,
                     :finish_carapace_passive_dead_chara_change_event,
                    ],
                                 # 31 身隠し
                    [
                     :check_resist_kamuy_passive_event,
                     :check_chara_resist_kamuy_passive_event,
                     :restore_resist_kamuy_passive_event,
                    ],
                                 # 32 状態抵抗 かめ
                    [
                     :check_revisers_passive_event,
                     :check_revisers_passive_change_event,
                     :check_revisers_passive_dead_change_event,
                    ],
                                 # 33 リバイザーズ
                    [
                     :check_resist_wall_passive_event,
                     :check_resist_wall_passive_change_event,
                     :check_resist_wall_passive_dead_change_event,
                     :check_resist_wall_passive_move_event,
                    ],
                                 # 34 レジストウォール
                    [
                     :check_curse_sign_passive_event,
                     :check_curse_sign_passive_change_event,
                     :check_curse_sign_passive_dead_change_event,
                     :finish_curse_sign_passive_event,
                     :finish_curse_sign_passive_change_event,
                     :finish_curse_sign_passive_dead_change_event,
                    ],
                                 # 35 呪印符
                    [
                     :check_loyalty_passive_event,
                     :check_loyalty_passive_change_event,
                     :check_loyalty_passive_dead_change_event,
                     :finish_loyalty_passive_event,
                     :finish_loyalty_passive_change_event,
                     :finish_loyalty_passive_dead_change_event,
                    ],
                                 # 36 従者の忠誠
                    [
                     :check_aiming_plus_passive_event,
                     :check_aiming_plus_passive_change_event,
                     :use_aiming_plus_passive_event,
                     :finish_aiming_plus_passive_event,
                     :finish_aiming_plus_passive_dead_chara_change_event,
                    ],
                                 # 37 精密射撃+
                    [
                     :check_easing_card_condition_passive_event,
                     :check_easing_card_condition_passive_change_event,
                     :check_easing_card_condition_passive_dead_change_event,
                    ],
                                 # 38 精密射撃+
                    [
                     :check_harvest_passive_event,
                     :finish_harvest_passive_event,
                    ],
                                 # 39 収穫
                    [
                     :check_td_passive_event,
                     :finish_td_passive_event,
                    ],
                                 # 40 T.D.
                    [
                     :check_moon_shine_passive_event,
                     :check_moon_shine_passive_change_event,
                     :finish_moon_shine_passive_event,
                    ],
                                 # 41 ムーンシャイン
                    [
                     :check_fertility_passive_event,
                     :finish_fertility_passive_pre_event,
                     :finish_fertility_passive_event,
                    ],
                                 # 42 豊穣符
                    [
                     :check_resist_pumpkin_passive_event,
                    ],
                                 # 43 状態抵抗 クエカボチャ
                    [
                     :check_awcs_passive_event,
                     :use_awcs_passive_damage_event,
                    ],
                                 # 44 AWCS
                    [
                     :check_resist_dw_passive_event,
                    ],
                                 # 45 状態抵抗 DW
                    [
                     :check_lonsbrough_event_passive_event,
                     :check_lonsbrough_event_passive_change_event,
                     :use_lonsbrough_event_passive_damage_event,
                    ],
                                 # 46 ロンズブラウイベント
                    [
                     :check_rock_crusher_passive_event,
                     :check_rock_crusher_change_passive_event,
                     :check_rock_crusher_dead_change_passive_event,
                     :use_rock_crusher_passive_event,
                     :finish_rock_crusher_passive_event,
                     :finish_rock_crusher_passive_dead_chara_change_event,
                    ],
                                 # 47 岩石割り
                    [
                     :check_projection_passive_change_event,
                     :check_projection_passive_dead_change_event,
                     :finish_projection_passive_event,
                    ],
                                 # 48 交錯する影
                    [
                     :check_damage_multiplier_passive_event,
                     :check_damage_multiplier_change_passive_event,
                     :check_damage_multiplier_dead_change_passive_event,
                     :use_damage_multiplier_passive_event,
                     :finish_damage_multiplier_passive_event,
                     :finish_damage_multiplier_passive_dead_chara_change_event,
                    ],
                                 # 49 ダメージ乗算
                    [
                     :check_ev201606_passive_event,
                     :check_ev201606_change_passive_event,
                     :check_ev201606_dead_change_passive_event,
                     :use_ev201606_passive_event,
                     :finish_ev201606_passive_event,
                     :finish_ev201606_passive_dead_chara_change_event,
                    ],
                                 # 50 2016.6イベント
                    [
                     :check_status_resistance_aquamarine_passive_event,
                    ],
                                 # 51 アクアマリン
                    [
                     :check_cooly_passive_event,
                     :check_cooly_change_passive_event,
                     :check_cooly_dead_change_passive_event,
                     :use_cooly_passive_move_event,
                     :use_cooly_passive_attack_event,
                     :use_cooly_passive_defense_event,
                    ],
                                 # 52 爽涼符
                    [
                     :check_ev201609_passive_event,
                     :check_ev201609_change_passive_event,
                     :check_ev201609_dead_change_passive_event,
                     :use_ev201609_passive_event,
                     :finish_ev201609_passive_event,
                     :finish_ev201609_passive_dead_chara_change_event,
                    ],
                                 # 53 2016.9イベント
                    [
                     :check_resist_byakhee_passive_event,
                    ],
                                 # 54 状態抵抗 ビヤーキー
                    [
                     :check_disaster_flame_passive_event,
                     :check_disaster_flame_passive_change_event,
                     :finish_disaster_flame_passive_event,
                    ],
                                 # 55 劫火
                    [
                     :check_brambles_card_passive_event,
                     :check_brambles_card_passive_change_event,
                     :check_brambles_card_passive_dead_change_event,
                     :use_brambles_card_passive_event,
                     :finish_brambles_card_passive_event,
                    ],
                                 # 56 荊棘符
                    [
                     :check_awakening_one_passive_event,
                     :check_awakening_one_passive_change_event,
                     :finish_awakening_one_passive_event,
                    ],
                                 # 57 目覚めしもの
                    [
                     :check_servo_skull_passive_event,
                     :check_servo_skull_passive_change_event,
                     :use_servo_skull_passive_event,
                     :finish_servo_skull_passive_event,
                     :finish_servo_skull_passive_dead_chara_change_event,
                    ],
                                 # 58 サーボスカル
                    [
                     :check_ev201612_passive_event,
                     :check_ev201612_change_passive_event,
                     :use_ev201612_passive_event,
                     :finish_ev201612_passive_event,
                     :finish_ev201612_passive_dead_chara_change_event,
                    ],
                                 # 59 2016.12イベント
                    [
                     :check_high_protection_passive_event,
                     :check_high_protection_passive_change_event,
                     :use_high_protection_passive_event,
                     :finish_high_protection_passive_event,
                    ],
                                 # 60 ハイプロテクション
                    [
                     :check_puppet_master_passive_event,
                     :check_puppet_master_passive_change_event,
                     :use_puppet_master_passive_event,
                     :finish_puppet_master_passive_event,
                    ],
                                 # 61 パペットマスター
                    [
                     :check_ogre_arm_passive_event,
                     :check_ogre_arm_change_passive_event,
                     :use_ogre_arm_passive_event,
                     :finish_ogre_arm_passive_event,
                     :finish_ogre_arm_passive_dead_chara_change_event,
                    ],
                                 # 62 岩石割り
                    [
                     :check_crimson_will_passive_event,
                     :check_crimson_will_passive_change_event,
                     :use_crimson_will_passive_damage_event,
                     :finish_crimson_will_passive_event,
                     :finish_crimson_will_passive_dead_chara_change_event,
                    ],
                                 # 63 紅の意志
                    [
                     :check_guardian_of_life_passive_event,
                     :check_guardian_of_life_passive_change_event,
                     :use_guardian_of_life_passive_attack_event,
                     :use_guardian_of_life_passive_defense_event,
                     :finish_guardian_of_life_passive_event,
                     :finish_guardian_of_life_passive_dead_chara_change_event,
                    ],
                                 # 64 生命の守人
                    [
                     :check_burning_embers_passive_event,
                     :check_burning_embers_change_passive_event,
                     :check_burning_embers_dead_change_passive_event,
                     :use_burning_embers_passive_move_event,
                     :use_burning_embers_passive_attack_event,
                     :use_burning_embers_passive_defense_event,
                     :use_burning_embers_passive_defense_det_chara_change_event,
                    ],
                                 # 65 余焔符
                   ]

#---------------------------------------------------------------------------------------------
# ドロー

  class CheckAdditionalDrawPassiveEvent < EventRule
    dsc        "ドローをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_additional_draw_passive
  end

  class FinishAdditionalDrawPassiveEvent < EventRule
    dsc        "ドローを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :finish_additional_draw_passive
  end

#---------------------------------------------------------------------------------------------
# 不屈

  class CheckIndomitableMindPassiveEvent < EventRule
    dsc        "不屈をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_indomitable_mind_passive
  end

  class CheckIndomitableMindPassiveChangeEvent < EventRule
    dsc        "不屈をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_indomitable_mind_passive
  end

  class UseIndomitableMindPassiveDamageEvent < EventRule
    dsc        "不屈を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>60
    func       :use_indomitable_mind_passive_damage
  end

  class FinishIndomitableMindPassiveEvent < EventRule
    dsc        "不屈を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_indomitable_mind_passive
  end

  class FinishIndomitableMindPassiveDeadCharaChangeEvent < EventRule
    dsc        "不屈を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_indomitable_mind_passive
  end

#---------------------------------------------------------------------------------------------
# 精神の器

  class CheckDrainSoulPassiveEvent < EventRule
    dsc        "精神の器をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_drain_soul_passive
  end

  class FinishDrainSoulPassiveEvent < EventRule
    dsc        "精神の器を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :finish_drain_soul_passive
  end

#---------------------------------------------------------------------------------------------
# 剣聖

  class CheckSealingAttackPassiveEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_sealing_attack_passive
  end

  class CheckSealingAttackPassiveChangeEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_sealing_attack_passive
  end

  class FinishSealingAttackPassiveEvent < EventRule
    dsc        "封印攻撃を発動"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_done_action
    func       :finish_sealing_attack_passive
  end

#---------------------------------------------------------------------------------------------
# 千古不朽

  class CheckInstantKillGuardPassiveStartTurnEvent < EventRule
    dsc        "千古不朽開始"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_instant_kill_guard_passive
  end

#---------------------------------------------------------------------------------------------
# レイジ

  class CheckRageAgainstPassiveStartEvent < EventRule
    dsc        "レイジアゲンストを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_rage_against_only_first_turn_passive
  end

  class CheckRageAgainstPassiveCharaChangeEvent < EventRule
    dsc        "レイジアゲンストを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_rage_against_passive
  end

  class CheckRageAgainstPassiveDeadChangeEvent < EventRule
    dsc        "レイジアゲンストを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_rage_against_passive
  end

  class FinishRageAgainstPassiveEvent < EventRule
    dsc        "レイジアゲンスト"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :finish_rage_against_passive
  end

  class OnRageAgainstEvent < EventRule
    dsc        "レイジアゲンストがON"
    func       :on_rage_against
    event      :finish
  end

#---------------------------------------------------------------------------------------------
# 創造主

  class CheckCreatorPassiveStartTurnEvent < EventRule
    dsc        "創造主開始"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_creator_passive
  end

  class FinishCreatorPassiveCharaChangeEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_chara_change_phase, :priority=>10
    func       :finish_creator_passive
  end

  class FinishCreatorPassiveDeadCharaChangeEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase, :priority=>10
    func       :finish_creator_passive
  end

  class CheckCreatorPassiveCharaChangeEvent < EventRule
    dsc        "創造主開始"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_creator_passive
  end

  class CheckCreatorPassiveDeadCharaChangeEvent < EventRule
    dsc        "創造主開始"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_creator_passive
  end

  class FinishCreatorPassiveFinishTurnEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_creator_passive
  end

  class UseCreatorPassiveDamageEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>199
    func       :use_creator_passive
  end

  class UseCreatorPassiveDetermineBpPhaseEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>199
    func       :use_creator_passive
  end

  class UseCreatorPassiveBattleResultPhaseEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>199
    func       :use_creator_passive
  end

  class TestCreatorPassiveCharaChangeEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :test_creator_passive
  end

  class UseCreatorPassiveDetermineMovePhaseEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>199
    func       :use_creator_passive
  end

  class UseCreatorPassiveMovePhaseEvent < EventRule
    dsc        "創造主終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase, :priority=>199
    func       :use_creator_passive
  end

#---------------------------------------------------------------------------------------------
# バウンスバック

  class CheckBounceBackPassiveEvent < EventRule
    dsc        "バウンスバックをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_bounce_back_passive
  end

  class CheckBounceBackPassiveChangeEvent < EventRule
    dsc        "バウンスバックをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_bounce_back_passive
  end

  class UseBounceBackPassiveDamageEvent < EventRule
    dsc        "バウンスバックを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_bounce_back_passive_damage
  end

  class FinishBounceBackPassiveEvent < EventRule
    dsc        "バウンスバックを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_bounce_back_passive
  end

  class FinishBounceBackPassiveDeadCharaChangeEvent < EventRule
    dsc        "バウンスバックを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_bounce_back_passive
  end

#---------------------------------------------------------------------------------------------
# リンケージ

  class CheckLinkagePassiveStartTurnEvent < EventRule
    dsc        "リンケージ開始"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_linkage_passive
  end

  class CheckLinkagePassiveCharaChangeEvent < EventRule
    dsc        "リンケージ開始"
    type       :type=>:after, :obj=>"duel", :hook=>:chara_change_phase
    func       :check_linkage_passive
  end

  class CheckLinkagePassiveDeadCharaChangeEvent < EventRule
    dsc        "リンケージ開始"
    type       :type=>:after, :obj=>"duel", :hook=>:dead_chara_change_phase
    func       :check_linkage_passive
  end

#---------------------------------------------------------------------------------------------
# リべレーション

  class UseLiberationPassiveEvent < EventRule
    dsc        "リべレーションを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>50
    func       :use_liberation_passive
  end

  class FinishLiberationPassiveEvent < EventRule
    dsc        "リべレーションを切る"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase
    func       :finish_liberation_passive
  end

  class FinishLiberationPassiveDeadCharaChangeEvent < EventRule
    dsc        "リべレーションを切る"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_liberation_passive
  end

#---------------------------------------------------------------------------------------------
# ハーデン

  class CheckHardenPassiveEvent < EventRule
    dsc        "ハーデンをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_harden_passive
  end

  class UseHardenPassiveDamageEvent < EventRule
    dsc        "ハーデンを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_harden_passive_damage
  end

  class FinishHardenPassiveEvent < EventRule
    dsc        "ハーデンを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_harden_passive
  end

  class FinishHardenPassiveDeadCharaChangeEvent < EventRule
    dsc        "ハーデンを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_harden_passive
  end

#---------------------------------------------------------------------------------------------
# アブソープ

  class CheckAbsorpPassiveEvent < EventRule
    dsc        "アブソープをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase, :priority=>10
    func       :check_absorp_passive
  end

  class UseAbsorpPassiveDamageEvent < EventRule
    dsc        "アブソープを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_absorp_passive_damage
  end

  class FinishAbsorpPassiveEvent < EventRule
    dsc        "アブソープを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_absorp_passive
  end

  class FinishAbsorpPassiveDeadCharaChangeEvent < EventRule
    dsc        "アブソープを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_absorp_passive
  end

#---------------------------------------------------------------------------------------------
# 幻月

  class CheckMoondogPassiveEvent < EventRule
    dsc        "幻月をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_moondog_passive
  end

  class CheckMoondogPassiveChangeEvent < EventRule
    dsc        "幻月をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_moondog_passive
  end

  class UseMoondogPassiveEvent < EventRule
    dsc        "幻月を発動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_moondog_passive
  end

  class FinishMoondogPassiveEvent < EventRule
    dsc        "幻月を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_moondog_passive
  end

  class FinishMoondogPassiveDeadCharaChangeEvent < EventRule
    dsc        "幻月を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_moondog_passive
  end

#---------------------------------------------------------------------------------------------
# 跳躍

  class CheckJumpPassiveEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action
    func       :check_jump_passive
  end

  class UseJumpPassiveDamageAfterEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_jump_passive
  end

  class UseJumpPassiveDamageBeforeEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>150
    func       :use_jump_passive
  end

  class UseJumpPassiveDetBpEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>100
    func       :use_jump_passive
  end

  class UseJumpPassiveBattleResultBeforeEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:battle_result_phase, :priority=>150
    func       :use_jump_passive
  end

  class UseJumpPassiveBattleResultAfterEvent < EventRule
    dsc        "跳躍をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>150
    func       :use_jump_passive
  end

  class FinishJumpPassiveEvent < EventRule
    dsc        "跳躍を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>200
    func       :finish_jump_passive
  end

  class FinishJumpPassiveDeadCharaChangeEvent < EventRule
    dsc        "跳躍を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_jump_passive
  end

#---------------------------------------------------------------------------------------------
# プロテクションエイム

  class CheckProtectionAimPassiveEvent < EventRule
    dsc        "プロテクションエイムをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_protection_aim_passive
  end

  class CheckProtectionAimPassiveChangeEvent < EventRule
    dsc        "プロテクションエイムをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_protection_aim_passive
  end

  class UseProtectionAimPassiveEvent < EventRule
    dsc        "プロテクションエイムを発動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_protection_aim_passive
  end

  class FinishProtectionAimPassiveEvent < EventRule
    dsc        "プロテクションエイムを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_protection_aim_passive
  end

  class FinishProtectionAimPassiveDeadCharaChangeEvent < EventRule
    dsc        "プロテクションエイムを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_protection_aim_passive
  end

#---------------------------------------------------------------------------------------------
# ミステイク
  class CheckMistakePassiveEvent < EventRule
    dsc        "ミステイクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action
    func       :check_mistake_passive
    goal       ["self", :use_end?]
  end

  class UseMistakePassiveDamageEvent < EventRule
    dsc        "ミステイク発動。不死になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :use_mistake_passive_damage
    goal       ["self", :use_end?]
  end

  class FinishMistakePassiveEvent < EventRule
    dsc        "ミステイクの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_mistake_passive
    goal       ["self", :use_end?]
  end

  class FinishMistakePassiveDeadCharaChangeEvent < EventRule
    dsc        "バウンスバックを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_mistake_passive
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 妖蛆
  class CheckStatusResistancePassiveEvent < EventRule
    dsc        "ミステイクが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_status_resistance_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 潜行する災厄

  class CheckSenkouPassiveEvent < EventRule
    dsc        "潜行する災厄をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_senkou_passive
  end

  class UseSenkouPassiveEvent < EventRule
    dsc        "潜行する災厄を発動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_senkou_passive
  end

  class FinishSenkouPassiveEvent < EventRule
    dsc        "潜行する災厄を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_senkou_passive
  end

  class FinishSenkouPassiveDeadCharaChangeEvent < EventRule
    dsc        "潜行する災厄を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_senkou_passive
  end

#---------------------------------------------------------------------------------------------
# 果てる路

  class CheckHatePassiveEvent < EventRule
    dsc        "果てる路をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_hate_passive
  end

  class UseHatePassiveEvent < EventRule
    dsc        "果てる路を発動"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hate_passive
  end

  class UseHatePassiveDamageEvent < EventRule
    dsc        "果てる路を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_hate_passive_damage
  end

  class FinishHatePassiveEvent < EventRule
    dsc        "果てる路を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_hate_passive
  end

  class FinishHatePassiveDeadCharaChangeEvent < EventRule
    dsc        "果てる路を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_hate_passive
  end

#---------------------------------------------------------------------------------------------
# リトルプリンセス

  class CheckLittlePrincessPassiveEvent < EventRule
    dsc        "リトルプリンセスをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_little_princess_passive
  end

  class CheckLittlePrincessChangePassiveEvent < EventRule
    dsc        "リトルプリンセスをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_little_princess_passive
  end

  class UseLittlePrincessPassiveEvent < EventRule
    dsc        "リトルプリンセスを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_little_princess_passive
  end

  class FinishLittlePrincessPassiveEvent < EventRule
    dsc        "リトルプリンセスを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_little_princess_passive
  end

  class FinishLittlePrincessPassiveDeadCharaChangeEvent < EventRule
    dsc        "リトルプリンセスを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_little_princess_passive
  end

#---------------------------------------------------------------------------------------------
# 深紅の魔女

  class CheckCrimsonWitchPassiveEvent < EventRule
    dsc        "深紅の魔女をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_crimson_witch_passive
  end

  class CheckCrimsonWitchChangePassiveEvent < EventRule
    dsc        "深紅の魔女をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_crimson_witch_passive
  end

  class UseCrimsonWitchPassiveEvent < EventRule
    dsc        "深紅の魔女を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_crimson_witch_passive
  end

  class FinishCrimsonWitchPassiveEvent < EventRule
    dsc        "深紅の魔女を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_crimson_witch_passive
  end

  class FinishCrimsonWitchPassiveDeadCharaChangeEvent < EventRule
    dsc        "深紅の魔女を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_crimson_witch_passive
  end

#---------------------------------------------------------------------------------------------
# イージス

  class CheckAegisPassiveEvent < EventRule
    dsc        "イージスをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_aegis_passive
  end

  class CheckAegisPassiveChangeEvent < EventRule
    dsc        "イージスをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_aegis_passive
  end

  class UseAegisPassiveEvent < EventRule
    dsc        "イージスを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_aegis_passive
  end

  class FinishAegisPassiveEvent < EventRule
    dsc        "イージスを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_aegis_passive
  end

  class FinishAegisPassiveDeadCharaChangeEvent < EventRule
    dsc        "イージスを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_aegis_passive
  end

#---------------------------------------------------------------------------------------------
# 溟海符

  class CheckOceanPassiveEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_ocean_passive
  end

  class CheckOceanPassiveChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_ocean_passive
  end

  class CheckOceanPassiveDeadChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_ocean_passive
  end

  class CheckOceanPassiveDamageEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :check_ocean_passive
  end

  class FinishOceanPassiveEvent < EventRule
    dsc        "溟海符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_ocean_passive
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 スキュラ
  class CheckResistSkyllaPassiveEvent < EventRule
    dsc        "状態抵抗が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_resist_skylla_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 立ち込める夜霧

  class CheckNightFogPassiveEvent < EventRule
    dsc        "立ち込める夜霧をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_night_fog_passive
  end

  class UseNightFogPassiveEvent < EventRule
    dsc        "立ち込める夜霧を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :use_night_fog_passive
  end

  class UseNightFogPassiveDamageEvent < EventRule
    dsc        "立ち込める夜霧を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_night_fog_passive_damage
  end

  class FinishNightFogPassiveEvent < EventRule
    dsc        "立ち込める夜霧を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_night_fog_passive
  end

  class FinishNightFogPassiveDeadCharaChangeEvent < EventRule
    dsc        "立ち込める夜霧を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_night_fog_passive
  end

#---------------------------------------------------------------------------------------------
# 2つの身体(パッシブ)

  class CheckDoubleBoddyPassiveEvent < EventRule
    dsc        "2つの身体(パッシブ)をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_double_boddy_passive
  end

  class CheckDoubleBoddyPassiveChangeEvent < EventRule
    dsc        "2つの身体(パッシブ)をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_double_boddy_passive
  end

  class UseDoubleBoddyPassiveEvent < EventRule
    dsc        "2つの身体(パッシブ)を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>60
    func       :use_double_boddy_passive
  end

  class FinishDoubleBoddyPassiveEvent < EventRule
    dsc        "2つの身体(パッシブ)を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_double_boddy_passive
  end

  class FinishDoubleBoddyPassiveDeadCharaChangeEvent < EventRule
    dsc        "2つの身体(パッシブ)を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_double_boddy_passive
  end

#---------------------------------------------------------------------------------------------
# 機知

  class CheckWitPassiveEvent < EventRule
    dsc        "機知をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_wit_passive
  end

  class UseWitPassiveDrawEvent < EventRule
    dsc        "イベカをひく"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :use_wit_passive_draw
  end

  class UseWitPassiveEvent < EventRule
    dsc        "機知を発動"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_wit_passive
  end

  class FinishWitPassiveEvent < EventRule
    dsc        "機知を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_wit_passive
  end

#---------------------------------------------------------------------------------------------
# 修羅

  class CheckCurseCarePassiveEvent < EventRule
    dsc        "修羅をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_curse_care_passive
  end

  class CheckCurseCarePassiveChangeEvent < EventRule
    dsc        "修羅をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_curse_care_passive
  end

  class RecoverCurseCarePassiveDetBpBfEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :recover_curse_care_passive
  end

  class RecoverCurseCarePassiveDetBpAfEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>50
    func       :recover_curse_care_passive
  end

  class RecoverCurseCarePassiveDamageBfEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>120
    func       :recover_curse_care_passive
  end

  class RecoverCurseCarePassiveDamageAfEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :recover_curse_care_passive
  end

  class RecoverCurseCarePassiveLastEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>50
    func       :recover_curse_care_passive
  end

  class UseCurseCarePassiveEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>60
    func       :use_curse_care_passive
  end

  class FinishCurseCarePassiveEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>70
    func       :finish_curse_care_passive
  end

  class FinishCurseCarePassiveDeadCharaChangeEvent < EventRule
    dsc        "修羅を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_curse_care_passive
  end

#---------------------------------------------------------------------------------------------
# 白晄

  class CheckWhiteLightPassiveEvent < EventRule
    dsc        "白晄をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_white_light_passive
  end

  class FinishWhiteLightPassiveEvent < EventRule
    dsc        "白晄を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :finish_white_light_passive
  end

#---------------------------------------------------------------------------------------------
# 甲羅割

  class CheckCarapaceBreakPassiveEvent < EventRule
    dsc        "甲羅割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_carapace_break_passive
  end

  class CheckCarapaceBreakChangePassiveEvent < EventRule
    dsc        "甲羅割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_carapace_break_passive
  end

  class CheckCarapaceBreakDeadChangePassiveEvent < EventRule
    dsc        "甲羅割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_carapace_break_passive
  end

  class UseCarapaceBreakPassiveEvent < EventRule
    dsc        "甲羅割を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_carapace_break_passive
  end

  class FinishCarapaceBreakPassiveEvent < EventRule
    dsc        "甲羅割を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_carapace_break_passive
  end

  class FinishCarapaceBreakPassiveDeadCharaChangeEvent < EventRule
    dsc        "甲羅割を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_carapace_break_passive
  end

#---------------------------------------------------------------------------------------------
# 身隠し

  class CheckCarapacePassiveEvent < EventRule
    dsc        "身隠しをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_carapace_passive
  end

  class UseCarapacePassiveEvent < EventRule
    dsc        "身隠しを発動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_carapace_passive
  end

  class FinishCarapacePassiveEvent < EventRule
    dsc        "身隠しを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_carapace_passive
  end

  class FinishCarapacePassiveDeadCharaChangeEvent < EventRule
    dsc        "身隠しを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_carapace_passive
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 かめ
  class CheckResistKamuyPassiveEvent < EventRule
    dsc        "状態抵抗が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_resist_kamuy_passive
    goal       ["self", :use_end?]
  end

  class CheckCharaResistKamuyPassiveEvent < EventRule
    dsc        "状態抵抗を緩和"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>79
    func       :check_chara_resist_kamuy_passive
    goal       ["self", :use_end?]
  end

  class RestoreResistKamuyPassiveEvent < EventRule
    dsc        "状態抵抗を復元"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>81
    func       :restore_resist_kamuy_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# リバイザーズ

  class CheckRevisersPassiveEvent < EventRule
    dsc        "リバイザーズをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_revisers_passive
  end

  class CheckRevisersPassiveChangeEvent < EventRule
    dsc        "リバイザーズをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_revisers_passive
  end

  class CheckRevisersPassiveDeadChangeEvent < EventRule
    dsc        "リバイザーズをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_revisers_passive
  end

#---------------------------------------------------------------------------------------------
# レジストウォール
  class CheckResistWallPassiveEvent < EventRule
    dsc        "レジストウォールが可能か"
    type       :type=>:before, :obj=>"owner", :hook=>:move_phase_init_event
    func       :check_resist_wall_passive
    goal       ["self", :use_end?]
  end

  class CheckResistWallPassiveChangeEvent < EventRule
    dsc        "レジストウォールが可能か"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_resist_wall_passive
    goal       ["self", :use_end?]
  end

  class CheckResistWallPassiveDeadChangeEvent < EventRule
    dsc        "レジストウォールが可能か"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_resist_wall_passive
    goal       ["self", :use_end?]
  end

  class CheckResistWallPassiveMoveEvent < EventRule
    dsc        "レジストウォールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_resist_wall_passive_move
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 呪印符

  class CheckCurseSignPassiveEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_curse_sign_passive
  end

  class CheckCurseSignPassiveChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_curse_sign_passive
  end

  class CheckCurseSignPassiveDeadChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_curse_sign_passive
  end

  class FinishCurseSignPassiveEvent < EventRule
    dsc        "溟海符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_curse_sign_passive
  end

  class FinishCurseSignPassiveChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_curse_sign_passive
  end

  class FinishCurseSignPassiveDeadChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_curse_sign_passive
  end

#---------------------------------------------------------------------------------------------
# 従者の忠誠

  class CheckLoyaltyPassiveEvent < EventRule
    dsc        "従者の忠誠をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_loyalty_passive
  end

  class CheckLoyaltyPassiveChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_loyalty_passive
  end

  class CheckLoyaltyPassiveDeadChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_loyalty_passive
  end

  class FinishLoyaltyPassiveEvent < EventRule
    dsc        "従者の忠誠をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_loyalty_passive
  end

  class FinishLoyaltyPassiveChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :finish_loyalty_passive
  end

  class FinishLoyaltyPassiveDeadChangeEvent < EventRule
    dsc        "溟海符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_loyalty_passive
  end

#---------------------------------------------------------------------------------------------
# 精密射撃+

  class CheckAimingPlusPassiveEvent < EventRule
    dsc        "精密射撃+をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_aiming_plus_passive
  end

  class CheckAimingPlusPassiveChangeEvent < EventRule
    dsc        "精密射撃+をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_aiming_plus_passive
  end

  class UseAimingPlusPassiveEvent < EventRule
    dsc        "精密射撃+を発動"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_aiming_plus_passive
  end

  class FinishAimingPlusPassiveEvent < EventRule
    dsc        "精密射撃+を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_aiming_plus_passive
  end

  class FinishAimingPlusPassiveDeadCharaChangeEvent < EventRule
    dsc        "精密射撃+を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_aiming_plus_passive
  end

#---------------------------------------------------------------------------------------------
# AC条件緩和

  class CheckEasingCardConditionPassiveEvent < EventRule
    dsc        "精密射撃+をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_easing_card_condition_passive
  end

  class CheckEasingCardConditionPassiveChangeEvent < EventRule
    dsc        "精密射撃+をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_easing_card_condition_passive
  end

  class CheckEasingCardConditionPassiveDeadChangeEvent < EventRule
    dsc        "精密射撃+を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_easing_card_condition_passive
  end

#---------------------------------------------------------------------------------------------
# 収穫

  class CheckHarvestPassiveEvent < EventRule
    dsc        "収穫をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_harvest_passive
  end

  class FinishHarvestPassiveEvent < EventRule
    dsc        "収穫を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_harvest_passive
  end

#---------------------------------------------------------------------------------------------
# T.D.

  class CheckTdPassiveEvent < EventRule
    dsc        "T.D.をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_td_passive
  end

  class FinishTdPassiveEvent < EventRule
    dsc        "T.D.を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :finish_td_passive
  end

#---------------------------------------------------------------------------------------------
# ムーンシャイン(passive)

  class CheckMoonShinePassiveEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_moon_shine_passive
  end

  class CheckMoonShinePassiveChangeEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_moon_shine_passive
  end

  class FinishMoonShinePassiveEvent < EventRule
    dsc        "封印攻撃を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_moon_shine_passive
  end

#---------------------------------------------------------------------------------------------
# 豊穣

  class CheckFertilityPassiveEvent < EventRule
    dsc        "豊穣をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_fertility_passive
  end

  class FinishFertilityPassivePreEvent < EventRule
    dsc        "豊穣を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :finish_fertility_passive_pre
  end

  class FinishFertilityPassiveEvent < EventRule
    dsc        "豊穣を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase, :priority=>10
    func       :finish_fertility_passive
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 クエカボチャ
  class CheckResistPumpkinPassiveEvent < EventRule
    dsc        "状態抵抗が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_resist_pumpkin_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# AWCS

  class CheckAwcsPassiveEvent < EventRule
    dsc        "AWCSをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_awcs_passive
  end

  class UseAwcsPassiveDamageEvent < EventRule
    dsc        "AWCSを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_awcs_passive_damage
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 DW
  class CheckResistDwPassiveEvent < EventRule
    dsc        "DWが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_resist_dw_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ロンズブラウイベント

  class CheckLonsbroughEventPassiveEvent < EventRule
    dsc        "LONSBROUGH_EVENTをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_lonsbrough_event_passive
  end

  class CheckLonsbroughEventPassiveChangeEvent < EventRule
    dsc        "LONSBROUGH_EVENTをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_lonsbrough_event_passive
  end

  class CheckLonsbroughEventPassiveDeadChangeEvent < EventRule
    dsc        "LONSBROUGH_EVENTをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_lonsbrough_event_passive
  end

  class UseLonsbroughEventPassiveDamageEvent < EventRule
    dsc        "LONSBROUGH_EVENTを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>71
    func       :use_lonsbrough_event_passive_damage
  end

#---------------------------------------------------------------------------------------------
# 岩石割

  class CheckRockCrusherPassiveEvent < EventRule
    dsc        "岩石割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_rock_crusher_passive
  end

  class CheckRockCrusherChangePassiveEvent < EventRule
    dsc        "岩石割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_rock_crusher_passive
  end

  class CheckRockCrusherDeadChangePassiveEvent < EventRule
    dsc        "岩石割をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_rock_crusher_passive
  end

  class UseRockCrusherPassiveEvent < EventRule
    dsc        "岩石割を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_rock_crusher_passive
  end

  class FinishRockCrusherPassiveEvent < EventRule
    dsc        "岩石割を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_rock_crusher_passive
  end

  class FinishRockCrusherPassiveDeadCharaChangeEvent < EventRule
    dsc        "岩石割を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_rock_crusher_passive
  end

#---------------------------------------------------------------------------------------------
# 交錯する影

  class CheckProjectionPassiveChangeEvent < EventRule
    dsc        "交錯する影をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_projection_passive
  end

  class CheckProjectionPassiveDeadChangeEvent < EventRule
    dsc        "交錯する影をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_projection_passive
  end

  class FinishProjectionPassiveEvent < EventRule
    dsc        "交錯する影を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_projection_passive
  end

#---------------------------------------------------------------------------------------------
# ダメージ乗算

  class CheckDamageMultiplierPassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_damage_multiplier_passive
  end

  class CheckDamageMultiplierChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_damage_multiplier_passive
  end

  class CheckDamageMultiplierDeadChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_damage_multiplier_passive
  end

  class UseDamageMultiplierPassiveEvent < EventRule
    dsc        "ダメージ乗算を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_damage_multiplier_passive
  end

  class FinishDamageMultiplierPassiveEvent < EventRule
    dsc        "ダメージ乗算を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_damage_multiplier_passive
  end

  class FinishDamageMultiplierPassiveDeadCharaChangeEvent < EventRule
    dsc        "ダメージ乗算を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_damage_multiplier_passive
  end

#---------------------------------------------------------------------------------------------
# 2016,6イベント

  class CheckEv201606PassiveEvent < EventRule
    dsc        "2016,6イベントをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_ev201606_passive
  end

  class CheckEv201606ChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_ev201606_passive
  end

  class CheckEv201606DeadChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_ev201606_passive
  end

  class UseEv201606PassiveEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:after, :obj=>"foe", :hook=>:bp_calc_resolve, :priority=>15
    func       :use_ev201606_passive
  end

  class FinishEv201606PassiveEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_ev201606_passive
  end

  class FinishEv201606PassiveDeadCharaChangeEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_ev201606_passive
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 鯉
  class CheckStatusResistanceAquamarinePassiveEvent < EventRule
    dsc        "ミステイクが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_status_resistance_aquamarine_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 爽涼符

  class CheckCoolyPassiveEvent < EventRule
    dsc        "爽涼符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :check_cooly_passive
  end

  class CheckCoolyChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_cooly_passive
  end

  class CheckCoolyDeadChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_cooly_passive
  end

  class UseCoolyPassiveMoveEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_cooly_passive_move
  end

  class UseCoolyPassiveAttackEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_cooly_passive_attack
  end

  class UseCoolyPassiveDefenseEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:after, :obj=>"foe", :hook=>:attack_done_action
    func       :use_cooly_passive_defense
  end

#---------------------------------------------------------------------------------------------
# 状態抵抗 Byakhee
  class CheckResistByakheePassiveEvent < EventRule
    dsc        "DWが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_resist_byakhee_passive
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 劫火(passive)

  class CheckDisasterFlamePassiveEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_disaster_flame_passive
  end

  class CheckDisasterFlamePassiveChangeEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_disaster_flame_passive
  end

  class FinishDisasterFlamePassiveEvent < EventRule
    dsc        "封印攻撃を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_disaster_flame_passive
  end

#---------------------------------------------------------------------------------------------
# 荊棘符

  class CheckBramblesCardPassiveEvent < EventRule
    dsc        "荊棘符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_brambles_card_passive
  end

  class CheckBramblesCardPassiveChangeEvent < EventRule
    dsc        "荊棘符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_brambles_card_passive
  end

  class CheckBramblesCardPassiveDeadChangeEvent < EventRule
    dsc        "荊棘符をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_brambles_card_passive
  end

  class UseBramblesCardPassiveEvent < EventRule
    dsc        "荊棘符をチェック"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :use_brambles_card_passive
  end

  class FinishBramblesCardPassiveEvent < EventRule
    dsc        "荊棘符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_brambles_card_passive
  end

#---------------------------------------------------------------------------------------------
# 目覚めしもの

  class CheckAwakeningOnePassiveEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_awakening_one_passive
  end

  class CheckAwakeningOnePassiveChangeEvent < EventRule
    dsc        "封印攻撃をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_awakening_one_passive
  end

  class FinishAwakeningOnePassiveEvent < EventRule
    dsc        "封印攻撃を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_awakening_one_passive
  end

#---------------------------------------------------------------------------------------------
# サーボスカル

  class CheckServoSkullPassiveEvent < EventRule
    dsc        "サーボスカルをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_servo_skull_passive
  end

  class CheckServoSkullPassiveChangeEvent < EventRule
    dsc        "サーボスカルをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_servo_skull_passive
  end

  class UseServoSkullPassiveEvent < EventRule
    dsc        "サーボスカルを発動"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_servo_skull_passive
  end

  class FinishServoSkullPassiveEvent < EventRule
    dsc        "サーボスカルを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_servo_skull_passive
  end

  class FinishServoSkullPassiveDeadCharaChangeEvent < EventRule
    dsc        "サーボスカルを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_servo_skull_passive
  end

#---------------------------------------------------------------------------------------------
# 2016,12イベント

  class CheckEv201612PassiveEvent < EventRule
    dsc        "2016,12イベントをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_ev201612_passive
  end

  class CheckEv201612ChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_ev201612_passive
  end

  class UseEv201612PassiveEvent < EventRule
    dsc        "2016,12イベントを発動"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ev201612_passive
  end

  class FinishEv201612PassiveEvent < EventRule
    dsc        "2016,12イベントを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_ev201612_passive
  end

  class FinishEv201612PassiveDeadCharaChangeEvent < EventRule
    dsc        "2016,12イベントを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_ev201612_passive
  end

#---------------------------------------------------------------------------------------------
# ハイプロテクション

  class CheckHighProtectionPassiveEvent < EventRule
    dsc        "ハイプロテクションをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_high_protection_passive
  end

  class CheckHighProtectionPassiveChangeEvent < EventRule
    dsc        "ハイプロテクションをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_high_protection_passive
  end

  class UseHighProtectionPassiveEvent < EventRule
    dsc        "ハイプロテクションを発動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_high_protection_passive
  end

  class FinishHighProtectionPassiveEvent < EventRule
    dsc        "ハイプロテクションを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_high_protection_passive
  end

  class FinishHighProtectionPassiveDeadCharaChangeEvent < EventRule
    dsc        "ハイプロテクションを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_high_protection_passive
  end

#---------------------------------------------------------------------------------------------
# パペットマスター

  class CheckPuppetMasterPassiveEvent < EventRule
    dsc        "パペットマスターをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_puppet_master_passive
  end

  class CheckPuppetMasterPassiveChangeEvent < EventRule
    dsc        "パペットマスターをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_puppet_master_passive
  end

  class UsePuppetMasterPassiveEvent < EventRule
    dsc        "パペットマスターを発動"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_puppet_master_passive
  end

  class FinishPuppetMasterPassiveEvent < EventRule
    dsc        "パペットマスターを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_puppet_master_passive
  end

  class FinishPuppetMasterPassiveDeadCharaChangeEvent < EventRule
    dsc        "パペットマスターを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_puppet_master_passive
  end

#---------------------------------------------------------------------------------------------
# オーガアーム

  class CheckOgreArmPassiveEvent < EventRule
    dsc        "オーガアームをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_ogre_arm_passive
  end

  class CheckOgreArmChangePassiveEvent < EventRule
    dsc        "オーガアームをチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_ogre_arm_passive
  end

  class UseOgreArmPassiveEvent < EventRule
    dsc        "オーガアームを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_ogre_arm_passive
  end

  class FinishOgreArmPassiveEvent < EventRule
    dsc        "オーガアームを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_ogre_arm_passive
  end

  class FinishOgreArmPassiveDeadCharaChangeEvent < EventRule
    dsc        "オーガアームを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_ogre_arm_passive
  end

#---------------------------------------------------------------------------------------------
# 紅の意志

  class CheckCrimsonWillPassiveEvent < EventRule
    dsc        "紅の意志をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_crimson_will_passive
  end

  class CheckCrimsonWillPassiveChangeEvent < EventRule
    dsc        "紅の意志をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_crimson_will_passive
  end

  class UseCrimsonWillPassiveDamageEvent < EventRule
    dsc        "紅の意志を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_crimson_will_passive_damage
  end

  class FinishCrimsonWillPassiveEvent < EventRule
    dsc        "紅の意志を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_crimson_will_passive
  end

  class FinishCrimsonWillPassiveDeadCharaChangeEvent < EventRule
    dsc        "紅の意志を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_crimson_will_passive
  end


#---------------------------------------------------------------------------------------------
# 生命の守り人

  class CheckGuardianOfLifePassiveEvent < EventRule
    dsc        "生命の守り人をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :check_guardian_of_life_passive
  end

  class CheckGuardianOfLifePassiveChangeEvent < EventRule
    dsc        "生命の守り人をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_guardian_of_life_passive
  end

  class UseGuardianOfLifePassiveDefenseEvent < EventRule
    dsc        "生命の守り人を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_guardian_of_life_passive_defense
  end

  class UseGuardianOfLifePassiveAttackEvent < EventRule
    dsc        "生命の守り人を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_guardian_of_life_passive_attack
  end

  class FinishGuardianOfLifePassiveEvent < EventRule
    dsc        "生命の守り人を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_guardian_of_life_passive
  end

  class FinishGuardianOfLifePassiveDeadCharaChangeEvent < EventRule
    dsc        "生命の守り人を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_guardian_of_life_passive
  end

#---------------------------------------------------------------------------------------------
# 余焔符

  class CheckBurningEmbersPassiveEvent < EventRule
    dsc        "爽涼符をチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :check_burning_embers_passive
  end

  class CheckBurningEmbersChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_burning_embers_passive
  end

  class CheckBurningEmbersDeadChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_burning_embers_passive
  end

  class UseBurningEmbersPassiveMoveEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_burning_embers_passive_move
  end

  class UseBurningEmbersPassiveAttackEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_burning_embers_passive_attack
  end

  class UseBurningEmbersPassiveDefenseEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :use_burning_embers_passive_defense
  end

  class UseBurningEmbersPassiveDefenseDetCharaChangeEvent < EventRule
    dsc        "爽涼符を発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase , :priority=>1
    func       :use_burning_embers_passive_defense
  end

#---------------------------------------------------------------------------------------------
# 汎用

  class OnPassiveEvent < EventRule
    dsc        "パッシブがON"
    func       :on_passive
    event      :finish
  end

  class OffPassiveEvent < EventRule
    dsc        "パッシブがOFF"
    func       :off_passive
    event      :finish
  end

  # ====================
  # 状態イベント
  # ====================

  # 追加したら以下の参照番号を付加すること
  # イベントの起動チェック関数を列挙する
  CHARA_STATE_EVENT_NO =[
                    [],
                          # 0
                    [
                     :check_poison_state_event,
                     :finish_poison_state_event,
                    ],    # 毒状態
                    [
                     :check_paralysis_state_event,
                     :finish_paralysis_state_event,
                    ],    # 麻痺状態
                    [
                     :check_attack_up_state_event,
                     :finish_attack_up_state_event,
                    ],    # ATKアップ状態
                    [
                     :check_attack_down_state_event,
                     :finish_attack_down_state_event,
                    ],    # ATKダウン状態
                    [
                     :check_deffence_up_state_event,
                     :finish_deffence_up_state_event,
                    ],    # DEFアップ状態
                    [
                     :check_deffence_down_state_event,
                     :finish_deffence_down_state_event,
                    ],    # DEFダウン状態
                    [
                     :check_berserk_state_event,
                     :finish_berserk_state_event,
                    ],    # バーサーク状態
                    [
                     :check_attack_stop_state_event,
                     :check_deffence_stop_state_event,
                     :finish_stop_state_event,
                    ],    # 停止状態
                    [
                     :check_seal_state_event,
                     :finish_seal_state_event,
                    ],    # 封印状態
                    [
                     :check_dead_count_state_event,
                     :finish_dead_count_state_event,
                    ],    # 自壊状態
                    [
                     :check_undead_state_event,
                     :finish_undead_state_event,
                    ],    # 不死状態
                    [
                     :check_stone_state_event,
                     :finish_stone_state_event,
                    ],    # 石化状態
                    [
                     :check_move_up_state_event,
                     :finish_move_up_state_event,
                    ],    # MOVアップ
                    [
                     :check_move_down_state_event,
                     :finish_move_down_state_event,
                    ],    # MOVダウン
                    [
                     :check_regene_state_event,
                     :finish_regene_state_event,
                    ],    # リジェネ状態
                    [
                     :check_bind_state_event,
                     :finish_bind_state_event,
                    ],    # 呪縛状態
                    [
                     :check_chaos_attack_state_event,
                     :check_chaos_defence_state_event,
                     :finish_chaos_state_event,
                    ],    # 混沌状態
                    [
                     :check_stigmata_attack_state_event,
                     :check_stigmata_defence_state_event,
                     :finish_stigmata_state_event,
                    ],    # 聖痕状態
                    [
                     :check_state_down_attack_state_event,
                     :check_state_down_defence_state_event,
                     :finish_state_down_state_event,
                    ],    # 魔力中毒状態
                    [
                     :check_attack_stick_state_event,
                     :check_deffence_stick_state_event,
                     :finish_stick_state_event,
                    ],    # 棍術状態
                    [
                     :check_curse_attack_state_event,
                    ],    # 詛呪状態
                    [
                     :check_bless_attack_state_event,
                     :check_bless_deffence_state_event,
                    ],    # 臨界状態
                    [
                     :check_undead2_state_event,
                     :finish_undead2_state_event,
                    ],    # 不死2状態
                    [
                     :check_poison2_state_event,
                     :finish_poison2_state_event,
                    ],    # 猛毒状態
                    [
                     :check_control_state_event,
                     :finish_control_state_event,
                    ],    # 操想状態
                    [
                    ],    # 正鵠状態
                    [
                     :finish_dark_state_event,
                    ],    # 暗黒状態
                    [
                     :finish_doll_state_event,
                    ],    # 人形状態
                   ]



#---------------------------------------------------------------------------------------------
# 毒状態

  class CheckPoisonStateEvent < EventRule
    dsc        "毒状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_poison_state
#     type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
#     func       :check_poison_state
  end

  class FinishPoisonStateEvent < EventRule
    dsc        "毒状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_poison_state
  end

#---------------------------------------------------------------------------------------------
# 猛毒状態

  class CheckPoison2StateEvent < EventRule
    dsc        "毒状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_poison2_state
  end

  class FinishPoison2StateEvent < EventRule
    dsc        "毒状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_poison2_state
  end

#---------------------------------------------------------------------------------------------
# 麻痺状態

  class CheckParalysisStateEvent < EventRule
    dsc        "麻痺状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve, :priority=>50
    func       :check_paralysis_state
  end

  class FinishParalysisStateEvent < EventRule
    dsc        "麻痺状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_paralysis_state
  end

#---------------------------------------------------------------------------------------------
# ATKアップ状態

  class CheckAttackUpStateEvent < EventRule
    dsc        "ATKアップ状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>15
    func       :check_attack_up_state
  end

  class FinishAttackUpStateEvent < EventRule
    dsc        "ATKアップ状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_attack_up_state
  end


#---------------------------------------------------------------------------------------------
# ATKダウン状態

  class CheckAttackDownStateEvent < EventRule
    dsc        "ATKダウン状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>15
    func       :check_attack_down_state
  end

  class FinishAttackDownStateEvent < EventRule
    dsc        "ATKダウン状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_attack_down_state
  end


#---------------------------------------------------------------------------------------------
# DEFアップ状態

  class CheckDeffenceUpStateEvent < EventRule
    dsc        "DEFアップ状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>15
    func       :check_deffence_up_state
  end

  class FinishDeffenceUpStateEvent < EventRule
    dsc        "DEFアップ状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_deffence_up_state
  end


#---------------------------------------------------------------------------------------------
# DEFダウン状態

  class CheckDeffenceDownStateEvent < EventRule
    dsc        "ATKダウン状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>15
    func       :check_deffence_down_state
  end

  class FinishDeffenceDownStateEvent < EventRule
    dsc        "ATKダウン状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_deffence_down_state
  end


#---------------------------------------------------------------------------------------------
# バーサーク状態

  class CheckBerserkStateEvent < EventRule
    dsc        "バーサーク状態か"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :check_berserk_state
  end

  class FinishBerserkStateEvent < EventRule
    dsc        "バーサーク使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_berserk_state
  end

#---------------------------------------------------------------------------------------------
# 停止状態

  class CheckAttackStopStateEvent < EventRule
    dsc        "停止状態か"
    type       :type=>:before, :obj=>"duel", :hook=>:attack_card_drop_phase
    func       :check_attack_stop_state
  end

  class CheckDeffenceStopStateEvent < EventRule
    dsc        "停止状態か"
    type       :type=>:before, :obj=>"duel", :hook=>:deffence_card_drop_phase
    func       :check_deffence_stop_state
  end

  class FinishStopStateEvent < EventRule
    dsc        "停止の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_stop_state
  end

#---------------------------------------------------------------------------------------------
# 封印状態

  class CheckSealStateEvent < EventRule
    dsc        "封印状態か"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :check_seal_state
  end

  class FinishSealStateEvent < EventRule
    dsc        "封印の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_seal_state
  end



#---------------------------------------------------------------------------------------------
# 自壊状態

  class CheckDeadCountStateEvent < EventRule
    dsc        "自壊状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_dead_count_state
  end

  class FinishDeadCountStateEvent < EventRule
    dsc        "自壊状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_dead_count_state
  end

#---------------------------------------------------------------------------------------------
# 不死状態

  class CheckUndeadStateEvent < EventRule
    dsc        "不死状態か"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>90
    func       :check_undead_state
  end

  class FinishUndeadStateEvent < EventRule
    dsc        "不死が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_undead_state
  end

#---------------------------------------------------------------------------------------------
# 石化状態

  class CheckStoneStateEvent < EventRule
    dsc        "石化状態か"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>45
    func       :check_stone_state
  end

  class FinishStoneStateEvent < EventRule
    dsc        "石化使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_stone_state
  end

#---------------------------------------------------------------------------------------------
# MOVEアップ状態

  class CheckMoveUpStateEvent < EventRule
    dsc        "MOVEアップ状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :check_move_up_state
  end

  class FinishMoveUpStateEvent < EventRule
    dsc        "MOVEアップ状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_move_up_state
  end


#---------------------------------------------------------------------------------------------
# MOVEダウン状態

  class CheckMoveDownStateEvent < EventRule
    dsc        "MOVEダウン状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve, :priority=>10
    func       :check_move_down_state
  end

  class FinishMoveDownStateEvent < EventRule
    dsc        "MOVEダウン状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_move_down_state
  end

#---------------------------------------------------------------------------------------------
# リジェネ状態

  class CheckRegeneStateEvent < EventRule
    dsc        "リジェネ状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_regene_state
  end

  class FinishRegeneStateEvent < EventRule
    dsc        "リジェネ状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_regene_state
  end

#---------------------------------------------------------------------------------------------
# 呪縛状態

  class CheckBindStateEvent < EventRule
    dsc        "呪縛状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_bind_state
  end

  class FinishBindStateEvent < EventRule
    dsc        "呪縛状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_bind_state
  end

#---------------------------------------------------------------------------------------------
# 混沌状態

  class CheckChaosAttackStateEvent < EventRule
    dsc        "混沌状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>30
    func       :check_chaos_state
  end

  class CheckChaosDefenceStateEvent < EventRule
    dsc        "混沌状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>30
    func       :check_chaos_state
  end

  class FinishChaosStateEvent < EventRule
    dsc        "混沌状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_chaos_state
  end

#---------------------------------------------------------------------------------------------
# 聖痕

  class CheckStigmataAttackStateEvent < EventRule
    dsc        "聖痕状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>10
    func       :check_stigmata_state
  end

  class CheckStigmataDefenceStateEvent < EventRule
    dsc        "聖痕状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>10
    func       :check_stigmata_state
  end


  class FinishStigmataStateEvent < EventRule
    dsc        "聖痕状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_stigmata_state
  end

#---------------------------------------------------------------------------------------------
# 能力低下

  class CheckStateDownAttackStateEvent < EventRule
    dsc        "能力低下状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>15
    func       :check_state_down_state
  end

  class CheckStateDownDefenceStateEvent < EventRule
    dsc        "能力低下状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>15
    func       :check_state_down_state
  end

  class FinishStateDownStateEvent < EventRule
    dsc        "能力低下状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_state_down_state
  end

#---------------------------------------------------------------------------------------------
# 棍術状態

  class CheckAttackStickStateEvent < EventRule
    dsc        "棍術状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>30
    func       :check_attack_stick_state
  end

  class CheckDeffenceStickStateEvent < EventRule
    dsc        "棍術状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>30
    func       :check_deffence_stick_state
  end

  class FinishStickStateEvent < EventRule
    dsc        "棍術状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_stick_state
  end

#---------------------------------------------------------------------------------------------
# 能力低下

  class CheckStateDownAttackStateEvent < EventRule
    dsc        "能力低下状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :check_state_down_state
  end

  class CheckStateDownDefenceStateEvent < EventRule
    dsc        "能力低下状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :check_state_down_state
  end

  class FinishStateDownStateEvent < EventRule
    dsc        "能力低下状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_state_down_state
  end

#---------------------------------------------------------------------------------------------
# 詛呪

  class CheckCurseAttackStateEvent < EventRule
    dsc        "詛呪によるダメージ制限"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :check_curse_attack_state
  end

#---------------------------------------------------------------------------------------------
# 臨界

  class CheckBlessAttackStateEvent < EventRule
    dsc        "臨界の空イベント"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>10
    func       :check_bless_state
  end

  class CheckBlessDeffenceStateEvent < EventRule
    dsc        "臨界の空イベント"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>10
    func       :check_bless_state
  end

#---------------------------------------------------------------------------------------------
# 不死2状態

  class CheckUndead2StateEvent < EventRule
    dsc        "不死2状態か"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>90
    func       :check_undead2_state
  end

  class FinishUndead2StateEvent < EventRule
    dsc        "不死2が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_undead2_state
  end

#---------------------------------------------------------------------------------------------
# 操想状態

  class CheckControlStateEvent < EventRule
    dsc        "操想状態か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action
    func       :check_control_state
  end

  class FinishControlStateEvent < EventRule
    dsc        "操想状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_control_state
  end

#---------------------------------------------------------------------------------------------
# 暗黒状態
  class FinishDarkStateEvent < EventRule
    dsc        "暗黒状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_dark_state
  end

#---------------------------------------------------------------------------------------------
# 人形状態
  class FinishDollStateEvent < EventRule
    dsc        "暗黒状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_doll_state
  end


# 汎用

  class OnBuffEvent < EventRule
    dsc        "状態付加がON"
    func       :on_buff
    event      :finish
  end

  class OffBuffEvent < EventRule
    dsc        "状態付加がOFF"
    func       :off_buff
    event      :finish
  end

  class UpdateBuffEvent < EventRule
    dsc        "状態が1ターン進行"
    func       :update_buff
    event      :finish
  end

  class UpdateCatStateEvent < EventRule
    dsc        "状態が1ターン進行"
    func       :update_cat_state
    event      :finish
  end

  # ====================
  # その他のイベント
  # ====================
  CHARA_OTHER_EVENT_NO = [
                          [],
                          # 0
                          [
                           :progress_trap_event,
                           :check_started_trap_det_bp_before_event,
                           :check_started_trap_det_bp_event,
                           :check_started_trap_battle_result_event,
                           :check_started_trap_damage_event,
                           :check_started_trap_finish_move_event,
                           :check_started_trap_det_change_event,
                          ],    # トラップチェック
                          [
                           :check_barrier_state_event,
                          ],    # 無敵状態
                          [
                           :check_harbour_event,
                          ],    # かばわれ状態
                          [
                           :check_field_status_finish_turn_event,
                          ],    # フィールド状態チェック
                         ]

#---------------------------------------------------------------------------------------------
# トラップチェック

  class ProgressTrapEvent < EventRule
    dsc        "ターンの最後に自身のトラップの状態を進行させる"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :progress_trap
  end

  class CheckStartedTrapDetBpBeforeEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>99
    func       :open_trap_check
  end

  class CheckStartedTrapDetBpEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>99
    func       :open_trap_check
  end

  class CheckStartedTrapBattleResultEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase
    func       :open_trap_check
  end

  class CheckStartedTrapDamageEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :open_trap_check
  end

  class CheckStartedTrapFinishMoveEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :open_trap_check
  end

  class CheckStartedTrapDetChangeEvent < EventRule
    dsc        "フェーズ後の更新"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :open_trap_check
  end

#---------------------------------------------------------------------------------------------
# 結界

  class CheckBarrierStateEvent < EventRule
    dsc        "結界による無敵状態イベント"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :check_barrier_state
  end

#---------------------------------------------------------------------------------------------
# かばわれ状態

  class CheckHarbourEvent < EventRule
    dsc        "かばわれによるダメージ無効化イベント"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :check_harbour
  end

#---------------------------------------------------------------------------------------------
# フィールド状態の自動アップデート

  class CheckFieldStatusDetChangeEvent < EventRule
    dsc        "フェイズ前のエイリアス設定"
    type       :type=>:after, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :check_field_status_det_change
  end

  class CheckFieldStatusPlDiceAttrEvent < EventRule
    dsc        "CC後のエイリアス設定"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action
    func       :check_field_status_dice_attr
  end

  class CheckFieldStatusFoeDiceAttrEvent < EventRule
    dsc        "CC後のエイリアス設定"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_done_action
    func       :check_field_status_dice_attr
  end

  class CheckFieldStatusFinishTurnEvent < EventRule
    dsc        "ターンの最後に状態更新"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :check_field_status_finish_turn
  end

#---------------------------------------------------------------------------------------------
# アクションカードのリセット

  # class ClearRewritenValueStartTurnEvent < EventRule
  #   dsc        "レイドボス用のクリア"
  #   type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
  #   func       :clear_rewriten_value_start_turn
  # end

  # アイコンとして表示しない、解除不可能な状態異常。技無効化等で解除される
  CHARA_SPECIAL_STATE_EVENT_NO =[
                    [],
                          # 0
                    [
                     :check_cat_state_attack_event,
                     :check_cat_state_defence_event,
                     :finish_cat_state_event,
                    ],    # 1 猫状態
                    [
                    ],    # 2 アンチセプチック 実体は技の内部で実装
                    [
                    ],    # 3 シャープンエッジ状態 実体は技の方で実装
                    [
                    ],    # 4 控えでダメージ無効 フラグとして使う
                    [
                     :check_dealing_restriction_state_event,
                     :finish_dealing_restriction_state_event,
                    ],    # 5 一時的なドロー枚数制限状態
                    [
                     :check_constraint_state_event,
                     :finish_constraint_state_event,
                    ],    # 6 行動制限状態
                    [
                    ],    # 7 ダメージ追加常態 技の方で実装
                    [
                    ],    # 8 スキル上書き状態 技の方で実装
                    [
                     :finish_magnetic_field_state_event,
                    ],    # 9 スキル移動禁止 終了チェック
                    [
                    ],    # 10 固定ダメージカウンター ワザの方で実装
                    [
                     :check_stuffed_toys_state_damage_event,
                     :finish_stuffed_toys_state_damage_event,
                    ],    # 11 ヌイグルミ
                    [
                     :use_monitoring_state_heal_before_event,
                     :use_monitoring_state_party_heal_before_event,
                     :use_monitoring_state_heal_after_event,
                     :use_monitoring_state_party_heal_after_event,
                     :finish_monitoring_state_event,
                    ],    # 12 監視 終了チェック
                    [
                     :finish_time_lag_draw_state_event,
                    ],    # 13 時差ドロー 終了チェック
                    [
                     :finish_time_lag_buff_state_change_event,
                    ],    # 14 時差バフ 終了チェック
                    [
                     :check_machine_cell_state_event,
                     :use_machine_cell_state_event,
                     :finish_machine_cell_state_event,
                    ],    # 15 マシンセル 終了チェック Rエイダ
                    [
                     :check_ax_guard_state_event,
                     :use_ax_guard_state_event,
                     :finish_ax_guard_state_event,
                    ],    # 16 アクスガード 終了チェック Rフロレ
                                ]

#---------------------------------------------------------------------------------------------
# 猫状態

  class CheckCatStateAttackEvent < EventRule
    dsc        "攻撃力固定 この後に聖痕・ATK補正を加算する"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>5
    func       :check_cat_state_attack
  end

  class CheckCatStateDefenceEvent < EventRule
    dsc        "防御力固定 この期に聖痕・DEF補正を計算する"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>5
    func       :check_cat_state_defence
  end

  class FinishCatStateEvent < EventRule
    dsc        "MOVEアップ状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_cat_state
  end

#---------------------------------------------------------------------------------------------
# 一時的な手札制限

  class CheckDealingRestrictionStateEvent < EventRule
    dsc        "ヴンダーカンマーが可能か"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_dealing_restriction_state
  end

  class FinishDealingRestrictionStateEvent < EventRule
    dsc        "ヴンダーカンマーが可能か"
    type       :type=>:after, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :finish_dealing_restriction_state
  end

#---------------------------------------------------------------------------------------------
# 行動制限状態

  class CheckConstraintStateEvent < EventRule
    dsc        "コンストレイント状態チェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_constraint_state
  end

  class FinishConstraintStateEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_constraint_state
  end

#---------------------------------------------------------------------------------------------
# 磁場状態 スキルによる移動禁止

  class FinishMagneticFieldStateEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_magnetic_field_state
  end

#---------------------------------------------------------------------------------------------
# ヌイグルミ

  class CheckStuffedToysStateDamageEvent < EventRule
    dsc        "追加攻撃"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priorit=>10
    func       :check_stuffed_toys_state_damage
  end

  class FinishStuffedToysStateDamageEvent < EventRule
    dsc        "追加攻撃"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :finish_stuffed_toys_state_damage
  end

  class StuffedToysSetEvent < EventRule
    dsc        "クライアント表示"
    func       :stuffed_toys_set
    event      :finish
  end

#---------------------------------------------------------------------------------------------
# 監視状態の終了チェック

  class UseMonitoringStateHealBeforeEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:before, :obj=>"owner", :hook=>:healed_event
    func       :use_monitoring_state_before_check
  end

  class UseMonitoringStateHealAfterEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"owner", :hook=>:healed_event
    func       :use_monitoring_state_after_check
  end

  class UseMonitoringStatePartyHealBeforeEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:before, :obj=>"owner", :hook=>:party_healed_event
    func       :use_monitoring_state_before_check
  end

  class UseMonitoringStatePartyHealAfterEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"owner", :hook=>:party_healed_event
    func       :use_monitoring_state_after_check
  end

  class FinishMonitoringStateEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase, :priority=>60
    func       :finish_monitoring_state
  end

#---------------------------------------------------------------------------------------------
# 時差ドロー状態の終了チェック

  class FinishTimeLagDrawStateEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"owner", :hook=>:set_initiative_event, :priority=>10
    func       :finish_time_lag_draw_state
  end

#---------------------------------------------------------------------------------------------
# 時差バフ状態の終了チェック

  class FinishTimeLagBuffStateChangeEvent < EventRule
    dsc        "コンストレイント終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :finish_time_lag_buff_state
  end

#---------------------------------------------------------------------------------------------
# マシンセル状態 Rエイダ

  class CheckMachineCellStateEvent < EventRule
    dsc        "使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event
    func       :check_machine_cell_state
  end

  class UseMachineCellStateEvent < EventRule
    dsc        "使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_machine_cell_state
  end

  class FinishMachineCellStateEvent < EventRule
    dsc        "終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_machine_cell_state
  end

#---------------------------------------------------------------------------------------------
# アクスガード状態 Rエイダ

  class CheckAxGuardStateEvent < EventRule
    dsc        "使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event
    func       :check_ax_guard_state
  end

  class UseAxGuardStateEvent < EventRule
    dsc        "使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_ax_guard_state
  end

  class FinishAxGuardStateEvent < EventRule
    dsc        "終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_ax_guard_state
  end




  # ====================
  # イベント
  # ====================

  # 追加したら以下の参照番号を付加すること
  # イベントの起動チェック関数を列挙する
  CHARA_FEAT_EVENT_NO =[
                    nil,
                        # 0
                    [
                     :check_add_smash_feat_event,
                     :check_remove_smash_feat_event,
                     :check_rotate_smash_feat_event,
                     :use_smash_feat_event,
                     :finish_smash_feat_event,
                    ],    # 1
                    [
                     :check_add_aiming_feat_event,
                     :check_remove_aiming_feat_event,
                     :check_rotate_aiming_feat_event,
                     :use_aiming_feat_event,
                     :finish_aiming_feat_event,
                    ],    # 2
                    [
                     :check_add_strike_feat_event,
                     :check_remove_strike_feat_event,
                     :check_rotate_strike_feat_event,
                     :use_strike_feat_event,
                     :use_strike_feat_damage_event,
                     :finish_strike_feat_event,
                    ],    # 3
                    [
                     :check_add_combo_feat_event,
                     :check_remove_combo_feat_event,
                     :check_rotate_combo_feat_event,
                     :use_combo_feat_event,
                     :finish_combo_feat_event,
                    ],
                        # 4
                    [:check_add_thorn_feat_event,
                     :check_remove_thorn_feat_event,
                     :check_rotate_thorn_feat_event,
                     :use_thorn_feat_event,
                     :use_thorn_feat_damage_event,
                     :finish_thorn_feat_event,
                    ],
                        # 5
                    [:check_add_charge_feat_event,
                     :check_remove_charge_feat_event,
                     :check_rotate_charge_feat_event,
                     :use_charge_feat_event,
                     :finish_charge_feat_event,
                    ],
                        # 6
                    [:check_add_mirage_feat_event,
                     :check_remove_mirage_feat_event,
                     :check_rotate_mirage_feat_event,
                     :check_move_mirage_feat_event,
                     :use_mirage_feat_event,
                     :finish_mirage_feat_event,
                    ],
                        # 7
                    [:check_add_frenzy_eyes_feat_event,
                     :check_remove_frenzy_eyes_feat_event,
                     :check_rotate_frenzy_eyes_feat_event,
                     :use_frenzy_eyes_feat_event,
                     :use_frenzy_eyes_feat_damage_event,
                     :finish_frenzy_eyes_feat_event,
                    ],
                        # 8 狂気の眼窩
                    [:check_add_abyss_feat_event,
                     :check_remove_abyss_feat_event,
                     :check_rotate_abyss_feat_event,
                     :use_abyss_feat_event,
                     :finish_abyss_feat_event,
                    ],
                        # 9 深淵
                    [:check_add_rapid_sword_feat_event,
                     :check_remove_rapid_sword_feat_event,
                     :check_rotate_rapid_sword_feat_event,
                     :use_rapid_sword_feat_event,
                     :finish_rapid_sword_feat_event,
                    ],
                        # 10 神速の剣
                    [:check_add_anger_feat_event,
                     :check_remove_anger_feat_event,
                     :check_rotate_anger_feat_event,
                     :use_anger_feat_event,
                     :finish_anger_feat_event,
                    ],
                        # 11 怒りの一撃
                    [:check_add_power_stock_feat_event,
                     :check_remove_power_stock_feat_event,
                     :check_rotate_power_stock_feat_event,
                     :finish_power_stock_feat_event,
                    ],
                        # 12 必殺の構え
                    [:check_add_shadow_shot_feat_event,
                     :check_remove_shadow_shot_feat_event,
                     :check_rotate_shadow_shot_feat_event,
                     :use_shadow_shot_feat_event,
                     :use_shadow_shot_feat_damage_event,
                     :finish_shadow_shot_feat_event,
                    ],
                        # 13 影撃ち
                    [:check_add_red_fang_feat_event,
                     :check_remove_red_fang_feat_event,
                     :check_rotate_red_fang_feat_event,
                     :use_red_fang_feat_event,
                     :use_red_fang_feat_damage_event,
                     :finish_red_fang_feat_event,
                    ],
                        # 14
                    [:check_add_blessing_blood_feat_event,
                     :check_remove_blessing_blood_feat_event,
                     :check_rotate_blessing_blood_feat_event,
                     :use_blessing_blood_feat_event,
                     :use_blessing_blood_feat_damage_event,
                     :finish_blessing_blood_feat_event,
                    ],
                        # 15
                    [:check_add_counter_preparation_feat_event,
                     :check_remove_counter_preparation_feat_event,
                     :check_rotate_counter_preparation_feat_event,
                     :use_counter_preparation_feat_damage_event,
                     :finish_counter_preparation_feat_event,
                    ],
                        # 16
                    [:check_add_karmic_time_feat_event,
                     :check_remove_karmic_time_feat_event,
                     :check_rotate_karmic_time_feat_event,
                     :use_karmic_time_feat_event,
                     :finish_chara_change_karmic_time_feat_event,
                     :finish_foe_chara_change_karmic_time_feat_event,
                    ],
                        # 17
                    [:check_add_karmic_ring_feat_event,
                     :check_remove_karmic_ring_feat_event,
                     :check_rotate_karmic_ring_feat_event,
                     :use_karmic_ring_feat_event,
                     :finish_karmic_ring_feat_event,
                    ],
                        # 18 因果の輪
                    [:check_add_karmic_string_feat_event,
                     :check_remove_karmic_string_feat_event,
                     :check_rotate_karmic_string_feat_event,
                     :use_karmic_string_feat_event,
                    ],
                        # 19
                    [
                     :check_add_hi_smash_feat_event,
                     :check_remove_hi_smash_feat_event,
                     :check_rotate_hi_smash_feat_event,
                     :use_hi_smash_feat_event,
                     :finish_hi_smash_feat_event,
                    ],
                        # 20
                    [
                     :check_add_hi_power_stock_feat_event,
                     :check_remove_hi_power_stock_feat_event,
                     :check_rotate_hi_power_stock_feat_event,
                     :finish_hi_power_stock_feat_event,
                    ],
                        # 21
                    [
                     :check_add_hi_aiming_feat_event,
                     :check_remove_hi_aiming_feat_event,
                     :check_rotate_hi_aiming_feat_event,
                     :use_hi_aiming_feat_event,
                     :finish_hi_aiming_feat_event,
                    ],
                        # 22
                    [:check_add_hi_rapid_sword_feat_event,
                     :check_remove_hi_rapid_sword_feat_event,
                     :check_rotate_hi_rapid_sword_feat_event,
                     :use_hi_rapid_sword_feat_event,
                     :finish_hi_rapid_sword_feat_event,
                    ],
                        # 23
                    [:check_add_hi_karmic_string_feat_event,
                     :check_remove_hi_karmic_string_feat_event,
                     :check_rotate_hi_karmic_string_feat_event,
                     :use_hi_karmic_string_feat_event,
                    ],
                        # 24
                    [:check_add_hi_frenzy_eyes_feat_event,
                     :check_remove_hi_frenzy_eyes_feat_event,
                     :check_rotate_hi_frenzy_eyes_feat_event,
                     :use_hi_frenzy_eyes_feat_event,
                     :use_hi_frenzy_eyes_feat_damage_event,
                     :finish_hi_frenzy_eyes_feat_event,
                    ],
                        # 25
                    [:check_add_hi_shadow_shot_feat_event,
                     :check_remove_hi_shadow_shot_feat_event,
                     :check_rotate_hi_shadow_shot_feat_event,
                     :use_hi_shadow_shot_feat_event,
                     :use_hi_shadow_shot_feat_damage_event,
                     :finish_hi_shadow_shot_feat_event,
                    ],
                        # 26
                    [:check_add_land_mine_feat_event,
                     :check_remove_land_mine_feat_event,
                     :check_rotate_land_mine_feat_event,
                     :use_land_mine_feat_event,
                    ],
                        # 27 地雷
                    [
                     :check_add_desperado_feat_event,
                     :check_remove_desperado_feat_event,
                     :check_rotate_desperado_feat_event,
                     :use_desperado_feat_event,
                     :finish_desperado_feat_event,
                    ],
                        # 28
                    [
                     :check_add_reject_sword_feat_event,
                     :check_remove_reject_sword_feat_event,
                     :check_rotate_reject_sword_feat_event,
                     :use_reject_sword_feat_event,
                     :finish_reject_sword_feat_event,
                    ],
                        # 29
                    [
                     :check_add_counter_guard_feat_event,
                     :check_remove_counter_guard_feat_event,
                     :check_rotate_counter_guard_feat_event,
                     :use_counter_guard_feat_event,
                     :use_counter_guard_feat_dice_attr_event,
                     :finish_counter_guard_feat_event,
                    ],
                        # 30 カウンターガード
                    [
                     :check_add_pain_flee_feat_event,
                     :check_remove_pain_flee_feat_event,
                     :check_rotate_pain_flee_feat_event,
                     :finish_pain_flee_feat_event,
                    ],
                        # 31
                    [
                     :check_add_body_of_light_feat_event,
                     :check_remove_body_of_light_feat_event,
                     :check_rotate_body_of_light_feat_event,
                     :use_body_of_light_feat_event,
                     :finish_body_of_light_feat_event,
                    ],
                        # 32 光の移し身
                    [:check_add_seal_chain_feat_event,
                     :check_remove_seal_chain_feat_event,
                     :check_rotate_seal_chain_feat_event,
                     :use_seal_chain_feat_event,
                     :use_seal_chain_feat_damage_event,
                     :finish_seal_chain_feat_event,
                    ],
                        # 33 封印の鎖
                    [
                     :check_add_purification_light_feat_event,
                     :check_remove_purification_light_feat_event,
                     :check_rotate_purification_light_feat_event,
                     :use_purification_light_feat_event,
                     :use_purification_light_feat_damage_event,
                     :finish_purification_light_feat_event,
                    ],
                        # 34
                    [:check_add_craftiness_feat_event,
                     :check_remove_craftiness_feat_event,
                     :check_rotate_craftiness_feat_event,
                     :finish_craftiness_feat_event,
                    ],
                        # 35 知略
                    [:check_add_land_bomb_feat_event,
                     :check_remove_land_bomb_feat_event,
                     :check_rotate_land_bomb_feat_event,
                     :use_land_bomb_feat_event,
                    ],
                        # 36 地雷2
                    [
                     :check_add_reject_blade_feat_event,
                     :check_remove_reject_blade_feat_event,
                     :check_rotate_reject_blade_feat_event,
                     :use_reject_blade_feat_event,
                     :finish_reject_blade_feat_event,
                    ],
                        # 37 リジェクトブレイド
                    [
                     :check_add_spell_chain_feat_event,
                     :check_remove_spell_chain_feat_event,
                     :check_rotate_spell_chain_feat_event,
                     :use_spell_chain_feat_event,
                     :use_spell_chain_feat_damage_event,
                     :finish_spell_chain_feat_event,
                    ],
                        # 38 呪縛の鎖
                    [
                     :check_add_indomitable_mind_feat_event,
                     :check_remove_indomitable_mind_feat_event,
                     :check_rotate_indomitable_mind_feat_event,
                     :use_indomitable_mind_feat_event,
                     :use_indomitable_mind_feat_damage_event,
                     :finish_indomitable_mind_feat_event,
                     :finish_indomitable_mind_feat_dead_chara_change_event,
                    ],
                        # 39 不屈の心
                    [
                     :check_add_drain_soul_feat_event,
                     :check_remove_drain_soul_feat_event,
                     :check_rotate_drain_soul_feat_event,
                     :use_drain_soul_feat_event,
                    ],
                        # 40 精神力吸収
                    [
                     :check_add_back_stab_feat_event,
                     :check_remove_back_stab_feat_event,
                     :check_rotate_back_stab_feat_event,
                     :use_back_stab_feat_event,
                     :finish_back_stab_feat_event,
                    ],
                        # 41 バックスタブ
                    [
                     :check_add_enlightened_feat_event,
                     :check_remove_enlightened_feat_event,
                     :check_rotate_enlightened_feat_event,
                     :use_enlightened_feat_event,
                    ],
                        # 42 見切り
                    [
                     :check_add_dark_whirlpool_feat_event,
                     :check_remove_dark_whirlpool_feat_event,
                     :check_rotate_dark_whirlpool_feat_event,
                     :use_dark_whirlpool_feat_event,
                     :use_dark_whirlpool_feat_damage_event,
                    ],
                        # 43 暗黒の渦
                    [
                     :check_add_karmic_phantom_feat_event,
                     :check_remove_karmic_phantom_feat_event,
                     :check_rotate_karmic_phantom_feat_event,
                     :use_karmic_phantom_feat_event,
                     :finish_karmic_phantom_feat_event,
                    ],
                        # 44 因果の幻
                    [
                     :check_add_recovery_wave_feat_event,
                     :check_remove_recovery_wave_feat_event,
                     :check_rotate_recovery_wave_feat_event,
                     :finish_recovery_wave_feat_event,
                    ],
                        # 45 治癒の波動
                    [
                     :check_add_self_destruction_feat_event,
                     :check_remove_self_destruction_feat_event,
                     :check_rotate_self_destruction_feat_event,
                     :finish_self_destruction_feat_event,
                    ],
                        # 46 自爆
                    [
                     :check_add_deffence_shooting_feat_event,
                     :check_remove_deffence_shooting_feat_event,
                     :check_rotate_deffence_shooting_feat_event,
                     :use_deffence_shooting_feat_event,
                     :use_deffence_shooting_feat_damage_event,
                    ],
                        # 47 防護射撃
                    [
                     :check_add_recovery_feat_event,
                     :check_remove_recovery_feat_event,
                     :check_rotate_recovery_feat_event,
                     :finish_recovery_feat_event,
                    ],
                        # 48 再生
                    [
                     :check_add_shadow_attack_feat_event,
                     :check_remove_shadow_attack_feat_event,
                     :check_rotate_shadow_attack_feat_event,
                     :use_shadow_attack_feat_event,
                     :finish_shadow_attack_feat_event,
                    ],
                        # 49 幻影
                    [
                     :check_add_suicidal_tendencies_feat_event,
                     :check_remove_suicidal_tendencies_feat_event,
                     :check_rotate_suicidal_tendencies_feat_event,
                     :use_suicidal_tendencies_feat_event,
                     :finish_suicidal_tendencies_feat_event,
                    ],
                        # 50 スーサイダルテンデンシー
                    [:check_add_misfit_feat_event,
                     :check_remove_misfit_feat_event,
                     :check_rotate_misfit_feat_event,
                     :use_misfit_feat_event,
                     :use_misfit_feat_damage_event,
                     :finish_misfit_feat_event,
                    ],
                        # 51 ミスフィット
                    [:check_add_big_bragg_feat_event,
                     :check_remove_big_bragg_feat_event,
                     :check_rotate_big_bragg_feat_event,
                     :finish_big_bragg_feat_event,
                    ],
                        # 52 ビッグブラッグ
                    [
                     :check_add_lets_knife_feat_event,
                     :check_remove_lets_knife_feat_event,
                     :check_rotate_lets_knife_feat_event,
                     :use_lets_knife_feat_event,
                     :finish_lets_knife_feat_event,
                    ],
                        # 53 レッツナイフ
                    [
                     :check_add_single_heart_feat_event,
                     :check_remove_single_heart_feat_event,
                     :check_rotate_single_heart_feat_event,
                     :use_single_heart_feat_event,
                    ],
                        # 54 1つの心
                    [
                     :check_add_double_body_feat_event,
                     :check_remove_double_body_feat_event,
                     :check_rotate_double_body_feat_event,
                     :use_double_body_feat_event,
                     :use_double_body_feat_damage_event,
                     :finish_double_body_feat_event,
                    ],
                        # 55 2つの身体
                    [:check_add_nine_soul_feat_event,
                     :check_remove_nine_soul_feat_event,
                     :check_rotate_nine_soul_feat_event,
                     :use_nine_soul_feat_event,
                     :finish_nine_soul_feat_event,
                    ],
                        # 56 9つの魂

                    [
                     :check_add_thirteen_eyes_feat_event,
                     :check_remove_thirteen_eyes_feat_event,
                     :check_rotate_thirteen_eyes_feat_event,
                     :use_owner_thirteen_eyes_feat_event,
                     :use_foe_thirteen_eyes_feat_event,
                     :finish_thirteen_eyes_feat_event,
                     :use_thirteen_eyes_feat_damage_event,
                    ],
                        # 57 13の眼
                    [:check_add_life_drain_feat_event,
                     :check_remove_life_drain_feat_event,
                     :check_rotate_life_drain_feat_event,
                     :use_life_drain_feat_event,
                     :use_life_drain_feat_damage_event,
                     :finish_life_drain_feat_event,
                    ],
                        # 58 ライフドレイン
                    [:check_add_random_curse_feat_event,
                     :check_remove_random_curse_feat_event,
                     :check_rotate_random_curse_feat_event,
                     :use_random_curse_feat_event,
                     :use_random_curse_feat_damage_event,
                     :finish_random_curse_feat_event,
                    ],
                        # 59 ランダムカース
                    [:check_add_heal_voice_feat_event,
                     :check_remove_heal_voice_feat_event,
                     :check_rotate_heal_voice_feat_event,
                     :use_heal_voice_feat_event,
                     :finish_heal_voice_feat_event,
                    ],
                        # 60 癒しの声
                    [
                     :check_add_double_attack_feat_event,
                     :check_remove_double_attack_feat_event,
                     :check_rotate_double_attack_feat_event,
                     :use_double_attack_feat_event,
                     :finish_double_attack_feat_event,
                    ],
                        # 61 ダブルアタック
                    [
                     :check_add_party_damage_feat_event,
                     :check_remove_party_damage_feat_event,
                     :check_rotate_party_damage_feat_event,
                     :use_party_damage_feat_event,
                     :finish_party_damage_feat_event,
                    ],
                        # 62 全体攻撃
                    [
                     :check_add_guard_feat_event,
                     :check_remove_guard_feat_event,
                     :check_rotate_guard_feat_event,
                     :use_guard_feat_event,
                     :use_guard_feat_damage_event,
                     :finish_guard_feat_event,
                    ],
                        # 63 ダメージ軽減

                    [
                     :check_add_death_control_feat_event,
                     :check_remove_death_control_feat_event,
                     :check_rotate_death_control_feat_event,
                     :use_death_control_feat_event,
                     :use_death_control_feat_damage_event,
                     :finish_death_control_feat_event,
                    ],
                        # 64 自壊攻撃
                    [
                     :check_add_wit_feat_event,
                     :check_remove_wit_feat_event,
                     :check_rotate_wit_feat_event,
                     :use_wit_feat_event,
                     :finish_wit_feat_event,
                    ],
                        # 65 機知
                    [
                     :check_add_thorn_care_feat_event,
                     :check_remove_thorn_care_feat_event,
                     :check_rotate_thorn_care_feat_event,
                     :use_thorn_care_feat_event,
                     :use_thorn_care_feat_damage_event,
                     :finish_thorn_care_feat_event,
                    ],
                        # 66 茨の構え
                    [
                     :check_add_liberating_sword_feat_event,
                     :check_remove_liberating_sword_feat_event,
                     :check_rotate_liberating_sword_feat_event,
                     :use_liberating_sword_feat_event,
                     :use_liberating_sword_feat_damage_event,
                     :finish_liberating_sword_feat_event,
                    ],
                        # 67 解放剣
                    [
                     :check_add_one_slash_feat_event,
                     :check_remove_one_slash_feat_event,
                     :check_rotate_one_slash_feat_event,
                     :use_one_slash_feat_event,
                     :use_one_slash_feat_damage_event,
                     :finish_one_slash_feat_event,
                    ],
                        # 68 一閃
                    [
                     :check_add_ten_slash_feat_event,
                     :check_remove_ten_slash_feat_event,
                     :check_rotate_ten_slash_feat_event,
                     :use_ten_slash_feat_event,
                     :finish_ten_slash_feat_event,
                    ],
                        # 69 十閃
                    [
                     :check_add_handled_slash_feat_event,
                     :check_remove_handled_slash_feat_event,
                     :check_rotate_handled_slash_feat_event,
                     :use_handled_slash_feat_event,
                     :use_handled_slash_feat_damage_event,
                     :finish_handled_slash_feat_event,
                    ],
                        # 70 百閃
                    [
                     :check_add_curse_care_feat_event,
                     :check_remove_curse_care_feat_event,
                     :check_rotate_curse_care_feat_event,
                     :use_curse_care_feat_event,
                     :use_curse_care_feat_damage_event,
                     :use_curse_care_feat_heal1_event,
                     :use_curse_care_feat_heal2_event,
                     :use_curse_care_feat_heal3_event,
                     :use_curse_care_feat_heal_det_bp_event,
                    ],
                        # 71 修羅の構え
                    [
                     :check_add_moon_shine_feat_event,
                     :check_remove_moon_shine_feat_event,
                     :check_rotate_moon_shine_feat_event,
                     :use_moon_shine_feat_event,
                     :finish_moon_shine_feat_event,
                    ],
                        # 72 ムーンシャイン
                    [
                     :check_add_rapture_feat_event,
                     :check_remove_rapture_feat_event,
                     :check_rotate_rapture_feat_event,
                     :use_rapture_feat_event,
                     :use_rapture_feat_damage_event,
                     :finish_rapture_feat_event,
                    ],
                        # 73 ラプチュア
                    [
                     :check_add_doomsday_feat_event,
                     :check_remove_doomsday_feat_event,
                     :check_rotate_doomsday_feat_event,
                     :finish_doomsday_feat_event,
                    ],
                        # 74 ドゥームスデイ
                    [
                     :check_add_hell_feat_event,
                     :check_remove_hell_feat_event,
                     :check_rotate_hell_feat_event,
                     :finish_hell_feat_event,
                    ],
                        # 75 hellboundheart
                    [
                     :check_add_awaking_feat_event,
                     :check_remove_awaking_feat_event,
                     :check_rotate_awaking_feat_event,
                     :finish_awaking_feat_event,
                    ],
                        # 76 スーパーヒロイン
                    [
                     :check_add_moving_one_feat_event,
                     :check_remove_moving_one_feat_event,
                     :check_rotate_moving_one_feat_event,
                     :use_moving_one_feat_event,
                     :finish_moving_one_feat_event,
                    ],
                        # 77 近距離移動
                    [
                     :check_add_arrogant_one_feat_event,
                     :check_remove_arrogant_one_feat_event,
                     :check_rotate_arrogant_one_feat_event,
                     :use_arrogant_one_feat_event,
                     :finish_arrogant_one_feat_event,
                    ],
                        # 78 下位防御
                    [
                     :check_add_eating_one_feat_event,
                     :check_remove_eating_one_feat_event,
                     :check_rotate_eating_one_feat_event,
                     :use_eating_one_feat_event,
                     :finish_eating_one_feat_event,
                    ],
                        # 79 食らうもの
                    [
                     :check_add_reviving_one_feat_event,
                     :check_remove_reviving_one_feat_event,
                     :check_rotate_reviving_one_feat_event,
                     :finish_reviving_one_feat_event,
                    ],
                        # 80 蘇るもの
                    [:check_add_white_light_feat_event,
                     :check_remove_white_light_feat_event,
                     :check_rotate_white_light_feat_event,
                     :finish_white_light_feat_event,
                    ],
                        # 81 ホワイトライト
                    [:check_add_crystal_shield_feat_event,
                     :check_remove_crystal_shield_feat_event,
                     :check_rotate_crystal_shield_feat_event,
                     :use_crystal_shield_feat_event,
                     :use_after_crystal_shield_feat_event,
                     :finish_crystal_shield_feat_event,
                    ],
                        # 82 クリスタル・M
                    [
                     :check_add_snow_balling_feat_event,
                     :check_remove_snow_balling_feat_event,
                     :check_rotate_snow_balling_feat_event,
                     :use_snow_balling_feat_event,
                     :use_snow_balling_feat_damage_event,
                     :use_snow_balling_feat_const_damage_event,
                     :finish_snow_balling_feat_event,
                    ],
                        # 83 スノーボーリング
                    [
                     :check_add_solvent_rain_feat_event,
                     :check_remove_solvent_rain_feat_event,
                     :check_rotate_solvent_rain_feat_event,
                     :use_solvent_rain_feat_event,
                     :finish_solvent_rain_feat_event,
                    ],
                        # 84 ソルベント・レイン
                    [
                     :check_add_awaking_door_feat_event,
                     :check_remove_awaking_door_feat_event,
                     :check_rotate_awaking_door_feat_event,
                     :finish_awaking_door_feat_event,
                    ],
                        # 85 知覚の扉
                    [
                     :check_add_over_dose_feat_event,
                     :check_remove_over_dose_feat_event,
                     :check_rotate_over_dose_feat_event,
                     :use_over_dose_feat_event,
                     :finish_over_dose_feat_event,
                    ],
                        # 86 オーバードウズ

                    [
                     :check_add_razors_edge_feat_event,
                     :check_remove_razors_edge_feat_event,
                     :check_rotate_razors_edge_feat_event,
                     :use_owner_razors_edge_feat_event,
                     :use_foe_razors_edge_feat_event,
                     :use_razors_edge_feat_dice_attr_event,
                     :finish_razors_edge_feat_event,
                    ],
                        # 87 レイザーズエッジ
                    [
                     :check_add_hells_bell_feat_event,
                     :check_remove_hells_bell_feat_event,
                     :check_rotate_hells_bell_feat_event,
                     :finish_hells_bell_feat_event,
                    ],
                        # 88 ヘルズベル
                    [
                     :check_add_drain_seed_feat_event,
                     :check_remove_drain_seed_feat_event,
                     :check_rotate_drain_seed_feat_event,
                     :finish_drain_seed_feat_event,
                    ],
                        # 89 ドレインシード
                    [
                     :check_add_atk_drain_feat_event,
                     :check_remove_atk_drain_feat_event,
                     :check_rotate_atk_drain_feat_event,
                     :finish_atk_drain_feat_event,
                    ],
                        # 90 攻撃吸収
                    [
                     :check_add_def_drain_feat_event,
                     :check_remove_def_drain_feat_event,
                     :check_rotate_def_drain_feat_event,
                     :finish_def_drain_feat_event,
                    ],
                        # 91 防御吸収
                    [
                     :check_add_mov_drain_feat_event,
                     :check_remove_mov_drain_feat_event,
                     :check_rotate_mov_drain_feat_event,
                     :finish_mov_drain_feat_event,
                    ],
                        # 92 移動吸収
                    [
                     :check_add_poison_skin_feat_event,
                     :check_remove_poison_skin_feat_event,
                     :check_rotate_poison_skin_feat_event,
                     :use_poison_skin_feat_event,
                     :use_poison_skin_feat_damage_event,
                     :finish_poison_skin_feat_event,
                    ],
                        # 93 毒竜燐
                    [:check_add_roar_feat_event,
                     :check_remove_roar_feat_event,
                     :check_rotate_roar_feat_event,
                     :use_roar_feat_event,
                     :finish_roar_feat_event,
                    ],
                        # 94 咆哮
                    [
                     :check_add_fire_breath_feat_event,
                     :check_remove_fire_breath_feat_event,
                     :check_rotate_fire_breath_feat_event,
                     :finish_fire_breath_feat_event,
                    ],
                        # 95 ヘルズベル
                    [:check_add_whirl_wind_feat_event,
                     :check_remove_whirl_wind_feat_event,
                     :check_rotate_whirl_wind_feat_event,
                     :use_whirl_wind_feat_event,
                     :finish_whirl_wind_feat_event,
                    ],
                        # 96 ワールウインド
                    [
                     :check_add_active_armor_feat_event,
                     :check_remove_active_armor_feat_event,
                     :check_rotate_active_armor_feat_event,
                     :use_active_armor_feat_event,
                     :use_active_armor_feat_damage_event,
                     :check_seal_active_armor_feat_move_after_event,
                     :check_seal_active_armor_feat_det_change_after_event,
                     :check_seal_active_armor_feat_damage_after_event,
                     :check_unseal_active_armor_feat_start_turn_event,
                     :check_unseal_active_armor_feat_damage_after_event,
                     :check_seal_active_armor_feat_chara_change_event,
                    ],
                        # 97 アクティブアーマ
                    [
                     :check_add_scolor_attack_feat_event,
                     :check_remove_scolor_attack_feat_event,
                     :check_rotate_scolor_attack_feat_event,
                     :use_scolor_attack_feat_event,
                     :use_scolor_attack_feat_damage_event,
                     :finish_scolor_attack_feat_event,
                    ],
                        # 98 マシンガン
                    [
                     :check_add_heat_seeker_feat_event,
                     :check_remove_heat_seeker_feat_event,
                     :check_rotate_heat_seeker_feat_event,
                     :use_heat_seeker_feat_event,
                     :use_heat_seeker_feat_damage_event,
                     :finish_heat_seeker_feat_event,
                    ],
                        # 99 ヒートシーカー
                    [
                     :check_add_purge_feat_event,
                     :check_remove_purge_feat_event,
                     :check_rotate_purge_feat_event,
                     :finish_purge_feat_event,
                    ],
                        # 100 パージ
                    [
                     :check_add_high_hand_feat_event,
                     :check_remove_high_hand_feat_event,
                     :check_rotate_high_hand_feat_event,
                     :use_high_hand_feat_event,
                     :use_high_hand_feat_damage_event,
                    ],
                        # 101 ハイハンド
                    [:check_add_jack_pot_feat_event,
                     :check_remove_jack_pot_feat_event,
                     :check_rotate_jack_pot_feat_event,
                     :use_jack_pot_feat_event,
                     :use_after_jack_pot_feat_event,
                     :finish_jack_pot_feat_event,
                    ],
                        # 102 ジャックポット
                    [
                     :check_add_low_ball_feat_event,
                     :check_remove_low_ball_feat_event,
                     :check_rotate_low_ball_feat_event,
                     :use_low_ball_feat_event,
                     :use_low_ball_feat_damage_event,
                     :finish_low_ball_feat_event,
                    ],
                        # 103 ローボール
                    [
                     :check_add_gamble_feat_event,
                     :check_remove_gamble_feat_event,
                     :check_rotate_gamble_feat_event,
                     :use_gamble_feat_event,
                     :use_gamble_feat_damage_event,
                     :finish_gamble_feat_event,
                    ],
                        # 104 ギャンブル
                    [
                     :check_add_bird_cage_feat_event,
                     :check_remove_bird_cage_feat_event,
                     :check_rotate_bird_cage_feat_event,
                     :finish_bird_cage_feat_event,
                    ],
                        # 105 バードケージ
                    [
                     :check_add_hanging_feat_event,
                     :check_remove_hanging_feat_event,
                     :check_rotate_hanging_feat_event,
                     :use_hanging_feat_event,
                     :finish_hanging_feat_event,
                    ],
                        # 106 ハンギング
                    [
                     :check_add_blast_off_feat_event,
                     :check_remove_blast_off_feat_event,
                     :check_rotate_blast_off_feat_event,
                     :use_blast_off_feat_event,
                     :ex_blast_off_feat_event,
                     :finish_blast_off_feat_event,
                    ],
                        # 107 ブラストオフ
                    [:check_add_puppet_master_feat_event,
                     :check_remove_puppet_master_feat_event,
                     :check_rotate_puppet_master_feat_event,
                     :use_puppet_master_feat_event,
                     :finish_puppet_master_feat_event,
                    ],
                        # 108 パペットマスター
                    [
                     :check_add_ctl_feat_event,
                     :check_remove_ctl_feat_event,
                     :check_rotate_ctl_feat_event,
                     :use_ctl_feat_event,
                     :finish_ctl_feat_event,
                    ],
                        # 109 C.T.L
                    [
                     :check_add_bpa_feat_event,
                     :check_remove_bpa_feat_event,
                     :check_rotate_bpa_feat_event,
                     :use_bpa_feat_event,
                     :finish_bpa_feat_event,
                    ],
                        # 110 B.P.A
                    [
                     :check_add_lar_feat_event,
                     :check_remove_lar_feat_event,
                     :check_rotate_lar_feat_event,
                     :use_lar_feat_event,
                     :use_lar_feat_damage_event,
                     :finish_lar_feat_event,
                    ],
                        # 111 L.A.R
                    [
                     :check_add_sss_feat_event,
                     :check_remove_sss_feat_event,
                     :check_rotate_sss_feat_event,
                     :finish_sss_feat_event,
                    ],
                        # 112 S.S.S
                    [
                     :check_add_counter_rush_feat_event,
                     :check_remove_counter_rush_feat_event,
                     :check_rotate_counter_rush_feat_event,
                     :use_counter_rush_feat_event,
                     :finish_counter_rush_feat_event,
                    ],
                        # 113 カウンターラッシュ
                    [
                     :check_add_disaster_flame_feat_event,
                     :check_remove_disaster_flame_feat_event,
                     :check_rotate_disaster_flame_feat_event,
                     :use_disaster_flame_feat_event,
                     :finish_disaster_flame_feat_event,
                    ],
                        # 114 劫火
                    [
                     :check_add_hell_fire_feat_event,
                     :check_remove_hell_fire_feat_event,
                     :check_rotate_hell_fire_feat_event,
                     :use_hell_fire_feat_event,
                     :use_hell_fire_feat_damage_event,
                     :use_hell_fire_feat_const_damage_event,
                     :finish_hell_fire_feat_event,
                    ],
                        # 115 煉獄
                    [
                     :check_add_blindness_feat_event,
                     :check_remove_blindness_feat_event,
                     :check_rotate_blindness_feat_event,
                     :use_blindness_feat1_event,
                     :use_blindness_feat2_event,
                     :finish_blindness_feat_event,
                    ],
                        # 116 眩彩
                    [
                     :check_add_fire_disappear_feat_event,
                     :check_remove_fire_disappear_feat_event,
                     :check_rotate_fire_disappear_feat_event,
                     :use_fire_disappear_feat_event,
                     :use_after_fire_disappear_feat_event,
                     :finish_fire_disappear_feat_event,
                    ],
                        # 117 焼滅
                    [
                     :check_add_dark_hole_feat_event,
                     :check_remove_dark_hole_feat_event,
                     :check_rotate_dark_hole_feat_event,
                     :use_dark_hole_feat_event,
                     :finish_dark_hole_feat_event,
                    ],
                        # 118 ダークホール
                    [
                     :check_add_tannhauser_gate_feat_event,
                     :check_remove_tannhauser_gate_feat_event,
                     :check_rotate_tannhauser_gate_feat_event,
                     :use_tannhauser_gate_feat_event,
                     :finish_tannhauser_gate_feat_event,
                    ],
                        # 119 タンホイザーゲート
                    [
                     :check_add_schwar_blitz_feat_event,
                     :check_remove_schwar_blitz_feat_event,
                     :check_rotate_schwar_blitz_feat_event,
                     :use_schwar_blitz_feat_event,
                     :use_schwar_blitz_feat_damage_event,
                     :finish_schwar_blitz_feat_event,
                    ],
                        # 120 シュバルトブリッツ
                    [
                     :check_add_hi_rounder_feat_event,
                     :check_remove_hi_rounder_feat_event,
                     :check_rotate_hi_rounder_feat_event,
                     :use_hi_rounder_feat_event,
                     :finish_hi_rounder_feat_event,
                     :use_hi_rounder_feat_const_damage_event,
                    ],
                        # 121 ハイランダー
                    [
                     :check_add_blood_retting_feat_event,
                     :check_remove_blood_retting_feat_event,
                     :check_rotate_blood_retting_feat_event,
                     :use_blood_retting_feat_event,
                     :use_blood_retting_feat_damage_event,
                     :finish_blood_retting_feat_event,
                    ],
                        # 122 ブラッドレッティング
                    [
                     :check_add_acupuncture_feat_event,
                     :check_remove_acupuncture_feat_event,
                     :check_rotate_acupuncture_feat_event,
                     :finish_acupuncture_feat_event,
                    ],
                        # 123 アキュパンクチャー
                    [
                     :check_add_dissection_feat_event,
                     :check_remove_dissection_feat_event,
                     :check_rotate_dissection_feat_event,
                     :use_dissection_feat_event,
                     :use_dissection_feat_damage_event,
                     :use_dissection_feat_guard_event,
                    ],
                        # 124 ディセクション
                    [
                     :check_add_euthanasia_feat_event,
                     :check_remove_euthanasia_feat_event,
                     :check_rotate_euthanasia_feat_event,
                     :use_euthanasia_feat_event,
                     :use_euthanasia_feat_damage_event,
                     :finish_euthanasia_feat_event,
                    ],
                        # 125 ユーサネイジアー
                    [
                     :check_add_anger_nail_feat_event,
                     :check_remove_anger_nail_feat_event,
                     :check_rotate_anger_nail_feat_event,
                     :finish_anger_nail_feat_event,
                    ],
                        # 126 憤怒の爪
                    [
                     :check_add_calm_back_feat_event,
                     :check_remove_calm_back_feat_event,
                     :check_rotate_calm_back_feat_event,
                     :use_calm_back_feat_event,
                     :use_calm_back_feat_damage_event,
                     :finish_calm_back_feat_event,
                    ],
                        # 127 静謐な背中
                    [
                     :check_add_blue_eyes_feat_event,
                     :check_remove_blue_eyes_feat_event,
                     :check_rotate_blue_eyes_feat_event,
                     :use_blue_eyes_feat_event,
                     :finish_blue_eyes_feat_event,
                    ],
                        # 128 慈悲の青眼
                    [
                     :check_add_wolf_fang_feat_event,
                     :check_remove_wolf_fang_feat_event,
                     :check_rotate_wolf_fang_feat_event,
                     :use_wolf_fang_feat_event,
                     :finish_wolf_fang_feat_event,
                    ],
                        # 129 戦慄の狼牙
                    [
                     :check_add_hagakure_feat_event,
                     :check_remove_hagakure_feat_event,
                     :check_rotate_hagakure_feat_event,
                     :use_hagakure_feat_event,
                     :use_hagakure_feat_damage_event,
                     :finish_hagakure_feat_event,
                    ],
                        # 130 葉隠れ
                    [
                     :check_add_reppu_feat_event,
                     :check_remove_reppu_feat_event,
                     :check_rotate_reppu_feat_event,
                     :use_reppu_feat_event,
                     :finish_reppu_feat_event,
                     :finish_effect_reppu_feat_event,
                     :finish_foe_change_reppu_feat_event,
                     :finish_dead_change_reppu_feat_event,
                     :finish_turn_reppu_feat_event,
                    ],
                        # 131 烈風
                    [
                     :check_add_enpi_feat_event,
                     :check_remove_enpi_feat_event,
                     :check_rotate_enpi_feat_event,
                     :use_enpi_feat_event,
                     :use_enpi_feat_damage_event,
                     :finish_enpi_feat_event,
                    ],
                        # 132 燕飛
                    [
                     :check_add_mikazuki_feat_event,
                     :check_remove_mikazuki_feat_event,
                     :check_rotate_mikazuki_feat_event,
                     :use_mikazuki_feat_event,
                     :finish_mikazuki_feat_event,
                    ],
                        # 133 三日月
                    [
                     :check_add_casablanca_feat_event,
                     :check_remove_casablanca_feat_event,
                     :check_rotate_casablanca_feat_event,
                     :finish_casablanca_feat_event,
                    ],
                        # 134 カサブランカの風
                    [
                     :check_add_rhodesia_feat_event,
                     :check_remove_rhodesia_feat_event,
                     :check_rotate_rhodesia_feat_event,
                     :use_rhodesia_feat_event,
                     :use_rhodesia_feat_damage_event,
                     :finish_rhodesia_feat_event,
                    ],
                        # 135 ローデシアの海
                    [
                     :check_add_madripool_feat_event,
                     :check_remove_madripool_feat_event,
                     :check_rotate_madripool_feat_event,
                     :finish_madripool_feat_event,
                    ],
                        # 136 マドリプールの雑踏
                    [
                     :check_add_asia_feat_event,
                     :check_remove_asia_feat_event,
                     :check_rotate_asia_feat_event,
                     :finish_asia_feat_event,
                    ],
                        # 137 エイジャの曙光
                    [
                     :check_add_demonic_feat_event,
                     :check_remove_demonic_feat_event,
                     :check_rotate_demonic_feat_event,
                     :use_demonic_feat_event,
                     :use_demonic_feat_damage_event,
                     :finish_demonic_feat_event,
                    ],
                        # 138 デモニック
                    [
                     :check_add_shadow_sword_feat_event,
                     :check_remove_shadow_sword_feat_event,
                     :check_rotate_shadow_sword_feat_event,
                     :use_shadow_sword_feat_event,
                     :finish_shadow_sword_feat_event,
                    ],
                        # 139 残像剣
                    [
                     :check_add_perfect_dead_feat_event,
                     :check_remove_perfect_dead_feat_event,
                     :check_rotate_perfect_dead_feat_event,
                     :use_perfect_dead_feat_event,
                     :use_perfect_dead_feat_damage_event,
                     :finish_perfect_dead_feat_event,
                    ],
                        # 140 パーフェクトデッド
                    [
                     :check_add_destruct_gear_feat_event,
                     :check_remove_destruct_gear_feat_event,
                     :check_rotate_destruct_gear_feat_event,
                     :use_destruct_gear_feat_event,
                     :use_destruct_gear_feat_damage_event,
                     :finish_destruct_gear_feat_event,
                    ],
                        # 141 破壊の歯車
                    [
                     :check_add_power_shift_feat_event,
                     :check_remove_power_shift_feat_event,
                     :check_rotate_power_shift_feat_event,
                     :use_power_shift_feat_event,
                     :use_power_shift_feat_damage_event,
                     :finish_power_shift_feat_event,
                    ],
                        # 142 パワーシフト
                    [
                     :check_add_kill_shot_feat_event,
                     :check_remove_kill_shot_feat_event,
                     :check_rotate_kill_shot_feat_event,
                     :use_kill_shot_feat_event,
                     :use_kill_shot_feat_damage_event,
                     :finish_kill_shot_feat_event,
                    ],
                        # 143 キルショット
                    [
                     :check_add_defrect_feat_event,
                     :check_remove_defrect_feat_event,
                     :check_rotate_defrect_feat_event,
                     :use_defrect_feat_event,
                     :use_defrect_feat_damage_event,
                     :finish_defrect_feat_event,
                    ],
                        # 144 ディフレクト
                    [
                     :check_add_flame_offering_feat_event,
                     :check_remove_flame_offering_feat_event,
                     :check_rotate_flame_offering_feat_event,
                     :use_flame_offering_feat_event,
                    ],
                        # 145 炎の供物
                    [
                     :check_add_drain_hand_feat_event,
                     :check_remove_drain_hand_feat_event,
                     :check_rotate_drain_hand_feat_event,
                     :use_drain_hand_feat_event,
                     :use_drain_hand_feat_damage_event,
                     :finish_drain_hand_feat_event,
                    ],
                        # 146 吸収の手
                    [
                     :check_add_fire_prizon_feat_event,
                     :check_remove_fire_prizon_feat_event,
                     :check_rotate_fire_prizon_feat_event,
                     :use_fire_prizon_feat_event,
                    ],
                        # 147 焔の監獄
                    [
                     :check_add_time_stop_feat_event,
                     :check_remove_time_stop_feat_event,
                     :check_rotate_time_stop_feat_event,
                     :finish_time_stop_feat_event,
                    ],
                        # 148 時間停止
                    [
                     :check_add_dead_guard_feat_event,
                     :check_remove_dead_guard_feat_event,
                     :check_rotate_dead_guard_feat_event,
                     :use_dead_guard_feat_event,
                     :use_dead_guard_feat_damage_event,
                     :finish_dead_guard_feat_event,
                    ],
                        # 149 即死防御
                    [
                     :check_add_dead_blue_feat_event,
                     :check_remove_dead_blue_feat_event,
                     :check_rotate_dead_blue_feat_event,
                     :use_dead_blue_feat_event,
                     :use_dead_blue_feat_damage_event,
                     :finish_dead_blue_feat_event,
                    ],
                        # 150 奇数即死
                    [
                     :check_add_evil_guard_feat_event,
                     :check_remove_evil_guard_feat_event,
                     :check_rotate_evil_guard_feat_event,
                     :use_evil_guard_feat_event,
                     :use_evil_guard_feat_damage_event,
                     :finish_evil_guard_feat_event,
                    ],
                        # 151 善悪の彼岸
                    [
                     :check_add_abyss_eyes_feat_event,
                     :check_remove_abyss_eyes_feat_event,
                     :check_rotate_abyss_eyes_feat_event,
                     :use_abyss_eyes_feat_event,
                     :use_abyss_eyes_feat_damage_event,
                     :finish_abyss_eyes_feat_event,
                    ],
                        # 152 道連れ
                    [
                     :check_add_dead_red_feat_event,
                     :check_remove_dead_red_feat_event,
                     :check_rotate_dead_red_feat_event,
                     :finish_dead_red_feat_event,
                    ],
                        # 153 偶数即死
                    [
                     :check_add_night_ghost_feat_event,
                     :check_remove_night_ghost_feat_event,
                     :check_rotate_night_ghost_feat_event,
                     :use_night_ghost_feat_event,
                     :use_night_ghost_feat_damage_event,
                     :finish_night_ghost_feat_event,
                    ],
                        # 154 幽冥の夜
                    [
                     :check_add_avatar_war_feat_event,
                     :check_remove_avatar_war_feat_event,
                     :check_rotate_avatar_war_feat_event,
                     :use_avatar_war_feat_event,
                     :use_avatar_war_feat_damage_event,
                     :finish_avatar_war_feat_event,
                    ],
                        # 155 人形の軍勢
                    [
                     :check_add_confuse_pool_feat_event,
                     :check_remove_confuse_pool_feat_event,
                     :check_rotate_confuse_pool_feat_event,
                     :use_confuse_pool_feat_event,
                     :use_confuse_pool_feat_damage_event,
                     :finish_confuse_pool_feat_event,
                    ],
                        # 156 混沌の渦
                    [
                     :check_add_prominence_feat_event,
                     :check_remove_prominence_feat_event,
                     :check_rotate_prominence_feat_event,
                     :use_prominence_feat_event,
                     :finish_prominence_feat_event,
                    ],
                        # 157 プロミネンス
                    [
                     :check_add_battle_axe_feat_event,
                     :check_remove_battle_axe_feat_event,
                     :check_rotate_battle_axe_feat_event,
                     :use_battle_axe_feat_event,
                     :use_battle_axe_feat_damage_event,
                     :finish_battle_axe_feat_event,
                    ],
                        # 158 バトルアックス
                    [
                     :check_add_moab_feat_event,
                     :check_remove_moab_feat_event,
                     :check_rotate_moab_feat_event,
                     :finish_moab_feat_event,
                    ],
                        # 159 MOAB
                    [
                     :check_add_over_heat_feat_event,
                     :check_remove_over_heat_feat_event,
                     :check_rotate_over_heat_feat_event,
                     :finish_over_heat_feat_event,
                    ],
                        # 160 オーバーヒート
                    [
                     :check_add_blue_rose_feat_event,
                     :check_remove_blue_rose_feat_event,
                     :check_rotate_blue_rose_feat_event,
                     :use_blue_rose_feat_event,
                     :use_blue_rose_feat_damage_event,
                     :finish_blue_rose_feat_event,
                    ],
                        # 161 蒼き薔薇
                    [
                     :check_add_white_crow_feat_event,
                     :check_remove_white_crow_feat_event,
                     :check_rotate_white_crow_feat_event,
                     :finish_white_crow_feat_event,
                    ],
                        # 162 白鴉
                    [
                     :check_add_red_moon_feat_event,
                     :check_remove_red_moon_feat_event,
                     :check_rotate_red_moon_feat_event,
                     :use_red_moon_feat_event,
                     :use_red_moon_feat_dice_attr_event,
                     :use_red_moon_feat_damage_event,
                     :finish_red_moon_feat_event,
                    ],
                        # 163 深紅の月
                    [
                     :check_add_black_sun_feat_event,
                     :check_remove_black_sun_feat_event,
                     :check_rotate_black_sun_feat_event,
                     :finish_black_sun_feat_event,
                    ],
                        # 164黒い太陽
                    [
                     :check_add_girasole_feat_event,
                     :check_remove_girasole_feat_event,
                     :check_rotate_girasole_feat_event,
                     :use_girasole_feat_event,
                     :use_girasole_feat_damage_event,
                     :use_girasole_feat_const_damage_event,
                     :finish_girasole_feat_event,
                    ],
                        # 165 ジラソーレ
                    [
                     :check_add_violetta_feat_event,
                     :check_remove_violetta_feat_event,
                     :check_rotate_violetta_feat_event,
                     :finish_violetta_feat_event,
                    ],
                        # 166 ビオレッタ
                    [
                     :check_add_digitale_feat_event,
                     :check_remove_digitale_feat_event,
                     :check_rotate_digitale_feat_event,
                     :use_digitale_feat_event,
                     :use_digitale_feat_damage_event,
                     :finish_digitale_feat_event,
                    ],
                        # 167 ディジタリス
                    [
                     :check_add_rosmarino_feat_event,
                     :check_remove_rosmarino_feat_event,
                     :check_rotate_rosmarino_feat_event,
                     :finish_rosmarino_feat_event,
                    ],
                        # 168 ロスマリーノ
                    [
                     :check_add_hachiyou_feat_event,
                     :check_remove_hachiyou_feat_event,
                     :check_rotate_hachiyou_feat_event,
                     :finish_hachiyou_feat_event,
                    ],
                        # 169 八葉
                    [
                     :check_add_stone_care_feat_event,
                     :check_remove_stone_care_feat_event,
                     :check_rotate_stone_care_feat_event,
                     :use_stone_care_feat_event,
                     :finish_stone_care_feat_event,
                    ],
                        # 170 鉄石の構え
                    [
                     :check_add_dust_sword_feat_event,
                     :check_remove_dust_sword_feat_event,
                     :check_rotate_dust_sword_feat_event,
                     :use_dust_sword_feat_event,
                     :use_dust_sword_feat_damage_event,
                     :finish_dust_sword_feat_event,
                    ],
                        # 171 絶塵剣
                    [
                     :check_add_illusion_feat_event,
                     :check_remove_illusion_feat_event,
                     :check_rotate_illusion_feat_event,
                     :use_illusion_feat_event,
                     :use_illusion_feat_damage_event,
                     :finish_illusion_feat_event,
                    ],
                        # 172 夢幻
                    [
                     :check_add_despair_shout_feat_event,
                     :check_remove_despair_shout_feat_event,
                     :check_rotate_despair_shout_feat_event,
                     :finish_despair_shout_feat_event,
                    ],
                        # 173 絶望の叫び
                    [
                     :check_add_darkness_song_feat_event,
                     :check_remove_darkness_song_feat_event,
                     :check_rotate_darkness_song_feat_event,
                     :use_darkness_song_feat_event,
                     :finish_darkness_song_feat_event,
                    ],
                        # 174 暗黒神の歌
                    [
                     :check_add_guard_spirit_feat_event,
                     :check_remove_guard_spirit_feat_event,
                     :check_rotate_guard_spirit_feat_event,
                     :finish_guard_spirit_feat_event,
                    ],
                        # 175 守護霊の魂
                    [
                     :check_add_slaughter_organ_feat_event,
                     :check_remove_slaughter_organ_feat_event,
                     :check_rotate_slaughter_organ_feat_event,
                     :use_slaughter_organ_feat_event,
                     :finish_slaughter_organ_feat_event,
                     :finish_turn_slaughter_organ_feat_event,
                    ],
                        # 176 殺戮器官
                    [
                     :check_add_fools_hand_feat_event,
                     :check_remove_fools_hand_feat_event,
                     :check_rotate_fools_hand_feat_event,
                     :use_fools_hand_feat_event,
                     :use_fools_hand_feat_damage_event,
                     :finish_fools_hand_feat_event,
                    ],
                        # 177 愚者の手
                    [
                     :check_add_time_seed_feat_event,
                     :check_remove_time_seed_feat_event,
                     :check_rotate_time_seed_feat_event,
                     :use_time_seed_feat_event,
                     :finish_time_seed_feat_event,
                    ],
                        # 178 時の種子
                    [
                     :check_add_irongate_of_fate_feat_event,
                     :check_remove_irongate_of_fate_feat_event,
                     :check_rotate_irongate_of_fate_feat_event,
                     :use_irongate_of_fate_feat_event,
                     :use_irongate_of_fate_feat_damage_event,
                     :finish_irongate_of_fate_feat_event,
                    ],
                        # 179 運命の鉄門
                    [
                     :check_add_gatherer_feat_event,
                     :check_remove_gatherer_feat_event,
                     :check_rotate_gatherer_feat_event,
                     :use_gatherer_feat_event,
                     :use_next_gatherer_feat_event,
                     :finish_gatherer_feat_event,
                     :finish_chara_change_gatherer_feat_event,
                     :finish_foe_chara_change_gatherer_feat_event,
                    ],
                        # 180 ザ・ギャザラー
                    [
                     :check_add_judge_feat_event,
                     :check_remove_judge_feat_event,
                     :check_rotate_judge_feat_event,
                     :use_judge_feat_event,
                     :use_judge_feat_damage_event,
                     :finish_judge_feat_event,
                    ],
                        # 161 ザ・ジャッジ
                    [
                     :check_add_dream_feat_event,
                     :check_remove_dream_feat_event,
                     :check_rotate_dream_feat_event,
                     :use_dream_feat_event,
                     :use_dream_feat_damage_event,
                     :finish_dream_feat_event,
                    ],
                        # 182 ザ・ドリーム
                    [
                     :check_add_one_above_all_feat_event,
                     :check_remove_one_above_all_feat_event,
                     :check_rotate_one_above_all_feat_event,
                     :use_one_above_all_feat_event,
                    ],
                        # 183 ジ・ワン・アボヴ・オール
                    [
                     :check_add_antiseptic_feat_event,
                     :check_remove_antiseptic_feat_event,
                     :check_rotate_antiseptic_feat_event,
                     :use_antiseptic_feat_event,
                     :finish_antiseptic_feat_event,
                     :finish_turn_antiseptic_feat_event,
                     :check_antiseptic_state_change_event,
                     :check_antiseptic_state_dead_change_event,
                     :finish_antiseptic_state_event,
                    ],
                        # 184 アンチセプティック・F
                    [
                     :check_add_silver_machine_feat_event,
                     :check_remove_silver_machine_feat_event,
                     :check_rotate_silver_machine_feat_event,
                     :use_silver_machine_feat_event,
                     :finish_silver_machine_feat_event,
                     :finish_turn_silver_machine_feat_event,
                    ],
                        # 185 シルバーマシン
                    [
                     :check_add_atom_heart_feat_event,
                     :check_remove_atom_heart_feat_event,
                     :check_rotate_atom_heart_feat_event,
                     :use_atom_heart_feat_event,
                     :use_next_atom_heart_feat_event,
                     :finish_atom_heart_feat_event,
                     :finish_result_atom_heart_feat_event,
                     :finish_calc_atom_heart_feat_event,
                     :disable_atom_heart_feat_event,
                     :disable_next_atom_heart_feat_event,
                    ],
                        # 186 アトムハート
                    [
                     :check_add_electric_surgery_feat_event,
                     :check_remove_electric_surgery_feat_event,
                     :check_rotate_electric_surgery_feat_event,
                     :use_electric_surgery_feat_event,
                     :use_electric_surgery_feat_damage_event,
                     :finish_electric_surgery_feat_event,
                    ],
                        # 187 エレクトロサージェリー
                    [
                     :check_add_acid_eater_feat_event,
                     :check_remove_acid_eater_feat_event,
                     :check_rotate_acid_eater_feat_event,
                     :finish_used_determine_acid_eater_feat_event,
                     :finish_determine_acid_eater_feat_event,
                     :finish_calc_acid_eater_feat_event,
                     :finish_next_acid_eater_feat_event,
                    ],
                        # 188 アシッドイーター
                    [
                     :check_add_dead_lock_feat_event,
                     :check_remove_dead_lock_feat_event,
                     :check_rotate_dead_lock_feat_event,
                     :use_dead_lock_feat_event,
                     :use_dead_lock_feat_damage_event,
                     :finish_dead_lock_feat_event,
                    ],
                        # 189 デッドロック
                    [
                     :check_add_beggars_banquet_feat_event,
                     :check_remove_beggars_banquet_feat_event,
                     :check_rotate_beggars_banquet_feat_event,
                     :use_beggars_banquet_feat_event,
                     :ex_beggars_banquet_tmp_feat_event,
                     :finish_ex_beggars_banquet_feat_event,
                     :finish_chara_change_ex_beggars_banquet_feat_event,
                     :finish_foe_chara_change_ex_beggars_banquet_feat_event,
                    ],
                        # 190 ベガーズバンケット
                    [
                     :check_add_swan_song_feat_event,
                     :check_remove_swan_song_feat_event,
                     :check_rotate_swan_song_feat_event,
                     :use_swan_song_feat_event,
                     :finish_swan_song_feat_event,
                    ],
                        # 191 スワンソング
                    [
                     :check_add_idle_grave_feat_event,
                     :check_remove_idle_grave_feat_event,
                     :check_rotate_idle_grave_feat_event,
                     :use_idle_grave_feat_event,
                    ],
                        # 192 精神力吸収
                    [
                     :check_add_sorrow_song_feat_event,
                     :check_remove_sorrow_song_feat_event,
                     :check_rotate_sorrow_song_feat_event,
                     :use_sorrow_song_feat_event,
                     :finish_sorrow_song_feat_event,
                     :finish_ex_sorrow_song_feat_event,
                    ],
                        # 193 慟哭の歌
                    [
                     :check_add_red_wheel_feat_event,
                     :check_remove_red_wheel_feat_event,
                     :check_rotate_red_wheel_feat_event,
                     :use_red_wheel_feat_event,
                     :use_red_wheel_feat_damage_event,
                     :finish_red_wheel_feat_event,
                    ],
                        # 194 紅蓮の車輪
                    [
                     :check_add_red_pomegranate_feat_event,
                     :check_remove_red_pomegranate_feat_event,
                     :check_rotate_red_pomegranate_feat_event,
                     :finish_red_pomegranate_feat_event,
                    ],
                        # 195 赤い石榴
                    [
                     :check_add_clock_works_feat_event,
                     :check_remove_clock_works_feat_event,
                     :check_rotate_clock_works_feat_event,
                     :finish_clock_works_feat_event,
                    ],
                        # 196 クロックワークス
                    [
                     :check_add_time_hunt_feat_event,
                     :check_remove_time_hunt_feat_event,
                     :check_rotate_time_hunt_feat_event,
                     :use_ex_time_hunt_feat_event,
                     :use_time_hunt_feat_event,
                     :finish_time_hunt_feat_event,
                    ],
                        # 197 タイムハント
                    [
                     :check_add_time_bomb_feat_event,
                     :check_remove_time_bomb_feat_event,
                     :check_rotate_time_bomb_feat_event,
                     :use_time_bomb_feat_event,
                     :finish_time_bomb_feat_event,
                    ],
                        # 198 タイムボム
                    [
                     :check_add_in_the_evening_feat_event,
                     :check_remove_in_the_evening_feat_event,
                     :check_rotate_in_the_evening_feat_event,
                     :finish_in_the_evening_feat_event,
                    ],
                        # 199 インジイブニング
                    [
                     :check_add_final_waltz_feat_event,
                     :check_remove_final_waltz_feat_event,
                     :check_rotate_final_waltz_feat_event,
                     :use_final_waltz_feat_event,
                     :use_final_waltz_feat_damage_event,
                     :finish_final_waltz_feat_event,
                    ],
                        # 200 終局のワルツ
                    [
                     :check_add_desperate_sonata_feat_event,
                     :check_remove_desperate_sonata_feat_event,
                     :check_rotate_desperate_sonata_feat_event,
                     :use_desperate_sonata_feat_event,
                     :finish_desperate_sonata_feat_event,
                     :finish_turn_desperate_sonata_feat_event,
                    ],
                        # 201 自棄のソナタ
                    [
                     :check_add_gladiator_march_feat_event,
                     :check_remove_gladiator_march_feat_event,
                     :check_rotate_gladiator_march_feat_event,
                     :use_gladiator_march_feat_event,
                     :finish_gladiator_march_feat_event,
                    ],
                        # 202 剣闘士のマーチ
                    [
                     :check_add_requiem_of_revenge_feat_event,
                     :check_remove_requiem_of_revenge_feat_event,
                     :check_rotate_requiem_of_revenge_feat_event,
                     :use_requiem_of_revenge_feat_event,
                     :finish_requiem_of_revenge_feat_event,
                    ],
                        # 203 恩讐のレクイエム
                    [
                     :check_add_delicious_milk_feat_event,
                     :check_remove_delicious_milk_feat_event,
                     :check_rotate_delicious_milk_feat_event,
                     :use_delicious_milk_feat_event,
                     :use_ex_delicious_milk_feat_event,
                     :finish_change_delicious_milk_feat_event,
                     :finish_delicious_milk_feat_event,
                     :finish_turn_delicious_milk_feat_event,
                    ],
                        # 204 おいしいミルク
                    [
                     :check_add_easy_injection_feat_event,
                     :check_remove_easy_injection_feat_event,
                     :check_rotate_easy_injection_feat_event,
                     :use_easy_injection_feat_event,
                     :finish_easy_injection_feat_event,
                    ],
                        # 205 やさしいお注射
                    [
                     :check_add_blood_collecting_feat_event,
                     :check_remove_blood_collecting_feat_event,
                     :check_rotate_blood_collecting_feat_event,
                     :use_blood_collecting_feat_event,
                     :finish_blood_collecting_feat_event,
                    ],
                        # 206 たのしい採血
                    [
                     :check_add_secret_medicine_feat_event,
                     :check_remove_secret_medicine_feat_event,
                     :check_rotate_secret_medicine_feat_event,
                     :use_secret_medicine_feat_event,
                     :finish_secret_medicine_feat_event,
                    ],
                        # 207 ひみつのお薬
                    [
                     :check_add_ice_gate_feat_event,
                     :check_remove_ice_gate_feat_event,
                     :check_rotate_ice_gate_feat_event,
                     :use_ice_gate_feat_event,
                     :finish_ice_gate_feat_event,
                    ],
                        # 208 氷の門
                    [
                     :check_add_fire_gate_feat_event,
                     :check_remove_fire_gate_feat_event,
                     :check_rotate_fire_gate_feat_event,
                     :use_fire_gate_feat_event,
                     :finish_fire_gate_feat_event,
                    ],
                        # 209 炎の門
                    [
                     :check_add_break_gate_feat_event,
                     :check_remove_break_gate_feat_event,
                     :check_rotate_break_gate_feat_event,
                     :finish_break_gate_feat_event,
                    ],
                        # 210
                    [
                     :check_add_shout_of_gate_feat_event,
                     :check_remove_shout_of_gate_feat_event,
                     :check_rotate_shout_of_gate_feat_event,
                     :use_shout_of_gate_feat_event,
                     :use_shout_of_gate_feat_damage_event,
                     :finish_shout_of_gate_feat_event,
                    ],
                        # 211 叫ぶ門
                    [
                     :check_add_ferreous_anger_feat_event,
                     :check_remove_ferreous_anger_feat_event,
                     :check_rotate_ferreous_anger_feat_event,
                     :use_ferreous_anger_feat_event,
                     :use_ferreous_anger_feat_damage_event,
                     :finish_ferreous_anger_feat_event,
                    ],
                        # 212 フュリアスアンガー
                    [
                     :check_add_name_of_charity_feat_event,
                     :check_remove_name_of_charity_feat_event,
                     :check_rotate_name_of_charity_feat_event,
                     :use_name_of_charity_feat_event,
                    ],
                        # 213 ネームオブチャリティ
                    [
                     :check_add_good_will_feat_event,
                     :check_remove_good_will_feat_event,
                     :check_rotate_good_will_feat_event,
                     :use_good_will_feat_event,
                     :finish_good_will_feat_event,
                    ],
                        # 214 グッドウィル
                    [
                     :check_add_great_vengeance_feat_event,
                     :check_remove_great_vengeance_feat_event,
                     :check_rotate_great_vengeance_feat_event,
                     :use_great_vengeance_feat_event,
                     :use_great_vengeance_feat_damage_event,
                     :use_great_vengeance_feat_const_damage_event,
                     :finish_great_vengeance_feat_event,
                    ],
                        # 215 グレートベンジェンス
                    [
                     :check_add_innocent_soul_feat_event,
                     :check_remove_innocent_soul_feat_event,
                     :check_rotate_innocent_soul_feat_event,
                     :finish_innocent_soul_feat_event,
                    ],
                        # 216 無辜の魂
                    [
                     :check_add_infallible_deed_feat_event,
                     :check_remove_infallible_deed_feat_event,
                     :check_rotate_infallible_deed_feat_event,
                     :use_infallible_deed_feat_event,
                     :finish_infallible_deed_feat_event,
                     :finish_chara_change_infallible_deed_feat_event,
                     :finish_effect_infallible_deed_feat_event,
                     :finish_foe_change_infallible_deed_feat_event,
                     :finish_owner_change_infallible_deed_feat_event,
                     :finish_dead_change_infallible_deed_feat_event,
                     :finish_turn_infallible_deed_feat_event,
                    ],
                        # 217 無謬の行い(光彩陸離)
                    [
                     :check_add_idle_fate_feat_event,
                     :check_remove_idle_fate_feat_event,
                     :check_rotate_idle_fate_feat_event,
                     :use_idle_fate_feat_event,
                     :use_idle_fate_feat_damage_event,
                     :finish_idle_fate_feat_event,
                    ],
                        # 218 無為の運命
                    [
                     :check_add_regrettable_judgment_feat_event,
                     :check_remove_regrettable_judgment_feat_event,
                     :check_rotate_regrettable_judgment_feat_event,
                     :use_regrettable_judgment_feat_event,
                     :use_regrettable_judgment_feat_damage_event,
                     :finish_regrettable_judgment_feat_event,
                    ],
                        # 219 無念の裁き
                    [
                     :check_add_sin_wriggle_feat_event,
                     :check_remove_sin_wriggle_feat_event,
                     :check_rotate_sin_wriggle_feat_event,
                     :use_sin_wriggle_feat_event,
                     :use_sin_wriggle_feat_damage_event,
                     :finish_sin_wriggle_feat_event,
                    ],
                        # 220 罪業の蠢き
                    [
                     :check_add_idle_groan_feat_event,
                     :check_remove_idle_groan_feat_event,
                     :check_rotate_idle_groan_feat_event,
                     :use_idle_groan_feat_event,
                     :use_idle_groan_feat_damage_event,
                     :finish_idle_groan_feat_event,
                     :finish_turn_idle_groan_feat_event,
                    ],
                        # 221 懶惰の呻き
                    [
                     :check_add_contamination_sorrow_feat_event,
                     :check_remove_contamination_sorrow_feat_event,
                     :check_rotate_contamination_sorrow_feat_event,
                     :finish_contamination_sorrow_feat_event,
                    ],
                        # 222 汚濁の囁き
                    [
                     :check_add_failure_groan_feat_event,
                     :check_remove_failure_groan_feat_event,
                     :check_rotate_failure_groan_feat_event,
                     :finish_failure_groan_feat_event,
                    ],
                        # 223 蹉跌の犇めき
                    [
                     :check_add_cathedral_feat_event,
                     :check_remove_cathedral_feat_event,
                     :check_rotate_cathedral_feat_event,
                     :use_cathedral_feat_event,
                     :finish_cathedral_feat_event,
                    ],
                        # 224 大聖堂
                    [
                     :check_add_winter_dream_feat_event,
                     :check_remove_winter_dream_feat_event,
                     :check_rotate_winter_dream_feat_event,
                     :use_winter_dream_feat_event,
                     :use_winter_dream_feat_damage_event,
                     :finish_winter_dream_feat_event,
                    ],
                        # 225 冬の夢
                    [
                     :check_add_tender_night_feat_event,
                     :check_remove_tender_night_feat_event,
                     :check_rotate_tender_night_feat_event,
                     :finish_tender_night_feat_event,
                    ],
                        # 226 夜はやさし
                    [
                     :check_add_fortunate_reason_feat_event,
                     :check_remove_fortunate_reason_feat_event,
                     :check_rotate_fortunate_reason_feat_event,
                     :finish_fortunate_reason_feat_event,
                    ],
                        # 227 しあわせの理由
                    [
                     :check_add_rud_num_feat_event,
                     :check_remove_rud_num_feat_event,
                     :check_rotate_rud_num_feat_event,
                     :use_rud_num_feat_event,
                     :finish_rud_num_feat_event,
                    ],
                        # 228 RudNum
                    [
                     :check_add_von_num_feat_event,
                     :check_remove_von_num_feat_event,
                     :check_rotate_von_num_feat_event,
                     :use_von_num_feat_event,
                     :use_von_num_feat_damage_event,
                     :finish_von_num_feat_event,
                    ],
                        # 229 VonNum
                    [
                     :check_add_chr_num_feat_event,
                     :check_remove_chr_num_feat_event,
                     :check_rotate_chr_num_feat_event,
                     :use_chr_num_feat_event,
                     :finish_chr_num_feat_event,
                    ],
                        # 230 CHR799
                    [
                     :check_add_wil_num_feat_event,
                     :check_remove_wil_num_feat_event,
                     :check_rotate_wil_num_feat_event,
                     :finish_wil_num_feat_event,
                    ],
                        # 231 wil846
                    [
                     :check_add_precision_fire_feat_event,
                     :check_remove_precision_fire_feat_event,
                     :check_rotate_precision_fire_feat_event,
                     :use_precision_fire_feat_event,
                     :use_precision_fire_feat_damage_event,
                     :finish_precision_fire_feat_event,
                    ],
                        # 232 精密射撃(復活)
                    [
                     :check_add_purple_lightning_feat_event,
                     :check_remove_purple_lightning_feat_event,
                     :check_rotate_purple_lightning_feat_event,
                     :use_purple_lightning_feat_event,
                     :use_purple_lightning_feat_damage_event,
                     :finish_purple_lightning_feat_event,
                    ],
                        # 233 紫電
                    [
                     :check_add_mortal_style_feat_event,
                     :check_remove_mortal_style_feat_event,
                     :check_rotate_mortal_style_feat_event,
                     :finish_mortal_style_feat_event,
                    ],
                        # 234 必殺の構え(復活)
                    [
                     :check_add_bloody_howl_feat_event,
                     :check_remove_bloody_howl_feat_event,
                     :check_rotate_bloody_howl_feat_event,
                     :use_bloody_howl_feat_event,
                     :finish_bloody_howl_feat_event,
                     :use_bloody_howl_feat_damage_event,
                    ],
                        # 235 ブラッディハウル
                    [
                     :check_add_charged_thrust_feat_event,
                     :check_remove_charged_thrust_feat_event,
                     :check_rotate_charged_thrust_feat_event,
                     :use_charged_thrust_feat_event,
                     :finish_charged_thrust_feat_event,
                    ],
                        # 236 チャージドストラト
                    [
                     :check_add_sword_dance_feat_event,
                     :check_remove_sword_dance_feat_event,
                     :check_rotate_sword_dance_feat_event,
                     :use_sword_dance_feat_event,
                     :finish_sword_dance_feat_event,
                     :use_sword_dance_feat_damage_event,
                    ],
                        # 237 ソードダンス
                    [
                     :check_add_sword_avoid_feat_event,
                     :check_remove_sword_avoid_feat_event,
                     :check_rotate_sword_avoid_feat_event,
                     :use_sword_avoid_feat_event,
                     :use_sword_avoid_feat_damage_event,
                     :finish_sword_avoid_feat_event,
                    ],
                        # 238 受け流し
                    [
                     :check_add_kutunesirka_feat_event,
                     :check_remove_kutunesirka_feat_event,
                     :check_rotate_kutunesirka_feat_event,
                     :use_kutunesirka_feat_event,
                     :finish_kutunesirka_feat_event,
                     :use_kutunesirka_feat_damage_event,
                    ],
                        # 239 クトネシリカ(フォイルニスゼーレ)
                    [
                     :check_add_feet_of_hermes_feat_event,
                     :check_remove_feet_of_hermes_feat_event,
                     :check_rotate_feet_of_hermes_feat_event,
                     :use_feet_of_hermes_feat_event,
                     :use_feet_of_hermes_feat_damage_event,
                    ],
                        # 240 ヘルメスの靴(ドゥンケルハイト)
                    [
                     :check_add_aegis_wing_feat_event,
                     :check_remove_aegis_wing_feat_event,
                     :check_rotate_aegis_wing_feat_event,
                     :use_aegis_wing_feat_event,
                     :finish_aegis_wing_feat_event,
                     :use_aegis_wing_feat_damage_event,
                    ],
                        # 241 イージスの翼(シャッテンフリューゲル)
                    [
                     :check_add_claiomh_solais_feat_event,
                     :check_remove_claiomh_solais_feat_event,
                     :check_rotate_claiomh_solais_feat_event,
                     :use_claiomh_solais_feat_event,
                     :finish_claiomh_solais_feat_event,
                    ],
                        # 242 クラウ・ソラス(ヴィルベルリッテル)
                    [
                     :check_add_mutation_feat_event,
                     :check_remove_mutation_feat_event,
                     :check_rotate_mutation_feat_event,
                     :use_mutation_feat_event,
                     :finish_mutation_feat_event,
                     :finish_effect_mutation_feat_event,
                    ],
                        # 243 細胞変異
                    [
                     :check_add_rampancy_feat_event,
                     :check_remove_rampancy_feat_event,
                     :check_rotate_rampancy_feat_event,
                     :use_rampancy_feat_damage_event,
                     :finish_rampancy_feat_event,
                    ],
                        # 244 指嗾する仔
                    [
                     :check_add_sacrifice_of_soul_feat_event,
                     :check_remove_sacrifice_of_soul_feat_event,
                     :check_rotate_sacrifice_of_soul_feat_event,
                     :use_sacrifice_of_soul_feat_event,
                     :use_sacrifice_of_soul_feat_heal_event,
                     :use_sacrifice_of_soul_feat_damage_event,
                    ],
                        # 245 魂魄の贄
                    [
                     :check_add_silver_bullet_feat_event,
                     :check_remove_silver_bullet_feat_event,
                     :check_rotate_silver_bullet_feat_event,
                     :finish_silver_bullet_feat_event,
                    ],
                        # 246 銀の丸弾(哀切の残光)
                    [
                     :check_add_pumpkin_drop_feat_event,
                     :check_remove_pumpkin_drop_feat_event,
                     :check_rotate_pumpkin_drop_feat_event,
                     :use_pumpkin_drop_feat_event,
                     :use_pumpkin_drop_feat_damage_event,
                     :use_pumpkin_drop_feat_const_damage_event,
                     :finish_pumpkin_drop_feat_event,
                    ],
                        # 247 かぼちゃ落とし
                    [
                     :check_add_wandering_feather_feat_event,
                     :check_remove_wandering_feather_feat_event,
                     :check_rotate_wandering_feather_feat_event,
                     :use_wandering_feather_feat_event,
                     :finish_wandering_feather_feat_event,
                     :cutin_wandering_feather_feat_event,
                    ],
                        # 248 彷徨う羽根
                    [
                     :check_add_sheep_song_feat_event,
                     :check_remove_sheep_song_feat_event,
                     :check_rotate_sheep_song_feat_event,
                     :use_sheep_song_feat_event,
                     :finish_sheep_song_feat_event,
                    ],
                        # 249 ひつじ数え歌
                    [
                     :check_add_dream_of_ovuerya_feat_event,
                     :check_remove_dream_of_ovuerya_feat_event,
                     :check_rotate_dream_of_ovuerya_feat_event,
                     :finish_dream_of_ovuerya_feat_event,
                    ],
                        # 250 オヴェリャの夢
                    [
                     :check_add_marys_sheep_feat_event,
                     :check_remove_marys_sheep_feat_event,
                     :check_rotate_marys_sheep_feat_event,
                     :use_marys_sheep_feat_event,
                     :use_marys_sheep_feat_damage_event,
                     :finish_marys_sheep_feat_event,
                    ],
                        # 251 メリーズシープ
                    [
                     :check_add_evil_eye_feat_event,
                     :check_remove_evil_eye_feat_event,
                     :check_rotate_evil_eye_feat_event,
                     :use_evil_eye_feat_event,
                     :use_evil_eye_feat_damage_event,
                     :finish_evil_eye_feat_event,
                    ],
                        # 252 光り輝く邪眼
                    [
                     :check_add_black_arts_feat_event,
                     :check_remove_black_arts_feat_event,
                     :check_rotate_black_arts_feat_event,
                     :finish_black_arts_feat_event,
                    ],
                        # 253 超越者の邪法
                    [
                     :check_add_blasphemy_curse_feat_event,
                     :check_remove_blasphemy_curse_feat_event,
                     :check_rotate_blasphemy_curse_feat_event,
                     :use_blasphemy_curse_feat_event,
                     :use_blasphemy_curse_feat_damage_event,
                     :finish_blasphemy_curse_feat_event,
                    ],
                        # 254 冒涜する呪詛
                    [
                     :check_add_end_of_end_feat_event,
                     :check_remove_end_of_end_feat_event,
                     :check_rotate_end_of_end_feat_event,
                     :use_end_of_end_feat_event,
                     :use_end_of_end_feat_damage_event,
                     :finish_end_of_end_feat_event,
                    ],
                        # 255 終焉の果て
                    [
                     :check_add_thrones_gate_feat_event,
                     :check_remove_thrones_gate_feat_event,
                     :check_rotate_thrones_gate_feat_event,
                     :use_thrones_gate_feat_event,
                     :use_thrones_gate_feat_damage_event,
                     :finish_thrones_gate_feat_event,
                    ],
                        # 256 玉座の凱旋門
                    [
                     :check_add_ghost_resentment_feat_event,
                     :check_remove_ghost_resentment_feat_event,
                     :check_rotate_ghost_resentment_feat_event,
                     :use_ghost_resentment_feat_event,
                     :use_ghost_resentment_feat_damage_event,
                     :finish_ghost_resentment_feat_event,
                    ],
                        # 257 幽愁暗恨
                    [
                     :check_add_curse_sword_feat_event,
                     :check_remove_curse_sword_feat_event,
                     :check_rotate_curse_sword_feat_event,
                     :use_curse_sword_feat_event,
                     :use_curse_sword_feat_damage_event,
                     :finish_curse_sword_feat_event,
                    ],
                        # 258 Ex呪剣
                    [
                     :check_add_rapid_sword_r2_feat_event,
                     :check_remove_rapid_sword_r2_feat_event,
                     :check_rotate_rapid_sword_r2_feat_event,
                     :use_rapid_sword_r2_feat_event,
                     :finish_rapid_sword_r2_feat_event,
                    ],
                        # 259 神速の剣(復活)
                    [
                     :check_add_anger_r_feat_event,
                     :check_remove_anger_r_feat_event,
                     :check_rotate_anger_r_feat_event,
                     :use_anger_r_feat_event,
                     :finish_anger_r_feat_event,
                    ],
                        # 260 怒りの一撃
                    [
                     :check_add_volition_deflect_feat_event,
                     :check_remove_volition_deflect_feat_event,
                     :check_rotate_volition_deflect_feat_event,
                     :use_volition_deflect_feat_event,
                     :finish_volition_deflect_feat_event,
                    ],
                        # 261 ヴォリッションディフレクト
                    [
                     :check_add_shadow_shot_r_feat_event,
                     :check_remove_shadow_shot_r_feat_event,
                     :check_rotate_shadow_shot_r_feat_event,
                     :use_shadow_shot_r_feat_event,
                     :use_shadow_shot_r_feat_damage_event,
                     :finish_shadow_shot_r_feat_event,
                    ],
                        # 262 影撃ち(復活)
                    [
                     :check_add_burning_tail_feat_event,
                     :check_remove_burning_tail_feat_event,
                     :check_rotate_burning_tail_feat_event,
                     :use_burning_tail_feat_event,
                     :finish_burning_tail_feat_event,
                    ],
                        # 263 嚇灼の尾
                    [
                     :check_add_quake_walk_feat_event,
                     :check_remove_quake_walk_feat_event,
                     :check_rotate_quake_walk_feat_event,
                     :finish_quake_walk_feat_event,
                    ],
                        # 264 震歩
                    [
                     :check_add_drainage_feat_event,
                     :check_remove_drainage_feat_event,
                     :check_rotate_drainage_feat_event,
                     :use_drainage_feat_event,
                     :use_drainage_feat_damage_event,
                     :use_drainage_feat_const_damage_event,
                     :finish_drainage_feat_event,
                    ],
                        # 265 ドレナージ
                    [
                     :check_add_smile_feat_event,
                     :check_remove_smile_feat_event,
                     :check_rotate_smile_feat_event,
                     :use_smile_feat_event,
                     :use_smile_feat_damage_event,
                     :finish_smile_feat_event,
                    ],
                        # 266 やさしい微笑み
                    [
                     :check_add_blutkontamina_feat_event,
                     :check_remove_blutkontamina_feat_event,
                     :check_rotate_blutkontamina_feat_event,
                     :use_blutkontamina_feat_event,
                     :use_blutkontamina_feat_damage_event,
                     :finish_blutkontamina_feat_event,
                    ],
                        # 267 血統汚染(レイド用)
                    [
                     :check_add_cold_eyes_feat_event,
                     :check_remove_cold_eyes_feat_event,
                     :check_rotate_cold_eyes_feat_event,
                     :use_cold_eyes_feat_damage_event,
                     :finish_cold_eyes_feat_event,
                    ],
                        # 268 つめたい視線
                    [
                     :check_add_feat1_feat_event,
                     :check_remove_feat1_feat_event,
                     :check_rotate_feat1_feat_event,
                     :use_feat1_feat_event,
                     :use_feat1_feat_damage_event,
                     :finish_feat1_feat_event,
                    ],
                        # 269 Feat1
                    [
                     :check_add_feat2_feat_event,
                     :check_remove_feat2_feat_event,
                     :check_rotate_feat2_feat_event,
                     :use_feat2_feat_event,
                     :finish_feat2_feat_event,
                     :use_feat2_feat_damage_event,
                    ],
                        # 270 Feat2
                    [
                     :check_add_feat3_feat_event,
                     :check_remove_feat3_feat_event,
                     :check_rotate_feat3_feat_event,
                     :use_feat3_feat_event,
                     :finish_feat3_feat_event,
                    ],
                        # 271 Feat3
                    [
                     :check_add_feat4_feat_event,
                     :check_remove_feat4_feat_event,
                     :check_rotate_feat4_feat_event,
                     :check_bp_feat4_attack_feat_event,
                     :check_bp_feat4_defence_feat_event,
                     :use_feat4_feat_event,
                     :finish_change_feat4_feat_event,
                     :start_feat4_feat_event,
                     :finish_feat4_feat_event,
                    ],
                        # 272 Feat4
                    [
                     :check_add_weasel_feat_event,
                     :check_remove_weasel_feat_event,
                     :check_rotate_weasel_feat_event,
                     :check_table_weasel_feat_move_event,
                     :check_table_weasel_feat_battle_event,
                     :use_weasel_feat_deal_event,
                     :use_weasel_feat_event,
                     :use_weasel_feat_damage_event,
                     :finish_weasel_feat_event,
                     :check_ending_weasel_feat_event,
                    ],
                        # 273 見えざる白群の鼬
                    [
                     :check_add_dark_profound_feat_event,
                     :check_remove_dark_profound_feat_event,
                     :check_rotate_dark_profound_feat_event,
                     :use_dark_profound_feat_event,
                     :use_dark_profound_feat_bornus_event,
                     :finish_dark_profound_feat_event,
                    ],
                        # 274 暗黒の渦(復活)
                    [
                     :check_add_karmic_dor_feat_event,
                     :check_remove_karmic_dor_feat_event,
                     :check_rotate_karmic_dor_feat_event,
                     :check_point_karmic_dor_feat_event,
                     :use_karmic_dor_feat_event,
                     :finish_karmic_dor_feat_event,
                    ],
                        # 275 因果の扉
                    [
                     :check_add_batafly_mov_feat_event,
                     :check_remove_batafly_mov_feat_event,
                     :check_rotate_batafly_mov_feat_event,
                     :determine_distance_batafly_mov_feat_event,
                     :finish_batafly_mov_feat_event,
                    ],
                        # 276 batafly_mov
                    [
                     :check_add_batafly_atk_feat_event,
                     :check_remove_batafly_atk_feat_event,
                     :check_rotate_batafly_atk_feat_event,
                     :use_batafly_atk_feat_event,
                     :finish_batafly_atk_feat_event,
                    ],
                        # 277 batafly_atk
                    [
                     :check_add_batafly_def_feat_event,
                     :check_remove_batafly_def_feat_event,
                     :check_rotate_batafly_def_feat_event,
                     :use_batafly_def_feat_event,
                     :finish_batafly_def_feat_event,
                    ],
                        # 278 batafly_def
                    [
                     :check_add_batafly_sld_feat_event,
                     :check_remove_batafly_sld_feat_event,
                     :check_rotate_batafly_sld_feat_event,
                     :use_batafly_sld_feat_event,
                     :finish_batafly_sld_feat_event,
                    ],
                        # 279 batafly_sld
                    [
                     :check_add_grace_cocktail_feat_event,
                     :check_remove_grace_cocktail_feat_event,
                     :check_rotate_grace_cocktail_feat_event,
                     :use_grace_cocktail_feat_event,
                     :use_grace_cocktail_feat_damage_event,
                     :finish_grace_cocktail_feat_event,
                    ],
                        # 280 ベンダーカクテル
                    [
                     :check_add_land_mine_r_feat_event,
                     :check_remove_land_mine_r_feat_event,
                     :check_rotate_land_mine_r_feat_event,
                     :use_land_mine_r_feat_event,
                    ],
                        # 281 ランドマイン(復活)
                    [
                     :check_add_napalm_death_feat_event,
                     :check_remove_napalm_death_feat_event,
                     :check_rotate_napalm_death_feat_event,
                     :use_napalm_death_feat_event,
                     :finish_napalm_death_feat_event,
                    ],
                        # 282 ナパーム・デス
                    [
                     :check_add_suicidal_failure_feat_event,
                     :check_remove_suicidal_failure_feat_event,
                     :check_rotate_suicidal_failure_feat_event,
                     :use_suicidal_failure_feat_event,
                     :finish_suicidal_failure_feat_event,
                    ],
                        # 283 スーサイダルフェイルア
                    [
                     :check_add_big_bragg_r_feat_event,
                     :check_remove_big_bragg_r_feat_event,
                     :check_rotate_big_bragg_r_feat_event,
                     :finish_big_bragg_r_feat_event,
                    ],
                        # 284 ビッグブラッグ(復活)
                    [
                     :check_add_lets_knife_r_feat_event,
                     :check_remove_lets_knife_r_feat_event,
                     :check_rotate_lets_knife_r_feat_event,
                     :use_lets_knife_r_feat_event,
                     :finish_lets_knife_r_feat_event,
                    ],
                        # 285 レッツナイフ(復活)
                    [
                     :check_add_prey_feat_event,
                     :check_remove_prey_feat_event,
                     :check_rotate_prey_feat_event,
                     :use_prey_feat_event,
                    ],
                        # 286 捕食
                    [
                     :check_add_rumination_feat_event,
                     :check_remove_rumination_feat_event,
                     :check_rotate_rumination_feat_event,
                     :use_rumination_feat_event,
                     :finish_rumination_feat_event,
                     :finish_rumination_feat_foe_chara_change_event,
                     :finish_rumination_feat_owner_chara_change_event,
                    ],
                        # 287 反芻
                    [
                     :check_add_pilum_feat_event,
                     :check_remove_pilum_feat_event,
                     :check_rotate_pilum_feat_event,
                     :use_pilum_feat_event,
                     :finish_pilum_feat_event,
                     :use_pilum_feat_damage_event,
                    ],
                        # 288 ピルム
                    [
                     :check_add_road_of_underground_feat_event,
                     :check_remove_road_of_underground_feat_event,
                     :check_rotate_road_of_underground_feat_event,
                     :use_road_of_underground_feat_event,
                     :use_road_of_underground_feat_finish_move_event,
                     :finish_road_of_underground_feat_event,
                    ],
                        # 289 地中の路
                    [
                     :check_add_fox_shadow_feat_event,
                     :check_remove_fox_shadow_feat_event,
                     :check_rotate_fox_shadow_feat_event,
                     :use_fox_shadow_feat_event,
                     :finish_fox_shadow_feat_event,
                    ],
                        # 290 狐分身
                    [
                     :check_add_fox_shoot_feat_event,
                     :check_remove_fox_shoot_feat_event,
                     :check_rotate_fox_shoot_feat_event,
                     :use_fox_shoot_feat_event,
                     :finish_fox_shoot_feat_event,
                     :use_fox_shoot_feat_damage_event,
                    ],
                        # 291 狐シュート
                    [
                     :check_add_fox_zone_feat_event,
                     :check_remove_fox_zone_feat_event,
                     :check_rotate_fox_zone_feat_event,
                     :use_fox_zone_feat_event,
                     :use_fox_zone_feat_attack_deal_det_chara_change_event,
                     :use_fox_zone_feat_attack_deal_change_initiative_event,
                     :use_fox_zone_feat_defense_deal_event,
                     :finish_fox_zone_feat_event,
                    ],
                        # 292 狐間空
                    [
                     :check_add_arrow_rain_feat_event,
                     :check_remove_arrow_rain_feat_event,
                     :check_rotate_arrow_rain_feat_event,
                     :use_arrow_rain_feat_event,
                     :finish_arrow_rain_feat_event,
                    ],
                        # 293 墜下する流星
                    [
                     :check_add_atemwende_feat_event,
                     :check_remove_atemwende_feat_event,
                     :check_rotate_atemwende_feat_event,
                     :use_atemwende_feat_event,
                     :finish_change_atemwende_feat_event,
                     :finish_turn_atemwende_feat_event,
                    ],
                        # 294 光輝強迫
                    [
                     :check_add_fadensonnen_feat_event,
                     :check_remove_fadensonnen_feat_event,
                     :check_rotate_fadensonnen_feat_event,
                     :use_fadensonnen_feat_event,
                     :finish_fadensonnen_feat_event,
                    ],
                        # 295 雪の重唱
                    [
                     :check_add_lichtzwang_feat_event,
                     :check_remove_lichtzwang_feat_event,
                     :check_rotate_lichtzwang_feat_event,
                     :use_lichtzwang_feat_event,
                     :finish_lichtzwang_feat_event,
                     :use_lichtzwang_feat_damage_event,
                    ],
                        # 296 紡がれる陽
                    [
                     :check_add_schneepart_feat_event,
                     :check_remove_schneepart_feat_event,
                     :check_rotate_schneepart_feat_event,
                     :use_schneepart_feat_event,
                     :use_schneepart_feat_damage_event,
                     :finish_schneepart_feat_event,
                    ],
                        # 297 溜息の転換
                    [
                     :check_add_highgate_feat_event,
                     :check_remove_highgate_feat_event,
                     :check_rotate_highgate_feat_event,
                     :use_highgate_feat_event,
                    ],
                        # 298 ハイゲート
                    [
                     :check_add_dorfloft_feat_event,
                     :check_remove_dorfloft_feat_event,
                     :check_rotate_dorfloft_feat_event,
                     :use_dorfloft_feat_event,
                     :use_dorfloft_feat_damage_event,
                    ],
                        # 299 ドルフルフト
                    [
                     :check_add_lumines_feat_event,
                     :check_remove_lumines_feat_event,
                     :check_rotate_lumines_feat_event,
                     :use_lumines_feat_event,
                     :use_lumines_feat_damage_event,
                     :finish_lumines_feat_event,
                    ],
                        # 300 ルミネセンス
                    [
                     :check_add_super_heroine_feat_event,
                     :check_remove_super_heroine_feat_event,
                     :check_rotate_super_heroine_feat_event,
                     :finish_super_heroine_feat_event,
                    ],
                        # 301 スーパーヒロイン(復活)
                    [
                     :check_add_stampede_feat_event,
                     :check_remove_stampede_feat_event,
                     :check_rotate_stampede_feat_event,
                     :use_stampede_feat_event,
                     :use_stampede_feat_damage_event,
                     :finish_stampede_feat_event,
                    ],
                        # 302 T・スタンピード
                    [
                     :check_add_death_control2_feat_event,
                     :check_remove_death_control2_feat_event,
                     :check_rotate_death_control2_feat_event,
                     :use_death_control2_feat_event,
                     :use_death_control2_feat_damage_event,
                     :finish_death_control2_feat_event,
                    ],
                        # 303 D・コントロール(復活)
                    [
                     :check_add_kengi_feat_event,
                     :check_remove_kengi_feat_event,
                     :check_rotate_kengi_feat_event,
                     :use_kengi_feat_event,
                     :use_kengi_feat_roll_chancel_event,
                     :use_kengi_feat_battle_result_event,
                     :finish_kengi_feat_event,
                    ],
                        # 304 俺様の剣技に見惚れろ
                    [
                     :check_add_dokowo_feat_event,
                     :check_remove_dokowo_feat_event,
                     :check_rotate_dokowo_feat_event,
                     :finish_dokowo_feat_event,
                    ],
                        # 305 何処を見てやがる
                    [
                     :check_add_mikitta_feat_event,
                     :check_remove_mikitta_feat_event,
                     :check_rotate_mikitta_feat_event,
                     :finish_mikitta_feat_event,
                    ],
                        # 306 お前の技は見切った
                    [
                     :check_add_hontou_feat_event,
                     :check_remove_hontou_feat_event,
                     :check_rotate_hontou_feat_event,
                     :use_hontou_feat_event,
                     :use_hontou_feat_roll_chancel_event,
                     :use_hontou_feat_battle_result_event,
                     :finish_hontou_feat_event,
                    ],
                        # 307 これが俺様の本当の力だ
                    [
                     :check_add_invited_feat_event,
                     :check_remove_invited_feat_event,
                     :check_rotate_invited_feat_event,
                     :finish_invited_feat_event,
                    ],
                        # 308 招かれるものども
                    [
                     :check_add_through_hand_feat_event,
                     :check_remove_through_hand_feat_event,
                     :check_rotate_through_hand_feat_event,
                     :use_through_hand_feat_event,
                    ],
                        # 309 透き通る手
                    [
                     :check_add_prof_breath_feat_event,
                     :check_remove_prof_breath_feat_event,
                     :check_rotate_prof_breath_feat_event,
                     :finish_prof_breath_feat_event,
                    ],
                        # 310 深遠なる息
                    [
                     :check_add_seven_wish_feat_event,
                     :check_remove_seven_wish_feat_event,
                     :check_rotate_seven_wish_feat_event,
                     :use_seven_wish_feat_event,
                     :use_seven_wish_feat_damage_event,
                    ],
                        # 311 7つの願い
                    [
                     :check_add_thirteen_eyes_r_feat_event,
                     :check_remove_thirteen_eyes_r_feat_event,
                     :check_rotate_thirteen_eyes_r_feat_event,
                     :use_owner_thirteen_eyes_r_feat_event,
                     :use_foe_thirteen_eyes_r_feat_event,
                     :finish_thirteen_eyes_r_feat_event,
                     :use_thirteen_eyes_r_feat_damage_event,
                    ],
                        # 312 13の眼(復活)
                    [
                     :check_add_thorn_care_r_feat_event,
                     :check_remove_thorn_care_r_feat_event,
                     :check_rotate_thorn_care_r_feat_event,
                     :use_thorn_care_r_feat_event,
                     :use_thorn_care_r_feat_damage_event,
                     :finish_thorn_care_r_feat_event,
                    ],
                        # 313 茨の構え(復活)
                    [
                     :check_add_liberating_sword_r_feat_event,
                     :check_remove_liberating_sword_r_feat_event,
                     :check_rotate_liberating_sword_r_feat_event,
                     :use_liberating_sword_r_feat_event,
                     :use_liberating_sword_r_feat_damage_event,
                     :finish_liberating_sword_r_feat_event,
                    ],
                        # 314 解放剣(復活)
                    [
                     :check_add_curse_sword_r_feat_event,
                     :check_remove_curse_sword_r_feat_event,
                     :check_rotate_curse_sword_r_feat_event,
                     :use_curse_sword_r_feat_event,
                     :use_curse_sword_r_feat_damage_event,
                     :finish_curse_sword_r_feat_event,
                    ],
                        # 315 獄剣
                    [
                     :check_add_flame_ring_feat_event,
                     :check_remove_flame_ring_feat_event,
                     :check_rotate_flame_ring_feat_event,
                     :use_flame_ring_feat_event,
                     :finish_flame_ring_feat_event,
                    ],
                        # 316 火の輪くぐり
                    [
                     :check_add_piano_feat_event,
                     :check_remove_piano_feat_event,
                     :check_rotate_piano_feat_event,
                     :use_piano_feat_event,
                     :use_piano_feat_damage_event,
                     :finish_piano_feat_event,
                    ],
                        # 317 ピアノ
                    [
                     :check_add_ona_ball_feat_event,
                     :check_remove_ona_ball_feat_event,
                     :check_rotate_ona_ball_feat_event,
                     :finish_next_ona_ball_feat_event,
                    ],
                        # 318 玉乗り
                    [
                     :check_add_violent_feat_event,
                     :check_remove_violent_feat_event,
                     :check_rotate_violent_feat_event,
                     :finish_violent_feat_change_event,
                     :finish_violent_feat_event,
                    ],
                        # 319 暴れる
                    [
                     :check_add_balance_life_feat_event,
                     :check_remove_balance_life_feat_event,
                     :check_rotate_balance_life_feat_event,
                     :use_balance_life_feat_event,
                     :use_balance_life_feat_damage_event,
                     :finish_balance_life_feat_event,
                    ],
                        # 320 バランスライフ
                    [
                     :check_add_lifetime_sound_feat_event,
                     :check_remove_lifetime_sound_feat_event,
                     :check_rotate_lifetime_sound_feat_event,
                     :use_lifetime_sound_feat_event,
                     :finish_lifetime_sound_feat_event,
                     :finish_lifetime_sound_feat_damage_event,
                    ],
                        # 321 ライフタイムサウンド
                    [
                     :check_add_coma_white_feat_event,
                     :check_remove_coma_white_feat_event,
                     :check_rotate_coma_white_feat_event,
                     :use_coma_white_feat_event,
                     :finish_coma_white_feat_event,
                    ],
                        # 322 コマホワイト
                    [
                     :check_add_goes_to_dark_feat_event,
                     :check_remove_goes_to_dark_feat_event,
                     :check_rotate_goes_to_dark_feat_event,
                     :finish_goes_to_dark_feat_event,
                    ],
                        # 323 ゴーズトゥダーク
                    [
                     :check_add_counter_guard_feat_event,
                     :check_remove_counter_guard_feat_event,
                     :check_rotate_counter_guard_feat_event,
                     :use_ex_counter_guard_feat_event,
                     :use_ex_counter_guard_feat_dice_attr_event,
                     :finish_counter_guard_feat_event,
                    ],
                        # 324 Exカウンターガード
                    [
                     :check_add_thirteen_eyes_feat_event,
                     :check_remove_thirteen_eyes_feat_event,
                     :check_rotate_thirteen_eyes_feat_event,
                     :use_owner_thirteen_eyes_feat_event,
                     :use_foe_ex_thirteen_eyes_feat_event,
                     :finish_ex_thirteen_eyes_feat_event,
                     :use_thirteen_eyes_feat_damage_event,
                    ],
                        # 325 Ex13の眼
                    [
                     :check_add_razors_edge_feat_event,
                     :check_remove_razors_edge_feat_event,
                     :check_rotate_razors_edge_feat_event,
                     :use_owner_razors_edge_feat_event,
                     :use_foe_ex_razors_edge_feat_event,
                     :use_ex_razors_edge_feat_dice_attr_event,
                     :finish_razors_edge_feat_event,
                    ],
                        # 326 Exレイザーズエッジ
                    [
                     :check_add_red_moon_feat_event,
                     :check_remove_red_moon_feat_event,
                     :check_rotate_red_moon_feat_event,
                     :use_red_moon_feat_event,
                     :use_ex_red_moon_feat_dice_attr_event,
                     :use_red_moon_feat_damage_event,
                     :finish_red_moon_feat_event,
                    ],
                        # 327 Ex深紅の月
                    [
                     :check_add_hassen_feat_event,
                     :check_remove_hassen_feat_event,
                     :check_rotate_hassen_feat_event,
                     :use_hassen_feat_event,
                     :finish_hassen_feat_event,
                    ],
                        # 328 八閃
                    [
                     :check_add_handled_slash_r_feat_event,
                     :check_remove_handled_slash_r_feat_event,
                     :check_rotate_handled_slash_r_feat_event,
                     :use_handled_slash_r_feat_event,
                     :use_handled_slash_r_feat_damage_event,
                     :finish_handled_slash_r_feat_event,
                    ],
                        # 329 百閃R
                    [
                     :check_add_rakshasa_stance_feat_event,
                     :check_remove_rakshasa_stance_feat_event,
                     :check_rotate_rakshasa_stance_feat_event,
                     :check_rakshasa_stance_state_change_event,
                     :use_rakshasa_stance_feat_event,
                     :use_rakshasa_stance_feat_result_event,
                     :on_rakshasa_stance_feat_event,
                     :off_rakshasa_stance_feat_event,
                     :finish_rakshasa_stance_feat_event,
                    ],
                        # 330 羅刹の構え
                    [
                     :check_add_obituary_feat_event,
                     :check_remove_obituary_feat_event,
                     :check_rotate_obituary_feat_event,
                     :use_obituary_feat_event,
                     :use_obituary_feat_damage_event,
                     :finish_obituary_feat_event,
                    ],
                        # 331 オビチュアリ
                    [
                     :check_add_solvent_rain_r_feat_event,
                     :check_remove_solvent_rain_r_feat_event,
                     :check_rotate_solvent_rain_r_feat_event,
                     :use_solvent_rain_r_feat_event,
                     :finish_solvent_rain_r_feat_event,
                    ],
                        # 332 ソルベント・レインR
                    [
                     :check_add_kirigakure_feat_event,
                     :check_remove_kirigakure_feat_event,
                     :check_rotate_kirigakure_feat_event,
                     :check_add_kirigakure_feat_foe_attack_event,
                     :check_remove_kirigakure_feat_foe_attack_event,
                     :check_rotate_kirigakure_feat_foe_attack_event,
                     :check_add_kirigakure_feat_foe_defense_event,
                     :check_remove_kirigakure_feat_foe_defense_event,
                     :check_rotate_kirigakure_feat_foe_defense_event,
                     :use_kirigakure_feat_calc_event,
                     :use_kirigakure_feat_phase_init_event,
                     :use_kirigakure_feat_defense_done_owner_event,
                     :use_kirigakure_feat_defense_done_foe_event,
                     :use_kirigakure_feat_event,
                     :use_kirigakure_feat_det_change_event,
                     :finish_kirigakure_feat_owner_damaged_event,
                     :finish_kirigakure_feat_do_damage_event,
                     :finish_kirigakure_feat_finish_turn_event,
                    ],
                        # 333 霧隠れ
                    [
                     :check_add_mikagami_feat_event,
                     :check_remove_mikagami_feat_event,
                     :check_rotate_mikagami_feat_event,
                     :use_mikagami_feat_event,
                     :finish_mikagami_feat_event,
                    ],
                        # 334 水鏡
                    [
                     :check_add_mutual_love_feat_event,
                     :check_remove_mutual_love_feat_event,
                     :check_rotate_mutual_love_feat_event,
                     :use_mutual_love_feat_event,
                     :use_mutual_love_feat_damage_event,
                     :use_mutual_love_feat_const_damage_event,
                     :finish_mutual_love_feat_event,
                    ],
                        # 335 落花流水
                    [
                     :check_add_mere_shadow_feat_event,
                     :check_remove_mere_shadow_feat_event,
                     :check_rotate_mere_shadow_feat_event,
                     :use_mere_shadow_feat_event,
                     :finish_mere_shadow_feat_event,
                     :finish_mere_shadow_feat_dice_attr_event,
                    ],
                        # 336 鏡花水月
                    [
                     :check_add_scapulimancy_feat_event,
                     :check_remove_scapulimancy_feat_event,
                     :check_rotate_scapulimancy_feat_event,
                     :finish_scapulimancy_feat_event,
                    ],
                        # 337 亀占い
                    [
                     :check_add_soil_guard_feat_event,
                     :check_remove_soil_guard_feat_event,
                     :check_rotate_soil_guard_feat_event,
                     :use_soil_guard_feat_event,
                     :use_soil_guard_feat_damage_event,
                    ],
                        # 338 土盾
                    [
                     :check_add_carapace_spin_feat_event,
                     :check_remove_carapace_spin_feat_event,
                     :check_rotate_carapace_spin_feat_event,
                     :finish_carapace_spin_feat_event,
                    ],
                        # 339 甲羅スピン
                    [
                     :check_add_vendetta_feat_event,
                     :check_remove_vendetta_feat_event,
                     :check_rotate_vendetta_feat_event,
                     :use_vendetta_feat_event,
                     :finish_vendetta_feat_event,
                    ],
                       # 340 ヴェンデッタ
                    [
                     :check_add_avengers_feat_event,
                     :check_remove_avengers_feat_event,
                     :check_rotate_avengers_feat_event,
                     :use_avengers_feat_event,
                     :finish_avengers_feat_event,
                    ],
                        # 341 アヴェンジャー
                    [
                     :check_add_sharpen_edge_feat_event,
                     :check_remove_sharpen_edge_feat_event,
                     :check_rotate_sharpen_edge_feat_event,
                     :use_sharpen_edge_feat_event,
                     :check_sharpen_edge_state_change_event,
                     :check_sharpen_edge_state_dead_change_event,
                     :use_sharpen_edge_state_damage_event,
                     :finish_sharpen_edge_state_event,
                    ],
                        # 342 シャープンエッジ
                    [
                     :check_add_hacknine_feat_event,
                     :check_remove_hacknine_feat_event,
                     :check_rotate_hacknine_feat_event,
                     :use_hacknine_feat_event,
                     :finish_hacknine_feat_event,
                    ],
                        # 343 ハックナイン
                    [
                     :check_add_black_mageia_feat_event,
                     :check_remove_black_mageia_feat_event,
                     :check_rotate_black_mageia_feat_event,
                     :finish_black_mageia_feat_event,
                    ],
                        # 344 ブラックマゲイア
                    [
                     :check_add_corps_drain_feat_event,
                     :check_remove_corps_drain_feat_event,
                     :check_rotate_corps_drain_feat_event,
                     :finish_corps_drain_feat_event,
                     :use_corps_drain_feat_damage_event,
                    ],
                        # 345 コープスドレイン
                    [
                     :check_add_invert_feat_event,
                     :check_remove_invert_feat_event,
                     :check_rotate_invert_feat_event,
                     :finish_invert_feat_event,
                    ],
                        # 346 インヴァート
                    [
                     :check_add_night_hawk_feat_event,
                     :check_remove_night_hawk_feat_event,
                     :check_rotate_night_hawk_feat_event,
                     :use_night_hawk_feat_event,
                     :use_night_hawk_feat_det_mp_before1_event,
                     :use_night_hawk_feat_det_mp_before2_event,
                     :use_night_hawk_feat_foe_change_event,
                     :use_night_hawk_feat_owner_change_event,
                     :use_night_hawk_feat_dead_change_event,
                     :finish_night_hawk_feat_change_event,
                    ],
                        # 347 追跡する夜鷹
                    [
                     :check_add_phantom_barrett_feat_event,
                     :check_remove_phantom_barrett_feat_event,
                     :check_rotate_phantom_barrett_feat_event,
                     :use_phantom_barrett_feat_event,
                     :finish_phantom_barrett_feat_event,
                    ],
                        # 348 幽幻の剛弾
                    [
                     :check_add_one_act_feat_event,
                     :check_remove_one_act_feat_event,
                     :check_rotate_one_act_feat_event,
                     :use_one_act_feat_event,
                     :finish_one_act_feat_event,
                    ],
                        # 349 惑わしの一幕
                    [
                     :check_add_final_barrett_feat_event,
                     :check_remove_final_barrett_feat_event,
                     :check_rotate_final_barrett_feat_event,
                     :finish_final_barrett_feat_event,
                    ],
                        # 350 終極の烈弾
                    [
                     :check_add_grimmdead_feat_event,
                     :check_remove_grimmdead_feat_event,
                     :check_rotate_grimmdead_feat_event,
                     :use_grimmdead_feat_calc_event,
                     :use_grimmdead_feat_event,
                     :use_grimmdead_feat_move_before_event,
                     :use_grimmdead_feat_move_after_event,
                     :finish_grimmdead_feat_event,
                    ],
                        # 351 グリムデッド
                    [
                     :check_add_wunderkammer_feat_event,
                     :check_remove_wunderkammer_feat_event,
                     :check_rotate_wunderkammer_feat_event,
                     :use_wunderkammer_feat_event,
                     :use_wunderkammer_feat_damage_event,
                     :finish_wunderkammer_feat_event,
                    ],
                        # 352 ヴンダーカンマー
                    [
                     :check_add_constraint_feat_event,
                     :check_remove_constraint_feat_event,
                     :check_rotate_constraint_feat_event,
                     :use_constraint_feat_event,
                     :use_constraint_feat_damage_event,
                     :finish_constraint_feat_event,
                    ],
                        # 353 コンストレイント
                    [
                     :check_add_renovate_atrandom_feat_event,
                     :check_remove_renovate_atrandom_feat_event,
                     :check_rotate_renovate_atrandom_feat_event,
                     :use_renovate_atrandom_feat_event,
                     :use_renovate_atrandom_feat_damage_event,
                     :finish_renovate_atrandom_feat_event,
                    ],
                        # 354 リノベートアトランダム
                    [
                     :check_add_backbeard_feat_event,
                     :check_remove_backbeard_feat_event,
                     :check_rotate_backbeard_feat_event,
                     :use_backbeard_feat_damage_event,
                     :finish_backbeard_feat_event,
                    ],
                        # 355 催眠術
                    [
                     :check_add_shadow_stitch_feat_event,
                     :check_remove_shadow_stitch_feat_event,
                     :check_rotate_shadow_stitch_feat_event,
                     :use_shadow_stitch_feat_event,
                     :use_shadow_stitch_feat_damage_event,
                     :finish_shadow_stitch_feat_event,
                    ],
                        # 356 影縫い
                    [
                     :check_add_mextli_feat_event,
                     :check_remove_mextli_feat_event,
                     :check_rotate_mextli_feat_event,
                     :use_mextli_feat_event,
                     :check_damage_insurance_change_event,
                     :check_damage_insurance_dead_change_event,
                     :use_damage_insurance_damage_event,
                    ],
                        # 357 ミキストリ
                    [
                     :check_add_rivet_and_surge_feat_event,
                     :check_remove_rivet_and_surge_feat_event,
                     :check_rotate_rivet_and_surge_feat_event,
                     :use_rivet_and_surge_feat_attack_event,
                     :use_rivet_and_surge_feat_defense_event,
                     :cutin_rivet_and_surge_feat_event,
                     :finish_rivet_and_surge_feat_event,
                    ],
                       # 358 リベットアンドサージ
                    [
                     :check_add_phantomas_feat_event,
                     :check_remove_phantomas_feat_event,
                     :check_rotate_phantomas_feat_event,
                     :finish_phantomas_feat_event,
                    ],
                       # 359 ファントマ
                    [
                     :check_add_danger_drug_feat_event,
                     :check_remove_danger_drug_feat_event,
                     :check_rotate_danger_drug_feat_event,
                     :finish_danger_drug_feat_event,
                    ],
                        # 360 危険ドラッグ
                    [
                     :check_add_three_thunder_feat_event,
                     :check_remove_three_thunder_feat_event,
                     :check_rotate_three_thunder_feat_event,
                     :use_three_thunder_feat_event,
                     :finish_three_thunder_feat_event,
                    ],
                        # 361 HP3サンダー
                    [
                     :check_add_prime_heal_feat_event,
                     :check_remove_prime_heal_feat_event,
                     :check_rotate_prime_heal_feat_event,
                     :use_prime_heal_feat_event,
                     :finish_prime_heal_feat_event,
                    ],
                        # 362 素数ヒール
                    [
                     :check_add_four_comet_feat_event,
                     :check_remove_four_comet_feat_event,
                     :check_rotate_four_comet_feat_event,
                     :use_four_comet_feat_event,
                     :finish_four_comet_feat_event,
                    ],
                        # 363 HP4コメット
                    [
                     :check_add_club_jugg_feat_event,
                     :check_remove_club_jugg_feat_event,
                     :check_rotate_club_jugg_feat_event,
                     :use_club_jugg_feat_event,
                     :use_club_jugg_feat_deal_event,
                     :finish_club_jugg_feat_event,
                    ],
                        # 364 クラブジャグ
                    [
                     :check_add_knife_jugg_feat_event,
                     :check_remove_knife_jugg_feat_event,
                     :check_rotate_knife_jugg_feat_event,
                     :use_knife_jugg_feat_event,
                     :use_knife_jugg_feat_deal_event,
                     :finish_knife_jugg_feat_event,
                    ],
                        # 365 ナイフジャグ
                    [
                     :check_add_blowing_fire_feat_event,
                     :check_remove_blowing_fire_feat_event,
                     :check_rotate_blowing_fire_feat_event,
                     :use_blowing_fire_feat_event,
                     :finish_blowing_fire_feat_event,
                    ],
                        # 366 火吹き
                    [
                     :check_add_balance_ball_feat_event,
                     :check_remove_balance_ball_feat_event,
                     :check_rotate_balance_ball_feat_event,
                     :use_balance_ball_feat_event,
                     :finish_balance_ball_feat_event,
                    ],
                        # 367 バランスボール
                    [
                     :check_add_bad_milk_feat_event,
                     :check_remove_bad_milk_feat_event,
                     :check_rotate_bad_milk_feat_event,
                     :use_bad_milk_feat_event,
                     :use_bad_milk_feat_recalc_event,
                     :use_ex_bad_milk_feat_event,
                     :finish_change_bad_milk_feat_event,
                     :finish_bad_milk_feat_event,
                     :finish_turn_bad_milk_feat_event,
                    ],
                        # 368 劣化ミルク
                    [
                     :check_add_mira_hp_feat_event,
                     :check_remove_mira_hp_feat_event,
                     :check_rotate_mira_hp_feat_event,
                     :use_mira_hp_feat_event,
                     :use_mira_hp_feat_damage_event,
                     :finish_mira_hp_feat_event,
                    ],
                        # 369 ミラHP
                    [
                     :check_add_skill_drain_feat_event,
                     :check_remove_skill_drain_feat_event,
                     :check_rotate_skill_drain_feat_event,
                     :use_skill_drain_feat_event,
                     :use_skill_drain_feat_damage_event,
                     :finish_skill_drain_feat_event,
                     :finish_skill_drain_feat_finish_event,
                     :finish_override_skill_state_event,
                    ],
                        # 370 スキルドレイン
                    [
                     :check_add_coffin_feat_event,
                     :check_remove_coffin_feat_event,
                     :check_rotate_coffin_feat_event,
                     :use_coffin_feat_event,
                     :finish_coffin_feat_event,
                    ],
                        # 371 コフィン
                    [
                     :check_add_dark_eyes_feat_event,
                     :check_remove_dark_eyes_feat_event,
                     :check_rotate_dark_eyes_feat_event,
                     :use_dark_eyes_feat_event,
                     :use_dark_eyes_feat_move_event,
                     :use_dark_eyes_feat_damage_event,
                    ],
                        # 372 玄青眼
                    [
                     :check_add_crows_claw_feat_event,
                     :check_remove_crows_claw_feat_event,
                     :check_rotate_crows_claw_feat_event,
                     :use_crows_claw_feat_event,
                     :finish_crows_claw_feat_event,
                    ],
                        # 373 烏爪一転
                    [
                     :check_add_mole_feat_event,
                     :check_remove_mole_feat_event,
                     :check_rotate_mole_feat_event,
                     :use_mole_feat_event,
                     :use_mole_feat_damage_event,
                     :finish_mole_feat_event,
                    ],
                        # 374 土竜一転
                    [
                     :check_add_sunset_feat_event,
                     :check_remove_sunset_feat_event,
                     :check_rotate_sunset_feat_event,
                     :use_sunset_feat_event,
                     :use_sunset_feat_result_event,
                     :use_sunset_feat_damage_check_event,
                     :use_sunset_feat_const_damage_event,
                    ],
                        # 375 五彩晩霞
                    [
                     :check_add_vine_feat_event,
                     :check_remove_vine_feat_event,
                     :check_rotate_vine_feat_event,
                     :use_vine_feat_event,
                     :use_vine_feat_damage_event,
                     :finish_vine_feat_event,
                     :finish_vine_feat_turn_event
                    ],
                        # 376 蔓縛り
                    [
                     :check_add_grape_vine_feat_event,
                     :check_remove_grape_vine_feat_event,
                     :check_rotate_grape_vine_feat_event,
                     :use_grape_vine_feat_event,
                     :use_grape_vine_feat_damage_event,
                     :use_grape_vine_feat_foe_event
                    ],
                        # 377 吸収
                    [
                     :check_add_thunder_struck_feat_event,
                     :check_remove_thunder_struck_feat_event,
                     :check_rotate_thunder_struck_feat_event,
                     :use_thunder_struck_feat_event,
                     :finish_thunder_struck_feat_event,
                     :finish_thunder_struck_feat_end_event,
                    ],
                        # 378 サンダーストラック
                    [
                     :check_add_weave_world_feat_event,
                     :check_remove_weave_world_feat_event,
                     :check_rotate_weave_world_feat_event,
                     :use_weave_world_feat_event,
                     :finish_weave_world_feat_event,
                    ],
                        # 379 ウィーヴワールド
                    [
                     :check_add_collection_feat_event,
                     :check_remove_collection_feat_event,
                     :check_rotate_collection_feat_event,
                     :check_table_collection_feat_move_event,
                     :check_table_collection_feat_battle_event,
                     :use_collection_feat_deal_event,
                     :use_collection_feat_event,
                     :finish_collection_feat_event,
                     :check_ending_collection_feat_event,
                    ],
                        # 380 コレクション
                    [
                     :check_add_restriction_feat_event,
                     :check_remove_restriction_feat_event,
                     :check_rotate_restriction_feat_event,
                     :use_restriction_feat_event,
                     :finish_restriction_feat_event,
                    ],
                        # 381 Dリストリクション
                    [
                     :check_add_dabs_feat_event,
                     :check_remove_dabs_feat_event,
                     :check_rotate_dabs_feat_event,
                     :use_dabs_feat_event,
                     :finish_dabs_feat_event,
                    ],
                        # 382 DABS
                    [
                     :check_add_vibration_feat_event,
                     :check_remove_vibration_feat_event,
                     :check_rotate_vibration_feat_event,
                     :use_vibration_feat_event,
                     :finish_vibration_feat_event,
                    ],
                        # 383 VIBRATION
                    [
                     :check_add_tot_feat_event,
                     :check_remove_tot_feat_event,
                     :check_rotate_tot_feat_event,
                     :use_tot_feat_event,
                     :use_tot_feat_damage_event,
                     :finish_tot_feat_event,
                    ],
                        # 384 ToT
                    [
                     :check_add_duck_apple_feat_event,
                     :check_remove_duck_apple_feat_event,
                     :check_rotate_duck_apple_feat_event,
                     :finish_duck_apple_feat_event,
                    ],
                        # 385 ダックアップル
                    [
                     :check_add_rampage_feat_event,
                     :check_remove_rampage_feat_event,
                     :check_rotate_rampage_feat_event,
                     :use_rampage_feat_event,
                     :use_rampage_feat_damage_event,
                     :finish_rampage_feat_event,
                    ],
                        # 386 ランページ
                    [
                     :check_add_scratch_fire_feat_event,
                     :check_remove_scratch_fire_feat_event,
                     :check_rotate_scratch_fire_feat_event,
                     :use_scratch_fire_feat_event,
                     :use_scratch_fire_feat_damage_event,
                     :finish_scratch_fire_feat_event,
                    ],
                        # 387 スクラッチファイア
                    [
                     :check_add_blue_ruin_feat_event,
                     :check_remove_blue_ruin_feat_event,
                     :check_rotate_blue_ruin_feat_event,
                     :use_blue_ruin_feat_event,
                     :finish_blue_ruin_feat_event,
                    ],
                        # 388 ブルールーイン
                    [
                     :check_add_third_step_feat_event,
                     :check_remove_third_step_feat_event,
                     :check_rotate_third_step_feat_event,
                     :use_third_step_feat_event,
                     :use_third_step_feat_damage_event,
                     :finish_third_step_feat_event,
                    ],
                        # 389 サードステップ
                    [
                     :check_add_metal_shield_feat_event,
                     :check_remove_metal_shield_feat_event,
                     :check_rotate_metal_shield_feat_event,
                     :use_metal_shield_feat_event,
                     :finish_metal_shield_feat_event,
                    ],
                        # 390 メタルシールド
                    [
                     :check_add_magnetic_field_feat_event,
                     :check_remove_magnetic_field_feat_event,
                     :check_rotate_magnetic_field_feat_event,
                     :use_magnetic_field_feat_event,
                     :finish_magnetic_field_feat_event,
                     :final_magnetic_field_feat_event,
                    ],
                        # 391 滞留する光波
                    [
                     :check_add_afterglow_feat_event,
                     :check_remove_afterglow_feat_event,
                     :check_rotate_afterglow_feat_event,
                     :use_afterglow_feat_event,
                     :use_afterglow_feat_damage_event,
                     :finish_afterglow_feat_event,
                    ],
                        # 392 拒絶の余光
                    [
                     :check_add_keeper_feat_event,
                     :check_remove_keeper_feat_event,
                     :check_rotate_keeper_feat_event,
                     :use_keeper_feat_event,
                     :finish_keeper_feat_event,
                    ],
                        # 393 夕暉の番人
                    [
                     :check_add_healing_schock_feat_event,
                     :check_remove_healing_schock_feat_event,
                     :check_rotate_healing_schock_feat_event,
                     :use_healing_schock_feat_event,
                     :finish_healing_schock_feat_event,
                    ],
                        # 394 ヒーリングショック
                    [
                     :check_add_claymore_feat_event,
                     :check_remove_claymore_feat_event,
                     :check_rotate_claymore_feat_event,
                     :finish_claymore_feat_event,
                    ],
                        # 395 クレイモア
                    [
                     :check_add_trap_chase_feat_event,
                     :check_remove_trap_chase_feat_event,
                     :check_rotate_trap_chase_feat_event,
                     :use_trap_chase_feat_event,
                     :use_trap_chase_feat_damage_event,
                     :finish_trap_chase_feat_event,
                    ],
                        # 396トラップチェイス
                    [
                     :check_add_panic_feat_event,
                     :check_remove_panic_feat_event,
                     :check_rotate_panic_feat_event,
                     :use_panic_feat_event,
                     :use_panic_feat_damage_event,
                     :finish_panic_feat_event,
                    ],
                        # 397 パニックグレネード
                    [
                     :check_add_bullet_counter_feat_event,
                     :check_remove_bullet_counter_feat_event,
                     :check_rotate_bullet_counter_feat_event,
                     :use_bullet_counter_feat_event,
                     :finish_bullet_counter_feat_event,
                    ],
                        # 398 バレットカウンター
                    [
                     :check_add_bean_storm_feat_event,
                     :check_remove_bean_storm_feat_event,
                     :check_rotate_bean_storm_feat_event,
                     :use_bean_storm_feat_event,
                     :finish_bean_storm_feat_event,
                    ],
                        # 399 大菽嵐
                    [
                     :check_add_joker_feat_event,
                     :check_remove_joker_feat_event,
                     :check_rotate_joker_feat_event,
                     :finish_joker_feat_event,
                    ],
                        # 400 ジョーカー
                    [
                     :check_add_familiar_feat_event,
                     :check_remove_familiar_feat_event,
                     :check_rotate_familiar_feat_event,
                     :use_familiar_feat_event,
                     :finish_familiar_feat_event,
                    ],
                        # 401 ファミリア
                    [
                     :check_add_crown_crown_feat_event,
                     :check_remove_crown_crown_feat_event,
                     :check_rotate_crown_crown_feat_event,
                     :use_crown_crown_feat_event,
                     :use_crown_crown_feat_damage_event,
                     :finish_crown_crown_feat_event,

                    ],
                        # 402 クラウンクラウン
                    [
                     :check_add_riddle_box_feat_event,
                     :check_remove_riddle_box_feat_event,
                     :check_rotate_riddle_box_feat_event,
                     :use_riddle_box_feat_event,
                     :use_riddle_box_feat_damage_event,
                     :finish_riddle_box_feat_event,
                    ],
                        # 403 リドルボックス
                    [
                     :check_add_flutter_sword_dance_feat_event,
                     :check_remove_flutter_sword_dance_feat_event,
                     :check_rotate_flutter_sword_dance_feat_event,
                     :finish_flutter_sword_dance_feat_event,
                    ],
                        # 404 翻る剣舞
                    [
                     :check_add_ritual_of_bravery_feat_event,
                     :check_remove_ritual_of_bravery_feat_event,
                     :check_rotate_ritual_of_bravery_feat_event,
                     :use_ritual_of_bravery_feat_event,
                     :finish_ritual_of_bravery_feat_event,
                    ],
                        # 405 勇猛の儀
                    [
                     :check_add_hunting_cheetah_feat_event,
                     :check_remove_hunting_cheetah_feat_event,
                     :check_rotate_hunting_cheetah_feat_event,
                     :use_hunting_cheetah_feat_event,
                     :use_hunting_cheetah_feat_damage_event,
                     :finish_hunting_cheetah_feat_event,
                    ],
                        # 406 狩猟豹の剣
                    [
                     :check_add_probe_feat_event,
                     :check_remove_probe_feat_event,
                     :check_rotate_probe_feat_event,
                     :use_probe_feat_pow_event,
                     :use_probe_feat_event,
                     :finish_probe_feat_event,
                    ],
                        # 407 探りの一手
                    [
                     :check_add_tailoring_feat_event,
                     :check_remove_tailoring_feat_event,
                     :check_rotate_tailoring_feat_event,
                     :use_tailoring_feat_event,
                     :use_tailoring_feat_damage_event,
                     :finish_tailoring_feat_event,
                    ],
                        # 408 仕立
                    [
                     :check_add_cut_feat_event,
                     :check_remove_cut_feat_event,
                     :check_rotate_cut_feat_event,
                     :use_cut_feat_event,
                     :finish_cut_feat_event,
                    ],
                        # 409 裁断
                    [
                     :check_add_sewing_feat_event,
                     :check_remove_sewing_feat_event,
                     :check_rotate_sewing_feat_event,
                     :use_sewing_feat_event,
                     :finish_sewing_feat_event,
                    ],
                        # 410 縫製
                    [
                     :check_add_cancellation_feat_event,
                     :check_remove_cancellation_feat_event,
                     :check_rotate_cancellation_feat_event,
                     :finish_cancellation_feat_event,
                    ],
                        # 411 DofD
                    [
                     :check_add_seiho_feat_event,
                     :check_remove_seiho_feat_event,
                     :check_rotate_seiho_feat_event,
                     :use_seiho_feat_event,
                     :finish_seiho_feat_event,
                    ],
                        # 412 整法
                    [
                     :check_add_dokko_feat_event,
                     :check_remove_dokko_feat_event,
                     :check_rotate_dokko_feat_event,
                     :use_dokko_feat_event,
                     :use_dokko_feat_damage_event,
                     :finish_dokko_feat_event,
                    ],  # 413 独鈷
                    [
                     :check_add_nyoi_feat_event,
                     :check_remove_nyoi_feat_event,
                     :check_rotate_nyoi_feat_event,
                     :use_nyoi_feat_event,
                     :use_nyoi_feat_damage_event,
                     :finish_nyoi_feat_event,
                    ],  # 414 如意
                    [
                     :check_add_kongo_feat_event,
                     :check_remove_kongo_feat_event,
                     :check_rotate_kongo_feat_event,
                     :use_kongo_feat_event,
                     :use_kongo_feat_damage_event,
                     :finish_kongo_feat_event,
                    ],
                        # 415 金剛
                    [
                     :check_add_carp_quake_feat_event,
                     :check_remove_carp_quake_feat_event,
                     :check_rotate_carp_quake_feat_event,
                     :finish_carp_quake_feat_event,
                    ],
                        # 416 鯉震
                    [
                     :check_add_carp_lightning_feat_event,
                     :check_remove_carp_lightning_feat_event,
                     :check_rotate_carp_lightning_feat_event,
                     :use_carp_lightning_feat_event,
                     :use_carp_lightning_feat_damage_event,
                     :finish_carp_lightning_feat_event,
                    ],
                        # 417 鯉光
                    [
                     :check_add_field_lock_feat_event,
                     :check_remove_field_lock_feat_event,
                     :check_rotate_field_lock_feat_event,
                     :use_field_lock_feat_event,
                    ],
                        # 418 フィールドロック
                    [
                     :check_add_arrest_feat_event,
                     :check_remove_arrest_feat_event,
                     :check_rotate_arrest_feat_event,
                     :use_arrest_feat_event,
                     :use_arrest_feat_damage_event,
                     :finish_arrest_feat_event,
                    ],
                        # 419 捕縛
                    [
                     :check_add_quick_draw_feat_event,
                     :check_remove_quick_draw_feat_event,
                     :check_rotate_quick_draw_feat_event,
                     :use_quick_draw_feat_event,
                     :finish_quick_draw_feat_event,
                    ],
                        # 420 クイックドロー
                    [
                     :check_add_gaze_feat_event,
                     :check_remove_gaze_feat_event,
                     :check_rotate_gaze_feat_event,
                     :use_gaze_feat_event,
                     :finish_gaze_feat_event,
                     :finish_chara_change_gaze_feat_event,
                     :finish_foe_chara_change_karmic_time_feat_event,
                    ],
                        # 421 ゲイズ
                    [
                     :check_add_monitoring_feat_event,
                     :check_remove_monitoring_feat_event,
                     :check_rotate_monitoring_feat_event,
                     :use_monitoring_feat_event,
                     :use_monitoring_feat_damage_event,
                     :finish_monitoring_feat_event,
                    ],
                        # 422 監視
                    [
                     :check_add_time_lag_draw_feat_event,
                     :check_remove_time_lag_draw_feat_event,
                     :check_rotate_time_lag_draw_feat_event,
                     :use_time_lag_draw_feat_event,
                     :finish_time_lag_draw_feat_event,
                    ],
                        # 423 時差ドロー
                    [
                     :check_add_time_lag_buff_feat_event,
                     :check_remove_time_lag_buff_feat_event,
                     :check_rotate_time_lag_buff_feat_event,
                     :use_time_lag_buff_feat_event,
                     :finish_time_lag_buff_feat_event,
                    ],
                        # 424 時差バフ
                    [
                     :check_add_damage_transfer_feat_event,
                     :check_remove_damage_transfer_feat_event,
                     :check_rotate_damage_transfer_feat_event,
                     :use_damage_transfer_feat_event,
                     :finish_damage_transfer_feat_event,
                    ],
                        # 425 移転
                    [
                     :check_add_cigarette_feat_event,
                     :check_remove_cigarette_feat_event,
                     :check_rotate_cigarette_feat_event,
                     :use_cigarette_feat_event,
                     :finish_cigarette_feat_event,
                    ],
                        # 426 シガレット
                    [
                     :check_add_three_card_feat_event,
                     :check_remove_three_card_feat_event,
                     :check_rotate_three_card_feat_event,
                     :use_three_card_feat_event,
                     :finish_three_card_feat_event,
                    ],
                        # 427 スリーカード
                    [
                     :check_add_card_search_feat_event,
                     :check_remove_card_search_feat_event,
                     :check_rotate_card_search_feat_event,
                     :finish_card_search_feat_event,
                    ],
                        # 428 カードサーチ
                    [
                     :check_add_all_in_one_feat_event,
                     :check_remove_all_in_one_feat_event,
                     :check_rotate_all_in_one_feat_event,
                     :use_all_in_one_feat_power_event,
                     :use_all_in_one_feat_event,
                     :finish_all_in_one_feat_event,
                    ],
                        # 429 オールインワン
                    [
                     :check_add_fire_bird_feat_event,
                     :check_remove_fire_bird_feat_event,
                     :check_rotate_fire_bird_feat_event,
                     :use_fire_bird_feat_event,
                     :use_after_fire_bird_feat_event,
                     :finish_fire_bird_feat_event,
                    ],
                        # 430 焼鳥
                    [
                     :check_add_brambles_feat_event,
                     :check_remove_brambles_feat_event,
                     :check_rotate_brambles_feat_event,
                     :use_brambles_feat_event,
                     :use_brambles_feat_move_before_event,
                     :use_brambles_feat_move_after_event,
                     :finish_brambles_feat_event,
                    ],
                        # 431 苔蔦
                    [
                     :check_add_franken_tackle_feat_event,
                     :check_remove_franken_tackle_feat_event,
                     :check_rotate_franken_tackle_feat_event,
                     :use_owner_franken_tackle_feat_event,
                     :use_foe_franken_tackle_feat_event,
                     :use_franken_tackle_feat_dice_attr_event,
                     :finish_franken_tackle_feat_event,
                    ],
                        # 432 フランケンタックル
                    [
                     :check_add_franken_charging_feat_event,
                     :check_remove_franken_charging_feat_event,
                     :check_rotate_franken_charging_feat_event,
                     :use_franken_charging_feat_event,
                     :use_franken_charging_feat_damage_event,
                     :finish_franken_charging_feat_event,
                    ],
                        # 433 フランケン充電
                    [
                     :check_add_moving_one_r_feat_event,
                     :check_remove_moving_one_r_feat_event,
                     :check_rotate_moving_one_r_feat_event,
                     :use_moving_one_r_feat_event,
                     :use_moving_one_r_feat_attack_event,
                     :use_moving_one_r_feat_defense_event,
                     :finish_moving_one_r_feat_event,
                     :finish_turn_moving_one_r_feat_event,
                    ],
                        # 434 挑みかかるものR
                    [
                     :check_add_arrogant_one_r_feat_event,
                     :check_remove_arrogant_one_r_feat_event,
                     :check_rotate_arrogant_one_r_feat_event,
                     :use_arrogant_one_r_feat_event,
                     :finish_arrogant_one_r_feat_event,
                    ],
                        # 435 驕りたかぶるものR
                    [
                     :check_add_eating_one_r_feat_event,
                     :check_remove_eating_one_r_feat_event,
                     :check_rotate_eating_one_r_feat_event,
                     :use_eating_one_r_feat_event,
                     :finish_eating_one_r_feat_event,
                    ],
                        # 436 貪り食うものR
                    [
                     :check_add_harf_dead_feat_event,
                     :check_remove_harf_dead_feat_event,
                     :check_rotate_harf_dead_feat_event,
                     :use_harf_dead_feat_event,
                     :finish_harf_dead_feat_event,
                    ],
                        # 437 ハーフデッド
                    [
                     :check_add_machine_cell_feat_event,
                     :check_remove_machine_cell_feat_event,
                     :check_rotate_machine_cell_feat_event,
                     :finish_machine_cell_feat_event,
                    ],
                        # 438 マシンセル
                    [
                     :check_add_heat_seeker_r_feat_event,
                     :check_remove_heat_seeker_r_feat_event,
                     :check_rotate_heat_seeker_r_feat_event,
                     :use_heat_seeker_r_feat_damage_event,
                     :finish_heat_seeker_r_feat_damage_event,
                    ],
                        # 439 ヒートシーカー
                    [
                     :check_add_directional_beam_feat_event,
                     :check_remove_directional_beam_feat_event,
                     :check_rotate_directional_beam_feat_event,
                     :use_directional_beam_feat_event,
                     :use_directional_beam_feat_damage_event,
                     :finish_directional_beam_feat_event,
                    ],
                        # 440 指向性エネルギー兵器
                    [
                     :check_add_delta_feat_event,
                     :check_remove_delta_feat_event,
                     :check_rotate_delta_feat_event,
                     :use_delta_feat_event,
                     :finish_delta_feat_event,
                    ],
                        # 441 デルタ
                    [
                     :check_add_sigma_feat_event,
                     :check_remove_sigma_feat_event,
                     :check_rotate_sigma_feat_event,
                     :use_sigma_feat_event,
                     :ex_sigma0_feat_event,
                     :ex_sigma_feat_event,
                     :finish_sigma_feat_event,
                    ],
                        # 442 シグマ
                    [
                     :check_add_stamp_feat_event,
                     :check_remove_stamp_feat_event,
                     :check_rotate_stamp_feat_event,
                     :use_stamp_feat_event,
                     :finish_stamp_feat_event,
                    ],
                        # 443 スタンプ
                    [
                     :check_add_acceleration_feat_event,
                     :check_remove_acceleration_feat_event,
                     :check_rotate_acceleration_feat_event,
                     :use_acceleration_feat_event,
                     :finish_acceleration_feat_event,
                    ],
                        # 444 アクセラレーション
                    [
                     :check_add_foab_feat_event,
                     :check_remove_foab_feat_event,
                     :check_rotate_foab_feat_event,
                     :finish_foab_feat_event,
                    ],
                        # 445 FOAB
                    [
                     :check_add_white_moon_feat_event,
                     :check_remove_white_moon_feat_event,
                     :check_rotate_white_moon_feat_event,
                     :use_white_moon_feat_event,
                     :use_white_moon_feat_dice_attr_event,
                     :use_white_moon_feat_damage_event,
                     :finish_white_moon_feat_event,
                    ],
                        # 446 白き玉桂
                    [
                     :check_add_anger_back_feat_event,
                     :check_remove_anger_back_feat_event,
                     :check_rotate_anger_back_feat_event,
                     :use_anger_back_feat_event,
                     :use_anger_back_feat_damage_event,
                     :finish_anger_back_feat_event,
                    ],
                        # 447 憤怒の背中
                       ]

#---------------------------------------------------------------------------------------------
# 強打

  class CheckAddSmashFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_smash_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSmashFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_smash_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSmashFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_smash_feat
    goal       ["self", :use_end?]
  end

  class UseSmashFeatEvent < EventRule
    dsc        "強打をを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_smash_feat
    goal       ["self", :use_end?]
  end

  class FinishSmashFeatEvent < EventRule
    dsc        "強打の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_smash_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ブラッディハウル

  class CheckAddBloodyHowlFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_bloody_howl_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBloodyHowlFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_bloody_howl_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBloodyHowlFeatEvent < EventRule
    dsc        "強打が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_bloody_howl_feat
    goal       ["self", :use_end?]
  end

  class UseBloodyHowlFeatEvent < EventRule
    dsc        "強打をを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_bloody_howl_feat
    goal       ["self", :use_end?]
  end

  class FinishBloodyHowlFeatEvent < EventRule
    dsc        "強打の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_bloody_howl_feat
    goal       ["self", :use_end?]
  end

  class UseBloodyHowlFeatDamageEvent < EventRule
    dsc        "紅蓮の車輪を使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_bloody_howl_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 精密射撃

  class CheckAddAimingFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_aiming_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAimingFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_aiming_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAimingFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_aiming_feat
    goal       ["self", :use_end?]
  end

  class UseAimingFeatEvent < EventRule
    dsc        "精密射撃を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_aiming_feat
    goal       ["self", :use_end?]
  end

  class FinishAimingFeatEvent < EventRule
    dsc        "精密射撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_aiming_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 精密射撃(復活)

  class CheckAddPrecisionFireFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_precision_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePrecisionFireFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_precision_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePrecisionFireFeatEvent < EventRule
    dsc        "精密射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_precision_fire_feat
    goal       ["self", :use_end?]
  end

  class UsePrecisionFireFeatEvent < EventRule
    dsc        "精密射撃を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_precision_fire_feat
    goal       ["self", :use_end?]
  end

  class FinishPrecisionFireFeatEvent < EventRule
    dsc        "精密射撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_precision_fire_feat
    goal       ["self", :use_end?]
  end

  class UsePrecisionFireFeatDamageEvent < EventRule
    dsc        "精密射撃を使用 固定ダメ"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_precision_fire_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 雷撃

  class CheckAddStrikeFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_strike_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveStrikeFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_strike_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateStrikeFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_strike_feat
    goal       ["self", :use_end?]
  end

  class UseStrikeFeatEvent < EventRule
    dsc        "雷撃を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_strike_feat
    goal       ["self", :use_end?]
  end

  class UseStrikeFeatDamageEvent < EventRule
    dsc        "雷撃を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_strike_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishStrikeFeatEvent < EventRule
    dsc        "雷撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_strike_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 紫電

  class CheckAddPurpleLightningFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_purple_lightning_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePurpleLightningFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_purple_lightning_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePurpleLightningFeatEvent < EventRule
    dsc        "雷撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_purple_lightning_feat
    goal       ["self", :use_end?]
  end

  class UsePurpleLightningFeatEvent < EventRule
    dsc        "雷撃を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_purple_lightning_feat
    goal       ["self", :use_end?]
  end

  class UsePurpleLightningFeatDamageEvent < EventRule
    dsc        "雷撃を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_purple_lightning_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPurpleLightningFeatEvent < EventRule
    dsc        "雷撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_purple_lightning_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 連続技

  class CheckAddComboFeatEvent < EventRule
    dsc        "連続技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_combo_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveComboFeatEvent < EventRule
    dsc        "連続技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_combo_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateComboFeatEvent < EventRule
    dsc        "連続技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_combo_feat
    goal       ["self", :use_end?]
  end

  class UseComboFeatEvent < EventRule
    dsc        "連続技を使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_combo_feat
    goal       ["self", :use_end?]
  end

  class FinishComboFeatEvent < EventRule
    dsc        "連続技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_combo_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ソードダンス(復活)

  class CheckAddSwordDanceFeatEvent < EventRule
    dsc        "ソードダンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSwordDanceFeatEvent < EventRule
    dsc        "ソードダンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSwordDanceFeatEvent < EventRule
    dsc        "ソードダンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class UseSwordDanceFeatEvent < EventRule
    dsc        "ソードダンスを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class FinishSwordDanceFeatEvent < EventRule
    dsc        "ソードダンスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class UseSwordDanceFeatDamageEvent < EventRule
    dsc        "ソードダンスを使用 攻撃力が+6"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_sword_dance_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 茨の森

  class CheckAddThornFeatEvent < EventRule
    dsc        "茨の森が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_thorn_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThornFeatEvent < EventRule
    dsc        "茨の森が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_thorn_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThornFeatEvent < EventRule
    dsc        "茨の森が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_thorn_feat
    goal       ["self", :use_end?]
  end

  class UseThornFeatEvent < EventRule
    dsc        "茨の森を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_thorn_feat
    goal       ["self", :use_end?]
  end

  class UseThornFeatDamageEvent < EventRule
    dsc        "茨の森使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_thorn_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishThornFeatEvent < EventRule
    dsc        "茨の森の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_thorn_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 突撃

  class CheckAddChargeFeatEvent < EventRule
    dsc        "突撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_charge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveChargeFeatEvent < EventRule
    dsc        "突撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_charge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateChargeFeatEvent < EventRule
    dsc        "突撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_charge_feat
    goal       ["self", :use_end?]
  end

  class UseChargeFeatEvent < EventRule
    dsc        "突撃をを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_charge_feat
    goal       ["self", :use_end?]
  end

  class FinishChargeFeatEvent < EventRule
    dsc        "突撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_charge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# チャージドスラスト(復活)

  class CheckAddChargedThrustFeatEvent < EventRule
    dsc        "チャージドスラストが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_charged_thrust_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveChargedThrustFeatEvent < EventRule
    dsc        "チャージドスラストが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_charged_thrust_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateChargedThrustFeatEvent < EventRule
    dsc        "チャージドスラストが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_charged_thrust_feat
    goal       ["self", :use_end?]
  end

  class UseChargedThrustFeatEvent < EventRule
    dsc        "チャージドスラストを使用 攻撃力＋"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_charged_thrust_feat
    goal       ["self", :use_end?]
  end

  class FinishChargedThrustFeatEvent < EventRule
    dsc        "チャージドスラストの使用が終了 距離操作"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_charged_thrust_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 砂漠の蜃気楼

  class CheckAddMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_mirage_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_mirage_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_mirage_feat
    goal       ["self", :use_end?]
  end

  class CheckMoveMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:bp_calc_resolve
    func       :check_move_mirage_feat
    goal       ["self", :use_end?]
  end

  class UseMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼を使用 防御力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_mirage_feat
    goal       ["self", :use_end?]
  end

  class FinishMirageFeatEvent < EventRule
    dsc        "砂漠の蜃気楼の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_mirage_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 狂気の眼窩

  class CheckAddFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩を使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end


  class UseFrenzyEyesFeatDamageEvent < EventRule
    dsc        "狂気の眼窩を使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_frenzy_eyes_feat_damage
    goal       ["self", :use_end?]
  end


  class FinishFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 深淵


  class CheckAddAbyssFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_abyss_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAbyssFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_abyss_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAbyssFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_abyss_feat
    goal       ["self", :use_end?]
  end

  class UseAbyssFeatEvent < EventRule
    dsc        "深淵を使用 威力ボーナスをリセット"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
     func       :use_abyss_feat
    goal       ["self", :use_end?]
  end

  class FinishAbyssFeatEvent < EventRule
    dsc        "深淵の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_abyss_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 神速の剣


  class CheckAddRapidSwordFeatEvent < EventRule
    dsc        "神速の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRapidSwordFeatEvent < EventRule
    dsc        "神速の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRapidSwordFeatEvent < EventRule
    dsc        "神速の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class UseRapidSwordFeatEvent < EventRule
    dsc        "神速の剣を使用 剣を攻撃力に加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishRapidSwordFeatEvent < EventRule
    dsc        "神速の剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rapid_sword_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 怒りの一撃

  class CheckAddAngerFeatEvent < EventRule
    dsc        "怒りの一撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_anger_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAngerFeatEvent < EventRule
    dsc        "怒りの一撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_anger_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAngerFeatEvent < EventRule
    dsc        "怒りの一撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_anger_feat
    goal       ["self", :use_end?]
  end

  class UseAngerFeatEvent < EventRule
    dsc        "怒りの一撃を使用 攻撃力にダメージを加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_anger_feat
    goal       ["self", :use_end?]
  end

  class FinishAngerFeatEvent < EventRule
    dsc        "怒りの一撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_anger_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 必殺の構え

  class CheckAddPowerStockFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_power_stock_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePowerStockFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_power_stock_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePowerStockFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_power_stock_feat
    goal       ["self", :use_end?]
  end

  class FinishPowerStockFeatEvent < EventRule
    dsc        "必殺の構えを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_power_stock_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 必殺の構え(復活)

  class CheckAddMortalStyleFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_mortal_style_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMortalStyleFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_mortal_style_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMortalStyleFeatEvent < EventRule
    dsc        "必殺の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_mortal_style_feat
    goal       ["self", :use_end?]
  end

  class FinishMortalStyleFeatEvent < EventRule
    dsc        "必殺の構えを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_mortal_style_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 影撃ち

  class CheckAddShadowShotFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShadowShotFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShadowShotFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class UseShadowShotFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class FinishShadowShotFeatEvent < EventRule
    dsc        "影撃ちの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class UseShadowShotFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_shadow_shot_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 赫い牙/呪剣

  class CheckAddRedFangFeatEvent < EventRule
    dsc        "赫い牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_red_fang_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRedFangFeatEvent < EventRule
    dsc        "赫い牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_red_fang_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRedFangFeatEvent < EventRule
    dsc        "赫い牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_red_fang_feat
    goal       ["self", :use_end?]
  end

  class UseRedFangFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_red_fang_feat
    goal       ["self", :use_end?]
  end

  class FinishRedFangFeatEvent < EventRule
    dsc        "赫い牙の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_red_fang_feat
    goal       ["self", :use_end?]
  end

  class UseRedFangFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_red_fang_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 血の恵み

  class CheckAddBlessingBloodFeatEvent < EventRule
    dsc        "血の恵みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_blessing_blood_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlessingBloodFeatEvent < EventRule
    dsc        "血の恵みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_blessing_blood_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlessingBloodFeatEvent < EventRule
    dsc        "血の恵みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_blessing_blood_feat
    goal       ["self", :use_end?]
  end

  class UseBlessingBloodFeatEvent < EventRule
    dsc        "血の恵みを使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_blessing_blood_feat
    goal       ["self", :use_end?]
  end

  class UseBlessingBloodFeatDamageEvent < EventRule
    dsc        "血の恵み使用時に上回った防御点を回復に当てる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_blessing_blood_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishBlessingBloodFeatEvent < EventRule
    dsc        "血の恵みの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blessing_blood_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 反撃の狼煙

  class CheckAddCounterPreparationFeatEvent < EventRule
    dsc        "反撃の狼煙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_counter_preparation_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCounterPreparationFeatEvent < EventRule
    dsc        "反撃の狼煙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_counter_preparation_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCounterPreparationFeatEvent < EventRule
    dsc        "反撃の狼煙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_counter_preparation_feat
    goal       ["self", :use_end?]
  end

  class UseCounterPreparationFeatDamageEvent < EventRule
    dsc        "反撃の狼煙使用時に上回った攻撃点を手札に当てる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_counter_preparation_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishCounterPreparationFeatEvent < EventRule
    dsc        "反撃の狼煙の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_counter_preparation_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 因果の刻

  class CheckAddKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_karmic_time_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_karmic_time_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_karmic_time_feat
    goal       ["self", :use_end?]
  end

  class UseKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻を使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_karmic_time_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻の使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :use_karmic_time_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeCharaChangeKarmicTimeFeatEvent < EventRule
    dsc        "因果の刻の使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :use_karmic_time_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 因果の輪

  class CheckAddKarmicRingFeatEvent < EventRule
    dsc        "因果の輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_karmic_ring_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKarmicRingFeatEvent < EventRule
    dsc        "因果の輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_karmic_ring_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKarmicRingFeatEvent < EventRule
    dsc        "因果の輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_karmic_ring_feat
    goal       ["self", :use_end?]
  end

  class UseKarmicRingFeatEvent < EventRule
    dsc        "因果の輪を使用 相手のカードを回転させる"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>2
    func       :use_karmic_ring_feat
    goal       ["self", :use_end?]
  end

  class FinishKarmicRingFeatEvent < EventRule
    dsc        "因果の輪の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_karmic_ring_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 因果の糸

  class CheckAddKarmicStringFeatEvent < EventRule
    dsc        "因果の糸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKarmicStringFeatEvent < EventRule
    dsc        "因果の糸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKarmicStringFeatEvent < EventRule
    dsc        "因果の糸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class UseKarmicStringFeatEvent < EventRule
    dsc        "因果の糸の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_karmic_string_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ハイスマッシュ

  class CheckAddHiSmashFeatEvent < EventRule
    dsc        "強打2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hi_smash_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiSmashFeatEvent < EventRule
    dsc        "強打2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hi_smash_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiSmashFeatEvent < EventRule
    dsc        "強打2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hi_smash_feat
    goal       ["self", :use_end?]
  end

  class UseHiSmashFeatEvent < EventRule
    dsc        "強打2を使用 攻撃力が+5"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hi_smash_feat
    goal       ["self", :use_end?]
  end

  class FinishHiSmashFeatEvent < EventRule
    dsc        "強打2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_smash_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 必殺の構え2

  class CheckAddHiPowerStockFeatEvent < EventRule
    dsc        "必殺の構え2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_hi_power_stock_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiPowerStockFeatEvent < EventRule
    dsc        "必殺の構え2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_hi_power_stock_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiPowerStockFeatEvent < EventRule
    dsc        "必殺の構え2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_hi_power_stock_feat
    goal       ["self", :use_end?]
  end

  class FinishHiPowerStockFeatEvent < EventRule
    dsc        "必殺の構え2を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_hi_power_stock_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 精密射撃2

  class CheckAddHiAimingFeatEvent < EventRule
    dsc        "精密射撃2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hi_aiming_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiAimingFeatEvent < EventRule
    dsc        "精密射撃2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hi_aiming_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiAimingFeatEvent < EventRule
    dsc        "精密射撃2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hi_aiming_feat
    goal       ["self", :use_end?]
  end


  class UseHiAimingFeatEvent < EventRule
    dsc        "精密射撃2を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hi_aiming_feat
    goal       ["self", :use_end?]
  end

  class FinishHiAimingFeatEvent < EventRule
    dsc        "精密射撃2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_aiming_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 神速の剣2

  class CheckAddHiRapidSwordFeatEvent < EventRule
    dsc        "神速の剣2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hi_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiRapidSwordFeatEvent < EventRule
    dsc        "神速の剣2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hi_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiRapidSwordFeatEvent < EventRule
    dsc        "神速の剣2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hi_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class UseHiRapidSwordFeatEvent < EventRule
    dsc        "神速の剣2を使用 剣を攻撃力に加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hi_rapid_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishHiRapidSwordFeatEvent < EventRule
    dsc        "神速の剣2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_rapid_sword_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 因果の糸2

  class CheckAddHiKarmicStringFeatEvent < EventRule
    dsc        "因果の糸2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_hi_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiKarmicStringFeatEvent < EventRule
    dsc        "因果の糸2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_hi_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiKarmicStringFeatEvent < EventRule
    dsc        "因果の糸2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_hi_karmic_string_feat
    goal       ["self", :use_end?]
  end

  class UseHiKarmicStringFeatEvent < EventRule
    dsc        "因果の糸2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_hi_karmic_string_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 狂気の眼窩2

  class CheckAddHiFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_hi_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_hi_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_hi_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseHiFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩2を使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_hi_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseHiFrenzyEyesFeatDamageEvent < EventRule
    dsc        "狂気の眼窩2を使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_hi_frenzy_eyes_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishHiFrenzyEyesFeatEvent < EventRule
    dsc        "狂気の眼窩2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_frenzy_eyes_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 影撃ち2

  class CheckAddHiShadowShotFeatEvent < EventRule
    dsc        "影撃ち2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hi_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiShadowShotFeatEvent < EventRule
    dsc        "影撃ち2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hi_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiShadowShotFeatEvent < EventRule
    dsc        "影撃ち2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hi_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class UseHiShadowShotFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hi_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class FinishHiShadowShotFeatEvent < EventRule
    dsc        "影撃ち2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_shadow_shot_feat
    goal       ["self", :use_end?]
  end

  class UseHiShadowShotFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_hi_shadow_shot_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 地雷

  class CheckAddLandMineFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_land_mine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLandMineFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_land_mine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLandMineFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_land_mine_feat
    goal       ["self", :use_end?]
  end

  class UseLandMineFeatEvent < EventRule
    dsc        "地雷の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_land_mine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# デスペラード

  class CheckAddDesperadoFeatEvent < EventRule
    dsc        "デスペラードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_desperado_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDesperadoFeatEvent < EventRule
    dsc        "デスペラードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_desperado_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDesperadoFeatEvent < EventRule
    dsc        "デスペラードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_desperado_feat
    goal       ["self", :use_end?]
  end

  class UseDesperadoFeatEvent < EventRule
    dsc        "デスペラードを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_desperado_feat
    goal       ["self", :use_end?]
  end

  class FinishDesperadoFeatEvent < EventRule
    dsc        "デスペラードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_desperado_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# リジェクトソード

  class CheckAddRejectSwordFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_reject_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRejectSwordFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_reject_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRejectSwordFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_reject_sword_feat
    goal       ["self", :use_end?]
  end

  class UseRejectSwordFeatEvent < EventRule
    dsc        "リジェクトソードを使用 攻撃力が+4"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_reject_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishRejectSwordFeatEvent < EventRule
    dsc        "リジェクトソードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_reject_sword_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# カウンターガード

  class CheckAddCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_counter_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_counter_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_counter_guard_feat
    goal       ["self", :use_end?]
  end

  class UseCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードの使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>20
    func       :use_counter_guard_feat
    goal       ["self", :use_end?]
  end

  class UseCounterGuardFeatDiceAttrEvent < EventRule
    dsc        "カウンターガードの使用が終了"
    type       :type=>:before, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>20
    func       :use_counter_guard_feat_dice_attr
    goal       ["self", :use_end?]
  end

  class FinishCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>60
    func       :finish_counter_guard_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Exカウンターガード

  class UseExCounterGuardFeatEvent < EventRule
    dsc        "カウンターガードの使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>60
    func       :use_counter_guard_feat
    goal       ["self", :use_end?]
  end

  class UseExCounterGuardFeatDiceAttrEvent < EventRule
    dsc        "カウンターガードの使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>70
    func       :use_counter_guard_feat_dice_attr
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ペインフリー

  class CheckAddPainFleeFeatEvent < EventRule
    dsc        "ペインフリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_pain_flee_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePainFleeFeatEvent < EventRule
    dsc        "ペインフリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_pain_flee_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePainFleeFeatEvent < EventRule
    dsc        "ペインフリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_pain_flee_feat
    goal       ["self", :use_end?]
  end

  class FinishPainFleeFeatEvent < EventRule
    dsc        "ペインフリーを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_pain_flee_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 光の映し身

  class CheckAddBodyOfLightFeatEvent < EventRule
    dsc        "光の映し身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_body_of_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBodyOfLightFeatEvent < EventRule
    dsc        "光の映し身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_body_of_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBodyOfLightFeatEvent < EventRule
    dsc        "光の映し身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_body_of_light_feat
    goal       ["self", :use_end?]
  end

  class UseBodyOfLightFeatEvent < EventRule
    dsc        "光の映し身を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_body_of_light_feat
    goal       ["self", :use_end?]
  end

  class FinishBodyOfLightFeatEvent < EventRule
    dsc        "光の映し身の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :finish_body_of_light_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 封印の鎖

  class CheckAddSealChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_seal_chain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSealChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_seal_chain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSealChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_seal_chain_feat
    goal       ["self", :use_end?]
  end

  class UseSealChainFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_seal_chain_feat
    goal       ["self", :use_end?]
  end

  class FinishSealChainFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_seal_chain_feat
    goal       ["self", :use_end?]
  end

  class UseSealChainFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_seal_chain_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 降魔の光

  class CheckAddPurificationLightFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_purification_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePurificationLightFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_purification_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePurificationLightFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_purification_light_feat
    goal       ["self", :use_end?]
  end

  class UsePurificationLightFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_purification_light_feat
    goal       ["self", :use_end?]
  end

  class FinishPurificationLightFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_purification_light_feat
    goal       ["self", :use_end?]
  end

  class UsePurificationLightFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_purification_light_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 知略

  class CheckAddCraftinessFeatEvent < EventRule
    dsc        "知略が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_craftiness_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCraftinessFeatEvent < EventRule
    dsc        "知略が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_craftiness_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCraftinessFeatEvent < EventRule
    dsc        "知略が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_craftiness_feat
    goal       ["self", :use_end?]
  end

  class FinishCraftinessFeatEvent < EventRule
    dsc        "知略を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_craftiness_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 地雷2

  class CheckAddLandBombFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_land_bomb_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLandBombFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_land_bomb_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLandBombFeatEvent < EventRule
    dsc        "地雷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_land_bomb_feat
    goal       ["self", :use_end?]
  end

  class UseLandBombFeatEvent < EventRule
    dsc        "地雷の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_land_bomb_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# リジェクトブレイド

  class CheckAddRejectBladeFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_reject_blade_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRejectBladeFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_reject_blade_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRejectBladeFeatEvent < EventRule
    dsc        "リジェクトソードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_reject_blade_feat
    goal       ["self", :use_end?]
  end

  class UseRejectBladeFeatEvent < EventRule
    dsc        "リジェクトソードを使用 攻撃力が+4"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_reject_blade_feat
    goal       ["self", :use_end?]
  end

  class FinishRejectBladeFeatEvent < EventRule
    dsc        "リジェクトソードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_reject_blade_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 呪縛の鎖

  class CheckAddSpellChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_spell_chain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSpellChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_spell_chain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSpellChainFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_spell_chain_feat
    goal       ["self", :use_end?]
  end

  class UseSpellChainFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_spell_chain_feat
    goal       ["self", :use_end?]
  end

  class FinishSpellChainFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_spell_chain_feat
    goal       ["self", :use_end?]
  end

  class UseSpellChainFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_spell_chain_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 不屈の心

  class CheckAddIndomitableMindFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_indomitable_mind_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIndomitableMindFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_indomitable_mind_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIndomitableMindFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_indomitable_mind_feat
    goal       ["self", :use_end?]
  end

  class UseIndomitableMindFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_indomitable_mind_feat
    goal       ["self", :use_end?]
  end

  class UseIndomitableMindFeatDamageEvent < EventRule
    dsc        "必殺技が使用される"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>60
    func       :use_indomitable_mind_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishIndomitableMindFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :finish_indomitable_mind_feat
    goal       ["self", :use_end?]
  end

  class FinishIndomitableMindFeatDeadCharaChangeEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_indomitable_mind_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 精神力吸収

  class CheckAddDrainSoulFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_drain_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDrainSoulFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_drain_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDrainSoulFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_drain_soul_feat
    goal       ["self", :use_end?]
  end

  class UseDrainSoulFeatEvent < EventRule
    dsc        "精神力吸収の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :use_drain_soul_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# バックスタブ

  class CheckAddBackStabFeatEvent < EventRule
    dsc        "バックスタブが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_back_stab_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBackStabFeatEvent < EventRule
    dsc        "バックスタブが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_back_stab_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBackStabFeatEvent < EventRule
    dsc        "バックスタブが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_back_stab_feat
    goal       ["self", :use_end?]
  end

  class UseBackStabFeatEvent < EventRule
    dsc        "バックスタブを使用 攻撃力が+4"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_back_stab_feat
    goal       ["self", :use_end?]
  end

  class FinishBackStabFeatEvent < EventRule
    dsc        "バックスタブの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_back_stab_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 見切り

  class CheckAddEnlightenedFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_enlightened_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEnlightenedFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_enlightened_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEnlightenedFeatEvent < EventRule
    dsc        "精神力吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_enlightened_feat
    goal       ["self", :use_end?]
  end

  class UseEnlightenedFeatEvent < EventRule
    dsc        "精神力吸収の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :use_enlightened_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 暗黒の渦

  class CheckAddDarkWhirlpoolFeatEvent < EventRule
    dsc        "暗黒の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dark_whirlpool_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDarkWhirlpoolFeatEvent < EventRule
    dsc        "暗黒の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dark_whirlpool_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDarkWhirlpoolFeatEvent < EventRule
    dsc        "暗黒の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dark_whirlpool_feat
    goal       ["self", :use_end?]
  end

  class UseDarkWhirlpoolFeatEvent < EventRule
    dsc        "暗黒の渦を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dark_whirlpool_feat
    goal       ["self", :use_end?]
  end

  class UseDarkWhirlpoolFeatDamageEvent < EventRule
    dsc        "暗黒の渦を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_dark_whirlpool_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 因果の幻

  class CheckAddKarmicPhantomFeatEvent < EventRule
    dsc        "因果の幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_karmic_phantom_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKarmicPhantomFeatEvent < EventRule
    dsc        "因果の幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_karmic_phantom_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKarmicPhantomFeatEvent < EventRule
    dsc        "因果の幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_karmic_phantom_feat
    goal       ["self", :use_end?]
  end

  class UseKarmicPhantomFeatEvent < EventRule
    dsc        "因果の幻を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_karmic_phantom_feat
    goal       ["self", :use_end?]
  end

  class FinishKarmicPhantomFeatEvent < EventRule
    dsc        "因果の幻の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :finish_karmic_phantom_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 治癒の波動

  class CheckAddRecoveryWaveFeatEvent < EventRule
    dsc        "治癒の波動が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_recovery_wave_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRecoveryWaveFeatEvent < EventRule
    dsc        "治癒の波動が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_recovery_wave_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRecoveryWaveFeatEvent < EventRule
    dsc        "治癒の波動が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_recovery_wave_feat
    goal       ["self", :use_end?]
  end

  class FinishRecoveryWaveFeatEvent < EventRule
    dsc        "治癒の波動の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :finish_recovery_wave_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 自爆


  class CheckAddSelfDestructionFeatEvent < EventRule
    dsc        "自爆が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_self_destruction_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSelfDestructionFeatEvent < EventRule
    dsc        "自爆が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_self_destruction_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSelfDestructionFeatEvent < EventRule
    dsc        "自爆が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_self_destruction_feat
    goal       ["self", :use_end?]
  end

  class FinishSelfDestructionFeatEvent < EventRule
    dsc        "自爆の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_self_destruction_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 防護射撃

  class CheckAddDeffenceShootingFeatEvent < EventRule
    dsc        "防護射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_deffence_shooting_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeffenceShootingFeatEvent < EventRule
    dsc        "防護射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_deffence_shooting_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeffenceShootingFeatEvent < EventRule
    dsc        "防護射撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_deffence_shooting_feat
    goal       ["self", :use_end?]
  end

  class UseDeffenceShootingFeatEvent < EventRule
    dsc        "防護射撃を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_deffence_shooting_feat
    goal       ["self", :use_end?]
  end

  class UseDeffenceShootingFeatDamageEvent < EventRule
    dsc        "防護射撃を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_deffence_shooting_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 再生

  class CheckAddRecoveryFeatEvent < EventRule
    dsc        "再生が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_recovery_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRecoveryFeatEvent < EventRule
    dsc        "再生が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_recovery_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRecoveryFeatEvent < EventRule
    dsc        "再生が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_recovery_feat
    goal       ["self", :use_end?]
  end

  class FinishRecoveryFeatEvent < EventRule
    dsc        "再生を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_recovery_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 幻影

  class CheckAddShadowAttackFeatEvent < EventRule
    dsc        "幻影が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_shadow_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShadowAttackFeatEvent < EventRule
    dsc        "幻影が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_shadow_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShadowAttackFeatEvent < EventRule
    dsc        "幻影が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_shadow_attack_feat
    goal       ["self", :use_end?]
  end

  class UseShadowAttackFeatEvent < EventRule
    dsc        "幻影をを使用 攻撃力が+2、攻撃終了時に距離が変化"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_shadow_attack_feat
    goal       ["self", :use_end?]
  end

  class FinishShadowAttackFeatEvent < EventRule
    dsc        "幻影の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shadow_attack_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スーサイダルテンデンシー

  class CheckAddSuicidalTendenciesFeatEvent < EventRule
    dsc        "スーサイダルテンデンシーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_suicidal_tendencies_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSuicidalTendenciesFeatEvent < EventRule
    dsc        "スーサイダルテンデンシーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_suicidal_tendencies_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSuicidalTendenciesFeatEvent < EventRule
    dsc        "スーサイダルテンデンシーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_suicidal_tendencies_feat
    goal       ["self", :use_end?]
  end

  class UseSuicidalTendenciesFeatEvent < EventRule
    dsc        "スーサイダルテンデンシーを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_suicidal_tendencies_feat
    goal       ["self", :use_end?]
  end

  class FinishSuicidalTendenciesFeatEvent < EventRule
    dsc        "スーサイダルテンデンシーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_suicidal_tendencies_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ミスフィット

  class CheckAddMisfitFeatEvent < EventRule
    dsc        "ミスフィットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_misfit_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMisfitFeatEvent < EventRule
    dsc        "ミスフィットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_misfit_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMisfitFeatEvent < EventRule
    dsc        "ミスフィットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_misfit_feat
    goal       ["self", :use_end?]
  end

  class UseMisfitFeatEvent < EventRule
    dsc        "ミスフィットを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_misfit_feat
    goal       ["self", :use_end?]
  end

  class UseMisfitFeatDamageEvent < EventRule
    dsc        "ミスフィット発動。不死になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :use_misfit_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishMisfitFeatEvent < EventRule
    dsc        "ミスフィットの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_misfit_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ビッグブラッグ

  class CheckAddBigBraggFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_big_bragg_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBigBraggFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_big_bragg_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBigBraggFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_big_bragg_feat
    goal       ["self", :use_end?]
  end

  class FinishBigBraggFeatEvent < EventRule
    dsc        "ビッグブラッグを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_big_bragg_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# レッツナイフ

  class CheckAddLetsKnifeFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_lets_knife_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLetsKnifeFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_lets_knife_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLetsKnifeFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_lets_knife_feat
    goal       ["self", :use_end?]
  end

  class UseLetsKnifeFeatEvent < EventRule
    dsc        "レッツナイフを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_lets_knife_feat
    goal       ["self", :use_end?]
  end

  class FinishLetsKnifeFeatEvent < EventRule
    dsc        "レッツナイフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_lets_knife_feat
    goal       ["self", :use_end?]
  end



#---------------------------------------------------------------------------------------------
# 1つの心

  class CheckAddSingleHeartFeatEvent < EventRule
    dsc        "1つの心が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_single_heart_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSingleHeartFeatEvent < EventRule
    dsc        "1つの心が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_single_heart_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSingleHeartFeatEvent < EventRule
    dsc        "1つの心が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_single_heart_feat
    goal       ["self", :use_end?]
  end

  class UseSingleHeartFeatEvent < EventRule
    dsc        "1つの心の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>1
    func       :use_single_heart_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 2つの身体

  class CheckAddDoubleBodyFeatEvent < EventRule
    dsc        "2つの身体が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_double_body_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDoubleBodyFeatEvent < EventRule
    dsc        "2つの身体が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_double_body_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDoubleBodyFeatEvent < EventRule
    dsc        "2つの身体が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_double_body_feat
    goal       ["self", :use_end?]
  end

  class UseDoubleBodyFeatEvent < EventRule
    dsc        "2つの身体を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_double_body_feat
    goal       ["self", :use_end?]
  end

  class UseDoubleBodyFeatDamageEvent < EventRule
    dsc        "2つの身体使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_double_body_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDoubleBodyFeatEvent < EventRule
    dsc        "2つの身体の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_double_body_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 9の魂

  class CheckAddNineSoulFeatEvent < EventRule
    dsc        "9の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_nine_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNineSoulFeatEvent < EventRule
    dsc        "9の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_nine_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNineSoulFeatEvent < EventRule
    dsc        "9の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_nine_soul_feat
    goal       ["self", :use_end?]
  end

  class UseNineSoulFeatEvent < EventRule
    dsc        "9の魂を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_nine_soul_feat
    goal       ["self", :use_end?]
  end

  class FinishNineSoulFeatEvent < EventRule
    dsc        "9の魂の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_nine_soul_feat
    goal       ["self", :use_end?]
  end



#---------------------------------------------------------------------------------------------
# 13の眼

  class CheckAddThirteenEyesFeatEvent < EventRule
    dsc        "13の眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThirteenEyesFeatEvent < EventRule
    dsc        "13の眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThirteenEyesFeatEvent < EventRule
    dsc        "13の眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseOwnerThirteenEyesFeatEvent < EventRule
    dsc        "13の眼を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>50
    func       :use_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseFoeThirteenEyesFeatEvent < EventRule
    dsc        "13の眼を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>50
    func       :use_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class FinishThirteenEyesFeatEvent < EventRule
    dsc        "13の眼の使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>60
    func       :finish_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseThirteenEyesFeatDamageEvent < EventRule
    dsc        "13の眼を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>60
    func       :use_thirteen_eyes_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Ex13の眼

  class UseFoeExThirteenEyesFeatEvent < EventRule
    dsc        "13の眼を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>70
    func       :use_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

  class FinishExThirteenEyesFeatEvent < EventRule
    dsc        "13の眼の使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>80
    func       :finish_thirteen_eyes_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ライフドレイン/ドレインエナジー/吸血

  class CheckAddLifeDrainFeatEvent < EventRule
    dsc        "ライフドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_life_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLifeDrainFeatEvent < EventRule
    dsc        "ライフドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_life_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLifeDrainFeatEvent < EventRule
    dsc        "ライフドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_life_drain_feat
    goal       ["self", :use_end?]
  end

  class UseLifeDrainFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_life_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishLifeDrainFeatEvent < EventRule
    dsc        "ライフドレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_life_drain_feat
    goal       ["self", :use_end?]
  end

  class UseLifeDrainFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_life_drain_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ランダムカース/呪いの手/サークルオブ・T

  class CheckAddRandomCurseFeatEvent < EventRule
    dsc        "ランダムカースが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_random_curse_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRandomCurseFeatEvent < EventRule
    dsc        "ランダムカースが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_random_curse_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRandomCurseFeatEvent < EventRule
    dsc        "ランダムカースが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_random_curse_feat
    goal       ["self", :use_end?]
  end

  class UseRandomCurseFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_random_curse_feat
    goal       ["self", :use_end?]
  end

  class FinishRandomCurseFeatEvent < EventRule
    dsc        "ランダムカースの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_random_curse_feat
    goal       ["self", :use_end?]
  end

  class UseRandomCurseFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_random_curse_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 癒しの声


  class CheckAddHealVoiceFeatEvent < EventRule
    dsc        "癒しの声が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_heal_voice_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHealVoiceFeatEvent < EventRule
    dsc        "癒しの声が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_heal_voice_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHealVoiceFeatEvent < EventRule
    dsc        "癒しの声が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_heal_voice_feat
    goal       ["self", :use_end?]
  end

  class UseHealVoiceFeatEvent < EventRule
    dsc        "癒しの声を使用 自分を回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_heal_voice_feat
    goal       ["self", :use_end?]
  end

  class FinishHealVoiceFeatEvent < EventRule
    dsc        "癒しの声の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_heal_voice_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ダブルアタック

  class CheckAddDoubleAttackFeatEvent < EventRule
    dsc        "ダブルアタックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_double_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDoubleAttackFeatEvent < EventRule
    dsc        "ダブルアタックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_double_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDoubleAttackFeatEvent < EventRule
    dsc        "ダブルアタックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_double_attack_feat
    goal       ["self", :use_end?]
  end

  class UseDoubleAttackFeatEvent < EventRule
    dsc        "ダブルアタックを使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_double_attack_feat
    goal       ["self", :use_end?]
  end

  class FinishDoubleAttackFeatEvent < EventRule
    dsc        "ダブルアタックの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :finish_double_attack_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 全体攻撃


  class CheckAddPartyDamageFeatEvent < EventRule
    dsc        "全体攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_party_damage_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePartyDamageFeatEvent < EventRule
    dsc        "全体攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_party_damage_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePartyDamageFeatEvent < EventRule
    dsc        "全体攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_party_damage_feat
    goal       ["self", :use_end?]
  end

  class UsePartyDamageFeatEvent < EventRule
    dsc        "全体攻撃を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_party_damage_feat
    goal       ["self", :use_end?]
  end

  class FinishPartyDamageFeatEvent < EventRule
    dsc        "全体攻撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_party_damage_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ダメージ軽減

  class CheckAddGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_guard_feat
    goal       ["self", :use_end?]
  end

  class UseGuardFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_guard_feat
    goal       ["self", :use_end?]
  end

  class UseGuardFeatDamageEvent < EventRule
    dsc        "必殺技が使用される"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_guard_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishGuardFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_guard_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 自壊攻撃/血統汚染/D・コントロール

  class CheckAddDeathControlFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_death_control_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeathControlFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_death_control_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeathControlFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_death_control_feat
    goal       ["self", :use_end?]
  end

  class UseDeathControlFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_death_control_feat
    goal       ["self", :use_end?]
  end

  class FinishDeathControlFeatEvent < EventRule
    dsc        "自壊攻撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_death_control_feat
    goal       ["self", :use_end?]
  end

  class UseDeathControlFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_death_control_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 移動上昇

  class CheckAddWitFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_wit_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWitFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_wit_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWitFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_wit_feat
    goal       ["self", :use_end?]
  end

  class UseWitFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_wit_feat
    goal       ["self", :use_end?]
  end

  class FinishWitFeatEvent < EventRule
    dsc        "移動上昇を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_wit_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 茨の構え

  class CheckAddThornCareFeatEvent < EventRule
    dsc        "茨の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_thorn_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThornCareFeatEvent < EventRule
    dsc        "茨の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_thorn_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThornCareFeatEvent < EventRule
    dsc        "茨の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_thorn_care_feat
    goal       ["self", :use_end?]
  end

  class UseThornCareFeatEvent < EventRule
    dsc        "茨の構えを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_thorn_care_feat
    goal       ["self", :use_end?]
  end

  class UseThornCareFeatDamageEvent < EventRule
    dsc        "茨の構え使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_thorn_care_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishThornCareFeatEvent < EventRule
    dsc        "茨の構えの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_thorn_care_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 解放剣

  class CheckAddLiberatingSwordFeatEvent < EventRule
    dsc        "解放剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_liberating_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLiberatingSwordFeatEvent < EventRule
    dsc        "解放剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_liberating_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLiberatingSwordFeatEvent < EventRule
    dsc        "解放剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_liberating_sword_feat
    goal       ["self", :use_end?]
  end

  class UseLiberatingSwordFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_liberating_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishLiberatingSwordFeatEvent < EventRule
    dsc        "解放剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_liberating_sword_feat
    goal       ["self", :use_end?]
  end

  class UseLiberatingSwordFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :use_liberating_sword_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 一閃

  class CheckAddOneSlashFeatEvent < EventRule
    dsc        "一閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_one_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOneSlashFeatEvent < EventRule
    dsc        "一閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_one_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOneSlashFeatEvent < EventRule
    dsc        "一閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_one_slash_feat
    goal       ["self", :use_end?]
  end

  class UseOneSlashFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_one_slash_feat
    goal       ["self", :use_end?]
  end

  class FinishOneSlashFeatEvent < EventRule
    dsc        "一閃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_one_slash_feat
    goal       ["self", :use_end?]
  end

  class UseOneSlashFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_one_slash_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 十閃

  class CheckAddTenSlashFeatEvent < EventRule
    dsc        "十閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ten_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTenSlashFeatEvent < EventRule
    dsc        "十閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ten_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTenSlashFeatEvent < EventRule
    dsc        "十閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ten_slash_feat
    goal       ["self", :use_end?]
  end

  class UseTenSlashFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ten_slash_feat
    goal       ["self", :use_end?]
  end

  class FinishTenSlashFeatEvent < EventRule
    dsc        "十閃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :finish_ten_slash_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 八閃

  class CheckAddHassenFeatEvent < EventRule
    dsc        "八閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hassen_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHassenFeatEvent < EventRule
    dsc        "八閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hassen_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHassenFeatEvent < EventRule
    dsc        "八閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hassen_feat
    goal       ["self", :use_end?]
  end

  class UseHassenFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hassen_feat
    goal       ["self", :use_end?]
  end

  class FinishHassenFeatEvent < EventRule
    dsc        "八閃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hassen_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 百閃

  class CheckAddHandledSlashFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_handled_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHandledSlashFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_handled_slash_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHandledSlashFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_handled_slash_feat
    goal       ["self", :use_end?]
  end

  class UseHandledSlashFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_handled_slash_feat
    goal       ["self", :use_end?]
  end

  class FinishHandledSlashFeatEvent < EventRule
    dsc        "百閃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_handled_slash_feat
    goal       ["self", :use_end?]
  end

  class UseHandledSlashFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :use_handled_slash_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 百閃(R)

  class CheckAddHandledSlashRFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_handled_slash_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHandledSlashRFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_handled_slash_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHandledSlashRFeatEvent < EventRule
    dsc        "百閃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_handled_slash_r_feat
    goal       ["self", :use_end?]
  end

  class UseHandledSlashRFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_handled_slash_r_feat
    goal       ["self", :use_end?]
  end

  class FinishHandledSlashRFeatEvent < EventRule
    dsc        "百閃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_handled_slash_r_feat
    goal       ["self", :use_end?]
  end

  class UseHandledSlashRFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :use_handled_slash_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 修羅の構え

  class CheckAddCurseCareFeatEvent < EventRule
    dsc        "修羅の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_curse_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCurseCareFeatEvent < EventRule
    dsc        "修羅の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_curse_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCurseCareFeatEvent < EventRule
    dsc        "修羅の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_curse_care_feat
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatEvent < EventRule
    dsc        "修羅の構えを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_curse_care_feat
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatDamageEvent < EventRule
    dsc        "修羅の構え発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>120
    func       :use_curse_care_feat_damage
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatHeal1Event < EventRule
    dsc        "修羅の構え発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>2
    func       :use_curse_care_feat_heal1
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatHealDetBpEvent < EventRule
    dsc        "修羅の構え発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>50
    func       :use_curse_care_feat_heal2
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatHeal2Event < EventRule
    dsc        "修羅の構え発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>0
    func       :use_curse_care_feat_heal2
    goal       ["self", :use_end?]
  end

  class UseCurseCareFeatHeal3Event < EventRule
    dsc        "修羅の構え発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>50
    func       :use_curse_care_feat_heal3
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ムーンシャイン

  class CheckAddMoonShineFeatEvent < EventRule
    dsc        "ムーンシャインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_moon_shine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMoonShineFeatEvent < EventRule
    dsc        "ムーンシャインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_moon_shine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMoonShineFeatEvent < EventRule
    dsc        "ムーンシャインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_moon_shine_feat
    goal       ["self", :use_end?]
  end

  class UseMoonShineFeatEvent < EventRule
    dsc        "ムーンシャインを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_moon_shine_feat
    goal       ["self", :use_end?]
  end

  class FinishMoonShineFeatEvent < EventRule
    dsc        "ムーンシャインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_moon_shine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ラプチュア

  class CheckAddRaptureFeatEvent < EventRule
    dsc        "ラプチュアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_rapture_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRaptureFeatEvent < EventRule
    dsc        "ラプチュアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_rapture_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRaptureFeatEvent < EventRule
    dsc        "ラプチュアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_rapture_feat
    goal       ["self", :use_end?]
  end

  class UseRaptureFeatEvent < EventRule
    dsc        "ラプチュアを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_rapture_feat
    goal       ["self", :use_end?]
  end

  class UseRaptureFeatDamageEvent < EventRule
    dsc        "ラプチュア使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_rapture_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRaptureFeatEvent < EventRule
    dsc        "ラプチュアの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rapture_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ドゥームスデイ

  class CheckAddDoomsdayFeatEvent < EventRule
    dsc        "ドゥームスデイが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_doomsday_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDoomsdayFeatEvent < EventRule
    dsc        "ドゥームスデイが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_doomsday_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDoomsdayFeatEvent < EventRule
    dsc        "ドゥームスデイが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_doomsday_feat
    goal       ["self", :use_end?]
  end

  class FinishDoomsdayFeatEvent < EventRule
    dsc        "ドゥームスデイを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_doomsday_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# hellboundheart


  class CheckAddHellFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hell_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHellFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hell_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHellFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hell_feat
    goal       ["self", :use_end?]
  end

  class UseHellFeatEvent < EventRule
    dsc        "深淵を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hell_feat
    goal       ["self", :use_end?]
  end

  class FinishHellFeatEvent < EventRule
    dsc        "深淵の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hell_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スーパーヒロイン

  class CheckAddAwakingFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_awaking_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAwakingFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_awaking_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAwakingFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_awaking_feat
    goal       ["self", :use_end?]
  end

  class FinishAwakingFeatEvent < EventRule
    dsc        "スーパーヒロインを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_awaking_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 近距離移動

  class CheckAddMovingOneFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_moving_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMovingOneFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_moving_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMovingOneFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_moving_one_feat
    goal       ["self", :use_end?]
  end

  class UseMovingOneFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_moving_one_feat
    goal       ["self", :use_end?]
  end

  class FinishMovingOneFeatEvent < EventRule
    dsc        "移動上昇を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_moving_one_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 下位防御

  class CheckAddArrogantOneFeatEvent < EventRule
    dsc        "下位防御が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_arrogant_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveArrogantOneFeatEvent < EventRule
    dsc        "下位防御が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_arrogant_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateArrogantOneFeatEvent < EventRule
    dsc        "下位防御が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_arrogant_one_feat
    goal       ["self", :use_end?]
  end

  class UseArrogantOneFeatEvent < EventRule
    dsc        "下位防御を使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_arrogant_one_feat
    goal       ["self", :use_end?]
  end

  class FinishArrogantOneFeatEvent < EventRule
    dsc        "下位防御の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_arrogant_one_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 食らうもの

  class CheckAddEatingOneFeatEvent < EventRule
    dsc        "食らうものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_eating_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEatingOneFeatEvent < EventRule
    dsc        "食らうものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_eating_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEatingOneFeatEvent < EventRule
    dsc        "食らうものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_eating_one_feat
    goal       ["self", :use_end?]
  end

  class UseEatingOneFeatEvent < EventRule
    dsc        "食らうものをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_eating_one_feat
    goal       ["self", :use_end?]
  end

  class FinishEatingOneFeatEvent < EventRule
    dsc        "食らうものの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_eating_one_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 蘇るもの

  class CheckAddRevivingOneFeatEvent < EventRule
    dsc        "蘇るものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_reviving_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRevivingOneFeatEvent < EventRule
    dsc        "蘇るものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_reviving_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRevivingOneFeatEvent < EventRule
    dsc        "蘇るものが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_reviving_one_feat
    goal       ["self", :use_end?]
  end

  class FinishRevivingOneFeatEvent < EventRule
    dsc        "蘇るものを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_reviving_one_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ホワイトライト

  class CheckAddWhiteLightFeatEvent < EventRule
    dsc        "ホワイトライトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_white_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWhiteLightFeatEvent < EventRule
    dsc        "ホワイトライトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_white_light_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWhiteLightFeatEvent < EventRule
    dsc        "ホワイトライトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_white_light_feat
    goal       ["self", :use_end?]
  end

  class FinishWhiteLightFeatEvent < EventRule
    dsc        "ホワイトライトを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_white_light_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クリスタル・M

  class CheckAddCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_crystal_shield_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_crystal_shield_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_crystal_shield_feat
    goal       ["self", :use_end?]
  end

  class UseCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mを使用 防御＋"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_crystal_shield_feat
    goal       ["self", :use_end?]
  end

  class UseAfterCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mを使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_after_crystal_shield_feat
    goal       ["self", :use_end?]
  end

  class FinishCrystalShieldFeatEvent < EventRule
    dsc        "クリスタル・Mの使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_crystal_shield_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スノーボーリング

  class CheckAddSnowBallingFeatEvent < EventRule
    dsc        "スノーボーリングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_snow_balling_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSnowBallingFeatEvent < EventRule
    dsc        "スノーボーリングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_snow_balling_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSnowBallingFeatEvent < EventRule
    dsc        "スノーボーリングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_snow_balling_feat
    goal       ["self", :use_end?]
  end

  class UseSnowBallingFeatEvent < EventRule
    dsc        "スノーボーリングを使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_snow_balling_feat
    goal       ["self", :use_end?]
  end

  class UseSnowBallingFeatDamageEvent < EventRule
    dsc        "スノーボーリングを使用時にパーティにダメージ"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_snow_balling_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishSnowBallingFeatEvent < EventRule
    dsc        "スノーボーリングの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_snow_balling_feat
    goal       ["self", :use_end?]
  end

  class UseSnowBallingFeatConstDamageEvent < EventRule
    dsc        "スノーボーリングを使用時にパーティにダメージ"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_snow_balling_feat_const_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# オビチュアリ

  class CheckAddObituaryFeatEvent < EventRule
    dsc        "オビチュアリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_obituary_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveObituaryFeatEvent < EventRule
    dsc        "オビチュアリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_obituary_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateObituaryFeatEvent < EventRule
    dsc        "オビチュアリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_obituary_feat
    goal       ["self", :use_end?]
  end

  class UseObituaryFeatEvent < EventRule
    dsc        "オビチュアリーを使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_obituary_feat
    goal       ["self", :use_end?]
  end

  class UseObituaryFeatDamageEvent < EventRule
    dsc        "オビチュアリーを使用時にパーティにダメージ"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_obituary_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishObituaryFeatEvent < EventRule
    dsc        "オビチュアリーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_obituary_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ソルベントレイン

  class CheckAddSolventRainFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_solvent_rain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSolventRainFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_solvent_rain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSolventRainFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_solvent_rain_feat
    goal       ["self", :use_end?]
  end

  class UseSolventRainFeatEvent < EventRule
    dsc        "ソルベントレインを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>50
    func       :use_solvent_rain_feat
    goal       ["self", :use_end?]
  end

  class FinishSolventRainFeatEvent < EventRule
    dsc        "ソルベントレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_solvent_rain_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ソルベントレインR

  class CheckAddSolventRainRFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_solvent_rain_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSolventRainRFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_solvent_rain_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSolventRainRFeatEvent < EventRule
    dsc        "ソルベントレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_solvent_rain_r_feat
    goal       ["self", :use_end?]
  end

  class UseSolventRainRFeatEvent < EventRule
    dsc        "ソルベントレインを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>50
    func       :use_solvent_rain_r_feat
    goal       ["self", :use_end?]
  end

  class FinishSolventRainRFeatEvent < EventRule
    dsc        "ソルベントレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_solvent_rain_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 知覚の扉

  class CheckAddAwakingDoorFeatEvent < EventRule
    dsc        "知覚の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_awaking_door_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAwakingDoorFeatEvent < EventRule
    dsc        "知覚の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_awaking_door_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAwakingDoorFeatEvent < EventRule
    dsc        "知覚の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_awaking_door_feat
    goal       ["self", :use_end?]
  end

  class FinishAwakingDoorFeatEvent < EventRule
    dsc        "知覚の扉を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>9
    func       :finish_awaking_door_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# オーバードウズ

  class CheckAddOverDoseFeatEvent < EventRule
    dsc        "オーバードウズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_over_dose_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOverDoseFeatEvent < EventRule
    dsc        "オーバードウズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_over_dose_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOverDoseFeatEvent < EventRule
    dsc        "オーバードウズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_over_dose_feat
    goal       ["self", :use_end?]
  end

  class UseOverDoseFeatEvent < EventRule
    dsc        "オーバードウズを使用 攻撃力にダメージを加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_over_dose_feat
    goal       ["self", :use_end?]
  end

  class FinishOverDoseFeatEvent < EventRule
    dsc        "オーバードウズの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>50
    func       :finish_over_dose_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# レイザーズエッジ

  class CheckAddRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class UseOwnerRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>10
    func       :use_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class UseFoeRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジを使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>30
    func       :use_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class UseRazorsEdgeFeatDiceAttrEvent < EventRule
    dsc        "レイザーズエッジを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>60
    func       :use_razors_edge_feat_dice_attr
    goal       ["self", :use_end?]
  end

  class FinishRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_razors_edge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# レイザーズエッジ
  class UseFoeExRazorsEdgeFeatEvent < EventRule
    dsc        "レイザーズエッジを使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>70
    func       :use_razors_edge_feat
    goal       ["self", :use_end?]
  end

  class UseExRazorsEdgeFeatDiceAttrEvent < EventRule
    dsc        "レイザーズエッジを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>80
    func       :use_razors_edge_feat_dice_attr
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヘルズベル


  class CheckAddHellsBellFeatEvent < EventRule
    dsc        "ヘルズベルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hells_bell_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHellsBellFeatEvent < EventRule
    dsc        "ヘルズベルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hells_bell_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHellsBellFeatEvent < EventRule
    dsc        "ヘルズベルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hells_bell_feat
    goal       ["self", :use_end?]
  end

  class UseHellsBellFeatEvent < EventRule
    dsc        "ヘルズベルを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hells_bell_feat
    goal       ["self", :use_end?]
  end

  class FinishHellsBellFeatEvent < EventRule
    dsc        "ヘルズベルの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hells_bell_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ドレインシード

  class CheckAddDrainSeedFeatEvent < EventRule
    dsc        "ドレインシードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_drain_seed_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDrainSeedFeatEvent < EventRule
    dsc        "ドレインシードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_drain_seed_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDrainSeedFeatEvent < EventRule
    dsc        "ドレインシードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_drain_seed_feat
    goal       ["self", :use_end?]
  end

  class FinishDrainSeedFeatEvent < EventRule
    dsc        "ドレインシードを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_drain_seed_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 攻撃吸収


  class CheckAddAtkDrainFeatEvent < EventRule
    dsc        "攻撃吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_atk_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAtkDrainFeatEvent < EventRule
    dsc        "攻撃吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_atk_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAtkDrainFeatEvent < EventRule
    dsc        "攻撃吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_atk_drain_feat
    goal       ["self", :use_end?]
  end

  class UseAtkDrainFeatEvent < EventRule
    dsc        "攻撃吸収を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_atk_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishAtkDrainFeatEvent < EventRule
    dsc        "攻撃吸収の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_atk_drain_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 防御吸収


  class CheckAddDefDrainFeatEvent < EventRule
    dsc        "防御吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_def_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDefDrainFeatEvent < EventRule
    dsc        "防御吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_def_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDefDrainFeatEvent < EventRule
    dsc        "防御吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_def_drain_feat
    goal       ["self", :use_end?]
  end

  class UseDefDrainFeatEvent < EventRule
    dsc        "防御吸収を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_def_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishDefDrainFeatEvent < EventRule
    dsc        "防御吸収の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_def_drain_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 混沌の翼

  class CheckAddMovDrainFeatEvent < EventRule
    dsc        "混沌の翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_mov_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMovDrainFeatEvent < EventRule
    dsc        "混沌の翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_mov_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMovDrainFeatEvent < EventRule
    dsc        "混沌の翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_mov_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishMovDrainFeatEvent < EventRule
    dsc        "混沌の翼を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_mov_drain_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 毒竜燐

  class CheckAddPoisonSkinFeatEvent < EventRule
    dsc        "毒竜燐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_poison_skin_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePoisonSkinFeatEvent < EventRule
    dsc        "毒竜燐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_poison_skin_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePoisonSkinFeatEvent < EventRule
    dsc        "毒竜燐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_poison_skin_feat
    goal       ["self", :use_end?]
  end

  class UsePoisonSkinFeatEvent < EventRule
    dsc        "毒竜燐を使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_poison_skin_feat
    goal       ["self", :use_end?]
  end

  class UsePoisonSkinFeatDamageEvent < EventRule
    dsc        "毒竜燐使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_poison_skin_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPoisonSkinFeatEvent < EventRule
    dsc        "毒竜燐の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_poison_skin_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 咆哮

  class CheckAddRoarFeatEvent < EventRule
    dsc        "咆哮が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_roar_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRoarFeatEvent < EventRule
    dsc        "咆哮が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_roar_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRoarFeatEvent < EventRule
    dsc        "咆哮が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_roar_feat
    goal       ["self", :use_end?]
  end

  class UseRoarFeatEvent < EventRule
    dsc        "咆哮をを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_roar_feat
    goal       ["self", :use_end?]
  end

  class FinishRoarFeatEvent < EventRule
    dsc        "咆哮の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_roar_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 火炎のブレス


  class CheckAddFireBreathFeatEvent < EventRule
    dsc        "火炎のブレスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_fire_breath_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFireBreathFeatEvent < EventRule
    dsc        "火炎のブレスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_fire_breath_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFireBreathFeatEvent < EventRule
    dsc        "火炎のブレスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_fire_breath_feat
    goal       ["self", :use_end?]
  end

  class UseFireBreathFeatEvent < EventRule
    dsc        "火炎のブレスを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_fire_breath_feat
    goal       ["self", :use_end?]
  end

  class FinishFireBreathFeatEvent < EventRule
    dsc        "火炎のブレスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_fire_breath_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ワールインド

  class CheckAddWhirlWindFeatEvent < EventRule
    dsc        "ワールウインドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_whirl_wind_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWhirlWindFeatEvent < EventRule
    dsc        "ワールウインドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_whirl_wind_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWhirlWindFeatEvent < EventRule
    dsc        "ワールウインドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_whirl_wind_feat
    goal       ["self", :use_end?]
  end

  class UseWhirlWindFeatEvent < EventRule
    dsc        "ワールウインドをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_whirl_wind_feat
    goal       ["self", :use_end?]
  end

  class FinishWhirlWindFeatEvent < EventRule
    dsc        "ワールウインドの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_whirl_wind_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アクティブアーマ

  class CheckAddActiveArmorFeatEvent < EventRule
    dsc        "アクティブアーマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveActiveArmorFeatEvent < EventRule
    dsc        "アクティブアーマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateActiveArmorFeatEvent < EventRule
    dsc        "アクティブアーマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_active_armor_feat
    goal       ["self", :use_end?]
  end

  class UseActiveArmorFeatEvent < EventRule
    dsc        "アクティブアーマを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_active_armor_feat
    goal       ["self", :use_end?]
  end

  class UseActiveArmorFeatDamageEvent < EventRule
    dsc        "アクティブアーマを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_active_armor_feat_damage
    goal       ["self", :use_end?]
  end

  class CheckSealActiveArmorFeatMoveAfterEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>50
    func       :check_seal_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckSealActiveArmorFeatDetChangeAfterEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase, :priority=>50
    func       :check_seal_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckSealActiveArmorFeatDamageAfterEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>50
    func       :check_seal_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckUnsealActiveArmorFeatDamageAfterEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>51
    func       :check_unseal_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckUnsealActiveArmorFeatStartTurnEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_unseal_active_armor_feat
    goal       ["self", :use_end?]
  end

  class CheckSealActiveArmorFeatCharaChangeEvent < EventRule
    dsc        "封印状態をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :set_active_armor_feat_sealing_state
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# マシンガン

  class CheckAddScolorAttackFeatEvent < EventRule
    dsc        "マシンガンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_scolor_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveScolorAttackFeatEvent < EventRule
    dsc        "マシンガンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_scolor_attack_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateScolorAttackFeatEvent < EventRule
    dsc        "マシンガンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_scolor_attack_feat
    goal       ["self", :use_end?]
  end

  class UseScolorAttackFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_scolor_attack_feat
    goal       ["self", :use_end?]
  end

  class FinishScolorAttackFeatEvent < EventRule
    dsc        "マシンガンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_scolor_attack_feat
    goal       ["self", :use_end?]
  end

  class UseScolorAttackFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_scolor_attack_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヒートシーカー

  class CheckAddHeatSeekerFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_heat_seeker_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHeatSeekerFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_heat_seeker_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHeatSeekerFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_heat_seeker_feat
    goal       ["self", :use_end?]
  end

  class UseHeatSeekerFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_heat_seeker_feat
    goal       ["self", :use_end?]
  end

  class FinishHeatSeekerFeatEvent < EventRule
    dsc        "ヒートシーカーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :finish_heat_seeker_feat
    goal       ["self", :use_end?]
  end

  class UseHeatSeekerFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_heat_seeker_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# パージ

  class CheckAddPurgeFeatEvent < EventRule
    dsc        "パージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_purge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePurgeFeatEvent < EventRule
    dsc        "パージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_purge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePurgeFeatEvent < EventRule
    dsc        "パージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_purge_feat
    goal       ["self", :use_end?]
  end

  class FinishPurgeFeatEvent < EventRule
    dsc        "パージを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_purge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ハイハンド

  class CheckAddHighHandFeatEvent < EventRule
    dsc        "ハイハンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_high_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHighHandFeatEvent < EventRule
    dsc        "ハイハンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_high_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHighHandFeatEvent < EventRule
    dsc        "ハイハンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_high_hand_feat
    goal       ["self", :use_end?]
  end

  class UseHighHandFeatEvent < EventRule
    dsc        "ハイハンドを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_high_hand_feat
    goal       ["self", :use_end?]
  end

  class UseHighHandFeatDamageEvent < EventRule
    dsc        "ハイハンドを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_high_hand_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ジャックポット

  class CheckAddJackPotFeatEvent < EventRule
    dsc        "ジャックポットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_jack_pot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveJackPotFeatEvent < EventRule
    dsc        "ジャックポットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_jack_pot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateJackPotFeatEvent < EventRule
    dsc        "ジャックポットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_jack_pot_feat
    goal       ["self", :use_end?]
  end

  class UseJackPotFeatEvent < EventRule
    dsc        "ジャックポットを使用 防御＋"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_jack_pot_feat
    goal       ["self", :use_end?]
  end

  class UseAfterJackPotFeatEvent < EventRule
    dsc        "ジャックポットを使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_after_jack_pot_feat
    goal       ["self", :use_end?]
  end

  class FinishJackPotFeatEvent < EventRule
    dsc        "ジャックポットの使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_jack_pot_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ローボール

  class CheckAddLowBallFeatEvent < EventRule
    dsc        "ローボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_low_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLowBallFeatEvent < EventRule
    dsc        "ローボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_low_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLowBallFeatEvent < EventRule
    dsc        "ローボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_low_ball_feat
    goal       ["self", :use_end?]
  end

  class UseLowBallFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_low_ball_feat
    goal       ["self", :use_end?]
  end

  class FinishLowBallFeatEvent < EventRule
    dsc        "ローボールの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_low_ball_feat
    goal       ["self", :use_end?]
  end

  class UseLowBallFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_low_ball_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ギャンブル

  class CheckAddGambleFeatEvent < EventRule
    dsc        "ギャンブルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_gamble_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGambleFeatEvent < EventRule
    dsc        "ギャンブルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_gamble_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGambleFeatEvent < EventRule
    dsc        "ギャンブルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_gamble_feat
    goal       ["self", :use_end?]
  end

  class UseGambleFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_gamble_feat
    goal       ["self", :use_end?]
  end

  class FinishGambleFeatEvent < EventRule
    dsc        "ギャンブルの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_gamble_feat
    goal       ["self", :use_end?]
  end

  class UseGambleFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>99
    func       :use_gamble_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# バードケージ

  class CheckAddBirdCageFeatEvent < EventRule
    dsc        "バードケージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_bird_cage_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBirdCageFeatEvent < EventRule
    dsc        "バードケージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_bird_cage_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBirdCageFeatEvent < EventRule
    dsc        "バードケージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_bird_cage_feat
    goal       ["self", :use_end?]
  end

  class FinishBirdCageFeatEvent < EventRule
    dsc        "バードケージを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_bird_cage_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ハンギング

  class CheckAddHangingFeatEvent < EventRule
    dsc        "ハンギングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hanging_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHangingFeatEvent < EventRule
    dsc        "ハンギングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hanging_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHangingFeatEvent < EventRule
    dsc        "ハンギングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hanging_feat
    goal       ["self", :use_end?]
  end

  class UseHangingFeatEvent < EventRule
    dsc        "ハンギングを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hanging_feat
    goal       ["self", :use_end?]
  end


  class FinishHangingFeatEvent < EventRule
    dsc        "ハンギングの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>25
    func       :finish_hanging_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ブラストオフ

  class CheckAddBlastOffFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blast_off_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlastOffFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blast_off_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlastOffFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blast_off_feat
    goal       ["self", :use_end?]
  end

  class UseBlastOffFeatEvent < EventRule
    dsc        "ブラストオフをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blast_off_feat
    goal       ["self", :use_end?]
  end

  class ExBlastOffFeatEvent < EventRule
    dsc        "ブラストオフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :ex_blast_off_feat
    goal       ["self", :use_end?]
  end

  class FinishBlastOffFeatEvent < EventRule
    dsc        "ブラストオフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>20
    func       :finish_blast_off_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# パペットマスター

  class CheckAddPuppetMasterFeatEvent < EventRule
    dsc        "パペットマスター可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_puppet_master_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePuppetMasterFeatEvent < EventRule
    dsc        "パペットマスターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_puppet_master_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePuppetMasterFeatEvent < EventRule
    dsc        "パペットマスターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_puppet_master_feat
    goal       ["self", :use_end?]
  end

  class UsePuppetMasterFeatEvent < EventRule
    dsc        "パペットマスターを使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_puppet_master_feat
    goal       ["self", :use_end?]
  end

  class FinishPuppetMasterFeatEvent < EventRule
    dsc        "パペットマスターの使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_puppet_master_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# C.T.L

  class CheckAddCtlFeatEvent < EventRule
    dsc        "C.T.Lが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ctl_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCtlFeatEvent < EventRule
    dsc        "C.T.Lが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ctl_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCtlFeatEvent < EventRule
    dsc        "C.T.Lが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ctl_feat
    goal       ["self", :use_end?]
  end

  class UseCtlFeatEvent < EventRule
    dsc        "C.T.Lを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ctl_feat
    goal       ["self", :use_end?]
  end

  class FinishCtlFeatEvent < EventRule
    dsc        "C.T.Lの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_ctl_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# B.P.A

  class CheckAddBpaFeatEvent < EventRule
    dsc        "B.P.Aが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_bpa_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBpaFeatEvent < EventRule
    dsc        "B.P.Aが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_bpa_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBpaFeatEvent < EventRule
    dsc        "B.P.Aが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_bpa_feat
    goal       ["self", :use_end?]
  end

  class UseBpaFeatEvent < EventRule
    dsc        "B.P.Aを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_bpa_feat
    goal       ["self", :use_end?]
  end

  class FinishBpaFeatEvent < EventRule
    dsc        "B.P.Aの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_bpa_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# L.A.R

  class CheckAddLarFeatEvent < EventRule
    dsc        "L.A.Rが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_lar_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLarFeatEvent < EventRule
    dsc        "L.A.Rが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_lar_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLarFeatEvent < EventRule
    dsc        "L.A.Rが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_lar_feat
    goal       ["self", :use_end?]
  end

  class UseLarFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_lar_feat
    goal       ["self", :use_end?]
  end

  class FinishLarFeatEvent < EventRule
    dsc        "L.A.Rの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_lar_feat
    goal       ["self", :use_end?]
  end

  class UseLarFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_lar_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# S.S.S

  class CheckAddSssFeatEvent < EventRule
    dsc        "S.S.Sが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_sss_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSssFeatEvent < EventRule
    dsc        "S.S.Sが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_sss_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSssFeatEvent < EventRule
    dsc        "S.S.Sが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_sss_feat
    goal       ["self", :use_end?]
  end

  class FinishSssFeatEvent < EventRule
    dsc        "S.S.Sを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_sss_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# カウンターラッシュ

  class CheckAddCounterRushFeatEvent < EventRule
    dsc        "カウンターラッシュが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_counter_rush_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCounterRushFeatEvent < EventRule
    dsc        "カウンターラッシュが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_counter_rush_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCounterRushFeatEvent < EventRule
    dsc        "カウンターラッシュが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_counter_rush_feat
    goal       ["self", :use_end?]
  end

  class UseCounterRushFeatEvent < EventRule
    dsc        "カウンターラッシュを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_counter_rush_feat
    goal       ["self", :use_end?]
  end

  class FinishCounterRushFeatEvent < EventRule
    dsc        "カウンターラッシュの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_counter_rush_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 劫火

  class CheckAddDisasterFlameFeatEvent < EventRule
    dsc        "劫火が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_disaster_flame_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDisasterFlameFeatEvent < EventRule
    dsc        "劫火が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_disaster_flame_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDisasterFlameFeatEvent < EventRule
    dsc        "劫火が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_disaster_flame_feat
    goal       ["self", :use_end?]
  end

  class UseDisasterFlameFeatEvent < EventRule
    dsc        "劫火を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_disaster_flame_feat
    goal       ["self", :use_end?]
  end

  class FinishDisasterFlameFeatEvent < EventRule
    dsc        "劫火の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_disaster_flame_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 煉獄

  class CheckAddHellFireFeatEvent < EventRule
    dsc        "煉獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hell_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHellFireFeatEvent < EventRule
    dsc        "煉獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hell_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHellFireFeatEvent < EventRule
    dsc        "煉獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hell_fire_feat
    goal       ["self", :use_end?]
  end

  class UseHellFireFeatEvent < EventRule
    dsc        "煉獄を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hell_fire_feat
    goal       ["self", :use_end?]
  end

  class UseHellFireFeatDamageEvent < EventRule
    dsc        "煉獄を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_hell_fire_feat_damage
    goal       ["self", :use_end?]
  end

  class UseHellFireFeatConstDamageEvent < EventRule
    dsc        "煉獄を使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_hell_fire_feat_const_damage
    goal       ["self", :use_end?]
  end

  class FinishHellFireFeatEvent < EventRule
    dsc        "煉獄の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hell_fire_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 眩彩

  class CheckAddBlindnessFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_blindness_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlindnessFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_blindness_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlindnessFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_blindness_feat
    goal       ["self", :use_end?]
  end

  class UseBlindnessFeat1Event < EventRule
    dsc        "眩彩を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_blindness_feat1
    goal       ["self", :use_end?]
  end

  class UseBlindnessFeat2Event < EventRule
    dsc        "眩彩を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>90
    func       :use_blindness_feat2
    goal       ["self", :use_end?]
  end

  class FinishBlindnessFeatEvent < EventRule
    dsc        "眩彩の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blindness_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 焼滅

  class CheckAddFireDisappearFeatEvent < EventRule
    dsc        "焼滅が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_fire_disappear_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFireDisappearFeatEvent < EventRule
    dsc        "焼滅が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_fire_disappear_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFireDisappearFeatEvent < EventRule
    dsc        "焼滅が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_fire_disappear_feat
    goal       ["self", :use_end?]
  end

  class UseFireDisappearFeatEvent < EventRule
    dsc        "焼滅を使用 防御＋"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_fire_disappear_feat
    goal       ["self", :use_end?]
  end

  class UseAfterFireDisappearFeatEvent < EventRule
    dsc        "焼滅を使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_after_fire_disappear_feat
    goal       ["self", :use_end?]
  end

  class FinishFireDisappearFeatEvent < EventRule
    dsc        "焼滅の使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_fire_disappear_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ダークホール

  class CheckAddDarkHoleFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dark_hole_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDarkHoleFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dark_hole_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDarkHoleFeatEvent < EventRule
    dsc        "眩彩が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dark_hole_feat
    goal       ["self", :use_end?]
  end

  class UseDarkHoleFeatEvent < EventRule
    dsc        "眩彩を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dark_hole_feat
    goal       ["self", :use_end?]
  end

  class FinishDarkHoleFeatEvent < EventRule
    dsc        "眩彩の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dark_hole_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# タンホイザーゲート

  class CheckAddTannhauserGateFeatEvent < EventRule
    dsc        "タンホイザーゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_tannhauser_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTannhauserGateFeatEvent < EventRule
    dsc        "タンホイザーゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_tannhauser_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTannhauserGateFeatEvent < EventRule
    dsc        "タンホイザーゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_tannhauser_gate_feat
    goal       ["self", :use_end?]
  end

  class UseTannhauserGateFeatEvent < EventRule
    dsc        "タンホイザーゲートを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_tannhauser_gate_feat
    goal       ["self", :use_end?]
  end

  class FinishTannhauserGateFeatEvent < EventRule
    dsc        "タンホイザーゲートの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_tannhauser_gate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# シュバルトブリッツ

  class CheckAddSchwarBlitzFeatEvent < EventRule
    dsc        "シュバルトブリッツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_schwar_blitz_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSchwarBlitzFeatEvent < EventRule
    dsc        "シュバルトブリッツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_schwar_blitz_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSchwarBlitzFeatEvent < EventRule
    dsc        "シュバルトブリッツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_schwar_blitz_feat
    goal       ["self", :use_end?]
  end

  class UseSchwarBlitzFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_schwar_blitz_feat
    goal       ["self", :use_end?]
  end

  class FinishSchwarBlitzFeatEvent < EventRule
    dsc        "シュバルトブリッツの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_schwar_blitz_feat
    goal       ["self", :use_end?]
  end

  class UseSchwarBlitzFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_schwar_blitz_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ハイランダー

  class CheckAddHiRounderFeatEvent < EventRule
    dsc        "ハイランダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hi_rounder_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHiRounderFeatEvent < EventRule
    dsc        "ハイランダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hi_rounder_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHiRounderFeatEvent < EventRule
    dsc        "ハイランダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hi_rounder_feat
    goal       ["self", :use_end?]
  end

  class UseHiRounderFeatEvent < EventRule
    dsc        "ハイランダーを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hi_rounder_feat
    goal       ["self", :use_end?]
  end

  class FinishHiRounderFeatEvent < EventRule
    dsc        "ハイランダーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hi_rounder_feat
    goal       ["self", :use_end?]
  end

  class UseHiRounderFeatConstDamageEvent < EventRule
    dsc        "ハイランダーの直接ダメージ部分"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_hi_rounder_feat_const_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ブラッドレッティング

  class CheckAddBloodRettingFeatEvent < EventRule
    dsc        "ブラッドレッティングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_blood_retting_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBloodRettingFeatEvent < EventRule
    dsc        "ブラッドレッティングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_blood_retting_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBloodRettingFeatEvent < EventRule
    dsc        "ブラッドレッティングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_blood_retting_feat
    goal       ["self", :use_end?]
  end

  class UseBloodRettingFeatEvent < EventRule
    dsc        "ブラッドレッティングを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_blood_retting_feat
    goal       ["self", :use_end?]
  end

  class UseBloodRettingFeatDamageEvent < EventRule
    dsc        "ブラッドレッティング使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_blood_retting_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishBloodRettingFeatEvent < EventRule
    dsc        "ブラッドレッティングの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blood_retting_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アキュパンクチャー

  class CheckAddAcupunctureFeatEvent < EventRule
    dsc        "アキュパンクチャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_acupuncture_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAcupunctureFeatEvent < EventRule
    dsc        "アキュパンクチャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_acupuncture_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAcupunctureFeatEvent < EventRule
    dsc        "アキュパンクチャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_acupuncture_feat
    goal       ["self", :use_end?]
  end

  class FinishAcupunctureFeatEvent < EventRule
    dsc        "アキュパンクチャーを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :finish_acupuncture_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ディセクション

  class CheckAddDissectionFeatEvent < EventRule
    dsc        "ディセクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dissection_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDissectionFeatEvent < EventRule
    dsc        "ディセクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dissection_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDissectionFeatEvent < EventRule
    dsc        "ディセクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dissection_feat
    goal       ["self", :use_end?]
  end

  class UseDissectionFeatEvent < EventRule
    dsc        "ディセクションを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dissection_feat
    goal       ["self", :use_end?]
  end

  class UseDissectionFeatDamageEvent < EventRule
    dsc        "ディセクション発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>120
    func       :use_dissection_feat_damage
    goal       ["self", :use_end?]
  end

  class UseDissectionFeatGuardEvent < EventRule
    dsc        "ディセクションの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_dissection_feat_guard
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ユーサネイジア

  class CheckAddEuthanasiaFeatEvent < EventRule
    dsc        "ユーサネイジアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_euthanasia_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEuthanasiaFeatEvent < EventRule
    dsc        "ユーサネイジアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_euthanasia_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEuthanasiaFeatEvent < EventRule
    dsc        "ユーサネイジアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_euthanasia_feat
    goal       ["self", :use_end?]
  end

  class UseEuthanasiaFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_euthanasia_feat
    goal       ["self", :use_end?]
  end

  class FinishEuthanasiaFeatEvent < EventRule
    dsc        "ユーサネイジアの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :finish_euthanasia_feat
    goal       ["self", :use_end?]
  end

  class UseEuthanasiaFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_euthanasia_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 憤怒の爪

  class CheckAddAngerNailFeatEvent < EventRule
    dsc        "憤怒の爪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_anger_nail_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAngerNailFeatEvent < EventRule
    dsc        "憤怒の爪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_anger_nail_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAngerNailFeatEvent < EventRule
    dsc        "憤怒の爪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_anger_nail_feat
    goal       ["self", :use_end?]
  end

  class FinishAngerNailFeatEvent < EventRule
    dsc        "憤怒の爪を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_anger_nail_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 静謐な背中

  class CheckAddCalmBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_calm_back_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCalmBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_calm_back_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCalmBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_calm_back_feat
    goal       ["self", :use_end?]
  end

  class UseCalmBackFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_calm_back_feat
    goal       ["self", :use_end?]
  end

  class FinishCalmBackFeatEvent < EventRule
    dsc        "静謐な背中の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_calm_back_feat
    goal       ["self", :use_end?]
  end

  class UseCalmBackFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_calm_back_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 慈悲の青眼

  class CheckAddBlueEyesFeatEvent < EventRule
    dsc        "慈悲の青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blue_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlueEyesFeatEvent < EventRule
    dsc        "慈悲の青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blue_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlueEyesFeatEvent < EventRule
    dsc        "慈悲の青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blue_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseBlueEyesFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blue_eyes_feat
    goal       ["self", :use_end?]
  end

  class FinishBlueEyesFeatEvent < EventRule
    dsc        "慈悲の青眼の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blue_eyes_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 戦慄の狼牙

  class CheckAddWolfFangFeatEvent < EventRule
    dsc        "戦慄の狼牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_wolf_fang_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWolfFangFeatEvent < EventRule
    dsc        "戦慄の狼牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_wolf_fang_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWolfFangFeatEvent < EventRule
    dsc        "戦慄の狼牙が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_wolf_fang_feat
    goal       ["self", :use_end?]
  end

  class UseWolfFangFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_wolf_fang_feat
    goal       ["self", :use_end?]
  end

  class FinishWolfFangFeatEvent < EventRule
    dsc        "戦慄の狼牙の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_wolf_fang_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 葉隠れ

  class CheckAddHagakureFeatEvent < EventRule
    dsc        "葉隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_hagakure_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHagakureFeatEvent < EventRule
    dsc        "葉隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_hagakure_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHagakureFeatEvent < EventRule
    dsc        "葉隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_hagakure_feat
    goal       ["self", :use_end?]
  end

  class UseHagakureFeatEvent < EventRule
    dsc        "葉隠れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_hagakure_feat
    goal       ["self", :use_end?]
  end

  class UseHagakureFeatDamageEvent < EventRule
    dsc        "葉隠れ使用時にダメージとして相手に与える"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_hagakure_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishHagakureFeatEvent < EventRule
    dsc        "葉隠れの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hagakure_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 烈風

  class CheckAddReppuFeatEvent < EventRule
    dsc        "烈風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_reppu_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveReppuFeatEvent < EventRule
    dsc        "烈風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_reppu_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateReppuFeatEvent < EventRule
    dsc        "烈風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_reppu_feat
    goal       ["self", :use_end?]
  end

  class UseReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_reppu_feat
    goal       ["self", :use_end?]
  end

  class FinishReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_reppu_feat
    goal       ["self", :use_end?]
  end

  class FinishEffectReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_effect_reppu_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeChangeReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_change_reppu_feat
    goal       ["self", :use_end?]
  end

  class FinishDeadChangeReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:dead_chara_change_phase
    func       :finish_change_reppu_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnReppuFeatEvent < EventRule
    dsc        "烈風を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_reppu_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 燕飛

  class CheckAddEnpiFeatEvent < EventRule
    dsc        "燕飛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_enpi_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEnpiFeatEvent < EventRule
    dsc        "燕飛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_enpi_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEnpiFeatEvent < EventRule
    dsc        "燕飛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_enpi_feat
    goal       ["self", :use_end?]
  end

  class UseEnpiFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_enpi_feat
    goal       ["self", :use_end?]
  end

  class FinishEnpiFeatEvent < EventRule
    dsc        "燕飛の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_enpi_feat
    goal       ["self", :use_end?]
  end

  class UseEnpiFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :use_enpi_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 三日月

  class CheckAddMikazukiFeatEvent < EventRule
    dsc        "三日月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_mikazuki_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMikazukiFeatEvent < EventRule
    dsc        "三日月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_mikazuki_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMikazukiFeatEvent < EventRule
    dsc        "三日月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_mikazuki_feat
    goal       ["self", :use_end?]
  end

  class UseMikazukiFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_mikazuki_feat
    goal       ["self", :use_end?]
  end

  class FinishMikazukiFeatEvent < EventRule
    dsc        "三日月の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_mikazuki_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# カサブランカの風

  class CheckAddCasablancaFeatEvent < EventRule
    dsc        "カサブランカの風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_casablanca_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCasablancaFeatEvent < EventRule
    dsc        "カサブランカの風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_casablanca_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCasablancaFeatEvent < EventRule
    dsc        "カサブランカの風が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_casablanca_feat
    goal       ["self", :use_end?]
  end

  class FinishCasablancaFeatEvent < EventRule
    dsc        "カサブランカの風を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_casablanca_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ローデシアの海

  class CheckAddRhodesiaFeatEvent < EventRule
    dsc        "ローデシアの海が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_rhodesia_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRhodesiaFeatEvent < EventRule
    dsc        "ローデシアの海が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_rhodesia_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRhodesiaFeatEvent < EventRule
    dsc        "ローデシアの海が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_rhodesia_feat
    goal       ["self", :use_end?]
  end

  class UseRhodesiaFeatEvent < EventRule
    dsc        "ローデシアの海を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_rhodesia_feat
    goal       ["self", :use_end?]
  end

  class UseRhodesiaFeatDamageEvent < EventRule
    dsc        "ローデシアの海使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_rhodesia_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRhodesiaFeatEvent < EventRule
    dsc        "ローデシアの海の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rhodesia_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# マドリプールの雑踏


  class CheckAddMadripoolFeatEvent < EventRule
    dsc        "マドリプールの雑踏が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_madripool_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMadripoolFeatEvent < EventRule
    dsc        "マドリプールの雑踏が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_madripool_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMadripoolFeatEvent < EventRule
    dsc        "マドリプールの雑踏が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_madripool_feat
    goal       ["self", :use_end?]
  end

  class UseMadripoolFeatEvent < EventRule
    dsc        "マドリプールの雑踏を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_madripool_feat
    goal       ["self", :use_end?]
  end

  class FinishMadripoolFeatEvent < EventRule
    dsc        "マドリプールの雑踏の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_madripool_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# エイジャの曙光


  class CheckAddAsiaFeatEvent < EventRule
    dsc        "エイジャの曙光が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_asia_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAsiaFeatEvent < EventRule
    dsc        "エイジャの曙光が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_asia_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAsiaFeatEvent < EventRule
    dsc        "エイジャの曙光が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_asia_feat
    goal       ["self", :use_end?]
  end

  class UseAsiaFeatEvent < EventRule
    dsc        "エイジャの曙光を使用 相手にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_asia_feat
    goal       ["self", :use_end?]
  end

  class FinishAsiaFeatEvent < EventRule
    dsc        "エイジャの曙光の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_asia_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# デモニック

  class CheckAddDemonicFeatEvent < EventRule
    dsc        "デモニックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_demonic_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDemonicFeatEvent < EventRule
    dsc        "デモニックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_demonic_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDemonicFeatEvent < EventRule
    dsc        "デモニックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_demonic_feat
    goal       ["self", :use_end?]
  end

  class UseDemonicFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_demonic_feat
    goal       ["self", :use_end?]
  end

  class FinishDemonicFeatEvent < EventRule
    dsc        "デモニックの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_demonic_feat
    goal       ["self", :use_end?]
  end

  class UseDemonicFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_demonic_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 残像剣


  class CheckAddShadowSwordFeatEvent < EventRule
    dsc        "残像剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_shadow_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShadowSwordFeatEvent < EventRule
    dsc        "残像剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_shadow_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShadowSwordFeatEvent < EventRule
    dsc        "残像剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_shadow_sword_feat
    goal       ["self", :use_end?]
  end

  class UseShadowSwordFeatEvent < EventRule
    dsc        "残像剣を使用 相手にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_shadow_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishShadowSwordFeatEvent < EventRule
    dsc        "残像剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shadow_sword_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# パーフェクトデッド

  class CheckAddPerfectDeadFeatEvent < EventRule
    dsc        "パーフェクトデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_perfect_dead_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePerfectDeadFeatEvent < EventRule
    dsc        "パーフェクトデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_perfect_dead_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePerfectDeadFeatEvent < EventRule
    dsc        "パーフェクトデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_perfect_dead_feat
    goal       ["self", :use_end?]
  end

  class UsePerfectDeadFeatEvent < EventRule
    dsc        "パーフェクトデッドを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_perfect_dead_feat
    goal       ["self", :use_end?]
  end

  class UsePerfectDeadFeatDamageEvent < EventRule
    dsc        "パーフェクトデッド使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_perfect_dead_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPerfectDeadFeatEvent < EventRule
    dsc        "パーフェクトデッドの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_perfect_dead_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 破壊の歯車

  class CheckAddDestructGearFeatEvent < EventRule
    dsc        "破壊の歯車が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_destruct_gear_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDestructGearFeatEvent < EventRule
    dsc        "破壊の歯車が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_destruct_gear_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDestructGearFeatEvent < EventRule
    dsc        "破壊の歯車が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_destruct_gear_feat
    goal       ["self", :use_end?]
  end

  class UseDestructGearFeatEvent < EventRule
    dsc        "破壊の歯車を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_destruct_gear_feat
    goal       ["self", :use_end?]
  end

  class UseDestructGearFeatDamageEvent < EventRule
    dsc        "破壊の歯車を使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_destruct_gear_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDestructGearFeatEvent < EventRule
    dsc        "破壊の歯車の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_destruct_gear_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# パワーシフト

  class CheckAddPowerShiftFeatEvent < EventRule
    dsc        "パワーシフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_power_shift_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePowerShiftFeatEvent < EventRule
    dsc        "パワーシフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_power_shift_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePowerShiftFeatEvent < EventRule
    dsc        "パワーシフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_power_shift_feat
    goal       ["self", :use_end?]
  end

  class UsePowerShiftFeatEvent < EventRule
    dsc        "パワーシフトを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_power_shift_feat
    goal       ["self", :use_end?]
  end

  class UsePowerShiftFeatDamageEvent < EventRule
    dsc        "パワーシフト使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>110
    func       :use_power_shift_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPowerShiftFeatEvent < EventRule
    dsc        "パワーシフトの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_power_shift_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# キルショット

  class CheckAddKillShotFeatEvent < EventRule
    dsc        "キルショットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_kill_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKillShotFeatEvent < EventRule
    dsc        "キルショットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_kill_shot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKillShotFeatEvent < EventRule
    dsc        "キルショットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_kill_shot_feat
    goal       ["self", :use_end?]
  end

  class UseKillShotFeatEvent < EventRule
    dsc        "キルショットを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_kill_shot_feat
    goal       ["self", :use_end?]
  end

  class UseKillShotFeatDamageEvent < EventRule
    dsc        "キルショットを使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_kill_shot_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishKillShotFeatEvent < EventRule
    dsc        "キルショットの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_kill_shot_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ディフレクト

  class CheckAddDefrectFeatEvent < EventRule
    dsc        "ディフレクトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_defrect_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDefrectFeatEvent < EventRule
    dsc        "ディフレクトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_defrect_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDefrectFeatEvent < EventRule
    dsc        "ディフレクトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_defrect_feat
    goal       ["self", :use_end?]
  end

  class UseDefrectFeatEvent < EventRule
    dsc        "ディフレクトを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_defrect_feat
    goal       ["self", :use_end?]
  end

  class UseDefrectFeatDamageEvent < EventRule
    dsc        "ディフレクト使用時にダメージとして相手に与える"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_defrect_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDefrectFeatEvent < EventRule
    dsc        "ディフレクトの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_defrect_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 炎の供物

  class CheckAddFlameOfferingFeatEvent < EventRule
    dsc        "炎の供物が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_flame_offering_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFlameOfferingFeatEvent < EventRule
    dsc        "炎の供物が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_flame_offering_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFlameOfferingFeatEvent < EventRule
    dsc        "炎の供物が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_flame_offering_feat
    goal       ["self", :use_end?]
  end

  class UseFlameOfferingFeatEvent < EventRule
    dsc        "炎の供物の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :use_flame_offering_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 吸収の手

  class CheckAddDrainHandFeatEvent < EventRule
    dsc        "吸収の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_drain_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDrainHandFeatEvent < EventRule
    dsc        "吸収の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_drain_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDrainHandFeatEvent < EventRule
    dsc        "吸収の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_drain_hand_feat
    goal       ["self", :use_end?]
  end

  class UseDrainHandFeatEvent < EventRule
    dsc        "吸収の手を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_drain_hand_feat
    goal       ["self", :use_end?]
  end

  class UseDrainHandFeatDamageEvent < EventRule
    dsc        "吸収の手を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_drain_hand_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDrainHandFeatEvent < EventRule
    dsc        "吸収の手の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_drain_hand_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 焔の監獄

  class CheckAddFirePrizonFeatEvent < EventRule
    dsc        "焔の監獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_fire_prizon_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFirePrizonFeatEvent < EventRule
    dsc        "焔の監獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_fire_prizon_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFirePrizonFeatEvent < EventRule
    dsc        "焔の監獄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_fire_prizon_feat
    goal       ["self", :use_end?]
  end

  class UseFirePrizonFeatEvent < EventRule
    dsc        "焔の監獄の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>20
    func       :use_fire_prizon_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 時間停止

  class CheckAddTimeStopFeatEvent < EventRule
    dsc        "時間停止が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_time_stop_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeStopFeatEvent < EventRule
    dsc        "時間停止が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_time_stop_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeStopFeatEvent < EventRule
    dsc        "時間停止が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_time_stop_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeStopFeatEvent < EventRule
    dsc        "時間停止を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_time_stop_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 即死防御

  class CheckAddDeadGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dead_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeadGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dead_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeadGuardFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dead_guard_feat
    goal       ["self", :use_end?]
  end

  class UseDeadGuardFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dead_guard_feat
    goal       ["self", :use_end?]
  end

  class UseDeadGuardFeatDamageEvent < EventRule
    dsc        "必殺技が使用される"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>90
    func       :use_dead_guard_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDeadGuardFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dead_guard_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 奇数即死

  class CheckAddDeadBlueFeatEvent < EventRule
    dsc        "奇数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dead_blue_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeadBlueFeatEvent < EventRule
    dsc        "奇数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dead_blue_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeadBlueFeatEvent < EventRule
    dsc        "奇数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dead_blue_feat
    goal       ["self", :use_end?]
  end

  class UseDeadBlueFeatEvent < EventRule
    dsc        "奇数即死を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dead_blue_feat
    goal       ["self", :use_end?]
  end

  class UseDeadBlueFeatDamageEvent < EventRule
    dsc        "奇数即死使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_dead_blue_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDeadBlueFeatEvent < EventRule
    dsc        "奇数即死の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dead_blue_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 善悪の彼岸

  class CheckAddEvilGuardFeatEvent < EventRule
    dsc        "善悪の彼岸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_evil_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEvilGuardFeatEvent < EventRule
    dsc        "善悪の彼岸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_evil_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEvilGuardFeatEvent < EventRule
    dsc        "善悪の彼岸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_evil_guard_feat
    goal       ["self", :use_end?]
  end

  class UseEvilGuardFeatEvent < EventRule
    dsc        "善悪の彼岸を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_evil_guard_feat
    goal       ["self", :use_end?]
  end

  class UseEvilGuardFeatDamageEvent < EventRule
    dsc        "善悪の彼岸使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_evil_guard_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishEvilGuardFeatEvent < EventRule
    dsc        "善悪の彼岸の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_evil_guard_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 道連れ

  class CheckAddAbyssEyesFeatEvent < EventRule
    dsc        "道連れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_abyss_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAbyssEyesFeatEvent < EventRule
    dsc        "道連れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_abyss_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAbyssEyesFeatEvent < EventRule
    dsc        "道連れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_abyss_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseAbyssEyesFeatEvent < EventRule
    dsc        "道連れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_abyss_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseAbyssEyesFeatDamageEvent < EventRule
    dsc        "道連れ発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>120
    func       :use_abyss_eyes_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishAbyssEyesFeatEvent < EventRule
    dsc        "道連れの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_abyss_eyes_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 偶数即死

  class CheckAddDeadRedFeatEvent < EventRule
    dsc        "偶数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dead_red_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeadRedFeatEvent < EventRule
    dsc        "偶数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dead_red_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeadRedFeatEvent < EventRule
    dsc        "偶数即死が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dead_red_feat
    goal       ["self", :use_end?]
  end

  class UseDeadRedFeatEvent < EventRule
    dsc        "偶数即死を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dead_red_feat
    goal       ["self", :use_end?]
  end

  class FinishDeadRedFeatEvent < EventRule
    dsc        "偶数即死の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dead_red_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 幽冥の夜

  class CheckAddNightGhostFeatEvent < EventRule
    dsc        "幽冥の夜が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_night_ghost_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNightGhostFeatEvent < EventRule
    dsc        "幽冥の夜が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_night_ghost_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNightGhostFeatEvent < EventRule
    dsc        "幽冥の夜が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_night_ghost_feat
    goal       ["self", :use_end?]
  end

  class UseNightGhostFeatEvent < EventRule
    dsc        "幽冥の夜を使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_night_ghost_feat
    goal       ["self", :use_end?]
  end

  class UseNightGhostFeatDamageEvent < EventRule
    dsc        "幽冥の夜を使用時にパーティにダメージ"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_night_ghost_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishNightGhostFeatEvent < EventRule
    dsc        "幽冥の夜の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_night_ghost_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 人形の軍勢

  class CheckAddAvatarWarFeatEvent < EventRule
    dsc        "人形の軍勢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_avatar_war_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAvatarWarFeatEvent < EventRule
    dsc        "人形の軍勢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_avatar_war_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAvatarWarFeatEvent < EventRule
    dsc        "人形の軍勢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_avatar_war_feat
    goal       ["self", :use_end?]
  end

  class UseAvatarWarFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_avatar_war_feat
    goal       ["self", :use_end?]
  end

  class FinishAvatarWarFeatEvent < EventRule
    dsc        "人形の軍勢の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_avatar_war_feat
    goal       ["self", :use_end?]
  end

  class UseAvatarWarFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_avatar_war_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 混沌の渦

  class CheckAddConfusePoolFeatEvent < EventRule
    dsc        "混沌の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_confuse_pool_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveConfusePoolFeatEvent < EventRule
    dsc        "混沌の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_confuse_pool_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateConfusePoolFeatEvent < EventRule
    dsc        "混沌の渦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_confuse_pool_feat
    goal       ["self", :use_end?]
  end

  class UseConfusePoolFeatEvent < EventRule
    dsc        "混沌の渦を使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_confuse_pool_feat
    goal       ["self", :use_end?]
  end


  class UseConfusePoolFeatDamageEvent < EventRule
    dsc        "混沌の渦を使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_confuse_pool_feat_damage
    goal       ["self", :use_end?]
  end


  class FinishConfusePoolFeatEvent < EventRule
    dsc        "混沌の渦の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_confuse_pool_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# プロミネンス

  class CheckAddProminenceFeatEvent < EventRule
    dsc        "プロミネンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_prominence_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveProminenceFeatEvent < EventRule
    dsc        "プロミネンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_prominence_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateProminenceFeatEvent < EventRule
    dsc        "プロミネンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_prominence_feat
    goal       ["self", :use_end?]
  end

  class UseProminenceFeatEvent < EventRule
    dsc        "プロミネンスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_prominence_feat
    goal       ["self", :use_end?]
  end

  class FinishProminenceFeatEvent < EventRule
    dsc        "プロミネンスを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_prominence_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# バトルアックス

  class CheckAddBattleAxeFeatEvent < EventRule
    dsc        "バトルアックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_battle_axe_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBattleAxeFeatEvent < EventRule
    dsc        "バトルアックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_battle_axe_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBattleAxeFeatEvent < EventRule
    dsc        "バトルアックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_battle_axe_feat
    goal       ["self", :use_end?]
  end

  class UseBattleAxeFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_battle_axe_feat
    goal       ["self", :use_end?]
  end

  class FinishBattleAxeFeatEvent < EventRule
    dsc        "バトルアックスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_battle_axe_feat
    goal       ["self", :use_end?]
  end

  class UseBattleAxeFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_battle_axe_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# MOAB


  class CheckAddMoabFeatEvent < EventRule
    dsc        "MOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_moab_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMoabFeatEvent < EventRule
    dsc        "MOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_moab_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMoabFeatEvent < EventRule
    dsc        "MOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_moab_feat
    goal       ["self", :use_end?]
  end

  class UseMoabFeatEvent < EventRule
    dsc        "MOABを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_moab_feat
    goal       ["self", :use_end?]
  end

  class FinishMoabFeatEvent < EventRule
    dsc        "MOABの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_moab_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# オーバーヒート

  class CheckAddOverHeatFeatEvent < EventRule
    dsc        "オーバーヒートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_over_heat_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOverHeatFeatEvent < EventRule
    dsc        "オーバーヒートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_over_heat_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOverHeatFeatEvent < EventRule
    dsc        "オーバーヒートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_over_heat_feat
    goal       ["self", :use_end?]
  end

  class FinishOverHeatFeatEvent < EventRule
    dsc        "オーバーヒートを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>1
    func       :finish_over_heat_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 蒼き薔薇

  class CheckAddBlueRoseFeatEvent < EventRule
    dsc        "蒼き薔薇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_blue_rose_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlueRoseFeatEvent < EventRule
    dsc        "蒼き薔薇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_blue_rose_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlueRoseFeatEvent < EventRule
    dsc        "蒼き薔薇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_blue_rose_feat
    goal       ["self", :use_end?]
  end

  class UseBlueRoseFeatEvent < EventRule
    dsc        "蒼き薔薇を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_blue_rose_feat
    goal       ["self", :use_end?]
  end

  class UseBlueRoseFeatDamageEvent < EventRule
    dsc        "蒼き薔薇使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_blue_rose_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishBlueRoseFeatEvent < EventRule
    dsc        "蒼き薔薇の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blue_rose_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 白鴉

  class CheckAddWhiteCrowFeatEvent < EventRule
    dsc        "白鴉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_white_crow_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWhiteCrowFeatEvent < EventRule
    dsc        "白鴉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_white_crow_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWhiteCrowFeatEvent < EventRule
    dsc        "白鴉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_white_crow_feat
    goal       ["self", :use_end?]
  end

  class FinishWhiteCrowFeatEvent < EventRule
    dsc        "白鴉を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_white_crow_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 深紅の月

  class CheckAddRedMoonFeatEvent < EventRule
    dsc        "深紅の月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_red_moon_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRedMoonFeatEvent < EventRule
    dsc        "深紅の月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_red_moon_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRedMoonFeatEvent < EventRule
    dsc        "深紅の月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_red_moon_feat
    goal       ["self", :use_end?]
  end

  class UseRedMoonFeatEvent < EventRule
    dsc        "深紅の月を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_red_moon_feat
    goal       ["self", :use_end?]
  end

  class UseRedMoonFeatDiceAttrEvent < EventRule
    dsc        "深紅の月を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>30
    func       :use_red_moon_feat_dice_attr
    goal       ["self", :use_end?]
  end

  class UseRedMoonFeatDamageEvent < EventRule
    dsc        "深紅の月を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_red_moon_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRedMoonFeatEvent < EventRule
    dsc        "深紅の月の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_red_moon_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Ex深紅の月

  class UseExRedMoonFeatDiceAttrEvent < EventRule
    dsc        "深紅の月を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>80
    func       :use_red_moon_feat_dice_attr
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 黒い太陽

  class CheckAddBlackSunFeatEvent < EventRule
    dsc        "黒い太陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_black_sun_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlackSunFeatEvent < EventRule
    dsc        "黒い太陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_black_sun_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlackSunFeatEvent < EventRule
    dsc        "黒い太陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_black_sun_feat
    goal       ["self", :use_end?]
  end

  class UseBlackSunFeatEvent < EventRule
    dsc        "黒い太陽を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_black_sun_feat
    goal       ["self", :use_end?]
  end

  class FinishBlackSunFeatEvent < EventRule
    dsc        "黒い太陽の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_black_sun_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ジラソーレ

  class CheckAddGirasoleFeatEvent < EventRule
    dsc        "ジラソーレが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_girasole_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGirasoleFeatEvent < EventRule
    dsc        "ジラソーレが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_girasole_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGirasoleFeatEvent < EventRule
    dsc        "ジラソーレが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_girasole_feat
    goal       ["self", :use_end?]
  end

  class UseGirasoleFeatEvent < EventRule
    dsc        "ジラソーレを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_girasole_feat
    goal       ["self", :use_end?]
  end

  class UseGirasoleFeatDamageEvent < EventRule
    dsc        "ジラソーレを使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_girasole_feat_damage
    goal       ["self", :use_end?]
  end

  class UseGirasoleFeatConstDamageEvent < EventRule
    dsc        "ジラソーレを使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_girasole_feat_const_damage
    goal       ["self", :use_end?]
  end

  class FinishGirasoleFeatEvent < EventRule
    dsc        "ジラソーレの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_girasole_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ビオレッタ

  class CheckAddViolettaFeatEvent < EventRule
    dsc        "ビオレッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_violetta_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveViolettaFeatEvent < EventRule
    dsc        "ビオレッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_violetta_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateViolettaFeatEvent < EventRule
    dsc        "ビオレッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_violetta_feat
    goal       ["self", :use_end?]
  end

  class FinishViolettaFeatEvent < EventRule
    dsc        "ビオレッタを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_violetta_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ディジタリス

  class CheckAddDigitaleFeatEvent < EventRule
    dsc        "ディジタリスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_digitale_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDigitaleFeatEvent < EventRule
    dsc        "ディジタリスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_digitale_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDigitaleFeatEvent < EventRule
    dsc        "ディジタリスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_digitale_feat
    goal       ["self", :use_end?]
  end

  class UseDigitaleFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_digitale_feat
    goal       ["self", :use_end?]
  end

  class FinishDigitaleFeatEvent < EventRule
    dsc        "ディジタリスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_digitale_feat
    goal       ["self", :use_end?]
  end

  class UseDigitaleFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :use_digitale_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ロスマリーノ


  class CheckAddRosmarinoFeatEvent < EventRule
    dsc        "ロスマリーノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rosmarino_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRosmarinoFeatEvent < EventRule
    dsc        "ロスマリーノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rosmarino_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRosmarinoFeatEvent < EventRule
    dsc        "ロスマリーノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rosmarino_feat
    goal       ["self", :use_end?]
  end

  class UseRosmarinoFeatEvent < EventRule
    dsc        "ロスマリーノを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rosmarino_feat
    goal       ["self", :use_end?]
  end

  class FinishRosmarinoFeatEvent < EventRule
    dsc        "ロスマリーノの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rosmarino_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 八葉

  class CheckAddHachiyouFeatEvent < EventRule
    dsc        "八葉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_hachiyou_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHachiyouFeatEvent < EventRule
    dsc        "八葉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_hachiyou_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHachiyouFeatEvent < EventRule
    dsc        "八葉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_hachiyou_feat
    goal       ["self", :use_end?]
  end

  class FinishHachiyouFeatEvent < EventRule
    dsc        "八葉を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_hachiyou_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 鉄石の構え


  class CheckAddStoneCareFeatEvent < EventRule
    dsc        "鉄石の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_stone_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveStoneCareFeatEvent < EventRule
    dsc        "鉄石の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_stone_care_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateStoneCareFeatEvent < EventRule
    dsc        "鉄石の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_stone_care_feat
    goal       ["self", :use_end?]
  end

  class UseStoneCareFeatEvent < EventRule
    dsc        "鉄石の構えを使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_stone_care_feat
    goal       ["self", :use_end?]
  end

  class FinishStoneCareFeatEvent < EventRule
    dsc        "鉄石の構えの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_stone_care_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 絶塵剣

  class CheckAddDustSwordFeatEvent < EventRule
    dsc        "絶塵剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dust_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDustSwordFeatEvent < EventRule
    dsc        "絶塵剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dust_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDustSwordFeatEvent < EventRule
    dsc        "絶塵剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dust_sword_feat
    goal       ["self", :use_end?]
  end

  class UseDustSwordFeatEvent < EventRule
    dsc        "絶塵剣を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dust_sword_feat
    goal       ["self", :use_end?]
  end

  class UseDustSwordFeatDamageEvent < EventRule
    dsc        "絶塵剣を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_dust_sword_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDustSwordFeatEvent < EventRule
    dsc        "絶塵剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dust_sword_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 夢幻

  class CheckAddIllusionFeatEvent < EventRule
    dsc        "夢幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_illusion_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIllusionFeatEvent < EventRule
    dsc        "夢幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_illusion_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIllusionFeatEvent < EventRule
    dsc        "夢幻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_illusion_feat
    goal       ["self", :use_end?]
  end

  class UseIllusionFeatEvent < EventRule
    dsc        "夢幻を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_illusion_feat
    goal       ["self", :use_end?]
  end

  class UseIllusionFeatDamageEvent < EventRule
    dsc        "夢幻を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_illusion_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishIllusionFeatEvent < EventRule
    dsc        "夢幻の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_illusion_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 絶望の叫び

  class CheckAddDespairShoutFeatEvent < EventRule
    dsc        "絶望の叫びが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_despair_shout_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDespairShoutFeatEvent < EventRule
    dsc        "絶望の叫びが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_despair_shout_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDespairShoutFeatEvent < EventRule
    dsc        "絶望の叫びが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_despair_shout_feat
    goal       ["self", :use_end?]
  end

  class FinishDespairShoutFeatEvent < EventRule
    dsc        "絶望の叫びを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_despair_shout_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 暗黒神の歌

  class CheckAddDarknessSongFeatEvent < EventRule
    dsc        "暗黒神の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_darkness_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDarknessSongFeatEvent < EventRule
    dsc        "暗黒神の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_darkness_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDarknessSongFeatEvent < EventRule
    dsc        "暗黒神の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_darkness_song_feat
    goal       ["self", :use_end?]
  end

  class UseDarknessSongFeatEvent < EventRule
    dsc        "暗黒神の歌を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>1
    func       :use_darkness_song_feat
    goal       ["self", :use_end?]
  end

  class FinishDarknessSongFeatEvent < EventRule
    dsc        "暗黒神の歌の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_darkness_song_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 守護霊の魂

  class CheckAddGuardSpiritFeatEvent < EventRule
    dsc        "守護霊の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_guard_spirit_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGuardSpiritFeatEvent < EventRule
    dsc        "守護霊の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_guard_spirit_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGuardSpiritFeatEvent < EventRule
    dsc        "守護霊の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_guard_spirit_feat
    goal       ["self", :use_end?]
  end

  class FinishGuardSpiritFeatEvent < EventRule
    dsc        "守護霊の魂を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_guard_spirit_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 殺戮器官

  class CheckAddSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

  class UseSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官をを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

  class FinishSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnSlaughterOrganFeatEvent < EventRule
    dsc        "殺戮器官を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_slaughter_organ_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 愚者の手

  class CheckAddFoolsHandFeatEvent < EventRule
    dsc        "愚者の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_fools_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFoolsHandFeatEvent < EventRule
    dsc        "愚者の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_fools_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFoolsHandFeatEvent < EventRule
    dsc        "愚者の手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_fools_hand_feat
    goal       ["self", :use_end?]
  end

  class UseFoolsHandFeatEvent < EventRule
    dsc        "愚者の手を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_fools_hand_feat
    goal       ["self", :use_end?]
  end

  class UseFoolsHandFeatDamageEvent < EventRule
    dsc        "愚者の手を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_fools_hand_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishFoolsHandFeatEvent < EventRule
    dsc        "愚者の手の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_fools_hand_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 時の種子


  class CheckAddTimeSeedFeatEvent < EventRule
    dsc        "時の種子が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_time_seed_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeSeedFeatEvent < EventRule
    dsc        "時の種子が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_time_seed_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeSeedFeatEvent < EventRule
    dsc        "時の種子が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_time_seed_feat
    goal       ["self", :use_end?]
  end

  class UseTimeSeedFeatEvent < EventRule
    dsc        "時の種子を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_time_seed_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeSeedFeatEvent < EventRule
    dsc        "時の種子の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_time_seed_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 運命の鉄門

  class CheckAddIrongateOfFateFeatEvent < EventRule
    dsc        "運命の鉄門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_irongate_of_fate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIrongateOfFateFeatEvent < EventRule
    dsc        "運命の鉄門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_irongate_of_fate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIrongateOfFateFeatEvent < EventRule
    dsc        "運命の鉄門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_irongate_of_fate_feat
    goal       ["self", :use_end?]
  end

  class UseIrongateOfFateFeatEvent < EventRule
    dsc        "運命の鉄門を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_irongate_of_fate_feat
    goal       ["self", :use_end?]
  end

  class UseIrongateOfFateFeatDamageEvent < EventRule
    dsc        "運命の鉄門を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_irongate_of_fate_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishIrongateOfFateFeatEvent < EventRule
    dsc        "運命の鉄門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_irongate_of_fate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ザ・ギャザラー

  class CheckAddGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_gatherer_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_gatherer_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_gatherer_feat
    goal       ["self", :use_end?]
  end

  class UseGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_gatherer_feat
    goal       ["self", :use_end?]
  end

  class UseNextGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーの回収予約"
    type       :type=>:before, :obj=>"owner", :hook=>:move_phase_init_event
    func       :use_next_gatherer_feat
    goal       ["self", :use_end?]
  end

  class FinishGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーの使用が終了"
    type       :type=>:before, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :finish_gatherer_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_gatherer_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeCharaChangeGathererFeatEvent < EventRule
    dsc        "ザ・ギャザラーの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_gatherer_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ザ・ジャッジ

  class CheckAddJudgeFeatEvent < EventRule
    dsc        "ザ・ジャッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_judge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveJudgeFeatEvent < EventRule
    dsc        "ザ・ジャッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_judge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateJudgeFeatEvent < EventRule
    dsc        "ザ・ジャッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_judge_feat
    goal       ["self", :use_end?]
  end

  class UseJudgeFeatEvent < EventRule
    dsc        "ザ・ジャッジを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_judge_feat
    goal       ["self", :use_end?]
  end

  class UseJudgeFeatDamageEvent < EventRule
    dsc        "ザ・ジャッジ使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_judge_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishJudgeFeatEvent < EventRule
    dsc        "ザ・ジャッジの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:battle_result_phase, :priority=>10
    func       :finish_judge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ザ・ドリーム

  class CheckAddDreamFeatEvent < EventRule
    dsc        "ザ・ドリームが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dream_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDreamFeatEvent < EventRule
    dsc        "ザ・ドリームが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dream_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDreamFeatEvent < EventRule
    dsc        "ザ・ドリームが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dream_feat
    goal       ["self", :use_end?]
  end

  class UseDreamFeatEvent < EventRule
    dsc        "ザ・ドリームを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dream_feat
    goal       ["self", :use_end?]
  end

  class UseDreamFeatDamageEvent < EventRule
    dsc        "ザ・ドリームを使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_dream_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDreamFeatEvent < EventRule
    dsc        "ザ・ドリームの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dream_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ジ・ワン・アボヴ・オール

  class CheckAddOneAboveAllFeatEvent < EventRule
    dsc        "ジ・ワン・アボヴ・オールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_one_above_all_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOneAboveAllFeatEvent < EventRule
    dsc        "ジ・ワン・アボヴ・オールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_one_above_all_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOneAboveAllFeatEvent < EventRule
    dsc        "ジ・ワン・アボヴ・オールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_one_above_all_feat
    goal       ["self", :use_end?]
  end

  class UseOneAboveAllFeatEvent < EventRule
    dsc        "ジ・ワン・アボヴ・オールの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>1
    func       :use_one_above_all_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アンチセプティック・F

  class CheckAddAntisepticFeatEvent < EventRule
    dsc        "アンチセプティック・Fが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAntisepticFeatEvent < EventRule
    dsc        "アンチセプティック・Fが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAntisepticFeatEvent < EventRule
    dsc        "アンチセプティック・Fが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class UseAntisepticFeatEvent < EventRule
    dsc        "アンチセプティック・Fを使用"
    type       :type=>:before, :obj=>"owner", :hook=>:move_phase_init_event
    func       :use_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class FinishAntisepticFeatEvent < EventRule
    dsc        "アンチセプティック・Fを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnAntisepticFeatEvent < EventRule
    dsc        "アンチセプティックFが終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase, :priority=>50
    func       :finish_turn_antiseptic_feat
    goal       ["self", :use_end?]
  end

  class CheckAntisepticStateChangeEvent < EventRule
    dsc        "アンチセプティックF状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_antiseptic_state_change
    goal       ["self", :use_end?]
  end

  class CheckAntisepticStateDeadChangeEvent < EventRule
    dsc        "アンチセプティックF状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_antiseptic_state_change
    goal       ["self", :use_end?]
  end

  class FinishAntisepticStateEvent < EventRule
    dsc        "アンチセプティックF状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :finish_antiseptic_state
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# シルバーマシン

  class CheckAddSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_silver_machine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_silver_machine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_silver_machine_feat
    goal       ["self", :use_end?]
  end

  class UseSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンを使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_silver_machine_feat
    goal       ["self", :use_end?]
  end

  class FinishSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_silver_machine_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnSilverMachineFeatEvent < EventRule
    dsc        "シルバーマシンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_silver_machine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アトムハート

  class CheckAddAtomHeartFeatEvent < EventRule
    dsc        "アトムハートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAtomHeartFeatEvent < EventRule
    dsc        "アトムハートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAtomHeartFeatEvent < EventRule
    dsc        "アトムハートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class UseAtomHeartFeatEvent < EventRule
    dsc        "アトムハートを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class UseNextAtomHeartFeatEvent < EventRule
    dsc        "アトムハートのエフェクト"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_next_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class FinishAtomHeartFeatEvent < EventRule
    dsc        "アトムハートの使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class FinishResultAtomHeartFeatEvent < EventRule
    dsc        "アトムハートの使用"
    type       :type=>:before, :obj=>"duel", :hook=>:battle_result_phase
    func       :finish_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class FinishCalcAtomHeartFeatEvent < EventRule
    dsc        "アトムハートを使用"
    type       :type=>:before, :obj=>"foe", :hook=>:dp_calc_resolve
    func       :finish_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class DisableAtomHeartFeatEvent < EventRule
    dsc        "アトムハートを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:change_initiative_phase
    func       :disable_atom_heart_feat
    goal       ["self", :use_end?]
  end

  class DisableNextAtomHeartFeatEvent < EventRule
    dsc        "アトムハートを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :disable_atom_heart_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# エレクトロサージェリー

  class CheckAddElectricSurgeryFeatEvent < EventRule
    dsc        "エレクトロサージェリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_electric_surgery_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveElectricSurgeryFeatEvent < EventRule
    dsc        "エレクトロサージェリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_electric_surgery_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateElectricSurgeryFeatEvent < EventRule
    dsc        "エレクトロサージェリーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_electric_surgery_feat
    goal       ["self", :use_end?]
  end

  class UseElectricSurgeryFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_electric_surgery_feat
    goal       ["self", :use_end?]
  end

  class FinishElectricSurgeryFeatEvent < EventRule
    dsc        "エレクトロサージェリーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_electric_surgery_feat
    goal       ["self", :use_end?]
  end

  class UseElectricSurgeryFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_electric_surgery_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アシッドイーター

  class CheckAddAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class FinishUsedDetermineAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_used_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class FinishDetermineAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>5
    func       :finish_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class FinishCalcAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターを使用"
    type       :type=>:before, :obj=>"foe", :hook=>:mp_calc_resolve, :priority=>10
    func       :finish_acid_eater_feat
    goal       ["self", :use_end?]
  end

  class FinishNextAcidEaterFeatEvent < EventRule
    dsc        "アシッドイーターを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_next_acid_eater_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# デッドロック

  class CheckAddDeadLockFeatEvent < EventRule
    dsc        "デッドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dead_lock_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeadLockFeatEvent < EventRule
    dsc        "デッドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dead_lock_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeadLockFeatEvent < EventRule
    dsc        "デッドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dead_lock_feat
    goal       ["self", :use_end?]
  end

  class UseDeadLockFeatEvent < EventRule
    dsc        "デッドロックを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dead_lock_feat
    goal       ["self", :use_end?]
  end

  class UseDeadLockFeatDamageEvent < EventRule
    dsc        "デッドロック使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_dead_lock_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDeadLockFeatEvent < EventRule
    dsc        "デッドロックの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dead_lock_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ベガーズバンケット

  class CheckAddBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class UseBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class ExBeggarsBanquetTmpFeatEvent < EventRule
    dsc        "ベガーズバンケットの拡張 カードキープ"
    type       :type=>:before, :obj=>"owner", :hook=>:move_phase_init_event
    func       :ex_beggars_banquet_tmp_feat
    goal       ["self", :use_end?]
  end

  class FinishExBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットの使用が終了"
    type       :type=>:before, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :finish_ex_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeExBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_ex_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeCharaChangeExBeggarsBanquetFeatEvent < EventRule
    dsc        "ベガーズバンケットの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_ex_beggars_banquet_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スワンソング

  class CheckAddSwanSongFeatEvent < EventRule
    dsc        "スワンソングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_swan_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSwanSongFeatEvent < EventRule
    dsc        "スワンソングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_swan_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSwanSongFeatEvent < EventRule
    dsc        "スワンソングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_swan_song_feat
    goal       ["self", :use_end?]
  end

  class UseSwanSongFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_swan_song_feat
    goal       ["self", :use_end?]
  end

  class FinishSwanSongFeatEvent < EventRule
    dsc        "スワンソングの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_swan_song_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 懶惰の墓標

  class CheckAddIdleGraveFeatEvent < EventRule
    dsc        "懶惰の墓標が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_idle_grave_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIdleGraveFeatEvent < EventRule
    dsc        "懶惰の墓標が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_idle_grave_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIdleGraveFeatEvent < EventRule
    dsc        "懶惰の墓標が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_idle_grave_feat
    goal       ["self", :use_end?]
  end

  class UseIdleGraveFeatEvent < EventRule
    dsc        "懶惰の墓標の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :use_idle_grave_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 慟哭の歌

  class CheckAddSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_sorrow_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_sorrow_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_sorrow_song_feat
    goal       ["self", :use_end?]
  end

  class UseSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌の使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>90
    func       :use_sorrow_song_feat
    goal       ["self", :use_end?]
  end

  class FinishSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:battle_result_phase
    func       :finish_sorrow_song_feat
    goal       ["self", :use_end?]
  end

  class FinishExSorrowSongFeatEvent < EventRule
    dsc        "慟哭の歌の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_ex_sorrow_song_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 紅蓮の車輪

  class CheckAddRedWheelFeatEvent < EventRule
    dsc        "紅蓮の車輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_red_wheel_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRedWheelFeatEvent < EventRule
    dsc        "紅蓮の車輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_red_wheel_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRedWheelFeatEvent < EventRule
    dsc        "紅蓮の車輪が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_red_wheel_feat
    goal       ["self", :use_end?]
  end

  class UseRedWheelFeatEvent < EventRule
    dsc        "紅蓮の車輪を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_red_wheel_feat
    goal       ["self", :use_end?]
  end

  class UseRedWheelFeatDamageEvent < EventRule
    dsc        "紅蓮の車輪を使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_red_wheel_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRedWheelFeatEvent < EventRule
    dsc        "紅蓮の車輪の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_red_wheel_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 赤い石榴

  class CheckAddRedPomegranateFeatEvent < EventRule
    dsc        "赤い石榴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_red_pomegranate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRedPomegranateFeatEvent < EventRule
    dsc        "赤い石榴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_red_pomegranate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRedPomegranateFeatEvent < EventRule
    dsc        "赤い石榴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_red_pomegranate_feat
    goal       ["self", :use_end?]
  end

  class FinishRedPomegranateFeatEvent < EventRule
    dsc        "赤い石榴を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_red_pomegranate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クロックワークス

  class CheckAddClockWorksFeatEvent < EventRule
    dsc        "クロックワークスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_clock_works_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveClockWorksFeatEvent < EventRule
    dsc        "クロックワークスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_clock_works_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateClockWorksFeatEvent < EventRule
    dsc        "クロックワークスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_clock_works_feat
    goal       ["self", :use_end?]
  end

  class FinishClockWorksFeatEvent < EventRule
    dsc        "クロックワークスを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_clock_works_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# タイムハント

  class CheckAddTimeHuntFeatEvent < EventRule
    dsc        "タイムハントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_time_hunt_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeHuntFeatEvent < EventRule
    dsc        "タイムハントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_time_hunt_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeHuntFeatEvent < EventRule
    dsc        "タイムハントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_time_hunt_feat
    goal       ["self", :use_end?]
  end

  class UseExTimeHuntFeatEvent < EventRule
    dsc        "タイムハントを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_ex_time_hunt_feat
    goal       ["self", :use_end?]
  end

  class UseTimeHuntFeatEvent < EventRule
    dsc        "タイムハントを使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>90
    func       :use_time_hunt_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeHuntFeatEvent < EventRule
    dsc        "タイムハントの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_time_hunt_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# タイムボム


  class CheckAddTimeBombFeatEvent < EventRule
    dsc        "タイムボムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_time_bomb_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeBombFeatEvent < EventRule
    dsc        "タイムボムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_time_bomb_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeBombFeatEvent < EventRule
    dsc        "タイムボムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_time_bomb_feat
    goal       ["self", :use_end?]
  end

  class UseTimeBombFeatEvent < EventRule
    dsc        "タイムボムを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_time_bomb_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeBombFeatEvent < EventRule
    dsc        "タイムボムの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_time_bomb_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# インジイブニング

  class CheckAddInTheEveningFeatEvent < EventRule
    dsc        "インジイブニングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_in_the_evening_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveInTheEveningFeatEvent < EventRule
    dsc        "インジイブニングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_in_the_evening_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateInTheEveningFeatEvent < EventRule
    dsc        "インジイブニングが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_in_the_evening_feat
    goal       ["self", :use_end?]
  end

  class FinishInTheEveningFeatEvent < EventRule
    dsc        "インジイブニングの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :finish_in_the_evening_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 終局のワルツ

  class CheckAddFinalWaltzFeatEvent < EventRule
    dsc        "終局のワルツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_final_waltz_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFinalWaltzFeatEvent < EventRule
    dsc        "終局のワルツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_final_waltz_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFinalWaltzFeatEvent < EventRule
    dsc        "終局のワルツが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_final_waltz_feat
    goal       ["self", :use_end?]
  end

  class UseFinalWaltzFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_final_waltz_feat
    goal       ["self", :use_end?]
  end

  class FinishFinalWaltzFeatEvent < EventRule
    dsc        "終局のワルツの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_final_waltz_feat
    goal       ["self", :use_end?]
  end

  class UseFinalWaltzFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_final_waltz_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 自棄のソナタ

  class CheckAddDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

  class UseDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

  class FinishDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>50
    func       :finish_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnDesperateSonataFeatEvent < EventRule
    dsc        "自棄のソナタを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_desperate_sonata_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 剣闘士のマーチ


  class CheckAddGladiatorMarchFeatEvent < EventRule
    dsc        "剣闘士のマーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_gladiator_march_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGladiatorMarchFeatEvent < EventRule
    dsc        "剣闘士のマーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_gladiator_march_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGladiatorMarchFeatEvent < EventRule
    dsc        "剣闘士のマーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_gladiator_march_feat
    goal       ["self", :use_end?]
  end

  class UseGladiatorMarchFeatEvent < EventRule
    dsc        "剣闘士のマーチを使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_gladiator_march_feat
    goal       ["self", :use_end?]
  end

  class FinishGladiatorMarchFeatEvent < EventRule
    dsc        "剣闘士のマーチの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_gladiator_march_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 恩讐のレクイエム

  class CheckAddRequiemOfRevengeFeatEvent < EventRule
    dsc        "恩讐のレクイエムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_requiem_of_revenge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRequiemOfRevengeFeatEvent < EventRule
    dsc        "恩讐のレクイエムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_requiem_of_revenge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRequiemOfRevengeFeatEvent < EventRule
    dsc        "恩讐のレクイエムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_requiem_of_revenge_feat
    goal       ["self", :use_end?]
  end

  class UseRequiemOfRevengeFeatEvent < EventRule
    dsc        "恩讐のレクイエムを使用 相手にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_requiem_of_revenge_feat
    goal       ["self", :use_end?]
  end

  class FinishRequiemOfRevengeFeatEvent < EventRule
    dsc        "恩讐のレクイエムの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_requiem_of_revenge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# おいしいミルク

  class CheckAddDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class UseDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class UseExDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>1
    func       :use_ex_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishChangeDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_change_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_delicious_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnDeliciousMilkFeatEvent < EventRule
    dsc        "おいしいミルクを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_delicious_milk_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# やさしいお注射


  class CheckAddEasyInjectionFeatEvent < EventRule
    dsc        "やさしいお注射が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_easy_injection_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEasyInjectionFeatEvent < EventRule
    dsc        "やさしいお注射が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_easy_injection_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEasyInjectionFeatEvent < EventRule
    dsc        "やさしいお注射が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_easy_injection_feat
    goal       ["self", :use_end?]
  end

  class UseEasyInjectionFeatEvent < EventRule
    dsc        "やさしいお注射を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_easy_injection_feat
    goal       ["self", :use_end?]
  end

  class FinishEasyInjectionFeatEvent < EventRule
    dsc        "やさしいお注射の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_easy_injection_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# たのしい採血

  class CheckAddBloodCollectingFeatEvent < EventRule
    dsc        "たのしい採血が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blood_collecting_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBloodCollectingFeatEvent < EventRule
    dsc        "たのしい採血が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blood_collecting_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBloodCollectingFeatEvent < EventRule
    dsc        "たのしい採血が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blood_collecting_feat
    goal       ["self", :use_end?]
  end

  class UseBloodCollectingFeatEvent < EventRule
    dsc        "たのしい採血を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blood_collecting_feat
    goal       ["self", :use_end?]
  end

  class FinishBloodCollectingFeatEvent < EventRule
    dsc        "たのしい採血の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blood_collecting_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 秘密のお薬


  class CheckAddSecretMedicineFeatEvent < EventRule
    dsc        "秘密のお薬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_secret_medicine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSecretMedicineFeatEvent < EventRule
    dsc        "秘密のお薬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_secret_medicine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSecretMedicineFeatEvent < EventRule
    dsc        "秘密のお薬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_secret_medicine_feat
    goal       ["self", :use_end?]
  end

  class UseSecretMedicineFeatEvent < EventRule
    dsc        "秘密のお薬を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_secret_medicine_feat
    goal       ["self", :use_end?]
  end

  class FinishSecretMedicineFeatEvent < EventRule
    dsc        "秘密のお薬の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>99
    func       :finish_secret_medicine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 氷の門

  class CheckAddIceGateFeatEvent < EventRule
    dsc        "氷の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ice_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIceGateFeatEvent < EventRule
    dsc        "氷の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ice_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIceGateFeatEvent < EventRule
    dsc        "氷の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ice_gate_feat
    goal       ["self", :use_end?]
  end

  class UseIceGateFeatEvent < EventRule
    dsc        "氷の門を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ice_gate_feat
    goal       ["self", :use_end?]
  end

  class FinishIceGateFeatEvent < EventRule
    dsc        "氷の門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_ice_gate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 炎の門

  class CheckAddFireGateFeatEvent < EventRule
    dsc        "炎の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_fire_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFireGateFeatEvent < EventRule
    dsc        "炎の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_fire_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFireGateFeatEvent < EventRule
    dsc        "炎の門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_fire_gate_feat
    goal       ["self", :use_end?]
  end

  class UseFireGateFeatEvent < EventRule
    dsc        "炎の門を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_fire_gate_feat
    goal       ["self", :use_end?]
  end

  class FinishFireGateFeatEvent < EventRule
    dsc        "炎の門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_fire_gate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 崩れる門


  class CheckAddBreakGateFeatEvent < EventRule
    dsc        "崩れる門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_break_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBreakGateFeatEvent < EventRule
    dsc        "崩れる門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_break_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBreakGateFeatEvent < EventRule
    dsc        "崩れる門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_break_gate_feat
    goal       ["self", :use_end?]
  end

  class UseBreakGateFeatEvent < EventRule
    dsc        "崩れる門を使用 自分にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_break_gate_feat
    goal       ["self", :use_end?]
  end

  class FinishBreakGateFeatEvent < EventRule
    dsc        "崩れる門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_break_gate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 叫ぶ門

  class CheckAddShoutOfGateFeatEvent < EventRule
    dsc        "叫ぶ門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_shout_of_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShoutOfGateFeatEvent < EventRule
    dsc        "叫ぶ門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_shout_of_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShoutOfGateFeatEvent < EventRule
    dsc        "叫ぶ門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_shout_of_gate_feat
    goal       ["self", :use_end?]
  end

  class UseShoutOfGateFeatEvent < EventRule
    dsc        "叫ぶ門を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_shout_of_gate_feat
    goal       ["self", :use_end?]
  end

  class UseShoutOfGateFeatDamageEvent < EventRule
    dsc        "叫ぶ門使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_shout_of_gate_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishShoutOfGateFeatEvent < EventRule
    dsc        "叫ぶ門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shout_of_gate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# フュリアスアンガー

  class CheckAddFerreousAngerFeatEvent < EventRule
    dsc        "フュリアスアンガーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ferreous_anger_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFerreousAngerFeatEvent < EventRule
    dsc        "フュリアスアンガーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ferreous_anger_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFerreousAngerFeatEvent < EventRule
    dsc        "フュリアスアンガーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ferreous_anger_feat
    goal       ["self", :use_end?]
  end

  class UseFerreousAngerFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ferreous_anger_feat
    goal       ["self", :use_end?]
  end

  class FinishFerreousAngerFeatEvent < EventRule
    dsc        "フュリアスアンガーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_ferreous_anger_feat
    goal       ["self", :use_end?]
  end

  class UseFerreousAngerFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :use_ferreous_anger_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ネームオブチャリティ

  class CheckAddNameOfCharityFeatEvent < EventRule
    dsc        "ネームオブチャリティが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_name_of_charity_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNameOfCharityFeatEvent < EventRule
    dsc        "ネームオブチャリティが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_name_of_charity_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNameOfCharityFeatEvent < EventRule
    dsc        "ネームオブチャリティが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_name_of_charity_feat
    goal       ["self", :use_end?]
  end

  class UseNameOfCharityFeatEvent < EventRule
    dsc        "ネームオブチャリティの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :use_name_of_charity_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# グッドウィル


  class CheckAddGoodWillFeatEvent < EventRule
    dsc        "グッドウィルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_good_will_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGoodWillFeatEvent < EventRule
    dsc        "グッドウィルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_good_will_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGoodWillFeatEvent < EventRule
    dsc        "グッドウィルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_good_will_feat
    goal       ["self", :use_end?]
  end

  class UseGoodWillFeatEvent < EventRule
    dsc        "グッドウィルを使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_good_will_feat
    goal       ["self", :use_end?]
  end

  class FinishGoodWillFeatEvent < EventRule
    dsc        "グッドウィルの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_good_will_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# グレードベンジェンス

  class CheckAddGreatVengeanceFeatEvent < EventRule
    dsc        "グレードベンジェンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_great_vengeance_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGreatVengeanceFeatEvent < EventRule
    dsc        "グレードベンジェンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_great_vengeance_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGreatVengeanceFeatEvent < EventRule
    dsc        "グレードベンジェンスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_great_vengeance_feat
    goal       ["self", :use_end?]
  end

  class UseGreatVengeanceFeatEvent < EventRule
    dsc        "グレードベンジェンスを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_great_vengeance_feat
    goal       ["self", :use_end?]
  end

  class UseGreatVengeanceFeatDamageEvent < EventRule
    dsc        "グレードベンジェンスを使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_great_vengeance_feat_damage
    goal       ["self", :use_end?]
  end

  class UseGreatVengeanceFeatConstDamageEvent < EventRule
    dsc        "グレードベンジェンスを使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_great_vengeance_feat_const_damage
    goal       ["self", :use_end?]
  end

  class FinishGreatVengeanceFeatEvent < EventRule
    dsc        "グレードベンジェンスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_great_vengeance_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 無辜の魂(無縫天衣)

  class CheckAddInnocentSoulFeatEvent < EventRule
    dsc        "無辜の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_innocent_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveInnocentSoulFeatEvent < EventRule
    dsc        "無辜の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_innocent_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateInnocentSoulFeatEvent < EventRule
    dsc        "無辜の魂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_innocent_soul_feat
    goal       ["self", :use_end?]
  end

  class FinishInnocentSoulFeatEvent < EventRule
    dsc        "無辜の魂を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>9
    func       :finish_innocent_soul_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 無謬の行い(光彩陸離)

  class CheckAddInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class UseInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_evaluation_event
    func       :finish_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishEffectInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_effect_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :finish_chara_change_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeChangeInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_change_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishOwnerChangeInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_change_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishDeadChangeInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:dead_chara_change_phase
    func       :finish_change_infallible_deed_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnInfallibleDeedFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_infallible_deed_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 無為の運命(転生輪廻)

  class CheckAddIdleFateFeatEvent < EventRule
    dsc        "無為の運命が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_idle_fate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIdleFateFeatEvent < EventRule
    dsc        "無為の運命が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_idle_fate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIdleFateFeatEvent < EventRule
    dsc        "無為の運命が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_idle_fate_feat
    goal       ["self", :use_end?]
  end

  class UseIdleFateFeatEvent < EventRule
    dsc        "無為の運命を使用 攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_idle_fate_feat
    goal       ["self", :use_end?]
  end

  class UseIdleFateFeatDamageEvent < EventRule
    dsc        "無為の運命を使用時、相手を倒した場合手札枚数の最大値を１減らす"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>99
    func       :use_idle_fate_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishIdleFateFeatEvent < EventRule
    dsc        "無為の運命の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_idle_fate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 無念の裁き(往生極楽)

  class CheckAddRegrettableJudgmentFeatEvent < EventRule
    dsc        "無念の裁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_regrettable_judgment_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRegrettableJudgmentFeatEvent < EventRule
    dsc        "無念の裁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_regrettable_judgment_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRegrettableJudgmentFeatEvent < EventRule
    dsc        "無念の裁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_regrettable_judgment_feat
    goal       ["self", :use_end?]
  end

  class UseRegrettableJudgmentFeatEvent < EventRule
    dsc        "無念の裁きを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_regrettable_judgment_feat
    goal       ["self", :use_end?]
  end

  class UseRegrettableJudgmentFeatDamageEvent < EventRule
    dsc        "無念の裁き発動"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>120
    func       :use_regrettable_judgment_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRegrettableJudgmentFeatEvent < EventRule
    dsc        "無念の裁きの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_regrettable_judgment_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 罪業の蠢き

  class CheckAddSinWriggleFeatEvent < EventRule
    dsc        "罪業の蠢きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_sin_wriggle_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSinWriggleFeatEvent < EventRule
    dsc        "罪業の蠢きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_sin_wriggle_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSinWriggleFeatEvent < EventRule
    dsc        "罪業の蠢きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_sin_wriggle_feat
    goal       ["self", :use_end?]
  end

  class UseSinWriggleFeatEvent < EventRule
    dsc        "罪業の蠢きを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_sin_wriggle_feat
    goal       ["self", :use_end?]
  end

  class UseSinWriggleFeatDamageEvent < EventRule
    dsc        "罪業の蠢き使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_sin_wriggle_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishSinWriggleFeatEvent < EventRule
    dsc        "2つの身体の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_sin_wriggle_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 懶惰の呻き

  class CheckAddIdleGroanFeatEvent < EventRule
    dsc        "懶惰の呻きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_idle_groan_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveIdleGroanFeatEvent < EventRule
    dsc        "懶惰の呻きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_idle_groan_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateIdleGroanFeatEvent < EventRule
    dsc        "懶惰の呻きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_idle_groan_feat
    goal       ["self", :use_end?]
  end

  class UseIdleGroanFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_idle_groan_feat
    goal       ["self", :use_end?]
  end

  class FinishIdleGroanFeatEvent < EventRule
    dsc        "懶惰の呻きの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_idle_groan_feat
    goal       ["self", :use_end?]
  end

  class UseIdleGroanFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_idle_groan_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishTurnIdleGroanFeatEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_idle_groan_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 汚濁の囁き

  class CheckAddContaminationSorrowFeatEvent < EventRule
    dsc        "汚濁の囁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_contamination_sorrow_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveContaminationSorrowFeatEvent < EventRule
    dsc        "汚濁の囁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_contamination_sorrow_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateContaminationSorrowFeatEvent < EventRule
    dsc        "汚濁の囁きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_contamination_sorrow_feat
    goal       ["self", :use_end?]
  end

  class FinishContaminationSorrowFeatEvent < EventRule
    dsc        "汚濁の囁きを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_contamination_sorrow_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 蹉跌の犇めき


  class CheckAddFailureGroanFeatEvent < EventRule
    dsc        "蹉跌の犇めきが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_failure_groan_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFailureGroanFeatEvent < EventRule
    dsc        "蹉跌の犇めきが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_failure_groan_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFailureGroanFeatEvent < EventRule
    dsc        "蹉跌の犇めきが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_failure_groan_feat
    goal       ["self", :use_end?]
  end

  class UseFailureGroanFeatEvent < EventRule
    dsc        "蹉跌の犇めきを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_failure_groan_feat
    goal       ["self", :use_end?]
  end

  class FinishFailureGroanFeatEvent < EventRule
    dsc        "蹉跌の犇めきの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_failure_groan_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 大聖堂


  class CheckAddCathedralFeatEvent < EventRule
    dsc        "大聖堂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_cathedral_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCathedralFeatEvent < EventRule
    dsc        "大聖堂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_cathedral_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCathedralFeatEvent < EventRule
    dsc        "大聖堂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_cathedral_feat
    goal       ["self", :use_end?]
  end

  class UseCathedralFeatEvent < EventRule
    dsc        "大聖堂を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_cathedral_feat
    goal       ["self", :use_end?]
  end

  class FinishCathedralFeatEvent < EventRule
    dsc        "大聖堂の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>10
    func       :finish_cathedral_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 冬の夢

  class CheckAddWinterDreamFeatEvent < EventRule
    dsc        "冬の夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_winter_dream_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWinterDreamFeatEvent < EventRule
    dsc        "冬の夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_winter_dream_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWinterDreamFeatEvent < EventRule
    dsc        "冬の夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_winter_dream_feat
    goal       ["self", :use_end?]
  end

  class UseWinterDreamFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_winter_dream_feat
    goal       ["self", :use_end?]
  end

  class FinishWinterDreamFeatEvent < EventRule
    dsc        "冬の夢の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_winter_dream_feat
    goal       ["self", :use_end?]
  end

  class UseWinterDreamFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_winter_dream_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 夜はやさし

  class CheckAddTenderNightFeatEvent < EventRule
    dsc        "夜はやさしが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_tender_night_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTenderNightFeatEvent < EventRule
    dsc        "夜はやさしが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_tender_night_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTenderNightFeatEvent < EventRule
    dsc        "夜はやさしが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_tender_night_feat
    goal       ["self", :use_end?]
  end

  class FinishTenderNightFeatEvent < EventRule
    dsc        "夜はやさしを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_tender_night_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# しあわせの理由

  class CheckAddFortunateReasonFeatEvent < EventRule
    dsc        "しあわせの理由が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_fortunate_reason_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFortunateReasonFeatEvent < EventRule
    dsc        "しあわせの理由が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_fortunate_reason_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFortunateReasonFeatEvent < EventRule
    dsc        "しあわせの理由が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_fortunate_reason_feat
    goal       ["self", :use_end?]
  end

  class FinishFortunateReasonFeatEvent < EventRule
    dsc        "しあわせの理由を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_fortunate_reason_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# RudNum

  class CheckAddRudNumFeatEvent < EventRule
    dsc        "RudNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rud_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRudNumFeatEvent < EventRule
    dsc        "RudNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rud_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRudNumFeatEvent < EventRule
    dsc        "RudNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rud_num_feat
    goal       ["self", :use_end?]
  end

  class UseRudNumFeatEvent < EventRule
    dsc        "RudNumをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rud_num_feat
    goal       ["self", :use_end?]
  end

  class FinishRudNumFeatEvent < EventRule
    dsc        "RudNumの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rud_num_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# von541

  class CheckAddVonNumFeatEvent < EventRule
    dsc        "von541が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_von_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveVonNumFeatEvent < EventRule
    dsc        "von541が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_von_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateVonNumFeatEvent < EventRule
    dsc        "von541が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_von_num_feat
    goal       ["self", :use_end?]
  end

  class UseVonNumFeatEvent < EventRule
    dsc        "von541を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_von_num_feat
    goal       ["self", :use_end?]
  end

  class UseVonNumFeatDamageEvent < EventRule
    dsc        "von541使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_von_num_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishVonNumFeatEvent < EventRule
    dsc        "von541の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_von_num_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ChrNum

  class CheckAddChrNumFeatEvent < EventRule
    dsc        "ChrNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_chr_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveChrNumFeatEvent < EventRule
    dsc        "ChrNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_chr_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateChrNumFeatEvent < EventRule
    dsc        "ChrNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_chr_num_feat
    goal       ["self", :use_end?]
  end

  class UseChrNumFeatEvent < EventRule
    dsc        "ChrNumをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_chr_num_feat
    goal       ["self", :use_end?]
  end

  class FinishChrNumFeatEvent < EventRule
    dsc        "ChrNumの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_chr_num_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# WilNum


  class CheckAddWilNumFeatEvent < EventRule
    dsc        "WilNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action, :priority=>1
    func       :check_wil_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWilNumFeatEvent < EventRule
    dsc        "WilNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action, :priority=>1
    func       :check_wil_num_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWilNumFeatEvent < EventRule
    dsc        "WilNumが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action, :priority=>1
    func       :check_wil_num_feat
    goal       ["self", :use_end?]
  end

  class UseWilNumFeatEvent < EventRule
    dsc        "WilNumを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_wil_num_feat
    goal       ["self", :use_end?]
  end

  class FinishWilNumFeatEvent < EventRule
    dsc        "WilNumの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_wil_num_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クトネシリカ(フォイルニスゼーレ)

  class CheckAddKutunesirkaFeatEvent < EventRule
    dsc        "クトネシリカが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_kutunesirka_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKutunesirkaFeatEvent < EventRule
    dsc        "クトネシリカが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_kutunesirka_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKutunesirkaFeatEvent < EventRule
    dsc        "クトネシリカが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_kutunesirka_feat
    goal       ["self", :use_end?]
  end

  class UseKutunesirkaFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_kutunesirka_feat
    goal       ["self", :use_end?]
  end

  class FinishKutunesirkaFeatEvent < EventRule
    dsc        "クトネシリカの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase
    func       :finish_kutunesirka_feat
    goal       ["self", :use_end?]
  end

  class UseKutunesirkaFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_kutunesirka_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヘルメスの靴(ドゥンケルハイト)

  class CheckAddFeetOfHermesFeatEvent < EventRule
    dsc        "ヘルメスの靴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_feet_of_hermes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFeetOfHermesFeatEvent < EventRule
    dsc        "ヘルメスの靴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_feet_of_hermes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFeetOfHermesFeatEvent < EventRule
    dsc        "ヘルメスの靴が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_feet_of_hermes_feat
    goal       ["self", :use_end?]
  end

  class UseFeetOfHermesFeatEvent < EventRule
    dsc        "ヘルメスの靴を使用 DEF+5 近距離に移動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_feet_of_hermes_feat
    goal       ["self", :use_end?]
  end

  class UseFeetOfHermesFeatDamageEvent < EventRule
    dsc        "ヘルメスの靴を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>10
    func       :use_feet_of_hermes_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# イージスの翼(シャッテンフリューゲル)

  class CheckAddAegisWingFeatEvent < EventRule
    dsc        "イージスの翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action, :priority=>1
    func       :check_aegis_wing_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAegisWingFeatEvent < EventRule
    dsc        "イージスの翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action, :priority=>1
    func       :check_aegis_wing_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAegisWingFeatEvent < EventRule
    dsc        "イージスの翼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action, :priority=>1
    func       :check_aegis_wing_feat
    goal       ["self", :use_end?]
  end

  class UseAegisWingFeatEvent < EventRule
    dsc        "イージスの翼を使用 DEF+5 遠距離に移動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>1
    func       :use_aegis_wing_feat
    goal       ["self", :use_end?]
  end

  class FinishAegisWingFeatEvent < EventRule
    dsc        "イージスの翼の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_aegis_wing_feat
    goal       ["self", :use_end?]
  end

  class UseAegisWingFeatDamageEvent < EventRule
    dsc        "イージスの翼で防御成功した場合HP+1"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>1
    func       :use_aegis_wing_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クラウ・ソラス(ヴィルベルリッテル)

  class CheckAddClaiomhSolaisFeatEvent < EventRule
    dsc        "クラウ・ソラスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_claiomh_solais_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveClaiomhSolaisFeatEvent < EventRule
    dsc        "クラウ・ソラスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_claiomh_solais_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateClaiomhSolaisFeatEvent < EventRule
    dsc        "クラウ・ソラスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_claiomh_solais_feat
    goal       ["self", :use_end?]
  end

  class UseClaiomhSolaisFeatEvent < EventRule
    dsc        "クラウ・ソラスを使用 攻撃力が+8、場に出した剣カードの枚数ｘ３を攻撃力に加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_claiomh_solais_feat
    goal       ["self", :use_end?]
  end

  class FinishClaiomhSolaisFeatEvent < EventRule
    dsc        "クラウ・ソラスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_claiomh_solais_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 細胞変異

  class CheckAddMutationFeatEvent < EventRule
    dsc        "細胞変異が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_mutation_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMutationFeatEvent < EventRule
    dsc        "細胞変異が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_mutation_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMutationFeatEvent < EventRule
    dsc        "細胞変異が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_mutation_feat
    goal       ["self", :use_end?]
  end

  class UseMutationFeatEvent < EventRule
    dsc        "細胞変異を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_mutation_feat
    goal       ["self", :use_end?]
  end

  class FinishMutationFeatEvent < EventRule
    dsc        "細胞変異を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>11
    func       :finish_mutation_feat
    goal       ["self", :use_end?]
  end

  class FinishEffectMutationFeatEvent < EventRule
    dsc        "細胞変異を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_effect_mutation_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 指嗾する仔

  class CheckAddRampancyFeatEvent < EventRule
    dsc        "指嗾する仔"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_rampancy_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRampancyFeatEvent < EventRule
    dsc        "指嗾する仔"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_rampancy_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRampancyFeatEvent < EventRule
    dsc        "指嗾する仔"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_rampancy_feat
    goal       ["self", :use_end?]
  end

  class UseRampancyFeatDamageEvent < EventRule
    dsc        "指嗾する仔"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_rampancy_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRampancyFeatEvent < EventRule
    dsc        "指嗾する仔使用時にダメージとして相手に与える"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>30
    func       :finish_rampancy_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 魂魄の贄

  class CheckAddSacrificeOfSoulFeatEvent < EventRule
    dsc        "魂魄の贄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_sacrifice_of_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSacrificeOfSoulFeatEvent < EventRule
    dsc        "魂魄の贄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_sacrifice_of_soul_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSacrificeOfSoulFeatEvent < EventRule
    dsc        "魂魄の贄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_sacrifice_of_soul_feat
    goal       ["self", :use_end?]
  end

  class UseSacrificeOfSoulFeatEvent < EventRule
    dsc        "魂魄の贄を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_sacrifice_of_soul_feat
    goal       ["self", :use_end?]
  end

  class UseSacrificeOfSoulFeatHealEvent < EventRule
    dsc        "魂魄の贄ダメージイベント"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_sacrifice_of_soul_feat_heal
    goal       ["self", :use_end?]
  end

  class UseSacrificeOfSoulFeatDamageEvent < EventRule
    dsc        "魂魄の贄ダメージイベント"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>35
    func       :use_sacrifice_of_soul_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 銀の弾丸(哀切の残光)

  class CheckAddSilverBulletFeatEvent < EventRule
    dsc        "銀の弾丸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_silver_bullet_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSilverBulletFeatEvent < EventRule
    dsc        "銀の弾丸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_silver_bullet_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSilverBulletFeatEvent < EventRule
    dsc        "銀の弾丸が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_silver_bullet_feat
    goal       ["self", :use_end?]
  end

  class FinishSilverBulletFeatEvent < EventRule
    dsc        "銀の弾丸の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_silver_bullet_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# かぼちゃ落とし

  class CheckAddPumpkinDropFeatEvent < EventRule
    dsc        "かぼちゃ落としが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_pumpkin_drop_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePumpkinDropFeatEvent < EventRule
    dsc        "かぼちゃ落としが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_pumpkin_drop_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePumpkinDropFeatEvent < EventRule
    dsc        "かぼちゃ落としが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_pumpkin_drop_feat
    goal       ["self", :use_end?]
  end

  class UsePumpkinDropFeatEvent < EventRule
    dsc        "かぼちゃ落としを使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_pumpkin_drop_feat
    goal       ["self", :use_end?]
  end

  class UsePumpkinDropFeatDamageEvent < EventRule
    dsc        "かぼちゃ落としを使用時 追加ダメージ"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_pumpkin_drop_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPumpkinDropFeatEvent < EventRule
    dsc        "かぼちゃ落としの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_pumpkin_drop_feat
    goal       ["self", :use_end?]
  end

  class UsePumpkinDropFeatConstDamageEvent < EventRule
    dsc        "かぼちゃ落としを使用時 追加ダメージ"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_pumpkin_drop_feat_const_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 彷徨う羽

  class CheckAddWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_wandering_feather_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_wandering_feather_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_wandering_feather_feat
    goal       ["self", :use_end?]
  end

  class UseWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽を使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_wandering_feather_feat
    goal       ["self", :use_end?]
  end

  class FinishWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽の使用が終了 攻撃失敗時にデバフ"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :finish_wandering_feather_feat
    goal       ["self", :use_end?]
  end

  class CutinWanderingFeatherFeatEvent < EventRule
    dsc        "彷徨う羽の使用が終了 攻撃失敗時にデバフ"
    type       :type=>:before, :obj=>"owner", :hook=>:dice_attribute_regist_event
    func       :cutin_wandering_feather_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ひつじ数え歌

  class CheckAddSheepSongFeatEvent < EventRule
    dsc        "ひつじ数え歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_sheep_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSheepSongFeatEvent < EventRule
    dsc        "ひつじ数え歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_sheep_song_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSheepSongFeatEvent < EventRule
    dsc        "ひつじ数え歌が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_sheep_song_feat
    goal       ["self", :use_end?]
  end

  class UseSheepSongFeatEvent < EventRule
    dsc        "ひつじ数え歌を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_sheep_song_feat
    goal       ["self", :use_end?]
  end

  class FinishSheepSongFeatEvent < EventRule
    dsc        "ひつじ数え歌の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>10
    func       :finish_sheep_song_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# オヴェリャの夢

  class CheckAddDreamOfOvueryaFeatEvent < EventRule
    dsc        "オヴェリャの夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_dream_of_ovuerya_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDreamOfOvueryaFeatEvent < EventRule
    dsc        "オヴェリャの夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_dream_of_ovuerya_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDreamOfOvueryaFeatEvent < EventRule
    dsc        "オヴェリャの夢が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_dream_of_ovuerya_feat
    goal       ["self", :use_end?]
  end

  class FinishDreamOfOvueryaFeatEvent < EventRule
    dsc        "オヴェリャの夢を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_dream_of_ovuerya_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# メリーズシープ

  class CheckAddMarysSheepFeatEvent < EventRule
    dsc        "メリーズシープが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_marys_sheep_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMarysSheepFeatEvent < EventRule
    dsc        "メリーズシープが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_marys_sheep_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMarysSheepFeatEvent < EventRule
    dsc        "メリーズシープが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_marys_sheep_feat
    goal       ["self", :use_end?]
  end

  class UseMarysSheepFeatEvent < EventRule
    dsc        "メリーズシープを使用 攻撃力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_marys_sheep_feat
    goal       ["self", :use_end?]
  end

  class UseMarysSheepFeatDamageEvent < EventRule
    dsc        "メリーズシープを使用時 追加ダメージ"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_marys_sheep_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishMarysSheepFeatEvent < EventRule
    dsc        "メリーズシープの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_marys_sheep_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 光り輝く邪眼

  class CheckAddEvilEyeFeatEvent < EventRule
    dsc        "光り輝く邪眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_evil_eye_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEvilEyeFeatEvent < EventRule
    dsc        "光り輝く邪眼壊が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_evil_eye_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEvilEyeFeatEvent < EventRule
    dsc        "光り輝く邪眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_evil_eye_feat
    goal       ["self", :use_end?]
  end

  class UseEvilEyeFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_evil_eye_feat
    goal       ["self", :use_end?]
  end

  class FinishEvilEyeFeatEvent < EventRule
    dsc        "光り輝く邪眼の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>0
    func       :finish_evil_eye_feat
    goal       ["self", :use_end?]
  end

  class UseEvilEyeFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>0
    func       :use_evil_eye_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 超越者の邪法を使用

  class CheckAddBlackArtsFeatEvent < EventRule
    dsc        "超越者の邪法を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_black_arts_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlackArtsFeatEvent < EventRule
    dsc        "超越者の邪法を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_black_arts_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlackArtsFeatEvent < EventRule
    dsc        "超越者の邪法を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_black_arts_feat
    goal       ["self", :use_end?]
  end

  class FinishBlackArtsFeatEvent < EventRule
    dsc        "超越者の邪法を使用を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :finish_black_arts_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 冒涜する呪詛

  class CheckAddBlasphemyCurseFeatEvent < EventRule
    dsc        "冒涜する呪詛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blasphemy_curse_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlasphemyCurseFeatEvent < EventRule
    dsc        "冒涜する呪詛壊が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blasphemy_curse_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlasphemyCurseFeatEvent < EventRule
    dsc        "冒涜する呪詛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blasphemy_curse_feat
    goal       ["self", :use_end?]
  end

  class UseBlasphemyCurseFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blasphemy_curse_feat
    goal       ["self", :use_end?]
  end

  class FinishBlasphemyCurseFeatEvent < EventRule
    dsc        "冒涜する呪詛の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>2
    func       :finish_blasphemy_curse_feat
    goal       ["self", :use_end?]
  end

  class UseBlasphemyCurseFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>2
    func       :use_blasphemy_curse_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 終焉の果て

  class CheckAddEndOfEndFeatEvent < EventRule
    dsc        "終焉の果てが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_end_of_end_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEndOfEndFeatEvent < EventRule
    dsc        "終焉の果て壊が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_end_of_end_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEndOfEndFeatEvent < EventRule
    dsc        "終焉の果てが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_end_of_end_feat
    goal       ["self", :use_end?]
  end

  class UseEndOfEndFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_end_of_end_feat
    goal       ["self", :use_end?]
  end

  class FinishEndOfEndFeatEvent < EventRule
    dsc        "終焉の果ての使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_end_of_end_feat
    goal       ["self", :use_end?]
  end

  class UseEndOfEndFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>1
    func       :use_end_of_end_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 玉座の凱旋門

  class CheckAddThronesGateFeatEvent < EventRule
    dsc        "玉座の凱旋門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_thrones_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThronesGateFeatEvent < EventRule
    dsc        "玉座の凱旋門壊が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_thrones_gate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThronesGateFeatEvent < EventRule
    dsc        "玉座の凱旋門が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_thrones_gate_feat
    goal       ["self", :use_end?]
  end

  class UseThronesGateFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_thrones_gate_feat
    goal       ["self", :use_end?]
  end

  class FinishThronesGateFeatEvent < EventRule
    dsc        "玉座の凱旋門の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_thrones_gate_feat
    goal       ["self", :use_end?]
  end

  class UseThronesGateFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>1
    func       :use_thrones_gate_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 幽愁暗恨

  class CheckAddGhostResentmentFeatEvent < EventRule
    dsc        "幽愁暗恨が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ghost_resentment_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGhostResentmentFeatEvent < EventRule
    dsc        "幽愁暗恨壊が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ghost_resentment_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGhostResentmentFeatEvent < EventRule
    dsc        "幽愁暗恨が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ghost_resentment_feat
    goal       ["self", :use_end?]
  end

  class UseGhostResentmentFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ghost_resentment_feat
    goal       ["self", :use_end?]
  end

  class FinishGhostResentmentFeatEvent < EventRule
    dsc        "幽愁暗恨の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_ghost_resentment_feat
    goal       ["self", :use_end?]
  end

  class UseGhostResentmentFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_ghost_resentment_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 受け流し

  class CheckAddSwordAvoidFeatEvent < EventRule
    dsc        "受け流しが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_sword_avoid_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSwordAvoidFeatEvent < EventRule
    dsc        "受け流しが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_sword_avoid_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSwordAvoidFeatEvent < EventRule
    dsc        "受け流しが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_sword_avoid_feat
    goal       ["self", :use_end?]
  end

  class UseSwordAvoidFeatEvent < EventRule
    dsc        "受け流しを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_sword_avoid_feat
    goal       ["self", :use_end?]
  end

  class UseSwordAvoidFeatDamageEvent < EventRule
    dsc        "受け流し使用時にダメージとして相手に与える"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_sword_avoid_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishSwordAvoidFeatEvent < EventRule
    dsc        "受け流しの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_sword_avoid_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Ex呪剣

  class CheckAddCurseSwordFeatEvent < EventRule
    dsc        "Ex呪剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_curse_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCurseSwordFeatEvent < EventRule
    dsc        "Ex呪剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_curse_sword_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCurseSwordFeatEvent < EventRule
    dsc        "Ex呪剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_curse_sword_feat
    goal       ["self", :use_end?]
  end

  class UseCurseSwordFeatEvent < EventRule
    dsc        "Ex呪剣を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_curse_sword_feat
    goal       ["self", :use_end?]
  end

  class FinishCurseSwordFeatEvent < EventRule
    dsc        "Ex呪剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_curse_sword_feat
    goal       ["self", :use_end?]
  end

  class UseCurseSwordFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_curse_sword_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 神速の剣(復活)

  class CheckAddRapidSwordR2FeatEvent < EventRule
    dsc        "神速の剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rapid_sword_r2_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRapidSwordR2FeatEvent < EventRule
    dsc        "神速の剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rapid_sword_r2_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRapidSwordR2FeatEvent < EventRule
    dsc        "神速の剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rapid_sword_r2_feat
    goal       ["self", :use_end?]
  end

  class UseRapidSwordR2FeatEvent < EventRule
    dsc        "神速の剣(復活)を使用 剣を攻撃力に加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rapid_sword_r2_feat
    goal       ["self", :use_end?]
  end

  class FinishRapidSwordR2FeatEvent < EventRule
    dsc        "神速の剣(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rapid_sword_r2_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヴォリションディフレクト

  class CheckAddVolitionDeflectFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_volition_deflect_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveVolitionDeflectFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_volition_deflect_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateVolitionDeflectFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_volition_deflect_feat
    goal       ["self", :use_end?]
  end

  class UseVolitionDeflectFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_volition_deflect_feat
    goal       ["self", :use_end?]
  end

  class FinishVolitionDeflectFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :finish_volition_deflect_feat
    goal       ["self", :use_end?]
  end

  class FinishVolitionDeflectFeatDeadCharaChangeEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_volition_deflect_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 怒りの一撃(復活)

  class CheckAddAngerRFeatEvent < EventRule
    dsc        "怒りの一撃(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_anger_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAngerRFeatEvent < EventRule
    dsc        "怒りの一撃(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_anger_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAngerRFeatEvent < EventRule
    dsc        "怒りの一撃(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_anger_r_feat
    goal       ["self", :use_end?]
  end

  class UseAngerRFeatEvent < EventRule
    dsc        "怒りの一撃(復活)を使用 攻撃力にダメージを加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_anger_r_feat
    goal       ["self", :use_end?]
  end

  class FinishAngerRFeatEvent < EventRule
    dsc        "怒りの一撃(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_anger_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 影撃ち(復活)

  class CheckAddShadowShotRFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_shadow_shot_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShadowShotRFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_shadow_shot_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShadowShotRFeatEvent < EventRule
    dsc        "影撃ちが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_shadow_shot_r_feat
    goal       ["self", :use_end?]
  end

  class UseShadowShotRFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_shadow_shot_r_feat
    goal       ["self", :use_end?]
  end

  class FinishShadowShotRFeatEvent < EventRule
    dsc        "影撃ちの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shadow_shot_r_feat
    goal       ["self", :use_end?]
  end

  class UseShadowShotRFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_shadow_shot_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 嚇灼の尾

  class CheckAddBurningTailFeatEvent < EventRule
    dsc        "嚇灼の尾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_burning_tail_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBurningTailFeatEvent < EventRule
    dsc        "嚇灼の尾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_burning_tail_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBurningTailFeatEvent < EventRule
    dsc        "嚇灼の尾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_burning_tail_feat
    goal       ["self", :use_end?]
  end

  class UseBurningTailFeatEvent < EventRule
    dsc        "嚇灼の尾を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_burning_tail_feat
    goal       ["self", :use_end?]
  end

  class FinishBurningTailFeatEvent < EventRule
    dsc        "嚇灼の尾を使用 相手のカードを回転させる"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_burning_tail_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 震歩を使用

  class CheckAddQuakeWalkFeatEvent < EventRule
    dsc        "震歩を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_quake_walk_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveQuakeWalkFeatEvent < EventRule
    dsc        "震歩を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_quake_walk_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateQuakeWalkFeatEvent < EventRule
    dsc        "震歩を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_quake_walk_feat
    goal       ["self", :use_end?]
  end

  class FinishQuakeWalkFeatEvent < EventRule
    dsc        "震歩を使用を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>0
    func       :finish_quake_walk_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ドレナージ

  class CheckAddDrainageFeatEvent < EventRule
    dsc        "ドレナージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_drainage_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDrainageFeatEvent < EventRule
    dsc        "ドレナージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_drainage_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDrainageFeatEvent < EventRule
    dsc        "ドレナージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_drainage_feat
    goal       ["self", :use_end?]
  end

  class UseDrainageFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_drainage_feat
    goal       ["self", :use_end?]
  end

  class FinishDrainageFeatEvent < EventRule
    dsc        "ドレナージの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_drainage_feat
    goal       ["self", :use_end?]
  end

  class UseDrainageFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :use_drainage_feat_damage
    goal       ["self", :use_end?]
  end

  class UseDrainageFeatConstDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>0
    func       :use_drainage_feat_const_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# やさしい微笑み

  class CheckAddSmileFeatEvent < EventRule
    dsc        "やさしい微笑みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_smile_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSmileFeatEvent < EventRule
    dsc        "やさしい微笑みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_smile_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSmileFeatEvent < EventRule
    dsc        "やさしい微笑みが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_smile_feat
    goal       ["self", :use_end?]
  end

  class UseSmileFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_smile_feat
    goal       ["self", :use_end?]
  end

  class FinishSmileFeatEvent < EventRule
    dsc        "やさしい微笑みの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :finish_smile_feat
    goal       ["self", :use_end?]
  end

  class UseSmileFeatDamageEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_smile_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 血統汚染(レイド用) blutkontamina

  class CheckAddBlutkontaminaFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blutkontamina_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlutkontaminaFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blutkontamina_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlutkontaminaFeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blutkontamina_feat
    goal       ["self", :use_end?]
  end

  class UseBlutkontaminaFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blutkontamina_feat
    goal       ["self", :use_end?]
  end

  class FinishBlutkontaminaFeatEvent < EventRule
    dsc        "自壊攻撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blutkontamina_feat
    goal       ["self", :use_end?]
  end

  class UseBlutkontaminaFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_blutkontamina_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# つめたい視線

  class CheckAddColdEyesFeatEvent < EventRule
    dsc        "つめたい視線が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_cold_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveColdEyesFeatEvent < EventRule
    dsc        "つめたい視線が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_cold_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateColdEyesFeatEvent < EventRule
    dsc        "つめたい視線が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_cold_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseColdEyesFeatDamageEvent < EventRule
    dsc        "つめたい視線を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_cold_eyes_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishColdEyesFeatEvent < EventRule
    dsc        "つめたい視線の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_cold_eyes_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Faet1

  class CheckAddFeat1FeatEvent < EventRule
    dsc        "Feat1が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_feat1_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFeat1FeatEvent < EventRule
    dsc        "Feat1が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_feat1_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFeat1FeatEvent < EventRule
    dsc        "Feat1が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_feat1_feat
    goal       ["self", :use_end?]
  end

  class UseFeat1FeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_feat1_feat
    goal       ["self", :use_end?]
  end

  class FinishFeat1FeatEvent < EventRule
    dsc        "Feat1の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_feat1_feat
    goal       ["self", :use_end?]
  end

  class UseFeat1FeatDamageEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_feat1_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# feat2

  class CheckAddFeat2FeatEvent < EventRule
    dsc        "feat2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_feat2_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFeat2FeatEvent < EventRule
    dsc        "feat2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_feat2_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFeat2FeatEvent < EventRule
    dsc        "feat2が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_feat2_feat
    goal       ["self", :use_end?]
  end

  class UseFeat2FeatEvent < EventRule
    dsc        "feat2を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_feat2_feat
    goal       ["self", :use_end?]
  end

  class FinishFeat2FeatEvent < EventRule
    dsc        "feat2の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>99
    func       :finish_feat2_feat
    goal       ["self", :use_end?]
  end

  class UseFeat2FeatDamageEvent < EventRule
    dsc        "feat2の防御成功時"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_feat2_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Faet3

  class CheckAddFeat3FeatEvent < EventRule
    dsc        "Feat3が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_feat3_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFeat3FeatEvent < EventRule
    dsc        "Feat3が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_feat3_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFeat3FeatEvent < EventRule
    dsc        "Feat3が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_feat3_feat
    goal       ["self", :use_end?]
  end

  class UseFeat3FeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_feat3_feat
    goal       ["self", :use_end?]
  end

  class FinishFeat3FeatEvent < EventRule
    dsc        "Feat3の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_feat3_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Faet4

  class CheckAddFeat4FeatEvent < EventRule
    dsc        "Feat4が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_feat4_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFeat4FeatEvent < EventRule
    dsc        "Feat4が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_feat4_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFeat4FeatEvent < EventRule
    dsc        "Feat4が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_feat4_feat
    goal       ["self", :use_end?]
  end

  class CheckBpFeat4AttackFeatEvent < EventRule
    dsc        "Feat4が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>30
    func       :check_bp_feat4_feat
    goal       ["self", :use_end?]
  end

  class CheckBpFeat4DefenceFeatEvent < EventRule
    dsc        "Feat4が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>30
    func       :check_bp_feat4_feat
    goal       ["self", :use_end?]
  end

  class UseFeat4FeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>30
    func       :use_feat4_feat
    goal       ["self", :use_end?]
  end

  class FinishChangeFeat4FeatEvent < EventRule
    dsc        "feat4を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :finish_change_feat4_feat
    goal       ["self", :use_end?]
  end

  class FinishFeat4FeatEvent < EventRule
    dsc        "Feat4の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_feat4_feat
    goal       ["self", :use_end?]
  end

  class StartFeat4FeatEvent < EventRule
    dsc        "Feat4の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:start_turn_phase
    func       :start_feat4_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 見えざる白群の鼬

  class CheckAddWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_weasel_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_weasel_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_weasel_feat
    goal       ["self", :use_end?]
  end

  class CheckTableWeaselFeatMoveEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :check_table_weasel_feat_move
    goal       ["self", :use_end?]
  end

  class CheckTableWeaselFeatBattleEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :check_table_weasel_feat_battle
    goal       ["self", :use_end?]
  end

  class UseWeaselFeatDealEvent < EventRule
    dsc        "見えざる白群の鼬を使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :use_weasel_feat_deal
    goal       ["self", :use_end?]
  end

  class UseWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬を使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_weasel_feat
    goal       ["self", :use_end?]
  end


  class UseWeaselFeatDamageEvent < EventRule
    dsc        "見えざる白群の鼬を使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_weasel_feat_damage
    goal       ["self", :use_end?]
  end


  class FinishWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_weasel_feat
    goal       ["self", :use_end?]
  end

  class CheckEndingWeaselFeatEvent < EventRule
    dsc        "見えざる白群の鼬が可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :check_ending_weasel_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 暗黒の渦(復活)

  class CheckAddDarkProfoundFeatEvent < EventRule
    dsc        "DarkProfoundが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dark_profound_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDarkProfoundFeatEvent < EventRule
    dsc        "DarkProfoundが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dark_profound_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDarkProfoundFeatEvent < EventRule
    dsc        "DarkProfoundが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dark_profound_feat
    goal       ["self", :use_end?]
  end

  class UseDarkProfoundFeatEvent < EventRule
    dsc        "DarkProfoundをを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dark_profound_feat
    goal       ["self", :use_end?]
  end

  class UseDarkProfoundFeatBornusEvent < EventRule
    dsc        "暗黒の渦を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>20
    func       :use_dark_profound_feat_bornus
    goal       ["self", :use_end?]
  end

  class FinishDarkProfoundFeatEvent < EventRule
    dsc        "DarkProfoundの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>30
    func       :finish_dark_profound_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 因果の扉

  class CheckAddKarmicDorFeatEvent < EventRule
    dsc        "因果の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKarmicDorFeatEvent < EventRule
    dsc        "因果の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKarmicDorFeatEvent < EventRule
    dsc        "因果の扉が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class CheckPointKarmicDorFeatEvent < EventRule
    dsc        "因果の扉が可能か 特殊ポイントを調べる"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :check_point_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class UseKarmicDorFeatEvent < EventRule
    dsc        "因果の扉を使用 カード回転"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class FinishKarmicDorFeatEvent < EventRule
    dsc        "因果の扉を使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeKarmicDorFeatEvent < EventRule
    dsc        "因果の扉の使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_karmic_dor_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeCharaChangeKarmicDorFeatEvent < EventRule
    dsc        "因果の扉の使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_karmic_dor_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# batafly_mov

  class CheckAddBataflyMovFeatEvent < EventRule
    dsc        "batafly_movが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_batafly_mov_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBataflyMovFeatEvent < EventRule
    dsc        "batafly_movが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_batafly_mov_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBataflyMovFeatEvent < EventRule
    dsc        "batafly_movが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_batafly_mov_feat
    goal       ["self", :use_end?]
  end

  class DetermineDistanceBataflyMovFeatEvent < EventRule
    dsc        "batafly_movを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>99
    func       :determine_distance_batafly_mov_feat
    goal       ["self", :use_end?]
  end

  class FinishBataflyMovFeatEvent < EventRule
    dsc        "batafly_movを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase, :priority=>99
    func       :finish_batafly_mov_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# batafly_atk

  class CheckAddBataflyAtkFeatEvent < EventRule
    dsc        "batafly_atkが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_batafly_atk_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBataflyAtkFeatEvent < EventRule
    dsc        "batafly_atkが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_batafly_atk_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBataflyAtkFeatEvent < EventRule
    dsc        "batafly_atkが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_batafly_atk_feat
    goal       ["self", :use_end?]
  end

  class UseBataflyAtkFeatEvent < EventRule
    dsc        "batafly_atkを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_batafly_atk_feat
    goal       ["self", :use_end?]
  end

  class FinishBataflyAtkFeatEvent < EventRule
    dsc        "batafly_atkの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_batafly_atk_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# batafly_def

  class CheckAddBataflyDefFeatEvent < EventRule
    dsc        "batafly_defが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_batafly_def_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBataflyDefFeatEvent < EventRule
    dsc        "batafly_defが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_batafly_def_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBataflyDefFeatEvent < EventRule
    dsc        "batafly_defが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_batafly_def_feat
    goal       ["self", :use_end?]
  end

  class UseBataflyDefFeatEvent < EventRule
    dsc        "batafly_defを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_batafly_def_feat
    goal       ["self", :use_end?]
  end

  class FinishBataflyDefFeatEvent < EventRule
    dsc        "batafly_defの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_batafly_def_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# batafly_sld

  class CheckAddBataflySldFeatEvent < EventRule
    dsc        "batafly_sldが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_batafly_sld_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBataflySldFeatEvent < EventRule
    dsc        "batafly_sldが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_batafly_sld_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBataflySldFeatEvent < EventRule
    dsc        "batafly_sldが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_batafly_sld_feat
    goal       ["self", :use_end?]
  end

  class UseBataflySldFeatEvent < EventRule
    dsc        "batafly_sldを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_batafly_sld_feat
    goal       ["self", :use_end?]
  end

  class FinishBataflySldFeatEvent < EventRule
    dsc        "batafly_sldの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_batafly_sld_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# グレイスカクテル

  class CheckAddGraceCocktailFeatEvent < EventRule
    dsc        "グレースカクテルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_grace_cocktail_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGraceCocktailFeatEvent < EventRule
    dsc        "グレースカクテルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_grace_cocktail_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGraceCocktailFeatEvent < EventRule
    dsc        "グレースカクテルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_grace_cocktail_feat
    goal       ["self", :use_end?]
  end

  class UseGraceCocktailFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_grace_cocktail_feat
    goal       ["self", :use_end?]
  end

  class FinishGraceCocktailFeatEvent < EventRule
    dsc        "グレースカクテルの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_grace_cocktail_feat
    goal       ["self", :use_end?]
  end

  class UseGraceCocktailFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_grace_cocktail_feat_damage
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# ランドマイン(復活)

  class CheckAddLandMineRFeatEvent < EventRule
    dsc        "ランドマイン(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_land_mine_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLandMineRFeatEvent < EventRule
    dsc        "ランドマイン(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_land_mine_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLandMineRFeatEvent < EventRule
    dsc        "ランドマイン(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_land_mine_r_feat
    goal       ["self", :use_end?]
  end

  class UseLandMineRFeatEvent < EventRule
    dsc        "ランドマイン(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_land_mine_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ナパーム・デス

  class CheckAddNapalmDeathFeatEvent < EventRule
    dsc        "ナパーム・デスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_napalm_death_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNapalmDeathFeatEvent < EventRule
    dsc        "ナパーム・デスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_napalm_death_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNapalmDeathFeatEvent < EventRule
    dsc        "ナパーム・デスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_napalm_death_feat
    goal       ["self", :use_end?]
  end

  class UseNapalmDeathFeatEvent < EventRule
    dsc        "ナパーム・デスを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_napalm_death_feat
    goal       ["self", :use_end?]
  end

  class FinishNapalmDeathFeatEvent < EventRule
    dsc        "ナパーム・デスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_napalm_death_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スーサイダイルフェイルア

  class CheckAddSuicidalFailureFeatEvent < EventRule
    dsc        "スーサイダルフェイルアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_suicidal_failure_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSuicidalFailureFeatEvent < EventRule
    dsc        "スーサイダルフェイルアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_suicidal_failure_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSuicidalFailureFeatEvent < EventRule
    dsc        "スーサイダルフェイルアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_suicidal_failure_feat
    goal       ["self", :use_end?]
  end

  class UseSuicidalFailureFeatEvent < EventRule
    dsc        "スーサイダルフェイルアを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_suicidal_failure_feat
    goal       ["self", :use_end?]
  end

  class FinishSuicidalFailureFeatEvent < EventRule
    dsc        "スーサイダルフェイルアの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_suicidal_failure_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ビッグブラッグ(復活)

  class CheckAddBigBraggRFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_big_bragg_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBigBraggRFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_big_bragg_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBigBraggRFeatEvent < EventRule
    dsc        "ビッグブラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_big_bragg_r_feat
    goal       ["self", :use_end?]
  end

  class FinishBigBraggRFeatEvent < EventRule
    dsc        "ビッグブラッグを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_big_bragg_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# レッツナイフ(復活)

  class CheckAddLetsKnifeRFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_lets_knife_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLetsKnifeRFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_lets_knife_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLetsKnifeRFeatEvent < EventRule
    dsc        "レッツナイフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_lets_knife_r_feat
    goal       ["self", :use_end?]
  end

  class UseLetsKnifeRFeatEvent < EventRule
    dsc        "レッツナイフを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_lets_knife_r_feat
    goal       ["self", :use_end?]
  end

  class FinishLetsKnifeRFeatEvent < EventRule
    dsc        "レッツナイフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_lets_knife_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 捕食

  class CheckAddPreyFeatEvent < EventRule
    dsc        "捕食が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_prey_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePreyFeatEvent < EventRule
    dsc        "捕食が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_prey_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePreyFeatEvent < EventRule
    dsc        "捕食が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_prey_feat
    goal       ["self", :use_end?]
  end

  class UsePreyFeatEvent < EventRule
    dsc        "捕食の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_prey_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 反芻

  class CheckAddRuminationFeatEvent < EventRule
    dsc        "反芻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_rumination_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRuminationFeatEvent < EventRule
    dsc        "反芻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_rumination_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRuminationFeatEvent < EventRule
    dsc        "反芻が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_rumination_feat
    goal       ["self", :use_end?]
  end

  class UseRuminationFeatEvent < EventRule
    dsc        "反芻の使用が終了"
    type       :type=>:before, :obj=>"owner", :hook=>:move_phase_init_event
    func       :use_rumination_feat
    goal       ["self", :use_end?]
  end

  class FinishRuminationFeatEvent < EventRule
    dsc        "反芻の使用が終了"
    type       :type=>:before, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :finish_rumination_feat
    goal       ["self", :use_end?]
  end

  class FinishRuminationFeatFoeCharaChangeEvent < EventRule
    dsc        "反芻の使用が終了"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_rumination_feat
    goal       ["self", :use_end?]
  end

  class FinishRuminationFeatOwnerCharaChangeEvent < EventRule
    dsc        "反芻の使用が終了"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_rumination_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ピルム

  class CheckAddPilumFeatEvent < EventRule
    dsc        "ピルムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_pilum_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePilumFeatEvent < EventRule
    dsc        "ピルムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_pilum_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePilumFeatEvent < EventRule
    dsc        "ピルムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_pilum_feat
    goal       ["self", :use_end?]
  end

  class UsePilumFeatEvent < EventRule
    dsc        "ピルムを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_pilum_feat
    goal       ["self", :use_end?]
  end

  class FinishPilumFeatEvent < EventRule
    dsc        "ピルムの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_pilum_feat
    goal       ["self", :use_end?]
  end

  class UsePilumFeatDamageEvent < EventRule
    dsc        "ピルムを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_pilum_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 地中の路

  class CheckAddRoadOfUndergroundFeatEvent < EventRule
    dsc        "地中の路が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_road_of_underground_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRoadOfUndergroundFeatEvent < EventRule
    dsc        "地中の路が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_road_of_underground_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRoadOfUndergroundFeatEvent < EventRule
    dsc        "地中の路が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_road_of_underground_feat
    goal       ["self", :use_end?]
  end

  class UseRoadOfUndergroundFeatEvent < EventRule
    dsc        "地中の路を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :use_road_of_underground_feat
    goal       ["self", :use_end?]
  end

  class UseRoadOfUndergroundFeatFinishMoveEvent < EventRule
    dsc        "地中の路を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase, :priority=>50
    func       :use_road_of_underground_feat_finish_move
    goal       ["self", :use_end?]
  end

  class FinishRoadOfUndergroundFeatEvent < EventRule
    dsc        "地中の路の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_road_of_underground_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 狐分身

  class CheckAddFoxShadowFeatEvent < EventRule
    dsc        "狐分身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_fox_shadow_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFoxShadowFeatEvent < EventRule
    dsc        "狐分身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_fox_shadow_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFoxShadowFeatEvent < EventRule
    dsc        "狐分身が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_fox_shadow_feat
    goal       ["self", :use_end?]
  end

  class UseFoxShadowFeatEvent < EventRule
    dsc        "狐分身を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_fox_shadow_feat
    goal       ["self", :use_end?]
  end

  class FinishFoxShadowFeatEvent < EventRule
    dsc        "狐分身の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase
    func       :finish_fox_shadow_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 狐シュート

  class CheckAddFoxShootFeatEvent < EventRule
    dsc        "狐シュートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_fox_shoot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFoxShootFeatEvent < EventRule
    dsc        "狐シュートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_fox_shoot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFoxShootFeatEvent < EventRule
    dsc        "狐シュートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_fox_shoot_feat
    goal       ["self", :use_end?]
  end

  class UseFoxShootFeatEvent < EventRule
    dsc        "狐シュートを使用 攻撃力が+3、場に出した剣カードの枚数ｘ３を攻撃力に加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_fox_shoot_feat
    goal       ["self", :use_end?]
  end

  class FinishFoxShootFeatEvent < EventRule
    dsc        "狐シュートの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_fox_shoot_feat
    goal       ["self", :use_end?]
  end

  class UseFoxShootFeatDamageEvent < EventRule
    dsc        "狐シュートの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_fox_shoot_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 狐空間

  class CheckAddFoxZoneFeatEvent < EventRule
    dsc        "狐空間が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_fox_zone_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFoxZoneFeatEvent < EventRule
    dsc        "狐空間が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_fox_zone_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFoxZoneFeatEvent < EventRule
    dsc        "狐空間が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_fox_zone_feat
    goal       ["self", :use_end?]
  end

  class UseFoxZoneFeatEvent < EventRule
    dsc        "狐空間を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:mp_calc_resolve, :priority=>200
    func       :use_fox_zone_feat
    goal       ["self", :use_end?]
  end

  class UseFoxZoneFeatAttackDealDetCharaChangeEvent < EventRule
    dsc        "狐空間を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :use_fox_zone_feat_attack_deal
    goal       ["self", :use_end?]
  end

  class UseFoxZoneFeatAttackDealChangeInitiativeEvent < EventRule
    dsc        "狐空間を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :use_fox_zone_feat_attack_deal
    goal       ["self", :use_end?]
  end

  class UseFoxZoneFeatDefenseDealEvent < EventRule
    dsc        "狐空間を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:attack_done_action
    func       :use_fox_zone_feat_defense_deal
    goal       ["self", :use_end?]
  end

  class FinishFoxZoneFeatEvent < EventRule
    dsc        "狐空間を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_fox_zone_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 墜下する流星

  class CheckAddArrowRainFeatEvent < EventRule
    dsc        "墜下する流星が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_arrow_rain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveArrowRainFeatEvent < EventRule
    dsc        "墜下する流星が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_arrow_rain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateArrowRainFeatEvent < EventRule
    dsc        "墜下する流星が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_arrow_rain_feat
    goal       ["self", :use_end?]
  end

  class UseArrowRainFeatEvent < EventRule
    dsc        "墜下する流星を使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_arrow_rain_feat
    goal       ["self", :use_end?]
  end

  class FinishArrowRainFeatEvent < EventRule
    dsc        "墜下する流星の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_arrow_rain_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 光輝強迫

  class CheckAddAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_atemwende_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_atemwende_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_atemwende_feat
    goal       ["self", :use_end?]
  end

  class UseAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫をを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_atemwende_feat
    goal       ["self", :use_end?]
  end

  class FinishChangeAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_change_atemwende_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnAtemwendeFeatEvent < EventRule
    dsc        "光輝強迫を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_atemwende_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 雪の重唱

  class CheckAddFadensonnenFeatEvent < EventRule
    dsc        "雪の重唱が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_fadensonnen_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFadensonnenFeatEvent < EventRule
    dsc        "雪の重唱が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_fadensonnen_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFadensonnenFeatEvent < EventRule
    dsc        "雪の重唱が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_fadensonnen_feat
    goal       ["self", :use_end?]
  end

  class UseFadensonnenFeatEvent < EventRule
    dsc        "雪の重唱を使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_fadensonnen_feat
    goal       ["self", :use_end?]
  end

  class FinishFadensonnenFeatEvent < EventRule
    dsc        "雪の重唱の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_fadensonnen_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 紡がれる陽


  class CheckAddLichtzwangFeatEvent < EventRule
    dsc        "紡がれる陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_lichtzwang_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLichtzwangFeatEvent < EventRule
    dsc        "紡がれる陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_lichtzwang_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLichtzwangFeatEvent < EventRule
    dsc        "紡がれる陽が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_lichtzwang_feat
    goal       ["self", :use_end?]
  end

  class UseLichtzwangFeatEvent < EventRule
    dsc        "紡がれる陽を使用 ATK補正"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_lichtzwang_feat
    goal       ["self", :use_end?]
  end

  class FinishLichtzwangFeatEvent < EventRule
    dsc        "紡がれる陽の使用 ランダムに固定ダメージ"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_lichtzwang_feat
    goal       ["self", :use_end?]
  end

  class UseLichtzwangFeatDamageEvent < EventRule
    dsc        "紡がれる陽を終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :use_lichtzwang_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 溜息の転換

  class CheckAddSchneepartFeatEvent < EventRule
    dsc        "溜息の転換が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_schneepart_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSchneepartFeatEvent < EventRule
    dsc        "溜息の転換が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_schneepart_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSchneepartFeatEvent < EventRule
    dsc        "溜息の転換が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_schneepart_feat
    goal       ["self", :use_end?]
  end

  class UseSchneepartFeatEvent < EventRule
    dsc        "溜息の転換を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_schneepart_feat
    goal       ["self", :use_end?]
  end

  class UseSchneepartFeatDamageEvent < EventRule
    dsc        "溜息の転換を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_schneepart_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishSchneepartFeatEvent < EventRule
    dsc        "溜息の転換の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_schneepart_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ハイゲート

  class CheckAddHighgateFeatEvent < EventRule
    dsc        "ハイゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_highgate_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHighgateFeatEvent < EventRule
    dsc        "ハイゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_highgate_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHighgateFeatEvent < EventRule
    dsc        "ハイゲートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_highgate_feat
    goal       ["self", :use_end?]
  end

  class UseHighgateFeatEvent < EventRule
    dsc        "ハイゲートをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_highgate_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ドルフルフト

  class CheckAddDorfloftFeatEvent < EventRule
    dsc        "ドルフルフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dorfloft_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDorfloftFeatEvent < EventRule
    dsc        "ドルフルフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dorfloft_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDorfloftFeatEvent < EventRule
    dsc        "ドルフルフトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dorfloft_feat
    goal       ["self", :use_end?]
  end

  class UseDorfloftFeatEvent < EventRule
    dsc        "ドルフルフトを使用 DEF+5 近距離に移動"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dorfloft_feat
    goal       ["self", :use_end?]
  end

  class UseDorfloftFeatDamageEvent < EventRule
    dsc        "ドルフルフトを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>10
    func       :use_dorfloft_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ルミネセンス

  class CheckAddLuminesFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_lumines_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLuminesFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_lumines_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLuminesFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_lumines_feat
    goal       ["self", :use_end?]
  end

  class UseLuminesFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_lumines_feat
    goal       ["self", :use_end?]
  end

  class FinishLuminesFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_lumines_feat
    goal       ["self", :use_end?]
  end

  class UseLuminesFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_lumines_feat_damage
    goal       ["self", :use_end?]
  end
#---------------------------------------------------------------------------------------------
# スーパーヒロイン(復活)

  class CheckAddSuperHeroineFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_super_heroine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSuperHeroineFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_super_heroine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSuperHeroineFeatEvent < EventRule
    dsc        "スーパーヒロインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_super_heroine_feat
    goal       ["self", :use_end?]
  end

  class FinishSuperHeroineFeatEvent < EventRule
    dsc        "スーパーヒロインを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_super_heroine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# T・スタンピード

  class CheckAddStampedeFeatEvent < EventRule
    dsc        "スタンピードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_stampede_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveStampedeFeatEvent < EventRule
    dsc        "スタンピードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_stampede_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateStampedeFeatEvent < EventRule
    dsc        "スタンピードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_stampede_feat
    goal       ["self", :use_end?]
  end

  class UseStampedeFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_stampede_feat
    goal       ["self", :use_end?]
  end

  class FinishStampedeFeatEvent < EventRule
    dsc        "スタンピードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_stampede_feat
    goal       ["self", :use_end?]
  end

  class UseStampedeFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_stampede_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# D・コントロール(復活)

  class CheckAddDeathControl2FeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_death_control2_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeathControl2FeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_death_control2_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeathControl2FeatEvent < EventRule
    dsc        "自壊攻撃が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_death_control2_feat
    goal       ["self", :use_end?]
  end

  class UseDeathControl2FeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_death_control2_feat
    goal       ["self", :use_end?]
  end

  class FinishDeathControl2FeatEvent < EventRule
    dsc        "自壊攻撃の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_death_control2_feat
    goal       ["self", :use_end?]
  end

  class UseDeathControl2FeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>81
    func       :use_death_control2_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 俺様の剣技に見惚れろ

  class CheckAddKengiFeatEvent < EventRule
    dsc        "俺様の剣技に見惚れろが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_kengi_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKengiFeatEvent < EventRule
    dsc        "俺様の剣技に見惚れろが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_kengi_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKengiFeatEvent < EventRule
    dsc        "俺様の剣技に見惚れろが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_kengi_feat
    goal       ["self", :use_end?]
  end

  class UseKengiFeatEvent < EventRule
    dsc        "俺様の剣技に見惚れろを使用 ATK補正"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_kengi_feat
    goal       ["self", :use_end?]
  end

  class UseKengiFeatRollChancelEvent < EventRule
    dsc        "通常のダイスロールの再生を抑制する"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_kengi_feat_roll_chancel
    goal       ["self", :use_end?]
  end

  class UseKengiFeatBattleResultEvent < EventRule
    dsc        "俺様の剣技に見惚れろの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>5
    func       :use_kengi_feat_battle_result
    goal       ["self", :use_end?]
  end

  class FinishKengiFeatEvent < EventRule
    dsc        "俺様の剣技に見惚れろの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_kengi_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 何処をみてやがる

  class CheckAddDokowoFeatEvent < EventRule
    dsc        "何処をみてやがるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_dokowo_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDokowoFeatEvent < EventRule
    dsc        "何処をみてやがるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_dokowo_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDokowoFeatEvent < EventRule
    dsc        "何処をみてやがるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_dokowo_feat
    goal       ["self", :use_end?]
  end

  class FinishDokowoFeatEvent < EventRule
    dsc        "何処をみてやがるを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :finish_dokowo_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# お前の技は見切った

  class CheckAddMikittaFeatEvent < EventRule
    dsc        "お前の技は見切ったが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_mikitta_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMikittaFeatEvent < EventRule
    dsc        "お前の技は見切ったが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_mikitta_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMikittaFeatEvent < EventRule
    dsc        "お前の技は見切ったが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_mikitta_feat
    goal       ["self", :use_end?]
  end

  class FinishMikittaFeatEvent < EventRule
    dsc        "お前の技は見切ったの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :finish_mikitta_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# これが俺様の本当の力だ

  class CheckAddHontouFeatEvent < EventRule
    dsc        "これが俺様の本当の力だが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hontou_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHontouFeatEvent < EventRule
    dsc        "これが俺様の本当の力だが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hontou_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHontouFeatEvent < EventRule
    dsc        "これが俺様の本当の力だが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hontou_feat
    goal       ["self", :use_end?]
  end

  class UseHontouFeatEvent < EventRule
    dsc        "これが俺様の本当の力だを使用 ATK補正"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hontou_feat
    goal       ["self", :use_end?]
  end

  class UseHontouFeatRollChancelEvent < EventRule
    dsc        "通常のダイスロールの再生を抑制する"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_hontou_feat_roll_chancel
    goal       ["self", :use_end?]
  end

  class UseHontouFeatBattleResultEvent < EventRule
    dsc        "これが俺様の本当の力だの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>6
    func       :use_hontou_feat_battle_result
    goal       ["self", :use_end?]
  end

  class FinishHontouFeatEvent < EventRule
    dsc        "これが俺様の本当の力だの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_hontou_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 招かれしものども

  class CheckAddInvitedFeatEvent < EventRule
    dsc        "招かれしものどもが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_invited_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveInvitedFeatEvent < EventRule
    dsc        "招かれしものどもが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_invited_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateInvitedFeatEvent < EventRule
    dsc        "招かれしものどもが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_invited_feat
    goal       ["self", :use_end?]
  end

  class FinishInvitedFeatEvent < EventRule
    dsc        "招かれしものどもを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_invited_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 透き通る手

  class CheckAddThroughHandFeatEvent < EventRule
    dsc        "透き通る手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_through_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThroughHandFeatEvent < EventRule
    dsc        "透き通る手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_through_hand_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThroughHandFeatEvent < EventRule
    dsc        "透き通る手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_through_hand_feat
    goal       ["self", :use_end?]
  end

  class UseThroughHandFeatEvent < EventRule
    dsc        "透き通る手の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_move_phase
    func       :use_through_hand_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 深遠なる息

  class CheckAddProfBreathFeatEvent < EventRule
    dsc        "深遠なる息が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_prof_breath_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveProfBreathFeatEvent < EventRule
    dsc        "深遠なる息が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_prof_breath_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateProfBreathFeatEvent < EventRule
    dsc        "深遠なる息が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_prof_breath_feat
    goal       ["self", :use_end?]
  end

  class FinishProfBreathFeatEvent < EventRule
    dsc        "深遠なる息を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>15
    func       :finish_prof_breath_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 7つの願い

  class CheckAddSevenWishFeatEvent < EventRule
    dsc        "7つの願いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_seven_wish_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSevenWishFeatEvent < EventRule
    dsc        "7つの願いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_seven_wish_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSevenWishFeatEvent < EventRule
    dsc        "7つの願いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_seven_wish_feat
    goal       ["self", :use_end?]
  end

  class UseSevenWishFeatEvent < EventRule
    dsc        "7つの願い発動"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_seven_wish_feat
    goal       ["self", :use_end?]
  end

  class UseSevenWishFeatDamageEvent < EventRule
    dsc        "7つの願い発動"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>50
    func       :use_seven_wish_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 13の眼(復活)

  class CheckAddThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class UseOwnerThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>50
    func       :use_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class UseFoeThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>70
    func       :use_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class FinishThirteenEyesRFeatEvent < EventRule
    dsc        "13の眼(復活)の使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>80
    func       :finish_thirteen_eyes_r_feat
    goal       ["self", :use_end?]
  end

  class UseThirteenEyesRFeatDamageEvent < EventRule
    dsc        "13の眼(復活)を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>60
    func       :use_thirteen_eyes_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 茨の構え(復活)

  class CheckAddThornCareRFeatEvent < EventRule
    dsc        "茨の構え(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_thorn_care_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThornCareRFeatEvent < EventRule
    dsc        "茨の構え(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_thorn_care_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThornCareRFeatEvent < EventRule
    dsc        "茨の構え(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_thorn_care_r_feat
    goal       ["self", :use_end?]
  end

  class UseThornCareRFeatEvent < EventRule
    dsc        "茨の構え(復活)を使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_thorn_care_r_feat
    goal       ["self", :use_end?]
  end

  class UseThornCareRFeatDamageEvent < EventRule
    dsc        "茨の構え(復活)使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_thorn_care_r_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishThornCareRFeatEvent < EventRule
    dsc        "茨の構え(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_thorn_care_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 解放剣(復活)

  class CheckAddLiberatingSwordRFeatEvent < EventRule
    dsc        "解放剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_liberating_sword_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLiberatingSwordRFeatEvent < EventRule
    dsc        "解放剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_liberating_sword_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLiberatingSwordRFeatEvent < EventRule
    dsc        "解放剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_liberating_sword_r_feat
    goal       ["self", :use_end?]
  end

  class UseLiberatingSwordRFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_liberating_sword_r_feat
    goal       ["self", :use_end?]
  end

  class FinishLiberatingSwordRFeatEvent < EventRule
    dsc        "解放剣(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_liberating_sword_r_feat
    goal       ["self", :use_end?]
  end

  class UseLiberatingSwordRFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>1
    func       :use_liberating_sword_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 呪剣(復活)

  class CheckAddCurseSwordRFeatEvent < EventRule
    dsc        "呪剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_curse_sword_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCurseSwordRFeatEvent < EventRule
    dsc        "呪剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_curse_sword_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCurseSwordRFeatEvent < EventRule
    dsc        "呪剣(復活)が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_curse_sword_r_feat
    goal       ["self", :use_end?]
  end

  class UseCurseSwordRFeatEvent < EventRule
    dsc        "呪剣(復活)を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_curse_sword_r_feat
    goal       ["self", :use_end?]
  end

  class FinishCurseSwordRFeatEvent < EventRule
    dsc        "呪剣(復活)の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_curse_sword_r_feat
    goal       ["self", :use_end?]
  end

  class UseCurseSwordRFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_curse_sword_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 火の輪くぐり

  class CheckAddFlameRingFeatEvent < EventRule
    dsc        "火の輪くぐりが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_flame_ring_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFlameRingFeatEvent < EventRule
    dsc        "火の輪くぐりが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_flame_ring_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFlameRingFeatEvent < EventRule
    dsc        "火の輪くぐりが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_flame_ring_feat
    goal       ["self", :use_end?]
  end

  class UseFlameRingFeatEvent < EventRule
    dsc        "火の輪くぐりを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_flame_ring_feat
    goal       ["self", :use_end?]
  end

  class FinishFlameRingFeatEvent < EventRule
    dsc        "火の輪くぐりの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_flame_ring_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ピアノ

  class CheckAddPianoFeatEvent < EventRule
    dsc        "ピアノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_piano_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePianoFeatEvent < EventRule
    dsc        "ピアノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_piano_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePianoFeatEvent < EventRule
    dsc        "ピアノが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_piano_feat
    goal       ["self", :use_end?]
  end

  class UsePianoFeatEvent < EventRule
    dsc        "ピアノを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_piano_feat
    goal       ["self", :use_end?]
  end

  class UsePianoFeatDamageEvent < EventRule
    dsc        "ピアノ使用"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action, :priority=>5
    func       :use_piano_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishPianoFeatEvent < EventRule
    dsc        "ピアノの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_piano_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 玉乗り

  class CheckAddOnaBallFeatEvent < EventRule
    dsc        "玉乗りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_ona_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOnaBallFeatEvent < EventRule
    dsc        "玉乗りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_ona_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOnaBallFeatEvent < EventRule
    dsc        "玉乗りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_ona_ball_feat
    goal       ["self", :use_end?]
  end

  class FinishNextOnaBallFeatEvent < EventRule
    dsc        "玉乗りを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_next_ona_ball_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 暴れる

  class CheckAddViolentFeatEvent < EventRule
    dsc        "暴れるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_violent_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveViolentFeatEvent < EventRule
    dsc        "暴れるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_violent_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateViolentFeatEvent < EventRule
    dsc        "暴れるが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_violent_feat
    goal       ["self", :use_end?]
  end

  class FinishViolentFeatEvent < EventRule
    dsc        "暴れるの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_violent_feat
    goal       ["self", :use_end?]
  end

  class FinishViolentFeatChangeEvent < EventRule
    dsc        "暴れるを使用 相手に特殊/2のダメージ"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_violent_feat_change
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ライフタイムサウンド

  class CheckAddLifetimeSoundFeatEvent < EventRule
    dsc        "ライフタイムサウンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_lifetime_sound_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveLifetimeSoundFeatEvent < EventRule
    dsc        "ライフタイムサウンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_lifetime_sound_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateLifetimeSoundFeatEvent < EventRule
    dsc        "ライフタイムサウンドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_lifetime_sound_feat
    goal       ["self", :use_end?]
  end

  class UseLifetimeSoundFeatEvent < EventRule
    dsc        "ライフタイムサウンドを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_lifetime_sound_feat
    goal       ["self", :use_end?]
  end

  class FinishLifetimeSoundFeatEvent < EventRule
    dsc        "ライフタイムサウンドの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase,:priority=>5
    func       :finish_lifetime_sound_feat
    goal       ["self", :use_end?]
  end

  class FinishLifetimeSoundFeatDamageEvent < EventRule
    dsc        "ライフタイムサウンドの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_lifetime_sound_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# バランスライフ

  class CheckAddBalanceLifeFeatEvent < EventRule
    dsc        "バランスライフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_balance_life_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBalanceLifeFeatEvent < EventRule
    dsc        "バランスライフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_balance_life_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBalanceLifeFeatEvent < EventRule
    dsc        "バランスライフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_balance_life_feat
    goal       ["self", :use_end?]
  end

  class UseBalanceLifeFeatEvent < EventRule
    dsc        "バランスライフを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_balance_life_feat
    goal       ["self", :use_end?]
  end

  class UseBalanceLifeFeatDamageEvent < EventRule
    dsc        "バランスライフ ダメージ制御"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_balance_life_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishBalanceLifeFeatEvent < EventRule
    dsc        "バランスライフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_balance_life_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# コマホワイト

  class CheckAddComaWhiteFeatEvent < EventRule
    dsc        "コマホワイトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_coma_white_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveComaWhiteFeatEvent < EventRule
    dsc        "コマホワイトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_coma_white_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateComaWhiteFeatEvent < EventRule
    dsc        "コマホワイトが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_coma_white_feat
    goal       ["self", :use_end?]
  end

  class UseComaWhiteFeatEvent < EventRule
    dsc        "コマホワイトを使用 攻撃力にダメージを加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_coma_white_feat
    goal       ["self", :use_end?]
  end

  class FinishComaWhiteFeatEvent < EventRule
    dsc        "コマホワイトの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>50
    func       :finish_coma_white_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ゴーズトゥダーク

  class CheckAddGoesToDarkFeatEvent < EventRule
    dsc        "ゴーズトゥダークが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_goes_to_dark_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGoesToDarkFeatEvent < EventRule
    dsc        "ゴーズトゥダークが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_goes_to_dark_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGoesToDarkFeatEvent < EventRule
    dsc        "ゴーズトゥダークが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_goes_to_dark_feat
    goal       ["self", :use_end?]
  end

  class FinishGoesToDarkFeatEvent < EventRule
    dsc        "ゴーズトゥダークを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_goes_to_dark_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 羅刹の構え

  class CheckAddRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構えが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class CheckRakshasaStanceStateChangeEvent < EventRule
    dsc        "羅刹の構え状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_rakshasa_stance_state_change
    goal       ["self", :use_end?]
  end

  class UseRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構えを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class UseRakshasaStanceFeatResultEvent < EventRule
    dsc        "羅刹の構え状態 ダメージ倍化"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>70
    func       :use_rakshasa_stance_feat_result
  end

  class OnRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構え状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:change_initiative_phase
    func       :on_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class OffRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構え状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :off_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

  class FinishRakshasaStanceFeatEvent < EventRule
    dsc        "羅刹の構え状態が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_rakshasa_stance_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 霧隠れ

  class CheckAddKirigakureFeatEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_kirigakure_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKirigakureFeatEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_kirigakure_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKirigakureFeatEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_kirigakure_feat
    goal       ["self", :use_end?]
  end

  class CheckAddKirigakureFeatFoeAttackEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:attack_card_add_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class CheckRemoveKirigakureFeatFoeAttackEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:attack_card_remove_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class CheckRotateKirigakureFeatFoeAttackEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:attack_card_rotate_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class CheckAddKirigakureFeatFoeDefenseEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_card_add_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class CheckRemoveKirigakureFeatFoeDefenseEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_card_remove_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class CheckRotateKirigakureFeatFoeDefenseEvent < EventRule
    dsc        "霧隠れが可能か"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_card_rotate_action, :priority=>500
    func       :check_kirigakure_feat_foe
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatCalcEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_kirigakure_feat_calc
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatPhaseInitEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :use_kirigakure_feat_phase_init
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatDefenseDoneOwnerEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action
    func       :use_kirigakure_feat_defense_done
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatDefenseDoneOwnerEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_done_action
    func       :use_kirigakure_feat_defense_done
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatDefenseDoneFoeEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"foe", :hook=>:deffence_done_action
    func       :use_kirigakure_feat_defense_done
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>7
    func       :use_kirigakure_feat
    goal       ["self", :use_end?]
  end

  class UseKirigakureFeatDetChangeEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :use_kirigakure_feat_det_change
    goal       ["self", :use_end?]
  end

  class FinishKirigakureFeatOwnerDamagedEvent < EventRule
    dsc        "受けるダメージが+のとき、霧隠れを終了"
    type       :type=>:after, :obj=>"owner", :hook=>:determine_damage_event
    func       :finish_kirigakure_feat_owner_damaged
    goal       ["self", :use_end?]
  end

  class FinishKirigakureFeatDoDamageEvent < EventRule
    dsc        "受けるダメージが+のとき、霧隠れを終了"
    type       :type=>:after, :obj=>"foe", :hook=>:determine_damage_event
    func       :finish_kirigakure_feat_do_damage
    goal       ["self", :use_end?]
  end

  class FinishKirigakureFeatFinishTurnEvent < EventRule
    dsc        "霧隠れを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_kirigakure_feat_finish_turn
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 水鏡

  class CheckAddMikagamiFeatEvent < EventRule
    dsc        "水鏡が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_mikagami_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMikagamiFeatEvent < EventRule
    dsc        "水鏡が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_mikagami_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMikagamiFeatEvent < EventRule
    dsc        "水鏡が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_mikagami_feat
    goal       ["self", :use_end?]
  end

  class UseMikagamiFeatEvent < EventRule
    dsc        "水鏡を使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_mikagami_feat
    goal       ["self", :use_end?]
  end

  class FinishMikagamiFeatEvent < EventRule
    dsc        "水鏡の使用が終了 防御成功時カウンター"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_mikagami_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 落花流水

  class CheckAddMutualLoveFeatEvent < EventRule
    dsc        "落花流水が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_mutual_love_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMutualLoveFeatEvent < EventRule
    dsc        "落花流水が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_mutual_love_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMutualLoveFeatEvent < EventRule
    dsc        "落花流水が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_mutual_love_feat
    goal       ["self", :use_end?]
  end

  class UseMutualLoveFeatEvent < EventRule
    dsc        "落花流水を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_mutual_love_feat
    goal       ["self", :use_end?]
  end

  class UseMutualLoveFeatDamageEvent < EventRule
    dsc        "落花流水を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_mutual_love_feat_damage
    goal       ["self", :use_end?]
  end

  class UseMutualLoveFeatConstDamageEvent < EventRule
    dsc        "落花流水を使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_mutual_love_feat_const_damage
    goal       ["self", :use_end?]
  end

  class FinishMutualLoveFeatEvent < EventRule
    dsc        "落花流水の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_mutual_love_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 鏡花水月

  class CheckAddMereShadowFeatEvent < EventRule
    dsc        "鏡花水月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_mere_shadow_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMereShadowFeatEvent < EventRule
    dsc        "鏡花水月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_mere_shadow_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMereShadowFeatEvent < EventRule
    dsc        "鏡花水月が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_mere_shadow_feat
    goal       ["self", :use_end?]
  end

  class UseMereShadowFeatEvent < EventRule
    dsc        "鏡花水月を使用 攻撃力が+4"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_mere_shadow_feat
    goal       ["self", :use_end?]
  end

  class FinishMereShadowFeatEvent < EventRule
    dsc        "鏡花水月の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>5
    func       :finish_mere_shadow_feat
    goal       ["self", :use_end?]
  end

  class FinishMereShadowFeatDiceAttrEvent < EventRule
    dsc        "数値書き換え"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>70
    func       :finish_mere_shadow_feat_dice_attr
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 亀占い

  class CheckAddScapulimancyFeatEvent < EventRule
    dsc        "亀占いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_scapulimancy_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveScapulimancyFeatEvent < EventRule
    dsc        "亀占いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_scapulimancy_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateScapulimancyFeatEvent < EventRule
    dsc        "亀占いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_scapulimancy_feat
    goal       ["self", :use_end?]
  end

  class FinishScapulimancyFeatEvent < EventRule
    dsc        "亀占いを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_scapulimancy_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 土盾

  class CheckAddSoilGuardFeatEvent < EventRule
    dsc        "土盾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_soil_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSoilGuardFeatEvent < EventRule
    dsc        "土盾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_soil_guard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSoilGuardFeatEvent < EventRule
    dsc        "土盾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_soil_guard_feat
    goal       ["self", :use_end?]
  end

  class UseSoilGuardFeatEvent < EventRule
    dsc        "土盾を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_soil_guard_feat
    goal       ["self", :use_end?]
  end

  class UseSoilGuardFeatDamageEvent < EventRule
    dsc        "土盾を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_soil_guard_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 甲羅スピン

  class CheckAddCarapaceSpinFeatEvent < EventRule
    dsc        "甲羅スピンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_carapace_spin_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCarapaceSpinFeatEvent < EventRule
    dsc        "甲羅スピンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_carapace_spin_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCarapaceSpinFeatEvent < EventRule
    dsc        "甲羅スピンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_carapace_spin_feat
    goal       ["self", :use_end?]
  end

  class UseCarapaceSpinFeatEvent < EventRule
    dsc        "甲羅スピンを使用 相手にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_carapace_spin_feat
    goal       ["self", :use_end?]
  end

  class FinishCarapaceSpinFeatEvent < EventRule
    dsc        "甲羅スピンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_carapace_spin_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヴェンデッタ

  class CheckAddVendettaFeatEvent < EventRule
    dsc        "ヴェンデッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_vendetta_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveVendettaFeatEvent < EventRule
    dsc        "ヴェンデッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_vendetta_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateVendettaFeatEvent < EventRule
    dsc        "ヴェンデッタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_vendetta_feat
    goal       ["self", :use_end?]
  end

  class UseVendettaFeatEvent < EventRule
    dsc        "ヴェンデッタを使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_vendetta_feat
    goal       ["self", :use_end?]
  end

  class FinishVendettaFeatEvent < EventRule
    dsc        "ヴェンデッタの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_vendetta_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アヴェンジャー

  class CheckAddAvengersFeatEvent < EventRule
    dsc        "アヴェンジャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_avengers_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAvengersFeatEvent < EventRule
    dsc        "アヴェンジャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_avengers_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAvengersFeatEvent < EventRule
    dsc        "アヴェンジャーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_avengers_feat
    goal       ["self", :use_end?]
  end

  class UseAvengersFeatEvent < EventRule
    dsc        "アヴェンジャーを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_avengers_feat
    goal       ["self", :use_end?]
  end

  class FinishAvengersFeatEvent < EventRule
    dsc        "アヴェンジャーの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:battle_result_phase, :priority=>10
    func       :finish_avengers_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# シャープンエッジ

  class CheckAddSharpenEdgeFeatEvent < EventRule
    dsc        "シャープンエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_sharpen_edge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSharpenEdgeFeatEvent < EventRule
    dsc        "シャープンエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_sharpen_edge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSharpenEdgeFeatEvent < EventRule
    dsc        "シャープンエッジが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_sharpen_edge_feat
    goal       ["self", :use_end?]
  end

  class UseSharpenEdgeFeatEvent < EventRule
    dsc        "シャープンエッジを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :use_sharpen_edge_feat
    goal       ["self", :use_end?]
  end

# 状態イベント

  class CheckSharpenEdgeStateChangeEvent < EventRule
    dsc        "シャープンエッジ状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_sharpen_edge_state_change
    goal       ["self", :use_end?]
  end

  class CheckSharpenEdgeStateDeadChangeEvent < EventRule
    dsc        "シャープンエッジ状態が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_sharpen_edge_state_change
    goal       ["self", :use_end?]
  end

  class UseSharpenEdgeStateDamageEvent < EventRule
    dsc        "シャープンエッジ状態 ダイス用の回避動作"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>60
    func       :use_sharpen_edge_state_damage
  end

  class FinishSharpenEdgeStateEvent < EventRule
    dsc        "シャープンエッジ状態 ターンおわり終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase, :priority=>10
    func       :finish_sharpen_edge_state
  end

#---------------------------------------------------------------------------------------------
# ハックナイン

  class CheckAddHacknineFeatEvent < EventRule
    dsc        "ハックナインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hacknine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHacknineFeatEvent < EventRule
    dsc        "ハックナインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hacknine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHacknineFeatEvent < EventRule
    dsc        "ハックナインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hacknine_feat
    goal       ["self", :use_end?]
  end

  class UseHacknineFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hacknine_feat
    goal       ["self", :use_end?]
  end

  class FinishHacknineFeatEvent < EventRule
    dsc        "ハックナインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_hacknine_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ブラックマゲイア

  class CheckAddBlackMageiaFeatEvent < EventRule
    dsc        "ブラックマゲイアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_black_mageia_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlackMageiaFeatEvent < EventRule
    dsc        "ブラックマゲイアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_black_mageia_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlackMageiaFeatEvent < EventRule
    dsc        "ブラックマゲイアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_black_mageia_feat
    goal       ["self", :use_end?]
  end

  class FinishBlackMageiaFeatEvent < EventRule
    dsc        "ブラックマゲイアの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_black_mageia_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# コープスドレイン

  class CheckAddCorpsDrainFeatEvent < EventRule
    dsc        "コープスドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_corps_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCorpsDrainFeatEvent < EventRule
    dsc        "コープスドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_corps_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCorpsDrainFeatEvent < EventRule
    dsc        "コープスドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_corps_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishCorpsDrainFeatEvent < EventRule
    dsc        "コープスドレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_corps_drain_feat
    goal       ["self", :use_end?]
  end

  class UseCorpsDrainFeatDamageEvent < EventRule
    dsc        "コープスドレイン使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>0
    func       :use_corps_drain_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# インヴァート
  class CheckAddInvertFeatEvent < EventRule
    dsc        "インヴァートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_invert_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveInvertFeatEvent < EventRule
    dsc        "インヴァートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_invert_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateInvertFeatEvent < EventRule
    dsc        "インヴァートが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_invert_feat
    goal       ["self", :use_end?]
  end

  class FinishInvertFeatEvent < EventRule
    dsc        "インヴァートの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_invert_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 追跡する夜鷹

  class CheckAddNightHawkFeatEvent < EventRule
    dsc        "追跡する夜鷹を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_night_hawk_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNightHawkFeatEvent < EventRule
    dsc        "追跡する夜鷹を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_night_hawk_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNightHawkFeatEvent < EventRule
    dsc        "追跡する夜鷹を使用が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_night_hawk_feat
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatEvent < EventRule
    dsc        "追跡する夜鷹を使用を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_night_hawk_feat
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatDetMpBefore1Event < EventRule
    dsc        "追跡する夜鷹を使用を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:set_initiative_event, :priority=>8
    func       :use_night_hawk_feat_det_mp_before1
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatDetMpBefore2Event < EventRule
    dsc        "追跡する夜鷹を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:set_initiative_event, :priority=>10
    func       :use_night_hawk_feat_det_mp_before2
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatFoeChangeEvent < EventRule
    dsc        "追跡する夜鷹を使用"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :use_night_hawk_feat_change
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatOwnerChangeEvent < EventRule
    dsc        "追跡する夜鷹を使用"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :use_night_hawk_feat_change
    goal       ["self", :use_end?]
  end

  class UseNightHawkFeatDeadChangeEvent < EventRule
    dsc        "追跡する夜鷹を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:dead_chara_change_phase
    func       :use_night_hawk_feat_change
    goal       ["self", :use_end?]
  end

  class FinishNightHawkFeatChangeEvent < EventRule
    dsc        "無謬の行いを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :finish_night_hawk_feat_change
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 幽幻の剛弾

  class CheckAddPhantomBarrettFeatEvent < EventRule
    dsc        "幽幻の剛弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_phantom_barrett_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePhantomBarrettFeatEvent < EventRule
    dsc        "幽幻の剛弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_phantom_barrett_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePhantomBarrettFeatEvent < EventRule
    dsc        "幽幻の剛弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_phantom_barrett_feat
    goal       ["self", :use_end?]
  end

  class UsePhantomBarrettFeatEvent < EventRule
    dsc        "幽幻の剛弾を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_phantom_barrett_feat
    goal       ["self", :use_end?]
  end

  class FinishPhantomBarrettFeatEvent < EventRule
    dsc        "幽幻の剛弾の使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :finish_phantom_barrett_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 惑わしの一幕

  class CheckAddOneActFeatEvent < EventRule
    dsc        "惑わしの一幕が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_one_act_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveOneActFeatEvent < EventRule
    dsc        "惑わしの一幕が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_one_act_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateOneActFeatEvent < EventRule
    dsc        "惑わしの一幕が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_one_act_feat
    goal       ["self", :use_end?]
  end

  class UseOneActFeatEvent < EventRule
    dsc        "惑わしの一幕を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_one_act_feat
    goal       ["self", :use_end?]
  end

  class FinishOneActFeatEvent < EventRule
    dsc        "惑わしの一幕を使用 相手のカードを変換"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_one_act_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 終極の烈弾

  class CheckAddFinalBarrettFeatEvent < EventRule
    dsc        "終極の烈弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_final_barrett_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFinalBarrettFeatEvent < EventRule
    dsc        "終極の烈弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_final_barrett_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFinalBarrettFeatEvent < EventRule
    dsc        "終極の烈弾が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_final_barrett_feat
    goal       ["self", :use_end?]
  end

  class UseFinalBarrettFeatEvent < EventRule
    dsc        "終極の烈弾を使用 相手にダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_final_barrett_feat
    goal       ["self", :use_end?]
  end

  class FinishFinalBarrettFeatEvent < EventRule
    dsc        "終極の烈弾の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_final_barrett_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# グリムデッド

  class CheckAddGrimmdeadFeatEvent < EventRule
    dsc        "グリムデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_grimmdead_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGrimmdeadFeatEvent < EventRule
    dsc        "グリムデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_grimmdead_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGrimmdeadFeatEvent < EventRule
    dsc        "グリムデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_grimmdead_feat
    goal       ["self", :use_end?]
  end

  class UseGrimmdeadFeatCalcEvent < EventRule
    dsc        "グリムデッドの使用が終了"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_grimmdead_feat_calc
    goal       ["self", :use_end?]
  end

  class UseGrimmdeadFeatEvent < EventRule
    dsc        "グリムデッドの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_grimmdead_feat
    goal       ["self", :use_end?]
  end

  class UseGrimmdeadFeatMoveBeforeEvent < EventRule
    dsc        "グリムデッドの距離保存"
    type       :type=>:before, :obj=>"owner", :hook=>:move_action , :priority=>1
    func       :use_grimmdead_feat_move_before
    goal       ["self", :use_end?]
  end

  class UseGrimmdeadFeatMoveAfterEvent < EventRule
    dsc        "グリムデッドのダメージ付与"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action, :priority=>1
    func       :use_grimmdead_feat_move_after
    goal       ["self", :use_end?]
  end

  class FinishGrimmdeadFeatEvent < EventRule
    dsc        "グリムデッド終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_grimmdead_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヴンダーカンマー

  class CheckAddWunderkammerFeatEvent < EventRule
    dsc        "ヴンダーカンマーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_wunderkammer_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWunderkammerFeatEvent < EventRule
    dsc        "ヴンダーカンマーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_wunderkammer_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWunderkammerFeatEvent < EventRule
    dsc        "ヴンダーカンマーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_wunderkammer_feat
    goal       ["self", :use_end?]
  end

  class FinishWunderkammerFeatEvent < EventRule
    dsc        "ヴンダーカンマーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_wunderkammer_feat
    goal       ["self", :use_end?]
  end

  class UseWunderkammerFeatEvent < EventRule
    dsc        "ヴンダーカンマーを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_wunderkammer_feat
    goal       ["self", :use_end?]
  end

  class UseWunderkammerFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_wunderkammer_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# コンストレイント

  class CheckAddConstraintFeatEvent < EventRule
    dsc        "コンストレイントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_constraint_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveConstraintFeatEvent < EventRule
    dsc        "コンストレイントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_constraint_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateConstraintFeatEvent < EventRule
    dsc        "コンストレイントが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_constraint_feat
    goal       ["self", :use_end?]
  end

  class UseConstraintFeatEvent < EventRule
    dsc        "コンストレイントを使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_constraint_feat
    goal       ["self", :use_end?]
  end

  class UseConstraintFeatDamageEvent < EventRule
    dsc        "コンストレイント使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_constraint_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishConstraintFeatEvent < EventRule
    dsc        "コンストレイントの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_constraint_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# リノベートアトランダム

  class CheckAddRenovateAtrandomFeatEvent < EventRule
    dsc        "リノベートアトランダムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_renovate_atrandom_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRenovateAtrandomFeatEvent < EventRule
    dsc        "リノベートアトランダムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_renovate_atrandom_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRenovateAtrandomFeatEvent < EventRule
    dsc        "リノベートアトランダムが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_renovate_atrandom_feat
    goal       ["self", :use_end?]
  end

  class UseRenovateAtrandomFeatEvent < EventRule
    dsc        "リノベートアトランダムを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_renovate_atrandom_feat
    goal       ["self", :use_end?]
  end

  class UseRenovateAtrandomFeatDamageEvent < EventRule
    dsc        "リノベートアトランダムを使用時に手札をランダムに失わせる"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :use_renovate_atrandom_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRenovateAtrandomFeatEvent < EventRule
    dsc        "リノベートアトランダムの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_renovate_atrandom_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 催眠術

  class CheckAddBackbeardFeatEvent < EventRule
    dsc        "催眠術が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_backbeard_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBackbeardFeatEvent < EventRule
    dsc        "催眠術が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_backbeard_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBackbeardFeatEvent < EventRule
    dsc        "催眠術が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_backbeard_feat
    goal       ["self", :use_end?]
  end

  class UseBackbeardFeatDamageEvent < EventRule
    dsc        "催眠術使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>110
    func       :use_backbeard_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishBackbeardFeatEvent < EventRule
    dsc        "催眠術の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_backbeard_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 影縫い

  class CheckAddShadowStitchFeatEvent < EventRule
    dsc        "影縫いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_shadow_stitch_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveShadowStitchFeatEvent < EventRule
    dsc        "影縫いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_shadow_stitch_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateShadowStitchFeatEvent < EventRule
    dsc        "影縫いが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_shadow_stitch_feat
    goal       ["self", :use_end?]
  end

  class UseShadowStitchFeatEvent < EventRule
    dsc        "攻撃力を減算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>10
    func       :use_shadow_stitch_feat
    goal       ["self", :use_end?]
  end

  class FinishShadowStitchFeatEvent < EventRule
    dsc        "影縫いの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_shadow_stitch_feat
    goal       ["self", :use_end?]
  end

  class UseShadowStitchFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_shadow_stitch_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ミキストリ

  class CheckAddMextliFeatEvent < EventRule
    dsc        "ミキストリが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_mextli_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMextliFeatEvent < EventRule
    dsc        "ミキストリが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_mextli_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMextliFeatEvent < EventRule
    dsc        "ミキストリが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_mextli_feat
    goal       ["self", :use_end?]
  end

  class UseMextliFeatEvent < EventRule
    dsc        "ミキストリを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :use_mextli_feat
    goal       ["self", :use_end?]
  end

# 状態イベント

  class CheckDamageInsuranceChangeEvent < EventRule
    dsc        "ダメージ追加状態チェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_damage_insurance_change
    goal       ["self", :use_end?]
  end

  class CheckDamageInsuranceDeadChangeEvent < EventRule
    dsc        "ダメージ追加状態チェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_damage_insurance_change
    goal       ["self", :use_end?]
  end

  class UseDamageInsuranceDamageEvent < EventRule
    dsc        "ダメージ追加 攻撃失敗時の動作"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_damage_insurance_damage
  end

#---------------------------------------------------------------------------------------------
# リベットアンドサージ

  class CheckAddRivetAndSurgeFeatEvent < EventRule
    dsc        "リベットアンドサージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRivetAndSurgeFeatEvent < EventRule
    dsc        "リベットアンドサージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRivetAndSurgeFeatEvent < EventRule
    dsc        "リベットアンドサージが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class UseRivetAndSurgeFeatAttackEvent < EventRule
    dsc        "リベットアンドサージをを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class UseRivetAndSurgeFeatDefenseEvent < EventRule
    dsc        "リベットアンドサージをを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class CutinRivetAndSurgeFeatEvent < EventRule
    dsc        "リベットアンドサージをを使用 攻撃力が+3"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :cutin_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

  class FinishRivetAndSurgeFeatEvent < EventRule
    dsc        "リベットアンドサージの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_rivet_and_surge_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ファントマ

  class CheckAddPhantomasFeatEvent < EventRule
    dsc        "ファントマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action, :priority=>1
    func       :check_phantomas_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePhantomasFeatEvent < EventRule
    dsc        "ファントマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action, :priority=>1
    func       :check_phantomas_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePhantomasFeatEvent < EventRule
    dsc        "ファントマが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action, :priority=>1
    func       :check_phantomas_feat
    goal       ["self", :use_end?]
  end

  class UsePhantomasFeatEvent < EventRule
    dsc        "ファントマを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_phantomas_feat
    goal       ["self", :use_end?]
  end

  class FinishPhantomasFeatEvent < EventRule
    dsc        "ファントマの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_phantomas_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 危険ドラッグ

  class CheckAddDangerDrugFeatEvent < EventRule
    dsc        "危険ドラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_danger_drug_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDangerDrugFeatEvent < EventRule
    dsc        "危険ドラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_danger_drug_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDangerDrugFeatEvent < EventRule
    dsc        "危険ドラッグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_danger_drug_feat
    goal       ["self", :use_end?]
  end

  class FinishDangerDrugFeatEvent < EventRule
    dsc        "危険ドラッグを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>9
    func       :finish_danger_drug_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# HP3サンダー

  class CheckAddThreeThunderFeatEvent < EventRule
    dsc        "HP3サンダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_three_thunder_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThreeThunderFeatEvent < EventRule
    dsc        "HP3サンダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_three_thunder_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThreeThunderFeatEvent < EventRule
    dsc        "HP3サンダーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_three_thunder_feat
    goal       ["self", :use_end?]
  end

  class UseThreeThunderFeatEvent < EventRule
    dsc        "HP3サンダーの使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_three_thunder_feat
    goal       ["self", :use_end?]
  end

  class FinishThreeThunderFeatEvent < EventRule
    dsc        "HP3サンダーの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_three_thunder_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 素数ヒール

  class CheckAddPrimeHealFeatEvent < EventRule
    dsc        "素数ヒールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_prime_heal_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePrimeHealFeatEvent < EventRule
    dsc        "素数ヒールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_prime_heal_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePrimeHealFeatEvent < EventRule
    dsc        "素数ヒールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_prime_heal_feat
    goal       ["self", :use_end?]
  end

  class UsePrimeHealFeatEvent < EventRule
    dsc        "素数ヒールの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_prime_heal_feat
    goal       ["self", :use_end?]
  end

  class FinishPrimeHealFeatEvent < EventRule
    dsc        "素数ヒールの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_prime_heal_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# HP4コメット

  class CheckAddFourCometFeatEvent < EventRule
    dsc        "HP4コメットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_four_comet_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFourCometFeatEvent < EventRule
    dsc        "HP4コメットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_four_comet_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFourCometFeatEvent < EventRule
    dsc        "HP4コメットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_four_comet_feat
    goal       ["self", :use_end?]
  end

  class UseFourCometFeatEvent < EventRule
    dsc        "HP4コメットの使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :use_four_comet_feat
    goal       ["self", :use_end?]
  end

  class FinishFourCometFeatEvent < EventRule
    dsc        "HP4コメットの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_four_comet_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クラブジャグ

  class CheckAddClubJuggFeatEvent < EventRule
    dsc        "クラブジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_club_jugg_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveClubJuggFeatEvent < EventRule
    dsc        "クラブジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_club_jugg_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateClubJuggFeatEvent < EventRule
    dsc        "クラブジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_club_jugg_feat
    goal       ["self", :use_end?]
  end

  class UseClubJuggFeatEvent < EventRule
    dsc        "クラブジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_club_jugg_feat
    goal       ["self", :use_end?]
  end

  class UseClubJuggFeatDealEvent < EventRule
    dsc        "クラブジャグを使用 カードを墓地から拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_club_jugg_feat_deal
    goal       ["self", :use_end?]
  end

  class FinishClubJuggFeatEvent < EventRule
    dsc        "クラブジャグが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_club_jugg_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ナイフジャグ

  class CheckAddKnifeJuggFeatEvent < EventRule
    dsc        "ナイフジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_knife_jugg_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKnifeJuggFeatEvent < EventRule
    dsc        "ナイフジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_knife_jugg_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKnifeJuggFeatEvent < EventRule
    dsc        "ナイフジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_knife_jugg_feat
    goal       ["self", :use_end?]
  end

  class UseKnifeJuggFeatEvent < EventRule
    dsc        "ナイフジャグが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_knife_jugg_feat
    goal       ["self", :use_end?]
  end

  class UseKnifeJuggFeatDealEvent < EventRule
    dsc        "ナイフジャグを使用 カードを墓地から拾う"
    type       :type=>:before, :obj=>"owner", :hook=>:battle_phase_init_event
    func       :use_knife_jugg_feat_deal
    goal       ["self", :use_end?]
  end

  class FinishKnifeJuggFeatEvent < EventRule
    dsc        "ナイフジャグが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_knife_jugg_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 火吹き

  class CheckAddBlowingFireFeatEvent < EventRule
    dsc        "火吹きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blowing_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlowingFireFeatEvent < EventRule
    dsc        "火吹きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blowing_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlowingFireFeatEvent < EventRule
    dsc        "火吹きが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blowing_fire_feat
    goal       ["self", :use_end?]
  end

  class UseBlowingFireFeatEvent < EventRule
    dsc        "火吹きを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blowing_fire_feat
    goal       ["self", :use_end?]
  end

  class FinishBlowingFireFeatEvent < EventRule
    dsc        "火吹きの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blowing_fire_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# バランスボール

  class CheckAddBalanceBallFeatEvent < EventRule
    dsc        "バランスボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_balance_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBalanceBallFeatEvent < EventRule
    dsc        "バランスボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_balance_ball_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBalanceBallFeatEvent < EventRule
    dsc        "バランスボールが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_balance_ball_feat
    goal       ["self", :use_end?]
  end

  class UseBalanceBallFeatEvent < EventRule
    dsc        "バランスボールを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>50
    func       :use_balance_ball_feat
    goal       ["self", :use_end?]
  end

  class FinishBalanceBallFeatEvent < EventRule
    dsc        "バランスボールを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_balance_ball_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 劣化ミルク

  class CheckAddBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class UseBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class UseBadMilkFeatRecalcEvent < EventRule
    dsc        "劣化ミルクをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>81
    func       :use_bad_milk_feat_recalc
    goal       ["self", :use_end?]
  end

  class UseExBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクをを使用 攻撃力が2倍"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>1
    func       :use_ex_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishChangeBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_change_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_bad_milk_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnBadMilkFeatEvent < EventRule
    dsc        "劣化ミルクを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_bad_milk_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ミラHP

  class CheckAddMiraHpFeatEvent < EventRule
    dsc        "ミラHPが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_mira_hp_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMiraHpFeatEvent < EventRule
    dsc        "ミラHPが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_mira_hp_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMiraHpFeatEvent < EventRule
    dsc        "ミラHPが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_mira_hp_feat
    goal       ["self", :use_end?]
  end

  class UseMiraHpFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_mira_hp_feat
    goal       ["self", :use_end?]
  end

  class FinishMiraHpFeatEvent < EventRule
    dsc        "ミラHPの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_mira_hp_feat
    goal       ["self", :use_end?]
  end

  class UseMiraHpFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event, :priority=>50
    func       :use_mira_hp_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スキルドレイン

  class CheckAddSkillDrainFeatEvent < EventRule
    dsc        "スキルドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_skill_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSkillDrainFeatEvent < EventRule
    dsc        "スキルドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_skill_drain_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSkillDrainFeatEvent < EventRule
    dsc        "スキルドレインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_skill_drain_feat
    goal       ["self", :use_end?]
  end

  class UseSkillDrainFeatEvent < EventRule
    dsc        "スキルドレインを使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_skill_drain_feat
    goal       ["self", :use_end?]
  end

  class UseSkillDrainFeatDamageEvent < EventRule
    dsc        "スキルドレインを使用 攻撃力が+2"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_skill_drain_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishSkillDrainFeatEvent < EventRule
    dsc        "スキルドレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_skill_drain_feat
    goal       ["self", :use_end?]
  end

  class FinishSkillDrainFeatFinishEvent < EventRule
    dsc        "スキルドレインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase, :priority=>70
    func       :finish_skill_drain_feat_finish
    goal       ["self", :use_end?]
  end

  class FinishOverrideSkillStateEvent < EventRule
    dsc        "スキル状態更新"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase, :priority=>80
    func       :finish_override_skill_state
  end

#---------------------------------------------------------------------------------------------
# コフィン

  class CheckAddCoffinFeatEvent < EventRule
    dsc        "コフィンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_coffin_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCoffinFeatEvent < EventRule
    dsc        "コフィンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_coffin_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCoffinFeatEvent < EventRule
    dsc        "コフィンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_coffin_feat
    goal       ["self", :use_end?]
  end

  class UseCoffinFeatEvent < EventRule
    dsc        "コフィンを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_coffin_feat
    goal       ["self", :use_end?]
  end

  class FinishCoffinFeatEvent < EventRule
    dsc        "コフィンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_coffin_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 玄青眼

  class CheckAddDarkEyesFeatEvent < EventRule
    dsc        "玄青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_dark_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDarkEyesFeatEvent < EventRule
    dsc        "玄青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_dark_eyes_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDarkEyesFeatEvent < EventRule
    dsc        "玄青眼が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_dark_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseDarkEyesFeatEvent < EventRule
    dsc        "玄青眼を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_dark_eyes_feat
    goal       ["self", :use_end?]
  end

  class UseDarkEyesFeatMoveEvent < EventRule
    dsc        "玄青眼を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>10
    func       :use_dark_eyes_feat_move
    goal       ["self", :use_end?]
  end

  class UseDarkEyesFeatDamageEvent < EventRule
    dsc        "玄青眼を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_dark_eyes_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 烏爪一転

  class CheckAddCrowsClawFeatEvent < EventRule
    dsc        "烏爪一転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_crows_claw_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCrowsClawFeatEvent < EventRule
    dsc        "烏爪一転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_crows_claw_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCrowsClawFeatEvent < EventRule
    dsc        "烏爪一転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_crows_claw_feat
    goal       ["self", :use_end?]
  end

  class UseCrowsClawFeatEvent < EventRule
    dsc        "烏爪一転を使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>20
    func       :use_crows_claw_feat
    goal       ["self", :use_end?]
  end

  class FinishCrowsClawFeatEvent < EventRule
    dsc        "烏爪一転の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_crows_claw_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 土竜縛符

  class CheckAddMoleFeatEvent < EventRule
    dsc        "土竜縛符が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_mole_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMoleFeatEvent < EventRule
    dsc        "土竜縛符が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_mole_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMoleFeatEvent < EventRule
    dsc        "土竜縛符が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_mole_feat
    goal       ["self", :use_end?]
  end

  class UseMoleFeatEvent < EventRule
    dsc        "土竜縛符を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_mole_feat
    goal       ["self", :use_end?]
  end

  class UseMoleFeatDamageEvent < EventRule
    dsc        "土竜縛符使用時にダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priorit=>100
    func       :use_mole_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishMoleFeatEvent < EventRule
    dsc        "土竜縛符の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_mole_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 五彩晩霞

  class CheckAddSunsetFeatEvent < EventRule
    dsc        "五彩晩霞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_sunset_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSunsetFeatEvent < EventRule
    dsc        "五彩晩霞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_sunset_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSunsetFeatEvent < EventRule
    dsc        "五彩晩霞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_sunset_feat
    goal       ["self", :use_end?]
  end

  class UseSunsetFeatEvent < EventRule
    dsc        "五彩晩霞を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_sunset_feat
    goal       ["self", :use_end?]
  end

  class UseSunsetFeatResultEvent < EventRule
    dsc        "五彩晩霞を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_sunset_feat_result
    goal       ["self", :use_end?]
  end

  class UseSunsetFeatDamageCheckEvent < EventRule
    dsc        "五彩晩霞を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_sunset_feat_damage_check
    goal       ["self", :use_end?]
  end

  class UseSunsetFeatConstDamageEvent < EventRule
    dsc        "五彩晩霞の直接ダメージ部分"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>10
    func       :use_sunset_feat_const_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 蔓縛り

  class CheckAddVineFeatEvent < EventRule
    dsc        "蔓縛りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_vine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveVineFeatEvent < EventRule
    dsc        "蔓縛りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_vine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateVineFeatEvent < EventRule
    dsc        "蔓縛りが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_vine_feat
    goal       ["self", :use_end?]
  end

  class UseVineFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_vine_feat
    goal       ["self", :use_end?]
  end

  class FinishVineFeatEvent < EventRule
    dsc        "蔓縛りの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_vine_feat
    goal       ["self", :use_end?]
  end

  class UseVineFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_vine_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishVineFeatTurnEvent < EventRule
    dsc        "蔓縛りの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_vine_feat_turn
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 吸収

  class CheckAddGrapeVineFeatEvent < EventRule
    dsc        "吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_grape_vine_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGrapeVineFeatEvent < EventRule
    dsc        "吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_grape_vine_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGrapeVineFeatEvent < EventRule
    dsc        "吸収が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_grape_vine_feat
    goal       ["self", :use_end?]
  end

  class UseGrapeVineFeatEvent < EventRule
    dsc        "吸収を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_grape_vine_feat
    goal       ["self", :use_end?]
  end

  class UseGrapeVineFeatDamageEvent < EventRule
    dsc        "吸収使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_grape_vine_feat_damage
    goal       ["self", :use_end?]
  end

  class UseGrapeVineFeatFoeEvent < EventRule
    dsc        "吸収の使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event, :priority=>40
    func       :use_grape_vine_feat_foe
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# サンダーストラック

  class CheckAddThunderStruckFeatEvent < EventRule
    dsc        "サンダーストラックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_thunder_struck_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThunderStruckFeatEvent < EventRule
    dsc        "サンダーストラックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_thunder_struck_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThunderStruckFeatEvent < EventRule
    dsc        "サンダーストラックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_thunder_struck_feat
    goal       ["self", :use_end?]
  end

  class UseThunderStruckFeatEvent < EventRule
    dsc        "サンダーストラックを使用 攻撃力にダメージを加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_thunder_struck_feat
    goal       ["self", :use_end?]
  end

  class FinishThunderStruckFeatEvent < EventRule
    dsc        "サンダーストラックの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>5
    func       :finish_thunder_struck_feat
    goal       ["self", :use_end?]
  end

  class FinishThunderStruckFeatEndEvent < EventRule
    dsc        "サンダーストラックの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase
    func       :finish_thunder_struck_feat_end
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ウィーヴワールド

  class CheckAddWeaveWorldFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_weave_world_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWeaveWorldFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_weave_world_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWeaveWorldFeatEvent < EventRule
    dsc        "深淵が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_weave_world_feat
    goal       ["self", :use_end?]
  end

  class UseWeaveWorldFeatEvent < EventRule
    dsc        "深淵を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_weave_world_feat
    goal       ["self", :use_end?]
  end

  class FinishWeaveWorldFeatEvent < EventRule
    dsc        "深淵の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_weave_world_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# コレクション

  class CheckAddCollectionFeatEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_collection_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCollectionFeatEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_collection_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCollectionFeatEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_collection_feat
    goal       ["self", :use_end?]
  end

  class CheckTableCollectionFeatMoveEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase
    func       :check_table_collection_feat_move
    goal       ["self", :use_end?]
  end

  class CheckTableCollectionFeatBattleEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :check_table_collection_feat_battle
    goal       ["self", :use_end?]
  end

  class UseCollectionFeatDealEvent < EventRule
    dsc        "コレクションを使用 相手の手札を1枚破棄"
    type       :type=>:before, :obj=>"duel", :hook=>:refill_event_card_phase
    func       :use_collection_feat_deal
    goal       ["self", :use_end?]
  end

  class UseCollectionFeatEvent < EventRule
    dsc        "コレクションを使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_collection_feat
    goal       ["self", :use_end?]
  end

  class FinishCollectionFeatEvent < EventRule
    dsc        "コレクションの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_collection_feat
    goal       ["self", :use_end?]
  end

  class CheckEndingCollectionFeatEvent < EventRule
    dsc        "コレクションが可能か"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :check_ending_collection_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Dリストリクション

  class CheckAddRestrictionFeatEvent < EventRule
    dsc        "リストリクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_restriction_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRestrictionFeatEvent < EventRule
    dsc        "リストリクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_restriction_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRestrictionFeatEvent < EventRule
    dsc        "リストリクションが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_restriction_feat
    goal       ["self", :use_end?]
  end

  class UseRestrictionFeatEvent < EventRule
    dsc        "リストリクションを使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_restriction_feat
    goal       ["self", :use_end?]
  end

  class FinishRestrictionFeatEvent < EventRule
    dsc        "リストリクションの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_restriction_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# DABS

  class CheckAddDabsFeatEvent < EventRule
    dsc        "DABSが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dabs_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDabsFeatEvent < EventRule
    dsc        "DABSが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dabs_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDabsFeatEvent < EventRule
    dsc        "DABSが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dabs_feat
    goal       ["self", :use_end?]
  end

  class UseDabsFeatEvent < EventRule
    dsc        "DABSを使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dabs_feat
    goal       ["self", :use_end?]
  end

  class FinishDabsFeatEvent < EventRule
    dsc        "DABSの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_dabs_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# VIBRATION

  class CheckAddVibrationFeatEvent < EventRule
    dsc        "VIBRATIONが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_vibration_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveVibrationFeatEvent < EventRule
    dsc        "VIBRATIONが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_vibration_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateVibrationFeatEvent < EventRule
    dsc        "VIBRATIONが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_vibration_feat
    goal       ["self", :use_end?]
  end

  class UseVibrationFeatEvent < EventRule
    dsc        "VIBRATIONを使用 相手の手札を1枚破棄"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_vibration_feat
    goal       ["self", :use_end?]
  end

  class FinishVibrationFeatEvent < EventRule
    dsc        "VIBRATIONの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_vibration_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# Trick or Treat

  class CheckAddTotFeatEvent < EventRule
    dsc        "ToTが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_tot_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTotFeatEvent < EventRule
    dsc        "ToTが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_tot_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTotFeatEvent < EventRule
    dsc        "ToTが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_tot_feat
    goal       ["self", :use_end?]
  end

  class UseTotFeatEvent < EventRule
    dsc        "ToTを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_tot_feat
    goal       ["self", :use_end?]
  end

  class UseTotFeatDamageEvent < EventRule
    dsc        "ToTを使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_tot_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishTotFeatEvent < EventRule
    dsc        "ToTの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_tot_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ダックアップル

  class CheckAddDuckAppleFeatEvent < EventRule
    dsc        "ダックアップルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_duck_apple_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDuckAppleFeatEvent < EventRule
    dsc        "ダックアップルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_duck_apple_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDuckAppleFeatEvent < EventRule
    dsc        "ダックアップルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_duck_apple_feat
    goal       ["self", :use_end?]
  end

  class FinishDuckAppleFeatEvent < EventRule
    dsc        "ダックアップルを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_duck_apple_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ランページ

  class CheckAddRampageFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_rampage_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRampageFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_rampage_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRampageFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_rampage_feat
    goal       ["self", :use_end?]
  end

  class UseRampageFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_rampage_feat
    goal       ["self", :use_end?]
  end

  class FinishRampageFeatEvent < EventRule
    dsc        "ランページの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_rampage_feat
    goal       ["self", :use_end?]
  end

  class UseRampageFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_rampage_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ランページ

  class CheckAddScratchFireFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_scratch_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveScratchFireFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_scratch_fire_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateScratchFireFeatEvent < EventRule
    dsc        "ランページが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_scratch_fire_feat
    goal       ["self", :use_end?]
  end

  class UseScratchFireFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_scratch_fire_feat
    goal       ["self", :use_end?]
  end

  class FinishScratchFireFeatEvent < EventRule
    dsc        "ランページの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_scratch_fire_feat
    goal       ["self", :use_end?]
  end

  class UseScratchFireFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_scratch_fire_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ブルールーイン

  class CheckAddBlueRuinFeatEvent < EventRule
    dsc        "ブルールーインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_blue_ruin_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBlueRuinFeatEvent < EventRule
    dsc        "ブルールーインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_blue_ruin_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBlueRuinFeatEvent < EventRule
    dsc        "ブルールーインが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_blue_ruin_feat
    goal       ["self", :use_end?]
  end

  class UseBlueRuinFeatEvent < EventRule
    dsc        "ブルールーインを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_blue_ruin_feat
    goal       ["self", :use_end?]
  end

  class FinishBlueRuinFeatEvent < EventRule
    dsc        "ブルールーインの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_blue_ruin_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ダメージ軽減

  class CheckAddThirdStepFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_third_step_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThirdStepFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_third_step_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThirdStepFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_third_step_feat
    goal       ["self", :use_end?]
  end

  class UseThirdStepFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_third_step_feat
    goal       ["self", :use_end?]
  end

  class UseThirdStepFeatDamageEvent < EventRule
    dsc        "必殺技が使用される"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :use_third_step_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishThirdStepFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_third_step_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# メタルシールド

  class CheckAddMetalShieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_metal_shield_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMetalShieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_metal_shield_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMetalShieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_metal_shield_feat
    goal       ["self", :use_end?]
  end

  class UseMetalShieldFeatEvent < EventRule
    dsc        "メタルシールドを使用 防御力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_metal_shield_feat
    goal       ["self", :use_end?]
  end

  class FinishMetalShieldFeatEvent < EventRule
    dsc        "メタルシールドの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_metal_shield_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 滞留する光波

  class CheckAddMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_magnetic_field_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_magnetic_field_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_magnetic_field_feat
    goal       ["self", :use_end?]
  end

  class UseMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドを使用 防御力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_magnetic_field_feat
    goal       ["self", :use_end?]
  end

  class FinishMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>4
    func       :finish_magnetic_field_feat
    goal       ["self", :use_end?]
  end

  class FinalMagneticFieldFeatEvent < EventRule
    dsc        "メタルシールドの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :final_magnetic_field_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 拒絶の余光

  class CheckAddAfterglowFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_afterglow_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAfterglowFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_afterglow_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAfterglowFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_afterglow_feat
    goal       ["self", :use_end?]
  end

  class UseAfterglowFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_afterglow_feat
    goal       ["self", :use_end?]
  end

  class UseAfterglowFeatDamageEvent < EventRule
    dsc        "必殺技が使用される"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>90
    func       :use_afterglow_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishAfterglowFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_afterglow_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 夕暉の番人

  class CheckAddKeeperFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_keeper_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKeeperFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_keeper_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKeeperFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_keeper_feat
    goal       ["self", :use_end?]
  end

  class UseKeeperFeatEvent < EventRule
    dsc        "必殺技を使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dice_attribute_regist_event
    func       :use_keeper_feat
    goal       ["self", :use_end?]
  end

  class FinishKeeperFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :finish_keeper_feat
    goal       ["self", :use_end?]
  end

  class FinishKeeperFeatDeadCharaChangeEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_keeper_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヒーリングショック

  class CheckAddHealingSchockFeatEvent < EventRule
    dsc        "ヒーリングショックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_healing_schock_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHealingSchockFeatEvent < EventRule
    dsc        "ヒーリングショックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_healing_schock_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHealingSchockFeatEvent < EventRule
    dsc        "ヒーリングショックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_healing_schock_feat
    goal       ["self", :use_end?]
  end

  class UseHealingSchockFeatEvent < EventRule
    dsc        "ヒーリングショックを使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_healing_schock_feat
    goal       ["self", :use_end?]
  end

  class FinishHealingSchockFeatEvent < EventRule
    dsc        "ヒーリングショックの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>99
    func       :finish_healing_schock_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クレイモア

  class CheckAddClaymoreFeatEvent < EventRule
    dsc        "クレイモアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_claymore_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveClaymoreFeatEvent < EventRule
    dsc        "クレイモアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_claymore_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateClaymoreFeatEvent < EventRule
    dsc        "クレイモアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_claymore_feat
    goal       ["self", :use_end?]
  end

  class FinishClaymoreFeatEvent < EventRule
    dsc        "クレイモアの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :finish_claymore_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# トラップチェイス

  class CheckAddTrapChaseFeatEvent < EventRule
    dsc        "トラップチェイスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_trap_chase_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTrapChaseFeatEvent < EventRule
    dsc        "トラップチェイスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_trap_chase_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTrapChaseFeatEvent < EventRule
    dsc        "トラップチェイスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_trap_chase_feat
    goal       ["self", :use_end?]
  end

  class UseTrapChaseFeatEvent < EventRule
    dsc        "トラップチェイスを使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_trap_chase_feat
    goal       ["self", :use_end?]
  end

  class UseTrapChaseFeatDamageEvent < EventRule
    dsc        "トラップチェイスを使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_trap_chase_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishTrapChaseFeatEvent < EventRule
    dsc        "トラップチェイスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_trap_chase_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# パニックグレネード

  class CheckAddPanicFeatEvent < EventRule
    dsc        "パニックグレネードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_panic_feat
    goal       ["self", :use_end?]
  end

  class CheckRemovePanicFeatEvent < EventRule
    dsc        "パニックグレネードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_panic_feat
    goal       ["self", :use_end?]
  end

  class CheckRotatePanicFeatEvent < EventRule
    dsc        "パニックグレネードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_panic_feat
    goal       ["self", :use_end?]
  end

  class UsePanicFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_panic_feat
    goal       ["self", :use_end?]
  end

  class FinishPanicFeatEvent < EventRule
    dsc        "パニックグレネードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_panic_feat
    goal       ["self", :use_end?]
  end

  class UsePanicFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_panic_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# バレットカウンター

  class CheckAddBulletCounterFeatEvent < EventRule
    dsc        "バレットカウンターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_bullet_counter_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBulletCounterFeatEvent < EventRule
    dsc        "バレットカウンターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_bullet_counter_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBulletCounterFeatEvent < EventRule
    dsc        "バレットカウンターが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_bullet_counter_feat
    goal       ["self", :use_end?]
  end

  class UseBulletCounterFeatEvent < EventRule
    dsc        "バレットカウンターを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_bullet_counter_feat
    goal       ["self", :use_end?]
  end

  class FinishBulletCounterFeatEvent < EventRule
    dsc        "バレットカウンターの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_bullet_counter_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 大菽嵐

  class CheckAddBeanStormFeatEvent < EventRule
    dsc        "大菽嵐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_bean_storm_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBeanStormFeatEvent < EventRule
    dsc        "大菽嵐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_bean_storm_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBeanStormFeatEvent < EventRule
    dsc        "大菽嵐が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_bean_storm_feat
    goal       ["self", :use_end?]
  end

  class UseBeanStormFeatEvent < EventRule
    dsc        "大菽嵐を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_bean_storm_feat
    goal       ["self", :use_end?]
  end

  class FinishBeanStormFeatEvent < EventRule
    dsc        "大菽嵐の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_bean_storm_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ジョーカー

  class CheckAddJokerFeatEvent < EventRule
    dsc        "ジョーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_joker_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveJokerFeatEvent < EventRule
    dsc        "ジョーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_joker_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateJokerFeatEvent < EventRule
    dsc        "ジョーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_joker_feat
    goal       ["self", :use_end?]
  end

  class FinishJokerFeatEvent < EventRule
    dsc        "ジョーカーの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>9
    func       :finish_joker_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ファミリア

  class CheckAddFamiliarFeatEvent < EventRule
    dsc        "ファミリアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_familiar_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFamiliarFeatEvent < EventRule
    dsc        "ファミリアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_familiar_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFamiliarFeatEvent < EventRule
    dsc        "ファミリアが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_familiar_feat
    goal       ["self", :use_end?]
  end

  class UseFamiliarFeatEvent < EventRule
    dsc        "ファミリアを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_familiar_feat
    goal       ["self", :use_end?]
  end

  class FinishFamiliarFeatEvent < EventRule
    dsc        "ファミリアの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :finish_familiar_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クラウンクラウン

  class CheckAddCrownCrownFeatEvent < EventRule
    dsc        "クラウンクラウンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_crown_crown_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCrownCrownFeatEvent < EventRule
    dsc        "クラウンクラウンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_crown_crown_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCrownCrownFeatEvent < EventRule
    dsc        "クラウンクラウンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_crown_crown_feat
    goal       ["self", :use_end?]
  end

  class UseCrownCrownFeatEvent < EventRule
    dsc        "クラウンクラウンを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_crown_crown_feat
    goal       ["self", :use_end?]
  end

  class UseCrownCrownFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>42
    func       :use_crown_crown_feat_damage
    goal       ["self", :use_end?]
  end


  class FinishCrownCrownFeatEvent < EventRule
    dsc        "クラウンクラウンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_crown_crown_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# リドルボックス

  class CheckAddRiddleBoxFeatEvent < EventRule
    dsc        "リドルボックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_riddle_box_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRiddleBoxFeatEvent < EventRule
    dsc        "リドルボックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_riddle_box_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRiddleBoxFeatEvent < EventRule
    dsc        "リドルボックスが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_riddle_box_feat
    goal       ["self", :use_end?]
  end

  class UseRiddleBoxFeatEvent < EventRule
    dsc        "リドルボックスを使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_riddle_box_feat
    goal       ["self", :use_end?]
  end

  class UseRiddleBoxFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>43
    func       :use_riddle_box_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishRiddleBoxFeatEvent < EventRule
    dsc        "リドルボックスの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_riddle_box_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 翻る剣舞

  class CheckAddFlutterSwordDanceFeatEvent < EventRule
    dsc        "翻る剣舞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_flutter_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFlutterSwordDanceFeatEvent < EventRule
    dsc        "翻る剣舞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_flutter_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFlutterSwordDanceFeatEvent < EventRule
    dsc        "翻る剣舞が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_flutter_sword_dance_feat
    goal       ["self", :use_end?]
  end

  class FinishFlutterSwordDanceFeatEvent < EventRule
    dsc        "翻る剣舞を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:alter_mp_event
    func       :finish_flutter_sword_dance_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 勇猛の儀

  class CheckAddRitualOfBraveryFeatEvent < EventRule
    dsc        "勇猛の儀が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_ritual_of_bravery_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveRitualOfBraveryFeatEvent < EventRule
    dsc        "勇猛の儀が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_ritual_of_bravery_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateRitualOfBraveryFeatEvent < EventRule
    dsc        "勇猛の儀が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_ritual_of_bravery_feat
    goal       ["self", :use_end?]
  end

  class UseRitualOfBraveryFeatEvent < EventRule
    dsc        "勇猛の儀を使用 攻撃力が+6"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_ritual_of_bravery_feat
    goal       ["self", :use_end?]
  end

  class FinishRitualOfBraveryFeatEvent < EventRule
    dsc        "勇猛の儀の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_ritual_of_bravery_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 狩猟豹の剣

  class CheckAddHuntingCheetahFeatEvent < EventRule
    dsc        "狩猟豹の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_hunting_cheetah_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHuntingCheetahFeatEvent < EventRule
    dsc        "狩猟豹の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_hunting_cheetah_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHuntingCheetahFeatEvent < EventRule
    dsc        "狩猟豹の剣が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_hunting_cheetah_feat
    goal       ["self", :use_end?]
  end

  class UseHuntingCheetahFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_hunting_cheetah_feat
    goal       ["self", :use_end?]
  end

  class FinishHuntingCheetahFeatEvent < EventRule
    dsc        "狩猟豹の剣の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_hunting_cheetah_feat
    goal       ["self", :use_end?]
  end

  class UseHuntingCheetahFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :use_hunting_cheetah_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 探りの一手

  class CheckAddProbeFeatEvent < EventRule
    dsc        "探りの一手可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_probe_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveProbeFeatEvent < EventRule
    dsc        "探りの一手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_probe_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateProbeFeatEvent < EventRule
    dsc        "探りの一手が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_probe_feat
    goal       ["self", :use_end?]
  end

  class UseProbeFeatEvent < EventRule
    dsc        "探りの一手を使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_probe_feat
    goal       ["self", :use_end?]
  end

  class UseProbeFeatPowEvent < EventRule
    dsc        "探りの一手を使用 防御力＋"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_probe_feat_pow
    goal       ["self", :use_end?]
  end

  class FinishProbeFeatEvent < EventRule
    dsc        "探りの一手の使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_probe_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 仕立

  class CheckAddTailoringFeatEvent < EventRule
    dsc        "仕立が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_tailoring_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTailoringFeatEvent < EventRule
    dsc        "仕立が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_tailoring_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTailoringFeatEvent < EventRule
    dsc        "仕立が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_tailoring_feat
    goal       ["self", :use_end?]
  end

  class UseTailoringFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_tailoring_feat
    goal       ["self", :use_end?]
  end

  class FinishTailoringFeatEvent < EventRule
    dsc        "仕立の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_tailoring_feat
    goal       ["self", :use_end?]
  end

  class UseTailoringFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_tailoring_feat_damage
    goal       ["self", :use_end?]
  end

#----------------c-----------------------------------------------------------------------------
# 裁断

  class CheckAddCutFeatEvent < EventRule
    dsc        "裁断が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_cut_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCutFeatEvent < EventRule
    dsc        "裁断が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_cut_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCutFeatEvent < EventRule
    dsc        "裁断が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_cut_feat
    goal       ["self", :use_end?]
  end

  class UseCutFeatEvent < EventRule
    dsc        "裁断を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_cut_feat
    goal       ["self", :use_end?]
  end

  class FinishCutFeatEvent < EventRule
    dsc        "裁断の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_cut_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 縫製

  class CheckAddSewingFeatEvent < EventRule
    dsc        "縫製が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_sewing_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSewingFeatEvent < EventRule
    dsc        "縫製が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_sewing_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSewingFeatEvent < EventRule
    dsc        "縫製が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_sewing_feat
    goal       ["self", :use_end?]
  end

  class UseSewingFeatEvent < EventRule
    dsc        "縫製を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_sewing_feat
    goal       ["self", :use_end?]
  end

  class FinishSewingFeatEvent < EventRule
    dsc        "縫製の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_sewing_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 破棄

  class CheckAddCancellationFeatEvent < EventRule
    dsc        "破棄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_cancellation_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCancellationFeatEvent < EventRule
    dsc        "破棄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_cancellation_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCancellationFeatEvent < EventRule
    dsc        "破棄が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_cancellation_feat
    goal       ["self", :use_end?]
  end

  class UseCancellationFeatEvent < EventRule
    dsc        "破棄を使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_cancellation_feat
    goal       ["self", :use_end?]
  end

  class FinishCancellationFeatEvent < EventRule
    dsc        "破棄の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_cancellation_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 整法

  class CheckAddSeihoFeatEvent < EventRule
    dsc        "整法が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_seiho_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSeihoFeatEvent < EventRule
    dsc        "整法が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_seiho_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSeihoFeatEvent < EventRule
    dsc        "整法が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_seiho_feat
    goal       ["self", :use_end?]
  end

  class UseSeihoFeatEvent < EventRule
    dsc        "整法を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_seiho_feat
    goal       ["self", :use_end?]
  end

  class FinishSeihoFeatEvent < EventRule
    dsc        "整法の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :finish_seiho_feat
    goal       ["self", :use_end?]
  end


#---------------------------------------------------------------------------------------------
# 独鈷

  class CheckAddDokkoFeatEvent < EventRule
    dsc        "独鈷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_dokko_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDokkoFeatEvent < EventRule
    dsc        "独鈷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_dokko_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDokkoFeatEvent < EventRule
    dsc        "独鈷が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_dokko_feat
    goal       ["self", :use_end?]
  end

  class UseDokkoFeatEvent < EventRule
    dsc        "独鈷を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_dokko_feat
    goal       ["self", :use_end?]
  end

  class UseDokkoFeatDamageEvent < EventRule
    dsc        "独鈷を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_dokko_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishDokkoFeatEvent < EventRule
    dsc        "独鈷の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_dokko_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 如意

  class CheckAddNyoiFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_nyoi_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveNyoiFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_nyoi_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateNyoiFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_nyoi_feat
    goal       ["self", :use_end?]
  end

  class UseNyoiFeatEvent < EventRule
    dsc        "如意を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_nyoi_feat
    goal       ["self", :use_end?]
  end

  class UseNyoiFeatDamageEvent < EventRule
    dsc        "如意を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_nyoi_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishNyoiFeatEvent < EventRule
    dsc        "如意の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_nyoi_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 金剛

  class CheckAddKongoFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_kongo_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveKongoFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_kongo_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateKongoFeatEvent < EventRule
    dsc        "必殺技が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_kongo_feat
    goal       ["self", :use_end?]
  end

  class UseKongoFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_kongo_feat
    goal       ["self", :use_end?]
  end

  class FinishKongoFeatEvent < EventRule
    dsc        "必殺技の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_kongo_feat
    goal       ["self", :use_end?]
  end

  class UseKongoFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>80
    func       :use_kongo_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 鯉震

  class CheckAddCarpQuakeFeatEvent < EventRule
    dsc        "鯉震が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_carp_quake_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCarpQuakeFeatEvent < EventRule
    dsc        "鯉震が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_carp_quake_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCarpQuakeFeatEvent < EventRule
    dsc        "鯉震が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_carp_quake_feat
    goal       ["self", :use_end?]
  end

  class FinishCarpQuakeFeatEvent < EventRule
    dsc        "鯉震を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_carp_quake_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 如意

  class CheckAddCarpLightningFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_carp_lightning_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCarpLightningFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_carp_lightning_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCarpLightningFeatEvent < EventRule
    dsc        "如意が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_carp_lightning_feat
    goal       ["self", :use_end?]
  end

  class UseCarpLightningFeatEvent < EventRule
    dsc        "如意を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_carp_lightning_feat
    goal       ["self", :use_end?]
  end

  class UseCarpLightningFeatDamageEvent < EventRule
    dsc        "如意を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_carp_lightning_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishCarpLightningFeatEvent < EventRule
    dsc        "如意の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_carp_lightning_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# フィールドロック

  class CheckAddFieldLockFeatEvent < EventRule
    dsc        "フィールドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_field_lock_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFieldLockFeatEvent < EventRule
    dsc        "フィールドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_field_lock_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFieldLockFeatEvent < EventRule
    dsc        "フィールドロックが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_field_lock_feat
    goal       ["self", :use_end?]
  end

  class UseFieldLockFeatEvent < EventRule
    dsc        "フィールドロックの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>7
    func       :use_field_lock_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 捕縛

  class CheckAddArrestFeatEvent < EventRule
    dsc        "捕縛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_arrest_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveArrestFeatEvent < EventRule
    dsc        "捕縛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_arrest_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateArrestFeatEvent < EventRule
    dsc        "捕縛が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_arrest_feat
    goal       ["self", :use_end?]
  end

  class UseArrestFeatEvent < EventRule
    dsc        "捕縛を使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_arrest_feat
    goal       ["self", :use_end?]
  end

  class UseArrestFeatDamageEvent < EventRule
    dsc        "捕縛使用時に上回った防御点をダメージとして相手に与える"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase
    func       :use_arrest_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishArrestFeatEvent < EventRule
    dsc        "捕縛の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_arrest_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# クイックドロー

  class CheckAddQuickDrawFeatEvent < EventRule
    dsc        "クイックドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_quick_draw_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveQuickDrawFeatEvent < EventRule
    dsc        "クイックドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_quick_draw_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateQuickDrawFeatEvent < EventRule
    dsc        "クイックドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_quick_draw_feat
    goal       ["self", :use_end?]
  end

  class UseQuickDrawFeatEvent < EventRule
    dsc        "クイックドローを使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_quick_draw_feat
    goal       ["self", :use_end?]
  end

  class FinishQuickDrawFeatEvent < EventRule
    dsc        "クイックドローの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_quick_draw_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ゲイズ

  class CheckAddGazeFeatEvent < EventRule
    dsc        "ゲイズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_gaze_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveGazeFeatEvent < EventRule
    dsc        "ゲイズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_gaze_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateGazeFeatEvent < EventRule
    dsc        "ゲイズが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_gaze_feat
    goal       ["self", :use_end?]
  end

  class UseGazeFeatEvent < EventRule
    dsc        "ゲイズを使用 墓地からカードを拾う"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_gaze_feat
    goal       ["self", :use_end?]
  end

  class FinishGazeFeatEvent < EventRule
    dsc        "ゲイズを使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_gaze_feat
    goal       ["self", :use_end?]
  end

  class FinishCharaChangeGazeFeatEvent < EventRule
    dsc        "ゲイズの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"owner", :hook=>:chara_change_action
    func       :finish_gaze_feat
    goal       ["self", :use_end?]
  end

  class FinishFoeCharaChangeGazeFeatEvent < EventRule
    dsc        "ゲイズの使用が終了(キャラチェンジ時)"
    type       :type=>:before, :obj=>"foe", :hook=>:chara_change_action
    func       :finish_gaze_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 監視

  class CheckAddMonitoringFeatEvent < EventRule
    dsc        "監視が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_monitoring_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMonitoringFeatEvent < EventRule
    dsc        "監視が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_monitoring_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMonitoringFeatEvent < EventRule
    dsc        "監視が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_monitoring_feat
    goal       ["self", :use_end?]
  end

  class UseMonitoringFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_monitoring_feat
    goal       ["self", :use_end?]
  end

  class FinishMonitoringFeatEvent < EventRule
    dsc        "監視の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_monitoring_feat
    goal       ["self", :use_end?]
  end

  class UseMonitoringFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :use_monitoring_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 時差ドロー

  class CheckAddTimeLagDrawFeatEvent < EventRule
    dsc        "時差ドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_time_lag_draw_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeLagDrawFeatEvent < EventRule
    dsc        "時差ドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_time_lag_draw_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeLagDrawFeatEvent < EventRule
    dsc        "時差ドローが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_time_lag_draw_feat
    goal       ["self", :use_end?]
  end

  class UseTimeLagDrawFeatEvent < EventRule
    dsc        "時差ドローを使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_time_lag_draw_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeLagDrawFeatEvent < EventRule
    dsc        "時差ドローの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_time_lag_draw_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 時差バフ

  class CheckAddTimeLagBuffFeatEvent < EventRule
    dsc        "時差バフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_time_lag_buff_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveTimeLagBuffFeatEvent < EventRule
    dsc        "時差バフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_time_lag_buff_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateTimeLagBuffFeatEvent < EventRule
    dsc        "時差バフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_time_lag_buff_feat
    goal       ["self", :use_end?]
  end

  class UseTimeLagBuffFeatEvent < EventRule
    dsc        "時差バフを使用 防御力が+3"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_time_lag_buff_feat
    goal       ["self", :use_end?]
  end

  class FinishTimeLagBuffFeatEvent < EventRule
    dsc        "時差バフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_time_lag_buff_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 移転

  class CheckAddDamageTransferFeatEvent < EventRule
    dsc        "移転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_damage_transfer_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDamageTransferFeatEvent < EventRule
    dsc        "移転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_damage_transfer_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDamageTransferFeatEvent < EventRule
    dsc        "移転が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_damage_transfer_feat
    goal       ["self", :use_end?]
  end

  class UseDamageTransferFeatEvent < EventRule
    dsc        "移転を使用 自分を特殊/2回復"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_damage_transfer_feat
    goal       ["self", :use_end?]
  end

  class FinishDamageTransferFeatEvent < EventRule
    dsc        "移転の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_damage_transfer_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# シガレット

  class CheckAddCigaretteFeatEvent < EventRule
    dsc        "シガレットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_cigarette_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCigaretteFeatEvent < EventRule
    dsc        "シガレットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_cigarette_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCigaretteFeatEvent < EventRule
    dsc        "シガレットが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_cigarette_feat
    goal       ["self", :use_end?]
  end

  class UseCigaretteFeatEvent < EventRule
    dsc        "シガレットを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_cigarette_feat
    goal       ["self", :use_end?]
  end

  class FinishCigaretteFeatEvent < EventRule
    dsc        "シガレットの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>50
    func       :finish_cigarette_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スリーカード

  class CheckAddThreeCardFeatEvent < EventRule
    dsc        "スリーカードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_three_card_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveThreeCardFeatEvent < EventRule
    dsc        "スリーカードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_three_card_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateThreeCardFeatEvent < EventRule
    dsc        "スリーカードが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_three_card_feat
    goal       ["self", :use_end?]
  end

  class UseThreeCardFeatEvent < EventRule
    dsc        "スリーカードを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_three_card_feat
    goal       ["self", :use_end?]
  end

  class FinishThreeCardFeatEvent < EventRule
    dsc        "スリーカードの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_three_card_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# カードサーチ

  class CheckAddCardSearchFeatEvent < EventRule
    dsc        "カードサーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_card_search_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveCardSearchFeatEvent < EventRule
    dsc        "カードサーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_card_search_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateCardSearchFeatEvent < EventRule
    dsc        "カードサーチが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_card_search_feat
    goal       ["self", :use_end?]
  end

  class FinishCardSearchFeatEvent < EventRule
    dsc        "カードサーチを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>10
    func       :finish_card_search_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# オールインワン

  class CheckAddAllInOneFeatEvent < EventRule
    dsc        "オールインワンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_all_in_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAllInOneFeatEvent < EventRule
    dsc        "オールインワンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_all_in_one_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAllInOneFeatEvent < EventRule
    dsc        "オールインワンが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_all_in_one_feat
    goal       ["self", :use_end?]
  end

  class UseAllInOneFeatPowerEvent < EventRule
    dsc        "オールインワンを使用 自分のカードを回転させる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_all_in_one_feat_power
    goal       ["self", :use_end?]
  end

  class UseAllInOneFeatEvent < EventRule
    dsc        "オールインワンを使用 自分のカードを回転させる"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :use_all_in_one_feat
    goal       ["self", :use_end?]
  end

  class FinishAllInOneFeatEvent < EventRule
    dsc        "オールインワンの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :finish_all_in_one_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 2016,9イベント

  class CheckEv201609PassiveEvent < EventRule
    dsc        "2016,6イベントをチェック"
    type       :type=>:before, :obj=>"duel", :hook=>:start_turn_phase
    func       :check_ev201609_passive
  end

  class CheckEv201609ChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_chara_change_phase
    func       :check_ev201609_passive
  end

  class CheckEv201609DeadChangePassiveEvent < EventRule
    dsc        "ダメージ乗算をチェック"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :check_ev201609_passive
  end

  class UseEv201609PassiveEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:after, :obj=>"foe", :hook=>:bp_calc_resolve, :priority=>15
    func       :use_ev201609_passive
  end

  class FinishEv201609PassiveEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_ev201609_passive
  end

  class FinishEv201609PassiveDeadCharaChangeEvent < EventRule
    dsc        "2016,6イベントを発動"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_dead_chara_change_phase
    func       :finish_ev201609_passive
  end

#---------------------------------------------------------------------------------------------
# 焼鳥

  class CheckAddFireBirdFeatEvent < EventRule
    dsc        "焼鳥が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_fire_bird_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFireBirdFeatEvent < EventRule
    dsc        "焼鳥が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_fire_bird_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFireBirdFeatEvent < EventRule
    dsc        "焼鳥が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_fire_bird_feat
    goal       ["self", :use_end?]
  end

  class UseFireBirdFeatEvent < EventRule
    dsc        "焼鳥を使用 防御＋"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_fire_bird_feat
    goal       ["self", :use_end?]
  end

  class UseAfterFireBirdFeatEvent < EventRule
    dsc        "焼鳥を使用 墓地からカードを拾う"
    type       :type=>:before, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :use_after_fire_bird_feat
    goal       ["self", :use_end?]
  end

  class FinishFireBirdFeatEvent < EventRule
    dsc        "焼鳥の使用が終了"
    type       :type=>:after, :obj=>"foe", :hook=>:battle_phase_init_event
    func       :finish_fire_bird_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 苔蔦

  class CheckAddBramblesFeatEvent < EventRule
    dsc        "苔蔦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_brambles_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveBramblesFeatEvent < EventRule
    dsc        "苔蔦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_brambles_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateBramblesFeatEvent < EventRule
    dsc        "苔蔦が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_brambles_feat
    goal       ["self", :use_end?]
  end

  class UseBramblesFeatEvent < EventRule
    dsc        "苔蔦の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :use_brambles_feat
    goal       ["self", :use_end?]
  end

  class UseBramblesFeatMoveBeforeEvent < EventRule
    dsc        "苔蔦の距離保存"
    type       :type=>:before, :obj=>"owner", :hook=>:move_action , :priority=>1
    func       :use_brambles_feat_move_before
    goal       ["self", :use_end?]
  end

  class UseBramblesFeatMoveAfterEvent < EventRule
    dsc        "苔蔦のダメージ付与"
    type       :type=>:after, :obj=>"owner", :hook=>:move_action, :priority=>1
    func       :use_brambles_feat_move_after
    goal       ["self", :use_end?]
  end

  class FinishBramblesFeatEvent < EventRule
    dsc        "苔蔦終了"
    type       :type=>:after, :obj=>"duel", :hook=>:finish_move_phase
    func       :finish_brambles_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# フランケンタックル

  class CheckAddFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_franken_tackle_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_franken_tackle_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_franken_tackle_feat
    goal       ["self", :use_end?]
  end

  class UseOwnerFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>10
    func       :use_franken_tackle_feat
    goal       ["self", :use_end?]
  end

  class UseFoeFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルを使用"
    type       :type=>:after, :obj=>"foe", :hook=>:dp_calc_resolve, :priority=>30
    func       :use_franken_tackle_feat
    goal       ["self", :use_end?]
  end

  class UseFrankenTackleFeatDiceAttrEvent < EventRule
    dsc        "フランケンタックルを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>60
    func       :use_franken_tackle_feat_dice_attr
    goal       ["self", :use_end?]
  end

  class FinishFrankenTackleFeatEvent < EventRule
    dsc        "フランケンタックルの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_franken_tackle_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# フランケン充電

  class CheckAddFrankenChargingFeatEvent < EventRule
    dsc        "フランケン充電が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_franken_charging_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFrankenChargingFeatEvent < EventRule
    dsc        "フランケン充電が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_franken_charging_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFrankenChargingFeatEvent < EventRule
    dsc        "フランケン充電が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_franken_charging_feat
    goal       ["self", :use_end?]
  end

  class UseFrankenChargingFeatEvent < EventRule
    dsc        "フランケン充電を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_franken_charging_feat
    goal       ["self", :use_end?]
  end

  class FinishFrankenChargingFeatEvent < EventRule
    dsc        "フランケン充電の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_franken_charging_feat
    goal       ["self", :use_end?]
  end

  class UseFrankenChargingFeatDamageEvent < EventRule
    dsc        "フランケン充電を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>20
    func       :use_franken_charging_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 挑みかかるものR

  class CheckAddMovingOneRFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_moving_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMovingOneRFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_moving_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMovingOneRFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_moving_one_r_feat
    goal       ["self", :use_end?]
  end

  class UseMovingOneRFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_moving_one_r_feat
    goal       ["self", :use_end?]
  end

  class UseMovingOneRFeatAttackEvent < EventRule
    dsc        "攻撃時"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve, :priority=>1
    func       :use_moving_one_r_feat_attack
    goal       ["self", :use_end?]
  end

  class UseMovingOneRFeatDefenseEvent < EventRule
    dsc        "防御時"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve, :priority=>1
    func       :use_moving_one_r_feat_defense
    goal       ["self", :use_end?]
  end

  class FinishMovingOneRFeatEvent < EventRule
    dsc        "移動上昇を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_moving_one_r_feat
    goal       ["self", :use_end?]
  end

  class FinishTurnMovingOneRFeatEvent < EventRule
    dsc        "移動上昇を使用"
    type       :type=>:before, :obj=>"duel", :hook=>:finish_turn_phase
    func       :finish_turn_moving_one_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 驕りたかぶるものR

  class CheckAddArrogantOneRFeatEvent < EventRule
    dsc        "驕りたかぶるものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_add_action
    func       :check_arrogant_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveArrogantOneRFeatEvent < EventRule
    dsc        "驕りたかぶるものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_remove_action
    func       :check_arrogant_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateArrogantOneRFeatEvent < EventRule
    dsc        "驕りたかぶるものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:deffence_card_rotate_action
    func       :check_arrogant_one_r_feat
    goal       ["self", :use_end?]
  end

  class UseArrogantOneRFeatEvent < EventRule
    dsc        "驕りたかぶるものRを使用 防御力が+"
    type       :type=>:after, :obj=>"owner", :hook=>:dp_calc_resolve
    func       :use_arrogant_one_r_feat
    goal       ["self", :use_end?]
  end

  class FinishArrogantOneRFeatEvent < EventRule
    dsc        "驕りたかぶるものRの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_arrogant_one_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 貪り食うものR

  class CheckAddEatingOneRFeatEvent < EventRule
    dsc        "貪り食うものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_eating_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveEatingOneRFeatEvent < EventRule
    dsc        "貪り食うものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_eating_one_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateEatingOneRFeatEvent < EventRule
    dsc        "貪り食うものRが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_eating_one_r_feat
    goal       ["self", :use_end?]
  end

  class UseEatingOneRFeatEvent < EventRule
    dsc        "貪り食うものRをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_eating_one_r_feat
    goal       ["self", :use_end?]
  end

  class FinishEatingOneRFeatEvent < EventRule
    dsc        "貪り食うものRの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_eating_one_r_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ハーフデッド
  class CheckAddHarfDeadFeatEvent < EventRule
    dsc        "ハーフデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_harf_dead_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHarfDeadFeatEvent < EventRule
    dsc        "ハーフデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_harf_dead_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHarfDeadFeatEvent < EventRule
    dsc        "ハーフデッドが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_harf_dead_feat
    goal       ["self", :use_end?]
  end

  class UseHarfDeadFeatEvent < EventRule
    dsc        "ハーフデッドを使用"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :use_harf_dead_feat
    goal       ["self", :use_end?]
  end

  class FinishHarfDeadFeatEvent < EventRule
    dsc        "ハーフデッドを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase, :priority=>8
    func       :finish_harf_dead_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# マシンセル

  class CheckAddMachineCellFeatEvent < EventRule
    dsc        "マシンセルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_machine_cell_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveMachineCellFeatEvent < EventRule
    dsc        "マシンセルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_machine_cell_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateMachineCellFeatEvent < EventRule
    dsc        "マシンセルが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_machine_cell_feat
    goal       ["self", :use_end?]
  end

  class FinishMachineCellFeatEvent < EventRule
    dsc        "マシンセルを使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_machine_cell_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# ヒートシーカー R

  class CheckAddHeatSeekerRFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_heat_seeker_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveHeatSeekerRFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_heat_seeker_r_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateHeatSeekerRFeatEvent < EventRule
    dsc        "ヒートシーカーが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_heat_seeker_r_feat
    goal       ["self", :use_end?]
  end

  class UseHeatSeekerRFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>5
    func       :use_heat_seeker_r_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishHeatSeekerRFeatDamageEvent < EventRule
    dsc        "追加効果が有効になる"
    type       :type=>:before, :obj=>"owner", :hook=>:dice_attribute_regist_event
    func       :finish_heat_seeker_r_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 指向性エネルギー兵器

  class CheckAddDirectionalBeamFeatEvent < EventRule
    dsc        "指向性エネルギー兵器が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_directional_beam_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDirectionalBeamFeatEvent < EventRule
    dsc        "指向性エネルギー兵器が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_directional_beam_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDirectionalBeamFeatEvent < EventRule
    dsc        "指向性エネルギー兵器が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_directional_beam_feat
    goal       ["self", :use_end?]
  end

  class UseDirectionalBeamFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_directional_beam_feat
    goal       ["self", :use_end?]
  end

  class FinishDirectionalBeamFeatEvent < EventRule
    dsc        "指向性エネルギー兵器の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_directional_beam_feat
    goal       ["self", :use_end?]
  end

  class UseDirectionalBeamFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_directional_beam_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# デルタ

  class CheckAddDeltaFeatEvent < EventRule
    dsc        "デルタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_delta_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveDeltaFeatEvent < EventRule
    dsc        "デルタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_delta_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateDeltaFeatEvent < EventRule
    dsc        "デルタが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_delta_feat
    goal       ["self", :use_end?]
  end

  class UseDeltaFeatEvent < EventRule
    dsc        "デルタを使用"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_delta_feat
    goal       ["self", :use_end?]
  end


  class FinishDeltaFeatEvent < EventRule
    dsc        "デルタの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>25
    func       :finish_delta_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# シグマ

  class CheckAddSigmaFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_sigma_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveSigmaFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_sigma_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateSigmaFeatEvent < EventRule
    dsc        "ブラストオフが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_sigma_feat
    goal       ["self", :use_end?]
  end

  class UseSigmaFeatEvent < EventRule
    dsc        "ブラストオフをを使用 攻撃力が+2、攻撃終了時に近距離になる"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_sigma_feat
    goal       ["self", :use_end?]
  end

  class ExSigma0FeatEvent < EventRule
    dsc        "ブラストオフの使用が終了"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>5
    func       :ex_sigma0_feat
    goal       ["self", :use_end?]
  end

  class ExSigmaFeatEvent < EventRule
    dsc        "ブラストオフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :ex_sigma_feat
    goal       ["self", :use_end?]
  end

  class FinishSigmaFeatEvent < EventRule
    dsc        "ブラストオフの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>20
    func       :finish_sigma_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# スタンプ

  class CheckAddStampFeatEvent < EventRule
    dsc        "スタンプが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_stamp_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveStampFeatEvent < EventRule
    dsc        "スタンプが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_stamp_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateStampFeatEvent < EventRule
    dsc        "スタンプが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_stamp_feat
    goal       ["self", :use_end?]
  end

  class UseStampFeatEvent < EventRule
    dsc        "スタンプを使用 攻撃力が+2"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_stamp_feat
    goal       ["self", :use_end?]
  end

  class FinishStampFeatEvent < EventRule
    dsc        "スタンプの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_stamp_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# アクセラレーション

  class CheckAddAccelerationFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_add_action
    func       :check_acceleration_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAccelerationFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_remove_action
    func       :check_acceleration_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAccelerationFeatEvent < EventRule
    dsc        "移動上昇が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:move_card_rotate_action
    func       :check_acceleration_feat
    goal       ["self", :use_end?]
  end

  class UseAccelerationFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:after, :obj=>"owner", :hook=>:mp_calc_resolve
    func       :use_acceleration_feat
    goal       ["self", :use_end?]
  end

  class FinishAccelerationFeatEvent < EventRule
    dsc        "移動上昇を使用"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_move_phase
    func       :finish_acceleration_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# FOAB

  class CheckAddFoabFeatEvent < EventRule
    dsc        "FOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_foab_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveFoabFeatEvent < EventRule
    dsc        "FOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_foab_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateFoabFeatEvent < EventRule
    dsc        "FOABが可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_foab_feat
    goal       ["self", :use_end?]
  end

  class UseFoabFeatEvent < EventRule
    dsc        "FOABを使用 相手に特殊/2のダメージ"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_foab_feat
    goal       ["self", :use_end?]
  end

  class FinishFoabFeatEvent < EventRule
    dsc        "FOABの使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>1
    func       :finish_foab_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 白き玉桂

  class CheckAddWhiteMoonFeatEvent < EventRule
    dsc        "白き玉桂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_white_moon_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveWhiteMoonFeatEvent < EventRule
    dsc        "白き玉桂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_white_moon_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateWhiteMoonFeatEvent < EventRule
    dsc        "白き玉桂が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_white_moon_feat
    goal       ["self", :use_end?]
  end

  class UseWhiteMoonFeatEvent < EventRule
    dsc        "白き玉桂を使用 攻撃力が+3 ダメージの分だけ、相手は手札をランダムに失う"
    type       :type=>:after, :obj=>"owner", :hook=>:bp_calc_resolve
    func       :use_white_moon_feat
    goal       ["self", :use_end?]
  end

  class UseWhiteMoonFeatDiceAttrEvent < EventRule
    dsc        "白き玉桂を使用"
    type       :type=>:after, :obj=>"owner", :hook=>:dice_attribute_regist_event, :priority=>80
    func       :use_white_moon_feat_dice_attr
    goal       ["self", :use_end?]
  end

  class UseWhiteMoonFeatDamageEvent < EventRule
    dsc        "白き玉桂を使用時に手札をランダムに失わせる"
    type       :type=>:before, :obj=>"duel", :hook=>:damage_phase, :priority=>100
    func       :use_white_moon_feat_damage
    goal       ["self", :use_end?]
  end

  class FinishWhiteMoonFeatEvent < EventRule
    dsc        "白き玉桂の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_white_moon_feat
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 憤怒の背中

  class CheckAddAngerBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_add_action
    func       :check_anger_back_feat
    goal       ["self", :use_end?]
  end

  class CheckRemoveAngerBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_remove_action
    func       :check_anger_back_feat
    goal       ["self", :use_end?]
  end

  class CheckRotateAngerBackFeatEvent < EventRule
    dsc        "静謐な背中が可能か"
    type       :type=>:after, :obj=>"owner", :hook=>:attack_card_rotate_action
    func       :check_anger_back_feat
    goal       ["self", :use_end?]
  end

  class UseAngerBackFeatEvent < EventRule
    dsc        "攻撃力を加算"
    type       :type=>:before, :obj=>"duel", :hook=>:determine_battle_point_phase, :priority=>5
    func       :use_anger_back_feat
    goal       ["self", :use_end?]
  end

  class FinishAngerBackFeatEvent < EventRule
    dsc        "静謐な背中の使用が終了"
    type       :type=>:after, :obj=>"duel", :hook=>:determine_battle_point_phase
    func       :finish_anger_back_feat
    goal       ["self", :use_end?]
  end

  class UseAngerBackFeatDamageEvent < EventRule
    dsc        "ダメージ時に追加効果が有効になる"
    type       :type=>:after, :obj=>"duel", :hook=>:battle_result_phase, :priority=>40
    func       :use_anger_back_feat_damage
    goal       ["self", :use_end?]
  end

#---------------------------------------------------------------------------------------------
# 汎用

  class UseFeatEvent < EventRule
    dsc        "必殺技が使用された"
    func       :use_feat
    event      :finish
  end

  class UsePassiveEvent < EventRule
    dsc        "パッシブが使用された"
    func       :use_passive
    event      :finish
  end

  class ChangeCharaCardEvent < EventRule
    dsc        "キャラカード交換"
    func       :change_chara_card
    event      :finish
  end

  class OnFeatEvent < EventRule
    dsc        "必殺技がON"
    func       :on_feat
    event      :finish
  end

  class OffFeatEvent < EventRule
    dsc        "必殺技がOFF"
    func       :off_feat
    event      :finish
  end

  class ChangeFeatEvent < EventRule
    dsc        "必殺技変更"
    func       :change_feat
    event      :finish
  end

  class OnTransformEvent < EventRule
    dsc        "キャラカードが変身"
    func       :on_transform
    event      :finish
  end

  class OffTransformEvent < EventRule
    dsc        "キャラカードが通常に戻る"
    func       :off_transform
    event      :finish
  end

  class OnLostInTheFogEvent < EventRule
    dsc        "霧隠れする"
    func       :on_lost_in_the_fog
    event      :finish
  end

  class OffLostInTheFogEvent < EventRule
    dsc        "霧隠れ解除"
    func       :off_lost_in_the_fog
    event      :finish
  end

  class InTheFogEvent < EventRule
    dsc        "霧隠れに対する有効範囲表示"
    func       :in_the_fog
    event      :finish
  end

  class OpenTrapEvent < EventRule
    dsc        "罠が発動する"
    func       :open_trap
    event      :finish
  end

  class UpdateFeatConditionEvent < EventRule
    dsc        "技の発動条件を更新する"
    func       :update_feat_condition
    event      :finish
  end



end
