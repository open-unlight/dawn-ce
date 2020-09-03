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

  # ===========================
  # イベント定義
  # ===========================

  class UseEnergyEvent < EventRule
    dsc       "行動力使用"
    func      :use_energy
    event     :finish
  end

  class UseFreeDuelCountEvent < EventRule
    dsc       "フリーデュエル使用"
    func      :use_free_duel_count
    event     :finish
  end

  class UpdateEnergyMaxEvent < EventRule
    dsc       "行動力MAXの更新"
    func      :update_energy_max
    event     :finish
  end

  class UpdateRemainTimeEvent < EventRule
    dsc       "残りアップデート時間の更新"
    func      :update_remain_time
    event     :finish
  end

  class GetExpEvent < EventRule
    dsc       "経験値獲得"
    func      :get_exp
    event     :finish
  end

  class LevelUpEvent < EventRule
    dsc       "レベルアップ"
    func      :level_up
    event     :finish
  end

  class GetDeckExpEvent < EventRule
    dsc       "デッキ経験値獲得"
    func      :get_deck_exp
    event     :finish
  end

  class DeckLevelUpEvent < EventRule
    dsc       "デッキレベルアップ"
    func      :deck_level_up
    event     :finish
  end

  class UpdateGemsEvent < EventRule
    dsc       "ジェムを獲得"
    func      :update_gems
    event     :finish
  end

  class UpdateResultEvent < EventRule
    dsc       "勝敗を更新"
    func      :update_result
    event     :finish
  end


  class ItemGetEvent < EventRule
    dsc       "アイテムを取得"
    func      :item_get
    event     :finish
  end

  class ItemUseEvent < EventRule
    dsc       "アイテムを使用した"
    func      :item_use
    event     :finish
  end

  class CoinUseEvent < EventRule
    dsc       "コインを使用した"
    func      :coin_use
    event     :finish
  end

  class PartGetEvent < EventRule
    dsc      "パーツを取得"
    func      :part_get
    event     :finish
  end

  class SlotCardGetEvent < EventRule
    dsc      "スロットカードをを取得"
    func      :slot_card_get
    event     :finish
  end

  class CharaCardGetEvent < EventRule
    dsc      "キャラカードをを取得"
    func      :chara_card_get
    event     :finish
  end

  class QuestGetEvent < EventRule
    dsc      "クエストを取得"
    func      :quest_get
    event     :finish
  end

  class QuestStateUpdateEvent < EventRule
    dsc      "クエストの状態をUPDATE"
    func      :quest_state_update
    event     :finish
  end

  class QuestDeletedEvent < EventRule
    dsc      "クエストを消去"
    func      :quest_deleted
    event     :finish
  end

  class QuestProgressUpdateEvent < EventRule
    dsc      "クエスト進行状態をUPDATE"
    func      :quest_progress_update
    event     :finish
  end

  class QuestDeckStateUpdateEvent < EventRule
    dsc      "クエストデッキの状態をUPDATE"
    func      :quest_deck_state_update
    event     :finish
  end

  class QuestFlagUpdateEvent < EventRule
    dsc      "クエスト進行度をUPDATE"
    func      :quest_flag_update
    event     :finish
  end

  # By_K2
  class FloorCountUpdateEvent < EventRule
    dsc      "FloorCountUPDATE"
    func      :floor_count_update
    event     :finish
  end

  class QuestClearNumUpdateEvent < EventRule
    dsc      "クエスト達成度をUPDATE"
    func      :quest_clear_num_update
    event     :finish
  end

  class QuestFindAtUpdateEvent < EventRule
    dsc      "クエスト探索時間をUPDATE"
    func      :quest_find_at_update
    event     :finish
  end

  class EventQuestFlagUpdateEvent < EventRule
    dsc      "イベントクエスト進行度をUPDATE"
    func      :event_quest_flag_update
    event     :finish
  end

  class EventQuestClearNumUpdateEvent < EventRule
    dsc      "イベントクエスト達成度をUPDATE"
    func      :event_quest_clear_num_update
    event     :finish
  end

  class UpdateFriendMaxEvent < EventRule
    dsc       "フレンド数MAXの更新"
    func      :update_friend_max
    event     :finish
  end

  class UpdatePartMaxEvent < EventRule
    dsc       "パーツ数MAXの更新"
    func      :update_part_max
    event     :finish
  end

  class GetQuestTreasureEvent < EventRule
    dsc       "クエスト宝箱をゲット"
    func      :get_quest_treasure
    event     :finish
  end

  class UpdateRecoveryIntervalEvent < EventRule
    dsc       "AP回復間隔の更新"
    func      :update_recovery_interval
    event     :finish
  end

  class UpdateQuestInventoryMaxEvent < EventRule
    dsc       "クエスト所持数MAXの更新"
    func      :update_quest_inventory_max
    event     :finish
  end

  class UpdateExpPowEvent < EventRule
    dsc       "EXPボーナス係数の更新"
    func      :update_exp_pow
    event     :finish
  end

  class UpdateGemPowEvent < EventRule
    dsc       "GEMボーナス係数の更新"
    func      :update_gem_pow
    event     :finish
  end

  class UpdateQuestFindPowEvent < EventRule
    dsc       "QUEST探し出す係数の更新"
    func      :update_quest_find_pow
    event     :finish
  end

  class UpdateQuestPointEvent < EventRule
    dsc       "QUESTポイントの更新"
    func      :update_quest_point
    event     :finish
  end

  class VanishPartEvent < EventRule
    dsc       "パーツ消滅イベント"
    func      :vanish_part
    event     :finish
  end

  class AchievementClearEvent < EventRule
    dsc       "アチーブメントクリアイベント"
    func      :achievement_clear
    event     :finish
  end

  class AddNewAchievementEvent < EventRule
    dsc       "アチーブメントクリアイベント"
    func      :add_new_achievement
    event     :finish
  end

  class DeleteAchievementEvent < EventRule
    dsc       "アチーブメント削除イベント"
    func      :delete_achievement
    event     :finish
  end

  class UpdateRankEvent < EventRule
    dsc       "ランクの更新"
    func      :update_rank
    event     :finish
  end

  class StartSaleEvent < EventRule
    dsc       "セール開始"
    func      :start_sale
    event     :finish
  end

  class DeckGetEvent < EventRule
    dsc       "デッキを取得"
    func      :deck_get
    event     :finish
  end

  class UpdateAchievementInfoEvent < EventRule
    dsc       "アチーブメントの更新"
    func      :update_achievement_info
    event     :finish
  end

  class DropAchievementEvent < EventRule
    dsc       "アチーブメント完全削除イベント"
    func      :drop_achievement
    event     :finish
  end

  class SendProfoundInfoEvent < EventRule
    dsc       "渦を取得"
    func      :send_profound_info
    event     :finish
  end

  class ResendProfoundInventoryEvent < EventRule
    dsc       "渦インベントリを再送信"
    func      :resend_profound_inventory
    event     :finish
  end

  class ResendProfoundInventoryFinishEvent < EventRule
    dsc       "渦インベントリ再送信完了"
    func      :resend_profound_inventory_finish
    event     :finish
  end

  class ChangeFavoriteCharaIdEvent < EventRule
    dsc       "お気に入りキャラを変更"
    func      :change_favorite_chara_id
    event     :finish
  end

  class UpdateCombineWeaponDataEvent < EventRule
    dsc      "合成武器情報を更新"
    func      :update_combine_weapon_data
    event     :finish
  end

end

