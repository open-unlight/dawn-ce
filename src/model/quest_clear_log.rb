# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # クジのログ
  class QuestClearLog < Sequel::Model
    # ポイントの倍数
    VALUE = [0, 3, 1.5, 1]

    # 他クラスのアソシエーション
    many_to_one :avatar # アバターを持つ
    many_to_one :avatar_quest_inventory, key: :quest_inventory_id # アバターを持つ

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    validates do
    end

    # 時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def QuestClearLog::create_log(a_id, q_iv, f_p, r, server_type, floor_count = 0) # By_K2 (무한의탑인 경우 층수 기록)
      ret = 0
      QuestClearLog.new do |i|
        aqi = AvatarQuestInventory[q_iv]
        if aqi
          d_i = aqi.deck_index
          i.avatar_id = a_id
          i.quest_inventory_id = q_iv

          i.chara_card_id_0 = i.avatar.chara_card_decks[d_i].cards_id[0] if i.avatar.chara_card_decks[d_i]
          i.chara_card_id_1 = i.avatar.chara_card_decks[d_i].cards_id[1] if i.avatar.chara_card_decks[d_i]
          i.chara_card_id_2 = i.avatar.chara_card_decks[d_i].cards_id[2] if i.avatar.chara_card_decks[d_i]
          c_0 = 0
          c_1 = 0
          c_2 = 0
          c_0 = i.avatar.chara_card_decks[d_i].cards_id[0] if i.avatar.chara_card_decks[d_i]
          c_1 = i.avatar.chara_card_decks[d_i].cards_id[1] if i.avatar.chara_card_decks[d_i]
          c_2 = i.avatar.chara_card_decks[d_i].cards_id[2] if i.avatar.chara_card_decks[d_i]

          i.finish_point = f_p
          i.result = r
          i.server_type = server_type

          num = i.avatar.chara_card_decks[aqi.deck_index].cards.size
          # Duel勝利時か、マップの先端に行き着いた場合
          if (r == RESULT_WIN || r == RESULT_DEAD_END) && VALUE[num]
            i.quest_point = (aqi.quest.difficulty * VALUE[num]).to_i
            qp = (aqi.quest.difficulty * VALUE[num]).to_i
          else
            i.quest_point = 0
            qp = 0
          end

          # By_K2 (무한의탑인 경우 층수 기록)
          if qp == 0 && aqi.quest.quest_map_id == QM_EV_INFINITE_TOWER
            qp = floor_count
          end

          ret = i.quest_point
          t = Time.now.utc
          QuestClearLog.dataset.insert(avatar_id: a_id,
                                       quest_inventory_id: q_iv,
                                       finish_point: f_p,
                                       chara_card_id_0: c_0,
                                       chara_card_id_1: c_1,
                                       chara_card_id_2: c_2,
                                       result: r,
                                       quest_point: qp,
                                       server_type: server_type,
                                       created_at: t,
                                       updated_at: t)

        end
      end
      ret
    end

    # リミットずつのログをもらう(1ページスタート)
    def QuestClearLog::get_page(a_id, page)
    end
  end
end
