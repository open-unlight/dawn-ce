# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # キャラクタークラス
  class CharaCard < Sequel::Model
    attr_accessor :owner, :foe, :duel, :deck, :status, :special_status, :using, :index, :status_update, :weapon_passive
    attr_reader :event

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # 他クラスのアソシエーション
    one_to_many :feat_inventories # 必殺技のインベントリを保持
    one_to_many :passive_skill_inventories # パッシブインベントリ
    one_to_many :chara_card_requirements # 必要とするカード
    one_to_many :chara_card_stories

    # 他クラスのアソシエーション
    many_to_one :charactor # キャラデータを持つ

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # アップデート後の後理処
    after_save do
      Unlight::CharaCard::refresh_data_version
    end

    # 全体データバージョンを返す
    def CharaCard::data_version
      ret = cache_store.get('CharaCardVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('CharaCardVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CharaCard::refresh_data_version
      m = Unlight::CharaCard.order(:updated_at).last
      if m
        FeatInventory::refresh_data_version
        if FeatInventory::data_version
          cache_store.set('CharaCardVersion', [m.version, FeatInventory::data_version].max)
        else
          cache_store.set('CharaCardVersion', m.version)
        end
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    def CharaCard::up_tree(id)
      CharaCardRequirement.up_tree(id)
    end

    def CharaCard::down_tree(id)
      CharaCardRequirement.down_tree(id)
    end

    # カードの交換条件情報をリストで返す
    def CharaCard::exchange(id, list, c_id)
      CharaCardRequirement.exchange(id, list, c_id)
    end

    def same_person?(cc)
      ret = false
      if (cc.charactor_id == self.charactor_id) ||
         (cc.unlight_charactor_id == self.unlight_charactor_id) ||
         (cc.parent_id == self.parent_id)
        ret = true
      end
      ret
    end

    # デュエルのスタート会話を返す

    def CharaCard::duel_start_dialogue(chara_id_str, other_id_str)
      ret = []
      a = CharaCard[chara_id_str.split(',')[0]]
      b = CharaCard[other_id_str.split(',')[0]]
      level = 0
      if a.rarity > 5 && b.rarity > 5
        level = 5
      elsif a.rarity > 5
        level = b.level
      elsif b.rarity > 5
        level = a.level
      else
        level = a.level > b.level ? b.level : a.level
      end

      if a && b
        d = DialogueWeight::get_dialogue(DLG_DUEL_START, a.parent_id, a.charactor_id, b.parent_id, b.charactor_id, level)
        if d
          ret = [d.id, d.content]
        else
          ret = [0, '']
        end
      end
      ret
    end

    # カードのストーリーを返す
    def story_id
      chara_card_stories[0].id if chara_card_stories.size > 0
    end

    # 台詞IDをゲットする
    def dialogue_id(type, other)
      DialogueWeight.DialogueWeight::get_dialogue_id
    end

    # 必殺技のIDリストを返す
    def feats_id
      ret = []
      if feat_inventories.size > 0
        feat_inventories.each do |f|
          ret << f.feat_id
        end
      end
      ret.join(',')
    end

    # パッシブのIDリストを返す
    def passives_id
      ret = []
      if passive_skill_inventories.size > 0
        passive_skill_inventories.each do |p|
          ret << p.passive_skill_id
        end
      end
      ret.join(',')
    end

    # 親のキャラクターIDを返す
    def parent_id
      if self.charactor.parent_id.blank? || self.charactor.parent_id == 0
        self.charactor_id
      else
        self.charactor.parent_id
      end
    end

    # UnlightカードのキャラクターIDを返す
    def unlight_charactor_id
      if self.kind == CC_KIND_REBORN_CHARA && self.charactor_id > CHARACTOR_ID_OFFSET_REBORN
        self.charactor_id - CHARACTOR_ID_OFFSET_REBORN
      else
        self.charactor_id
      end
    end

    # 復活カードの場合はULカード。子カードの場合は親カードのIDを返す
    def base_charactor_id
      if self.kind == CC_KIND_REBORN_CHARA
        self.unlight_charactor_id
      else
        self.parent_id
      end
    end

    # スロットの色数を返す
    def slot_color_num(color_no)
      ret = CharaCard::cache_store.get("CharaCard:color_num:#{id}")
      unless ret
        ret = 0
        slot.to_s.each_char { |c| ret += 1 if c == color_no }
        CharaCard::cache_store.set("CharaCard:color_num:#{id}", ret)
      end
      ret
    end

    # カードの初期化
    def init_card(ctxt, entrant, foe, duel, index)
      @owner = entrant                # 現在の使用者
      @foe = foe
      @duel = duel
      @deck = duel.deck
      @index = index
      @event = CharaCardEvent.new(ctxt, self)
      @status = []                    # [power, turn, resistance]
      @special_status = []
      @event.singleton_class # NOTE: Create singleton class to ensure `method` get same object
      # ステータス状態を初期化
      CHARA_STATE_EVENT_NO.each_index do |i|
        @status << [1, 0, 0]
      end
      # ステータス状態のHookを登録
      CHARA_STATE_EVENT_NO.each do |s|
        s.each do |g|
          @event.send(g)
        end
      end
      # 特殊ステータス状態を初期化
      CHARA_SPECIAL_STATE_EVENT_NO.each_index do |i|
        @special_status << [1, 0, 0]
      end
      # 特殊ステータス状態のHookを登録
      CHARA_SPECIAL_STATE_EVENT_NO.each do |s|
        s.each do |g|
          @event.send(g)
        end
      end
      CHARA_OTHER_EVENT_NO.each do |s|
        s.each do |g|
          @event.send(g)
        end
      end
      @status_update = true
    end

    # カードイベントの初期化
    def init_event()
      @using = true
      # 必殺技のHookを登録
      @event.get_feat_nos.each do |fno|
        if CHARA_FEAT_EVENT_NO[fno]
          CHARA_FEAT_EVENT_NO[fno].each do |g|
            @event.send(g) if @event
          end
        end
      end

      # パッシブのHookを登録
      inventory_max = 4 # 最大４つまで
      registed_cnt = 0
      self.passive_skill_inventories.each do |p|
        break if registed_cnt >= inventory_max

        if CHARA_PASSIVE_SKILL_EVENT_NO[p.passive_skill.passive_skill_no]
          CHARA_PASSIVE_SKILL_EVENT_NO[p.passive_skill.passive_skill_no].each do |g|
            @event.send(g) if @event
          end
          registed_cnt += 1
        end
      end

      if weapon_passive
        weapon_passive.each do |pid|
          break if registed_cnt >= inventory_max

          pno = PassiveSkill[pid].passive_skill_no
          if CHARA_PASSIVE_SKILL_EVENT_NO[pno]
            CHARA_PASSIVE_SKILL_EVENT_NO[pno].each do |g|
              @event.send(g) if @event
            end
            registed_cnt += 1
          end
        end
      end
    end

    # 治癒できないステータス
    STATE_CONTROL = 25
    IRREMEDIABLE_STATE = [
      STATE_CONTROL,
    ]
    # ステータス状態を初期化
    HAS_PILOTS = [20, 27]
    def cure_status()
      if @status
        @status.each_with_index do |s, i|
          s[1] = 0 unless IRREMEDIABLE_STATE.include?(i)
        end
        if HAS_PILOTS.include?(self.charactor_id)
          check_unseal_active_armor_feat
        end
      end
    end

    # 必殺技を初期化
    def reset_feats()
      if @event
        @event.reset_feats_enable
      end
    end

    # 特殊ステータスを初期化
    def reset_special_status
      if @special_status
        @special_status.each_with_index do |s, i|
          s[1] = 0
        end
      end
    end

    # カードイベントの初期化
    def remove_event()
      @using = false
      # ここでFeatEnableをくりあする
      if @event
        @event.init_feats_enable
        @event.init_passives_enable
      end
    end

    # カードイベントの後処理
    def finalize_event
      if @event
        # 全てのイベントをリムーブする
        @event.remove_all_event_listener
        # 全てのHookをリムーブする
        @event.remove_all_hook
        @event.finalize_event
        @event = nil
      end
      @using = false
      @owner = nil # 現在の使用者
      @foe = nil
      @duel = nil
      @status = []
      @index = nil
      @status_update = true
    end

    # イベントを委譲する
    def method_missing(message, *arg)
      @event.send(message, *arg)
    end

    def feat_event_no_to_id
    end

    def get_data_csv_str
      ret = ''
      ret << self.id.to_s << ','
      ret << '"' << (self.name || '') << '",'
      ret << '"' << (self.ab_name || '') << '",'
      ret << (self.level || 0).to_s << ','
      ret << (self.hp || 0).to_s << ','
      ret << (self.ap || 0).to_s << ','
      ret << (self.dp || 0).to_s << ','
      ret << (self.rarity || 0).to_s << ','
      ret << (self.deck_cost || 0).to_s << ','
      ret << (self.slot || 0).to_s << ','
      ret << '"' << (self.stand_image || '') << '",'
      ret << '"' << (self.chara_image || '') << '",'
      ret << '"' << (self.artifact_image || '') << '",'
      ret << '"' << (self.bg_image || '') << '",'
      ret << '"' << (self.caption || '') << '",'
      ret << '"' << (self.feats_id || '') << '",'
      ret << (self.story_id || 0).to_s << ','
      ret << (self.charactor_id || 0).to_s << ','
      ret << (self.next_id || 0).to_s << ','
      ret << '"' << (CharaCardRequirement.up_tree(self.id).join(',')) << '",'
      ret << '"' << (CharaCardRequirement.down_tree(self.id).join(',')) << '",'
      ret << (self.kind || 0).to_s << ','
      ret << '"' << (self.passives_id || '') << '"'
      ret
    end
  end

  # TODO: Move to top
  require 'model/chara_card_event'
end
