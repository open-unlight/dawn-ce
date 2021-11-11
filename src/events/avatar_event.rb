# frozen_string_literal: true

module Unlight
  class AvatarEvent < BaseEvent
    def initialize(avatar)
      @avatar = avatar
      create_context # コンテクストの作成
      super
    end

    # 行動力を使用する(返値：新しい行動値)
    def use_energy(r = true)
      @avatar.refresh if r
      [@avatar.energy, @avatar.get_next_recovery_time(r)]
    end
    regist_event UseEnergyEvent

    def use_free_duel_count(r = true)
      @avatar.refresh if r
      @avatar.free_duel_count
    end
    regist_event UseFreeDuelCountEvent

    # 残り時間の更新
    def update_remain_time(i, r = true)
      @avatar.refresh if r
      [@avatar.energy, i.to_i]
    end
    regist_event UpdateRemainTimeEvent

    def update_energy_max
      @avatar.energy_max
    end
    regist_event UpdateEnergyMaxEvent

    # 経験値獲得(返値:新しい経験値)
    def get_exp
      @avatar.exp
    end
    regist_event GetExpEvent

    # レベルアップ(返値:新しいレベル)
    def level_up
      @avatar.level
    end
    regist_event LevelUpEvent

    # デッキ経験値獲得(返値:新しい経験値)
    def get_deck_exp
      @avatar.duel_deck.exp
    end
    regist_event GetDeckExpEvent

    # デッキレベルアップ(返値:新しいレベル)
    def deck_level_up
      @avatar.duel_deck.level
    end
    regist_event DeckLevelUpEvent

    # Gemの更新(返値:新しい合計ジェム)
    def update_gems
      @avatar.gems
    end
    regist_event UpdateGemsEvent

    # 勝敗の更新
    def update_result
      [@avatar.point, @avatar.win, @avatar.lose, @avatar.draw]
    end
    regist_event UpdateResultEvent

    # AP回復間隔の更新
    def update_recovery_interval
      @avatar.recovery_interval
    end
    regist_event UpdateRecoveryIntervalEvent

    # クエスト所持数MAXの更新
    def update_quest_inventory_max
      @avatar.quest_inventory_max
    end
    regist_event UpdateQuestInventoryMaxEvent

    # クエスト所持数MAXの更新
    def update_exp_pow
      @avatar.exp_pow
    end
    regist_event UpdateExpPowEvent

    # クエスト所持数MAXの更新
    def update_gem_pow
      @avatar.gem_pow
    end
    regist_event UpdateGemPowEvent

    # クエスト所持数MAXの更新
    def update_quest_find_pow
      @avatar.quest_find_pow
    end
    regist_event UpdateQuestFindPowEvent

    # クエストポイントのアップデート
    def update_quest_point
      @avatar.quest_point
    end
    regist_event UpdateQuestPointEvent

    # パーツが捨てられた
    def vanish_part(inv_id, alert = true)
      [inv_id, alert]
    end
    regist_event VanishPartEvent

    # アイテムゲット
    def item_get(inv, item_id)
      [inv, item_id]
    end
    regist_event ItemGetEvent

    # デッキゲット
    def deck_get(n, k, l, e, s, c, mc, cards)
      [n, k, l, e, s, c, mc, cards]
    end
    regist_event DeckGetEvent

    # アイテムを使用した
    def item_use(inv)
      inv
    end
    regist_event ItemUseEvent

    # コインを使用した
    def coin_use(inv)
      inv
    end
    regist_event CoinUseEvent

    # パーツゲット
    def part_get(inv, part_id)
      [inv, part_id]
    end
    regist_event PartGetEvent

    # スロットカードゲット
    def slot_card_get(inv, kind, card_id)
      [inv, kind, card_id]
    end
    regist_event SlotCardGetEvent

    # キャラカードゲット
    def chara_card_get(inv, card_id)
      [inv, card_id]
    end
    regist_event CharaCardGetEvent

    # クエストゲット
    def quest_get(inv, quest_id, timer, pow = 100, quest_state = QS_NEW, ba_name = QUEST_PRESENT_AVATAR_NAME_NIL)
      [inv, quest_id, timer, pow, quest_state, ba_name]
    end
    regist_event QuestGetEvent

    # クエスト状態更新
    def quest_state_update(inv, state, map_id)
      [inv, state, map_id]
    end
    regist_event QuestStateUpdateEvent

    # クエスト状態更新
    def quest_progress_update(inv, progress)
      [inv, progress]
    end
    regist_event QuestProgressUpdateEvent

    # クエストデッキ状態更新
    def quest_deck_state_update(deck_index, state, hp0, hp1, hp2)
      [deck_index, state, hp0, hp1, hp2]
    end
    regist_event QuestDeckStateUpdateEvent

    # クエスト消去
    def quest_deleted(inv)
      inv
    end
    regist_event QuestDeletedEvent

    # クエストフラグアップデート
    def quest_flag_update(flag)
      flag
    end
    regist_event QuestFlagUpdateEvent

    # By_K2
    def floor_count_update(floor)
      floor
    end
    regist_event FloorCountUpdateEvent

    # クエストフラグアップデート
    def quest_clear_num_update(clearNum)
      clearNum
    end
    regist_event QuestClearNumUpdateEvent

    def quest_find_at_update(inv, t)
      [inv, t]
    end
    regist_event QuestFindAtUpdateEvent

    # イベントクエストフラグアップデート
    def event_quest_flag_update(quest_type, flag)
      [quest_type, flag]
    end
    regist_event EventQuestFlagUpdateEvent

    # イベントクエスト達成度アップデート
    def event_quest_clear_num_update(quest_type, clear_num)
      [quest_type, clear_num]
    end
    regist_event EventQuestClearNumUpdateEvent

    # フレンド数MAXのUPDATE
    def update_friend_max
      @avatar.friend_max
    end
    regist_event UpdateFriendMaxEvent

    # パーツ数MAXのUPDATE
    def update_part_max
      @avatar.part_inventory_max
    end
    regist_event UpdatePartMaxEvent

    # クエストで宝物をケットイベント
    def get_quest_treasure(type, no, num)
      [type, no, num]
    end
    regist_event GetQuestTreasureEvent

    # アチーブメントクリアイベント
    def achievement_clear(a_id, i_type, i_id, i_num, c_type)
      [a_id, i_type, i_id, i_num, c_type]
    end
    regist_event AchievementClearEvent

    # アチーブメント追加イベント
    def add_new_achievement(a_id)
      SERVER_LOG.info("<UID:#{@avatar.player_id}>Avatar: [add_new_achievement] ID: #{a_id}")
      a_id
    end
    regist_event AddNewAchievementEvent

    # アチーブメント削除イベント
    def delete_achievement(a_id)
      SERVER_LOG.info("<UID:#{@avatar.player_id}>Avatar: [delete_achievement] ID: #{a_id}")
      a_id
    end
    regist_event DeleteAchievementEvent

    def start_sale(sale_type, remain_time)
      [sale_type, remain_time]
    end
    regist_event StartSaleEvent

    def Avatar.null_info_set; end

    # アチーブメント情報更新イベント
    def update_achievement_info(achievements, achievements_state, achievements_progress, achievements_end_at, achievements_code)
      [achievements, achievements_state, achievements_progress, achievements_end_at, achievements_code]
    end
    regist_event UpdateAchievementInfoEvent

    # アチーブメント完全削除イベント
    def drop_achievement(a_id)
      a_id
    end
    regist_event DropAchievementEvent

    # 渦を取得した
    def send_profound_info(data_id, hash, close_at, created_at, state, map_id, pos_idx, copy_type, set_defeat_reward, now_damage, finder_id, finder_name, inv_id, prof_id, deck_id, cc_dmg_1, cc_dmg_2, cc_dmg_3, dmg_cnt, inv_state, deck_status)
      [data_id, hash, close_at, created_at, state, map_id, pos_idx, copy_type, set_defeat_reward, now_damage, finder_id, finder_name, inv_id, prof_id, deck_id, cc_dmg_1, cc_dmg_2, cc_dmg_3, dmg_cnt, inv_state, deck_status]
    end
    regist_event SendProfoundInfoEvent

    # 渦インベントリ情報を再送信
    def resend_profound_inventory(data_id, hash, close_at, state, map_id, pos_idx, inv_id, prof_id, deck_id, cc_dmg_1, cc_dmg_2, cc_dmg_3, dmg_cnt, inv_state)
      [data_id, hash, close_at, state, map_id, pos_idx, inv_id, prof_id, deck_id, cc_dmg_1, cc_dmg_2, cc_dmg_3, dmg_cnt, inv_state]
    end
    regist_event ResendProfoundInventoryEvent

    # 渦インベントリ情報再送信完了
    def resend_profound_inventory_finish; end
    regist_event ResendProfoundInventoryFinishEvent

    # お気に入りキャラを変更
    def change_favorite_chara_id(chara_id)
      chara_id
    end
    regist_event ChangeFavoriteCharaIdEvent

    # 合成武器情報を更新
    def update_combine_weapon_data(inv_id, card_id, base_sap, base_sdp, base_aap, base_adp, base_max, add_sap, add_sdp, add_aap, add_adp, add_max, passive_id, restriction, cnt_str, cnt_max_str, level, exp, psv_num_max, passive_pass, vani_psv_ids = '')
      SERVER_LOG.info("<UID:#{@avatar.player_id}>#{Dawn::Server.name}: [#{__method__}] id:#{inv_id} card_id:#{card_id}")
      [inv_id, card_id, base_sap, base_sdp, base_aap, base_adp, base_max, add_sap, add_sdp, add_aap, add_adp, add_max, passive_id, restriction, cnt_str, cnt_max_str, level, exp, psv_num_max, passive_pass, vani_psv_ids]
    end
    regist_event UpdateCombineWeaponDataEvent
  end
end
