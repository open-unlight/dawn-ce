# frozen_string_literal: true

# rubocop:disable Naming/VariableNumber
Sequel.migration do # rubocop:disable Metrics/BlockLength
  change do # rubocop:disable Metrics/BlockLength
    create_table :achievement_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :achievement_id
      Integer :state, default: 0, null: false
      Integer :progress, default: 0
      Integer :before_avatar_id, default: 0
      DateTime :end_at
      String :code, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :achievements do
      primary_key :id
      Integer :kind, default: 0
      Integer :cond
      String :items, default: '', size: 255
      Integer :prerequisite, default: 0
      String :exclusion, default: '', size: 255
      Integer :loop, default: 0
      String :caption, default: '', size: 255
      Integer :success_cond, default: 0
      String :explanation, default: '', size: 255
      String :set_loop, default: '', size: 255
      String :set_end_type, default: '0', size: 255
      DateTime :event_start_at
      DateTime :event_end_at
      Integer :clear_code_type, default: 0
      Integer :clear_code_max, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :action_cards do
      primary_key :id
      Integer :u_type, default: 0
      Integer :u_value, default: 1
      Integer :b_type, default: 0
      Integer :b_value, default: 1
      Integer :event_no, default: 0
      String :caption, size: 255
      String :image, size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :avatar_apologies do
      primary_key :id
      Integer :avatar_id
      String :body, text: true
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id], name: :avatar_id, unique: true
    end

    create_table :avatar_items do
      primary_key :id
      String :name, size: 255
      Integer :item_no
      Integer :kind
      String :sub_kind, default: '', size: 255
      Integer :duration, default: 0
      String :cond, default: '', size: 255
      String :image, default: '', size: 255
      Integer :image_frame, default: 0
      String :effect_image, default: '', size: 255
      String :caption, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :avatar_notices do
      primary_key :id
      Integer :avatar_id
      String :body, text: true
      DateTime :created_at
      DateTime :updated_at
      DateTime :send_at

      index [:avatar_id]
    end

    create_table :avatar_parts do
      primary_key :id
      String :name, size: 255
      String :image, text: true
      Integer :parts_type, default: 0
      Integer :power_type, default: 0
      Integer :power, default: 0
      Integer :duration, default: 0
      String :caption, text: true
      Integer :color, default: 0
      Integer :offset_x, default: 0
      Integer :offset_y, default: 0
      Integer :offset_scale, default: 100
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :avatar_quest_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :quest_id
      Integer :status
      Integer :progress, default: 0
      Integer :deck_index, default: 1
      Integer :hp0, default: 0
      Integer :hp1, default: 0
      Integer :hp2, default: 0
      Integer :before_avatar_id
      DateTime :find_at
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :avatars do
      primary_key :id
      String :name, size: 255
      Integer :player_id
      Integer :gems, default: 0
      Integer :exp, default: 0
      Integer :level, default: 1
      Integer :energy, default: 5
      Integer :energy_max, default: 5
      Integer :recovery_interval, default: 1800
      Integer :current_deck, default: 1
      Integer :win, default: 0
      Integer :lose, default: 0
      Integer :draw, default: 0
      Integer :point, default: 1500
      Integer :free_duel_count, default: 3
      Integer :friend_max, default: 10
      Integer :part_inventory_max, default: 30
      Integer :quest_inventory_max, default: 4
      Integer :quest_flag, default: 0
      Integer :quest_clear_num, default: 0
      Integer :exp_pow, default: 100
      Integer :gem_pow, default: 100
      Integer :quest_find_pow, default: 100
      Integer :quest_point, default: 0
      Integer :sale_type, default: 0
      DateTime :sale_limit_at
      Integer :favorite_chara_id, default: 1
      Integer :floor_count, default: 1
      Integer :server_type, default: 0
      DateTime :last_recovery_at
      DateTime :created_at
      DateTime :updated_at
      Integer :soul_stamp_id, default: 0
      Integer :soul_stamp_level, default: 0

      index [:name]
    end

    create_table :card_inventories do
      primary_key :id
      Integer :chara_card_deck_id
      Integer :chara_card_id
      Integer :position, default: 0, null: false
      Integer :before_deck_id
      DateTime :created_at
      DateTime :updated_at

      index [:chara_card_deck_id], name: :chara_card_deck_id
    end

    create_table :channels do
      primary_key :id
      String :name, default: '新規サーバ', size: 255
      Integer :order, default: 0
      Integer :rule, default: 0
      Integer :max, default: 2000
      String :host_name, default: '', size: 255
      String :host, default: '', size: 255
      Integer :port, default: 0
      String :chat_host, default: '', size: 255
      Integer :chat_port, default: 0
      String :duel_host, default: '', size: 255
      Integer :duel_port, default: 0
      String :watch_host, default: '', size: 255
      Integer :watch_port, default: 0
      Integer :state, default: 1
      String :caption, default: '', size: 255
      Integer :count, default: 0
      Integer :penalty_type, default: 0
      Integer :watch_mode, default: 0
      Integer :cost_limit_min, default: 0
      Integer :cost_limit_max, default: 0
      Integer :cpu_matching_type, default: 0
      String :cpu_matching_condition, default: '', size: 255
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :chara_card_decks do
      primary_key :id
      String :name, default: 'No Name', size: 255
      Integer :avatar_id
      Integer :kind, default: 0
      Integer :level, default: 1
      Integer :exp, default: 0
      Integer :max_cost, default: 45
      Integer :status, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
      index [:name]
    end

    create_table :chara_card_requirements do
      primary_key :id
      Integer :chara_card_id
      Integer :require_chara_card_id
      Integer :require_num
      DateTime :created_at
      DateTime :updated_at

      index [:chara_card_id]
    end

    create_table :chara_card_slot_inventories do
      primary_key :id
      Integer :chara_card_deck_id
      Integer :deck_position
      Integer :card_position
      Integer :kind
      Integer :card_id
      Integer :weapon_type, default: 0
      Integer :before_deck_id
      Integer :combine_param1, default: 0
      Integer :combine_param2, default: 536881152
      String :combine_param1_str, default: '0', size: 255
      Integer :level, default: 1
      Integer :exp, default: 0
      Integer :combine_param3, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:chara_card_deck_id]
    end

    create_table :chara_card_stories do
      primary_key :id
      Integer :chara_card_id
      Integer :book_type
      String :title, text: true
      String :content, text: true
      String :image, default: '', size: 255
      String :age_no, default: '', size: 255
      Integer :text_id
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :chara_cards do
      primary_key :id
      String :name, size: 255
      String :ab_name, default: '', size: 255
      Integer :level, default: 1
      Integer :hp, default: 1
      Integer :ap, default: 1
      Integer :dp, default: 1
      Integer :rarity, default: 1
      Integer :deck_cost, default: 1
      Integer :slot, default: 0
      String :stand_image, default: '', size: 255
      String :chara_image, default: '', size: 255
      String :artifact_image, default: '', size: 255
      String :bg_image, default: '', size: 255
      String :caption, default: '', size: 255
      Integer :charactor_id
      Integer :next_id
      DateTime :created_at
      DateTime :updated_at
      Integer :kind, default: 0

      index [:name]
    end

    create_table :chara_records do
      primary_key :id
      Integer :avatar_id
      Integer :charactor_id
      Integer :chara_card_id
      Integer :likability, default: 0
      Integer :hit_point, default: 0
      Integer :tension, default: 50
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :charactors do
      primary_key :id
      String :name, size: 255
      Integer :parent_id, default: 0
      String :chara_attribute, default: '', size: 255
      String :lobby_image, default: '', size: 255
      String :chara_voice, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :clear_codes do
      primary_key :id
      String :code, size: 255
      Integer :kind, default: 0
      Integer :state, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:code]
      index [:code], name: :code, unique: true
    end

    create_table :combine_cases do
      primary_key :id
      Integer :weapon_card_id, default: 0
      String :requirement, default: '', size: 255
      Integer :mod_type, default: 0
      String :mod_args, default: '', size: 255
      Integer :limited, default: 0
      Integer :priority, default: 0
      Integer :combined_w_id, default: 0
      Integer :pow, default: 100
      DateTime :created_at
      DateTime :updated_at

      index [:weapon_card_id]
    end

    create_table :comeback_logs do
      primary_key :id
      Integer :send_player_id
      String :comebacked_player_id, size: 255
      TrueClass :comebacked, default: false
      DateTime :created_at
      DateTime :updated_at

      index [:comebacked_player_id]
      index [:send_player_id]
    end

    create_table :cpu_card_datas do
      primary_key :id
      String :name, default: 'monster', size: 255
      Integer :allocation_type, default: 0
      String :chara_card_id, default: '1001+1001+1001', size: 255
      String :weapon_card_id, default: '0+0+0', size: 255
      String :equip_card_id, default: '0+0+0', size: 255
      String :event_card_id, default: '1/1/1+1/1/1+1/1/1', size: 255
      Integer :ai_rank, default: 10
      Integer :treasure_id
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :cpu_room_datas do
      primary_key :id
      String :name, default: '', size: 255
      Integer :level, default: 0
      Integer :cpu_card_data_no, default: 0
      Integer :rule, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :dialogue_weights do
      primary_key :id
      Integer :dialogue_type, default: 0
      Integer :chara_id
      Integer :other_chara_id, default: 0
      Integer :dialogue_id
      Integer :weight, default: 1
      Integer :level, default: 1
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :dialogues do
      primary_key :id
      String :content, text: true
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :equip_cards do
      primary_key :id
      String :name, size: 255
      Integer :equip_no
      Integer :card_cost, default: 0
      String :restriction, default: '', size: 255
      String :image, default: '', size: 255
      String :caption, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :estimation_rankings do
      primary_key :id
      Integer :rank_type
      Integer :point, default: 0
      Integer :ranking, default: 0
      Float :user_num, default: 0.0
      Integer :rank_index
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :event_cards do
      primary_key :id
      String :name, size: 255
      Integer :event_no
      Integer :card_cost, default: 0
      Integer :color, default: 0
      Integer :max_in_deck, default: 0
      String :restriction, default: '', size: 255
      String :image, default: '', size: 255
      String :caption, default: '', size: 255
      TrueClass :filler, default: false
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :event_quest_flag_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :event_quest_flag_id, default: 0
      Integer :event_id
      Integer :quest_flag
      Integer :quest_clear_num, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
      index [:event_id]
      index [:event_quest_flag_id]
    end

    create_table :event_quest_flags do
      primary_key :id
      Integer :avatar_id
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :event_serials do
      primary_key :id
      String :serial, size: 255
      String :pass, default: 'pass', size: 255
      Integer :rm_item_type, default: 0
      Integer :item_id, default: 0
      Integer :num, default: 1
      Integer :extra_id, default: 0
      Integer :state, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:serial]
      index [:serial], name: :serial, unique: true
    end

    create_table :feat_inventories do
      primary_key :id
      Integer :chara_card_id
      Integer :feat_id
      DateTime :created_at
      DateTime :updated_at

      index [:chara_card_id]
    end

    create_table :feats do
      primary_key :id
      String :name, size: 255
      Integer :feat_no
      Integer :pow
      String :dice_attribute, default: '', size: 255
      String :effect_image, default: '', size: 255
      String :caption, default: '', size: 255
      String :condition, text: true
      DateTime :created_at
      DateTime :updated_at

      index [:name]
    end

    create_table :friend_links do
      primary_key :id
      Integer :relating_player_id
      Integer :related_player_id
      Integer :friend_type, default: 0
      TrueClass :invated, default: false
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:related_player_id]
      index [:relating_player_id]
      index [:server_type]
    end

    create_table :infection_collabo_serials do
      primary_key :id
      String :serial, size: 255
      Integer :player_id
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:player_id]
      index [:serial]
      index [:player_id], name: :player_id, unique: true
      index [:serial], name: :serial, unique: true
    end

    create_table :invite_logs do
      primary_key :id
      Integer :invite_player_id
      String :invited_user_id, size: 255
      TrueClass :invited, default: false
      Integer :sns_log_id
      DateTime :created_at
      DateTime :updated_at

      index [:invite_player_id]
      index [:invited_user_id]
      index [:sns_log_id]
    end

    create_table :item_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :avatar_item_id
      Integer :state, default: 0
      Integer :server_type, default: 0
      DateTime :use_at
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :lot_logs do
      primary_key :id
      Integer :player_id
      Integer :lot_type
      String :description, size: 255
      Integer :geted_lot_no
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :match_logs do
      primary_key :id
      Integer :channel_id
      String :match_name, text: true
      Integer :match_rule
      Integer :match_stage
      Integer :a_avatar_id
      Integer :b_avatar_id
      Integer :a_chara_card_id_0
      Integer :a_chara_card_id_1
      Integer :a_chara_card_id_2
      Integer :b_chara_card_id_0
      Integer :b_chara_card_id_1
      Integer :b_chara_card_id_2
      Integer :a_deck_cost
      Integer :b_deck_cost
      Integer :cpu_card_data_id, default: 0
      Integer :state
      Integer :match_option, default: 0
      Integer :match_level
      Integer :winner_avatar_id
      Integer :get_bp
      Integer :lose_bp
      Integer :channel_set_rule, default: 0
      String :a_remain_hp_set, size: 255
      String :b_remain_hp_set, size: 255
      Integer :turn_num, default: 0
      Integer :warn, default: 0
      Integer :watch_mode, default: 0
      Integer :server_type, default: 0
      DateTime :start_at
      DateTime :finish_at
      DateTime :created_at
      DateTime :updated_at

      index [:winner_avatar_id]
    end

    create_table :monster_treasure_inventories do
      primary_key :id
      Integer :cpu_card_data_id
      Integer :treasure_data_id
      Integer :num
      Integer :step
      DateTime :created_at
      DateTime :updated_at

      index [:cpu_card_data_id]
    end

    create_table :part_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :avatar_part_id
      Integer :used, default: 0
      DateTime :end_at
      Integer :before_avatar_id, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :passive_skill_inventories do
      primary_key :id
      Integer :chara_card_id
      Integer :passive_skill_id
      DateTime :created_at
      DateTime :updated_at

      index [:chara_card_id]
    end

    create_table :passive_skills do
      primary_key :id
      String :name, size: 255
      Integer :passive_skill_no
      Integer :pow
      String :effect_image, default: '', size: 255
      String :caption, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at

      index [:name]
    end

    create_table :payment_logs do
      primary_key :id
      Integer :player_id
      Integer :real_money_item_id
      String :payment_id, size: 255
      Integer :num, default: 1
      Float :amount, default: 0.0
      Integer :result, default: 0
      String :buyer_data, text: true
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :players do
      primary_key :id
      String :name, size: 255
      String :email, size: 255
      String :salt, size: 255
      String :verifier, size: 255
      Integer :role, default: 0
      Integer :state, default: 0
      Integer :game_session
      DateTime :login_at
      DateTime :logout_at
      Integer :total_time, default: 0
      String :last_ip, size: 255
      String :data_ver, size: 255
      Integer :penalty, default: 0
      String :session_key, size: 255
      Integer :tutorial, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:name], name: :name, unique: true
      index [:name]
    end

    create_table :profound_comments do
      primary_key :id
      Integer :profound_id
      Integer :avatar_id
      String :name, size: 255
      String :comment, size: 255
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
      index [:profound_id]
    end

    create_table :profound_datas do
      primary_key :id
      Integer :prf_type
      String :name, size: 255
      Integer :rarity
      Integer :level
      String :ttl, size: 255
      Integer :core_monster_id
      Integer :quest_map_id
      Integer :group_id
      Integer :treasure_level
      Integer :stage
      Integer :finder_start_point, default: 10
      Integer :member_limit, default: 100
      String :caption, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :profound_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :profound_id
      Integer :deck_idx, default: 0
      Integer :chara_card_dmg_1, default: 0
      Integer :chara_card_dmg_2, default: 0
      Integer :chara_card_dmg_3, default: 0
      Integer :damage_count, default: 0
      Integer :score, default: 0
      Integer :state, default: 0
      TrueClass :found, default: false
      TrueClass :defeat, default: false
      Integer :reward_state, default: 0
      Integer :btl_count, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
      index [:profound_id]
      index [:state]
    end

    create_table :profound_logs do
      primary_key :id
      Integer :profound_id
      Integer :avatar_id
      String :avatar_name, size: 255
      Integer :chara_no
      String :boss_name, size: 255
      Integer :damage
      Integer :atk_charactor
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
      index [:profound_id]
    end

    create_table :profound_treasure_datas do
      primary_key :id
      Integer :level
      Integer :prf_trs_type, default: 0
      Integer :rank_min, default: 0
      Integer :rank_max, default: 0
      Integer :treasure_type, default: 0
      Integer :treasure_id, default: 0
      Integer :slot_type, default: 0
      Integer :value, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :profounds do
      primary_key :id
      Integer :data_id
      String :profound_hash, size: 255
      DateTime :close_at
      Integer :state
      Integer :map_id
      Integer :pos_idx
      Integer :copy_type, default: 1
      TrueClass :set_defeat_reward, default: true
      Integer :found_avatar_id
      Integer :defeat_avatar_id
      DateTime :finish_at
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:profound_hash]
    end

    create_table :quest_clear_logs do
      primary_key :id
      Integer :avatar_id
      Integer :quest_inventory_id
      Integer :chara_card_id_0
      Integer :chara_card_id_1
      Integer :chara_card_id_2
      Integer :finish_point
      Integer :result
      Integer :quest_point
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :quest_lands do
      primary_key :id
      String :name, default: '', size: 255
      Integer :monstar_no, default: 0
      Integer :treasure_no, default: 0
      Integer :event_no, default: 0
      Integer :stage, default: 0
      String :caption, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :quest_logs do
      primary_key :id
      Integer :avatar_id
      Integer :type_no
      Integer :type_id
      String :name, size: 255
      String :body, size: 255
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :quest_maps do
      primary_key :id
      String :name, default: '', size: 255
      String :caption, default: '', size: 255
      Integer :region, default: 0
      Integer :level, default: 0
      Integer :difficulty, default: 1
      Integer :ap, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :quests do
      primary_key :id
      Integer :quest_map_id
      String :name, default: '', size: 255
      String :caption, default: '', size: 255
      Integer :ap, default: 0
      Integer :kind, default: 0
      Integer :difficulty, default: 0
      Integer :rarity, default: 0
      Integer :story_no, default: 0
      Integer :quest_land_id_0_0, default: 0, null: false
      Integer :next_0_0, default: 0, null: false
      Integer :quest_land_id_0_1, default: 0, null: false
      Integer :next_0_1, default: 0, null: false
      Integer :quest_land_id_0_2, default: 0, null: false
      Integer :next_0_2, default: 0, null: false
      Integer :quest_land_id_1_0, default: 0, null: false
      Integer :next_1_0, default: 0, null: false
      Integer :quest_land_id_1_1, default: 0, null: false
      Integer :next_1_1, default: 0, null: false
      Integer :quest_land_id_1_2, default: 0, null: false
      Integer :next_1_2, default: 0, null: false
      Integer :quest_land_id_2_0, default: 0, null: false
      Integer :next_2_0, default: 0, null: false
      Integer :quest_land_id_2_1, default: 0, null: false
      Integer :next_2_1, default: 0, null: false
      Integer :quest_land_id_2_2, default: 0, null: false
      Integer :next_2_2, default: 0, null: false
      Integer :quest_land_id_3_0, default: 0, null: false
      Integer :next_3_0, default: 0, null: false
      Integer :quest_land_id_3_1, default: 0, null: false
      Integer :next_3_1, default: 0, null: false
      Integer :quest_land_id_3_2, default: 0, null: false
      Integer :next_3_2, default: 0, null: false
      Integer :quest_land_id_4_0, default: 0, null: false
      Integer :next_4_0, default: 0, null: false
      Integer :quest_land_id_4_1, default: 0, null: false
      Integer :next_4_1, default: 0, null: false
      Integer :quest_land_id_4_2, default: 0, null: false
      Integer :next_4_2, default: 0, null: false
      DateTime :created_at
      DateTime :updated_at

      index [:quest_map_id]
    end

    create_table :rare_card_lots do
      primary_key :id
      Integer :lot_kind, default: 0
      Integer :article_kind, default: 0
      Integer :article_id
      Integer :order, default: 0
      Integer :rarity, default: 0
      Integer :visible, default: 0
      Integer :num, default: 1
      String :image_url, default: '', size: 255
      String :description, default: '', size: 255
      DateTime :created_at
      DateTime :updated_at

      index [:lot_kind]
    end

    create_table :real_money_items do
      primary_key :id
      String :name, default: 'real_money_item', size: 255
      Float :price, default: 0.0
      Integer :rm_item_type, default: 0
      Integer :item_id, default: 0
      Integer :num, default: 0
      Integer :order, default: 0
      Integer :state, default: 0
      String :image_url, default: '', size: 255
      Integer :tab, default: 0
      String :description, default: '', size: 255
      Integer :extra_id, default: 0
      Integer :view_frame, default: 0
      Integer :sale_type, default: 0
      String :deck_image_url, default: '', size: 255
      Float :twd, default: 0.0
      Float :hkd, default: 0.0
      Float :usd, default: 0.0
      Float :eur, default: 0.0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :reissue_requests do
      primary_key :id
      String :uniq_str, size: 255
      String :email, size: 255
      Integer :player_id, default: 0
      Integer :status, default: 0
      DateTime :limit_at
      DateTime :created_at
      DateTime :updated_at

      index [:email]
      index [:uniq_str]
    end

    create_table :reward_datas do
      primary_key :id
      Integer :exps, default: 0
      Integer :gems, default: 0
      Integer :item_id, default: 0
      Integer :item_num, default: 0
      Integer :own_card_lv, default: 0
      Integer :own_card_num, default: 0
      Integer :random_card_rarity, default: 0
      Integer :random_card_num, default: 0
      Integer :rare_card_lv, default: 0
      Integer :event_card_id, default: 0
      Integer :event_card_num, default: 0
      Integer :weapon_card_id, default: 0
      Integer :weapon_card_num, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :scenario_flag_inventories do
      primary_key :id
      Integer :avatar_id
      String :flags, default: '{}', size: 255
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :scenario_inventories do
      primary_key :id
      Integer :avatar_id
      Integer :scenario_id
      Integer :state
      DateTime :end_at
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :scenarios do
      primary_key :id
      Integer :chara_id
      String :script, text: true
      Integer :count
      Integer :priority
      DateTime :event_start_at
      DateTime :event_end_at
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :shops do
      primary_key :id
      Integer :shop_type
      Integer :article_kind
      Integer :article_id
      Integer :price, default: 0
      Integer :coin_0, default: 0
      Integer :coin_1, default: 0
      Integer :coin_2, default: 0
      Integer :coin_3, default: 0
      Integer :coin_4, default: 0
      Integer :coin_ex, default: 0
      Integer :view_frame, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:article_kind]
    end

    create_table :total_chara_vote_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :avatar_item_id, default: 0
      DateTime :created_at
      DateTime :updated_at
      Integer :server_type, default: 0

      index [:avatar_id]
      index [:avatar_item_id]
    end

    create_table :total_duel_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :total_event_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :total_quest_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :treasure_datas do
      primary_key :id
      String :name, default: 'treasure', size: 255
      Integer :allocation_type, default: 0
      String :allocation_id, default: '', size: 255
      Integer :treasure_type, default: 0
      Integer :slot_type, default: 0
      Integer :value, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :weapon_cards do
      primary_key :id
      String :name, size: 255
      Integer :weapon_no
      String :passive_id, default: '', size: 255
      Integer :card_cost, default: 0
      String :restriction, default: '', size: 255
      String :image, default: '', size: 255
      String :caption, default: '', size: 255
      Integer :weapon_type, default: 0
      Integer :material_use_cnt, default: 0
      Integer :material_add_param, default: 0
      Integer :material_exp, default: 0
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :weekly_duel_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :arrow, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end

    create_table :weekly_quest_rankings do
      primary_key :id
      Integer :avatar_id
      String :name, default: '', size: 255
      Integer :point, default: 0
      Integer :arrow, default: 0
      Integer :server_type, default: 0
      DateTime :created_at
      DateTime :updated_at

      index [:avatar_id]
    end
  end
end
# rubocop:enable Naming/VariableNumber
