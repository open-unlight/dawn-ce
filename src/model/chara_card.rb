# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # キャラクタークラス
  class CharaCard < Sequel::Model
    attr_accessor :owner,:foe,:duel,:deck,:status,:special_status,:using,:index,:status_update
    attr_reader :event
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    one_to_many :feat_inventories   # 必殺技のインベントリを保持
    one_to_many :passive_skill_inventories   # パッシブインベントリ
    one_to_many :chara_card_requirements   # 必要とするカード
    one_to_many :chara_card_stories

    # 他クラスのアソシエーション
    many_to_one :charactor      # キャラデータを持つ


    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :index=>true
      String      :ab_name,:default => ""
      integer     :level, :default => 1
      integer     :hp, :default => 1
      integer     :ap, :default => 1
      integer     :dp, :default => 1
      integer     :rarity, :default => 1
      integer     :deck_cost, :default => 1
      integer     :slot, :default => 0
      String      :stand_image, :default => ""
      String      :chara_image, :default => ""
      String      :artifact_image, :default => ""
      String      :bg_image, :default => ""
      String      :caption, :default => ""
      integer     :charactor_id
      integer     :next_id
      datetime    :created_at
      datetime    :updated_at

      integer     :kind, :default => 0 # 新規追加 2013/06/24

    end

    # DBにテーブルをつくる
    if !(CharaCard.table_exists?)
      CharaCard.create_table
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    DB.alter_table :chara_cards do
      add_column :kind, :integer, :default => 0 unless Unlight::CharaCard.columns.include?(:kind)  # 新規追加 2013/6/24
    end

    # アップデート後の後理処
    after_save do
      Unlight::CharaCard::refresh_data_version
    end

    # 全体データバージョンを返す
    def CharaCard::data_version
      ret = cache_store.get("CharaCardVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("CharaCardVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CharaCard::refresh_data_version
      m = Unlight::CharaCard.order(:updated_at).last
      if m
        FeatInventory::refresh_data_version
        if FeatInventory::data_version
          cache_store.set("CharaCardVersion",[m.version, FeatInventory::data_version].max)
          else
          cache_store.set("CharaCardVersion", m.version)
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
      a = CharaCard[chara_id_str.split(",")[0]]
      b = CharaCard[other_id_str.split(",")[0]]
      level = 0
      if a.rarity > 5 && b.rarity >5
        level = 5
      elsif a.rarity > 5
        level = b.level
      elsif b.rarity > 5
        level = a.level
      else
        level = a.level > b.level ? b.level : a.level
      end

      if a&&b
        d = DialogueWeight::get_dialogue(DLG_DUEL_START, a.parent_id, a.charactor_id, b.parent_id, b.charactor_id, level)
        if d
          ret = [d.id,d.content]
        else
          ret = [0,""]
        end
      end
      ret
    end

    # カードのストーリーを返す
    def story_id
      chara_card_stories[0].id if chara_card_stories.size>0
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
      ret.join(",")
    end

    # パッシブのIDリストを返す
    def passives_id
      ret = []
      if passive_skill_inventories.size > 0
        passive_skill_inventories.each do |p|
          ret << p.passive_skill_id
        end
      end
      ret.join(",")
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
      self.kind == CC_KIND_REBORN_CHARA && self.charactor_id > CHARACTOR_ID_OFFSET_REBORN ?
      self.charactor_id - CHARACTOR_ID_OFFSET_REBORN : self.charactor_id
    end

    # 復活カードの場合はULカード。子カードの場合は親カードのIDを返す
    def base_charactor_id
      if self.kind == CC_KIND_REBORN_CHARA
        return self.unlight_charactor_id
      else
        return self.parent_id
      end
    end

    # スロットの色数を返す
    def slot_color_num(color_no)
      ret = CharaCard::cache_store.get("CharaCard:color_num:#{id}")
      unless ret
        ret = 0
        slot.to_s.each_char{ |c| ret+=1 if c == color_no}
        CharaCard::cache_store.set("CharaCard:color_num:#{id}", ret)
      end
      ret
    end

    # 所有されている参加者の登録
   def owner=(entrant)
      @owner = entrant
    end

   def weapon_passive=(wp)
     @weapon_passive = wp
   end

   def weapon_passive
     @weapon_passive
   end

    # カードの初期化
    def init_card(ctxt,entrant,foe,duel,index)
      @owner = entrant                # 現在の使用者
      @foe = foe
      @duel = duel
      @deck = duel.deck
      @index = index
      @event = CharaCardEvent.new(ctxt,self)
      @status = []                    # [power, turn, resistance]
      @special_status = []
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
      registed_cnt =0
      self.passive_skill_inventories.each do |p|
        break if registed_cnt >= inventory_max
        if CHARA_PASSIVE_SKILL_EVENT_NO[p.passive_skill.passive_skill_no]
          CHARA_PASSIVE_SKILL_EVENT_NO[p.passive_skill.passive_skill_no].each do |g|
            @event.send(g) if @event
          end
          registed_cnt+=1
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
            registed_cnt+=1
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
    HAS_PILOTS = [20,27]
    def cure_status()
      if @status
        @status.each_with_index do |s,i|
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
        @special_status.each_with_index do |s,i|
          s[1] = 0
        end
      end
    end

    # カードイベントの初期化
    def remove_event()
      @using =false
      # ここでFeatEnableをくりあする
      if @event
        @event.init_feats_enable
        @event.init_passives_enable
      end
    end

    # カードイベントの後処理
    def finalize_event()#
      if @event
      # 全てのイベントをリムーブする
        @event.remove_all_event_listener
        # 全てのHookをリムーブする
        @event.remove_all_hook
        @event.finalize_event
        @event = nil
      end
      @using =false
      @owner = nil                # 現在の使用者
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
      ret = ""
      ret << self.id.to_s << ","
      ret << '"' << (self.name||"") << '",'
      ret << '"' << (self.ab_name||"")<< '",'
      ret << (self.level||0).to_s<< ","
      ret << (self.hp||0).to_s << ","
      ret << (self.ap||0).to_s << ","
      ret << (self.dp||0).to_s << ","
      ret << (self.rarity||0).to_s << ","
      ret << (self.deck_cost||0).to_s << ","
      ret << (self.slot||0).to_s << ","
      ret << '"' << (self.stand_image||"") << '",'
      ret << '"' << (self.chara_image||"") << '",'
      ret << '"' << (self.artifact_image||"") << '",'
      ret << '"' << (self.bg_image||"") << '",'
      ret << '"' << (self.caption||"") << '",'
      ret << '"' << (self.feats_id||"") << '",'
      ret << (self.story_id||0).to_s << ","
      ret << (self.charactor_id||0).to_s << ","
      ret << (self.next_id||0).to_s << ","
      ret << '"' << (CharaCardRequirement.up_tree(self.id).join(",")) << '",'
      ret << '"' << (CharaCardRequirement.down_tree(self.id).join(","))<< '",'
      ret << (self.kind||0).to_s << ","
      ret << '"' << (self.passives_id||"") << '"'
      ret
    end

  end

  class CharaCardEvent < BaseEvent
    require 'prime'
    attr_reader :feats_enable, :passives_enable

    # パッシブの定数
    PASSIVE_ADDITIONAL_DRAW, PASSIVE_INDOMITABLE_MIND, PASSIVE_DRAIN_SOUL, PASSIVE_SEALING_ATTACK,
    PASSIVE_INSTANT_KILL_GUARD,PASSIVE_RAGE_AGAINST,PASSIVE_CREATOR,PASSIVE_BOUNCE_BACK,PASSIVE_LINKAGE,
    PASSIVE_LIBERATION,PASSIVE_HARDEN,PASSIVE_ABSORP,PASSIVE_MOONDOG,PASSIVE_JUMP,PASSIVE_PROTECTION_AIM,
    PASSIVE_MISTAKE,PASSIVE_STATE_RESISTANCE,PASSIVE_SENKOU,PASSIVE_HATE,PASSIVE_LITTLE_PRINCESS,
    PASSIVE_CRIMSON_WITCH,PASSIVE_AEGIS,PASSIVE_OCEAN,PASSIVE_RESIST_SKYLLA,PASSIVE_NIGHT_FOG,
    PASSIVE_DOUBLE_BODDY,PASSIVE_WIT,PASSIVE_CURSE_CARE,PASSIVE_WHITE_LIGHT,PASSIVE_CARAPACE_BREAKE,
    PASSIVE_CARAPACE,PASSIVE_RESIST_KAMUY,PASSIVE_REVISERS,PASSIVE_RESIST_WALL,PASSIVE_CURSE_SIGN,
    PASSIVE_LOYALTY,PASSIVE_AIMING_PLUS,PASSIVE_EASING_CARD_CONDITION,PASSIVE_HARVEST,
    PASSIVE_TD,PASSIVE_MOON_SHINE,PASSIVE_FERTILITY,PASSIVE_RESIST_PUMPKIN,
    PASSIVE_AWCS,PASSIVE_RESIST_DW,PASSIVE_LONSBROUGH_EVENT,PASSIVE_ROCK_CRUSHER,
    PASSIVE_PROJECTION,PASSIVE_DAMAGE_MULTIPLIER,PASSIVE_EV201606,PASSIVE_STATE_RESISTANCE_AQUAMARINE,
    PASSIVE_COOLY,PASSIVE_EV201609,PASSIVE_RESIST_BYAKHEE,PASSIVE_DISASTER_FLAME,PASSIVE_BRAMBLES_CARD,
    PASSIVE_AWAKENING_ONE,PASSIVE_SERVO_SKULL,PASSIVE_EV201612,PASSIVE_HIGH_PROTECTION,
    PASSIVE_PUPPET_MASTER,PASSIVE_OGRE_ARM,PASSIVE_CRIMSON_WILL,PASSIVE_GUARDIAN_OF_LIFE,
    PASSIVE_BURNING_EMBERS=(1..65).to_a

    # ステータス異常の定数
    STATE_POISON,STATE_PARALYSIS,STATE_ATK_UP,STATE_ATK_DOWN,STATE_DEF_UP,
    STATE_DEF_DOWN,STATE_BERSERK,STATE_STOP,STATE_SEAL,STATE_DEAD_COUNT,
    STATE_UNDEAD,STATE_STONE,STATE_MOVE_UP,STATE_MOVE_DOWN,STATE_REGENE,
    STATE_BIND,STATE_CHAOS,STATE_STIGMATA,STATE_STATE_DOWN,STATE_STICK,
    STATE_CURSE,STATE_BLESS,STATE_UNDEAD2,STATE_POISON2,STATE_CONTROL,
    STATE_TARGET,STATE_DARK,STATE_DOLL= (1..28).to_a

    # 特殊ステータス異常の定数
    SPECIAL_STATE_CAT,SPECIAL_STATE_ANTISEPTIC,SPECIAL_STATE_SHARPEN_EDGE,SPECIAL_STATE_RESERVE_GUARD,
    SPECIAL_STATE_DEALING_RESTRICTION,SPECIAL_STATE_CONSTRAINT,SPECIAL_STATE_DAMAGE_INSURANCE,
    SPECIAL_STATE_OVERRIDE_SKILL,SPECIAL_STATE_MAGNETIC_FIELD,SPECIAL_STATE_CONST_COUNTER,
    SPECIAL_STATE_STUFFED_TOYS,SPECIAL_STATE_MONITORING,SPECIAL_STATE_TIME_LAG_DROW,
    SPECIAL_STATE_TIME_LAG_BUFF,SPECIAL_STATE_MACHINE_CELL,SPECIAL_STATE_AX_GUARD=(1..16).to_a

    BLESS_MAX = 3

    FEAT_SMASH,FEAT_AIMING,FEAT_STRIKE,FEAT_COMBO,FEAT_THORN,
    FEAT_CHARGE,FEAT_MIRAGE,FEAT_FRENZY_EYES,FEAT_ABYSS,FEAT_RAPID_SWORD,
    FEAT_ANGER,FEAT_POWER_STOCK,FEAT_SHADOW_SHOT,FEAT_RED_FANG,FEAT_BLESSING_BLOOD,
    FEAT_COUNTER_PREPARATION,FEAT_KARMIC_TIME,FEAT_KARMIC_RING,FEAT_KARMIC_STRING,FEAT_HI_SMASH,
    FEAT_HI_POWER_STOCK,FEAT_HI_AIMING,FEAT_HI_RAPID_SWORD,FEAT_HI_KARMIC_STRING,FEAT_HI_FRENZY_EYES,
    FEAT_HI_SHADOW_SHOT,FEAT_LAND_MINE,FEAT_DESPERADO,FEAT_REJECT_SWORD,FEAT_COUNTER_GUARD,
    FEAT_PAIN_FLEE,FEAT_BODY_OF_LIGHT,FEAT_SEAL_CHAIN,FEAT_PURIFICATION_LIGHT,FEAT_CRAFTINESS,
    FEAT_LAND_BOMB,FEAT_REJECT_BLADE,FEAT_SPELL_CHAIN,FEAT_INDOMITABLE_MIND,FEAT_DRAIN_SOUL,
    FEAT_BACK_STAB,FEAT_ENLIGHTENED,FEAT_DARK_WHIRLPOOL,FEAT_KARMIC_PHANTOM,FEAT_RECOVERY_WAVE,
    FEAT_SELF_DESTRUCTION,FEAT_DEFFENCE_SHOOTING,FEAT_RECOVERY,FEAT_SHADOW_ATTACK,FEAT_SUICIDAL_TENDENCIES,
    FEAT_MISFIT,FEAT_BIG_BRAGG,FEAT_LETS_KNIFE,FEAT_SINGLE_HEART,FEAT_DOUBLE_BODY,
    FEAT_NINE_SOUL,FEAT_THIRTEEN_EYES,FEAT_LIFE_DRAIN, FEAT_RANDOM_CURSE, FEAT_HEAL_VOICE,
    FEAT_DOUBLE_ATTACK, FEAT_PARTY_DAMAGE, FEAT_GUARD, FEAT_DEATH_CONTROL, FEAT_WIT,
    FEAT_THORN_CARE, FEAT_LIBERATING_SWORD, FEAT_ONE_SLASH, FEAT_TEN_SLASH, FEAT_HANDLED_SLASH,
    FEAT_CURSE_CARE, FEAT_MOON_SHINE, FEAT_RAPTURE, FEAT_DOOMSDAY, FEAT_HELL,
    FEAT_AWAKING, FEAT_MOVING_ONE, FEAT_ARROGANT_ONE, FEAT_EATING_ONE, FEAT_REVIVING_ONE,
    FEAT_WHITE_LIGHT, FEAT_CRYSTAL_SHIELD, FEAT_SNOW_BALLING, FEAT_SOLVENT_RAIN, FEAT_AWAKING_DOOR,
    FEAT_OVER_DOSE, FEAT_RAZORS_EDGE, FEAT_HELLS_BELL, FEAT_DRAIN_SEED, FEAT_ATK_DRAIN,
    FEAT_DEF_DRAIN, FEAT_MOV_DRAIN, FEAT_POISON_SKIN, FEAT_ROAR, FEAT_FIRE_BREATH,
    FEAT_WHIRL_WIND, FEAT_ACTIVE_ARMOR, FEAT_SCOLOR_ATTACK, FEAT_HEAT_SEEKER, FEAT_PURGE,
    FEAT_HIGH_HAND, FEAT_JACK_POT, FEAT_LOW_BALL, FEAT_GAMBLE, FEAT_BIRD_CAGE,
    FEAT_HANGING, FEAT_BLAST_OFF, FEAT_PUPPET_MASTER, FEAT_CTL, FEAT_BPA,
    FEAT_LAR, FEAT_SSS, FEAT_COUNTER_RUSH, FEAT_DISASTER_FLAME, FEAT_HELL_FIRE,
    FEAT_BLINDNESS, FEAT_FIRE_DISAPPEAR, FEAT_DARK_HOLE, FEAT_TANNHAUSER_GATE, FEAT_SCHWAR_BLITZ,
    FEAT_HI_ROUNDER, FEAT_BLOOD_RETTING, FEAT_ACUPUNCTURE, FEAT_DISSECTION, FEAT_EUTHANASIA,
    FEAT_ANGER_NAIL, FEAT_CALM_BACK, FEAT_BLUE_EYES, FEAT_WOLF_FANG, FEAT_HAGAKURE,
    FEAT_REPPU, FEAT_ENPI, FEAT_MIKAZUKI, FEAT_CASABLANCA, FEAT_RHODESIA,
    FEAT_MADRIPOOL, FEAT_ASIA, FEAT_DEMONIC, FEAT_SHADOW_SWORD, FEAT_PERFECT_DEAD,
    FEAT_DESTRUCT_GEAR, FEAT_POWER_SHIFT, FEAT_KILL_SHOT, FEAT_DEFRECT, FEAT_FLAME_OFFERING,
    FEAT_DRAIN_HAND, FEAT_FIRE_PRIZON, FEAT_TIME_STOP, FEAT_DEAD_GUARD, FEAT_DEAD_BLUE,
    FEAT_EVIL_GUARD, FEAT_ABYSS_EYES, FEAT_DEAD_RED, FEAT_NIGHT_GHOST, FEAT_AVATAR_WAR,
    FEAT_CONFUSE_POOL, FEAT_PROMINENCE, FEAT_BATTLE_AXE, FEAT_MOAB, FEAT_OVER_HEAT,
    FEAT_BLUE_ROSE, FEAT_WHITE_CROW, FEAT_RED_MOON, FEAT_BLACK_SUN, FEAT_GIRASOLE,
    FEAT_VIOLETTA, FEAT_DIGITALE, FEAT_ROSMARINO, FEAT_HACHIYOU, FEAT_STONE_CARE,
    FEAT_DUST_SWORD, FEAT_ILLUSION, FEAT_DESPAIR_SHOUT, FEAT_DARKNESS_SONG, FEAT_GUARD_SPIRIT,
    FEAT_SLAUGHTER_ORGAN, FEAT_FOOLS_HAND, FEAT_TIME_SEED, FEAT_IRONGATE_OF_FATE, FEAT_GATHERER,
    FEAT_JUDGE, FEAT_DREAM, FEAT_ONE_ABOVE_ALL, FEAT_ANTISEPTIC, FEAT_SILVER_MACHINE,
    FEAT_ATOM_HEART, FEAT_ELECTRIC_SURGERY, FEAT_ACID_EATER, FEAT_DEAD_LOCK, FEAT_BEGGARS_BANQUET,
    FEAT_SWAN_SONG, FEAT_IDLE_GRAVE, FEAT_SORROW_SONG, FEAT_RED_WHEEL, FEAT_RED_POMEGRANATE,
    FEAT_CLOCK_WORKS, FEAT_TIME_HUNT, FEAT_TIME_BOMB, FEAT_IN_THE_EVENING, FEAT_FINAL_WALTZ,
    FEAT_DESPERATE_SONATA, FEAT_GLADIATOR_MARCH, FEAT_REQUIEM_OF_REVENGE, FEAT_DELICIOUS_MILK, FEAT_EASY_INJECTION,
    FEAT_BLOOD_COLLECTING, FEAT_SECRET_MEDICINE, FEAT_ICE_GATE, FEAT_FIRE_GATE, FEAT_BREAK_GATE,
    FEAT_SHOUT_OF_GATE, FEAT_FERREOUS_ANGER, FEAT_NAME_OF_CHARITY, FEAT_GOOD_WILL, FEAT_GREAT_VENGEANCE,
    FEAT_INNOCENT_SOUL, FEAT_INFALLIBLE_DEED, FEAT_IDLE_FATE, FEAT_REGRETTABLE_JUDGMENT, FEAT_SIN_WRIGGLE,
    FEAT_IDLE_GROAN, FEAT_CONTAMINATION_SORROW, FEAT_FAILURE_GROAN, FEAT_CATHEDRAL, FEAT_WINTER_DREAM,
    FEAT_TENDER_NIGHT, FEAT_FORTUNATE_REASON, FEAT_RUD_NUM, FEAT_VON_NUM, FEAT_CHR_NUM,
    FEAT_WIL_NUM, FEAT_PRECISION_FIRE, FEAT_PURPLE_LIGHTNING, FEAT_MORTAL_STYLE, FEAT_BLOODY_HOWL,
    FEAT_CHARGED_THRUST, FEAT_SWORD_DANCE, FEAT_SWORD_AVOID,
    FEAT_KUTUNESIRKA,FEAT_FEET_OF_HERMES,FEAT_AEGIS_WING,FEAT_CLAIOMH_SOLAIS,
    FEAT_MUTATION,FEAT_RAMPANCY,FEAT_SACRIFICE_OF_SOUL,FEAT_SILVER_BULLET,FEAT_PUMPKIN_DROP,
    FEAT_WANDERING_FEATHER,FEAT_SHEEP_SONG,FEAT_DREAM_OF_OVUERYA,FEAT_MARYS_SHEEP,
    FEAT_EVIL_EYE,FEAT_BLACK_ARTS,FEAT_BLASPHEMY_CURSE,FEAT_END_OF_END,FEAT_THRONES_GATE,FEAT_GHOST_RESENTMENT,
    FEAT_CURSE_SWORD,FEAT_RAPID_SWORD_R2,FEAT_ANGER_R,FEAT_VOLITION_DEFLECT,FEAT_SHAROW_SHOT_R,
    FEAT_BURNING_TAIL,FEAT_QUAKE_WALK,FEAT_DRAINAGE,FEAT_SMILE,FEAT_BLUTKONTAMINA,FEAT_COLD_EYES,
    FEAT_FEAT1,FEAT_FEAT2,FEAT_FEAT3,FEAT_FEAT4,FEAT_WEASEL,FEAT_DARK_PROFOUND,FEAT_KARMIC_DOR,FEAT_BATAFLY_MOV,
    FEAT_BATAFLY_ATK,FEAT_BATAFLY_DEF,FEAT_BATAFLY_SLD,FEAT_GRACE_COCKTAIL,FEAT_LAND_MINE_R,FEAT_NAPALM_DEATH,
    FEAT_SUICIDAL_FAILURE,FEAT_BIG_BRAGG_R,FEAT_LETS_KNIFE_R,FEAT_PREY,FEAT_RUMINATION,FEAT_PILUM,
    FEAT_ROAD_OF_UNDERGROUND,FEAT_FOX_SHADOW,FEAT_FOX_SHOOT,FEAT_FOX_ZONE,FEAT_ARROW_RAIN,
    FEAT_ATEMWENDE,FEAT_FADENSONNEN,FEAT_LICHTZWANG,FEAT_SCHNEEPART,FEAT_HIGHGATE,FEAT_DORFLOFT,FEAT_LUMINES,
    FEAT_SUPER_HEROINE,FEAT_STAMPEDE,FEAT_DEATH_CONTROL2,FEAT_KENGI,FEAT_DOKOWO,FEAT_MIKITTA,FEAT_HONTOU,
    FEAT_INVITED,FEAT_THROUGH_HAND,FEAT_PROF_BREATH,FEAT_SEVEN_WISH,FEAT_THIRTEEN_EYES_R,
    FEAT_THORN_CARE_R,FEAT_LIBERATING_SWORD_R,FEAT_CURSE_SWORD_R,FEAT_FLAME_RING,
    FEAT_PIANO,FEAT_ONA_BALL,FEAT_VIOLENT,FEAT_BALANCE_LIFE,FEAT_LIFETIME_SOUND,FEAT_COMA_WHITE,
    FEAT_GOES_TO_DARK,FEAT_EX_COUNTER_GUARD,FEAT_EX_THIRTEEN_EYES,FEAT_EX_RAZORS_EDGE,FEAT_EX_RED_MOON,
    FEAT_HASSEN,FEAT_HANDLED_SLASH_R,FEAT_RAKSHASA_STANCE,FEAT_OBITUARY,FEAT_SOLVENT_RAIN_R,
    FEAT_KIRIGAKURE,FEAT_MIKAGAMI,FEAT_MUTUAL_LOVE,FEAT_MERE_SHADOW,FEAT_SCAPULIMANCY,FEAT_SOIL_GUARD,
    FEAT_CARAPACE_SPIN,FEAT_VENDETTA,FEAT_AVENGERS,FEAT_SHARPEN_EDGE,FEAT_HACKNINE,FEAT_BLACK_MAGEIA,
    FEAT_CORPS_DRAIN,FEAT_INVERT,FEAT_NIGHT_HAWK,FEAT_PHANTOM_BARRETT,FEAT_ONE_ACT,FEAT_FINAL_BARRETT,
    FEAT_GRIMMDEAD,FEAT_WUNDERKAMMER,FEAT_CONSTRAINT,FEAT_RENOVATE_ATRANDOM,FEAT_BACKBEARD,
    FEAT_SHADOW_STITCH,FEAT_MEXTLI,FEAT_RIVET_AND_SURGE,FEAT_PHANTOMAS,FEAT_DANGER_DRUG,
    FEAT_THREE_THUNDER,FEAT_PRIME_HEAL,FEAT_FOUR_COMET,FEAT_CLUB_JUGG,FEAT_KNIFE_JUGG,
    FEAT_BLOWING_FIRE,FEAT_BALANCE_BALL,FEAT_BAD_MILK,FEAT_MIRA_HP,FEAT_SKILL_DRAIN,FEAT_COFFIN,
    FEAT_DARK_EYES,FEAT_CROWS_CLAW,FEAT_MOLE,FEAT_SUNSET,FEAT_VINE,FEAT_GRAPE_VINE,
    FEAT_THUNDER_STRUCK,FEAT_WEAVE_WORLD,FEAT_COLLECTION,FEAT_RESTRICTION,FEAT_DABS,FEAT_VIBRATION,
    FEAT_TOT,FEAT_DUCK_APPLE,FEAT_RAMPAGE,FEAT_SCRATCH_FIRE,FEAT_BLUE_RUIN,FEAT_THIRD_STEP,
    FEAT_METAL_SHIELD,FEAT_MAGNETIC_FIELD,FEAT_AFTERGLOW,FEAT_KEEPER,FEAT_HEALING_SCHOCK,
    FEAT_CLAYMORE,FEAT_TRAP_CHASE,FEAT_PANIC,FEAT_BULLET_COUNTER,FEAT_BEAN_STORM,
    FEAT_JOKER, FEAT_FAMILIAR, FEAT_CROWN_CROWN, FEAT_RIDDLE_BOX,FEAT_FLUTTER_SWORD_DANCE,
    FEAT_RITUAL_OF_BRAVERY,FEAT_HUNTING_CHEETAH,FEAT_PROBE,FEAT_TAILORING,FEAT_CUT,
    FEAT_SEWING,FEAT_CANCELLATION,FEAT_SEIHO,FEAT_DOKKO,FEAT_NYOI,FEAT_KONGO,
    FEAT_CARP_QUAKE,FEAT_CARP_LIGHTNING,FEAT_FIELD_LOCK,FEAT_ARREST,FEAT_QUICK_DRAW,
    FEAT_GAZE,FEAT_MONITORING,FEAT_TIME_LAG_DRAW,FEAT_TIME_LAG_BUFF,FEAT_DAMAGE_TRANSFER,
    FEAT_CIGARETTE,FEAT_THREE_CARD,FEAT_CARD_SEARCH,FEAT_ALL_IN_ONE,FEAT_FIRE_BIRD,FEAT_BRAMBLES,
    FEAT_FRANKEN_TACKLE,FEAT_FRANKEN_CHARGING,FEAT_MOVING_ONE_R,FEAT_ARROGANT_ONE_R,
    FEAT_EATING_ONE_R,FEAT_HARF_DEAD,FEAT_MACHINE_CELL,FEAT_HEAT_SEEKER_R,FEAT_DIRECTIONAL_BEAM,
    FEAT_DELTA,FEAT_SIGMA,FEAT_STAMP,FEAT_ACCELERATION,FEAT_FOAB,FEAT_WHITE_MOON,
    FEAT_ANGER_BACK= (1..447).to_a


    # 13の目シリーズ
    THIRTEEN_EYES=[FEAT_THIRTEEN_EYES,FEAT_EX_THIRTEEN_EYES,FEAT_THIRTEEN_EYES_R]

    # 技の属性の定数
    ATTRIBUTE_DEATH,ATTRIBUTE_HALF,ATTRIBUTE_CONSTANT,ATTRIBUTE_DYING,ATTRIBUTE_ZAKURO,
    ATTRIBUTE_HP_EXCHANGE,ATTRIBUTE_DIFF,ATTRIBUTE_SELF_INJURY,ATTRIBUTE_REFLECTION,ATTRIBUTE_COUNTER,
    ATTRIBUTE_SPECIAL_COUNTER = (1..11).to_a

    # ダメージイベント用。ダメージの由来を示すフラグ。(由来が対戦相手:false, それ以外:true)。省略可。デフォルト値:false
    IS_HOSTILE_DAMAGE = false
    IS_NOT_HOSTILE_DAMAGE = true

    # フェイズ識別子

    PHASE_ATTACK = "攻撃"
    PHASE_DEFENSE = "防御"
    PHASE_MOVE = "移動"

    # レンジ定数
    AI_RANGE_ALL = [1, 2, 3]
    AI_RANGE_ARROW = [2, 3]
    AI_RANGE_SWORD = [1]
    AI_RANGE_NOTHING = []

    # カメのID
    TURTLES_ID = (30036 .. 30039).to_a.concat((30119 .. 30121).to_a)
    # 巨人岩石
    ROCK_SPIRITS_ID = (30125 .. 30128).to_a

    # ノイクローム
    NOICHROME_ID = 57

    # パーティダメージのタイプ
    TARGET_TYPE_SINGLE = 0
    TARGET_TYPE_RANDOM = 1
    TARGET_TYPE_ALL = 2
    TARGET_TYPE_HP_MIN = 3

    def initialize(c, cc)
      @cc = cc
      super
      share_context(c)
      # 必殺技を登録
      @feats = { }
      @cc.feat_inventories.each do |f|
        @feats[f.feat.feat_no] = f.feat.id
      end
      # パッシブを登録
      @passives = { }
      @cc.passive_skill_inventories.each do |s|
        @passives[s.passive_skill.passive_skill_no] = s.passive_skill.id
      end
      wp = owner.weapon_passives(@cc.index)
      if wp
        wp.each do |p|
          pno = PassiveSkill[p].passive_skill_no
          @passives[pno] = p if !@passives.key?(pno)
        end
      end
      @feats_enable = { }
      @used_feats = { }
      @passives_enable = { }
    end

    def init_feats_enable
      @feats_enable = { }
    end

    def init_passives_enable
      @passives_enable = { }
    end

    def reset_feats_enable
      @feats_enable.each do |k, v|
        @feats_enable[k] = false
      end
    end

    def reset_passives_enable
      @passives_enable.each do |k, v|
        @passives_enable[k] = false
      end
    end

    def finalize_event
      @cc =nil
    end

    # 複数の要素から影響を受ける特殊ダメージ量を評価する
    def attribute_damage(attribute, target, d=0)

      ret = 0

      # 完全無効化の類
      if target.current_chara_card.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] > 0 && d > 0
        case attribute
        when ATTRIBUTE_DEATH, ATTRIBUTE_DIFF
          # DEATHは基本的に無効化できない, DIFFはダイスにかかる
        else
          set_state(target.current_chara_card.special_status[SPECIAL_STATE_SHARPEN_EDGE], 1, target.current_chara_card.special_status[SPECIAL_STATE_SHARPEN_EDGE][1]-1)
          target.current_chara_card.finish_sharpen_edge_feat if @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] == 0
          target.duel_message_event(DUEL_MSGDLG_AVOID_DAMAGE, d)
          return ret
        end
      end

      # 倍率変動の類
      case attribute
        # 即死  無効化される場合に固定ダメージを返す。
      when ATTRIBUTE_DEATH
        if instant_kill_guard?(target)
          owner.attribute_regist_message_event(:ATTRIBUTE_REGIST_MESSAGE_DEATH)
          ret = target.instant_kill_damage
        else
          ret = 99
        end

        # 割合(1/2)ダメージ  無効化される場合に固定ダメージを返す。
      when ATTRIBUTE_HALF
        if instant_kill_guard?(target)
          owner.attribute_regist_message_event(:ATTRIBUTE_REGIST_MESSAGE_HALF)
          ret = (target.instant_kill_damage*0.5).to_i

        else
          ret = (target.hit_point/2).to_i
        end

        # 固定値ダメージ  特定のスキルで軽減・無効化する。
      when ATTRIBUTE_CONSTANT
        if target.invincible
          ret = 0
        elsif target.is_indomitable
          dmg = target.hit_point - d < 1 ? target.hit_point - 1 : d
          ret = dmg < 0 ? 0 : dmg
        elsif target.const_damage_guard
          use_volition_deflect_feat_damage(d)
          ret = 0
        elsif (target.current_chara_card.special_status[SPECIAL_STATE_CONST_COUNTER][1] > 0 && target.current_chara_card.special_status[SPECIAL_STATE_CONST_COUNTER][0] >= d)
          owner.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION,owner,d))
          ret = 0
        elsif target.current_chara_card.status[STATE_UNDEAD2][1] > 0
          ret = 0
        else
          ret = d
        end

        # 瀕死(相手のHPをdmgにする)  無効化される場合に固定ダメージを返す。
      when ATTRIBUTE_DYING
        if instant_kill_guard?(target)
          owner.attribute_regist_message_event(:ATTRIBUTE_REGIST_MESSAGE_DYING)
          ret = target.instant_kill_damage - d

        else
          ret = target.hit_point - d
        end
        ret = 0 if ret < 0

        # 赤い石榴の対BOSS用特殊効果  ダメージの期待値が即死技とおよそ同等になるよう調整。HP99への固定は99pt回復に変更。
      when ATTRIBUTE_ZAKURO
        if d == 99
          ret = instant_kill_guard?(target) ? d : d - target.hit_point
        else
          ret = instant_kill_guard?(target) ? target.instant_kill_damage*(8 - d) : target.hit_point - d
        end

        # HP交換  無効化される場合、使用者のダメージ量に等しいダメージを相手に与える。
      when ATTRIBUTE_HP_EXCHANGE
        if instant_kill_guard?(target)
          owner.attribute_regist_message_event(:ATTRIBUTE_REGIST_MESSAGE_EXCHANGE)
          ret = owner.current_hit_point_max - owner.hit_point
        else
          ret = d
        end

        # 最大HPとの差によるダメージ(d=最大HP-d)  無効化される場合に固定ダメージを返す。
      when ATTRIBUTE_DIFF
        dmg = target.current_hit_point_max - d
        if instant_kill_guard?(target)
          owner.attribute_regist_message_event(:ATTRIBUTE_REGIST_MESSAGE_DIFF)
          ret = target.instant_kill_damage - d

        elsif target.is_indomitable
          dmg = target.hit_point - dmg < 1 ? target.hit_point - 1 : dmg
          ret = dmg < 0 ? 0 : dmg

        else
          ret = target.current_hit_point_max - d
        end

        # 自傷によるダメージ
      when ATTRIBUTE_SELF_INJURY
        dmg = target.current_chara_card.status[STATE_UNDEAD2][1] > 0 ? 0 : d
        ret = dmg

        # 反射によるダメージ
      when ATTRIBUTE_REFLECTION
        dmg = target.current_chara_card.status[STATE_UNDEAD2][1] > 0 ? 0 : d
        dmg = target.current_chara_card.is_senkou? ? dmg*7 : dmg
        dmg = target.current_chara_card.in_carapace? ? dmg*5 : dmg
        ret = dmg

        # カウンターによるダメージ
      when ATTRIBUTE_COUNTER
        dmg = target.current_chara_card.status[STATE_UNDEAD2][1] > 0 ? 0 : d
        dmg = target.current_chara_card.is_senkou? ? dmg*7 : dmg
        dmg = target.current_chara_card.in_carapace? ? dmg*5 : dmg
        ret = dmg

        # 割合ダメージ、即死系のカウンター
      when ATTRIBUTE_SPECIAL_COUNTER
        dmg = target.current_chara_card.is_senkou? ? d*7 : d
        dmg = target.current_chara_card.in_carapace? ? dmg*5 : dmg
        ret = dmg

      end

      ret += owner.tmp_focus
      ret *= target.magnification_hurt_const_damage
      if target == foe
        ret *= owner.magnification_cause_const_damage
        ret *= gen_multipler_num(PassiveSkill.pow(@passives[PASSIVE_DAMAGE_MULTIPLIER])) if maltipl_damage?(target)
        ret *= get_carapace_multi_num if carapace_break?(foe)
        ret *= get_rock_crusher_multi_num if rock_crusher?(foe)
      end

      return ret

    end

    # パーティダメージ量を評価する
    def attribute_party_damage(target, indexies, damage, attribute=ATTRIBUTE_CONSTANT, type=TARGET_TYPE_SINGLE, attack_times=1, is_not_hostile=false)
      idxs = indexies.kind_of?(Array) ? indexies : [indexies]

      return if idxs.size == 0

      case type
        # 単一の相手を対象とする
      when TARGET_TYPE_SINGLE
        attack_times.times do
          damage_to_index(target, idxs[0], damage, attribute, type, is_not_hostile)
        end

        # 受け取ったインデックスの中から、毎回ランダムで対象を選ぶ
      when TARGET_TYPE_RANDOM
        attack_times.times do
          target_index = idxs[rand(idxs.size)]
          damage_to_index(target, target_index, damage, attribute, type, is_not_hostile)
          idxs.delete(target_index) if target.hit_points[target_index] < 1
          break if idxs.size == 0
        end

        # 受け取ったインデックス全てが対象
      when TARGET_TYPE_ALL
        attack_times.times do
          idxs.each do |i|
            damage_to_index(target, i, damage, attribute, type, is_not_hostile)
          end
        end

        # HPが最小のインデックスが対象
      when TARGET_TYPE_HP_MIN
        hps = []
        idxs.each do |i|
          hps << [i, target.hit_points[i]]
        end
        attack_times.times do
          damage_to_index(target, hps.sort{ |a,b| a[1] <=> b[1] }[0][0], damage, attribute, type, is_not_hostile)
        end
      end

    end

    # 指定したIndexへダメージを与える
    def damage_to_index(target, index, damage, attribute, type, is_not_hostile)

      # 割り込み攻撃回避動作
      case type
      when TARGET_TYPE_ALL
        # TYPE_ALL を除き、庇う効果
      else
        if target.hit_point > 0 &&
            target.current_chara_card.event.passives_enable[PASSIVE_LOYALTY] &&
            index == get_last_index(target) &&
            !is_not_hostile

          index = target.current_chara_card_no
        end
      end

      # 攻撃実行
      if index == target.current_chara_card_no
        target.damaged_event(attribute_damage(attribute,foe,damage), is_not_hostile)
      else
        unless target.chara_cards[index].status[STATE_UNDEAD2][1] > 0
          target.party_damaged_event(index, damage, is_not_hostile)
        end
      end
    end

    def get_last_index(target)
      target.hit_points.size-1
    end

    # ===========================================
    # パッシブ関連のイベント
    # ===========================================
    # ------------------
    # 追加ドロー
    # ------------------
    # 追加ドローを発動可能状態にする
    def check_additional_draw_passive
      if @cc.using
        check_and_on_passive(PASSIVE_ADDITIONAL_DRAW)
      end
    end
    regist_event CheckAdditionalDrawPassiveEvent

    # 追加ドローを発動終了する
    def finish_additional_draw_passive
      if @passives_enable[PASSIVE_ADDITIONAL_DRAW]
        owner.special_dealed_event(duel.deck.draw_cards_event(PassiveSkill.pow(@passives[PASSIVE_ADDITIONAL_DRAW])).each{ |c| owner.dealed_event(c)})
        off_passive_event(true, PASSIVE_ADDITIONAL_DRAW)
      end
      @passives_enable[PASSIVE_ADDITIONAL_DRAW] = false
    end
    regist_event FinishAdditionalDrawPassiveEvent

    # ------------------
    # 不屈
    # ------------------
    # 不屈を発動可能状態にする
    def check_indomitable_mind_passive
      if @cc.using && !owner.initiative && @cc.owner.distance != 2 && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_INDOMITABLE_MIND)
      end
    end
    regist_event CheckIndomitableMindPassiveEvent
    regist_event CheckIndomitableMindPassiveChangeEvent

    # 不屈を発動終了する
    def use_indomitable_mind_passive_damage
      if @passives_enable[PASSIVE_INDOMITABLE_MIND]
        if @cc.owner.hit_point - duel.tmp_damage < PassiveSkill.pow(@passives[PASSIVE_INDOMITABLE_MIND])
          duel.tmp_damage = @cc.owner.hit_point - PassiveSkill.pow(@passives[PASSIVE_INDOMITABLE_MIND])
          duel.tmp_damage = 0 if duel.tmp_damage < 0
        end
      end
    end
    regist_event UseIndomitableMindPassiveDamageEvent

    # 不屈を発動終了する
    def finish_indomitable_mind_passive
      if @passives_enable[PASSIVE_INDOMITABLE_MIND]
        off_passive_event(true, PASSIVE_INDOMITABLE_MIND)
        @passives_enable[PASSIVE_INDOMITABLE_MIND] = false
      end
    end
    regist_event FinishIndomitableMindPassiveEvent
    regist_event FinishIndomitableMindPassiveDeadCharaChangeEvent

    # ------------------
    # 精神の器
    # ------------------
    # 精神の器を発動可能状態にする
    def check_drain_soul_passive
      if @cc.using
        check_and_on_passive(PASSIVE_DRAIN_SOUL)
      end
    end
    regist_event CheckDrainSoulPassiveEvent

    # 精神の器を発動終了する
    def finish_drain_soul_passive
      if @passives_enable[PASSIVE_DRAIN_SOUL]
        # 相手のカードを奪う

        drain_cond = false  # 吸収発動するか
        pow = 0             # 枚数
        if foe.current_chara_card.kind == CC_KIND_MONSTAR ||
            foe.current_chara_card.kind == CC_KIND_BOSS_MONSTAR ||
            foe.current_chara_card.kind == CC_KIND_PROFOUND_BOSS
          drain_cond = true
          pow = PassiveSkill.pow(@passives[PASSIVE_DRAIN_SOUL]) + 2
        else
          drain_cond = owner.get_type_cards_count_both_faces(ActionCard::SPC) <= foe.get_type_cards_count_both_faces(ActionCard::SPC)
          pow = PassiveSkill.pow(@passives[PASSIVE_DRAIN_SOUL])
        end

        if foe.cards.size > 0 && drain_cond
          tmp_cards = foe.cards.dup.sort_by{rand}
          tmp_count = 0
          tmp_cards.each do |c|
            if c.u_type == ActionCard::SPC || c.b_type == ActionCard::SPC
              steal_deal(c)
              tmp_count += 1
            end
            break if tmp_count >= pow
          end
        end
        off_passive_event(true, PASSIVE_DRAIN_SOUL)
      end
      @passives_enable[PASSIVE_DRAIN_SOUL] = false
    end
    regist_event FinishDrainSoulPassiveEvent

    # ------------------
    # 封印攻撃(剣聖)
    # ------------------
    # 封印攻撃を発動可能状態にする
    def check_sealing_attack_passive
      if @cc.using && owner.initiative && @cc.owner.distance == 1 && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_SEALING_ATTACK)
      end
    end
    regist_event CheckSealingAttackPassiveEvent
    regist_event CheckSealingAttackPassiveChangeEvent

    # 封印攻撃を発動終了する
    def finish_sealing_attack_passive
      if @passives_enable[PASSIVE_SEALING_ATTACK]
        # 相手の変身を解除
        off_transform_sequence(false) if foe.is_transforming
        # 相手の必殺技を解除
        foe.current_chara_card.reset_override_feats
        foe.current_chara_card.reset_special_status()
        foe.current_chara_card.remove_singlton_method_rakshasa_stance_feat()
        foe.sealed_event()
        off_passive_event(true, PASSIVE_SEALING_ATTACK)
      end
      @passives_enable[PASSIVE_SEALING_ATTACK] = false
    end
    regist_event FinishSealingAttackPassiveEvent


    # ------------------
    # 千古不朽
    # ------------------
    # 千古不朽を発動する。
    def check_instant_kill_guard_passive
      if @cc.using
        @cc.owner.instant_kill_damage = PassiveSkill.pow(@passives[PASSIVE_INSTANT_KILL_GUARD])
        force_on_passive(PASSIVE_INSTANT_KILL_GUARD)
      end
    end
    regist_event CheckInstantKillGuardPassiveStartTurnEvent

    # パッシブインベントリを直接見て判定
    def instant_kill_guard?(target)
      ret = false
      target.current_chara_card.passive_skill_inventories.each do |p|
        if p.passive_skill.passive_skill_no == PASSIVE_INSTANT_KILL_GUARD || p.passive_skill.passive_skill_no == PASSIVE_LINKAGE || p.passive_skill.passive_skill_no == PASSIVE_CREATOR
          target.current_chara_card.set_instant_kill_base_damage(target, p.passive_skill.passive_skill_no)
          return true
        end
      end
      ret
    end

    def set_instant_kill_base_damage(target, passive_skill_no)
      target.instant_kill_damage = PassiveSkill.pow(@passives[passive_skill_no])
    end

    # ------------------
    # レイジ
    # ------------------
    # レイジを発動チェック
    def check_rage_against_passive
      # 相手キャラクターに自分へのダメージを与えたキャラがいる
      if @cc.using && duel.profound_id
        chara_set =  ProfoundLog::get_chara_ranking_no_set(duel.profound_id, PassiveSkill.pow(@passives[PASSIVE_RAGE_AGAINST]))
        if chara_set.include?(foe.current_chara_card.charactor_id)
          on_passive_event(true, PASSIVE_RAGE_AGAINST) unless @passives_enable[PASSIVE_RAGE_AGAINST]
          @passives_enable[PASSIVE_RAGE_AGAINST] = true
          on_rage_against_event(chara_set)
        else
          off_passive_event(true, PASSIVE_RAGE_AGAINST) if @passives_enable[PASSIVE_RAGE_AGAINST]
          @passives_enable[PASSIVE_RAGE_AGAINST] = false
        end
      else
        @passives_enable[PASSIVE_RAGE_AGAINST] = false if @passives_enable[PASSIVE_RAGE_AGAINST]
        off_passive_event(true, PASSIVE_RAGE_AGAINST)
      end
    end
    regist_event CheckRageAgainstPassiveCharaChangeEvent
    regist_event CheckRageAgainstPassiveDeadChangeEvent



    # レイジを発動チェック。（最初のターンだけ1回だけチェックする。毎ターンしないのは重いから）
    def check_rage_against_only_first_turn_passive
      if duel.turn == 0
          check_rage_against_passive
      end
    end
    regist_event CheckRageAgainstPassiveStartEvent


    # レイジ発動。攻撃時に基本攻撃力を二倍にする
    def finish_rage_against_passive
      if @passives_enable[PASSIVE_RAGE_AGAINST]
        owner.tmp_power += @cc.ap if owner.tmp_power > 0
      end
    end
    regist_event FinishRageAgainstPassiveEvent

    # レイジアゲンストが有効になったときのイベント
    def on_rage_against(chara_set)
      chara_set
    end
    regist_event OnRageAgainstEvent

    # ------------------
    # 創造主
    # ------------------
    def check_creator_passive
      if @cc.using
        @cc.owner.transformable = true
        @cc.owner.instant_kill_damage = PassiveSkill.pow(@passives[PASSIVE_CREATOR])
        on_passive_event(true, PASSIVE_CREATOR) unless @passives_enable[PASSIVE_CREATOR]
        @passives_enable[PASSIVE_CREATOR] = true
        transform_of_fire if duel.turn == 18 && owner.chara_cards[owner.current_chara_card_no].id != 20011
      end
    end
    regist_event CheckCreatorPassiveStartTurnEvent
    regist_event CheckCreatorPassiveCharaChangeEvent
    regist_event CheckCreatorPassiveDeadCharaChangeEvent

    def finish_creator_passive
      unless @cc.using
        @cc.owner.transformable = false
        @cc.owner.instant_kill_damage = 0
        off_passive_event(true, PASSIVE_CREATOR) if @passives_enable[PASSIVE_CREATOR]
        @passives_enable[PASSIVE_CREATOR] = false
      end
    end
    regist_event FinishCreatorPassiveCharaChangeEvent
    regist_event FinishCreatorPassiveDeadCharaChangeEvent
    regist_event FinishCreatorPassiveFinishTurnEvent

    def use_creator_passive
      if @passives_enable[PASSIVE_CREATOR]
        transform_of_fire if @cc.owner.hit_point <=0 && owner.chara_cards[owner.current_chara_card_no].id != 20011
      end
    end
    regist_event UseCreatorPassiveDamageEvent
    regist_event UseCreatorPassiveMovePhaseEvent
    regist_event UseCreatorPassiveDetermineMovePhaseEvent
    regist_event UseCreatorPassiveDetermineBpPhaseEvent
    regist_event UseCreatorPassiveBattleResultPhaseEvent
    #regist_event UseCreatorPassiveCharaChangeEvent

    # ------------------
    # バウンスバック
    # ------------------

    # バウンスバックを発動可能状態にする
    def check_bounce_back_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_BOUNCE_BACK)
      end
    end
    regist_event CheckBounceBackPassiveEvent
    regist_event CheckBounceBackPassiveChangeEvent

    # バウンスバックを発動終了する
    def use_bounce_back_passive_damage
      if @passives_enable[PASSIVE_BOUNCE_BACK]
        if duel.tmp_damage > 0
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(duel.tmp_damage+PassiveSkill.pow(@passives[PASSIVE_BOUNCE_BACK])).each{ |c| @cc.owner.dealed_event(c)})
        end
      end
    end
    regist_event UseBounceBackPassiveDamageEvent

    # バウンスバックを発動終了する
    def finish_bounce_back_passive
      if @passives_enable[PASSIVE_BOUNCE_BACK]
        off_passive_event(true, PASSIVE_BOUNCE_BACK)
        @passives_enable[PASSIVE_BOUNCE_BACK] = false
      end
    end
    regist_event FinishBounceBackPassiveEvent
    regist_event FinishBounceBackPassiveDeadCharaChangeEvent

    # ------------------
    # リンケージ
    # ------------------
    # リンケージを発動する。
    def check_linkage_passive
      if @cc.using
        @cc.owner.instant_kill_damage = PassiveSkill.pow(@passives[PASSIVE_LINKAGE])
        on_passive_event(true, PASSIVE_LINKAGE) unless @passives_enable[PASSIVE_LINKAGE]
        @passives_enable[PASSIVE_LINKAGE] = true
      end
    end
    regist_event CheckLinkagePassiveStartTurnEvent
    regist_event CheckLinkagePassiveCharaChangeEvent
    regist_event CheckLinkagePassiveDeadCharaChangeEvent

    # ------------------
    # リべレーション
    # ------------------

    # リベレーションを使用する
    def use_liberation_passive
      if @cc.using
        if rand(99) < 5
          force_on_passive(PASSIVE_LIBERATION)
          if @cc.status[STATE_SEAL][1] > 0
            @cc.status[STATE_SEAL][1] = 0
            off_buff_event(true, owner.current_chara_card_no, STATE_SEAL, @cc.status[STATE_SEAL][0])
          end
        end
      end
    end
    regist_event UseLiberationPassiveEvent

    # リベレーションを発動終了する
    def finish_liberation_passive
      if @cc.using && @passives_enable[PASSIVE_LIBERATION]
        off_passive_event(true, PASSIVE_LIBERATION)
        @passives_enable[PASSIVE_LIBERATION] = false
      end
    end
    regist_event FinishLiberationPassiveEvent
    regist_event FinishLiberationPassiveDeadCharaChangeEvent

    # ------------------
    # ハーデン
    # ------------------

    # ハーデンを発動可能状態にする
    def check_harden_passive
      if @cc.using
        min = Time.now.min
        if (10 .. 19).include?(min) || (40 .. 49).include?(min)
          force_on_passive(PASSIVE_HARDEN)
        end
      end
    end
    regist_event CheckHardenPassiveEvent

    # ハーデンを発動終了する
    def use_harden_passive_damage
      if @passives_enable[PASSIVE_HARDEN] && !owner.initiative
        ats = duel.dice_attributes
        if ats.include?("special") && !ats.include?("physical")
          duel.tmp_damage *= 2
        elsif !ats.include?("special")
          duel.tmp_damage = (duel.tmp_damage/4).to_i
        end
      end
    end
    regist_event UseHardenPassiveDamageEvent

    # ハーデンを発動終了する
    def finish_harden_passive
      if @passives_enable[PASSIVE_HARDEN]
        off_passive_event(true, PASSIVE_HARDEN)
        @passives_enable[PASSIVE_HARDEN] = false
      end
    end
    regist_event FinishHardenPassiveEvent
    regist_event FinishHardenPassiveDeadCharaChangeEvent

    # ------------------
    # アブソープ
    # ------------------

    # アブソープを発動可能状態にする
    def check_absorp_passive
      if @cc.using
        min = Time.now.min
        if (20 .. 29).include?(min) || (50 .. 59).include?(min)
          unless @passives_enable[PASSIVE_HARDEN]
            force_on_passive(PASSIVE_ABSORP)
          end
        end
      end
    end
    regist_event CheckAbsorpPassiveEvent

    # アブソープを発動終了する
    def use_absorp_passive_damage
      if @passives_enable[PASSIVE_ABSORP] && !owner.initiative
        ats = duel.dice_attributes
        heal_pt = duel.tmp_damage > 5 ? 5 : duel.tmp_damage
        # special のみのとき、ダメージ無効＋回復
        if ats.include?("special") && !ats.include?("physical")
          owner.healed_event(heal_pt)
          duel.tmp_damage = 0
        # physical のみのとき、ダメージ普通＋回復
        elsif ats.include?("special") && ats.include?("physical")
          owner.healed_event(heal_pt)
        # special がないとき、ダメージ2倍
        else
          duel.tmp_damage *= 2
        end
      end
    end
    regist_event UseAbsorpPassiveDamageEvent

    # アブソープを発動終了する
    def finish_absorp_passive
      if @passives_enable[PASSIVE_ABSORP]
        off_passive_event(true, PASSIVE_ABSORP)
        @passives_enable[PASSIVE_ABSORP] = false
      end
    end
    regist_event FinishAbsorpPassiveEvent
    regist_event FinishAbsorpPassiveDeadCharaChangeEvent

    # ------------------
    # 幻月
    # ------------------
    # 発動状態をONにする
    def check_moondog_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_MOONDOG)
      end
    end
    regist_event CheckMoondogPassiveEvent
    regist_event CheckMoondogPassiveChangeEvent

    # 発動終了する
    def use_moondog_passive
      if @passives_enable[PASSIVE_MOONDOG]
        owner.tmp_power += PassiveSkill.pow(@passives[PASSIVE_MOONDOG]) * owner.distance * owner.get_type_table_count(ActionCard::DEF)
      end
    end
    regist_event UseMoondogPassiveEvent

    # 発動終了する
    def finish_moondog_passive
      if @passives_enable[PASSIVE_MOONDOG]
        off_passive_event(true, PASSIVE_MOONDOG)
        @passives_enable[PASSIVE_MOONDOG] = false
      end
    end
    regist_event FinishMoondogPassiveEvent
    regist_event FinishMoondogPassiveDeadCharaChangeEvent

    # ------------------
    # 跳躍
    # ------------------

    # 発動状態をONにする
    def check_jump_passive
      @jump_passive_reduce = 0 unless @jump_passive_reduce
      # 自身が所持する特殊カードの枚数
      spc_num = owner.get_type_table_count_both_faces(ActionCard::SPC) + owner.get_type_cards_count_both_faces(ActionCard::SPC)
      r = rand(100)
      jump_r = (spc_num * 15) + 5 - @jump_passive_reduce
      r_cap = 100 - @jump_passive_reduce*2
      jump_r = r_cap if jump_r > r_cap
      if @cc.using && !owner.initiative && r < jump_r && check_passive(PASSIVE_JUMP)
        @passives_enable[PASSIVE_JUMP] = true
        @jump_passive_pre_hp = owner.hit_point
        @jump_passive_pre_status = Marshal.load(Marshal.dump(owner.current_chara_card.status))
        @jump_passive_pre_cards_max = owner.cards_max
      end
    end
    regist_event CheckJumpPassiveEvent

    def use_jump_passive
      # 発動条件クリア状態で、死んでいたら。
      if @passives_enable[PASSIVE_JUMP] && owner.hit_point < 1
        on_passive_event(true, PASSIVE_JUMP)
        off_transform_sequence(true)
        jump_passive_restore
        owner.change_need=(false)
        owner.change_done=(true)
        owner.cards_max=(@jump_passive_pre_cards_max) if owner.cards_max != @jump_passive_pre_cards_max
        @jump_passive_reduce += 15
        jump_passive_card_reset
      end
    end
    regist_event UseJumpPassiveDamageAfterEvent
    regist_event UseJumpPassiveDamageBeforeEvent
    regist_event UseJumpPassiveDetBpEvent
    regist_event UseJumpPassiveBattleResultBeforeEvent
    regist_event UseJumpPassiveBattleResultAfterEvent

    # 発動終了する
    def finish_jump_passive
      if @passives_enable[PASSIVE_JUMP]
        off_passive_event(true, PASSIVE_JUMP)
        @passives_enable[PASSIVE_JUMP] = false
      end
    end
    regist_event FinishJumpPassiveEvent
    regist_event FinishJumpPassiveDeadCharaChangeEvent

    # HPとステータスを復元する
    def jump_passive_restore
      # HP復元
      owner.hit_point_changed_event(@jump_passive_pre_hp)
      # ステータス復元
      @jump_passive_pre_status.each_index do |i|
        if @cc.status[i][0] != @jump_passive_pre_status[i][0] || @cc.status[i][1] != @jump_passive_pre_status[i][1]
          # 追加されたものを消す
          if @jump_passive_pre_status[i][1] == 0
            off_buff_event(true, owner.current_chara_card_no, i, @cc.status[i][0])
            @cc.status[i][0] = @jump_passive_pre_status[i][0]
            @cc.status[i][1] = @jump_passive_pre_status[i][1]
          else
            # ターン変動 or 消されたものを追加する
            @cc.status[i][0] = @jump_passive_pre_status[i][0]
            @cc.status[i][1] = @jump_passive_pre_status[i][1]
            on_buff_event(true, owner.current_chara_card_no, i, @cc.status[i][0], @cc.status[i][1])
          end
        end
      end
    end

    # 発動時、カードを半分破棄、再度引く
    def jump_passive_card_reset
      ex_num = ((owner.cards.size+1)/2).to_i
      # 破棄候補のカード
      aca = []
      # カードをシャッフルする
      owner.cards.shuffle.each do |c|
        aca << c
      end
      # 手札の半分カードを捨てる。
      before_cards_num = owner.cards.size
      ex_num.times do |a|
        if aca[a]
          discard(owner, aca[a])
        end
      end
      owner.special_dealed_event(duel.deck.draw_cards_event(ex_num).each{ |c| owner.dealed_event(c)}) if owner.cards.size != before_cards_num
    end

    # ------------------
    # プロテクティブエイム
    # ------------------

    # 発動状態をONにする
    def check_protection_aim_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_PROTECTION_AIM)
      end
    end
    regist_event CheckProtectionAimPassiveEvent
    regist_event CheckProtectionAimPassiveChangeEvent

    # 発動終了する
    def use_protection_aim_passive
      if @passives_enable[PASSIVE_PROTECTION_AIM]
        arrow_ap = owner.get_battle_table_point(ActionCard::ARW)
        owner.tmp_power += arrow_ap + 3 if arrow_ap > 0
      end
    end
    regist_event UseProtectionAimPassiveEvent

    # 発動終了する
    def finish_protection_aim_passive
      if @passives_enable[PASSIVE_PROTECTION_AIM]
        off_passive_event(true, PASSIVE_PROTECTION_AIM)
        @passives_enable[PASSIVE_PROTECTION_AIM] = false
      end
    end
    regist_event FinishProtectionAimPassiveEvent
    regist_event FinishProtectionAimPassiveDeadCharaChangeEvent


    regist_event FinishProtectionAimPassiveEvent
    regist_event FinishProtectionAimPassiveDeadCharaChangeEvent
    # ------------------
    # ミステイク
    # ------------------
    # 使用されたかのチェック
    def check_mistake_passive
      if @cc.using && !owner.initiative && !(@cc.status[STATE_UNDEAD2][1] > 0)
        cnt = @passive_mistake_count ? @passive_mistake_count : 0
        # 初回は必ず発動。2回目以降は(hp x 2)/hp_max  発動最大確率を(100-使用回数x30%)でキャップする
        mistake_r = 100
        if cnt > 0
          mistake_r = @cc.owner.hit_point * 2 / @cc.owner.current_hit_point * 100
          r_cap = 100 - (@passive_mistake_count*30)
          mistake_r = r_cap if mistake_r > r_cap
        end
        r = rand(100)
        return if r >= mistake_r || !check_passive(PASSIVE_MISTAKE)
        @passives_enable[PASSIVE_MISTAKE] = true
      end
    end
    regist_event CheckMistakePassiveEvent

    # 使用
    def use_mistake_passive_damage()
      if @passives_enable[PASSIVE_MISTAKE]
        if duel.tmp_damage >= @cc.owner.hit_point && !(@cc.status[STATE_UNDEAD][1] > 0)
          on_passive_event(true, PASSIVE_MISTAKE)
          duel.tmp_damage = 0
          set_state(@cc.status[STATE_ATK_UP], 7, PassiveSkill.pow(@passives[PASSIVE_MISTAKE]));
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
          set_state(@cc.status[STATE_UNDEAD2], 1, PassiveSkill.pow(@passives[PASSIVE_MISTAKE]));
          on_buff_event(true, owner.current_chara_card_no, STATE_UNDEAD2, @cc.status[STATE_UNDEAD2][0], @cc.status[STATE_UNDEAD2][1])
          set_state(@cc.status[STATE_DEAD_COUNT], 1, PassiveSkill.pow(@passives[PASSIVE_MISTAKE]));
          on_buff_event(true, owner.current_chara_card_no, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0], @cc.status[STATE_DEAD_COUNT][1])
          @passive_mistake_count ? @passive_mistake_count += 1 : @passive_mistake_count = 1
        end
      end
    end
    regist_event UseMistakePassiveDamageEvent

    # ミステイクが使用終了
    def finish_mistake_passive()
      if @passives_enable[PASSIVE_MISTAKE]
        off_passive_event(true, PASSIVE_MISTAKE)
        @passives_enable[PASSIVE_MISTAKE] = false
      end
    end
    regist_event FinishMistakePassiveEvent
    regist_event FinishMistakePassiveDeadCharaChangeEvent

    # ------------------
    # 状態抵抗 妖蛆
    # ------------------
    # 状態抵抗をONにする
    def check_status_resistance_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_STATE_RESISTANCE)
        @cc.status[STATE_STONE][2] = 100
        @cc.status[STATE_POISON][2] = 50
        @cc.status[STATE_PARALYSIS][2] = 75
        @cc.status[STATE_SEAL][2] = 90
      end
    end
    regist_event CheckStatusResistancePassiveEvent


    # ------------------
    # 潜行する災厄
    # ------------------
    # 発動状態をONにする HP 3/5 ~ 2/5 まで
    def check_senkou_passive
      if @cc.using && owner.current_hit_point_max*3/5 >= owner.hit_point && owner.hit_point > owner.current_hit_point_max*2/5
        force_on_passive(PASSIVE_SENKOU)
      end
    end
    regist_event CheckSenkouPassiveEvent

    # 発動する
    def use_senkou_passive
      if @passives_enable[PASSIVE_SENKOU]
        owner.tmp_power += PassiveSkill.pow(@passives[PASSIVE_SENKOU])
      end
    end
    regist_event UseSenkouPassiveEvent

    # 発動終了する
    def finish_senkou_passive
      if @passives_enable[PASSIVE_SENKOU]
        off_passive_event(true, PASSIVE_SENKOU)
        @passives_enable[PASSIVE_SENKOU] = false
      end
    end
    regist_event FinishSenkouPassiveEvent
    regist_event FinishSenkouPassiveDeadCharaChangeEvent

    def is_senkou?
      return @passives_enable[PASSIVE_SENKOU]
    end

    # ------------------
    # 果てる路
    # ------------------
    # 発動状態をONにする HP 2/5 ~ 0まで
    def check_hate_passive
      if @cc.using && ((PassiveSkill.pow(@passives[PASSIVE_HATE]) == 7 && owner.current_hit_point_max*2/5 >= owner.hit_point) || (PassiveSkill.pow(@passives[PASSIVE_HATE]) == 5 && owner.current_hit_point_max/2 >= owner.hit_point && foe.current_hit_point_max/2 >= foe.hit_point))
        force_on_passive(PASSIVE_HATE)
      end
    end
    regist_event CheckHatePassiveEvent

    # 発動する
    def use_hate_passive
      if @passives_enable[PASSIVE_HATE]
        owner.tmp_power += PassiveSkill.pow(@passives[PASSIVE_HATE])
      end
    end
    regist_event UseHatePassiveEvent

    # 発動する
    def use_hate_passive_damage
      if @passives_enable[PASSIVE_HATE]
        if @cc&&@cc.index == owner.current_chara_card_no && !owner.initiative
          duel.tmp_damage = duel.tmp_damage * 2
        end
      end
    end
    regist_event UseHatePassiveDamageEvent

    # 発動終了する
    def finish_hate_passive
      if @passives_enable[PASSIVE_HATE]
        off_passive_event(true, PASSIVE_HATE)
        @passives_enable[PASSIVE_HATE] = false
      end
    end
    regist_event FinishHatePassiveEvent
    regist_event FinishHatePassiveDeadCharaChangeEvent

    # ------------------
    # リトルプリンセス
    # ------------------
    # 発動状態をONにする HP 5以上
    def check_little_princess_passive
      if @cc.using && owner.hit_point >= 5 && !@passives_enable[PASSIVE_CRIMSON_WITCH]
        check_and_on_passive(PASSIVE_LITTLE_PRINCESS)
      end
    end
    regist_event CheckLittlePrincessPassiveEvent
    regist_event CheckLittlePrincessChangePassiveEvent

    # 発動する
    def use_little_princess_passive
      if @passives_enable[PASSIVE_LITTLE_PRINCESS] && !owner.initiative
        if duel.tmp_damage > 0
          trigger = @feats_enable[FEAT_ATEMWENDE] ? 20 * Feat.pow(@feats[FEAT_ATEMWENDE]) : 20
          r = rand(100)
          if trigger > r
            duel.tmp_damage = 0
            owner.duel_message_event(DUEL_MSGDLG_LITTLE_PRINCESS)
          end
        end
      end
    end
    regist_event UseLittlePrincessPassiveEvent

    # 発動終了する
    def finish_little_princess_passive
      if @passives_enable[PASSIVE_LITTLE_PRINCESS]
        off_passive_event(true, PASSIVE_LITTLE_PRINCESS)
        @passives_enable[PASSIVE_LITTLE_PRINCESS] = false
      end
    end
    regist_event FinishLittlePrincessPassiveEvent
    regist_event FinishLittlePrincessPassiveDeadCharaChangeEvent

    # ------------------
    # 深紅の魔女
    # ------------------
    # 発動状態をONにする HP 4以下
    def check_crimson_witch_passive
      if @cc.using && owner.hit_point < 5 && !@passives_enable[PASSIVE_LITTLE_PRINCESS]
        check_and_on_passive(PASSIVE_CRIMSON_WITCH)
      end
    end
    regist_event CheckCrimsonWitchPassiveEvent
    regist_event CheckCrimsonWitchChangePassiveEvent

    # 発動する
    def use_crimson_witch_passive
      if @passives_enable[PASSIVE_CRIMSON_WITCH] && owner.initiative
        if duel.tmp_damage > 0
          trigger = @feats_enable[FEAT_ATEMWENDE] ? 20 * Feat.pow(@feats[FEAT_ATEMWENDE]) : 20
          r = rand(100)
          if trigger > r
            duel.tmp_damage *= 2
            owner.duel_message_event(DUEL_MSGDLG_CRIMSON_WITCH)
          end
        end
      end
    end
    regist_event UseCrimsonWitchPassiveEvent

    # 発動終了する
    def finish_crimson_witch_passive
      if @passives_enable[PASSIVE_CRIMSON_WITCH]
        off_passive_event(true, PASSIVE_CRIMSON_WITCH)
        @passives_enable[PASSIVE_CRIMSON_WITCH] = false
      end
    end
    regist_event FinishCrimsonWitchPassiveEvent
    regist_event FinishCrimsonWitchPassiveDeadCharaChangeEvent

    # ------------------
    # イージス
    # ------------------
    # 発動状態をONにする HP 5以上
    def check_aegis_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_AEGIS)
      end
    end
    regist_event CheckAegisPassiveEvent
    regist_event CheckAegisPassiveChangeEvent

    # 発動する
    def use_aegis_passive
      if @passives_enable[PASSIVE_AEGIS]
        if duel.tmp_damage > 0
          duel.tmp_damage -= 2
          duel.tmp_damage = 0 if duel.tmp_damage < 0
        end
      end
    end
    regist_event UseAegisPassiveEvent

    # 発動終了する
    def finish_aegis_passive
      if @passives_enable[PASSIVE_AEGIS]
        off_passive_event(true, PASSIVE_AEGIS)
        @passives_enable[PASSIVE_AEGIS] = false
      end
    end
    regist_event FinishAegisPassiveEvent
    regist_event FinishAegisPassiveDeadCharaChangeEvent

    # ------------------
    # 溟海符
    # ------------------
    # 発動状態をONにする 3の倍数ターン
    def check_ocean_passive
      if @cc.using && duel.turn % PassiveSkill.pow(@passives[PASSIVE_OCEAN]) == 0
        force_on_passive(PASSIVE_OCEAN)
      elsif @passives_enable[PASSIVE_OCEAN]
        force_off_passive(PASSIVE_OCEAN)
      end
    end
    regist_event CheckOceanPassiveEvent
    regist_event CheckOceanPassiveChangeEvent
    regist_event CheckOceanPassiveDeadChangeEvent
    regist_event CheckOceanPassiveDamageEvent

    # 発動終了する
    def finish_ocean_passive
      if @passives_enable[PASSIVE_OCEAN]
        owner.healed_event(1) if duel.turn % PassiveSkill.pow(@passives[PASSIVE_OCEAN]) == 0 && owner.hit_point > 0
        off_passive_event(true, PASSIVE_OCEAN)
        @passives_enable[PASSIVE_OCEAN] = false
      end
    end
    regist_event FinishOceanPassiveEvent

    # ------------------
    # 状態抵抗 スキュラ
    # ------------------
    # 状態抵抗をONにする
    def check_resist_skylla_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_RESIST_SKYLLA)
        @cc.status[STATE_BERSERK][2] = 50
        @cc.status[STATE_PARALYSIS][2] = 80
        @cc.status[STATE_SEAL][2] = 90
      end
    end
    regist_event CheckResistSkyllaPassiveEvent

    # ------------------
    # 立ち込める夜霧
    # ------------------
    # 発動状態をONにする HP 2/5 ~ 0まで
    def check_night_fog_passive
      if @cc.using && owner.current_hit_point_max/2 >= owner.hit_point
        force_on_passive(PASSIVE_NIGHT_FOG)
        owner.magnification_hurt_const_damage = 2
      end
    end
    regist_event CheckNightFogPassiveEvent

    # 倍化効果終了
    def use_night_fog_passive
      if @passives_enable[PASSIVE_NIGHT_FOG]
        owner.magnification_hurt_const_damage = 1
      end
    end
    regist_event UseNightFogPassiveEvent

    # 発動する
    def use_night_fog_passive_damage
      if @passives_enable[PASSIVE_NIGHT_FOG]
        if @cc&&@cc.index == owner.current_chara_card_no && !owner.initiative
          if duel.tmp_damage > PassiveSkill.pow(@passives[PASSIVE_NIGHT_FOG])
            duel.tmp_damage = PassiveSkill.pow(@passives[PASSIVE_NIGHT_FOG])
          end
        end
      end
    end
    regist_event UseNightFogPassiveDamageEvent

    # 発動終了する
    def finish_night_fog_passive
      if @passives_enable[PASSIVE_NIGHT_FOG]
        off_passive_event(true, PASSIVE_NIGHT_FOG)
        @passives_enable[PASSIVE_NIGHT_FOG] = false
      end
    end
    regist_event FinishNightFogPassiveEvent
    regist_event FinishNightFogPassiveDeadCharaChangeEvent

    # ------------------
    # 2つの身体(パッシブ)
    # ------------------
    # 発動状態をONにする HP 5以上
    def check_double_boddy_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_DOUBLE_BODDY)
      end
    end
    regist_event CheckDoubleBoddyPassiveEvent
    regist_event CheckDoubleBoddyPassiveChangeEvent

    # 発動する
    def use_double_boddy_passive
      if @passives_enable[PASSIVE_DOUBLE_BODDY] && !owner.initiative
        if duel.tmp_damage > 0

          attribute_party_damage(foe, get_hps(foe), ((duel.tmp_damage)/2).to_i, ATTRIBUTE_REFLECTION, TARGET_TYPE_RANDOM)

        end
      end
    end
    regist_event UseDoubleBoddyPassiveEvent

    # 発動終了する
    def finish_double_boddy_passive
      if @passives_enable[PASSIVE_DOUBLE_BODDY]
        off_passive_event(true, PASSIVE_DOUBLE_BODDY)
        @passives_enable[PASSIVE_DOUBLE_BODDY] = false
      end
    end
    regist_event FinishDoubleBoddyPassiveEvent
    regist_event FinishDoubleBoddyPassiveDeadCharaChangeEvent

    # ------------------
    # 機知
    # ------------------
    # 機知を発動可能状態にする

    def check_wit_passive
      if @cc.using
        check_and_on_passive(PASSIVE_WIT)
      end
    end
    regist_event CheckWitPassiveEvent

    # イベカをドロー
    WIT_PASSIVE_RATES = [[0, 3, 6, 15], [1, 5, 11, 35], [9, 19, 34, 69], [19, 39, 59, 79]]
    def use_wit_passive_draw
      if @passives_enable[PASSIVE_WIT]
        if owner.hit_point <= 4
          # 残りHPに応じて入手率を操作する
          rate = WIT_PASSIVE_RATES[4 - owner.hit_point]

          2.times do
            r = rand(100)
            card = 0
            case r
            when 0..rate[0]
              card = MOVE_EVENT_CARD5
            when rate[0]+1 .. rate[1]
              card = MOVE_EVENT_CARD4
            when rate[1]+1 .. rate[2]
              card = MOVE_EVENT_CARD3
            when rate[2]+1 .. rate[3]
              card = MOVE_EVENT_CARD2
            else
              card = MOVE_EVENT_CARD1
            end

            ret = duel.get_event_deck(owner).replace_event_cards(card,1,true)
            if ret > 0
              @cc.owner.special_event_card_dealed_event(duel.get_event_deck(owner).draw_cards_event(1).each{ |c| @cc.owner.dealed_event(c)})
            end

          end

        end
      end
    end
    regist_event UseWitPassiveDrawEvent

    def use_wit_passive
      if @passives_enable[PASSIVE_WIT]
        @cc.owner.tmp_power += PassiveSkill.pow(@passives[PASSIVE_WIT])
        @cc.owner.tmp_power += 1 if owner.hit_point < 3
      end
    end
    regist_event UseWitPassiveEvent

    # 機知を発動終了する
    def finish_wit_passive
      if @passives_enable[PASSIVE_WIT]
        off_passive_event(true, PASSIVE_WIT)
      end
      @passives_enable[PASSIVE_WIT] = false
    end
    regist_event FinishWitPassiveEvent

    # ------------------
    # 修羅
    # ------------------
    # 修羅が使用されたかのチェック
    def check_curse_care_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_CURSE_CARE)
        @healed = false
        @debuffed = false
      end
    end
    regist_event CheckCurseCarePassiveEvent
    regist_event CheckCurseCarePassiveChangeEvent

    def recover_curse_care_passive
      if @passives_enable[PASSIVE_CURSE_CARE] && !owner.initiative
        if !@healed && owner.hit_point < 5
          owner.healed_event(3) if owner.hit_point > 0
          @healed = true

          if owner.hit_point < 1
            debuff_curse_care_passive
            @debuffed = true
          end
        end
      end
    end
    regist_event RecoverCurseCarePassiveDetBpBfEvent
    regist_event RecoverCurseCarePassiveDetBpAfEvent
    regist_event RecoverCurseCarePassiveDamageBfEvent
    regist_event RecoverCurseCarePassiveDamageAfEvent
    regist_event RecoverCurseCarePassiveLastEvent

    # 発動する
    def use_curse_care_passive
      if @passives_enable[PASSIVE_CURSE_CARE] && !owner.initiative
        if @healed && !@debuffed
          debuff_curse_care_passive
        end
      end
    end
    regist_event UseCurseCarePassiveEvent

    # 発動終了する
    def finish_curse_care_passive
      if @passives_enable[PASSIVE_CURSE_CARE]
        off_passive_event(true, PASSIVE_CURSE_CARE)
        @passives_enable[PASSIVE_CURSE_CARE] = false
      end
    end
    regist_event FinishCurseCarePassiveEvent
    regist_event FinishCurseCarePassiveDeadCharaChangeEvent

    def debuff_curse_care_passive
      buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], PassiveSkill.pow(@passives[PASSIVE_CURSE_CARE]), 2);
      on_buff_event(false,
                    foe.current_chara_card_no,
                    STATE_ATK_DOWN,
                    foe.current_chara_card.status[STATE_ATK_DOWN][0],
                    foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
      buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], PassiveSkill.pow(@passives[PASSIVE_CURSE_CARE]), 2);
      on_buff_event(false,
                    foe.current_chara_card_no,
                    STATE_DEF_DOWN,
                    foe.current_chara_card.status[STATE_DEF_DOWN][0],
                    foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
      buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, 2)
      on_buff_event(false,
                    foe.current_chara_card_no,
                    STATE_MOVE_DOWN,
                    foe.current_chara_card.status[STATE_MOVE_DOWN][0],
                    foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
    end


    # ------------------
    # 白晄
    # ------------------
    # 白晄を発動可能状態にする
    def check_white_light_passive
      if @cc.using
        check_and_on_passive(PASSIVE_WHITE_LIGHT)
      end
    end
    regist_event CheckWhiteLightPassiveEvent

    # 白晄を発動終了する
    def finish_white_light_passive
      if @passives_enable[PASSIVE_WHITE_LIGHT]
        num = foe.current_chara_card.hp == foe.hit_point ? 1 + PassiveSkill.pow(@passives[PASSIVE_WHITE_LIGHT]) : 1
        owner.special_dealed_event(duel.deck.draw_cards_event(num).each{ |c| owner.dealed_event(c)})
        off_passive_event(true, PASSIVE_WHITE_LIGHT)
      end
      @passives_enable[PASSIVE_WHITE_LIGHT] = false
    end
    regist_event FinishWhiteLightPassiveEvent

    # ------------------
    # 甲羅割り
    # ------------------
    # 発動状態をONにする
    def check_carapace_break_passive
      if @cc.using && TURTLES_ID.include?(foe.current_chara_card.id)
        check_and_on_passive(PASSIVE_CARAPACE_BREAKE)
      end
    end
    regist_event CheckCarapaceBreakPassiveEvent
    regist_event CheckCarapaceBreakChangePassiveEvent
    regist_event CheckCarapaceBreakDeadChangePassiveEvent

    # 発動する
    def use_carapace_break_passive
      if @passives_enable[PASSIVE_CARAPACE_BREAKE] && owner.initiative
        if duel.tmp_damage > 0 && TURTLES_ID.include?(foe.current_chara_card.id)
          duel.tmp_damage = (duel.tmp_damage * get_carapace_multi_num).to_i
        end
      end
    end
    regist_event UseCarapaceBreakPassiveEvent

    # 発動終了する
    def finish_carapace_break_passive
      if @passives_enable[PASSIVE_CARAPACE_BREAKE]
        off_passive_event(true, PASSIVE_CARAPACE_BREAKE)
        @passives_enable[PASSIVE_CARAPACE_BREAKE] = false
      end
    end
    regist_event FinishCarapaceBreakPassiveEvent
    regist_event FinishCarapaceBreakPassiveDeadCharaChangeEvent

    def carapace_break?(target)
      TURTLES_ID.include?(target.current_chara_card.id) && @passives_enable[PASSIVE_CARAPACE_BREAKE]
    end

    def get_carapace_multi_num
      PassiveSkill.pow(@passives[PASSIVE_CARAPACE_BREAKE]) == 1 ? 1.5 : PassiveSkill.pow(@passives[PASSIVE_CARAPACE_BREAKE])
    end

    # ------------------
    # 身隠し
    # ------------------
    # 発動状態をONにする HP 1/3 ~ 0まで
    def check_carapace_passive
      if @cc.using && owner.current_hit_point_max/3 >= owner.hit_point
        force_on_passive(PASSIVE_CARAPACE)
      end
    end
    regist_event CheckCarapacePassiveEvent

    # 発動する
    def use_carapace_passive
      if @passives_enable[PASSIVE_CARAPACE]
        owner.tmp_power += PassiveSkill.pow(@passives[PASSIVE_CARAPACE])
      end
    end
    regist_event UseCarapacePassiveEvent

    # 発動終了する
    def finish_carapace_passive
      if @passives_enable[PASSIVE_CARAPACE]
        off_passive_event(true, PASSIVE_CARAPACE)
        @passives_enable[PASSIVE_CARAPACE] = false
      end
    end
    regist_event FinishCarapacePassiveEvent
    regist_event FinishCarapacePassiveDeadCharaChangeEvent

    def in_carapace?
      @passives_enable[PASSIVE_CARAPACE]
    end

    # ------------------
    # 状態抵抗 かめ
    # ------------------
    # 状態抵抗をONにする
    def check_resist_kamuy_passive
      if @cc.using
        force_on_passive(PASSIVE_RESIST_KAMUY)
        @cc.status[STATE_SEAL][2] = 92
      end
    end
    regist_event CheckResistKamuyPassiveEvent

    def check_chara_resist_kamuy_passive
      favor_chara = 10
      if @cc.using && foe.current_chara_card.charactor_id == favor_chara
        @cc.status[STATE_SEAL][2] = 75
      end
    end
    regist_event CheckCharaResistKamuyPassiveEvent

    def restore_resist_kamuy_passive
      favor_chara = 10
      if @cc.using && foe.current_chara_card.charactor_id == favor_chara
        @cc.status[STATE_SEAL][2] = 92
      end
    end
    regist_event RestoreResistKamuyPassiveEvent

    # ------------------
    # リバイザーズ
    # ------------------
    # 発動状態をONにする ノイクロームが居る場合
    def check_revisers_passive
      if @cc.using && contains_deck_charactor(owner, NOICHROME_ID)
        force_on_passive(PASSIVE_REVISERS)
      end
    end
    regist_event CheckRevisersPassiveEvent
    regist_event CheckRevisersPassiveChangeEvent
    regist_event CheckRevisersPassiveDeadChangeEvent

    def contains_deck_charactor(entrant, cid)
      entrant.chara_cards.each do |c|
        return true if c.charactor_id == cid
      end
      return false
    end

    # ------------------
    # レジストウォール
    # ------------------
    # 状態抵抗をONにする
    def check_resist_wall_passive
      if @cc.using
        check_resist_wall_passive_move
      end
    end
    regist_event CheckResistWallPassiveEvent
    regist_event CheckResistWallPassiveChangeEvent
    regist_event CheckResistWallPassiveDeadChangeEvent

    def check_resist_wall_passive_move
      if @cc.using && owner.distance != 1
        check_and_on_passive(PASSIVE_RESIST_WALL)
        set_all_resist
      else
        @passives_enable[PASSIVE_RESIST_WALL] = false
        off_passive_event(true, PASSIVE_RESIST_WALL)
        crear_all_resist
      end
    end
    regist_event CheckResistWallPassiveMoveEvent

    def set_all_resist
      if @cc.using && @cc.status
        @cc.status.each_with_index do |s,i|
          s[2] = 100 unless i == STATE_CONTROL
        end
      end
    end

    def crear_all_resist
      if @cc.using &&  @cc.status
        @cc.status.each_with_index do |s,i|
          s[2] = 0 unless i == STATE_CONTROL
        end
      end
    end

    # ------------------
    # 呪印符
    # ------------------
    # 発動状態をONにする 3の倍数ターン
    def check_curse_sign_passive
      if @cc.using
        force_on_passive(PASSIVE_CURSE_SIGN)
      end
    end
    regist_event CheckCurseSignPassiveEvent
    regist_event CheckCurseSignPassiveChangeEvent
    regist_event CheckCurseSignPassiveDeadChangeEvent

    # 発動終了する
    def finish_curse_sign_passive
      if @passives_enable[PASSIVE_CURSE_SIGN]
        off_passive_event(true, PASSIVE_CURSE_SIGN)
        @passives_enable[PASSIVE_CURSE_SIGN] = false
      end
    end
    regist_event FinishCurseSignPassiveEvent
    regist_event FinishCurseSignPassiveChangeEvent
    regist_event FinishCurseSignPassiveDeadChangeEvent

    # ------------------
    # 従者の忠誠
    # ------------------
    # 発動状態をONにする
    def check_loyalty_passive
      if @cc.using
        check_and_on_passive(PASSIVE_LOYALTY)
      end
    end
    regist_event CheckLoyaltyPassiveEvent
    regist_event CheckLoyaltyPassiveChangeEvent
    regist_event CheckLoyaltyPassiveDeadChangeEvent

    # 発動終了する
    def finish_loyalty_passive
      if @passives_enable[PASSIVE_LOYALTY]
        off_passive_event(true, PASSIVE_LOYALTY)
        @passives_enable[PASSIVE_LOYALTY] = false
      end
    end
    regist_event FinishLoyaltyPassiveEvent
    regist_event FinishLoyaltyPassiveChangeEvent
    regist_event FinishLoyaltyPassiveDeadChangeEvent

    # ------------------
    # 収穫
    # ------------------
    # 収穫を発動可能状態にする
    def check_harvest_passive
      if @cc.using && owner.current_hit_point_max/2 >= owner.hit_point
        check_and_on_passive(PASSIVE_HARVEST)
      end
    end
    regist_event CheckHarvestPassiveEvent

    # 追加ドローを発動終了する
    def finish_harvest_passive
      if @passives_enable[PASSIVE_HARVEST]
        dealed_cards = []
        num = PassiveSkill.pow(@passives[PASSIVE_HARVEST])
        owner.special_dealed_event(duel.deck.draw_cards_event(num).each{ |c|
                                     dealed_cards << c
                                     owner.dealed_event(c)
                                   })
        off_passive_event(true, PASSIVE_HARVEST)
        dealed_cards.each{ |c|
          if c.u_type != ActionCard::ARW && c.b_type != ActionCard::ARW
            foe.current_chara_card.steal_deal(c)
          end
        }
      end
      @passives_enable[PASSIVE_HARVEST] = false
    end
    regist_event FinishHarvestPassiveEvent

    # ------------------
    # T.D.
    # ------------------
    def check_td_passive
      if @cc.using
        check_and_on_passive(PASSIVE_TD)
      end
    end
    regist_event CheckTdPassiveEvent

    # 知覚の扉を使用
    def finish_td_passive()
      if @passives_enable[PASSIVE_TD]
        @passives_enable[PASSIVE_TD] = false
        case rand(3)
        when 0
          set_state(@cc.status[STATE_ATK_UP], 5, PassiveSkill.pow(@passives[PASSIVE_TD]));
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        when 1
          set_state(@cc.status[STATE_DEF_UP], 5, PassiveSkill.pow(@passives[PASSIVE_TD]));
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        when 2
          set_state(@cc.status[STATE_MOVE_UP], 1, PassiveSkill.pow(@passives[PASSIVE_TD]));
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        end
        off_passive_event(true, PASSIVE_TD)
      end
    end
    regist_event FinishTdPassiveEvent

    # ------------------
    # ムーンシャイン(passive)
    # ------------------
    def check_moon_shine_passive
      if @cc.using && owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_MOON_SHINE)
      end
    end
    regist_event CheckMoonShinePassiveEvent
    regist_event CheckMoonShinePassiveChangeEvent

    # ムーンシャインが使用終了
    def finish_moon_shine_passive()
      if @passives_enable[PASSIVE_MOON_SHINE] && owner.tmp_power > 0
        # 与えるダメージ
        dmg = 0
        # 特殊カード
        aca = []
        # 特殊カードのみにする
        foe.cards.shuffle.each do |c|
           aca << c if c.u_type == ActionCard::SPC || c.b_type == ActionCard::SPC
        end
        PassiveSkill.pow(@passives[PASSIVE_MOON_SHINE]).times do |a|
          if aca[a]
            dmg+=discard(foe, aca[a])
          end
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
        off_passive_event(true, PASSIVE_MOON_SHINE)
      end
      @passives_enable[PASSIVE_MOON_SHINE] = false
    end
    regist_event FinishMoonShinePassiveEvent

    # ------------------
    # 豊穣
    # ------------------
    # 豊穣を発動可能状態にする
    def check_fertility_passive
      if @cc.using
        force_on_passive(PASSIVE_FERTILITY)
      end
    end
    regist_event CheckFertilityPassiveEvent

    # 豊穣を発動終了する
    def finish_fertility_passive_pre
      if @passives_enable[PASSIVE_FERTILITY]
        @fertility_reserved_cards = owner.cards.dup
      end
    end
    regist_event FinishFertilityPassivePreEvent

    # 豊穣を発動終了する
    def finish_fertility_passive
      if @passives_enable[PASSIVE_FERTILITY]
        new_card_count = 0

        owner.cards.each do |c|
          new_card_count += 1 if c.get_types.include?(ActionCard::ARW) && !@fertility_reserved_cards.include?(c)
        end

        if new_card_count > 0
          set_state(@cc.status[STATE_ATK_UP], ((new_card_count+1)/2).to_i, 1);
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        end
        off_passive_event(true, PASSIVE_FERTILITY)
      end
      @passives_enable[PASSIVE_FERTILITY] = false
      @fertility_reserved_cards = []
    end
    regist_event FinishFertilityPassiveEvent

    # ------------------
    # 状態抵抗 クエカボチャ
    # ------------------
    # 状態抵抗をONにする
    def check_resist_pumpkin_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_RESIST_PUMPKIN)
        @cc.status[STATE_SEAL][2] = 70
      end
    end
    regist_event CheckResistPumpkinPassiveEvent

    # ------------------
    # AWCS
    # ------------------
    # 発動状態をONにする
    def check_awcs_passive
      if @cc.using
        if @awcs_stack.nil?
          @awcs = [2,3]
          @awcs_stack = 0
        end
        @awcs_stack += 1
        force_on_passive(PASSIVE_AWCS)
        if rand(11 - @awcs_stack) < 3
          @awcs = @awcs == [2,3] ? [1] : [2,3]
          @awcs_stack = 0

          if @awcs == [1]
            owner.duel_message_event(DUEL_MSGDLG_SWORD_DEF_UP)
          else
            owner.duel_message_event(DUEL_MSGDLG_ARROW_DEF_UP)
          end
        elsif duel.turn == 0
          owner.duel_message_event(DUEL_MSGDLG_ARROW_DEF_UP)
        end
      end
    end
    regist_event CheckAwcsPassiveEvent

    # 発動する
    def use_awcs_passive_damage
      if @passives_enable[PASSIVE_AWCS]
        if @cc&&@cc.index == owner.current_chara_card_no && !owner.initiative
          if !@awcs.include?(owner.distance)
            duel.tmp_damage = duel.tmp_damage * 2
          end
        end
      end
    end
    regist_event UseAwcsPassiveDamageEvent

    # ------------------
    # 状態抵抗 DW
    # ------------------
    # 状態抵抗をONにする
    def check_resist_dw_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_RESIST_DW)
        @cc.status[STATE_POISON][2] = 100
        @cc.status[STATE_POISON2][2] = 100
        @cc.status[STATE_PARALYSIS][2] = 70
        @cc.status[STATE_SEAL][2] = 90
      end
    end
    regist_event CheckResistDwPassiveEvent

    # ------------------
    # ロンズブラウイベント
    # ------------------
    # 発動状態をONにする
    def check_lonsbrough_event_passive
      if @cc.using
        if CHARA_GROUP_MEMBERS["lonsbrough"].include?(foe.current_chara_card.charactor_id)
          force_on_passive(PASSIVE_LONSBROUGH_EVENT)
        else
          force_off_passive(PASSIVE_LONSBROUGH_EVENT)
        end
      end
    end
    regist_event CheckLonsbroughEventPassiveEvent
    regist_event CheckLonsbroughEventPassiveChangeEvent
    regist_event CheckLonsbroughEventPassiveDeadChangeEvent

    # 発動する
    def use_lonsbrough_event_passive_damage
      if @passives_enable[PASSIVE_LONSBROUGH_EVENT]
        if @cc&&@cc.index == owner.current_chara_card_no && !owner.initiative
          duel.tmp_damage = (duel.tmp_damage * 1.5).ceil
        end
      end
    end
    regist_event UseLonsbroughEventPassiveDamageEvent

    # ------------------
    # 交錯する影
    # ------------------
    # 発動状態をONにする 3の倍数ターン
    def check_projection_passive
      if @cc.using && owner.hit_point > 0 && foe.hit_point > 0 && foe.hit_point > owner.hit_point
        force_on_passive(PASSIVE_PROJECTION)
        owner.healed_event(foe.hit_point - owner.hit_point)
      end
    end
    regist_event CheckProjectionPassiveChangeEvent

    # 発動終了する
    def finish_projection_passive
      if @passives_enable[PASSIVE_PROJECTION]
        force_off_passive(PASSIVE_PROJECTION)
      end
    end
    regist_event CheckProjectionPassiveDeadChangeEvent
    regist_event FinishProjectionPassiveEvent

    def damage_multiplier
    end

    # ------------------
    # ダメージ乗算(特定のIDに対して、自身が与えるダメージを強化 pow=id倍率)
    # ------------------
    # 発動状態をONにする
    def check_damage_multiplier_passive
      if @cc.using && gen_target_charactor_id(PassiveSkill.pow(@passives[PASSIVE_DAMAGE_MULTIPLIER])) == foe.current_chara_card.unlight_charactor_id
        check_and_on_passive(PASSIVE_DAMAGE_MULTIPLIER)
      end
    end
    regist_event CheckDamageMultiplierPassiveEvent
    regist_event CheckDamageMultiplierChangePassiveEvent
    regist_event CheckDamageMultiplierDeadChangePassiveEvent

    # 発動する
    def use_damage_multiplier_passive
      if @passives_enable[PASSIVE_DAMAGE_MULTIPLIER] && owner.initiative
        if duel.tmp_damage > 0 && gen_target_charactor_id(PassiveSkill.pow(@passives[PASSIVE_DAMAGE_MULTIPLIER])) == foe.current_chara_card.unlight_charactor_id
          duel.tmp_damage = (duel.tmp_damage * gen_multipler_num(PassiveSkill.pow(@passives[PASSIVE_DAMAGE_MULTIPLIER]))).to_i
        end
      end
    end
    regist_event UseDamageMultiplierPassiveEvent

    # 発動終了する
    def finish_damage_multiplier_passive
      if @passives_enable[PASSIVE_DAMAGE_MULTIPLIER]
        off_passive_event(true, PASSIVE_DAMAGE_MULTIPLIER)
        @passives_enable[PASSIVE_DAMAGE_MULTIPLIER] = false
      end
    end
    regist_event FinishDamageMultiplierPassiveEvent
    regist_event FinishDamageMultiplierPassiveDeadCharaChangeEvent

    def gen_target_charactor_id(pow)
      pow.to_s.chop.to_i
    end

    def gen_multipler_num(pow)
      str = pow.to_s
      n = str[str.size-1].to_i
      n == 1 ? 1.5 : n
    end

    def maltipl_damage?(target)
      @passives_enable[PASSIVE_DAMAGE_MULTIPLIER] && gen_target_charactor_id(PassiveSkill.pow(@passives[PASSIVE_DAMAGE_MULTIPLIER])) == target.current_chara_card.unlight_charactor_id
    end

    # ------------------
    # 2016,6イベント
    # ------------------
    # 発動状態をONにする
    def check_ev201606_passive
      if @cc.using && EVENT_LEADERS201606.include?(foe.current_chara_card.unlight_charactor_id)
        force_on_passive(PASSIVE_EV201606)
      else
        force_off_passive(PASSIVE_EV201606)
      end
    end
    regist_event CheckEv201606PassiveEvent
    regist_event CheckEv201606ChangePassiveEvent
    regist_event CheckEv201606DeadChangePassiveEvent

    # 発動する
    def use_ev201606_passive
      if @passives_enable[PASSIVE_EV201606] && !owner.initiative && foe.tmp_power > 0
        foe.tmp_power += PassiveSkill.pow(@passives[PASSIVE_EV201606])
      end
    end
    regist_event UseEv201606PassiveEvent

    # 発動終了する
    def finish_ev201606_passive
      if @passives_enable[PASSIVE_EV201606]
        off_passive_event(true, PASSIVE_EV201606)
        @passives_enable[PASSIVE_EV201606] = false
      end
    end
    regist_event FinishEv201606PassiveEvent
    regist_event FinishEv201606PassiveDeadCharaChangeEvent

    # ------------------
    # 状態抵抗 妖蛆
    # ------------------
    # 状態抵抗をONにする
    def check_status_resistance_aquamarine_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_STATE_RESISTANCE_AQUAMARINE)
        @cc.status[STATE_BIND][2] = 75
        @cc.status[STATE_PARALYSIS][2] = 80
        @cc.status[STATE_SEAL][2] = 90
      end
    end
    regist_event CheckStatusResistanceAquamarinePassiveEvent

    # ------------------
    # 爽涼符
    # ------------------
    def check_cooly_passive
      if @cc.using
        unless @passives_enable[PASSIVE_COOLY]
          init_cooly
          force_on_passive(PASSIVE_COOLY)
        end
      end
    end
    regist_event CheckCoolyPassiveEvent
    regist_event CheckCoolyChangePassiveEvent
    regist_event CheckCoolyDeadChangePassiveEvent

    # 移動or攻撃
    def use_cooly_passive_move
      if @passives_enable[PASSIVE_COOLY]
        owner.battle_table.clone.each do |c|
          if (c.u_type == ActionCard::DEF || c.b_type == ActionCard::DEF) && (1..60).include?(c.id)
            @passive_cooly_card_list << c
          end
        end
      end
    end
    regist_event UseCoolyPassiveMoveEvent

    # 移動or攻撃
    def use_cooly_passive_attack
      if @passives_enable[PASSIVE_COOLY] && owner.initiative
        owner.battle_table.clone.each do |c|
          if (c.u_type == ActionCard::DEF || c.b_type == ActionCard::DEF) && (1..60).include?(c.id)
            @passive_cooly_card_list << c
          end
        end
      end
    end
    regist_event UseCoolyPassiveAttackEvent

    # 防御
    def use_cooly_passive_defense
      if @passives_enable[PASSIVE_COOLY] && !owner.initiative
        owner.battle_table = []
        @passive_cooly_card_list.shuffle.each do |c|
          if (!duel.deck.exist?(c) && !foe.cards.include?(c) && !owner.cards.include?(c))  # 山札・手札になければ引く
            owner.grave_dealed_event([c])
            break
          end
        end
        force_off_passive(PASSIVE_COOLY)
      end
    end
    regist_event UseCoolyPassiveDefenseEvent


    def init_cooly
      @passive_cooly_card_list = []
    end

    # ------------------
    # 余焔符
    # ------------------
    def check_burning_embers_passive
      if @cc.using
        unless @passives_enable[PASSIVE_BURNING_EMBERS]
          init_burning_embers
          force_on_passive(PASSIVE_BURNING_EMBERS)
        end
      end
    end
    regist_event CheckBurningEmbersPassiveEvent
    regist_event CheckBurningEmbersChangePassiveEvent
    regist_event CheckBurningEmbersDeadChangePassiveEvent

    # 移動or防御
    def use_burning_embers_passive_move
      if @passives_enable[PASSIVE_BURNING_EMBERS]
        owner.battle_table.clone.each do |c|
          if (c.u_type == ActionCard::SWD || c.b_type == ActionCard::SWD) && (1..60).include?(c.id)
            @passive_burning_embers_card_list << c
          end
        end
      end
    end
    regist_event UseBurningEmbersPassiveMoveEvent

    # 移動or防御
    def use_burning_embers_passive_attack
      if @passives_enable[PASSIVE_BURNING_EMBERS] && !owner.initiative
        owner.battle_table.clone.each do |c|
          if (c.u_type == ActionCard::SWD || c.b_type == ActionCard::SWD) && (1..60).include?(c.id)
            @passive_burning_embers_card_list << c
          end
        end
      end
    end
    regist_event UseBurningEmbersPassiveAttackEvent

    # 攻撃
    def use_burning_embers_passive_defense
      if @passives_enable[PASSIVE_BURNING_EMBERS] && owner.initiative
        owner.battle_table = []
        @passive_burning_embers_card_list.shuffle.each do |c|
          if (!duel.deck.exist?(c) && !foe.cards.include?(c) && !owner.cards.include?(c))  # 山札・手札になければ引く
            owner.grave_dealed_event([c])
            break
          end
        end
        force_off_passive(PASSIVE_BURNING_EMBERS)
      end
    end
    regist_event UseBurningEmbersPassiveDefenseEvent
    regist_event UseBurningEmbersPassiveDefenseDetCharaChangeEvent


    def init_burning_embers
      @passive_burning_embers_card_list = []
    end

    # ------------------
    # 2016,9イベント(raid:Byakhee)
    # ------------------
    # 発動状態をONにする
    def check_ev201609_passive
      if @cc.using && EVENT_LEADERS201609.include?(foe.current_chara_card.unlight_charactor_id)
        force_on_passive(PASSIVE_EV201609)
      else
        force_off_passive(PASSIVE_EV201609)
      end
    end
    regist_event CheckEv201609PassiveEvent
    regist_event CheckEv201609ChangePassiveEvent
    regist_event CheckEv201609DeadChangePassiveEvent

    # 発動する
    def use_ev201609_passive
      if @passives_enable[PASSIVE_EV201609] && !owner.initiative && foe.tmp_power > 0
        foe.tmp_power += PassiveSkill.pow(@passives[PASSIVE_EV201609])
      end
    end
    regist_event UseEv201609PassiveEvent

    # 発動終了する
    def finish_ev201609_passive
      if @passives_enable[PASSIVE_EV201609]
        off_passive_event(true, PASSIVE_EV201609)
        @passives_enable[PASSIVE_EV201609] = false
      end
    end
    regist_event FinishEv201609PassiveEvent
    regist_event FinishEv201609PassiveDeadCharaChangeEvent

    # ------------------
    # 状態抵抗 Byakhee
    # ------------------
    # 状態抵抗をONにする
    def check_resist_byakhee_passive
      if @cc.using && duel.turn < 2
        force_on_passive(PASSIVE_RESIST_BYAKHEE)
        @cc.status[STATE_POISON][2] = 100
        @cc.status[STATE_POISON2][2] = 100
        @cc.status[STATE_BIND][2] = 70
        @cc.status[STATE_SEAL][2] = 90
      end
    end
    regist_event CheckResistByakheePassiveEvent

    # ------------------
    # 劫火(passive)
    # ------------------
    def check_disaster_flame_passive
      if @cc.using && owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_DISASTER_FLAME)
      end
    end
    regist_event CheckDisasterFlamePassiveEvent
    regist_event CheckDisasterFlamePassiveChangeEvent

    # 劫火が使用終了
    def finish_disaster_flame_passive()
      if @passives_enable[PASSIVE_DISASTER_FLAME] && owner.tmp_power > 0
        # 与えるダメージ
        dmg = 0
        # 特殊カード
        aca = []
        # カードをシャッフルする
        foe.cards.shuffle.each do |c|
           aca << c
        end
        PassiveSkill.pow(@passives[PASSIVE_DISASTER_FLAME]).times do |a|
          if aca[a]
            discard(foe, aca[a])
          end
        end
      end
      off_passive_event(true, PASSIVE_DISASTER_FLAME)
      @passives_enable[PASSIVE_DISASTER_FLAME] = false
    end
    regist_event FinishDisasterFlamePassiveEvent

    # ------------------
    # 目覚めしもの
    # ------------------
    def check_awakening_one_passive
      if @cc.using && owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_AWAKENING_ONE)
      end
    end
    regist_event CheckAwakeningOnePassiveEvent
    regist_event CheckAwakeningOnePassiveChangeEvent

    # 目覚めしものが使用終了
    def finish_awakening_one_passive()
      if @passives_enable[PASSIVE_AWAKENING_ONE]
        off_passive_event(true, PASSIVE_AWAKENING_ONE)
        @passives_enable[PASSIVE_AWAKENING_ONE] = false
      end
    end
    regist_event FinishAwakeningOnePassiveEvent

    # ------------------
    # サーボスカル
    # ------------------
    # 発動状態をONにする
    def check_servo_skull_passive
      if @cc.using && owner.initiative && owner.current_hit_point_max/2 <= owner.hit_point
        force_on_passive(PASSIVE_SERVO_SKULL)
      else
        force_off_passive(PASSIVE_SERVO_SKULL)
      end
    end
    regist_event CheckServoSkullPassiveEvent
    regist_event CheckServoSkullPassiveChangeEvent

    # 発動する
    def use_servo_skull_passive
      if @passives_enable[PASSIVE_SERVO_SKULL]
        pow = PassiveSkill.pow(@passives[PASSIVE_SERVO_SKULL])
        owner.tmp_power += pow
      end
    end
    regist_event UseServoSkullPassiveEvent

    # 発動終了する
    def finish_servo_skull_passive
      if @passives_enable[PASSIVE_SERVO_SKULL]
        off_passive_event(true, PASSIVE_SERVO_SKULL)
        @passives_enable[PASSIVE_SERVO_SKULL] = false
      end
    end
    regist_event FinishServoSkullPassiveEvent
    regist_event FinishServoSkullPassiveDeadCharaChangeEvent

    # ------------------
    # 2016,12イベント(raid)
    # ------------------
    # 発動状態をONにする
    def check_ev201612_passive
      if @cc.using && owner.initiative  && foe.current_chara_card.kind == CC_KIND_PROFOUND_BOSS
        force_on_passive(PASSIVE_EV201612)
      else
        force_off_passive(PASSIVE_EV201612)
      end
    end
    regist_event CheckEv201612PassiveEvent
    regist_event CheckEv201612ChangePassiveEvent

    # 発動する
    def use_ev201612_passive
      if @passives_enable[PASSIVE_EV201612]
        pow = PassiveSkill.pow(@passives[PASSIVE_EV201612])
        owner.tmp_power += pow
      end
    end
    regist_event UseEv201612PassiveEvent

    # 発動終了する
    def finish_ev201612_passive
      if @passives_enable[PASSIVE_EV201612]
        off_passive_event(true, PASSIVE_EV201612)
        @passives_enable[PASSIVE_EV201612] = false
      end
    end
    regist_event FinishEv201612PassiveEvent
    regist_event FinishEv201612PassiveDeadCharaChangeEvent

    # ------------------
    # ハイプロテクション
    # ------------------
    # 発動状態をONにする
    def check_high_protection_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_HIGH_PROTECTION)
      end
    end
    regist_event CheckHighProtectionPassiveEvent
    regist_event CheckHighProtectionPassiveChangeEvent

    # 発動終了する
    def use_high_protection_passive
      if @passives_enable[PASSIVE_HIGH_PROTECTION]
        @high_protection_def_card_point = @cc.owner.table_point_check(ActionCard::DEF)
        owner.tmp_power += @high_protection_def_card_point * PassiveSkill.pow(@passives[PASSIVE_HIGH_PROTECTION])
      end
    end
    regist_event UseHighProtectionPassiveEvent

    # 発動終了する
    def finish_high_protection_passive
      if @passives_enable[PASSIVE_HIGH_PROTECTION] && @high_protection_def_card_point > 0
        set_state(@cc.status[STATE_DEF_DOWN], @high_protection_def_card_point*2, 2)
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_DOWN, @cc.status[STATE_DEF_DOWN][0], @cc.status[STATE_DEF_DOWN][1])
      end
      off_passive_event(true, PASSIVE_HIGH_PROTECTION)
      @passives_enable[PASSIVE_HIGH_PROTECTION] = false
    end
    regist_event FinishHighProtectionPassiveEvent
    regist_event FinishHighProtectionPassiveDeadCharaChangeEvent


    # ------------------
    # パペットマスター
    # ------------------
    # 発動状態をONにする
    def check_puppet_master_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_PUPPET_MASTER)
      end
    end
    regist_event CheckPuppetMasterPassiveEvent
    regist_event CheckPuppetMasterPassiveChangeEvent

    # 発動終了する
    def use_puppet_master_passive
      if @passives_enable[PASSIVE_PUPPET_MASTER]
        return if foe.current_chara_card.status[STATE_BIND][1] == 0

        # 相手の手札を奪う
        PassiveSkill.pow(@passives[PASSIVE_PUPPET_MASTER]).times do
          break if foe.cards.size == 0
          steal_deal(foe.cards[rand(foe.cards.size)])
        end

        # 相手の使用カードを奪う
        PassiveSkill.pow(@passives[PASSIVE_PUPPET_MASTER]).times do
          return if foe.battle_table.size == 0
          @cc.owner.grave_dealed_event([foe.battle_table.delete_at(rand(foe.battle_table.size))])
        end

      end
    end
    regist_event UsePuppetMasterPassiveEvent

    # 発動終了する
    def finish_puppet_master_passive
      if @passives_enable[PASSIVE_PUPPET_MASTER]
        off_passive_event(true, PASSIVE_PUPPET_MASTER)
        @passives_enable[PASSIVE_PUPPET_MASTER] = false
      end
    end
    regist_event FinishPuppetMasterPassiveEvent
    regist_event FinishPuppetMasterPassiveDeadCharaChangeEvent

    # 武器用パッシブ
    # ===========================================
    # ------------------
    # 精密射撃+
    # ------------------
    # 精密射撃+を発動可能状態にする
    def check_aiming_plus_passive
      if @cc.using && owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_AIMING_PLUS)
      end
    end
    regist_event CheckAimingPlusPassiveEvent
    regist_event CheckAimingPlusPassiveChangeEvent

    # 精密射撃+を発動終了する
    def use_aiming_plus_passive
      if @passives_enable[PASSIVE_AIMING_PLUS] && @feats_enable[FEAT_AIMING]
        @cc.owner.tmp_power+=PassiveSkill.pow(@passives[PASSIVE_AIMING_PLUS])
      end
    end
    regist_event UseAimingPlusPassiveEvent

    # 精密射撃+を発動終了する
    def finish_aiming_plus_passive
      if @passives_enable[PASSIVE_AIMING_PLUS]
        off_passive_event(true, PASSIVE_AIMING_PLUS)
        @passives_enable[PASSIVE_AIMING_PLUS] = false
      end
    end
    regist_event FinishAimingPlusPassiveEvent
    regist_event FinishAimingPlusPassiveDeadCharaChangeEvent

    # ------------------
    # AC条件緩和
    # ------------------
    # アクションカード条件緩和 POWに技効果NOを指定する
    def check_easing_card_condition_passive
      if @cc.using
        force_on_passive(PASSIVE_EASING_CARD_CONDITION)
        unless @easing_card_condition_passive_used
          easing_card_condition(PassiveSkill.pow(@passives[PASSIVE_EASING_CARD_CONDITION]))
          @easing_card_condition_passive_used = true
        end
      end
    end
    regist_event CheckEasingCardConditionPassiveEvent
    regist_event CheckEasingCardConditionPassiveChangeEvent
    regist_event CheckEasingCardConditionPassiveDeadChangeEvent

    # ------------------
    # 岩石割り
    # ------------------
    # 発動状態をONにする
    def check_rock_crusher_passive
      if @cc.using && ROCK_SPIRITS_ID.include?(foe.current_chara_card.id)
        check_and_on_passive(PASSIVE_ROCK_CRUSHER)
      end
    end
    regist_event CheckRockCrusherPassiveEvent
    regist_event CheckRockCrusherChangePassiveEvent
    regist_event CheckRockCrusherDeadChangePassiveEvent

    # 発動する
    def use_rock_crusher_passive
      if @passives_enable[PASSIVE_ROCK_CRUSHER] && owner.initiative
        if duel.tmp_damage > 0 && ROCK_SPIRITS_ID.include?(foe.current_chara_card.id)
          duel.tmp_damage = (duel.tmp_damage * get_rock_crusher_multi_num).to_i
        end
      end
    end
    regist_event UseRockCrusherPassiveEvent

    # 発動終了する
    def finish_rock_crusher_passive
      if @passives_enable[PASSIVE_ROCK_CRUSHER]
        off_passive_event(true, PASSIVE_ROCK_CRUSHER)
        @passives_enable[PASSIVE_ROCK_CRUSHER] = false
      end
    end
    regist_event FinishRockCrusherPassiveEvent
    regist_event FinishRockCrusherPassiveDeadCharaChangeEvent

    def rock_crusher?(target)
      ROCK_SPIRITS_ID.include?(target.current_chara_card.id) && @passives_enable[PASSIVE_ROCK_CRUSHER]
    end

    def get_rock_crusher_multi_num
      PassiveSkill.pow(@passives[PASSIVE_ROCK_CRUSHER]) == 1 ? 1.5 : PassiveSkill.pow(@passives[PASSIVE_ROCK_CRUSHER])
    end

    # ------------------
    # 荊棘符
    # ------------------
    def check_brambles_card_passive
      if @cc.using
        force_on_passive(PASSIVE_BRAMBLES_CARD)
      end
    end
    regist_event CheckBramblesCardPassiveEvent
    regist_event CheckBramblesCardPassiveChangeEvent
    regist_event CheckBramblesCardPassiveDeadChangeEvent

    def use_brambles_card_passive
      if @cc && @cc.index == owner.current_chara_card_no && @passives_enable[PASSIVE_BRAMBLES_CARD]
        dmg = owner.move_point_abs > 2 ? 2 : owner.move_point_abs
        owner.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,owner,dmg), IS_NOT_HOSTILE_DAMAGE)
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg))
      end
    end
    regist_event UseBramblesCardPassiveEvent

    # 発動終了する
    def finish_brambles_card_passive
      if @passives_enable[PASSIVE_BRAMBLES_CARD]
        off_passive_event(true, PASSIVE_BRAMBLES_CARD)
        @passives_enable[PASSIVE_BRAMBLES_CARD] = false
      end
    end
    regist_event FinishBramblesCardPassiveEvent

    # ------------------
    # オーガアーム
    # ------------------
    # 発動状態をONにする
    def check_ogre_arm_passive
      if @cc.using && owner.initiative && @cc.status[STATE_STOP][1] == 0 && owner.distance == 1
        check_and_on_passive(PASSIVE_OGRE_ARM)
      end
    end
    regist_event CheckOgreArmPassiveEvent
    regist_event CheckOgreArmChangePassiveEvent

    # 発動する
    def use_ogre_arm_passive
      if @passives_enable[PASSIVE_OGRE_ARM] && owner.initiative
        if duel.tmp_damage > 0
          duel.tmp_damage = (duel.tmp_damage * PassiveSkill.pow(@passives[PASSIVE_OGRE_ARM])).to_i
        end
      end
    end
    regist_event UseOgreArmPassiveEvent

    # 発動終了する
    def finish_ogre_arm_passive
      if @passives_enable[PASSIVE_OGRE_ARM]
        off_passive_event(true, PASSIVE_OGRE_ARM)
        @passives_enable[PASSIVE_OGRE_ARM] = false
      end
    end
    regist_event FinishOgreArmPassiveEvent
    regist_event FinishOgreArmPassiveDeadCharaChangeEvent

    # ------------------
    # 紅の意志
    # ------------------
    # 使用されたかのチェック
    def check_crimson_will_passive
      if @cc.using && !owner.initiative && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_CRIMSON_WILL)
      end
    end
    regist_event CheckCrimsonWillPassiveEvent
    regist_event CheckCrimsonWillPassiveChangeEvent

    # 使用
    def use_crimson_will_passive_damage()
      if @passives_enable[PASSIVE_CRIMSON_WILL]
        if duel.tmp_damage >= 1 && duel.tmp_damage <= PassiveSkill.pow(@passives[PASSIVE_CRIMSON_WILL])
          set_state(@cc.status[STATE_BERSERK], 1, 1)
          on_buff_event(true, owner.current_chara_card_no, STATE_BERSERK, @cc.status[STATE_BERSERK][0], @cc.status[STATE_BERSERK][1])
        end
      end
    end
    regist_event UseCrimsonWillPassiveDamageEvent

    # 紅の意志が使用終了
    def finish_crimson_will_passive()
      if @passives_enable[PASSIVE_CRIMSON_WILL]
        off_passive_event(true, PASSIVE_CRIMSON_WILL)
        @passives_enable[PASSIVE_CRIMSON_WILL] = false
      end
    end
    regist_event FinishCrimsonWillPassiveEvent
    regist_event FinishCrimsonWillPassiveDeadCharaChangeEvent

    # ------------------
    # 生命の守り人
    # ------------------
    # 生命の守り人を発動可能状態にする
    def check_guardian_of_life_passive
      if @cc.using && @cc.status[STATE_STOP][1] == 0
        check_and_on_passive(PASSIVE_GUARDIAN_OF_LIFE)
      end
    end
    regist_event CheckGuardianOfLifePassiveEvent
    regist_event CheckGuardianOfLifePassiveChangeEvent

    # 生命の守り人を発動終了する
    def use_guardian_of_life_passive_defense
      if @passives_enable[PASSIVE_GUARDIAN_OF_LIFE] && !owner.initiative
        if duel.tmp_damage > 0
          if @cc.status[STATE_STIGMATA][1] > 0
            @cc.status[STATE_STIGMATA][1] += PassiveSkill.pow(@passives[PASSIVE_GUARDIAN_OF_LIFE])
            @cc.status[STATE_STIGMATA][1] = 9 if @cc.status[STATE_STIGMATA][1] > 9
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          else
            set_state(@cc.status[STATE_STIGMATA], 1, PassiveSkill.pow(@passives[PASSIVE_GUARDIAN_OF_LIFE]));
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          end
        end
      end
    end
    regist_event UseGuardianOfLifePassiveDefenseEvent

    # 生命の守り人を発動終了する
    def use_guardian_of_life_passive_attack
      if @passives_enable[PASSIVE_GUARDIAN_OF_LIFE] && owner.initiative
        if duel.tmp_damage <= 0
          if @cc.status[STATE_STIGMATA][1] > 0
            @cc.status[STATE_STIGMATA][1] += PassiveSkill.pow(@passives[PASSIVE_GUARDIAN_OF_LIFE])
            @cc.status[STATE_STIGMATA][1] = 9 if @cc.status[STATE_STIGMATA][1] > 9
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          else
            set_state(@cc.status[STATE_STIGMATA], 1,  PassiveSkill.pow(@passives[PASSIVE_GUARDIAN_OF_LIFE]));
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          end
        end
      end
    end
    regist_event UseGuardianOfLifePassiveAttackEvent

    # 生命の守り人を発動終了する
    def finish_guardian_of_life_passive
      if @passives_enable[PASSIVE_GUARDIAN_OF_LIFE]
        off_passive_event(true, PASSIVE_GUARDIAN_OF_LIFE)
        @passives_enable[PASSIVE_GUARDIAN_OF_LIFE] = false
      end
    end
    regist_event FinishGuardianOfLifePassiveEvent
    regist_event FinishGuardianOfLifePassiveDeadCharaChangeEvent

# バウンスバック
    # ===========================================
    # ステータス関連の汎用イベント
    # ===========================================
    # パッシブが有効になったときのイベント
   def on_passive(player, id)
      [player, id]
    end
    regist_event OnPassiveEvent

    # パッシブが無効になったときのイベント
    def off_passive(player, id)
      [player, id]
    end
    regist_event OffPassiveEvent

    # ===========================================
    # ステータス関連のイベント
    # ===========================================

    # ------------------
    # 毒状態
    # ------------------

    # 毒状態かどうかのチェック
    def check_poison_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_POISON][1] > 0
      end
    end
    regist_event CheckPoisonStateEvent

    # 毒が終了される
    def finish_poison_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_POISON][1] > 0
        owner.damaged_event(1,IS_NOT_HOSTILE_DAMAGE) if owner.hit_point > 0
        @cc.status[STATE_POISON][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_POISON, @cc.status[STATE_POISON][0])
      end
    end
    regist_event FinishPoisonStateEvent

    # ------------------
    # 猛毒状態
    # ------------------
    # 猛毒状態かどうかのチェック
    def check_poison2_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_POISON2][1] > 0
      end
    end
    regist_event CheckPoison2StateEvent

    # 猛毒が終了される
    def finish_poison2_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_POISON2][1] > 0
        owner.damaged_event(2,IS_NOT_HOSTILE_DAMAGE) if owner.hit_point > 0
        @cc.status[STATE_POISON2][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_POISON2, @cc.status[STATE_POISON2][0])
      end
    end
    regist_event FinishPoison2StateEvent

    # ------------------
    # 麻痺状態
    # ------------------

    # 麻痺状態かどうかのチェック
    def check_paralysis_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_PARALYSIS][1] > 0
        owner.move_point = 0
      end
    end
    regist_event CheckParalysisStateEvent

    # 麻痺が終了される
    def finish_paralysis_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_PARALYSIS][1] > 0
        @cc.status[STATE_PARALYSIS][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_PARALYSIS, @cc.status[STATE_PARALYSIS][0])
      end
    end
    regist_event FinishParalysisStateEvent

    # ------------------
    # ATKアップ状態
    # ------------------

    # ATKアップが使用されたかのチェック
    def check_attack_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_ATK_UP][1] > 0 && owner.initiative && owner.tmp_power > 0
        owner.tmp_power += @cc.status[STATE_ATK_UP][0]
      end
    end
    regist_event CheckAttackUpStateEvent

    # ATKアップが終了される
    def finish_attack_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_ATK_UP][1] > 0
        @cc.status[STATE_ATK_UP][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0])
      end
    end
    regist_event FinishAttackUpStateEvent

    # ------------------
    # ATKアップ状態
    # ------------------
    # ATKダウンが使用されたかのチェック
    def check_attack_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_ATK_DOWN][1] > 0 && owner.initiative && owner.tmp_power > 0
        owner.tmp_power -= @cc.status[STATE_ATK_DOWN][0]
      end
    end
    regist_event CheckAttackDownStateEvent

    # ATKダウンが終了される
    def finish_attack_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_ATK_DOWN][1] > 0
        @cc.status[STATE_ATK_DOWN][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_ATK_DOWN, @cc.status[STATE_ATK_DOWN][0])
      end
    end
    regist_event FinishAttackDownStateEvent


    # ------------------
    # DEFアップ状態
    # ------------------

    # DEFアップが使用されたかのチェック
    def check_deffence_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEF_UP][1] > 0 && !owner.initiative
        owner.tmp_power += @cc.status[STATE_DEF_UP][0]
      end
    end
    regist_event CheckDeffenceUpStateEvent

    # DEFアップが終了される
    def finish_deffence_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEF_UP][1] > 0
        @cc.status[STATE_DEF_UP][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0])
      end
    end
    regist_event FinishDeffenceUpStateEvent

    # ------------------
    # DEFアップ状態
    # ------------------

    # DEFダウンが使用されたかのチェック
    def check_deffence_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEF_DOWN][1] > 0 && !owner.initiative
        owner.tmp_power -= @cc.status[STATE_DEF_DOWN][0]
      end
    end
    regist_event CheckDeffenceDownStateEvent

    # DEFダウンが終了される
    def finish_deffence_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEF_DOWN][1] > 0
        @cc.status[STATE_DEF_DOWN][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_DEF_DOWN, @cc.status[STATE_DEF_DOWN][0])
      end
    end
    regist_event FinishDeffenceDownStateEvent


    # ------------------
    # MOVEアップ状態
    # ------------------

    # MOVEアップが使用されたかのチェック
    def check_move_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_MOVE_UP][1] > 0
        owner.tmp_power += @cc.status[STATE_MOVE_UP][0]
      end
    end
    regist_event CheckMoveUpStateEvent

    # DEFアップが終了される
    def finish_move_up_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_MOVE_UP][1] > 0
        @cc.status[STATE_MOVE_UP][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0])
      end
    end
    regist_event FinishMoveUpStateEvent

    # ------------------
    # MOVEダウン状態
    # ------------------

    # MOVEダウンが使用されたかのチェック
    def check_move_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_MOVE_DOWN][1] > 0
        if owner.tmp_power > 0
          owner.tmp_power -= @cc.status[STATE_MOVE_DOWN][0]
          owner.tmp_power = 0 if owner.tmp_power < 0
       elsif owner.tmp_power < 0
          owner.tmp_power += @cc.status[STATE_MOVE_DOWN][0]
          owner.tmp_power = 0 if owner.tmp_power > 0
        end
      end
    end
    regist_event CheckMoveDownStateEvent

    # MOVEダウンが終了される
    def finish_move_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_MOVE_DOWN][1] > 0
        @cc.status[STATE_MOVE_DOWN][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_MOVE_DOWN, @cc.status[STATE_MOVE_DOWN][0])
      end
    end
    regist_event FinishMoveDownStateEvent

    # ------------------
    # バーサーク状態
    # ------------------

    # バーサークが使用されたかのチェック
    def check_berserk_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_BERSERK][1] > 0
        duel.tmp_damage = duel.tmp_damage * 2
      end
    end
    regist_event CheckBerserkStateEvent

    # バーサークが終了される
    def finish_berserk_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_BERSERK][1] > 0
        @cc.status[STATE_BERSERK][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_BERSERK, @cc.status[STATE_BERSERK][0])
      end
    end
    regist_event FinishBerserkStateEvent


    # ------------------
    # 停止状態
    # ------------------

    # 停止が使用されたかのチェック
    def check_attack_stop_state
      if @cc&&@cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STOP][1] > 0
        owner.attack_done # 即決定
      end
    end
    regist_event CheckAttackStopStateEvent

    # 停止が使用されたかのチェック
    def check_deffence_stop_state
      if @cc&&@cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STOP][1] > 0
        owner.deffence_done # 即決定
      end
    end
    regist_event CheckDeffenceStopStateEvent

    # 停止が終了される
    def finish_stop_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STOP][1] > 0
        @cc.status[STATE_STOP][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_STOP, @cc.status[STATE_STOP][0])
      end
    end
    regist_event FinishStopStateEvent


    # ------------------
    # 封印状態
    # ------------------

    # 封印が使用されたかのチェック
    def check_seal_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_SEAL][1] > 0
      end
    end
    regist_event CheckSealStateEvent

    # 封印が終了される
    def finish_seal_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_SEAL][1] > 0
        @cc.status[STATE_SEAL][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_SEAL, @cc.status[STATE_SEAL][0])
      end
    end
    regist_event FinishSealStateEvent

    # ------------------
    # 自壊状態
    # ------------------

    # 自壊が使用されたかのチェック
    def check_dead_count_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEAD_COUNT][1] > 0
      end
    end
    regist_event CheckDeadCountStateEvent

    # 自壊が終了される
    def finish_dead_count_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DEAD_COUNT][1] > 0
        @cc.status[STATE_DEAD_COUNT][1] -= 1 if @cc.status_update
        @cc.owner.damaged_event(attribute_damage(ATTRIBUTE_DEATH, owner),IS_NOT_HOSTILE_DAMAGE) if @cc.status[STATE_DEAD_COUNT][1] <= 0
        update_buff_event(true, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0])
      end
    end
    regist_event FinishDeadCountStateEvent

    # ------------------
    # 操想状態
    # ------------------
    # 操想が使用されたかのチェック
    def check_control_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_CONTROL][1] > 0
      end
    end
    regist_event CheckControlStateEvent

    # 操想が終了される
    def finish_control_state
      if  @cc && @cc.status[STATE_CONTROL][1] > 0 && ! Charactor.attribute(@cc.charactor_id).include?("revisers")
        @cc.status[STATE_CONTROL][1] -= 1 if @cc.status_update
        attribute_party_damage(owner, @cc.index, 99, ATTRIBUTE_DEATH, TARGET_TYPE_SINGLE, 1, IS_NOT_HOSTILE_DAMAGE) if @cc.status[STATE_CONTROL][1] <= 0

        if @cc.index == owner.current_chara_card_no
          update_buff_event(true, STATE_CONTROL, @cc.status[STATE_CONTROL][0])
        else
          update_buff_event(true, STATE_CONTROL, @cc.status[STATE_CONTROL][0], @cc.index)
        end
      end
    end
    regist_event FinishControlStateEvent

    # ------------------
    # 不死状態
    # ------------------

    # 不死が使用されたかのチェック
    def check_undead_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_UNDEAD][1] > 0 && !owner.initiative
        duel.tmp_damage = 0
      end
    end
    regist_event CheckUndeadStateEvent

    # 不死が終了される
    def finish_undead_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_UNDEAD][1] > 0
        @cc.status[STATE_UNDEAD][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_UNDEAD, @cc.status[STATE_UNDEAD][0])
      end
    end
    regist_event FinishUndeadStateEvent

    # ------------------
    # 不死状態
    # ------------------

    # 不死が使用されたかのチェック
    def check_undead2_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_UNDEAD2][1] > 0 && !owner.initiative
        duel.tmp_damage = 0
      end
    end
    regist_event CheckUndead2StateEvent

    # 不死が終了される
    def finish_undead2_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_UNDEAD2][1] > 0
        @cc.status[STATE_UNDEAD2][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_UNDEAD2, @cc.status[STATE_UNDEAD2][0])
      end
    end
    regist_event FinishUndead2StateEvent

    # ------------------
    # 石化状態
    # ------------------

    # 石化が使用されたかのチェック
    def check_stone_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STONE][1] > 0
        if foe.current_chara_card.event.passives_enable[PASSIVE_AWAKENING_ONE] && !owner.initiative ||
          owner.current_chara_card.event.passives_enable[PASSIVE_AWAKENING_ONE] && owner.initiative

          return
        end
        duel.tmp_damage = (duel.tmp_damage * 0.5).to_i
      end
    end
    regist_event CheckStoneStateEvent

    # 石化が終了される
    def finish_stone_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STONE][1] > 0
        @cc.status[STATE_STONE][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_STONE, @cc.status[STATE_STONE][0])
      end
    end
    regist_event FinishStoneStateEvent

    # ------------------
    # リジェネ状態
    # ------------------

    # リジェネ状態かどうかのチェック
    def check_regene_state
    end
    regist_event CheckRegeneStateEvent

    # リジェネが終了される
    def finish_regene_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_REGENE][1] > 0
        owner.healed_event(1)
        @cc.status[STATE_REGENE][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_REGENE, @cc.status[STATE_REGENE][0])
      end
    end
    regist_event FinishRegeneStateEvent

    # ------------------
    # 呪縛状態
    # ------------------

    # 呪縛状態かどうかのチェック
    def check_bind_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_BIND][1] > 0
        dmg = owner.move_point_abs > 2 ? 2 : owner.move_point_abs
        add_dmg = @cc.status[STATE_BIND][0] > 1 ? @cc.status[STATE_BIND][0] - 1 : 0
        owner.damaged_event(dmg+add_dmg, IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event CheckBindStateEvent

    # 呪縛が終了される
    def finish_bind_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_BIND][1] > 0
        @cc.status[STATE_BIND][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_BIND, @cc.status[STATE_BIND][0])
      end
    end
    regist_event FinishBindStateEvent

    # ------------------
    # 混沌状態
    # ------------------

    # 混沌が使用されたかのチェック
    def check_chaos_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_CHAOS][1] > 0
        owner.tmp_power *= 2
      end
    end
    regist_event CheckChaosAttackStateEvent
    regist_event CheckChaosDefenceStateEvent

    # 混沌が終了される
    def finish_chaos_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_CHAOS][1] > 0
        @cc.status[STATE_CHAOS][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_CHAOS, @cc.status[STATE_CHAOS][0])
      end
    end
    regist_event FinishChaosStateEvent

    # ------------------
    # 聖痕
    # ------------------
    # 聖痕が使用されたかのチェック
    def check_stigmata_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STIGMATA][1] > 0 && owner.tmp_power > 0
        owner.tmp_power += @cc.status[STATE_STIGMATA][1]
      end
    end
    regist_event CheckStigmataAttackStateEvent
    regist_event CheckStigmataDefenceStateEvent

    # 聖痕が終了される
    def finish_stigmata_state
    end
    regist_event FinishStigmataStateEvent


    # ------------------
    # 能力低下
    # ------------------
    # 能力低下が使用されたかのチェック
    def check_state_down_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STATE_DOWN][1] > 0 && owner.tmp_power > 0
        owner.tmp_power -= @cc.status[STATE_STATE_DOWN][1]
        owner.tmp_power = 0 if owner.tmp_power < 0
      end
    end
    regist_event CheckStateDownAttackStateEvent
    regist_event CheckStateDownDefenceStateEvent

    # 能力低下が終了される
    def finish_state_down_state
    end
    regist_event FinishStateDownStateEvent


    # ------------------
    # 詛呪
    # ------------------
    # 詛呪が使用されたかのチェック
    def check_curse_attack_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_CURSE][1] > 0 && owner.initiative && duel.tmp_damage > 0
        damage_cap = 10 - @cc.status[STATE_CURSE][1]
        damage_cap = 5 if instant_kill_guard?(owner) && damage_cap < 5
        duel.tmp_damage = damage_cap if duel.tmp_damage > damage_cap
      end
    end
    regist_event CheckCurseAttackStateEvent

    # ------------------
    # 臨界
    # ------------------
    # 臨界が使用されたかのチェック
    def check_bless_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_BLESS][1] > 0 && owner.tmp_power > 0
        case @cc.status[STATE_BLESS][1]
        when 1 .. 2
          owner.tmp_power += @cc.status[STATE_BLESS][1]
        when 3
          owner.tmp_power += @cc.status[STATE_BLESS][1] + 2
        end
      end
    end
    regist_event CheckBlessAttackStateEvent
    regist_event CheckBlessDeffenceStateEvent

    # ------------------
    # 結界
    # ------------------
    # 結界が使用されたかのチェック
    def check_barrier_state
      if owner.invincible && !owner.initiative && duel.tmp_damage > 0
        duel.tmp_damage = 0
      end
    end
    regist_event CheckBarrierStateEvent

    # ------------------
    # 棍術状態
    # ------------------

    # 棍術が使用されたかのチェック
    def check_attack_stick_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STICK][0] == 1 && @cc.status[STATE_STICK][1] > 0 && owner.initiative && owner.tmp_power > 0
        owner.tmp_power *= 2
      end
    end
    regist_event CheckAttackStickStateEvent

    # 棍術が使用されたかのチェック
    def check_deffence_stick_state
      if  @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_STICK][0] == 2 && @cc.status[STATE_STICK][1] > 0 && !owner.initiative
        owner.tmp_power *= 2
      end
    end
    regist_event CheckDeffenceStickStateEvent

    # 棍術が終了される
    def finish_stick_state
    end
    regist_event FinishStickStateEvent

    # 棍術を入れ替える
    def change_stick_state
      if @cc.status[STATE_STICK][0] == 1
        @cc.status[STATE_STICK][0] = 2
      elsif @cc.status[STATE_STICK][0] == 2
        @cc.status[STATE_STICK][0] = 1
      end
    end

    # ------------------
    # 猫状態
    # ------------------
    # 攻撃力上書き
    def check_cat_state_attack
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.special_status[SPECIAL_STATE_CAT][1] > 0 && owner.initiative && owner.tmp_power > 0
        owner.tmp_power = 13
      end
    end
    regist_event CheckCatStateAttackEvent

    # 防御力上書き
    def check_cat_state_defence
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.special_status[SPECIAL_STATE_CAT][1] > 0 && !owner.initiative
        owner.tmp_power = 7
      end
    end
    regist_event CheckCatStateDefenceEvent

    # 猫状態の終了
    def finish_cat_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.special_status[SPECIAL_STATE_CAT][1] > 0
        @cc.special_status[SPECIAL_STATE_CAT][1] -= 1 if @cc.status_update
        if @cc.special_status[SPECIAL_STATE_CAT][1] == 0
          off_transform_sequence(true)
        else
          update_cat_state_event(true, owner.current_chara_card_no, true)
        end
      end
    end
    regist_event FinishCatStateEvent

    # ------------------
    # 人形状態
    # ------------------
    # 人形が終了される
    def finish_doll_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DOLL][1] > 0
        @cc.status[STATE_DOLL][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_DOLL, @cc.status[STATE_DOLL][0])
      end
    end
    regist_event FinishDollStateEvent


    # ------------------
    # 断絶
    # ------------------
    # 断絶が終了される
    def finish_dark_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.status[STATE_DARK][1] > 0
        @cc.status[STATE_DARK][1] -= 1 if @cc.status_update
        update_buff_event(true, STATE_DARK, @cc.status[STATE_DARK][0])
      end
    end
    regist_event FinishDarkStateEvent

    def is_dark?
      @cc.status[STATE_DARK][1] > 0
    end

    # ------------------
    # Anti Septic
    # ------------------
    # C.C.専用
    # キャラチェンジキャンセル時、技ラベルを点灯する
    def check_antiseptic_state_change
      if @feats_enable[FEAT_ANTISEPTIC]
        on_feat_event(FEAT_ANTISEPTIC)
      else
        @cc.special_status[SPECIAL_STATE_ANTISEPTIC][1] = 0
      end
    end
    regist_event CheckAntisepticStateChangeEvent
    regist_event CheckAntisepticStateDeadChangeEvent

    # 終了チェッカ ターン切れなら技を打ち切る
    def finish_antiseptic_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_ANTISEPTIC][1] > 0

        @cc.special_status[SPECIAL_STATE_ANTISEPTIC][1] -= 1 if @cc.status_update
        if @cc.special_status[SPECIAL_STATE_ANTISEPTIC][1] > 0
          @feats_enable[FEAT_ANTISEPTIC] = true
          on_feat_event(FEAT_ANTISEPTIC)
        end
      end
    end
    regist_event FinishAntisepticStateEvent

    # ------------------
    # 磁場状態
    # ------------------
    def finish_magnetic_field_state
      if @cc&&@cc.index == owner.current_chara_card_no && @cc.special_status[SPECIAL_STATE_MAGNETIC_FIELD][1] > 0
        @cc.special_status[SPECIAL_STATE_MAGNETIC_FIELD][1] -= 1 if @cc.status_update
      end
    end
    regist_event FinishMagneticFieldStateEvent

    def is_magnetic?
      @cc.special_status[SPECIAL_STATE_MAGNETIC_FIELD][1] > 0
    end

    # ------------------
    # シャープンエッジ状態
    # ------------------
    # シラーリー専用
    # キャラチェンジキャンセル時、技ラベルを点灯する
    def check_sharpen_edge_state_change
      if @feats_enable[FEAT_SHARPEN_EDGE]
        on_feat_event(FEAT_SHARPEN_EDGE)
      else
        @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] = 0
      end
    end
    regist_event CheckSharpenEdgeStateChangeEvent
    regist_event CheckSharpenEdgeStateDeadChangeEvent

    # シャープンエッジ使用時
    def use_sharpen_edge_state_damage
      if @cc&&@cc.index == owner.current_chara_card_no && !owner.initiative &&
          @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] > 0 &&
          @feats_enable[FEAT_SHARPEN_EDGE]

        if duel.tmp_damage > 0
          owner.duel_message_event(DUEL_MSGDLG_AVOID_DAMAGE, duel.tmp_damage)
          duel.tmp_damage = 0
          set_state(@cc.special_status[SPECIAL_STATE_SHARPEN_EDGE], 1, @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1]-1)
          finish_sharpen_edge_feat if @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] == 0
        end
      end
    end
    regist_event UseSharpenEdgeStateDamageEvent

    # 終了チェッカ ターン終わりに終了
    def finish_sharpen_edge_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] > 0
        @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] = 0
        finish_sharpen_edge_feat
      end
    end
    regist_event FinishSharpenEdgeStateEvent

    # ------------------
    # ドロー枚数制限状態
    # ------------------
    # ドロー終了後、一時的に操作した最大手札を元に戻す
    def check_dealing_restriction_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_DEALING_RESTRICTION][1] > 0
        foe.cards_max = foe.cards_max - @cc.special_status[SPECIAL_STATE_DEALING_RESTRICTION][0]
      end
    end
    regist_event CheckDealingRestrictionStateEvent

    def finish_dealing_restriction_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_DEALING_RESTRICTION][1] > 0
        foe.cards_max = foe.cards_max + @cc.special_status[SPECIAL_STATE_DEALING_RESTRICTION][0]
        @cc.special_status[SPECIAL_STATE_DEALING_RESTRICTION][1] = 0
      end
    end
    regist_event FinishDealingRestrictionStateEvent

    # ------------------
    # 行動制限状態
    # ------------------
    # MOVEフェイズの行動を制限する
    CONSTRAINT_FORWARD,CONSTRAINT_BACKWARD,CONSTRAINT_STAY,CONSTRAINT_CHARA_CHANGE=[1,2,4,8]
    # ターン開始
    def check_constraint_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_CONSTRAINT][1] > 0
        owner.constraint_event(@cc.special_status[SPECIAL_STATE_CONSTRAINT][0])
      end
    end
    regist_event CheckConstraintStateEvent

    # 終了
    def finish_constraint_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_CONSTRAINT][1] > 0
        @cc.special_status[SPECIAL_STATE_CONSTRAINT][1] = 0
        owner.constraint_event(0)
      end
    end
    regist_event FinishConstraintStateEvent

    # ディレクションが無効化されているか
    def forbidden_direction?(dir)
      return false if dir == Entrant::DIRECTION_PEND
      return false if @cc.special_status[SPECIAL_STATE_CONSTRAINT][1] == 0

      flg = @cc.special_status[SPECIAL_STATE_CONSTRAINT][0]
      const_bit = 0
      case dir
      when Entrant::DIRECTION_FORWARD
        const_bit = CONSTRAINT_FORWARD
      when Entrant::DIRECTION_BACKWARD
        const_bit = CONSTRAINT_BACKWARD
      when Entrant::DIRECTION_STAY
        const_bit = CONSTRAINT_STAY
      when Entrant::DIRECTION_CHARA_CHANGE
        const_bit = CONSTRAINT_CHARA_CHANGE
      end

      return (flg & const_bit) == const_bit
    end

    # ------------------
    # ダメージ追加状態
    # ------------------
    # クライド専用
    # キャラチェンジキャンセル時、技ラベルを点灯する
    def check_damage_insurance_change
      if @feats_enable[FEAT_MEXTLI]
        on_feat_event(FEAT_MEXTLI)
      else
        @cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE][1] = 0
      end
    end
    regist_event CheckDamageInsuranceChangeEvent
    regist_event CheckDamageInsuranceDeadChangeEvent

    # ダメージないとき
    def use_damage_insurance_damage
      if @cc&&@cc.index == owner.current_chara_card_no && owner.initiative &&
          @cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE][1] > 0 &&
          @feats_enable[FEAT_MEXTLI]

        if owner.tmp_power > 0 && duel.tmp_damage <= 0
          dmg = 0
          if owner.distance == 1
            dmg = owner.current_weapon_bonus_at(0)
            dmg += owner.current_weapon_bonus_at(4) if @cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE][0] > 1
          else
            dmg = owner.current_weapon_bonus_at(4)
            dmg += owner.current_weapon_bonus_at(0) if @cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE][0] > 1
          end

          if dmg < 1
            dmg = 0
          else
            dmg = ((dmg + 1)/2).to_i
          end

          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, dmg))
        end
        finish_mextli_feat()
      end
    end
    regist_event UseDamageInsuranceDamageEvent

    # ------------------
    # スキル上書き状態 (グレゴール専用)
    # ------------------
    # スキル上書きが終了される
    def finish_override_skill_state
      if  @cc && @cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL][1] > 0
        @cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL][1] -= 1 if @cc.status_update
        if @cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL][1] <= 0
          reset_override_feats
        end
      end
    end
    regist_event FinishOverrideSkillStateEvent


    def reset_override_feats
      # 相手
      if @override_feats && @override_feats.key?(3) && @override_feats[3][:foe_index]
        foe.chara_cards[@override_feats[3][:foe_index]].reset_override_my_feats()
      end
      # 自分自身
      if @override_feats && @override_feats.key?(3)
        owner.chara_cards[@override_feats[3][:owner_index]].reset_override_my_feats()
      end
      @override_feats = { }
    end

    # ------------------
    # ヌイグルミ
    # ------------------
    # 追加攻撃
    def check_stuffed_toys_state_damage
      if @cc.using && @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 0 && owner.initiative && owner.tmp_power > 0
        owner.duel_message_event(DUEL_MSGDLG_DOLL_ATK)
        @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1].times do |i|
          duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,1))
        end
      end
    end
    regist_event CheckStuffedToysStateDamageEvent

    # 被撃時破壊
    def finish_stuffed_toys_state_damage
      if @cc.using && !owner.initiative && @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 0 && duel.tmp_damage > 0
        foe.duel_message_event(DUEL_MSGDLG_DOLL_CRASH)
        @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] -= 1
        stuffed_toys_set_event(true, @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1])
      end
    end
    regist_event FinishStuffedToysStateDamageEvent

    # クライアント表示イベント
    def stuffed_toys_set(player, num)
      [player, num]
    end
    regist_event StuffedToysSetEvent

    # ------------------
    # 監視状態 (終了チェック)
    # ------------------
    # ヒール前のHP
    def use_monitoring_state_before_check
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_MONITORING][1] > 0
        @monitoring_feat_before_hp = owner.hit_points[owner.current_chara_card_no]
      end
    end
    regist_event UseMonitoringStateHealBeforeEvent
    regist_event UseMonitoringStatePartyHealBeforeEvent

    # ヒール後の処理
    def use_monitoring_state_after_check
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_MONITORING][1] > 0 && (@monitoring_feat_before_hp < owner.hit_points[owner.current_chara_card_no])
        heal_pt = owner.hit_points[owner.current_chara_card_no] - @monitoring_feat_before_hp
        foe.healed_event(heal_pt) if heal_pt > 0
      end
    end
    regist_event UseMonitoringStateHealAfterEvent
    regist_event UseMonitoringStatePartyHealAfterEvent

    # ターンエンド バフの消去
    def finish_monitoring_state
      if @cc && @cc.using && @cc.special_status[SPECIAL_STATE_MONITORING][1] > 0
        @cc.special_status[SPECIAL_STATE_MONITORING][1] -= 1 if @cc.status_update
        owner.monitoring = false
      end
    end
    regist_event FinishMonitoringStateEvent

    # ------------------
    # 時差ドロー (終了チェック)
    # ------------------
    # スキル上書きが終了される
    def finish_time_lag_draw_state
      if @cc && @cc.special_status[SPECIAL_STATE_TIME_LAG_DROW][1] > 0
        @cc.special_status[SPECIAL_STATE_TIME_LAG_DROW][1] -= 1 if @cc.status_update
        if owner.initiative
          owner.special_dealed_event(duel.deck.draw_cards_event(4).each{ |c| owner.dealed_event(c)})
        end
      end
    end
    regist_event FinishTimeLagDrawStateEvent

    # ------------------
    # 時差バフ (終了チェック)
    # ------------------
    # スキル上書きが終了される
    def finish_time_lag_buff_state
      if @cc && @cc.special_status[SPECIAL_STATE_TIME_LAG_BUFF][1] > 0
        @cc.special_status[SPECIAL_STATE_TIME_LAG_BUFF][1] -= 1 if @cc.status_update
        return unless @cc.using
        buffed = set_state(@cc.status[STATE_ATK_UP], @cc.special_status[SPECIAL_STATE_TIME_LAG_BUFF][0], 1)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], @cc.special_status[SPECIAL_STATE_TIME_LAG_BUFF][0], 1)
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
      end
    end
    regist_event FinishTimeLagBuffStateChangeEvent

    # ------------------
    # マシンセル状態 エイダR
    # ------------------
    def check_machine_cell_state
      if @cc && @cc.special_status[SPECIAL_STATE_MACHINE_CELL][1] > 0
        # 攻撃していない場合効果終了
        if owner.tmp_power < 1
          @cc.special_status[SPECIAL_STATE_MACHINE_CELL][1] = 0
        end
      end
    end
    regist_event CheckMachineCellStateEvent

    def use_machine_cell_state
      if @cc && @cc.special_status[SPECIAL_STATE_MACHINE_CELL][1] > 0 && owner.initiative
        if owner.distance > 1
          duel.tmp_damage += 2
        end
      end
    end
    regist_event UseMachineCellStateEvent

    # スキルが終了される
    def finish_machine_cell_state
      if @cc && @cc.special_status[SPECIAL_STATE_MACHINE_CELL][1] > 0
        @cc.special_status[SPECIAL_STATE_MACHINE_CELL][1] -= 1
      end
    end
    regist_event FinishMachineCellStateEvent

    # ------------------
    # アクスガード状態 フロレンスR
    # ------------------
    def check_ax_guard_state
      if @cc && @cc.special_status[SPECIAL_STATE_AX_GUARD][1] > 0
        # 攻撃していない場合効果終了
        if owner.tmp_power < 1
          @cc.special_status[SPECIAL_STATE_AX_GUARD][1] = 0
        end
      end
    end
    regist_event CheckAxGuardStateEvent

    def use_ax_guard_state
      if @cc && @cc.special_status[SPECIAL_STATE_AX_GUARD][1] > 0 && !owner.initiative
        duel.tmp_damage = (duel.tmp_damage/2).to_i
      end
    end
    regist_event UseAxGuardStateEvent

    # スキルが終了される
    def finish_ax_guard_state
      if @cc && @cc.special_status[SPECIAL_STATE_AX_GUARD][1] > 0
        @cc.special_status[SPECIAL_STATE_AX_GUARD][1] -= 1
      end
    end
    regist_event FinishAxGuardStateEvent


    # ===========================================
    # ステータス関連の汎用イベント
    # ===========================================
    # 状態付加が実際にされたときのイベント
    def on_buff(player, index, id, value, turn)
      check_exclusive_state(player, index, id, value, turn)
      value, turn = state_adjust(player, index, id, value, turn)
      [player, index, id, value, turn]
    end
    regist_event OnBuffEvent

    # 状態付加が解除されたときのイベント
    def off_buff(player, index, id, value)
      [player, index, id, value]
    end
    regist_event OffBuffEvent

    # 状態付加が進行したときのイベント
    def update_buff(player, id, value, idx=-1, turn=-1)
      target = player ? owner : foe
      index = idx < 0 ? target.current_chara_card_no : idx
      [player, id, value, index, turn]
    end
    regist_event UpdateBuffEvent

    # 猫状態をクライアントへ通知する 途中観戦用
    def update_cat_state(player, index, value)
      [player, index, value]
    end
    regist_event UpdateCatStateEvent

    # ステータスを補正する
    def state_adjust(player, index, id, value, turn)
      target = player ? owner : foe
      tmp_value = value
      tmp_turn = turn

      # ターン延長処理
      if target.chara_cards[index].event.passives_enable[PASSIVE_CURSE_SIGN] && turn > 0
        case id
          # スタン,聖痕,能力低下,混術,詛呪,臨界 は除外する
        when STATE_STOP, STATE_STIGMATA, STATE_STATE_DOWN, STATE_STICK, STATE_CURSE, STATE_BLESS, STATE_TARGET
        else
          tmp_turn = turn + 1
          tmp_turn = 9 if tmp_turn > 9
          if tmp_turn > turn
            target.chara_cards[index].status[id][1] = tmp_turn
          end
        end
      end

      return [tmp_value, tmp_turn]
    end

    # 共存不可能な状態異常を消す
    def check_exclusive_state(player, index, id, value, turn)
      target = player ? owner : foe
      case id
      when STATE_POISON then
        if target.chara_cards[index].status[STATE_POISON2][1] > 0
          target.chara_cards[index].status[STATE_POISON2][1] = 0
          off_buff_event(player, index, STATE_POISON2, target.chara_cards[index].status[STATE_POISON2][0])
        end
      when STATE_POISON2 then
        if target.chara_cards[index].status[STATE_POISON][1] > 0
          target.chara_cards[index].status[STATE_POISON][1] = 0
          off_buff_event(player, index, STATE_POISON, target.chara_cards[index].status[STATE_POISON][0])
        end
      end
    end

    # ===========================================
    # フィールド状態のアップデート
    # ==========================================
    # ターンエンド
    def check_field_status_finish_turn
      if @cc && @cc.using
        owner.field_status.each_with_index { |val, i|
          if val[1] > 0
            val[1] -= 1

            case i
            when Entrant::FIELD_STATUS["FOG"]
              foe.move_action(0)
              owner.move_action(0)
              owner.set_field_status_event(i, val[0], val[1])
            when Entrant::FIELD_STATUS["AC_LOCK"]
              owner.set_field_status(i, val[0], val[1])
            end

          end
        }
        foe.current_chara_card.check_feat_range_free = false
        foe.bp_calc_range_free = false
        owner.clear_card_locks_event
        foe.clear_card_locks_event
      end
    end
    regist_event CheckFieldStatusFinishTurnEvent

    # ===========================================
    # 必殺技の固有イベント
    # ===========================================

    # ------------------
    # 強打(バッシュ)
    # ------------------

    # 強打が使用されたかのチェック
    def check_smash_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SMASH)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SMASH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSmashFeatEvent
    regist_event CheckAddSmashFeatEvent
    regist_event CheckRotateSmashFeatEvent

    # 強打が使用される
    def use_smash_feat()
      if @feats_enable[FEAT_SMASH]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SMASH])
      end
    end
    regist_event UseSmashFeatEvent

    # 強打が使用終了される
    def finish_smash_feat()
      if @feats_enable[FEAT_SMASH]
        @feats_enable[FEAT_SMASH] = false
        use_feat_event(@feats[FEAT_SMASH])
      end
    end
    regist_event FinishSmashFeatEvent

    # ------------------
    # ブラッディハウル
    # ------------------

    # ブラッディハウルが使用されたかのチェック
    def check_bloody_howl_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLOODY_HOWL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLOODY_HOWL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBloodyHowlFeatEvent
    regist_event CheckAddBloodyHowlFeatEvent
    regist_event CheckRotateBloodyHowlFeatEvent

    # ブラッディハウルが使用される
    def use_bloody_howl_feat()
      if @feats_enable[FEAT_BLOODY_HOWL]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BLOODY_HOWL])
      end
    end
    regist_event UseBloodyHowlFeatEvent

    # ブラッディハウルが使用終了される
    def finish_bloody_howl_feat()
      if @feats_enable[FEAT_BLOODY_HOWL]
        use_feat_event(@feats[FEAT_BLOODY_HOWL])
      end
    end
    regist_event FinishBloodyHowlFeatEvent

    # ブラッディハウルＨＰ吸収
    def use_bloody_howl_feat_damage()
      if @feats_enable[FEAT_BLOODY_HOWL]
        @feats_enable[FEAT_BLOODY_HOWL] = false
        tmp_hp_before = foe.hit_point
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,(owner.tmp_power/10).to_i))
        tmp_hp_after = foe.hit_point
        owner.healed_event(tmp_hp_before - tmp_hp_after)
      end
    end
    regist_event UseBloodyHowlFeatDamageEvent

    # ------------------
    # 精密射撃
    # ------------------
    # 精密射撃が使用されたかのチェック
    def check_aiming_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_AIMING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_AIMING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAimingFeatEvent
    regist_event CheckAddAimingFeatEvent
    regist_event CheckRotateAimingFeatEvent

    # 精密射撃が使用される
    def use_aiming_feat()
      if @feats_enable[FEAT_AIMING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_AIMING])
      end
    end
    regist_event UseAimingFeatEvent

    # 精密射撃が使用終了
    def finish_aiming_feat()
      if @feats_enable[FEAT_AIMING]
        @feats_enable[FEAT_AIMING] = false
        use_feat_event(@feats[FEAT_AIMING])
      end
    end
    regist_event FinishAimingFeatEvent

    # ------------------
    # 精密射撃(復活)
    # ------------------
    # 精密射撃が使用されたかのチェック
    def check_precision_fire_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_PRECISION_FIRE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PRECISION_FIRE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePrecisionFireFeatEvent
    regist_event CheckAddPrecisionFireFeatEvent
    regist_event CheckRotatePrecisionFireFeatEvent

    # 精密射撃が使用される
    def use_precision_fire_feat()
      if @feats_enable[FEAT_PRECISION_FIRE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PRECISION_FIRE])
        @precision_fire_arrow_const = @cc.owner.get_table_max_value(ActionCard::ARW)
      end
    end
    regist_event UsePrecisionFireFeatEvent

    # 精密射撃が使用終了
    def finish_precision_fire_feat()
      if @feats_enable[FEAT_PRECISION_FIRE]
        use_feat_event(@feats[FEAT_PRECISION_FIRE])
      end
    end
    regist_event FinishPrecisionFireFeatEvent

    # 直接ダメージ部分
    def use_precision_fire_feat_damage()
      if @feats_enable[FEAT_PRECISION_FIRE]
        @feats_enable[FEAT_PRECISION_FIRE] = false
        if foe.distance == 3 && @precision_fire_arrow_const > 2
          duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@precision_fire_arrow_const-2))
        end
      end
    end
    regist_event UsePrecisionFireFeatDamageEvent

    # ------------------
    # 雷撃
    # ------------------
    # 雷撃が使用されたかのチェック
    def check_strike_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_STRIKE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_STRIKE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveStrikeFeatEvent
    regist_event CheckAddStrikeFeatEvent
    regist_event CheckRotateStrikeFeatEvent

    # 雷撃が使用される
    # 有効の場合必殺技IDを返す
    def use_strike_feat()
      if @feats_enable[FEAT_STRIKE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_STRIKE])
      end
    end
    regist_event UseStrikeFeatEvent

    # 精密射撃が使用終了
    def finish_strike_feat()
      if @feats_enable[FEAT_STRIKE]
        use_feat_event(@feats[FEAT_STRIKE])
      end
    end
    regist_event FinishStrikeFeatEvent

    # 雷撃が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_strike_feat_damage()
      if @feats_enable[FEAT_STRIKE]
        if duel.tmp_damage>0
          # 手持ちのカードを複製してシャッフル
          aca =foe.cards.shuffle
          # ダメージの分だけカードを捨てる
          duel.tmp_damage.times{ |a| discard(foe, aca[a]) if aca[a] }
        end
        @feats_enable[FEAT_STRIKE] = false
      end
    end
    regist_event UseStrikeFeatDamageEvent


    # ------------------
    # 連続技
    # ------------------
    # 連続技が使用されたかのチェック
    def check_combo_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_COMBO)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_COMBO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveComboFeatEvent
    regist_event CheckAddComboFeatEvent
    regist_event CheckRotateComboFeatEvent

    # 連続技が使用される
    # 有効の場合必殺技IDを返す
    def use_combo_feat()
      if @feats_enable[FEAT_COMBO]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_COMBO])
      end
    end
    regist_event UseComboFeatEvent

    # 連続射撃が使用終了
    def finish_combo_feat()
      if @feats_enable[FEAT_COMBO]
        @feats_enable[FEAT_COMBO] = false
        use_feat_event(@feats[FEAT_COMBO])
      end
    end
    regist_event FinishComboFeatEvent

    # ------------------
    # ソードダンス(復活)
    # ------------------
    # ソードダンスが使用されたかのチェック
    def check_sword_dance_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SWORD_DANCE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SWORD_DANCE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSwordDanceFeatEvent
    regist_event CheckAddSwordDanceFeatEvent
    regist_event CheckRotateSwordDanceFeatEvent

    # ソードダンスが使用される
    # 有効の場合必殺技IDを返す
    def use_sword_dance_feat()
      if @feats_enable[FEAT_SWORD_DANCE]
        @cc.owner.tmp_power += owner.get_type_table_count(ActionCard::SWD) * Feat.pow(@feats[FEAT_SWORD_DANCE])

        @sword_dance_card_set = owner.get_card_points_set(ActionCard::SWD)
        if @sword_dance_card_set[0] && @sword_dance_card_set[2] && @sword_dance_card_set[4] && @sword_dance_card_set[6]
          @cc.owner.tmp_power *= 3
        elsif @sword_dance_card_set[0] && @sword_dance_card_set[2] && @sword_dance_card_set[4]
          @cc.owner.tmp_power *= 2
        end

      end
    end
    regist_event UseSwordDanceFeatEvent

    # ソードダンスが使用終了
    def finish_sword_dance_feat()
      if @feats_enable[FEAT_SWORD_DANCE]
        use_feat_event(@feats[FEAT_SWORD_DANCE])
      end
    end
    regist_event FinishSwordDanceFeatEvent

    def use_sword_dance_feat_damage()
      if @feats_enable[FEAT_SWORD_DANCE]
        @feats_enable[FEAT_SWORD_DANCE] = false

        @sword_dance_card_set.each_with_index do |a, i|
          break unless a
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,i)) if i > 0
        end

      end
    end
    regist_event UseSwordDanceFeatDamageEvent

    # ------------------
    # 茨の森
    # ------------------
    # 茨の森が使用されたかのチェック
    def check_thorn_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_THORN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_THORN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThornFeatEvent
    regist_event CheckAddThornFeatEvent
    regist_event CheckRotateThornFeatEvent

    # 茨の森が使用される
    # 有効の場合必殺技IDを返す
    def use_thorn_feat()
      if @feats_enable[FEAT_THORN]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_THORN])
      end
    end
    regist_event UseThornFeatEvent


    # 茨の森が使用終了
    def finish_thorn_feat()
      if @feats_enable[FEAT_THORN]
        use_feat_event(@feats[FEAT_THORN])
      end
    end
    regist_event FinishThornFeatEvent

    # 茨の森が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_thorn_feat_damage()
      if @feats_enable[FEAT_THORN]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0 && foe.tmp_power > 0
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, duel.tmp_dice_heads_def - duel.tmp_dice_heads_atk)) if (duel.tmp_dice_heads_def - duel.tmp_dice_heads_atk) > 0
        end
        @feats_enable[FEAT_THORN] = false
      end
    end
    regist_event UseThornFeatDamageEvent

    # ------------------
    # 紫電
    # ------------------
    # 紫電が使用されたかのチェック
    def check_purple_lightning_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PURPLE_LIGHTNING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PURPLE_LIGHTNING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePurpleLightningFeatEvent
    regist_event CheckAddPurpleLightningFeatEvent
    regist_event CheckRotatePurpleLightningFeatEvent

    # 紫電が使用される
    # 有効の場合必殺技IDを返す
    def use_purple_lightning_feat()
      if @feats_enable[FEAT_PURPLE_LIGHTNING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PURPLE_LIGHTNING])
      end
    end
    regist_event UsePurpleLightningFeatEvent

    # 紫電が使用終了
    def finish_purple_lightning_feat()
      if @feats_enable[FEAT_PURPLE_LIGHTNING]
        use_feat_event(@feats[FEAT_PURPLE_LIGHTNING])
      end
    end
    regist_event FinishPurpleLightningFeatEvent

    # 紫電が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_purple_lightning_feat_damage()
      if @feats_enable[FEAT_PURPLE_LIGHTNING]
        if duel.tmp_damage > 0
          # 手持ちのカードを複製してシャッフル
          foe_cards_cnt = foe.cards.size
          aca =foe.cards.shuffle
          # ダメージの分だけカードを捨てる
          duel.tmp_damage.times{ |a| discard(foe, aca[a]) if aca[a] }
          deal_count = duel.tmp_damage
          if foe.current_chara_card.kind != CC_KIND_MONSTAR &&
              foe.current_chara_card.kind != CC_KIND_BOSS_MONSTAR &&
              foe.current_chara_card.kind != CC_KIND_PROFOUND_BOSS
            deal_count = foe_cards_cnt if duel.tmp_damage > foe_cards_cnt
          end
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(deal_count).each{ |c| @cc.owner.dealed_event(c)})
        end
        @feats_enable[FEAT_PURPLE_LIGHTNING] = false
      end
    end
    regist_event UsePurpleLightningFeatDamageEvent

    # ------------------
    # 突撃
    # ------------------

    # 突撃が使用されたかのチェック
    def check_charge_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CHARGE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CHARGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveChargeFeatEvent
    regist_event CheckAddChargeFeatEvent
    regist_event CheckRotateChargeFeatEvent

    # 突撃が使用される
    # 有効の場合必殺技IDを返す
    def use_charge_feat()
      if @feats_enable[FEAT_CHARGE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CHARGE])
      end
    end
    regist_event UseChargeFeatEvent

    # 突撃が使用終了
    def finish_charge_feat()
      if @feats_enable[FEAT_CHARGE]
        @feats_enable[FEAT_CHARGE] = false
        use_feat_event(@feats[FEAT_CHARGE])
        @cc.owner.move_action(-1)
        @cc.foe.move_action(-1)
      end
    end
    regist_event FinishChargeFeatEvent

    # ------------------
    # チャージドスラスト(復活)
    # ------------------

    # チャージドスラストが使用されたかのチェック
    def check_charged_thrust_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CHARGED_THRUST)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CHARGED_THRUST)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveChargedThrustFeatEvent
    regist_event CheckAddChargedThrustFeatEvent
    regist_event CheckRotateChargedThrustFeatEvent

    # チャージドスラストが使用される
    # 有効の場合必殺技IDを返す
    def use_charged_thrust_feat()
      if @feats_enable[FEAT_CHARGED_THRUST]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CHARGED_THRUST])
      end
    end
    regist_event UseChargedThrustFeatEvent

    # チャージドスラストが使用終了
    def finish_charged_thrust_feat()
      if @feats_enable[FEAT_CHARGED_THRUST]
        @feats_enable[FEAT_CHARGED_THRUST] = false
        use_feat_event(@feats[FEAT_CHARGED_THRUST])
        @cc.owner.move_action(-@cc.owner.get_battle_table_point(ActionCard::MOVE))
        @cc.foe.move_action(-@cc.owner.get_battle_table_point(ActionCard::MOVE))
      end
    end
    regist_event FinishChargedThrustFeatEvent

    # ------------------
    # 砂漠の蜃気楼
    # ------------------
    # 砂漠の蜃気楼が使用されたかのチェック
    def check_move_mirage_feat
      if !@mirage_checked && @cc.owner.initiative == false
        @cc.owner.reset_feat_on_cards(FEAT_MIRAGE)
        check_feat(FEAT_MIRAGE)
        @mirage_checked= true
        @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
      end
    end
    regist_event CheckMoveMirageFeatEvent

    # 突撃が使用されたかのチェック
    def check_mirage_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MIRAGE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MIRAGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMirageFeatEvent
    regist_event CheckAddMirageFeatEvent
    regist_event CheckRotateMirageFeatEvent


    # 砂漠の蜃気楼が使用される
    # 有効の場合必殺技IDを返す
    def use_mirage_feat()
      if @feats_enable[FEAT_MIRAGE] && @cc.owner.initiative == false
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MIRAGE])
      end
    end
    regist_event UseMirageFeatEvent


    # 砂漠の蜃気楼が使用終了
    def finish_mirage_feat()
      @mirage_checked = false
      if @feats_enable[FEAT_MIRAGE] && @cc.owner.initiative == false
        @feats_enable[FEAT_MIRAGE] = false
        use_feat_event(@feats[FEAT_MIRAGE])
      end
    end
    regist_event FinishMirageFeatEvent

    # ------------------
    # 狂気の眼窩
    # ------------------
    # 狂気の眼窩が使用されたかのチェック
    def check_frenzy_eyes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FRENZY_EYES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FRENZY_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFrenzyEyesFeatEvent
    regist_event CheckAddFrenzyEyesFeatEvent
    regist_event CheckRotateFrenzyEyesFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_frenzy_eyes_feat()
      if @feats_enable[FEAT_FRENZY_EYES]
         @cc.owner.tmp_power+=3
      end
    end
    regist_event UseFrenzyEyesFeatEvent


    # 狂気の眼窩が使用終了
    def finish_frenzy_eyes_feat()
      if @feats_enable[FEAT_FRENZY_EYES]
        use_feat_event(@feats[FEAT_FRENZY_EYES])
      end
    end
    regist_event FinishFrenzyEyesFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_frenzy_eyes_feat_damage()
      if @feats_enable[FEAT_FRENZY_EYES]
        aca = foe.cards.shuffle
        Feat.pow(@feats[FEAT_FRENZY_EYES]).times do |i|
          discard(foe, aca[i]) if aca[i]
        end
        @feats_enable[FEAT_FRENZY_EYES] = false
      end
    end
    regist_event UseFrenzyEyesFeatDamageEvent

    # ------------------
    # 深淵
    # ------------------

    # 深淵が使用されたかのチェック
    def check_abyss_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ABYSS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ABYSS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAbyssFeatEvent
    regist_event CheckAddAbyssFeatEvent
    regist_event CheckRotateAbyssFeatEvent

    # 狂気の眼窩が使用される
    # 深淵の威力ボーナスをリセット。他の技によって変動する。
    def use_abyss_feat()
      if @feats_enable[FEAT_ABYSS]
        @feat_abyss_bornus_damage = 0
      end
    end
    regist_event UseAbyssFeatEvent


    # 深淵が使用終了される
    def finish_abyss_feat()
      if @feats_enable[FEAT_ABYSS]
        @feats_enable[FEAT_ABYSS] = false
        use_feat_event(@feats[FEAT_ABYSS])
        @feat_abyss_bornus_damage = 0 unless @feat_abyss_bornus_damage
        d = ((@cc.owner.get_battle_table_point(ActionCard::SPC)+1)/2).to_i + @feat_abyss_bornus_damage
        if Feat.pow(@feats[FEAT_ABYSS]) > 0
          duel.first_entrant.healed_event(d)
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,d))
      end
    end
    regist_event FinishAbyssFeatEvent

    # ------------------
    # 神速の剣
    # ------------------

    #  神速の剣が使用されたかのチェック
    def check_rapid_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RAPID_SWORD)
      # 中距離で尚且つテーブルにアクションカードがおかれている
      check_feat(FEAT_RAPID_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRapidSwordFeatEvent
    regist_event CheckAddRapidSwordFeatEvent
    regist_event CheckRotateRapidSwordFeatEvent

    #  神速の剣が使用される
    # 有効の場合必殺技IDを返す
    def use_rapid_sword_feat()
      if @feats_enable[FEAT_RAPID_SWORD]
        if Feat.pow(@feats[FEAT_RAPID_SWORD]) == 2
          @cc.owner.tmp_power+=(((@cc.owner.get_battle_table_point(ActionCard::SWD)+1)/2).to_i)
        else
          @cc.owner.tmp_power+=@cc.owner.get_battle_table_point(ActionCard::SWD)
        end
      end
    end
    regist_event UseRapidSwordFeatEvent

    #  神速の剣が使用終了される
    def finish_rapid_sword_feat()
      if @feats_enable[FEAT_RAPID_SWORD]
        @feats_enable[FEAT_RAPID_SWORD] = false
        use_feat_event(@feats[FEAT_RAPID_SWORD])
      end
    end
    regist_event FinishRapidSwordFeatEvent

    # ------------------
    # 神速の剣(復活)
    # ------------------

    # 少し攻撃力ボーナスが入る仕様。L1ではとりあえずこちらを採用。
    #  神速の剣が使用されたかのチェック
    def check_rapid_sword_r2_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RAPID_SWORD_R2)
      # 中距離で尚且つテーブルにアクションカードがおかれている
      check_feat(FEAT_RAPID_SWORD_R2)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRapidSwordR2FeatEvent
    regist_event CheckAddRapidSwordR2FeatEvent
    regist_event CheckRotateRapidSwordR2FeatEvent

    #  神速の剣が使用される
    # 有効の場合必殺技IDを返す
    def use_rapid_sword_r2_feat()
      if @feats_enable[FEAT_RAPID_SWORD_R2]
        @cc.owner.tmp_power+=@cc.owner.get_battle_table_point(ActionCard::SWD) + Feat.pow(@feats[FEAT_RAPID_SWORD_R2])
      end
    end
    regist_event UseRapidSwordR2FeatEvent

    #  神速の剣が使用終了される
    def finish_rapid_sword_r2_feat()
      if @feats_enable[FEAT_RAPID_SWORD_R2]
        @feats_enable[FEAT_RAPID_SWORD_R2] = false
        use_feat_event(@feats[FEAT_RAPID_SWORD_R2])
      end
    end
    regist_event FinishRapidSwordR2FeatEvent

    # ------------------
    # 怒りの一撃
    # ------------------

    # 怒りの一撃が使用されたかのチェック
    def check_anger_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ANGER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ANGER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAngerFeatEvent
    regist_event CheckAddAngerFeatEvent
    regist_event CheckRotateAngerFeatEvent

    # 怒りの一撃が使用される
    def use_anger_feat()
      if @feats_enable[FEAT_ANGER]
        mod = (@cc.hp - @cc.owner.current_hit_point)*2
        mod_max = Feat.pow(@feats[FEAT_ANGER])
        @cc.owner.tmp_power += (mod > mod_max)? mod_max:mod
      end
    end
    regist_event UseAngerFeatEvent

    # 怒りの一撃が使用終了される
    def finish_anger_feat()
      if @feats_enable[FEAT_ANGER]
        @feats_enable[FEAT_ANGER] = false
        use_feat_event(@feats[FEAT_ANGER])
      end
    end
    regist_event FinishAngerFeatEvent


    # ------------------
    # 必殺の構え
    # ------------------

    # 必殺の構えが使用されたかのチェック
    def check_power_stock_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_POWER_STOCK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_POWER_STOCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemovePowerStockFeatEvent
    regist_event CheckAddPowerStockFeatEvent
    regist_event CheckRotatePowerStockFeatEvent

    # 必殺の構えを使用
    def finish_power_stock_feat()
      if @feats_enable[FEAT_POWER_STOCK]
        use_feat_event(@feats[FEAT_POWER_STOCK])
        @feats_enable[FEAT_POWER_STOCK] = false
        set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_POWER_STOCK]), 1);
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
      end
    end
    regist_event FinishPowerStockFeatEvent

    # ------------------
    # 必殺の構え(復活)
    # ------------------

    # 必殺の構えが使用されたかのチェック
    def check_mortal_style_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MORTAL_STYLE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MORTAL_STYLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMortalStyleFeatEvent
    regist_event CheckAddMortalStyleFeatEvent
    regist_event CheckRotateMortalStyleFeatEvent

    # 必殺の構えを使用
    def finish_mortal_style_feat()
      if @feats_enable[FEAT_MORTAL_STYLE]

        use_feat_event(@feats[FEAT_MORTAL_STYLE])
        @feats_enable[FEAT_MORTAL_STYLE] = false

        r = rand(2) + 1
        @cc.status[STATE_ATK_UP][0] = @cc.status[STATE_ATK_UP][1] > 0 ? @cc.status[STATE_ATK_UP][0]+r : Feat.pow(@feats[FEAT_MORTAL_STYLE])
        @cc.status[STATE_DEF_UP][0] = @cc.status[STATE_DEF_UP][1] > 0 ? @cc.status[STATE_DEF_UP][0]+r : Feat.pow(@feats[FEAT_MORTAL_STYLE])


        if @cc.status[STATE_ATK_UP][0] > 9 && @cc.status[STATE_ATK_DOWN][1] > 0

          rem = @cc.status[STATE_ATK_UP][0] - 9

          if rem >= @cc.status[STATE_ATK_DOWN][0]

            @cc.status[STATE_ATK_DOWN][1] = 0
            off_buff_event(true, owner.current_chara_card_no, STATE_ATK_DOWN, @cc.status[STATE_ATK_DOWN][0])

          else

            set_state(@cc.status[STATE_ATK_DOWN], @cc.status[STATE_ATK_DOWN][0] - rem, @cc.status[STATE_ATK_DOWN][1])
            on_buff_event(true, owner.current_chara_card_no, STATE_ATK_DOWN, @cc.status[STATE_ATK_DOWN][0], @cc.status[STATE_ATK_DOWN][1])

          end

        end


        if @cc.status[STATE_DEF_UP][0] > 9 && @cc.status[STATE_DEF_DOWN][1] > 0

          rem = @cc.status[STATE_DEF_UP][0] - 9

          if rem >= @cc.status[STATE_DEF_DOWN][0]

            @cc.status[STATE_DEF_DOWN][1] = 0
            off_buff_event(true, owner.current_chara_card_no, STATE_DEF_DOWN, @cc.status[STATE_DEF_DOWN][0])

          else

            buffed = set_state(@cc.status[STATE_DEF_DOWN], @cc.status[STATE_DEF_DOWN][0] - rem, @cc.status[STATE_DEF_DOWN][1])
            on_buff_event(true, owner.current_chara_card_no, STATE_DEF_DOWN, @cc.status[STATE_DEF_DOWN][0], @cc.status[STATE_DEF_DOWN][1]) if buffed

          end

        end

        set_state(@cc.status[STATE_ATK_UP], @cc.status[STATE_ATK_UP][0], 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        set_state(@cc.status[STATE_DEF_UP], @cc.status[STATE_DEF_UP][0], 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])

      end

    end
    regist_event FinishMortalStyleFeatEvent

    # ------------------
    # 影撃ち
    # ------------------
    # 影撃ちが使用されたかのチェック
    def check_shadow_shot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHADOW_SHOT)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SHADOW_SHOT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShadowShotFeatEvent
    regist_event CheckAddShadowShotFeatEvent
    regist_event CheckRotateShadowShotFeatEvent

    # 必殺技の状態
    def use_shadow_shot_feat()
      if @feats_enable[FEAT_SHADOW_SHOT]
      end
    end
    regist_event UseShadowShotFeatEvent

    # 影撃ちが使用される
    def finish_shadow_shot_feat()
      if @feats_enable[FEAT_SHADOW_SHOT]
        use_feat_event(@feats[FEAT_SHADOW_SHOT])
      end
    end
    regist_event FinishShadowShotFeatEvent

    # 影撃ちが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_shadow_shot_feat_damage()
      if @feats_enable[FEAT_SHADOW_SHOT]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, Feat.pow(@feats[FEAT_SHADOW_SHOT]));
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_SHADOW_SHOT] = false
      end
    end
    regist_event UseShadowShotFeatDamageEvent


    # ------------------
    # 赫い牙
    # ------------------

    # 赫い牙が使用されたかのチェック
    def check_red_fang_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RED_FANG)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_RED_FANG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRedFangFeatEvent
    regist_event CheckAddRedFangFeatEvent
    regist_event CheckRotateRedFangFeatEvent

    # 必殺技の状態
    def use_red_fang_feat()
      if @feats_enable[FEAT_RED_FANG]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_RED_FANG])
      end
    end
    regist_event UseRedFangFeatEvent

    # 赫い牙が使用される
    def finish_red_fang_feat()
      if @feats_enable[FEAT_RED_FANG]
        use_feat_event(@feats[FEAT_RED_FANG])
      end
    end
    regist_event FinishRedFangFeatEvent

    # 赫い牙が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_red_fang_feat_damage()
      if @feats_enable[FEAT_RED_FANG]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
        end
        @feats_enable[FEAT_RED_FANG] = false
      end
    end
    regist_event UseRedFangFeatDamageEvent


    # ------------------
    # 血の恵み
    # ------------------
    # 血の恵みが使用されたかのチェック
    def check_blessing_blood_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLESSING_BLOOD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BLESSING_BLOOD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlessingBloodFeatEvent
    regist_event CheckAddBlessingBloodFeatEvent
    regist_event CheckRotateBlessingBloodFeatEvent

    # 血の恵みが使用される
    # 有効の場合必殺技IDを返す
    def use_blessing_blood_feat()
      if @feats_enable[FEAT_BLESSING_BLOOD]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BLESSING_BLOOD])
      end
    end
    regist_event UseBlessingBloodFeatEvent

    # 血の恵みが使用終了
    def finish_blessing_blood_feat()
      if @feats_enable[FEAT_BLESSING_BLOOD]
        use_feat_event(@feats[FEAT_BLESSING_BLOOD])
      end
    end
    regist_event FinishBlessingBloodFeatEvent

    # 血の恵みが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_blessing_blood_feat_damage()
      if @feats_enable[FEAT_BLESSING_BLOOD]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0 && foe.tmp_power > 0
          # 回復処理
          @cc.owner.healed_event(duel.tmp_dice_heads_def - duel.tmp_dice_heads_atk) if (duel.tmp_dice_heads_def - duel.tmp_dice_heads_atk) > 0
        end
        @feats_enable[FEAT_BLESSING_BLOOD] = false
      end
    end
    regist_event UseBlessingBloodFeatDamageEvent


    # ------------------
    # 反撃の狼煙
    # ------------------
    # 反撃の狼煙が使用されたかのチェック
    def check_counter_preparation_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COUNTER_PREPARATION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_COUNTER_PREPARATION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCounterPreparationFeatEvent
    regist_event CheckAddCounterPreparationFeatEvent
    regist_event CheckRotateCounterPreparationFeatEvent

    # 反撃の狼煙が使用終了
    def finish_counter_preparation_feat()
      if @feats_enable[FEAT_COUNTER_PREPARATION]
        use_feat_event(@feats[FEAT_COUNTER_PREPARATION])
      end
    end
    regist_event FinishCounterPreparationFeatEvent

    # 反撃の狼煙が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_counter_preparation_feat_damage()
      if @feats_enable[FEAT_COUNTER_PREPARATION]
        if duel.tmp_damage > 0
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(duel.tmp_damage+Feat.pow(@feats[FEAT_COUNTER_PREPARATION])).each{ |c| @cc.owner.dealed_event(c)})
        end
        @feats_enable[FEAT_COUNTER_PREPARATION] = false
      end
    end
    regist_event UseCounterPreparationFeatDamageEvent


    # ------------------
    # 因果の刻
    # ------------------

    # 因果の刻が使用されたかのチェック
    def check_karmic_time_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KARMIC_TIME)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KARMIC_TIME)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKarmicTimeFeatEvent
    regist_event CheckAddKarmicTimeFeatEvent
    regist_event CheckRotateKarmicTimeFeatEvent

    # 因果の刻が使用される
    def use_karmic_time_feat()
      if @feats_enable[FEAT_KARMIC_TIME]
        @feats_enable[FEAT_KARMIC_TIME] = false
        use_feat_event(@feats[FEAT_KARMIC_TIME])
        tmp_table = foe.battle_table.clone
        foe.battle_table = []
        if Feat.pow(@feats[FEAT_KARMIC_TIME]) > 0
          tmp_table = tmp_table + owner.battle_table.clone
          owner.battle_table = []
        end
        @cc.owner.grave_dealed_event(tmp_table)
      end
    end
    regist_event UseKarmicTimeFeatEvent
    regist_event FinishCharaChangeKarmicTimeFeatEvent
    regist_event FinishFoeCharaChangeKarmicTimeFeatEvent

    # ------------------
    # 因果の輪
    # ------------------

    # 因果の輪が使用されたかのチェック
    def check_karmic_ring_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KARMIC_RING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KARMIC_RING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKarmicRingFeatEvent
    regist_event CheckAddKarmicRingFeatEvent
    regist_event CheckRotateKarmicRingFeatEvent

    # 因果の輪が使用される
    def use_karmic_ring_feat()
      if @feats_enable[FEAT_KARMIC_RING]
        use_feat_event(@feats[FEAT_KARMIC_RING])
        # 相手のカードを回転する
        if Feat.pow(@feats[FEAT_KARMIC_RING]) > 0
          foe.battle_table.each do |a|
            foe.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, (a.up?)? false : true)
          end
        else
          foe.battle_table.each do |a|
            foe.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, (rand(2) == 1)? true : false)
          end
        end
        @feats_enable[FEAT_KARMIC_RING] = false
      end
    end
    regist_event UseKarmicRingFeatEvent

    # 因果の輪が使用終了される
    def finish_karmic_ring_feat()
      if @feats_enable[FEAT_KARMIC_RING]
        @feats_enable[FEAT_KARMIC_RING] = false
      end
    end
    regist_event FinishKarmicRingFeatEvent


    # ------------------
    # 因果の糸
    # ------------------
    # 因果の糸が使用されたかのチェック
    def check_karmic_string_feat
      @cc.owner.reset_feat_on_cards(FEAT_KARMIC_STRING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_KARMIC_STRING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveKarmicStringFeatEvent
    regist_event CheckAddKarmicStringFeatEvent
    regist_event CheckRotateKarmicStringFeatEvent

    # 因果の糸が使用される
    def use_karmic_string_feat()
      if @feats_enable[FEAT_KARMIC_STRING]
        use_feat_event(@feats[FEAT_KARMIC_STRING])
        # 相手のカードを奪う
        Feat.pow(@feats[FEAT_KARMIC_STRING]).times do
          if foe.cards.size > 0
            steal_deal(foe.cards[rand(foe.cards.size)])
          end
        end
        @feats_enable[FEAT_KARMIC_STRING] = false
      end
    end
    regist_event UseKarmicStringFeatEvent

    # ------------------
    # 強打2 (未使用)
    # ------------------

    # 強打2が使用されたかのチェック
    def check_hi_smash_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_SMASH)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HI_SMASH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveHiSmashFeatEvent
    regist_event CheckAddHiSmashFeatEvent
    regist_event CheckRotateHiSmashFeatEvent

    # 強打2が使用される
    def use_hi_smash_feat()
      if @feats_enable[FEAT_HI_SMASH]
        @cc.owner.tmp_power+=5
      end
    end
    regist_event UseHiSmashFeatEvent

    # 強打2が使用終了される
    def finish_hi_smash_feat()
      if @feats_enable[FEAT_HI_SMASH]
        @feats_enable[FEAT_HI_SMASH] = false
        use_feat_event(@feats[FEAT_HI_SMASH])
      end
    end
    regist_event FinishHiSmashFeatEvent


    # ------------------
    # 必殺の構え2（未使用）
    # ------------------

    # 必殺の構え2が使用されたかのチェック
    def check_hi_power_stock_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_POWER_STOCK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HI_POWER_STOCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveHiPowerStockFeatEvent
    regist_event CheckAddHiPowerStockFeatEvent
    regist_event CheckRotateHiPowerStockFeatEvent

    # 必殺の構え2を使用
    def finish_hi_power_stock_feat()
      if @feats_enable[FEAT_HI_POWER_STOCK]
        use_feat_event(@feats[FEAT_HI_POWER_STOCK])
        @feats_enable[FEAT_HI_POWER_STOCK] = false
        set_state(@cc.status[STATE_ATK_UP], 5, 1);
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        set_state(@cc.status[STATE_DEF_UP], 2, 1);
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
      end
    end
    regist_event FinishHiPowerStockFeatEvent

    # ------------------
    # 精密射撃2（未使用）
    # ------------------
    # 精密射撃が使用されたかのチェック
    def check_hi_aiming_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_AIMING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HI_AIMING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHiAimingFeatEvent
    regist_event CheckAddHiAimingFeatEvent
    regist_event CheckRotateHiAimingFeatEvent

    # 精密射撃が使用される
    def use_hi_aiming_feat()
      if @feats_enable[FEAT_HI_AIMING]
        @cc.owner.tmp_power+=3
      end
    end
    regist_event UseHiAimingFeatEvent

    # 精密射撃が使用終了
    def finish_hi_aiming_feat()
      if @feats_enable[FEAT_HI_AIMING]
        @feats_enable[FEAT_HI_AIMING] = false
        use_feat_event(@feats[FEAT_HI_AIMING])
      end
    end
    regist_event FinishHiAimingFeatEvent

    # ------------------
    # 神速の剣2（未使用）
    # ------------------

    #  神速の剣2が使用されたかのチェック
    def check_hi_rapid_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_RAPID_SWORD)
      # 中距離で尚且つテーブルにアクションカードがおかれている
      check_feat(FEAT_HI_RAPID_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHiRapidSwordFeatEvent
    regist_event CheckAddHiRapidSwordFeatEvent
    regist_event CheckRotateHiRapidSwordFeatEvent

    #  神速の剣2が使用される
    # 有効の場合必殺技IDを返す
    def use_hi_rapid_sword_feat()
      if @feats_enable[FEAT_HI_RAPID_SWORD]
        @cc.owner.tmp_power+=(((@cc.owner.get_battle_table_point(ActionCard::SWD)+1)*0.75).to_i)
      end
    end
    regist_event UseHiRapidSwordFeatEvent

    #  神速の剣2が使用終了される
    def finish_hi_rapid_sword_feat()
      if @feats_enable[FEAT_HI_RAPID_SWORD]
        @feats_enable[FEAT_HI_RAPID_SWORD] = false
        use_feat_event(@feats[FEAT_HI_RAPID_SWORD])
      end
    end
    regist_event FinishHiRapidSwordFeatEvent


    # ------------------
    # 因果の糸2（未使用）
    # ------------------

    # 因果の糸2が使用されたかのチェック
    def check_hi_karmic_string_feat
      @cc.owner.reset_feat_on_cards(FEAT_HI_KARMIC_STRING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HI_KARMIC_STRING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveHiKarmicStringFeatEvent
    regist_event CheckAddHiKarmicStringFeatEvent
    regist_event CheckRotateHiKarmicStringFeatEvent

    # 因果の糸2が使用される
    def use_hi_karmic_string_feat()
      if @feats_enable[FEAT_HI_KARMIC_STRING]
        use_feat_event(@feats[FEAT_HI_KARMIC_STRING])
        # 相手のカードを奪う
        if foe.cards.size > 0
          steal_deal(foe.cards[rand(foe.cards.size)])
        end
        @feats_enable[FEAT_HI_KARMIC_STRING] = false
        buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], 2, 1);
        on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
      end
    end
    regist_event UseHiKarmicStringFeatEvent


    # ------------------
    # 狂気の眼窩2（未使用）
    # ------------------
    # 狂気の眼窩2が使用されたかのチェック
    def check_hi_frenzy_eyes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_FRENZY_EYES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HI_FRENZY_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHiFrenzyEyesFeatEvent
    regist_event CheckAddHiFrenzyEyesFeatEvent
    regist_event CheckRotateHiFrenzyEyesFeatEvent

    # 狂気の眼窩2が使用される
    # 有効の場合必殺技IDを返す
    def use_hi_frenzy_eyes_feat()
      if @feats_enable[FEAT_HI_FRENZY_EYES]
        @cc.owner.tmp_power+=3
      end
    end
    regist_event UseHiFrenzyEyesFeatEvent

    # 狂気の眼窩2が使用終了
    def finish_hi_frenzy_eyes_feat()
      if @feats_enable[FEAT_HI_FRENZY_EYES]
        use_feat_event(@feats[FEAT_HI_FRENZY_EYES])
      end
    end
    regist_event FinishHiFrenzyEyesFeatEvent

    # 狂気の眼窩2が使用される
    # 有効の場合必殺技IDを返す
    def use_hi_frenzy_eyes_feat_damage()
      if @feats_enable[FEAT_HI_FRENZY_EYES]
        aca = foe.cards.shuffle
        discard(foe, aca[0]) if aca[0]
        aca = foe.cards.shuffle
        discard(foe, aca[0]) if aca[0]
        @feats_enable[FEAT_HI_FRENZY_EYES] = false
      end
    end
    regist_event UseHiFrenzyEyesFeatDamageEvent


    # ------------------
    # 影撃ち2（未使用）
    # ------------------

    # 影撃ち2が使用されたかのチェック
    def check_hi_shadow_shot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_SHADOW_SHOT)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HI_SHADOW_SHOT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHiShadowShotFeatEvent
    regist_event CheckAddHiShadowShotFeatEvent
    regist_event CheckRotateHiShadowShotFeatEvent

    # 必殺技の状態
    def use_hi_shadow_shot_feat()
      if @feats_enable[FEAT_HI_SHADOW_SHOT]
        @cc.owner.tmp_power += 3
      end
    end
    regist_event UseHiShadowShotFeatEvent

    # 影撃ち2が使用される
    def finish_hi_shadow_shot_feat()
      if @feats_enable[FEAT_HI_SHADOW_SHOT]
        use_feat_event(@feats[FEAT_HI_SHADOW_SHOT])
      end
    end
    regist_event FinishHiShadowShotFeatEvent

    # 影撃ち2が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_hi_shadow_shot_feat_damage()

      if @feats_enable[FEAT_HI_SHADOW_SHOT]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_HI_SHADOW_SHOT] = false
      end
    end
    regist_event UseHiShadowShotFeatDamageEvent

    # ------------------
    # 地雷
    # ------------------

    # 地雷が使用されたかのチェック
    def check_land_mine_feat
      @cc.owner.reset_feat_on_cards(FEAT_LAND_MINE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_LAND_MINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveLandMineFeatEvent
    regist_event CheckAddLandMineFeatEvent
    regist_event CheckRotateLandMineFeatEvent

    # 因果の糸が使用される
    def use_land_mine_feat()
      if @feats_enable[FEAT_LAND_MINE]
        @feats_enable[FEAT_LAND_MINE] = false
        use_feat_event(@feats[FEAT_LAND_MINE])
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_LAND_MINE])))
      end
    end
    regist_event UseLandMineFeatEvent


    # ------------------
    # デスペラード
    # ------------------
    # デスペラードが使用されたかのチェック
    def check_desperado_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DESPERADO)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DESPERADO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDesperadoFeatEvent
    regist_event CheckAddDesperadoFeatEvent
    regist_event CheckRotateDesperadoFeatEvent

    # デスペラードが使用される
    # 有効の場合必殺技IDを返す
    def use_desperado_feat()
      if @feats_enable[FEAT_DESPERADO]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DESPERADO])
      end
    end
    regist_event UseDesperadoFeatEvent

    # デスペラードが使用終了
    def finish_desperado_feat()
      if @feats_enable[FEAT_DESPERADO]
        @feats_enable[FEAT_DESPERADO] = false
        use_feat_event(@feats[FEAT_DESPERADO])
      end
    end
    regist_event FinishDesperadoFeatEvent


    # ------------------
    # リジェクトソード
    # ------------------

    # リジェクトソードが使用されたかのチェック
    def check_reject_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_REJECT_SWORD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_REJECT_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveRejectSwordFeatEvent
    regist_event CheckAddRejectSwordFeatEvent
    regist_event CheckRotateRejectSwordFeatEvent

    # リジェクトソードが使用される
    def use_reject_sword_feat()
      if @feats_enable[FEAT_REJECT_SWORD]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_REJECT_SWORD])
      end
    end
    regist_event UseRejectSwordFeatEvent

    # リジェクトソードが使用終了される
    def finish_reject_sword_feat()
      if @feats_enable[FEAT_REJECT_SWORD]
        @feats_enable[FEAT_REJECT_SWORD] = false
        use_feat_event(@feats[FEAT_REJECT_SWORD])
      end
    end
    regist_event FinishRejectSwordFeatEvent


    # ------------------
    # カウンターガード
    # ------------------
    # カウンターガードが使用されたかのチェック
    def check_counter_guard_feat
      f_no = @feats[FEAT_COUNTER_GUARD] ? FEAT_COUNTER_GUARD : FEAT_EX_COUNTER_GUARD
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(f_no)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(f_no)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCounterGuardFeatEvent
    regist_event CheckAddCounterGuardFeatEvent
    regist_event CheckRotateCounterGuardFeatEvent

    # カウンターガード 一度だけ防御力を計算し、その数値を適用する
    def use_counter_guard_feat()
      if @feats_enable[FEAT_COUNTER_GUARD] || @feats_enable[FEAT_EX_COUNTER_GUARD]
        unless @lock
          f_id = @feats[FEAT_COUNTER_GUARD] ? @feats[FEAT_COUNTER_GUARD] : @feats[FEAT_EX_COUNTER_GUARD]
          @cc.owner.tmp_power = foe.tmp_power + (2 - @cc.owner.distance) * Feat.pow(f_id)
          @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
          @lock = true
          @locked_value = @cc.owner.tmp_power
        else
          @cc.owner.tmp_power = @locked_value
        end
      end
    end
    regist_event UseCounterGuardFeatEvent
    regist_event UseExCounterGuardFeatEvent

    # カウンターガード 一度だけ防御力を再計算し、適用する
    def use_counter_guard_feat_dice_attr()
      if @feats_enable[FEAT_COUNTER_GUARD] || @feats_enable[FEAT_EX_COUNTER_GUARD]
        f_id = @feats[FEAT_COUNTER_GUARD] ? @feats[FEAT_COUNTER_GUARD] : @feats[FEAT_EX_COUNTER_GUARD]
        @cc.owner.tmp_power = foe.tmp_power + (2 - @cc.owner.distance) * Feat.pow(f_id)
        @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
        owner.point_rewrite_event
      end
      @lock = false
    end
    regist_event UseCounterGuardFeatDiceAttrEvent
    regist_event UseExCounterGuardFeatDiceAttrEvent

    # カウンターガードが使用終了
    def finish_counter_guard_feat()
      if @feats_enable[FEAT_COUNTER_GUARD] || @feats_enable[FEAT_EX_COUNTER_GUARD]
        f_no = @feats[FEAT_COUNTER_GUARD] ? FEAT_COUNTER_GUARD : FEAT_EX_COUNTER_GUARD
        @feats_enable[f_no] = false
        use_feat_event(@feats[f_no])
      end
    end
    regist_event FinishCounterGuardFeatEvent


    # ------------------
    # ペインフリー
    # ------------------
    # ペインフリーが使用されたかのチェック
    def check_pain_flee_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PAIN_FLEE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PAIN_FLEE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemovePainFleeFeatEvent
    regist_event CheckAddPainFleeFeatEvent
    regist_event CheckRotatePainFleeFeatEvent

    # ペインフリーを使用
    def finish_pain_flee_feat()
      if @feats_enable[FEAT_PAIN_FLEE]
        use_feat_event(@feats[FEAT_PAIN_FLEE])
        @feats_enable[FEAT_PAIN_FLEE] = false
        atk_pt = Feat.pow(@feats[FEAT_PAIN_FLEE]) > 3 ? 7 : 4
        set_state(@cc.status[STATE_BERSERK], 1, Feat.pow(@feats[FEAT_PAIN_FLEE]));
        on_buff_event(true, owner.current_chara_card_no, STATE_BERSERK, @cc.status[STATE_BERSERK][0], @cc.status[STATE_BERSERK][1])
        set_state(@cc.status[STATE_ATK_UP], atk_pt, Feat.pow(@feats[FEAT_PAIN_FLEE]));
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
      end
    end
    regist_event FinishPainFleeFeatEvent

    # ------------------
    # 光の移し身
    # ------------------

    # 光の移し身が使用されたかのチェック
    def check_body_of_light_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BODY_OF_LIGHT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BODY_OF_LIGHT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBodyOfLightFeatEvent
    regist_event CheckAddBodyOfLightFeatEvent
    regist_event CheckRotateBodyOfLightFeatEvent

    # 光の移し身が使用される
    # 有効の場合必殺技IDを返す
    def use_body_of_light_feat()
      if @feats_enable[FEAT_BODY_OF_LIGHT]
      end
    end
    regist_event UseBodyOfLightFeatEvent

    # 光の移し身が使用終了
    def finish_body_of_light_feat()
      if @feats_enable[FEAT_BODY_OF_LIGHT]
        use_feat_event(@feats[FEAT_BODY_OF_LIGHT])
        duel.tmp_damage = Feat.pow(@feats[FEAT_BODY_OF_LIGHT])
        @feats_enable[FEAT_BODY_OF_LIGHT] = false
      end
    end
    regist_event FinishBodyOfLightFeatEvent


    # ------------------
    # 封印の鎖
    # ------------------

    # 封印の鎖が使用されたかのチェック
    def check_seal_chain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SEAL_CHAIN)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SEAL_CHAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSealChainFeatEvent
    regist_event CheckAddSealChainFeatEvent
    regist_event CheckRotateSealChainFeatEvent

    # 封印の鎖の状態
    def use_seal_chain_feat()
      if @feats_enable[FEAT_SEAL_CHAIN]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SEAL_CHAIN])
      end
    end
    regist_event UseSealChainFeatEvent

    # 封印の鎖が使用される
    def finish_seal_chain_feat()
      if @feats_enable[FEAT_SEAL_CHAIN]
        use_feat_event(@feats[FEAT_SEAL_CHAIN])
      end
    end
    regist_event FinishSealChainFeatEvent

    # 封印の鎖が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_seal_chain_feat_damage()
      if @feats_enable[FEAT_SEAL_CHAIN]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        end
        @feats_enable[FEAT_SEAL_CHAIN] = false
      end
    end
    regist_event UseSealChainFeatDamageEvent


    # ------------------
    # 降魔の光
    # ------------------

    # 降魔の光が使用されたかのチェック
    def check_purification_light_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PURIFICATION_LIGHT)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_PURIFICATION_LIGHT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePurificationLightFeatEvent
    regist_event CheckAddPurificationLightFeatEvent
    regist_event CheckRotatePurificationLightFeatEvent

    # 降魔の光の状態
    def use_purification_light_feat()
      if @feats_enable[FEAT_PURIFICATION_LIGHT]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_PURIFICATION_LIGHT])
      end
    end
    regist_event UsePurificationLightFeatEvent

    # 降魔の光が使用される
    def finish_purification_light_feat()
      if @feats_enable[FEAT_PURIFICATION_LIGHT]
        use_feat_event(@feats[FEAT_PURIFICATION_LIGHT])
      end
    end
    regist_event FinishPurificationLightFeatEvent

    # 降魔の光が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_purification_light_feat_damage()
      if @feats_enable[FEAT_PURIFICATION_LIGHT]
        if duel.tmp_damage>0 && !instant_kill_guard?(foe)
          buffed = set_state(foe.current_chara_card.status[STATE_STOP], 1, 1);
          on_buff_event(false, foe.current_chara_card_no, STATE_STOP, foe.current_chara_card.status[STATE_STOP][0], foe.current_chara_card.status[STATE_STOP][1]) if buffed
        end
        @feats_enable[FEAT_PURIFICATION_LIGHT] = false
      end
    end
    regist_event UsePurificationLightFeatDamageEvent

    # ------------------
    # 知略
    # ------------------
    # 知略が使用されたかのチェック
    def check_craftiness_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CRAFTINESS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CRAFTINESS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveCraftinessFeatEvent
    regist_event CheckAddCraftinessFeatEvent
    regist_event CheckRotateCraftinessFeatEvent

    # 知略を使用
    def finish_craftiness_feat()
      if @feats_enable[FEAT_CRAFTINESS]
        use_feat_event(@feats[FEAT_CRAFTINESS])
        @feats_enable[FEAT_CRAFTINESS] = false
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(Feat.pow(@feats[FEAT_CRAFTINESS])).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishCraftinessFeatEvent

    # ------------------
    # ランドボム(未使用)
    # ------------------

    # 地雷が使用されたかのチェック
    def check_land_bomb_feat
      @cc.owner.reset_feat_on_cards(FEAT_LAND_BOMB)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_LAND_BOMB)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveLandBombFeatEvent
    regist_event CheckAddLandBombFeatEvent
    regist_event CheckRotateLandBombFeatEvent

    # 地雷が使用される
    def use_land_bomb_feat()
      if @feats_enable[FEAT_LAND_BOMB]
        @feats_enable[FEAT_LAND_BOMB] = false
        use_feat_event(@feats[FEAT_LAND_BOMB])
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,3))
      end
    end
    regist_event UseLandBombFeatEvent

    # ------------------
    # リジェクトブレイド（未使用）
    # ------------------

    # リジェクトブレイドが使用されたかのチェック
    def check_reject_blade_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_REJECT_BLADE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_REJECT_BLADE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveRejectBladeFeatEvent
    regist_event CheckAddRejectBladeFeatEvent
    regist_event CheckRotateRejectBladeFeatEvent

    # リジェクトブレイドが使用される
    def use_reject_blade_feat()
      if @feats_enable[FEAT_REJECT_BLADE]
        @cc.owner.tmp_power+=5
      end
    end
    regist_event UseRejectBladeFeatEvent

    # リジェクトブレイドが使用終了される
    def finish_reject_blade_feat()
      if @feats_enable[FEAT_REJECT_BLADE]
        @feats_enable[FEAT_REJECT_BLADE] = false
        use_feat_event(@feats[FEAT_REJECT_BLADE])
      end
    end
    regist_event FinishRejectBladeFeatEvent


    # ------------------
    # 呪縛の鎖（未使用）
    # ------------------

    # 封印の鎖が使用されたかのチェック
    def check_spell_chain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SPELL_CHAIN)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SPELL_CHAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSpellChainFeatEvent
    regist_event CheckAddSpellChainFeatEvent
    regist_event CheckRotateSpellChainFeatEvent

    # 封印の鎖の状態
    def use_spell_chain_feat()
      if @feats_enable[FEAT_SPELL_CHAIN]
        @cc.owner.tmp_power += 3
      end
    end
    regist_event UseSpellChainFeatEvent

    # 封印の鎖が使用される
    def finish_spell_chain_feat()
      if @feats_enable[FEAT_SPELL_CHAIN]
        use_feat_event(@feats[FEAT_SPELL_CHAIN])
      end
    end
    regist_event FinishSpellChainFeatEvent

    # 封印の鎖が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_spell_chain_feat_damage()
      if @feats_enable[FEAT_SPELL_CHAIN]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        end
        @feats_enable[FEAT_SPELL_CHAIN] = false
      end
    end
    regist_event UseSpellChainFeatDamageEvent

    # ------------------
    # 不屈の心
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_indomitable_mind_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_INDOMITABLE_MIND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_INDOMITABLE_MIND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIndomitableMindFeatEvent
    regist_event CheckAddIndomitableMindFeatEvent
    regist_event CheckRotateIndomitableMindFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_indomitable_mind_feat()
      if @feats_enable[FEAT_INDOMITABLE_MIND] && Feat.pow(@feats[FEAT_INDOMITABLE_MIND]) > 1
        owner.is_indomitable = true
      end
    end
    regist_event UseIndomitableMindFeatEvent

    # 必殺技が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_indomitable_mind_feat_damage()
      if @feats_enable[FEAT_INDOMITABLE_MIND]
        use_feat_event(@feats[FEAT_INDOMITABLE_MIND])
        if @cc.owner.hit_point - duel.tmp_damage < 1
          duel.tmp_damage = @cc.owner.hit_point - 1
          duel.tmp_damage = 0 if duel.tmp_damage < 0
        end
        owner.battle_table = []
      end
    end
    regist_event UseIndomitableMindFeatDamageEvent

    # 必殺技が使用終了
    def finish_indomitable_mind_feat()
      if @feats_enable[FEAT_INDOMITABLE_MIND]
        if Feat.pow(@feats[FEAT_INDOMITABLE_MIND]) > 1
          owner.is_indomitable = false
        end
        @feats_enable[FEAT_INDOMITABLE_MIND] = false
        off_feat_event(FEAT_INDOMITABLE_MIND)
      end
    end
    regist_event FinishIndomitableMindFeatEvent
    regist_event FinishIndomitableMindFeatDeadCharaChangeEvent

    # ------------------
    # 精神力吸収
    # ------------------

    # 精神力吸収が使用されたかのチェック
    def check_drain_soul_feat
      @cc.owner.reset_feat_on_cards(FEAT_DRAIN_SOUL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DRAIN_SOUL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDrainSoulFeatEvent
    regist_event CheckAddDrainSoulFeatEvent
    regist_event CheckRotateDrainSoulFeatEvent

    # 精神力吸収が使用される
    def use_drain_soul_feat()
      if @feats_enable[FEAT_DRAIN_SOUL]
        use_feat_event(@feats[FEAT_DRAIN_SOUL])
        # 相手のカードを奪う
        if foe.cards.size > 0
          tmp_cards = foe.cards.dup.sort_by{rand}
          tmp_count = 0
          tmp_cards.each do |c|
            if c.u_type == ActionCard::SPC || c.b_type == ActionCard::SPC
              steal_deal(c)
              tmp_count += 1
            end
            break if tmp_count >= 3
          end
        end
        @feats_enable[FEAT_DRAIN_SOUL] = false
      end
    end
    regist_event UseDrainSoulFeatEvent


    # ------------------
    # バックスタブ
    # ------------------

    # バックスタブが使用されたかのチェック
    def check_back_stab_feat
      if foe.current_chara_card.status[STATE_PARALYSIS][1] > 0
        # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_BACK_STAB)
        # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
        check_feat(FEAT_BACK_STAB)
        # ポイントの変更をチェック
        @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
      end
     end
    regist_event CheckRemoveBackStabFeatEvent
    regist_event CheckAddBackStabFeatEvent
    regist_event CheckRotateBackStabFeatEvent

    # バックスタブが使用される
    def use_back_stab_feat()
      if @feats_enable[FEAT_BACK_STAB]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BACK_STAB]) if foe.current_chara_card.status[STATE_PARALYSIS][1] > 0
      end
    end
    regist_event UseBackStabFeatEvent

    # バックスタブが使用終了される
    def finish_back_stab_feat()
      if @feats_enable[FEAT_BACK_STAB]
        @feats_enable[FEAT_BACK_STAB] = false
        use_feat_event(@feats[FEAT_BACK_STAB])
      end
    end
    regist_event FinishBackStabFeatEvent

    # ------------------
    # 見切り
    # ------------------

    # 見切りが使用されたかのチェック
    def check_enlightened_feat
      @cc.owner.reset_feat_on_cards(FEAT_ENLIGHTENED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ENLIGHTENED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveEnlightenedFeatEvent
    regist_event CheckAddEnlightenedFeatEvent
    regist_event CheckRotateEnlightenedFeatEvent

    # 見切りが使用される
    def use_enlightened_feat()
      if @feats_enable[FEAT_ENLIGHTENED]
        use_feat_event(@feats[FEAT_ENLIGHTENED])
        buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, Feat.pow(@feats[FEAT_ENLIGHTENED]));
        on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        @feats_enable[FEAT_ENLIGHTENED] = false
      end
    end
    regist_event UseEnlightenedFeatEvent

    # ------------------
    # 暗黒の渦
    # ------------------
    # 暗黒の渦が使用されたかのチェック
    def check_dark_whirlpool_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DARK_WHIRLPOOL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DARK_WHIRLPOOL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDarkWhirlpoolFeatEvent
    regist_event CheckAddDarkWhirlpoolFeatEvent
    regist_event CheckRotateDarkWhirlpoolFeatEvent

    # 暗黒の渦が使用される
    # 有効の場合必殺技IDを返す
    def use_dark_whirlpool_feat()
      if @feats_enable[FEAT_DARK_WHIRLPOOL]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DARK_WHIRLPOOL])
      end
    end
    regist_event UseDarkWhirlpoolFeatEvent

    # 暗黒の渦が使用される
    # 有効の場合必殺技IDを返す
    def use_dark_whirlpool_feat_damage()
      if @feats_enable[FEAT_DARK_WHIRLPOOL]
        use_feat_event(@feats[FEAT_DARK_WHIRLPOOL])
        @feats_enable[FEAT_DARK_WHIRLPOOL] = false
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event UseDarkWhirlpoolFeatDamageEvent

    # ------------------
    # 因果の幻
    # ------------------

    # 因果の幻が使用されたかのチェック
    def check_karmic_phantom_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KARMIC_PHANTOM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KARMIC_PHANTOM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveKarmicPhantomFeatEvent
    regist_event CheckAddKarmicPhantomFeatEvent
    regist_event CheckRotateKarmicPhantomFeatEvent

    # 因果の幻が使用される
    def use_karmic_phantom_feat()
      if @feats_enable[FEAT_KARMIC_PHANTOM]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_KARMIC_PHANTOM])
      end
    end
    regist_event UseKarmicPhantomFeatEvent

    # 因果の幻が使用終了される
    def finish_karmic_phantom_feat()
      if @feats_enable[FEAT_KARMIC_PHANTOM]
        @feats_enable[FEAT_KARMIC_PHANTOM] = false
        use_feat_event(@feats[FEAT_KARMIC_PHANTOM])
        # １回目のダイスを振ってダメージを保存
        rec_damage = duel.tmp_damage
        rec_dice_heads_atk = duel.tmp_dice_heads_atk
        rec_dice_heads_def = duel.tmp_dice_heads_def
        # ダメージ計算をもう１度実行
        @cc.owner.dice_roll_event(duel.battle_result)
        # ダメージが大きいほう結果を適用
        if duel.tmp_damage < rec_damage
          duel.tmp_damage = rec_damage
          duel.tmp_dice_heads_atk = rec_dice_heads_atk
          duel.tmp_dice_heads_def = rec_dice_heads_def
        end
        duel.tmp_damage = rec_damage if duel.tmp_damage < rec_damage
      end
    end
    regist_event FinishKarmicPhantomFeatEvent


    # ------------------
    # 治癒の波動
    # ------------------

    # 治癒の波動が使用されたかのチェック
    def check_recovery_wave_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RECOVERY_WAVE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RECOVERY_WAVE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRecoveryWaveFeatEvent
    regist_event CheckAddRecoveryWaveFeatEvent
    regist_event CheckRotateRecoveryWaveFeatEvent

    #  治癒の波動を使用
    def finish_recovery_wave_feat()
      if @feats_enable[FEAT_RECOVERY_WAVE]
        use_feat_event(@feats[FEAT_RECOVERY_WAVE])
        @feats_enable[FEAT_RECOVERY_WAVE] = false
        @cc.owner.hit_points.each_index do |i|
          @cc.owner.party_healed_event(i, Feat.pow(@feats[FEAT_RECOVERY_WAVE])) if @cc.owner.hit_points[i] > 0
        end
      end
    end
    regist_event FinishRecoveryWaveFeatEvent

    # ------------------
    # 自爆
    # ------------------
    # 自爆が使用されたかのチェック
    def check_self_destruction_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SELF_DESTRUCTION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SELF_DESTRUCTION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSelfDestructionFeatEvent
    regist_event CheckAddSelfDestructionFeatEvent
    regist_event CheckRotateSelfDestructionFeatEvent

    # 自爆が使用終了される
    def finish_self_destruction_feat()
      if @feats_enable[FEAT_SELF_DESTRUCTION]
        @feats_enable[FEAT_SELF_DESTRUCTION] = false
        use_feat_event(@feats[FEAT_SELF_DESTRUCTION])
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@cc.owner.hit_point*Feat.pow(@feats[FEAT_SELF_DESTRUCTION])))
        duel.first_entrant.damaged_event(@cc.owner.hit_point*Feat.pow(@feats[FEAT_SELF_DESTRUCTION]),IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishSelfDestructionFeatEvent

    # ------------------
    # 防護射撃
    # ------------------
    # 防護射撃が使用されたかのチェック
    def check_deffence_shooting_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEFFENCE_SHOOTING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DEFFENCE_SHOOTING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeffenceShootingFeatEvent
    regist_event CheckAddDeffenceShootingFeatEvent
    regist_event CheckRotateDeffenceShootingFeatEvent

    # 防護射撃が使用される
    # 有効の場合必殺技IDを返す
    def use_deffence_shooting_feat()
      if @feats_enable[FEAT_DEFFENCE_SHOOTING]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::ARW)+Feat.pow(@feats[FEAT_DEFFENCE_SHOOTING]))
      end
    end
    regist_event UseDeffenceShootingFeatEvent

    # 防護射撃が使用される
    # 有効の場合必殺技IDを返す
    def use_deffence_shooting_feat_damage()
      if @feats_enable[FEAT_DEFFENCE_SHOOTING]
        use_feat_event(@feats[FEAT_DEFFENCE_SHOOTING])
        @feats_enable[FEAT_DEFFENCE_SHOOTING] = false
      end
    end
    regist_event UseDeffenceShootingFeatDamageEvent


    # ------------------
    # 再生
    # ------------------

    # 再生が使用されたかのチェック
    def check_recovery_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RECOVERY)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RECOVERY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRecoveryFeatEvent
    regist_event CheckAddRecoveryFeatEvent
    regist_event CheckRotateRecoveryFeatEvent

    # 再生を使用
    def finish_recovery_feat()
      if @feats_enable[FEAT_RECOVERY]
        use_feat_event(@feats[FEAT_RECOVERY])
        @feats_enable[FEAT_RECOVERY] = false
        @cc.owner.healed_event(Feat.pow(@feats[FEAT_RECOVERY]))
      end
    end
    regist_event FinishRecoveryFeatEvent

    # ------------------
    # 幻影
    # ------------------

    # 幻影が使用されたかのチェック
    def check_shadow_attack_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHADOW_ATTACK)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SHADOW_ATTACK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShadowAttackFeatEvent
    regist_event CheckAddShadowAttackFeatEvent
    regist_event CheckRotateShadowAttackFeatEvent

    # 幻影が使用される
    # 有効の場合必殺技IDを返す
    def use_shadow_attack_feat()
      if @feats_enable[FEAT_SHADOW_ATTACK]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SHADOW_ATTACK])
      end
    end
    regist_event UseShadowAttackFeatEvent

    # 幻影が使用終了
    def finish_shadow_attack_feat()
      if @feats_enable[FEAT_SHADOW_ATTACK]
        @feats_enable[FEAT_SHADOW_ATTACK] = false
        use_feat_event(@feats[FEAT_SHADOW_ATTACK])
        point = rand(3)-2
        @cc.owner.move_action(point)
        @cc.foe.move_action(point)
      end
    end
    regist_event FinishShadowAttackFeatEvent

    # ------------------
    # スーサイダルテンデンシー
    # ------------------

    # スーサイダルテンデンシーが使用されたかのチェック
    def check_suicidal_tendencies_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SUICIDAL_TENDENCIES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SUICIDAL_TENDENCIES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSuicidalTendenciesFeatEvent
    regist_event CheckAddSuicidalTendenciesFeatEvent
    regist_event CheckRotateSuicidalTendenciesFeatEvent

    # スーサイダルテンデンシーが使用される
    # 有効の場合必殺技IDを返す
    def use_suicidal_tendencies_feat()
      if @feats_enable[FEAT_SUICIDAL_TENDENCIES]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SUICIDAL_TENDENCIES])*@cc.owner.get_battle_table_point(ActionCard::SPC)
      end
    end
    regist_event UseSuicidalTendenciesFeatEvent

    # スーサイダルテンデンシーが使用終了
    def finish_suicidal_tendencies_feat()
      if @feats_enable[FEAT_SUICIDAL_TENDENCIES]
        @feats_enable[FEAT_SUICIDAL_TENDENCIES] = false
        use_feat_event(@feats[FEAT_SUICIDAL_TENDENCIES])
        owner.damaged_event(@cc.owner.get_battle_table_point(ActionCard::SPC).to_i,IS_NOT_HOSTILE_DAMAGE)
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishSuicidalTendenciesFeatEvent

    # ------------------
    # ミスフィット
    # ------------------
    # ミスフィットが使用されたかのチェック
    def check_misfit_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_MISFIT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MISFIT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMisfitFeatEvent
    regist_event CheckAddMisfitFeatEvent
    regist_event CheckRotateMisfitFeatEvent

    # ミスフィットが使用される
    # 有効の場合必殺技IDを返す
    def use_misfit_feat()
    end
    regist_event UseMisfitFeatEvent


    # ミスフィットが使用終了
    def finish_misfit_feat()
    end
    regist_event FinishMisfitFeatEvent

    # ミスフィットが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_misfit_feat_damage()
      if @feats_enable[FEAT_MISFIT]
        # HPがマイナスで1度だけ発動
        if duel.tmp_damage >= @cc.owner.hit_point && !(@cc.status[STATE_UNDEAD][1] > 0)
          duel.tmp_damage = 0
          set_state(@cc.status[STATE_ATK_UP], 7, Feat.pow(@feats[FEAT_MISFIT]));
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
          set_state(@cc.status[STATE_UNDEAD], 1, Feat.pow(@feats[FEAT_MISFIT]));
          on_buff_event(true, owner.current_chara_card_no, STATE_UNDEAD, @cc.status[STATE_UNDEAD][0], @cc.status[STATE_UNDEAD][1])
          set_state(@cc.status[STATE_DEAD_COUNT], 1, Feat.pow(@feats[FEAT_MISFIT]));
          on_buff_event(true, owner.current_chara_card_no, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0], @cc.status[STATE_DEAD_COUNT][1])
        end
        use_feat_event(@feats[FEAT_MISFIT])
        @feats_enable[FEAT_MISFIT] = false
      end
    end
    regist_event UseMisfitFeatDamageEvent


    # ------------------
    # ビッグブラッグ
    # ------------------

    # ビッグブラッグが使用されたかのチェック
    def check_big_bragg_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BIG_BRAGG)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BIG_BRAGG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBigBraggFeatEvent
    regist_event CheckAddBigBraggFeatEvent
    regist_event CheckRotateBigBraggFeatEvent

    # ビッグブラッグを使用
    def finish_big_bragg_feat()
      if @feats_enable[FEAT_BIG_BRAGG]
        use_feat_event(@feats[FEAT_BIG_BRAGG])
        @feats_enable[FEAT_BIG_BRAGG] = false
        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG]), 3);
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
      end
    end
    regist_event FinishBigBraggFeatEvent


    # ------------------
    # レッツナイフ
    # ------------------

    # レッツナイフが使用されたかのチェック
    def check_lets_knife_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LETS_KNIFE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_LETS_KNIFE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLetsKnifeFeatEvent
    regist_event CheckAddLetsKnifeFeatEvent
    regist_event CheckRotateLetsKnifeFeatEvent

    # レッツナイフが使用される
    # 有効の場合必殺技IDを返す
    def use_lets_knife_feat()
      if @feats_enable[FEAT_LETS_KNIFE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_LETS_KNIFE])*@cc.owner.battle_table.count
      end
    end
    regist_event UseLetsKnifeFeatEvent

    # レッツナイフが使用終了
    def finish_lets_knife_feat()
      if @feats_enable[FEAT_LETS_KNIFE]
        @feats_enable[FEAT_LETS_KNIFE] = false
        use_feat_event(@feats[FEAT_LETS_KNIFE])
      end
    end
    regist_event FinishLetsKnifeFeatEvent

    # ------------------
    # 1つの心
    # ------------------

    # 1つの心が使用されたかのチェック
    def check_single_heart_feat
      @cc.owner.reset_feat_on_cards(FEAT_SINGLE_HEART)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SINGLE_HEART)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveSingleHeartFeatEvent
    regist_event CheckAddSingleHeartFeatEvent
    regist_event CheckRotateSingleHeartFeatEvent

    # 1つの心が使用される
    def use_single_heart_feat()
      if @feats_enable[FEAT_SINGLE_HEART]
        use_feat_event(@feats[FEAT_SINGLE_HEART])
        # 相手のカードを奪う
        Feat.pow(@feats[FEAT_SINGLE_HEART]).times do
          if foe.cards.size > 0
            idx = 0
            value_max = 0
            foe.cards.each_index do |i|
              if value_max < foe.cards[i].get_value_max
                value_max = foe.cards[i].get_value_max
                idx = i
              end
            end
            steal_deal(foe.cards[idx])
          end
        end
        @feats_enable[FEAT_SINGLE_HEART] = false
      end
    end
    regist_event UseSingleHeartFeatEvent


    # ------------------
    # ２つの身体
    # ------------------
    # ２つの身体が使用されたかのチェック
    def check_double_body_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_DOUBLE_BODY)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DOUBLE_BODY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDoubleBodyFeatEvent
    regist_event CheckAddDoubleBodyFeatEvent
    regist_event CheckRotateDoubleBodyFeatEvent

    # ２つの身体が使用される
    # 有効の場合必殺技IDを返す
    def use_double_body_feat()
    end
    regist_event UseDoubleBodyFeatEvent

    # ２つの身体が使用終了
    def finish_double_body_feat()
      if @feats_enable[FEAT_DOUBLE_BODY]
        use_feat_event(@feats[FEAT_DOUBLE_BODY])
      end
    end
    regist_event FinishDoubleBodyFeatEvent

    # ２つの身体が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_double_body_feat_damage()
      if @feats_enable[FEAT_DOUBLE_BODY]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          hps = []
          duel.first_entrant.hit_points.each_index do |i|
            hps << i if duel.first_entrant.hit_points[i] > 0
          end
          # 相手のカードを回転する
          if Feat.pow(@feats[FEAT_DOUBLE_BODY]) > 0
            attribute_party_damage(foe, hps, ((duel.tmp_damage+1)/2).to_i, ATTRIBUTE_REFLECTION, TARGET_TYPE_RANDOM)
          else
            attribute_party_damage(foe, hps, ((duel.tmp_damage)/2).to_i, ATTRIBUTE_REFLECTION, TARGET_TYPE_RANDOM)
          end
        end
        @feats_enable[FEAT_DOUBLE_BODY] = false
      end
    end
    regist_event UseDoubleBodyFeatDamageEvent

    # ------------------
    # 9の魂
    # ------------------
    # 9の魂が使用されたかのチェック
    def check_nine_soul_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_NINE_SOUL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_NINE_SOUL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveNineSoulFeatEvent
    regist_event CheckAddNineSoulFeatEvent
    regist_event CheckRotateNineSoulFeatEvent

    # 9の魂が使用
    def use_nine_soul_feat()
      if @feats_enable[FEAT_NINE_SOUL]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_NINE_SOUL])
      end
    end
    regist_event UseNineSoulFeatEvent

    # 9の魂が使用終了される
    def finish_nine_soul_feat()
      if @feats_enable[FEAT_NINE_SOUL]
        @feats_enable[FEAT_NINE_SOUL] = false
        use_feat_event(@feats[FEAT_NINE_SOUL])
        add_num = Feat.pow(@feats[FEAT_NINE_SOUL]) > 10 ? 2 : 1
        duel.second_entrant.healed_event(((@cc.owner.get_battle_table_point(ActionCard::SPC)+add_num)/2).to_i)
      end
    end
    regist_event FinishNineSoulFeatEvent

    # ------------------
    # 13の眼
    # ------------------

    # 13の眼が使用されたかのチェック
    def check_thirteen_eyes_feat
      f_no = @feats[FEAT_THIRTEEN_EYES] ? FEAT_THIRTEEN_EYES : FEAT_EX_THIRTEEN_EYES
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(f_no)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(f_no)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThirteenEyesFeatEvent
    regist_event CheckAddThirteenEyesFeatEvent
    regist_event CheckRotateThirteenEyesFeatEvent

    def use_thirteen_eyes_feat()
      if @feats_enable[FEAT_THIRTEEN_EYES] || @feats_enable[FEAT_EX_THIRTEEN_EYES]
        owner.tmp_power = 13
        foe.tmp_power = 0
      end
    end
    regist_event UseOwnerThirteenEyesFeatEvent
    regist_event UseFoeThirteenEyesFeatEvent
    regist_event UseFoeExThirteenEyesFeatEvent

    # 13の眼が使用終了
    def finish_thirteen_eyes_feat()
      if @feats_enable[FEAT_THIRTEEN_EYES] || @feats_enable[FEAT_EX_THIRTEEN_EYES]
        f_id = @feats[FEAT_THIRTEEN_EYES] ? @feats[FEAT_THIRTEEN_EYES] : @feats[FEAT_EX_THIRTEEN_EYES]
        use_feat_event(f_id)
        owner.tmp_power = 13
        foe.tmp_power = 0
        owner.point_rewrite_event
        foe.point_rewrite_event
      end
    end
    regist_event FinishThirteenEyesFeatEvent
    regist_event FinishExThirteenEyesFeatEvent

    # 13の眼追加ダメージ
    def use_thirteen_eyes_feat_damage()
      if @feats_enable[FEAT_THIRTEEN_EYES] || @feats_enable[FEAT_EX_THIRTEEN_EYES]
        f_no = @feats[FEAT_THIRTEEN_EYES] ? FEAT_THIRTEEN_EYES : FEAT_EX_THIRTEEN_EYES
        @feats_enable[f_no] = false
        if Feat.pow(@feats[f_no]) > 13
          if duel.tmp_damage < 4
            rec_damage = duel.tmp_damage
            @cc.owner.dice_roll_event(duel.battle_result)
            owner.special_message_event(:EX_THIRTEEN_EYES, duel.tmp_damage.to_s)
            duel.tmp_damage += rec_damage
          end
        end
      end
    end
    regist_event UseThirteenEyesFeatDamageEvent


    # ------------------
    # ライフドレイン
    # ------------------

    # ライフドレインが使用されたかのチェック
    def check_life_drain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LIFE_DRAIN)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LIFE_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLifeDrainFeatEvent
    regist_event CheckAddLifeDrainFeatEvent
    regist_event CheckRotateLifeDrainFeatEvent

    # 必殺技の状態
    def use_life_drain_feat()
      if @feats_enable[FEAT_LIFE_DRAIN]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_LIFE_DRAIN])
      end
    end
    regist_event UseLifeDrainFeatEvent

    # ライフドレインが使用される
    def finish_life_drain_feat()
      if @feats_enable[FEAT_LIFE_DRAIN]
        use_feat_event(@feats[FEAT_LIFE_DRAIN])
      end
    end
    regist_event FinishLifeDrainFeatEvent

    # ライフドレインが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_life_drain_feat_damage()
      if @feats_enable[FEAT_LIFE_DRAIN]
        if duel.tmp_damage>0
          # 回復処理
          @cc.owner.healed_event(1)
        end
        @feats_enable[FEAT_LIFE_DRAIN] = false
      end
    end
    regist_event UseLifeDrainFeatDamageEvent


    # ------------------
    # ランダムカース
    # ------------------

    # ランダムカースが使用されたかのチェック
    def check_random_curse_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RANDOM_CURSE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_RANDOM_CURSE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRandomCurseFeatEvent
    regist_event CheckAddRandomCurseFeatEvent
    regist_event CheckRotateRandomCurseFeatEvent

    # 必殺技の状態
    def use_random_curse_feat()
    end
    regist_event UseRandomCurseFeatEvent

    # ランダムカースが使用される
    def finish_random_curse_feat()
      if @feats_enable[FEAT_RANDOM_CURSE]
        use_feat_event(@feats[FEAT_RANDOM_CURSE])
      end
    end
    regist_event FinishRandomCurseFeatEvent

    # ランダムカースが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_random_curse_feat_damage()
      if @feats_enable[FEAT_RANDOM_CURSE]
        if duel.tmp_damage>0
          tmp = rand(3)
          if tmp == 0
            buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, Feat.pow(@feats[FEAT_RANDOM_CURSE]));
            on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
          elsif tmp == 1
            buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, Feat.pow(@feats[FEAT_RANDOM_CURSE]));
            on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
          else
            buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, Feat.pow(@feats[FEAT_RANDOM_CURSE]));
            on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
          end
        end
        @feats_enable[FEAT_RANDOM_CURSE] = false
      end
    end
    regist_event UseRandomCurseFeatDamageEvent


    # ------------------
    # 癒しの声
    # ------------------

    # 癒しの声が使用されたかのチェック
    def check_heal_voice_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HEAL_VOICE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HEAL_VOICE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHealVoiceFeatEvent
    regist_event CheckAddHealVoiceFeatEvent
    regist_event CheckRotateHealVoiceFeatEvent

    # 癒しの声が使用
    def use_heal_voice_feat()
    end
    regist_event UseHealVoiceFeatEvent

    # 癒しの声が使用終了される
    def finish_heal_voice_feat()
      if @feats_enable[FEAT_HEAL_VOICE]
        @feats_enable[FEAT_HEAL_VOICE] = false
        use_feat_event(@feats[FEAT_HEAL_VOICE])
        duel.second_entrant.healed_event(Feat.pow(@feats[FEAT_HEAL_VOICE]))
      end
    end
    regist_event FinishHealVoiceFeatEvent


    # ------------------
    # ダブルアタック
    # ------------------

    # ダブルアタックが使用されたかのチェック
    def check_double_attack_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DOUBLE_ATTACK)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DOUBLE_ATTACK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveDoubleAttackFeatEvent
    regist_event CheckAddDoubleAttackFeatEvent
    regist_event CheckRotateDoubleAttackFeatEvent

    # ダブルアタックが使用される
    def use_double_attack_feat()
      if @feats_enable[FEAT_DOUBLE_ATTACK]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DOUBLE_ATTACK])
      end
    end
    regist_event UseDoubleAttackFeatEvent

    # ダブルアタックが使用終了される
    def finish_double_attack_feat()
      if @feats_enable[FEAT_DOUBLE_ATTACK]
        @feats_enable[FEAT_DOUBLE_ATTACK] = false
        use_feat_event(@feats[FEAT_DOUBLE_ATTACK])
        # １回目のダメージを保存
        rec_damage = duel.tmp_damage
        rec_dice_heads_atk = duel.tmp_dice_heads_atk
        rec_dice_heads_def = duel.tmp_dice_heads_def
        # ダメージ計算をもう１度実行
        @cc.owner.dice_roll_event(duel.battle_result)
        # ダメージをプラス
        duel.tmp_damage += rec_damage
        duel.tmp_dice_heads_atk += rec_dice_heads_atk
        duel.tmp_dice_heads_def += rec_dice_heads_def
      end
    end
    regist_event FinishDoubleAttackFeatEvent

    # ------------------
    # 全体攻撃
    # ------------------

    # 全体攻撃が使用されたかのチェック
    def check_party_damage_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PARTY_DAMAGE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PARTY_DAMAGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePartyDamageFeatEvent
    regist_event CheckAddPartyDamageFeatEvent
    regist_event CheckRotatePartyDamageFeatEvent

    # 全体攻撃が使用される
    # 有効の場合必殺技IDを返す
    def use_party_damage_feat()
      if @feats_enable[FEAT_PARTY_DAMAGE]
      end
    end
    regist_event UsePartyDamageFeatEvent


    # 全体攻撃が使用終了される
    def finish_party_damage_feat()
      if @feats_enable[FEAT_PARTY_DAMAGE]
        @feats_enable[FEAT_PARTY_DAMAGE] = false
        use_feat_event(@feats[FEAT_PARTY_DAMAGE])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << i if duel.second_entrant.hit_points[i] > 0
        end
        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_PARTY_DAMAGE]), ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
      end
    end
    regist_event FinishPartyDamageFeatEvent

    # ------------------
    # ダメージ軽減
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_guard_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_GUARD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GUARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGuardFeatEvent
    regist_event CheckAddGuardFeatEvent
    regist_event CheckRotateGuardFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_guard_feat()
      if @feats_enable[FEAT_GUARD]
      end
    end
    regist_event UseGuardFeatEvent

    # 必殺技が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_guard_feat_damage()
      if @feats_enable[FEAT_GUARD]
        duel.tmp_damage -= Feat.pow(@feats[FEAT_GUARD])
        duel.tmp_damage = 0 if duel.tmp_damage < 0
        @feats_enable[FEAT_GUARD] = false
      end
    end
    regist_event UseGuardFeatDamageEvent

    # 必殺技が使用終了
    def finish_guard_feat()
      if @feats_enable[FEAT_GUARD]
        use_feat_event(@feats[FEAT_GUARD])
      end
    end
    regist_event FinishGuardFeatEvent


    # ------------------
    # 自壊攻撃
    # ------------------

    # 自壊攻撃が使用されたかのチェック
    def check_death_control_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEATH_CONTROL)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DEATH_CONTROL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeathControlFeatEvent
    regist_event CheckAddDeathControlFeatEvent
    regist_event CheckRotateDeathControlFeatEvent

    # 必殺技の状態
    def use_death_control_feat()
      if @feats_enable[FEAT_DEATH_CONTROL]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DEATH_CONTROL])
      end
    end
    regist_event UseDeathControlFeatEvent

    # 自壊攻撃が使用される
    def finish_death_control_feat()
    end
    regist_event FinishDeathControlFeatEvent

    # 自壊攻撃が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_death_control_feat_damage()
      if @feats_enable[FEAT_DEATH_CONTROL]
        use_feat_event(@feats[FEAT_DEATH_CONTROL])
        if duel.tmp_damage>0

          foe_dead_count_num = foe.current_chara_card.status[STATE_DEAD_COUNT][1]
          own_dead_count_num = owner.current_chara_card.status[STATE_DEAD_COUNT][1]

          if Feat.pow(@feats[FEAT_DEATH_CONTROL]) != 15 || foe_dead_count_num == 0

            foe_dead_count_num = Feat.pow(@feats[FEAT_DEATH_CONTROL]) >= 15 ? 4 : 5
            buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, foe_dead_count_num);
            on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed

          else

            # レイド戦の場合。ステータスArray[1]を1以下にしない(0で通常戦闘時の挙動をするため)。
            foe.current_chara_card.status[STATE_DEAD_COUNT][1] -= 1 unless (!@cc.status_update && foe_dead_count_num == 1)
            update_buff_event(false, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0])

            if own_dead_count_num > 0 && own_dead_count_num < 9

              @cc.status[STATE_DEAD_COUNT][1] += 1
              update_buff_event(true, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0], owner.current_chara_card_no, 1)

            end

            if foe_dead_count_num == 1

              # レイド戦の場合。表示上の残り時間を0にする。
              if @cc.status_update
                off_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0])
                foe.current_chara_card.status[STATE_DEAD_COUNT][1] = 0
              else
                on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], 0)
              end
              foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))

            end

          end

        end
        @feats_enable[FEAT_DEATH_CONTROL] = false
      end
    end
    regist_event UseDeathControlFeatDamageEvent


    # ------------------
    # 移動上昇(機知)
    # ------------------

    # 移動上昇が使用されたかのチェック
    def check_wit_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WIT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_WIT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveWitFeatEvent
    regist_event CheckAddWitFeatEvent
    regist_event CheckRotateWitFeatEvent

    # 必殺技の状態
    def use_wit_feat()
      if @feats_enable[FEAT_WIT]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_WIT])
      end
    end
    regist_event UseWitFeatEvent

    # 移動上昇を使用
    def finish_wit_feat()
      if @feats_enable[FEAT_WIT]
        use_feat_event(@feats[FEAT_WIT])
        @feats_enable[FEAT_WIT] = false
      end
    end
    regist_event FinishWitFeatEvent


    # ------------------
    # 茨の構え
    # ------------------
    # 茨の構えが使用されたかのチェック
    def check_thorn_care_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THORN_CARE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_THORN_CARE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThornCareFeatEvent
    regist_event CheckAddThornCareFeatEvent
    regist_event CheckRotateThornCareFeatEvent

    # 茨の構えが使用される
    # 有効の場合必殺技IDを返す
    def use_thorn_care_feat()
      if @feats_enable[FEAT_THORN_CARE]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::MOVE)*Feat.pow(@feats[FEAT_THORN_CARE]))
      end
    end
    regist_event UseThornCareFeatEvent

    # 茨の構えが使用終了
    def finish_thorn_care_feat()
      if @feats_enable[FEAT_THORN_CARE]
        use_feat_event(@feats[FEAT_THORN_CARE])
      end
    end
    regist_event FinishThornCareFeatEvent

    # 茨の構えが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_thorn_care_feat_damage()
      if @feats_enable[FEAT_THORN_CARE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          # buff処理
          buff_pow = Feat.pow(@feats[FEAT_THORN_CARE]) > 3 ? 6 : 3
          set_state(@cc.status[STATE_ATK_UP], buff_pow, 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
          set_state(@cc.status[STATE_DEF_UP], buff_pow, 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        end
        @feats_enable[FEAT_THORN_CARE] = false
      end
    end
    regist_event UseThornCareFeatDamageEvent


    # ------------------
    # 解放剣
    # ------------------

    # 解放剣が使用されたかのチェック
    def check_liberating_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LIBERATING_SWORD)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LIBERATING_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLiberatingSwordFeatEvent
    regist_event CheckAddLiberatingSwordFeatEvent
    regist_event CheckRotateLiberatingSwordFeatEvent

    # 必殺技の状態
    def use_liberating_sword_feat()
      if @feats_enable[FEAT_LIBERATING_SWORD]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_LIBERATING_SWORD])
      end
    end
    regist_event UseLiberatingSwordFeatEvent

    # 解放剣が使用される
    def finish_liberating_sword_feat()
      if @feats_enable[FEAT_LIBERATING_SWORD]
        use_feat_event(@feats[FEAT_LIBERATING_SWORD])
      end
    end
    regist_event FinishLiberatingSwordFeatEvent

    # 解放剣が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_liberating_sword_feat_damage()
      if @feats_enable[FEAT_LIBERATING_SWORD]
        dmg = 0
        foe.current_chara_card.status.each do |i|
          dmg+=1 if i[1] > 0
        end
        @cc.status.each do |i|
          dmg+=1 if i[1] > 0
        end
        dmg = (dmg*1.5).to_i if Feat.pow(@feats[FEAT_LIBERATING_SWORD]) == 7
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg))
        @feats_enable[FEAT_LIBERATING_SWORD] = false
      end
    end
    regist_event UseLiberatingSwordFeatDamageEvent


    # ------------------
    # 一閃
    # ------------------

    # 一閃が使用されたかのチェック
    def check_one_slash_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ONE_SLASH)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_ONE_SLASH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveOneSlashFeatEvent
    regist_event CheckAddOneSlashFeatEvent
    regist_event CheckRotateOneSlashFeatEvent

    # 必殺技の状態
    def use_one_slash_feat()
    end
    regist_event UseOneSlashFeatEvent

    # 一閃が使用される
    def finish_one_slash_feat()
      if @feats_enable[FEAT_ONE_SLASH]
        use_feat_event(@feats[FEAT_ONE_SLASH])
      end
    end
    regist_event FinishOneSlashFeatEvent

    # 一閃が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_one_slash_feat_damage()
      if @feats_enable[FEAT_ONE_SLASH]
        set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_ONE_SLASH]), 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        @feats_enable[FEAT_ONE_SLASH] = false
      end
    end
    regist_event UseOneSlashFeatDamageEvent


    # ------------------
    # 十閃
    # ------------------

    # 十閃が使用されたかのチェック
    def check_ten_slash_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TEN_SLASH)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_TEN_SLASH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTenSlashFeatEvent
    regist_event CheckAddTenSlashFeatEvent
    regist_event CheckRotateTenSlashFeatEvent

    # 必殺技の状態
    def use_ten_slash_feat()
    end
    regist_event UseTenSlashFeatEvent

    # 十閃が使用される
    def finish_ten_slash_feat()
      if @feats_enable[FEAT_TEN_SLASH]
        use_feat_event(@feats[FEAT_TEN_SLASH])
        @feats_enable[FEAT_TEN_SLASH] = false
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,1))
        set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_TEN_SLASH]), 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
      end
    end
    regist_event FinishTenSlashFeatEvent

    # ------------------
    # 八閃
    # ------------------
    # 八閃が使用されたかのチェック
    def check_hassen_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HASSEN)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HASSEN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHassenFeatEvent
    regist_event CheckAddHassenFeatEvent
    regist_event CheckRotateHassenFeatEvent

    # 必殺技の状態
    def use_hassen_feat()
    end
    regist_event UseHassenFeatEvent

    # 八閃が使用される
    def finish_hassen_feat()
      if @feats_enable[FEAT_HASSEN]
        use_feat_event(@feats[FEAT_HASSEN])
        buff_list = [STATE_ATK_UP, STATE_DEF_UP]

        if @cc.status[STATE_ATK_UP][1] == @cc.status[STATE_DEF_UP][1]
          buff_list.shuffle!
        elsif @cc.status[STATE_ATK_UP][1] > @cc.status[STATE_DEF_UP][1]
          buff_list.reverse!
        end

        buff = buff_list[0]
        set_state(@cc.status[buff], Feat.pow(@feats[FEAT_HASSEN]), 3)
        on_buff_event(true, owner.current_chara_card_no, buff, @cc.status[buff][0], @cc.status[buff][1])

        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,1))

        @feats_enable[FEAT_HASSEN] = false
      end
    end
    regist_event FinishHassenFeatEvent


    # ------------------
    # 百閃
    # ------------------

    # 百閃が使用されたかのチェック
    def check_handled_slash_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HANDLED_SLASH)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HANDLED_SLASH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHandledSlashFeatEvent
    regist_event CheckAddHandledSlashFeatEvent
    regist_event CheckRotateHandledSlashFeatEvent

    # 必殺技の状態
    def use_handled_slash_feat()
      if @feats_enable[FEAT_HANDLED_SLASH]
        @cc.owner.tmp_power += 6
      end
    end
    regist_event UseHandledSlashFeatEvent

    # 百閃が使用される
    def finish_handled_slash_feat()
      if @feats_enable[FEAT_HANDLED_SLASH]
        use_feat_event(@feats[FEAT_HANDLED_SLASH])
      end
    end
    regist_event FinishHandledSlashFeatEvent

    # 百閃が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_handled_slash_feat_damage()
      if @feats_enable[FEAT_HANDLED_SLASH]
        if (@cc.status[STATE_ATK_UP][1] > 0) && (@cc.status[STATE_DEF_UP][1] > 0)
          tmp_dice_atk = duel.tmp_dice_heads_atk
          tmp_dice_def = duel.tmp_dice_heads_def
          (Feat.pow(@feats[FEAT_HANDLED_SLASH])-1).times.each do |i|
            # １回目のダイスを振ってダメージを保存
            rec_damage = duel.tmp_damage
            # ダメージ計算をもう１度実行
            @cc.owner.dice_roll_event(duel.battle_result)
            # ダメージをプラス
            duel.tmp_damage += rec_damage
            tmp_dice_atk += duel.tmp_dice_heads_atk
            tmp_dice_def += duel.tmp_dice_heads_def
          end
          duel.tmp_dice_heads_atk = tmp_dice_atk
          duel.tmp_dice_heads_def = tmp_dice_def
        end
        @feats_enable[FEAT_HANDLED_SLASH] = false
      end
    end
    regist_event UseHandledSlashFeatDamageEvent

    # ------------------
    # 百閃(R)
    # ------------------
    # 百閃が使用されたかのチェック
    def check_handled_slash_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HANDLED_SLASH_R)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HANDLED_SLASH_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHandledSlashRFeatEvent
    regist_event CheckAddHandledSlashRFeatEvent
    regist_event CheckRotateHandledSlashRFeatEvent

    # 必殺技の状態
    def use_handled_slash_r_feat()
      if @feats_enable[FEAT_HANDLED_SLASH_R]
        @cc.owner.tmp_power += 5
      end
    end
    regist_event UseHandledSlashRFeatEvent

    # 百閃が使用される
    def finish_handled_slash_r_feat()
      if @feats_enable[FEAT_HANDLED_SLASH_R]
        use_feat_event(@feats[FEAT_HANDLED_SLASH_R])
      end
    end
    regist_event FinishHandledSlashRFeatEvent

    # 百閃が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_handled_slash_r_feat_damage()
      if @feats_enable[FEAT_HANDLED_SLASH_R]
        add_roll = 0
        if @cc.status[STATE_ATK_UP][1] > 0 && @cc.status[STATE_DEF_UP][1] > 0
          add_roll = Feat.pow(@feats[FEAT_HANDLED_SLASH_R]) - 1
        elsif @cc.status[STATE_ATK_UP][1] > 0 || @cc.status[STATE_DEF_UP][1] > 0
          add_roll = 1 + rand(2)
        end

        tmp_dice_atk = duel.tmp_dice_heads_atk
        tmp_dice_def = duel.tmp_dice_heads_def
        add_roll.times.each do |i|
          # １回目のダイスを振ってダメージを保存
          rec_damage = duel.tmp_damage
          # ダメージ計算をもう１度実行
          @cc.owner.dice_roll_event(duel.battle_result)
          # ダメージをプラス
          duel.tmp_damage += rec_damage
          tmp_dice_atk += duel.tmp_dice_heads_atk
          tmp_dice_def += duel.tmp_dice_heads_def
        end

        duel.tmp_dice_heads_atk = tmp_dice_atk
        duel.tmp_dice_heads_def = tmp_dice_def
        @feats_enable[FEAT_HANDLED_SLASH_R] = false
      end
    end
    regist_event UseHandledSlashRFeatDamageEvent

    # 技可否チェックの百閃用 無効化されたカードを除外してチェックする
    # 撤廃してACに無効化機能をつけるかは今後次第
    def check_feat_handled_slash_rakushasa_edition()
      feat_no = FEAT_HANDLED_SLASH_R
      if @cc.using
        if (@check_feat_range_free || owner.distance == 1) &&
            @cc.status[STATE_SEAL][1] <= 0 &&
            @cc.special_status[SPECIAL_STATE_CAT][1] <= 0 &&
            owner.greater_check(feat_no, ActionCard::SWD, 6)

          unless  @feats_enable[feat_no]
            @feats_enable[feat_no] = true
            on_feat_event(feat_no)
          end
        else
          @cc.owner.reset_feat_on_cards(feat_no)
          if  @feats_enable[feat_no]
            @feats_enable[feat_no] = false
            off_feat_event(feat_no)
          end
        end
      else
        @cc.owner.reset_feat_on_cards(feat_no)
      end
    end

    # ------------------
    # 修羅の構え
    # ------------------
    # 修羅の構えが使用されたかのチェック
    def check_curse_care_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_CURSE_CARE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CURSE_CARE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCurseCareFeatEvent
    regist_event CheckAddCurseCareFeatEvent
    regist_event CheckRotateCurseCareFeatEvent

    # 修羅の構えが使用される
    # 有効の場合必殺技IDを返す
    def use_curse_care_feat()
    end
    regist_event UseCurseCareFeatEvent

    def use_curse_care_feat_heal1()
      if @feats_enable[FEAT_CURSE_CARE]

        reset_flags

        if curse_care_hp_check
          curse_care_healing
          curse_care_play_cutin
        end
      end
    end
    regist_event UseCurseCareFeatHeal1Event

    # 修羅の構えが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_curse_care_feat_damage()
      if @feats_enable[FEAT_CURSE_CARE]

        # 遅くともここ(damage_phase before)で、発動可否に因らずカットインは再生する。
        curse_care_play_cutin

        damage = duel.tmp_damage < 0 ? 0 : duel.tmp_damage
        if curse_care_hp_check(damage)
          curse_care_healing if @curse_care_is_ex
        end
      end
    end
    regist_event UseCurseCareFeatDamageEvent

    # damage after 早期回復
    def use_curse_care_feat_heal2()
      if @feats_enable[FEAT_CURSE_CARE]
        if curse_care_hp_check
          curse_care_healing if @curse_care_is_ex
        end
      end
    end
    regist_event UseCurseCareFeatHeal2Event
    regist_event UseCurseCareFeatHealDetBpEvent

    # 全て終わった後、再チェック
    def use_curse_care_feat_heal3()
        if @feats_enable[FEAT_CURSE_CARE]
        if @curse_care_actuate_ex || curse_care_hp_check
          curse_care_debuffaring
          curse_care_healing if @curse_care_is_ex
        end
        @feats_enable[FEAT_CURSE_CARE] = false
      end
    end
    regist_event UseCurseCareFeatHeal3Event

    def reset_flags
      @curse_care_healed = false                                               # 回復済み？
      @curse_care_cutin_played = false                                         # カットイン再生済み？
      @curse_care_actuate_ex = false                                           # デバフをかけるまで技の有効性を保持する(極力遅デバフをかける
      @curse_care_actuate_normal = false                                       # デバフをかけるまで技の有効性を保持する(極力遅デバフをかける
      @curse_care_dead_line = Feat.pow(@feats[FEAT_CURSE_CARE]) == 7 ? 4 : 0   # HPがdead_line以下ならば発動
      @curse_care_is_ex = Feat.pow(@feats[FEAT_CURSE_CARE]) == 7               # Ex技？
    end

    def curse_care_play_cutin
      if !@curse_care_cutin_played
        use_feat_event(@feats[FEAT_CURSE_CARE])
        @curse_care_cutin_played = true
      end
    end

    def curse_care_hp_check(dmg=0)
      if @cc.owner.hit_point <= @curse_care_dead_line + dmg
        @curse_care_actuate_ex = true
        @curse_care_actuate_normal = true if dmg > 0
        return true
      else
        return false
      end
    end

    def curse_care_healing
      if @curse_care_actuate_ex && !@curse_care_healed && @cc.owner.hit_point > 0
        owner.healed_event(3)
        @curse_care_healed = true
      end
    end

    def curse_care_debuffaring
      if (@curse_care_actuate_normal && !@curse_care_is_ex) || (@curse_care_actuate_ex && @curse_care_is_ex)
        buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_CURSE_CARE]), 3);
        on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_CURSE_CARE]), 3);
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed

        if @curse_care_is_ex
          buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, 3)
          on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        end
      end
    end

    # ------------------
    # 羅刹の構え
    # ------------------
    # 羅刹の構えが使用されたかのチェック
    def check_rakshasa_stance_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RAKSHASA_STANCE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RAKSHASA_STANCE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRakshasaStanceFeatEvent
    regist_event CheckAddRakshasaStanceFeatEvent
    regist_event CheckRotateRakshasaStanceFeatEvent

    # キャラチェンジキャンセル時、技ラベルを点灯する
    def check_rakshasa_stance_state_change
      if @feats_enable[FEAT_RAKSHASA_STANCE]
        add_singlton_method_rakshasa_stance_feat()
        on_feat_event(FEAT_RAKSHASA_STANCE)
      end
    end
    regist_event CheckRakshasaStanceStateChangeEvent

    # 羅刹の構えを使用
    def use_rakshasa_stance_feat()
      if @feats_enable[FEAT_RAKSHASA_STANCE]
        use_feat_event(@feats[FEAT_RAKSHASA_STANCE])
      end
    end
    regist_event UseRakshasaStanceFeatEvent

    # 羅刹が使用されたかのチェック
    def use_rakshasa_stance_feat_result
      if @cc&&@cc.using &&
          owner.initiative? &&
          @feats_enable[FEAT_RAKSHASA_STANCE]

        duel.tmp_damage = duel.tmp_damage * 2
      end
    end
    regist_event UseRakshasaStanceFeatResultEvent

    # 計算が始まる前にカードを無効化
    def on_rakshasa_stance_feat()
      if @cc && @cc.using && @feats_enable[FEAT_RAKSHASA_STANCE]
        add_singlton_method_rakshasa_stance_feat()
      end
    end
    regist_event OnRakshasaStanceFeatEvent

    # ownerに特異メソッドを付加する
    def add_singlton_method_rakshasa_stance_feat()

      unless owner.singleton_class.instance_methods(false).include?(:greater_check)
        def owner.greater_check(feat_no, type, point)
          case type
          when ActionCard::SWD
          else
            return false
          end
          ret  = false
          counter = 0
          value = 0
          @table.each do |a|
            v = a.battle_point(type)
            if v > 0
              value += v
              @feat_battle_table_on_list[feat_no] |= (1 << counter)
            end
            if value >= point
              ret =true
            end
            counter += 1
          end
          ret
        end

        def owner.get_battle_table_point(type)
          ret = 0
          case type
          when ActionCard::SWD
          else
            return ret
          end
          counter = 0
          @table_on_list = 0
          @table.each do  |a|
            tmp = a.battle_point(type)
            if tmp > 0
              @table_on_list = @table_on_list | (1 << counter)
              ret += tmp
            end
            counter +=1
          end
          get_battle_table_focus_point(type)
          ret
        end
      end
    end

    # 取り除く
    def remove_singlton_method_rakshasa_stance_feat()
      if owner.singleton_class.instance_methods(false).include?(:greater_check)
        owner.singleton_class.send(:remove_method, :greater_check)
        owner.singleton_class.send(:remove_method, :get_battle_table_point)
      end
    end

    # 計算が終わったらさっさと解く
    def off_rakshasa_stance_feat
      if @cc && @cc.using && @feats_enable[FEAT_RAKSHASA_STANCE]
        remove_singlton_method_rakshasa_stance_feat()
      end
    end
    regist_event OffRakshasaStanceFeatEvent

    def finish_rakshasa_stance_feat
      if @cc && @cc.using && @feats_enable[FEAT_RAKSHASA_STANCE]
        remove_singlton_method_rakshasa_stance_feat()
        @feats_enable[FEAT_RAKSHASA_STANCE] = false
      end
    end
    regist_event FinishRakshasaStanceFeatEvent

    # ------------------
    # ムーンシャイン
    # ------------------
    # ムーンシャインが使用されたかのチェック
    def check_moon_shine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MOON_SHINE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MOON_SHINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMoonShineFeatEvent
    regist_event CheckAddMoonShineFeatEvent
    regist_event CheckRotateMoonShineFeatEvent

    # ムーンシャインが使用される
    # 有効の場合必殺技IDを返す
    def use_moon_shine_feat()
      if @feats_enable[FEAT_MOON_SHINE]
        @cc.owner.tmp_power+=4
      end
    end
    regist_event UseMoonShineFeatEvent

    # ムーンシャインが使用終了
    def finish_moon_shine_feat()
      if @feats_enable[FEAT_MOON_SHINE]
        use_feat_event(@feats[FEAT_MOON_SHINE])
        # 与えるダメージ
        dmg = 0
        # 特殊カード
        aca = []
        # 特殊カードのみにする
        foe.cards.shuffle.each do |c|
           aca << c if c.u_type == ActionCard::SPC || c.b_type == ActionCard::SPC
        end
        # ダメージの分だけカードを捨てる
        Feat.pow(@feats[FEAT_MOON_SHINE]).times do |a|
          if aca[a]
            dmg+=discard(foe, aca[a])
          end
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
      @feats_enable[FEAT_MOON_SHINE] = false
    end
    regist_event FinishMoonShineFeatEvent

    # ------------------
    # ラプチュア
    # ------------------
    # ラプチュアが使用されたかのチェック
    def check_rapture_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RAPTURE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RAPTURE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRaptureFeatEvent
    regist_event CheckAddRaptureFeatEvent
    regist_event CheckRotateRaptureFeatEvent

    # ラプチュアが使用される
    # 有効の場合必殺技IDを返す
    def use_rapture_feat()
      if @feats_enable[FEAT_RAPTURE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_RAPTURE])
      end
    end
    regist_event UseRaptureFeatEvent

    # ラプチュアが使用終了
    def finish_rapture_feat()
      if @feats_enable[FEAT_RAPTURE]
        use_feat_event(@feats[FEAT_RAPTURE])
      end
    end
    regist_event FinishRaptureFeatEvent

    # ラプチュアが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_rapture_feat_damage()
      if @feats_enable[FEAT_RAPTURE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          # buff処理
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_RAPTURE] = false
      end
    end
    regist_event UseRaptureFeatDamageEvent


    # ------------------
    # ドゥームスデイ
    # ------------------

    # ドゥームスデイが使用されたかのチェック
    def check_doomsday_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DOOMSDAY)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DOOMSDAY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDoomsdayFeatEvent
    regist_event CheckAddDoomsdayFeatEvent
    regist_event CheckRotateDoomsdayFeatEvent

    # ドゥームスデイを使用
    def finish_doomsday_feat()
      if @feats_enable[FEAT_DOOMSDAY]
        use_feat_event(@feats[FEAT_DOOMSDAY])
        @feats_enable[FEAT_DOOMSDAY] = false
        turn = Feat.pow(@feats[FEAT_DOOMSDAY]) > 10 ? Feat.pow(@feats[FEAT_DOOMSDAY]) - 10 : Feat.pow(@feats[FEAT_DOOMSDAY])
        if Feat.pow(@feats[FEAT_DOOMSDAY]) > 10
          buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, turn);
          on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
        end

        if foe.distance == 1
          buffed = set_state(foe.current_chara_card.status[STATE_STONE], 1, turn);
          on_buff_event(false, foe.current_chara_card_no, STATE_STONE, foe.current_chara_card.status[STATE_STONE][0], foe.current_chara_card.status[STATE_STONE][1]) if buffed
        elsif foe.distance == 2
          st = Feat.pow(@feats[FEAT_DOOMSDAY]) > 10 ? STATE_PARALYSIS : STATE_POISON
          buffed = set_state(foe.current_chara_card.status[st], 1, turn);
          on_buff_event(false, foe.current_chara_card_no, st, foe.current_chara_card.status[st][0], foe.current_chara_card.status[st][1]) if buffed
        elsif foe.distance == 3
          buffed = set_state(foe.current_chara_card.status[STATE_BERSERK], 1, turn);
          on_buff_event(false, foe.current_chara_card_no, STATE_BERSERK, foe.current_chara_card.status[STATE_BERSERK][0], foe.current_chara_card.status[STATE_BERSERK][1]) if buffed
        end
      end
    end
    regist_event FinishDoomsdayFeatEvent

    # ------------------
    # hellboundheart
    # ------------------

    # 深淵が使用されたかのチェック
    def check_hell_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HELL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HELL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHellFeatEvent
    regist_event CheckAddHellFeatEvent
    regist_event CheckRotateHellFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_hell_feat()
    end
    regist_event UseHellFeatEvent

    # 深淵が使用終了される
    def finish_hell_feat()
      if @feats_enable[FEAT_HELL]
        @feats_enable[FEAT_HELL] = false
        use_feat_event(@feats[FEAT_HELL])
        d = (@cc.owner.get_battle_table_point(ActionCard::SWD)+@cc.owner.get_battle_table_point(ActionCard::ARW))/Feat.pow(@feats[FEAT_HELL]).to_f
        d = Feat.pow(@feats[FEAT_HELL]) < 5 ? d.ceil : d.to_i
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe, d))
      end
    end
    regist_event FinishHellFeatEvent

    # ------------------
    # スーパーヒロイン
    # ------------------

    # スーパーヒロインが使用されたかのチェック
    def check_awaking_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_AWAKING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_AWAKING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAwakingFeatEvent
    regist_event CheckAddAwakingFeatEvent
    regist_event CheckRotateAwakingFeatEvent
    # スーパーヒロインを使用
    def finish_awaking_feat()
      if @feats_enable[FEAT_AWAKING]
        use_feat_event(@feats[FEAT_AWAKING])
        @feats_enable[FEAT_AWAKING] = false
        set_state(@cc.status[STATE_ATK_UP], 6, Feat.pow(@feats[FEAT_AWAKING]))
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        set_state(@cc.status[STATE_DEF_UP], 4, Feat.pow(@feats[FEAT_AWAKING]))
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        set_state(@cc.status[STATE_MOVE_UP], 1, Feat.pow(@feats[FEAT_AWAKING]));
        on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
      end
    end
    regist_event FinishAwakingFeatEvent

    # ------------------
    # 近距離移動
    # ------------------

    # 近距離移動が使用されたかのチェック
    def check_moving_one_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MOVING_ONE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MOVING_ONE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMovingOneFeatEvent
    regist_event CheckAddMovingOneFeatEvent
    regist_event CheckRotateMovingOneFeatEvent

    # 必殺技の状態
    def use_moving_one_feat()
      if @feats_enable[FEAT_MOVING_ONE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MOVING_ONE]) if @cc.level > foe.current_chara_card.level
      end
    end
    regist_event UseMovingOneFeatEvent

    # 近距離移動を使用
    def finish_moving_one_feat()
      if @feats_enable[FEAT_MOVING_ONE]
        use_feat_event(@feats[FEAT_MOVING_ONE])
        @feats_enable[FEAT_MOVING_ONE] = false
        @cc.owner.move_action(-3)
        @cc.foe.move_action(-3)
      end
    end
    regist_event FinishMovingOneFeatEvent

    # ------------------
    # 下位防御
    # ------------------
    # 下位防御が使用されたかのチェック
    def check_arrogant_one_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ARROGANT_ONE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ARROGANT_ONE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveArrogantOneFeatEvent
    regist_event CheckAddArrogantOneFeatEvent
    regist_event CheckRotateArrogantOneFeatEvent

    # 下位防御が使用される
    # 有効の場合必殺技IDを返す
    def use_arrogant_one_feat()
      if @feats_enable[FEAT_ARROGANT_ONE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ARROGANT_ONE])
      end
    end
    regist_event UseArrogantOneFeatEvent

    # 下位防御が使用終了
    def finish_arrogant_one_feat()
      if @feats_enable[FEAT_ARROGANT_ONE]
        use_feat_event(@feats[FEAT_ARROGANT_ONE])
        @feats_enable[FEAT_ARROGANT_ONE] = false
        const_damage = Feat.pow(@feats[FEAT_ARROGANT_ONE]) > 4 ? 3 : 1
        duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, const_damage)) if @cc.level > foe.current_chara_card.level
      end
    end
    regist_event FinishArrogantOneFeatEvent

    # ------------------
    # 食らうもの
    # ------------------

    # 食らうものが使用されたかのチェック
    def check_eating_one_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_EATING_ONE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_EATING_ONE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEatingOneFeatEvent
    regist_event CheckAddEatingOneFeatEvent
    regist_event CheckRotateEatingOneFeatEvent

    # 食らうものが使用される
    # 有効の場合必殺技IDを返す
    def use_eating_one_feat()
      if @feats_enable[FEAT_EATING_ONE]
        bonus = 0
        if Feat.pow(@feats[FEAT_EATING_ONE]) == 6
          bonus = 2 if foe.current_chara_card.status[STATE_STONE][1] > 0
        end
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::MOVE)*(Feat.pow(@feats[FEAT_EATING_ONE])+bonus))
      end
    end
    regist_event UseEatingOneFeatEvent

    # 食らうものが使用終了
    def finish_eating_one_feat()
      if @feats_enable[FEAT_EATING_ONE]
        @feats_enable[FEAT_EATING_ONE] = false
        use_feat_event(@feats[FEAT_EATING_ONE])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishEatingOneFeatEvent

    # ------------------
    # 蘇るもの
    # ------------------

    # 蘇るものが使用されたかのチェック
    def check_reviving_one_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_REVIVING_ONE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_REVIVING_ONE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRevivingOneFeatEvent
    regist_event CheckAddRevivingOneFeatEvent
    regist_event CheckRotateRevivingOneFeatEvent

    # 蘇るものを使用
    def finish_reviving_one_feat()
      if @feats_enable[FEAT_REVIVING_ONE]
        use_feat_event(@feats[FEAT_REVIVING_ONE])
        @feats_enable[FEAT_REVIVING_ONE] = false
        set_state(@cc.status[STATE_REGENE], 1, Feat.pow(@feats[FEAT_REVIVING_ONE]))
        on_buff_event(true, owner.current_chara_card_no, STATE_REGENE, @cc.status[STATE_REGENE][0], @cc.status[STATE_REGENE][1])
        if Feat.pow(@feats[FEAT_REVIVING_ONE]) > 3
          set_state(@cc.status[STATE_ATK_UP], 4, Feat.pow(@feats[FEAT_REVIVING_ONE]))
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
          set_state(@cc.status[STATE_DEF_UP], 4, Feat.pow(@feats[FEAT_REVIVING_ONE]))
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
          owner.healed_event(1) if owner.hit_point > 0
        end
        buffed = set_state(foe.current_chara_card.status[STATE_STONE], 1, Feat.pow(@feats[FEAT_REVIVING_ONE]))
        on_buff_event(false, foe.current_chara_card_no, STATE_STONE, foe.current_chara_card.status[STATE_STONE][0], foe.current_chara_card.status[STATE_STONE][1]) if buffed
      end
    end
    regist_event FinishRevivingOneFeatEvent

    # ------------------
    # ホワイトライト
    # ------------------
    # ホワイトライトが使用されたかのチェック
    def check_white_light_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WHITE_LIGHT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_WHITE_LIGHT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveWhiteLightFeatEvent
    regist_event CheckAddWhiteLightFeatEvent
    regist_event CheckRotateWhiteLightFeatEvent

    # ホワイトライトを使用
    def finish_white_light_feat()
      if @feats_enable[FEAT_WHITE_LIGHT]
        use_feat_event(@feats[FEAT_WHITE_LIGHT])
        @feats_enable[FEAT_WHITE_LIGHT] = false
        p = Feat.pow(@feats[FEAT_WHITE_LIGHT])
        p *= 2 if foe.current_chara_card.hp == foe.hit_point
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(p).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishWhiteLightFeatEvent

    # ------------------
    # クリスタル・M
    # ------------------

    # クリスタル・Mが使用されたかのチェック
    def check_crystal_shield_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CRYSTAL_SHIELD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CRYSTAL_SHIELD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCrystalShieldFeatEvent
    regist_event CheckAddCrystalShieldFeatEvent
    regist_event CheckRotateCrystalShieldFeatEvent

    # クリスタル・Mが使用される
    # 有効の場合必殺技IDを返す
    def use_crystal_shield_feat()
      if @feats_enable[FEAT_CRYSTAL_SHIELD]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CRYSTAL_SHIELD])
      end
    end
    regist_event UseCrystalShieldFeatEvent

    # クリスタル・Mが使用される
    def use_after_crystal_shield_feat()
      if @feats_enable[FEAT_CRYSTAL_SHIELD]
        use_feat_event(@feats[FEAT_CRYSTAL_SHIELD])
        tmp_table = owner.battle_table.clone
        owner.battle_table = []
        @cc.owner.grave_dealed_event(tmp_table)
        @feats_enable[FEAT_CRYSTAL_SHIELD] = false
      end
    end
    regist_event UseAfterCrystalShieldFeatEvent

    # クリスタル・Mが使用終了される
    def finish_crystal_shield_feat()
      if @feats_enable[FEAT_CRYSTAL_SHIELD]
      end
    end
    regist_event FinishCrystalShieldFeatEvent


    # ------------------
    # スノーボーリング
    # ------------------
    # スノーボーリングが使用されたかのチェック
    def check_snow_balling_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SNOW_BALLING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SNOW_BALLING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSnowBallingFeatEvent
    regist_event CheckAddSnowBallingFeatEvent
    regist_event CheckRotateSnowBallingFeatEvent

    # スノーボーリングが使用される
    # 有効の場合必殺技IDを返す
    def use_snow_balling_feat()
      if @feats_enable[FEAT_SNOW_BALLING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SNOW_BALLING])
      end
    end
    regist_event UseSnowBallingFeatEvent

    # 精密射撃が使用終了
    def finish_snow_balling_feat()
      if @feats_enable[FEAT_SNOW_BALLING]
        use_feat_event(@feats[FEAT_SNOW_BALLING])
      end
    end
    regist_event FinishSnowBallingFeatEvent

    # スノーボーリングが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_snow_balling_feat_damage()
      if @feats_enable[FEAT_SNOW_BALLING]
        # ダメージがプラスなら
        if duel.tmp_damage > 0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if duel.second_entrant.hit_points[i] > 0
          end
          @snow_balling_const_actuated = true
        end
      end
    end
    regist_event UseSnowBallingFeatDamageEvent

    def use_snow_balling_feat_const_damage()
      if @feats_enable[FEAT_SNOW_BALLING]
        # ダメージがプラスなら
        if @snow_balling_const_actuated
          attribute_party_damage(foe, get_hps(foe), 2, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        end
        @feats_enable[FEAT_SNOW_BALLING] = false
        @snow_balling_const_actuated = false
      end
    end
    regist_event UseSnowBallingFeatConstDamageEvent

    # ------------------
    # オビチュアリ
    # ------------------
    # オビチュアリーが使用されたかのチェック
    def check_obituary_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_OBITUARY)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_OBITUARY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveObituaryFeatEvent
    regist_event CheckAddObituaryFeatEvent
    regist_event CheckRotateObituaryFeatEvent

    # オビチュアリが使用される
    # 有効の場合必殺技IDを返す
    def use_obituary_feat()
      if @feats_enable[FEAT_OBITUARY]
        hps = []
        foe.hit_points.each_index do |i|
          hps << [i] if foe.hit_points[i] == 0
        end

        owner.hit_points.each_index do |i|
          hps << [i] if i != owner.current_chara_card_no && owner.hit_points[i] == 0
        end

        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_OBITUARY]) * hps.size
      end
    end
    regist_event UseObituaryFeatEvent

    # 精密射撃が使用終了
    def finish_obituary_feat()
      if @feats_enable[FEAT_OBITUARY]
        use_feat_event(@feats[FEAT_OBITUARY])
      end
    end
    regist_event FinishObituaryFeatEvent

    # オビチュアリが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_obituary_feat_damage()
      if @feats_enable[FEAT_OBITUARY]
        # ダメージがプラスなら
        if duel.tmp_damage > 0
          duel.get_event_deck(foe).freez_event_cards(1)
        end
        @feats_enable[FEAT_OBITUARY] = false
      end
    end
    regist_event UseObituaryFeatDamageEvent


    # ------------------
    # ソルベントレイン
    # ------------------
    # ソルベントレインが使用されたかのチェック
    def check_solvent_rain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SOLVENT_RAIN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SOLVENT_RAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSolventRainFeatEvent
    regist_event CheckAddSolventRainFeatEvent
    regist_event CheckRotateSolventRainFeatEvent

    # ソルベントレインが使用される
    def use_solvent_rain_feat()
      if @feats_enable[FEAT_SOLVENT_RAIN]
        p = 10
        cnt = @cc.owner.battle_table.count
        cnt += foe.battle_table.count if Feat.pow(@feats[FEAT_SOLVENT_RAIN]) == 7
        p += 10 if cnt >= 10
        p += 15 if cnt >= 15
        @cc.owner.tmp_power += p
      end
    end
    regist_event UseSolventRainFeatEvent

    # ソルベントレインが使用終了される
    def finish_solvent_rain_feat()
      if @feats_enable[FEAT_SOLVENT_RAIN]
        @feats_enable[FEAT_SOLVENT_RAIN] = false
        use_feat_event(@feats[FEAT_SOLVENT_RAIN])

        # Exの自壊付与。自分50%自分以外50%で2回抽選するのと確率的に同義な処理
        if Feat.pow(@feats[FEAT_SOLVENT_RAIN]) == 7
          dead_count_turn = 3
          debuff_times = 2

          hps = []
          foe.hit_points.each_index do |i|
            hps << [false, i] if foe.hit_points[i] > 0
          end

          owner.hit_points.each_index do |i|
            hps << [true, i] if i != owner.current_chara_card_no && owner.hit_points[i] > 0
          end

          # 自分にかかる確率は3/4
          own_buff = rand(4) != 0 ? true : false

          if hps.size == 1 || own_buff
            hps = [[true, owner.current_chara_card_no]] + hps.shuffle
          else
            hps = hps.shuffle
          end
          debuff_times.times do |i|
            player = hps[i][0]
            target = player ? owner : foe
            buffed = set_state(target.chara_cards[hps[i][1]].status[STATE_DEAD_COUNT], 1, dead_count_turn)
            on_buff_event(player,
                          hps[i][1],
                          STATE_DEAD_COUNT,
                          target.chara_cards[hps[i][1]].status[STATE_DEAD_COUNT][0],
                          target.chara_cards[hps[i][1]].status[STATE_DEAD_COUNT][1]) if buffed
          end
        end
      end
    end
    regist_event FinishSolventRainFeatEvent

    # ------------------
    # ソルベントレイン(R)
    # ------------------
    # ソルベントレインが使用されたかのチェック
    def check_solvent_rain_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SOLVENT_RAIN_R)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SOLVENT_RAIN_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSolventRainRFeatEvent
    regist_event CheckAddSolventRainRFeatEvent
    regist_event CheckRotateSolventRainRFeatEvent

    # ソルベントレインが使用される
    def use_solvent_rain_r_feat()
      if @feats_enable[FEAT_SOLVENT_RAIN_R]
        p = 10
        cnt = @cc.owner.battle_table.count + foe.battle_table.count
        p += 10 if cnt >= 10
        p += 15 if cnt >= 15
        @cc.owner.tmp_power += p
      end
    end
    regist_event UseSolventRainRFeatEvent

    # ソルベントレインが使用終了される
    def finish_solvent_rain_r_feat()
      if @feats_enable[FEAT_SOLVENT_RAIN_R]
        @feats_enable[FEAT_SOLVENT_RAIN_R] = false
        use_feat_event(@feats[FEAT_SOLVENT_RAIN_R])
      end
    end
    regist_event FinishSolventRainRFeatEvent


    # ------------------
    # 知覚の扉
    # ------------------
    # 知覚の扉が使用されたかのチェック
    def check_awaking_door_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_AWAKING_DOOR)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_AWAKING_DOOR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAwakingDoorFeatEvent
    regist_event CheckAddAwakingDoorFeatEvent
    regist_event CheckRotateAwakingDoorFeatEvent

    # 知覚の扉を使用
    def finish_awaking_door_feat()
      if @feats_enable[FEAT_AWAKING_DOOR]
        use_feat_event(@feats[FEAT_AWAKING_DOOR])
        @feats_enable[FEAT_AWAKING_DOOR] = false
        case rand(3)
        when 0
          set_state(@cc.status[STATE_ATK_UP], 5, Feat.pow(@feats[FEAT_AWAKING_DOOR]));
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        when 1
          set_state(@cc.status[STATE_DEF_UP], 5, Feat.pow(@feats[FEAT_AWAKING_DOOR]));
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        when 2
          set_state(@cc.status[STATE_MOVE_UP], 1, Feat.pow(@feats[FEAT_AWAKING_DOOR]));
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        end
        owner.damaged_event(1,IS_NOT_HOSTILE_DAMAGE) if owner.hit_point > 0
      end
    end
    regist_event FinishAwakingDoorFeatEvent


    # ------------------
    # オーバードウズ
    # ------------------

    # オーバードウズが使用されたかのチェック
    def check_over_dose_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_OVER_DOSE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_OVER_DOSE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveOverDoseFeatEvent
    regist_event CheckAddOverDoseFeatEvent
    regist_event CheckRotateOverDoseFeatEvent

    # オーバードウズが使用される
    def use_over_dose_feat()
      if @feats_enable[FEAT_OVER_DOSE]
        mod = @cc.owner.current_hit_point*2
        mod_max = Feat.pow(@feats[FEAT_OVER_DOSE])
        @cc.owner.tmp_power += (mod > mod_max)? mod_max:mod
      end
    end
    regist_event UseOverDoseFeatEvent

    # オーバードウズが使用終了される
    def finish_over_dose_feat()
      if @feats_enable[FEAT_OVER_DOSE]
        @feats_enable[FEAT_OVER_DOSE] = false
        use_feat_event(@feats[FEAT_OVER_DOSE])
      end
    end
    regist_event FinishOverDoseFeatEvent


    # ------------------
    # レイザーズエッジ
    # ------------------
    # レイザーズエッジが使用されたかのチェック
    def check_razors_edge_feat
      f_no = @feats[FEAT_RAZORS_EDGE] ? FEAT_RAZORS_EDGE : FEAT_EX_RAZORS_EDGE
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(f_no)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(f_no)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRazorsEdgeFeatEvent
    regist_event CheckAddRazorsEdgeFeatEvent
    regist_event CheckRotateRazorsEdgeFeatEvent

    # レイザーズエッジが使用される
    # 有効の場合必殺技IDを返す
    def use_razors_edge_feat()
      if @feats_enable[FEAT_RAZORS_EDGE] || @feats_enable[FEAT_EX_RAZORS_EDGE]
        foe.tmp_power = foe.tmp_power/2
      end
    end
    regist_event UseOwnerRazorsEdgeFeatEvent
    regist_event UseFoeRazorsEdgeFeatEvent
    regist_event UseFoeExRazorsEdgeFeatEvent

    def use_razors_edge_feat_dice_attr()
      if @feats_enable[FEAT_RAZORS_EDGE] || @feats_enable[FEAT_EX_RAZORS_EDGE]
        foe.point_check_silence(Entrant::POINT_CHECK_BATTLE)
        foe.point_rewrite_event
      end
    end
    regist_event UseRazorsEdgeFeatDiceAttrEvent
    regist_event UseExRazorsEdgeFeatDiceAttrEvent

    # レイザーズエッジが使用終了
    def finish_razors_edge_feat()
      if @feats_enable[FEAT_RAZORS_EDGE] || @feats_enable[FEAT_EX_RAZORS_EDGE]
        f_no = @feats[FEAT_RAZORS_EDGE] ? FEAT_RAZORS_EDGE : FEAT_EX_RAZORS_EDGE
        use_feat_event(@feats[f_no])
        @feats_enable[f_no] = false
        # オーバードウズ
        if @feats_enable[FEAT_OVER_DOSE] || @feats_enable[FEAT_THUNDER_STRUCK]
          owner.healed_event(Feat.pow(@feats[f_no]))
        end
      end
    end
    regist_event FinishRazorsEdgeFeatEvent


    # ------------------
    # ヘルズベル
    # ------------------

    # ヘルズベルが使用されたかのチェック
    def check_hells_bell_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HELLS_BELL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HELLS_BELL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHellsBellFeatEvent
    regist_event CheckAddHellsBellFeatEvent
    regist_event CheckRotateHellsBellFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_hells_bell_feat()
    end
    regist_event UseHellsBellFeatEvent

    # ヘルズベルが使用終了される
    def finish_hells_bell_feat()
      if @feats_enable[FEAT_HELLS_BELL]
        @feats_enable[FEAT_HELLS_BELL] = false
        use_feat_event(@feats[FEAT_HELLS_BELL])
        # 敵デッキ全体にダメージ
        hps_f = []
        foe.hit_points.each_with_index do |v,i|
          hps_f << i if v > 0
        end
        attribute_party_damage(foe, hps_f, Feat.pow(@feats[FEAT_HELLS_BELL]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL) if hps_f.size > 0

        # 自身を除く自デッキ全体にダメージ
        hps_o = []
        owner.hit_points.each_with_index do |v,i|
          hps_o << i if v > 0 && i != owner.current_chara_card_no
        end
        attribute_party_damage(owner, hps_o, Feat.pow(@feats[FEAT_HELLS_BELL]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL, 1, IS_NOT_HOSTILE_DAMAGE) if hps_o.size > 0

        # オーバードウズ
        if @feats_enable[FEAT_OVER_DOSE] || @feats_enable[FEAT_THUNDER_STRUCK]
          owner.healed_event(Feat.pow(@feats[FEAT_HELLS_BELL]))
        end
      end
    end
    regist_event FinishHellsBellFeatEvent

    # ------------------
    # ドレインシード
    # ------------------

    # ドレインシードが使用されたかのチェック
    def check_drain_seed_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DRAIN_SEED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DRAIN_SEED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDrainSeedFeatEvent
    regist_event CheckAddDrainSeedFeatEvent
    regist_event CheckRotateDrainSeedFeatEvent

    # ドレインシードを使用
    def finish_drain_seed_feat()
      if @feats_enable[FEAT_DRAIN_SEED]
        use_feat_event(@feats[FEAT_DRAIN_SEED])
        @feats_enable[FEAT_DRAIN_SEED] = false
        set_state(@cc.status[STATE_REGENE], 1, Feat.pow(@feats[FEAT_DRAIN_SEED]))
        on_buff_event(true, owner.current_chara_card_no, STATE_REGENE, @cc.status[STATE_REGENE][0], @cc.status[STATE_REGENE][1])
        buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, Feat.pow(@feats[FEAT_DRAIN_SEED]))
        on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
      end
    end
    regist_event FinishDrainSeedFeatEvent

    # ------------------
    # 攻撃吸収
    # ------------------

    # 攻撃吸収が使用されたかのチェック
    def check_atk_drain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ATK_DRAIN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ATK_DRAIN)
#      check_feat(@cc.owner.greater_check(FEAT_ATK_DRAIN, ActionCard::SPC,4), FEAT_ATK_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAtkDrainFeatEvent
    regist_event CheckAddAtkDrainFeatEvent
    regist_event CheckRotateAtkDrainFeatEvent

    # 攻撃吸収が使用される
    # 有効の場合必殺技IDを返す
    def use_atk_drain_feat()
    end
    regist_event UseAtkDrainFeatEvent


    # 攻撃吸収が使用終了される
    def finish_atk_drain_feat()
      if @feats_enable[FEAT_ATK_DRAIN]
        @feats_enable[FEAT_ATK_DRAIN] = false
        use_feat_event(@feats[FEAT_ATK_DRAIN])
        buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_ATK_DRAIN]), 3)
        on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
      end
    end
    regist_event FinishAtkDrainFeatEvent

    # ------------------
    # 防御吸収
    # ------------------

    # 防御吸収が使用されたかのチェック
    def check_def_drain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEF_DRAIN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DEF_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDefDrainFeatEvent
    regist_event CheckAddDefDrainFeatEvent
    regist_event CheckRotateDefDrainFeatEvent

    # 防御吸収が使用される
    # 有効の場合必殺技IDを返す
    def use_def_drain_feat()
    end
    regist_event UseDefDrainFeatEvent


    # 防御吸収が使用終了される
    def finish_def_drain_feat()
      if @feats_enable[FEAT_DEF_DRAIN]
        @feats_enable[FEAT_DEF_DRAIN] = false
        use_feat_event(@feats[FEAT_DEF_DRAIN])
        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_DEF_DRAIN]), 3)
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
      end
    end
    regist_event FinishDefDrainFeatEvent

    # ------------------
    # 混沌の翼
    # ------------------

    # 混沌の翼が使用されたかのチェック
    def check_mov_drain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MOV_DRAIN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MOV_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMovDrainFeatEvent
    regist_event CheckAddMovDrainFeatEvent
    regist_event CheckRotateMovDrainFeatEvent

    # 混沌の翼を使用
    def finish_mov_drain_feat()
      if @feats_enable[FEAT_MOV_DRAIN]
        use_feat_event(@feats[FEAT_MOV_DRAIN])
        @feats_enable[FEAT_MOV_DRAIN] = false
        buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], Feat.pow(@feats[FEAT_MOV_DRAIN]), 3)
        on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
      end
    end
    regist_event FinishMovDrainFeatEvent

    # ------------------
    # 毒竜燐
    # ------------------
    # 毒竜燐が使用されたかのチェック
    def check_poison_skin_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_POISON_SKIN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_POISON_SKIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePoisonSkinFeatEvent
    regist_event CheckAddPoisonSkinFeatEvent
    regist_event CheckRotatePoisonSkinFeatEvent

    # 毒竜燐が使用される
    # 有効の場合必殺技IDを返す
    def use_poison_skin_feat()
      if @feats_enable[FEAT_POISON_SKIN]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_POISON_SKIN])
      end
    end
    regist_event UsePoisonSkinFeatEvent

    # 毒竜燐が使用終了
    def finish_poison_skin_feat()
      if @feats_enable[FEAT_POISON_SKIN]
        use_feat_event(@feats[FEAT_POISON_SKIN])
      end
    end
    regist_event FinishPoisonSkinFeatEvent

    # 毒竜燐が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_poison_skin_feat_damage()
      if @feats_enable[FEAT_POISON_SKIN]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          # buff処理
          buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
        end
        @feats_enable[FEAT_POISON_SKIN] = false
      end
    end
    regist_event UsePoisonSkinFeatDamageEvent

    # ------------------
    # 咆哮
    # ------------------

    # 咆哮が使用されたかのチェック
    def check_roar_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ROAR)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ROAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRoarFeatEvent
    regist_event CheckAddRoarFeatEvent
    regist_event CheckRotateRoarFeatEvent

    # 咆哮が使用される
    # 有効の場合必殺技IDを返す
    def use_roar_feat()
      if @feats_enable[FEAT_ROAR]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_ROAR])
      end
    end
    regist_event UseRoarFeatEvent

    # 咆哮が使用終了
    def finish_roar_feat()
      if @feats_enable[FEAT_ROAR]
        @feats_enable[FEAT_ROAR] = false
        use_feat_event(@feats[FEAT_ROAR])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishRoarFeatEvent


    # ------------------
    # 火炎のブレス
    # ------------------

    # 火炎のブレスが使用されたかのチェック
    def check_fire_breath_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FIRE_BREATH)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FIRE_BREATH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFireBreathFeatEvent
    regist_event CheckAddFireBreathFeatEvent
    regist_event CheckRotateFireBreathFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_fire_breath_feat()
    end
    regist_event UseFireBreathFeatEvent

    # 火炎のブレスが使用終了される
    def finish_fire_breath_feat()
      if @feats_enable[FEAT_FIRE_BREATH]
        @feats_enable[FEAT_FIRE_BREATH] = false
        use_feat_event(@feats[FEAT_FIRE_BREATH])
        # 敵デッキ全体にダメージ
        hps = []
        foe.hit_points.each_with_index do |v,i|
          hps << i if v > 0
        end

        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_FIRE_BREATH]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)

      end
    end
    regist_event FinishFireBreathFeatEvent


    # ------------------
    # ワールウインド
    # ------------------

    # ワールウインドが使用されたかのチェック
    def check_whirl_wind_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WHIRL_WIND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_WHIRL_WIND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWhirlWindFeatEvent
    regist_event CheckAddWhirlWindFeatEvent
    regist_event CheckRotateWhirlWindFeatEvent

    # ワールウインドが使用される
    # 有効の場合必殺技IDを返す
    def use_whirl_wind_feat()
      if @feats_enable[FEAT_WHIRL_WIND]
        @cc.owner.tmp_power+=(owner.distance * Feat.pow(@feats[FEAT_WHIRL_WIND]))
      end
    end
    regist_event UseWhirlWindFeatEvent

    # ワールウインドが使用終了
    def finish_whirl_wind_feat()
      if @feats_enable[FEAT_WHIRL_WIND]
        @feats_enable[FEAT_WHIRL_WIND] = false
        use_feat_event(@feats[FEAT_WHIRL_WIND])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishWhirlWindFeatEvent


    # ------------------
    # アクティブアーマ
    # ------------------
    # アクティブアーマが使用されたかのチェック
    def check_active_armor_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ACTIVE_ARMOR)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ACTIVE_ARMOR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveActiveArmorFeatEvent
    regist_event CheckAddActiveArmorFeatEvent
    regist_event CheckRotateActiveArmorFeatEvent

    # アクティブアーマが使用される
    # 有効の場合必殺技IDを返す
    def use_active_armor_feat()
      if @feats_enable[FEAT_ACTIVE_ARMOR]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::DEF)*Feat.pow(@feats[FEAT_ACTIVE_ARMOR]))
      end
    end
    regist_event UseActiveArmorFeatEvent

    # アクティブアーマが使用される
    # 有効の場合必殺技IDを返す
    def use_active_armor_feat_damage()
      if @feats_enable[FEAT_ACTIVE_ARMOR]
        use_feat_event(@feats[FEAT_ACTIVE_ARMOR])
        set_state(@cc.status[STATE_PARALYSIS], 1, 1)
        on_buff_event(true, owner.current_chara_card_no, STATE_PARALYSIS, @cc.status[STATE_PARALYSIS][0], @cc.status[STATE_PARALYSIS][1])
        @feats_enable[FEAT_ACTIVE_ARMOR] = false
      end
    end
    regist_event UseActiveArmorFeatDamageEvent

    # 封印状態と更新を管理する
    @active_armor_feat_state_initialized = false
    @active_armor_feat_state_sealing = false
    @active_armor_feat_state_changed = false
    def set_active_armor_feat_sealing_state()
      chara_id = @cc.owner.current_chara_card.charactor_id
      if @active_armor_feat_state_initialized
        if @cc.status[STATE_SEAL][1] > 0 != @active_armor_feat_state_sealing
          @active_armor_feat_state_sealing = @cc.status[STATE_SEAL][1] > 0
          @active_armor_feat_state_changed = true
        end
      else
        @active_armor_feat_state_sealing = @cc.status[STATE_SEAL][1] > 0
        @active_armor_feat_state_changed = false
        @active_armor_feat_state_initialized = true
      end
    end
    regist_event CheckSealActiveArmorFeatCharaChangeEvent

    def check_seal_active_armor_feat()
      set_active_armor_feat_sealing_state
      if @cc.status[STATE_SEAL][1] > 0 && @cc.owner.hit_point > 0 && @active_armor_feat_state_changed
        on_transform_sequence(true)
        @active_armor_feat_state_changed = false
      end
    end
    regist_event CheckSealActiveArmorFeatMoveAfterEvent
    regist_event CheckSealActiveArmorFeatDetChangeAfterEvent
    regist_event CheckSealActiveArmorFeatDamageAfterEvent

    def check_unseal_active_armor_feat
      set_active_armor_feat_sealing_state
      if @cc.status[STATE_SEAL][1] == 0 && @cc.owner.hit_point > 0 && @active_armor_feat_state_changed
        off_transform_sequence(true)
        @active_armor_feat_state_changed = false
      end
    end
    regist_event CheckUnsealActiveArmorFeatDamageAfterEvent
    regist_event CheckUnsealActiveArmorFeatStartTurnEvent

    # ------------------
    # マシンガン
    # ------------------

    # マシンガンが使用されたかのチェック
    def check_scolor_attack_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SCOLOR_ATTACK)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SCOLOR_ATTACK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveScolorAttackFeatEvent
    regist_event CheckAddScolorAttackFeatEvent
    regist_event CheckRotateScolorAttackFeatEvent

    # 必殺技の状態
    def use_scolor_attack_feat()
      if @feats_enable[FEAT_SCOLOR_ATTACK]
      end
    end
    regist_event UseScolorAttackFeatEvent

    # マシンガンが使用される
    def finish_scolor_attack_feat()
      if @feats_enable[FEAT_SCOLOR_ATTACK]
        use_feat_event(@feats[FEAT_SCOLOR_ATTACK])
      end
    end
    regist_event FinishScolorAttackFeatEvent

    # マシンガンが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_scolor_attack_feat_damage()
      if @feats_enable[FEAT_SCOLOR_ATTACK]
        if duel.tmp_damage>0
          duel.tmp_damage += duel.tmp_damage * rand(Feat.pow(@feats[FEAT_SCOLOR_ATTACK]))
        end
        @feats_enable[FEAT_SCOLOR_ATTACK] = false
      end
    end
    regist_event UseScolorAttackFeatDamageEvent

    # ------------------
    # ヒートシーカー
    # ------------------

    # ヒートシーカーが使用されたかのチェック
    def check_heat_seeker_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HEAT_SEEKER)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HEAT_SEEKER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHeatSeekerFeatEvent
    regist_event CheckAddHeatSeekerFeatEvent
    regist_event CheckRotateHeatSeekerFeatEvent

    # 必殺技の状態
    def use_heat_seeker_feat()
      if @feats_enable[FEAT_HEAT_SEEKER]
        @cc.owner.tmp_power = 0 if Feat.pow(@feats[FEAT_HEAT_SEEKER]) != 9
      end
    end
    regist_event UseHeatSeekerFeatEvent

    # ヒートシーカーが使用される
    def finish_heat_seeker_feat()
      if @feats_enable[FEAT_HEAT_SEEKER]
        use_feat_event(@feats[FEAT_HEAT_SEEKER])
      end
    end
    regist_event FinishHeatSeekerFeatEvent

    # ヒートシーカーが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_heat_seeker_feat_damage()
      if @feats_enable[FEAT_HEAT_SEEKER]
        if Feat.pow(@feats[FEAT_HEAT_SEEKER]) == 9 && @cc.status[STATE_PARALYSIS][1] > 0
          set_state(@cc.status[STATE_PARALYSIS], 1, 0)
          off_buff_event(true, owner.current_chara_card_no, STATE_PARALYSIS, @cc.status[STATE_PARALYSIS][0])
        end

        buff_turn = Feat.pow(@feats[FEAT_HEAT_SEEKER]) == 9 ? 5 : 3
        set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_HEAT_SEEKER]), buff_turn)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])

        @feats_enable[FEAT_HEAT_SEEKER] = false
      end
    end
    regist_event UseHeatSeekerFeatDamageEvent

    # ------------------
    # パージ
    # ------------------

    # パージが使用されたかのチェック
    def check_purge_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PURGE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PURGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemovePurgeFeatEvent
    regist_event CheckAddPurgeFeatEvent
    regist_event CheckRotatePurgeFeatEvent

    # パージを使用
    def finish_purge_feat()
      if @feats_enable[FEAT_PURGE]
        use_feat_event(@feats[FEAT_PURGE])
        @feats_enable[FEAT_PURGE] = false
        if Feat.pow(@feats[FEAT_PURGE]) == 9 && owner.distance == 1
          d = owner.hit_point
          d = 5 if d > 5
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, d))
        end

        owner.healed_event(Feat.pow(@feats[FEAT_PURGE]))
        set_state(@cc.status[STATE_MOVE_UP], 1, 9)
        on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        set_state(@cc.status[STATE_SEAL], 1, 9)
        on_buff_event(true, owner.current_chara_card_no, STATE_SEAL, @cc.status[STATE_SEAL][0], @cc.status[STATE_SEAL][1])
      end
    end
    regist_event FinishPurgeFeatEvent


    # ------------------
    # ハイハンド
    # ------------------
    # ハイハンドが使用されたかのチェック
    def check_high_hand_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HIGH_HAND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HIGH_HAND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHighHandFeatEvent
    regist_event CheckAddHighHandFeatEvent
    regist_event CheckRotateHighHandFeatEvent

    # ハイハンドが使用される
    # 有効の場合必殺技IDを返す
    def use_high_hand_feat()
      if @feats_enable[FEAT_HIGH_HAND]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_HIGH_HAND])*@cc.foe.battle_table.count
      end
    end
    regist_event UseHighHandFeatEvent

    # ハイハンドが使用される
    # 有効の場合必殺技IDを返す
    def use_high_hand_feat_damage()
      if @feats_enable[FEAT_HIGH_HAND]
        use_feat_event(@feats[FEAT_HIGH_HAND])
        @feats_enable[FEAT_HIGH_HAND] = false
      end
    end
    regist_event UseHighHandFeatDamageEvent


    # ------------------
    # ジャックポット
    # ------------------

    # ジャックポットが使用されたかのチェック
    def check_jack_pot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_JACK_POT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_JACK_POT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveJackPotFeatEvent
    regist_event CheckAddJackPotFeatEvent
    regist_event CheckRotateJackPotFeatEvent

    # ジャックポットが使用される
    # 有効の場合必殺技IDを返す
    def use_jack_pot_feat()
    end
    regist_event UseJackPotFeatEvent

    # ジャックポットが使用される
    def use_after_jack_pot_feat()
      if @feats_enable[FEAT_JACK_POT]
        use_feat_event(@feats[FEAT_JACK_POT])
        multi_num = Feat.pow(@feats[FEAT_JACK_POT]) > 2 ? 2 : Feat.pow(@feats[FEAT_JACK_POT])
        p = owner.battle_table.count * multi_num
        p += 2 if Feat.pow(@feats[FEAT_JACK_POT]) > 2
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(p).each{ |c| @cc.owner.dealed_event(c)})
        @feats_enable[FEAT_JACK_POT] = false
      end
    end
    regist_event UseAfterJackPotFeatEvent

    # ジャックポットが使用終了される
    def finish_jack_pot_feat()
      if @feats_enable[FEAT_JACK_POT]
      end
    end
    regist_event FinishJackPotFeatEvent

    # ------------------
    # ローボール
    # ------------------

    # ローボールが使用されたかのチェック
    def check_low_ball_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LOW_BALL)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LOW_BALL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLowBallFeatEvent
    regist_event CheckAddLowBallFeatEvent
    regist_event CheckRotateLowBallFeatEvent

    # 必殺技の状態
    def use_low_ball_feat()
      if @feats_enable[FEAT_LOW_BALL]
      end
    end
    regist_event UseLowBallFeatEvent

    # ローボールが使用される
    def finish_low_ball_feat()
      if @feats_enable[FEAT_LOW_BALL]
        use_feat_event(@feats[FEAT_LOW_BALL])
      end
    end
    regist_event FinishLowBallFeatEvent

    # ローボールが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_low_ball_feat_damage()
      if @feats_enable[FEAT_LOW_BALL]
        duel.tmp_damage += Feat.pow(@feats[FEAT_LOW_BALL])
        @feats_enable[FEAT_LOW_BALL] = false
      end
    end
    regist_event UseLowBallFeatDamageEvent

    # ------------------
    # ギャンブル
    # ------------------

    # ギャンブルが使用されたかのチェック
    def check_gamble_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GAMBLE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_GAMBLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGambleFeatEvent
    regist_event CheckAddGambleFeatEvent
    regist_event CheckRotateGambleFeatEvent

    # 必殺技の状態
    def use_gamble_feat()
      if @feats_enable[FEAT_GAMBLE]
      end
    end
    regist_event UseGambleFeatEvent

    # ギャンブルが使用される
    def finish_gamble_feat()
      if @feats_enable[FEAT_GAMBLE]
        use_feat_event(@feats[FEAT_GAMBLE])
      end
    end
    regist_event FinishGambleFeatEvent

    # ギャンブルが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_gamble_feat_damage()
      if @feats_enable[FEAT_GAMBLE]
        if duel.tmp_damage == 1 || (Feat.pow(@feats[FEAT_GAMBLE]) == 0 && duel.tmp_damage == 2)
          duel.tmp_damage = attribute_damage(ATTRIBUTE_DEATH, foe)
        end
        @feats_enable[FEAT_GAMBLE] = false
      end
    end
    regist_event UseGambleFeatDamageEvent


    # ------------------
    # バードケージ
    # ------------------

    # バードケージが使用されたかのチェック
    def check_bird_cage_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BIRD_CAGE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BIRD_CAGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBirdCageFeatEvent
    regist_event CheckAddBirdCageFeatEvent
    regist_event CheckRotateBirdCageFeatEvent

    # バードケージを使用
    def finish_bird_cage_feat()
      if @feats_enable[FEAT_BIRD_CAGE]
        use_feat_event(@feats[FEAT_BIRD_CAGE])
        @feats_enable[FEAT_BIRD_CAGE] = false
        buffed = set_state(foe.current_chara_card.status[STATE_BIND], 1, Feat.pow(@feats[FEAT_BIRD_CAGE]));
        on_buff_event(false, foe.current_chara_card_no, STATE_BIND, foe.current_chara_card.status[STATE_BIND][0], foe.current_chara_card.status[STATE_BIND][1]) if buffed
      end
    end
    regist_event FinishBirdCageFeatEvent

    # ------------------
    # ハンギング
    # ------------------

    # ハンギングが使用されたかのチェック
    def check_hanging_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HANGING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HANGING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHangingFeatEvent
    regist_event CheckAddHangingFeatEvent
    regist_event CheckRotateHangingFeatEvent

    # ハンギングが使用される
    # 有効の場合必殺技IDを返す
    def use_hanging_feat()
      if @feats_enable[FEAT_HANGING]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_HANGING])
      end
    end
    regist_event UseHangingFeatEvent

    # ハンギングが使用終了
    def finish_hanging_feat()
      if @feats_enable[FEAT_HANGING]
        use_feat_event(@feats[FEAT_HANGING])
        @feats_enable[FEAT_HANGING] = false
        d = foe.current_chara_card.status[STATE_BIND][1]
        d += 1 if d > 0 && Feat.pow(@feats[FEAT_HANGING]) > 5
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,d))
      end
    end
    regist_event FinishHangingFeatEvent

    # ------------------
    # ブラストオフ
    # ------------------

    # ブラストオフが使用されたかのチェック
    def check_blast_off_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLAST_OFF)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLAST_OFF)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlastOffFeatEvent
    regist_event CheckAddBlastOffFeatEvent
    regist_event CheckRotateBlastOffFeatEvent

    # ブラストオフが使用される
    # 有効の場合必殺技IDを返す
    def use_blast_off_feat()
      if @feats_enable[FEAT_BLAST_OFF]
        pt = Feat.pow(@feats[FEAT_BLAST_OFF]) > 7 ? 7 : Feat.pow(@feats[FEAT_BLAST_OFF])
        @cc.owner.tmp_power += pt
      end
    end
    regist_event UseBlastOffFeatEvent

    # ブラストオフが使用終了
    def ex_blast_off_feat()
      if @feats_enable[FEAT_BLAST_OFF] && Feat.pow(@feats[FEAT_BLAST_OFF]) > 7
        @cc.owner.move_action(-1)
        @cc.foe.move_action(-1)
      end
    end
    regist_event ExBlastOffFeatEvent

    # ブラストオフが使用終了
    def finish_blast_off_feat()
      if @feats_enable[FEAT_BLAST_OFF]
        @feats_enable[FEAT_BLAST_OFF] = false
        use_feat_event(@feats[FEAT_BLAST_OFF])
        @cc.owner.move_action(2)
        @cc.foe.move_action(2)
      end
    end
    regist_event FinishBlastOffFeatEvent

    # ------------------
    # パペットマスター
    # ------------------

    # パペットマスターが使用されたかのチェック
    def check_puppet_master_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PUPPET_MASTER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PUPPET_MASTER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePuppetMasterFeatEvent
    regist_event CheckAddPuppetMasterFeatEvent
    regist_event CheckRotatePuppetMasterFeatEvent

    # パペットマスターが使用される
    def use_puppet_master_feat()
      if @feats_enable[FEAT_PUPPET_MASTER]
        use_feat_event(@feats[FEAT_PUPPET_MASTER])
        # 相手の使用カードを奪う
        tmp_table = foe.battle_table.clone
        foe.battle_table = []
        @cc.owner.grave_dealed_event(tmp_table)
        # 相手の手札を奪う
        foe.cards.size.times do
          if foe.cards.size > 0
            steal_deal(foe.cards[rand(foe.cards.size)])
          end
        end
        @feats_enable[FEAT_PUPPET_MASTER] = false
      end
    end
    regist_event UsePuppetMasterFeatEvent

    # パペットマスターが使用終了される
    def finish_puppet_master_feat()
      if @feats_enable[FEAT_PUPPET_MASTER]
      end
    end
    regist_event FinishPuppetMasterFeatEvent

    # ------------------
    # C.T.L
    # ------------------
    # C.T.Lが使用されたかのチェック
    def check_ctl_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CTL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CTL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCtlFeatEvent
    regist_event CheckAddCtlFeatEvent
    regist_event CheckRotateCtlFeatEvent

    # C.T.Lが使用される
    # 有効の場合必殺技IDを返す
    def use_ctl_feat()
      if @feats_enable[FEAT_CTL]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CTL])
        # 特殊カードをさがす
        foe.cards.each do |c|
          if c.u_type == ActionCard::SPC || c.b_type == ActionCard::SPC
            @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CTL])
            break
          end
        end
      end
    end
    regist_event UseCtlFeatEvent

    # C.T.Lが使用終了
    def finish_ctl_feat()
      if @feats_enable[FEAT_CTL]
        use_feat_event(@feats[FEAT_CTL])
      end
      @feats_enable[FEAT_CTL] = false
    end
    regist_event FinishCtlFeatEvent

    # ------------------
    # B.P.A
    # ------------------
    # B.P.Aが使用されたかのチェック
    def check_bpa_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BPA)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BPA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBpaFeatEvent
    regist_event CheckAddBpaFeatEvent
    regist_event CheckRotateBpaFeatEvent

    # B.P.Aが使用される
    # 有効の場合必殺技IDを返す
    def use_bpa_feat()
      if @feats_enable[FEAT_BPA]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BPA])
      end
    end
    regist_event UseBpaFeatEvent

    # B.P.Aが使用終了
    def finish_bpa_feat()
      if @feats_enable[FEAT_BPA]
        use_feat_event(@feats[FEAT_BPA])
        dmg = 0
        dmg = foe.battle_table.size if foe.battle_table
        dmg += 1 if (Feat.pow(@feats[FEAT_BPA]) == 5 && dmg > 0)
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
      @feats_enable[FEAT_BPA] = false
    end
    regist_event FinishBpaFeatEvent

    # ------------------
    # L.A.R
    # ------------------

    # L.A.Rが使用されたかのチェック
    def check_lar_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LAR)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLarFeatEvent
    regist_event CheckAddLarFeatEvent
    regist_event CheckRotateLarFeatEvent

    # 必殺技の状態
    def use_lar_feat()
      if @feats_enable[FEAT_LAR]
      end
    end
    regist_event UseLarFeatEvent

    # L.A.Rが使用される
    def finish_lar_feat()
      if @feats_enable[FEAT_LAR]
        heal_pt = (Feat.pow(@feats[FEAT_LAR]) > 1 && @cc.status[STATE_CHAOS][1] > 0) ? 2 : 1
        @cc.owner.healed_event(heal_pt)
        use_feat_event(@feats[FEAT_LAR])
      end
    end
    regist_event FinishLarFeatEvent

    # L.A.Rが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_lar_feat_damage()
      if @feats_enable[FEAT_LAR]
        if duel.tmp_damage > 0
          @cc.owner.healed_event(Feat.pow(@feats[FEAT_LAR]))
        end
        @feats_enable[FEAT_LAR] = false
      end
    end
    regist_event UseLarFeatDamageEvent

    # ------------------
    # S.S.S
    # ------------------

    # S.S.Sが使用されたかのチェック
    def check_sss_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SSS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SSS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveSssFeatEvent
    regist_event CheckAddSssFeatEvent
    regist_event CheckRotateSssFeatEvent

    # S.S.Sを使用
    def finish_sss_feat()
      if @feats_enable[FEAT_SSS]
        use_feat_event(@feats[FEAT_SSS])
        @feats_enable[FEAT_SSS] = false
        set_state(@cc.status[STATE_CHAOS], 1, Feat.pow(@feats[FEAT_SSS]));
        on_buff_event(true, owner.current_chara_card_no, STATE_CHAOS, @cc.status[STATE_CHAOS][0], @cc.status[STATE_CHAOS][1])
      end
    end
    regist_event FinishSssFeatEvent

    # ------------------
    # カウンターラッシュ
    # ------------------
    # カウンターラッシュが使用されたかのチェック
    def check_counter_rush_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COUNTER_RUSH)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_COUNTER_RUSH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCounterRushFeatEvent
    regist_event CheckAddCounterRushFeatEvent
    regist_event CheckRotateCounterRushFeatEvent

    # カウンターラッシュが使用される
    # 有効の場合必殺技IDを返す
    def use_counter_rush_feat()
      if @feats_enable[FEAT_COUNTER_RUSH]
        @cc.owner.tmp_power = foe.tmp_power+Feat.pow(@feats[FEAT_COUNTER_RUSH])
      end
    end
    regist_event UseCounterRushFeatEvent

    # カウンターラッシュが使用終了
    def finish_counter_rush_feat()
      if @feats_enable[FEAT_COUNTER_RUSH]
        @feats_enable[FEAT_COUNTER_RUSH] = false
        use_feat_event(@feats[FEAT_COUNTER_RUSH])
      end
    end
    regist_event FinishCounterRushFeatEvent

    # ------------------
    # 劫火
    # ------------------
    # 劫火が使用されたかのチェック
    def check_disaster_flame_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DISASTER_FLAME)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DISASTER_FLAME)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDisasterFlameFeatEvent
    regist_event CheckAddDisasterFlameFeatEvent
    regist_event CheckRotateDisasterFlameFeatEvent

    # 劫火が使用される
    # 有効の場合必殺技IDを返す
    def use_disaster_flame_feat()
      if @feats_enable[FEAT_DISASTER_FLAME]
        @cc.owner.tmp_power+=3
      end
    end
    regist_event UseDisasterFlameFeatEvent

    # 劫火が使用終了
    def finish_disaster_flame_feat()
      if @feats_enable[FEAT_DISASTER_FLAME]
        use_feat_event(@feats[FEAT_DISASTER_FLAME])
        # 破棄候補のカード
        aca = []
        # カードをシャッフルする
        foe.cards.shuffle.each do |c|
           aca << c
        end
        # ダメージの分だけカードを捨てる
        Feat.pow(@feats[FEAT_DISASTER_FLAME]).times do |a|
          if aca[a]
            discard(foe, aca[a])
          end
        end
      end
      @feats_enable[FEAT_DISASTER_FLAME] = false
    end
    regist_event FinishDisasterFlameFeatEvent


    # ------------------
    # 煉獄
    # ------------------
    # 煉獄が使用されたかのチェック
    def check_hell_fire_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HELL_FIRE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HELL_FIRE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHellFireFeatEvent
    regist_event CheckAddHellFireFeatEvent
    regist_event CheckRotateHellFireFeatEvent

    # 煉獄が使用される
    # 有効の場合必殺技IDを返す
    def use_hell_fire_feat()
      if @feats_enable[FEAT_HELL_FIRE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_HELL_FIRE])
      end
    end
    regist_event UseHellFireFeatEvent

    # 精密射撃が使用終了
    def finish_hell_fire_feat()
      if @feats_enable[FEAT_HELL_FIRE]
        use_feat_event(@feats[FEAT_HELL_FIRE])
      end
    end
    regist_event FinishHellFireFeatEvent

    # 煉獄が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_hell_fire_feat_damage()
      if @feats_enable[FEAT_HELL_FIRE]
        # ダメージがマイナス
        if duel.tmp_damage > 0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if duel.second_entrant.hit_points[i] > 0
          end
          @hell_fire_feat_target_index = hps[rand(hps.size)]
          @hell_fire_feat_const_damage = Feat.pow(@feats[FEAT_HELL_FIRE]) == 15 ? ((duel.tmp_damage+1)/2).to_i : (duel.tmp_damage/2).to_i
        end
      end
    end
    regist_event UseHellFireFeatDamageEvent

    def use_hell_fire_feat_const_damage()
      if @feats_enable[FEAT_HELL_FIRE]
        @feats_enable[FEAT_HELL_FIRE] = false
        if @hell_fire_feat_const_damage && @hell_fire_feat_const_damage > 0
          hps = []
          foe.hit_points.each_index do |i|
            hps << i if duel.second_entrant.hit_points[i] > 0
          end

          attribute_party_damage(foe, hps, @hell_fire_feat_const_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        end
        @hell_fire_feat_const_damage = 0
        if Feat.pow(@feats[FEAT_HELL_FIRE]) == 14
          owner.cured_event()
          set_state(@cc.status[STATE_ATK_UP], 6, 2)
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        end
      end
    end
    regist_event UseHellFireFeatConstDamageEvent

    # ------------------
    # 眩彩
    # ------------------
    # 眩彩が使用されたかのチェック
    def check_blindness_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLINDNESS)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLINDNESS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlindnessFeatEvent
    regist_event CheckAddBlindnessFeatEvent
    regist_event CheckRotateBlindnessFeatEvent

    # 眩彩が使用される
    # 有効の場合必殺技IDを返す
    def use_blindness_feat1()
      if @feats_enable[FEAT_BLINDNESS]
        owner.tmp_power += Feat.pow(@feats[FEAT_BLINDNESS])
      end
    end
    regist_event UseBlindnessFeat1Event

    # 眩彩が使用される
    # 有効の場合必殺技IDを返す
    def use_blindness_feat2()
      if @feats_enable[FEAT_BLINDNESS]
        unless (foe.current_chara_card.get_enable_feats(PHASE_ATTACK).keys & THIRTEEN_EYES).size > 0
          hands_limit = Feat.pow(@feats[FEAT_BLINDNESS]) > 5 ? 2 : 0
          foe.tmp_power = foe.tmp_power/2 if foe.cards.count <= hands_limit
          foe.point_rewrite_event
        end
      end
    end
    regist_event UseBlindnessFeat2Event

    # 眩彩が使用終了
    def finish_blindness_feat()
      if @feats_enable[FEAT_BLINDNESS]
        @feats_enable[FEAT_BLINDNESS] = false
        use_feat_event(@feats[FEAT_BLINDNESS])
      end
    end
    regist_event FinishBlindnessFeatEvent


    # ------------------
    # 焼滅
    # ------------------

    # 焼滅が使用されたかのチェック
    def check_fire_disappear_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FIRE_DISAPPEAR)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FIRE_DISAPPEAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFireDisappearFeatEvent
    regist_event CheckAddFireDisappearFeatEvent
    regist_event CheckRotateFireDisappearFeatEvent

    # 焼滅が使用される
    # 有効の場合必殺技IDを返す
    def use_fire_disappear_feat()
    end
    regist_event UseFireDisappearFeatEvent

    # 焼滅が使用される
    def use_after_fire_disappear_feat()
      if @feats_enable[FEAT_FIRE_DISAPPEAR]
        use_feat_event(@feats[FEAT_FIRE_DISAPPEAR])
        aca = []
        dmg = 0
        # 手持ちのカードを複製してシャッフル
        aca = foe.cards.shuffle
        # カードを全て捨てる
        aca.count.times do |a|
          if aca[a]
            dmg+=discard(foe, aca[a])
          end
        end
        foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, dmg * Feat.pow(@feats[FEAT_FIRE_DISAPPEAR])))
      end
      @feats_enable[FEAT_FIRE_DISAPPEAR] = false
    end
    regist_event UseAfterFireDisappearFeatEvent

    # 焼滅が使用終了される
    def finish_fire_disappear_feat()
      if @feats_enable[FEAT_FIRE_DISAPPEAR]
      end
    end
    regist_event FinishFireDisappearFeatEvent

    # ------------------
    # ダークホール
    # ------------------
    # ダークホールが使用されたかのチェック
    def check_dark_hole_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DARK_HOLE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DARK_HOLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDarkHoleFeatEvent
    regist_event CheckAddDarkHoleFeatEvent
    regist_event CheckRotateDarkHoleFeatEvent

    # ダークホールが使用される
    # 有効の場合必殺技IDを返す
    def use_dark_hole_feat()
      if @feats_enable[FEAT_DARK_HOLE]
        owner.tmp_power = Feat.pow(@feats[FEAT_DARK_HOLE])
      end
    end
    regist_event UseDarkHoleFeatEvent

    # ダークホールが使用終了
    def finish_dark_hole_feat()
      if @feats_enable[FEAT_DARK_HOLE]
        @feats_enable[FEAT_DARK_HOLE] = false
        use_feat_event(@feats[FEAT_DARK_HOLE])
      end
    end
    regist_event FinishDarkHoleFeatEvent

    # ------------------
    # タンホイザーゲート
    # ------------------
    # タンホイザーゲートが使用されたかのチェック
    def check_tannhauser_gate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TANNHAUSER_GATE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_TANNHAUSER_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTannhauserGateFeatEvent
    regist_event CheckAddTannhauserGateFeatEvent
    regist_event CheckRotateTannhauserGateFeatEvent

    # タンホイザーゲートが使用される
    # 有効の場合必殺技IDを返す
    def use_tannhauser_gate_feat()
      if @feats_enable[FEAT_TANNHAUSER_GATE]
        use_feat_event(@feats[FEAT_TANNHAUSER_GATE])
        # 相手のカードを奪う
        Feat.pow(@feats[FEAT_TANNHAUSER_GATE]).times do
          if foe.cards.size > 0
            steal_deal(foe.cards[rand(foe.cards.size)])
          end
        end
        # 50%でダークホールを有効にする。Exで55%
        ref_val = Feat.pow(@feats[FEAT_TANNHAUSER_GATE]) > 2 ? 55 : 50
        r = rand(100)
        @feats_enable[FEAT_DARK_HOLE] = true if r < ref_val && get_feat_nos.include?(FEAT_DARK_HOLE)
      end
    end
    regist_event UseTannhauserGateFeatEvent

    # タンホイザーゲートが使用終了
    def finish_tannhauser_gate_feat()
      if @feats_enable[FEAT_TANNHAUSER_GATE]
        @feats_enable[FEAT_TANNHAUSER_GATE] = false
      end
    end
    regist_event FinishTannhauserGateFeatEvent

    # ------------------
    # シュバルトブリッツ
    # ------------------
    # シュバルトブリッツが使用されたかのチェック
    def check_schwar_blitz_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SCHWAR_BLITZ)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SCHWAR_BLITZ)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSchwarBlitzFeatEvent
    regist_event CheckAddSchwarBlitzFeatEvent
    regist_event CheckRotateSchwarBlitzFeatEvent

    # 必殺技の状態
    def use_schwar_blitz_feat()
      if @feats_enable[FEAT_SCHWAR_BLITZ]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SCHWAR_BLITZ])
      end
    end
    regist_event UseSchwarBlitzFeatEvent

    # シュバルトブリッツが使用される
    def finish_schwar_blitz_feat()
      if @feats_enable[FEAT_SCHWAR_BLITZ]
        use_feat_event(@feats[FEAT_SCHWAR_BLITZ])
      end
    end
    regist_event FinishSchwarBlitzFeatEvent

    # シュバルトブリッツが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_schwar_blitz_feat_damage()
      if @feats_enable[FEAT_SCHWAR_BLITZ]
        pow = 1
        turn = 5
        if owner.current_chara_card.charactor_id == 68
          pow = 2
          turn = 3
        end
        buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], pow, turn);
        on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        @feats_enable[FEAT_SCHWAR_BLITZ] = false
      end
    end
    regist_event UseSchwarBlitzFeatDamageEvent


    # ------------------
    # ハイランダー
    # ------------------
    # ハイランダーが使用されたかのチェック
    def check_hi_rounder_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HI_ROUNDER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HI_ROUNDER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHiRounderFeatEvent
    regist_event CheckAddHiRounderFeatEvent
    regist_event CheckRotateHiRounderFeatEvent

    # ハイランダーが使用される
    # 有効の場合必殺技IDを返す
    def use_hi_rounder_feat()
      if @feats_enable[FEAT_HI_ROUNDER]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_HI_ROUNDER])
      end
    end
    regist_event UseHiRounderFeatEvent

    # ハイランダーが使用終了
    def finish_hi_rounder_feat()
      if @feats_enable[FEAT_HI_ROUNDER]
        use_feat_event(@feats[FEAT_HI_ROUNDER])
      end
    end
    regist_event FinishHiRounderFeatEvent

    def use_hi_rounder_feat_const_damage()
      if @feats_enable[FEAT_HI_ROUNDER]
        @feats_enable[FEAT_HI_ROUNDER] = false
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << i if duel.second_entrant.hit_points[i] > 0
        end

        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_HI_ROUNDER]), ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
      end
    end
    regist_event UseHiRounderFeatConstDamageEvent


    # ------------------
    # ブラッドレッティング
    # ------------------
    # ブラッドレッティングが使用されたかのチェック
    def check_blood_retting_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_BLOOD_RETTING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLOOD_RETTING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBloodRettingFeatEvent
    regist_event CheckAddBloodRettingFeatEvent
    regist_event CheckRotateBloodRettingFeatEvent

    # ブラッドレッティングが使用される
    # 有効の場合必殺技IDを返す
    def use_blood_retting_feat()
    end
    regist_event UseBloodRettingFeatEvent

    # ブラッドレッティングが使用終了
    def finish_blood_retting_feat()
      if @feats_enable[FEAT_BLOOD_RETTING]
        use_feat_event(@feats[FEAT_BLOOD_RETTING])
      end
    end
    regist_event FinishBloodRettingFeatEvent

    # ブラッドレッティングが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_blood_retting_feat_damage()
      if @feats_enable[FEAT_BLOOD_RETTING]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0 && foe.tmp_power > 0
          @cc.owner.hit_points.each_index do |i|
            @cc.owner.party_healed_event(i, duel.tmp_damage) if i != @cc.owner.current_chara_card_no && @cc.owner.hit_points[i] > 0
          end
        end
        @feats_enable[FEAT_BLOOD_RETTING] = false
      end
    end
    regist_event UseBloodRettingFeatDamageEvent

    # ------------------
    # アキュパンクチャー
    # ------------------

    # アキュパンクチャーが使用されたかのチェック
    def check_acupuncture_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ACUPUNCTURE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ACUPUNCTURE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAcupunctureFeatEvent
    regist_event CheckAddAcupunctureFeatEvent
    regist_event CheckRotateAcupunctureFeatEvent

    # アキュパンクチャーを使用
    def finish_acupuncture_feat()
      if @feats_enable[FEAT_ACUPUNCTURE]
        use_feat_event(@feats[FEAT_ACUPUNCTURE])
        @feats_enable[FEAT_ACUPUNCTURE] = false
        buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, 3)
        on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        # 移動方向を制御
        if Feat.pow(@feats[FEAT_ACUPUNCTURE]) > 1
          if foe.direction == Entrant::DIRECTION_STAY || foe.direction == Entrant::DIRECTION_CHARA_CHANGE
            foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 2))
          end
        end
        foe.set_direction(Entrant::DIRECTION_PEND) if foe.get_direction == 0
      end
    end
    regist_event FinishAcupunctureFeatEvent

    # ------------------
    # ディセクション
    # ------------------
    # ディセクションが使用されたかのチェック
    def check_dissection_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_DISSECTION)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DISSECTION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDissectionFeatEvent
    regist_event CheckAddDissectionFeatEvent
    regist_event CheckRotateDissectionFeatEvent

    # ディセクションが使用される
    # 有効の場合必殺技IDを返す
    def use_dissection_feat()
      if @feats_enable[FEAT_DISSECTION]
      end
    end
    regist_event UseDissectionFeatEvent

    # ディセクションが使用(防御成功時)
    def use_dissection_feat_guard()
      if @feats_enable[FEAT_DISSECTION]
        use_feat_event(@feats[FEAT_DISSECTION])
        if Feat.pow(@feats[FEAT_DISSECTION]) > 1
          if duel.tmp_damage < 1
            p = Feat.pow(@feats[FEAT_DISSECTION]) == 2 ? 2 : 4
            @cc.owner.hit_points.each_index do |i|
              @cc.owner.party_healed_event(i, p) if i != @cc.owner.current_chara_card_no && @cc.owner.hit_points[i] > 0
            end
          end
        end
      end
    end
    regist_event UseDissectionFeatGuardEvent

    # ディセクションが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dissection_feat_damage()
      if @feats_enable[FEAT_DISSECTION]
        # HPがマイナスで1度だけ発動
        if duel.tmp_damage >= @cc.owner.hit_point
          owner.cards_max = owner.cards_max + 1
        end
        @feats_enable[FEAT_DISSECTION] = false
      end
    end
    regist_event UseDissectionFeatDamageEvent

    # ------------------
    # ユーサネイジア
    # ------------------
    # ユーサネイジアが使用されたかのチェック
    def check_euthanasia_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_EUTHANASIA)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_EUTHANASIA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEuthanasiaFeatEvent
    regist_event CheckAddEuthanasiaFeatEvent
    regist_event CheckRotateEuthanasiaFeatEvent

    # 必殺技の状態
    def use_euthanasia_feat()
      if @feats_enable[FEAT_EUTHANASIA]
        @cc.owner.tmp_power = 0
      end
    end
    regist_event UseEuthanasiaFeatEvent

    # ユーサネイジアが使用される
    def finish_euthanasia_feat()
      if @feats_enable[FEAT_EUTHANASIA]
        use_feat_event(@feats[FEAT_EUTHANASIA])
      end
    end
    regist_event FinishEuthanasiaFeatEvent

    # ユーサネイジアが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_euthanasia_feat_damage()
      if @feats_enable[FEAT_EUTHANASIA]
        p = Feat.pow(@feats[FEAT_EUTHANASIA]) == 3 ? 7 : 3
        buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], p, Feat.pow(@feats[FEAT_EUTHANASIA]));
        on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], p, Feat.pow(@feats[FEAT_EUTHANASIA]));
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, Feat.pow(@feats[FEAT_EUTHANASIA]));
        on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed
        @feats_enable[FEAT_EUTHANASIA] = false
      end
    end
    regist_event UseEuthanasiaFeatDamageEvent

    # ------------------
    # 憤怒の爪
    # ------------------

    # 憤怒の爪が使用されたかのチェック
    def check_anger_nail_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ANGER_NAIL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ANGER_NAIL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAngerNailFeatEvent
    regist_event CheckAddAngerNailFeatEvent
    regist_event CheckRotateAngerNailFeatEvent

    # 憤怒の爪を使用
    def finish_anger_nail_feat()
      if @feats_enable[FEAT_ANGER_NAIL]
        use_feat_event(@feats[FEAT_ANGER_NAIL])
        @feats_enable[FEAT_ANGER_NAIL] = false
        if @cc.status[STATE_STIGMATA][1] > 0
          @cc.status[STATE_STIGMATA][1] += Feat.pow(@feats[FEAT_ANGER_NAIL])
          @cc.status[STATE_STIGMATA][1] = 9 if @cc.status[STATE_STIGMATA][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
        else
          set_state(@cc.status[STATE_STIGMATA], 1,  Feat.pow(@feats[FEAT_ANGER_NAIL]));
          on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
        end
      end
    end
    regist_event FinishAngerNailFeatEvent

    # ------------------
    # 静謐な背中
    # ------------------

    # 静謐な背中が使用されたかのチェック
    def check_calm_back_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CALM_BACK)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_CALM_BACK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCalmBackFeatEvent
    regist_event CheckAddCalmBackFeatEvent
    regist_event CheckRotateCalmBackFeatEvent

    # 必殺技の状態
    def use_calm_back_feat()
      if @feats_enable[FEAT_CALM_BACK]
      end
    end
    regist_event UseCalmBackFeatEvent

    # 静謐な背中が使用される
    def finish_calm_back_feat()
      if @feats_enable[FEAT_CALM_BACK]
        use_feat_event(@feats[FEAT_CALM_BACK])
      end
    end
    regist_event FinishCalmBackFeatEvent

    # 静謐な背中が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_calm_back_feat_damage()
      if @feats_enable[FEAT_CALM_BACK]
        if @cc.status[STATE_STIGMATA][1] > 0
          damage_bonus = Feat.pow(@feats[FEAT_CALM_BACK]) > 1 ? Feat.pow(@feats[FEAT_CALM_BACK]) : 0
          duel.tmp_damage += @cc.status[STATE_STIGMATA][1] + damage_bonus
          @cc.status[STATE_STIGMATA][1] -= 1
          @cc.status[STATE_STIGMATA][1] = 0 if @cc.status[STATE_STIGMATA][1] < 0
          update_buff_event(true, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0])
        end
        @feats_enable[FEAT_CALM_BACK] = false
      end
    end
    regist_event UseCalmBackFeatDamageEvent


    # ------------------
    # 慈悲の青眼
    # ------------------

    # 慈悲の青眼が使用されたかのチェック
    def check_blue_eyes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLUE_EYES)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_BLUE_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlueEyesFeatEvent
    regist_event CheckAddBlueEyesFeatEvent
    regist_event CheckRotateBlueEyesFeatEvent

    # 必殺技の状態
    def use_blue_eyes_feat()
      if @feats_enable[FEAT_BLUE_EYES]
        @cc.owner.tmp_power = 0
      end
    end
    regist_event UseBlueEyesFeatEvent

    # 慈悲の青眼が使用される
    def finish_blue_eyes_feat()
      if @feats_enable[FEAT_BLUE_EYES]
        use_feat_event(@feats[FEAT_BLUE_EYES])
        stigma = Feat.pow(@feats[FEAT_BLUE_EYES])
        stigma -= 1 if stigma == 3 && owner.get_battle_table_point(ActionCard::SWD) < 8
        if @cc.status[STATE_STIGMATA][1] > 0
          @cc.status[STATE_STIGMATA][1] += stigma
          @cc.status[STATE_STIGMATA][1] = 9 if @cc.status[STATE_STIGMATA][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
        else
          set_state(@cc.status[STATE_STIGMATA], 1, stigma);
          on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
        end
        heal_pt = Feat.pow(@feats[FEAT_BLUE_EYES])
        heal_pt -= 1 if heal_pt == 3 && owner.get_battle_table_point(ActionCard::SWD) < 8
        owner.healed_event(heal_pt)
        @feats_enable[FEAT_BLUE_EYES] = false
      end
    end
    regist_event FinishBlueEyesFeatEvent

    # ------------------
    # 戦慄の狼牙
    # ------------------

    # 戦慄の狼牙が使用されたかのチェック
    def check_wolf_fang_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WOLF_FANG)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_WOLF_FANG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWolfFangFeatEvent
    regist_event CheckAddWolfFangFeatEvent
    regist_event CheckRotateWolfFangFeatEvent

    # 必殺技の状態
    def use_wolf_fang_feat()
      if @feats_enable[FEAT_WOLF_FANG]
      end
    end
    regist_event UseWolfFangFeatEvent

    # 戦慄の狼牙が使用される
    def finish_wolf_fang_feat()
      if @feats_enable[FEAT_WOLF_FANG]
        use_feat_event(@feats[FEAT_WOLF_FANG])
        stigma_pow = @cc.status[STATE_STIGMATA][1]
        stigma_pow += Feat.pow(@feats[FEAT_WOLF_FANG]) if Feat.pow(@feats[FEAT_WOLF_FANG]) > 1 && stigma_pow > 0
        dmg = attribute_damage(ATTRIBUTE_CONSTANT,foe,stigma_pow)
        owner.healed_event(stigma_pow)
        foe.damaged_event(dmg)
        owner.cured_event()
        foe.cured_event()
        @feats_enable[FEAT_WOLF_FANG] = false
      end
    end
    regist_event FinishWolfFangFeatEvent

    # ------------------
    # 葉隠れ
    # ------------------
    # 葉隠れが使用されたかのチェック
    def check_hagakure_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_HAGAKURE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HAGAKURE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHagakureFeatEvent
    regist_event CheckAddHagakureFeatEvent
    regist_event CheckRotateHagakureFeatEvent

    # 葉隠れが使用される
    # 有効の場合必殺技IDを返す
    def use_hagakure_feat()
    end
    regist_event UseHagakureFeatEvent

    # 葉隠れが使用終了
    def finish_hagakure_feat()
      if @feats_enable[FEAT_HAGAKURE]
        use_feat_event(@feats[FEAT_HAGAKURE])
      end
    end
    regist_event FinishHagakureFeatEvent

    # 葉隠れが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_hagakure_feat_damage()
      if @feats_enable[FEAT_HAGAKURE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          # 相手のカードを回転する
          if Feat.pow(@feats[FEAT_HAGAKURE]) > 0
            duel.tmp_damage = ((duel.tmp_damage+1)/2).to_i
          else
            duel.tmp_damage = (duel.tmp_damage/2).to_i
          end
        end
        @feats_enable[FEAT_HAGAKURE] = false
      end
    end
    regist_event UseHagakureFeatDamageEvent

    # ------------------
    # 烈風
    # ------------------

    # 烈風が使用されたかのチェック
    def check_reppu_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_REPPU)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_REPPU)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveReppuFeatEvent
    regist_event CheckAddReppuFeatEvent
    regist_event CheckRotateReppuFeatEvent

    # 烈風が使用される
    # 有効の場合必殺技IDを返す
    def use_reppu_feat()
      if @feats_enable[FEAT_REPPU]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_REPPU])
      end
    end
    regist_event UseReppuFeatEvent

    # 烈風を使用
    def finish_reppu_feat()
      if @feats_enable[FEAT_REPPU]
        # 移動方向を制御
        foe.set_direction(Entrant::DIRECTION_CHARA_CHANGE)
      end
    end
    regist_event FinishReppuFeatEvent

    # 烈風を使用
    def finish_effect_reppu_feat()
      if @feats_enable[FEAT_REPPU]
        use_feat_event(@feats[FEAT_REPPU])

        ret = []
        foe.hit_points.each_index do |i|
          if foe.hit_points[i] > 0 && foe.current_chara_card_no != i
            ret << i
          end
        end
        foe.chara_change_index = ret[rand(ret.size)]

      end
    end
    regist_event FinishEffectReppuFeatEvent

    # 烈風を使用
    def finish_change_reppu_feat()
      if @feats_enable[FEAT_REPPU]
      end
    end
    regist_event FinishFoeChangeReppuFeatEvent
    regist_event FinishDeadChangeReppuFeatEvent

    # 烈風を使用
    def finish_turn_reppu_feat()
      if @feats_enable[FEAT_REPPU]
        @feats_enable[FEAT_REPPU] = false
      end
    end
    regist_event FinishTurnReppuFeatEvent

    # ------------------
    # 燕飛
    # ------------------

    # 燕飛が使用されたかのチェック
    def check_enpi_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ENPI)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_ENPI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEnpiFeatEvent
    regist_event CheckAddEnpiFeatEvent
    regist_event CheckRotateEnpiFeatEvent

    # 必殺技の状態
    def use_enpi_feat()
      if @feats_enable[FEAT_ENPI]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ENPI])
      end
    end
    regist_event UseEnpiFeatEvent

    # 燕飛が使用される
    def finish_enpi_feat()
      if @feats_enable[FEAT_ENPI]
        use_feat_event(@feats[FEAT_ENPI])
      end
    end
    regist_event FinishEnpiFeatEvent

    # 燕飛が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_enpi_feat_damage()
      if @feats_enable[FEAT_ENPI]
        if (foe.current_chara_card.hp == foe.hit_point && Feat.pow(@feats[FEAT_ENPI]) < 7) ||
          (foe.current_chara_card.hp - 3 <= foe.hit_point && Feat.pow(@feats[FEAT_ENPI]) >= 7)
          # １回目のダイスを振ってダメージを保存
          rec_damage = duel.tmp_damage
          rec_dice_heads_atk = duel.tmp_dice_heads_atk
          rec_dice_heads_def = duel.tmp_dice_heads_def
          # ダメージ計算をもう１度実行
          @cc.owner.dice_roll_event(duel.battle_result)
          # ダメージをプラス
          duel.tmp_damage += rec_damage
          duel.tmp_dice_heads_atk += rec_dice_heads_atk
          duel.tmp_dice_heads_def += rec_dice_heads_def
        end
        @feats_enable[FEAT_ENPI] = false
      end
    end
    regist_event UseEnpiFeatDamageEvent

    # ------------------
    # 三日月
    # ------------------

    # 三日月が使用されたかのチェック
    def check_mikazuki_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MIKAZUKI)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_MIKAZUKI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMikazukiFeatEvent
    regist_event CheckAddMikazukiFeatEvent
    regist_event CheckRotateMikazukiFeatEvent

    # 必殺技の状態
    def use_mikazuki_feat()
      if @feats_enable[FEAT_MIKAZUKI]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MIKAZUKI])
      end
    end
    regist_event UseMikazukiFeatEvent

    EX_MIKAZUKI_STATE_LIST=
      [
       STATE_ATK_UP,
       STATE_DEF_UP,
       STATE_MOVE_UP,
       STATE_UNDEAD,
       STATE_CHAOS,
       STATE_STIGMATA,
       STATE_STICK
      ]

    # 三日月が使用される
    def finish_mikazuki_feat()
      if @feats_enable[FEAT_MIKAZUKI]
        use_feat_event(@feats[FEAT_MIKAZUKI])
        fs = foe.current_chara_card.status
        # 全ての状態をコピーする
        fs.each_index do |i|
          if Feat.pow(@feats[FEAT_MIKAZUKI]) == 10
            unless EX_MIKAZUKI_STATE_LIST.include?(i)
              next
            end
          end
          if fs[i][1] > 0 && i != STATE_CONTROL
            @cc.status[i][0] = fs[i][0]
            @cc.status[i][1] = fs[i][1]
            on_buff_event(true, owner.current_chara_card_no, i, @cc.status[i][0], @cc.status[i][1])
          end
          if Feat.pow(@feats[FEAT_MIKAZUKI]) == 10
            foe.current_chara_card.status[i][1] = 0
            off_buff_event(false, foe.current_chara_card_no, i, foe.current_chara_card.status[i][0])
          end
        end
        # 状態初期化
        if Feat.pow(@feats[FEAT_MIKAZUKI]) != 10
          foe.cured_event()
        end
        @feats_enable[FEAT_MIKAZUKI] = false
      end
    end
    regist_event FinishMikazukiFeatEvent


    # ------------------
    # カサブランカの風
    # ------------------

    # カサブランカの風が使用されたかのチェック
    def check_casablanca_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CASABLANCA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CASABLANCA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveCasablancaFeatEvent
    regist_event CheckAddCasablancaFeatEvent
    regist_event CheckRotateCasablancaFeatEvent

    # カサブランカの風を使用
    def finish_casablanca_feat()
      if @feats_enable[FEAT_CASABLANCA]
        use_feat_event(@feats[FEAT_CASABLANCA])
        @feats_enable[FEAT_CASABLANCA] = false
        mov_up = rand(Feat.pow(@feats[FEAT_CASABLANCA]))+1
        up_turn = Feat.pow(@feats[FEAT_CASABLANCA]) > 1 ? 4 : 3
        if @cc.status[STATE_MOVE_UP][1] > 0
          set_state(@cc.status[STATE_MOVE_UP], (@cc.status[STATE_MOVE_UP][0]+mov_up), up_turn);
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        else
          set_state(@cc.status[STATE_MOVE_UP], mov_up, up_turn);
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        end
      end
    end
    regist_event FinishCasablancaFeatEvent

    # ------------------
    # ローデシアの海
    # ------------------
    # ローデシアの海が使用されたかのチェック
    def check_rhodesia_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_RHODESIA)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RHODESIA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRhodesiaFeatEvent
    regist_event CheckAddRhodesiaFeatEvent
    regist_event CheckRotateRhodesiaFeatEvent

    # ローデシアの海が使用される
    # 有効の場合必殺技IDを返す
    def use_rhodesia_feat()
      if @feats_enable[FEAT_RHODESIA]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_RHODESIA])
      end
    end
    regist_event UseRhodesiaFeatEvent

    # ローデシアの海が使用終了
    def finish_rhodesia_feat()
      if @feats_enable[FEAT_RHODESIA]
        use_feat_event(@feats[FEAT_RHODESIA])
      end
    end
    regist_event FinishRhodesiaFeatEvent

    # ローデシアの海が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_rhodesia_feat_damage()
      if @feats_enable[FEAT_RHODESIA]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          r = rand(100)
          ref = Feat.pow(@feats[FEAT_RHODESIA]) > 8 ? 43 : 33
          if r < ref
            duel.tmp_damage = 0
          end
        end
        @feats_enable[FEAT_RHODESIA] = false
      end
    end
    regist_event UseRhodesiaFeatDamageEvent

    # ------------------
    # マドリプールの雑踏
    # ------------------

    # マドリプールの雑踏が使用されたかのチェック
    def check_madripool_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MADRIPOOL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MADRIPOOL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMadripoolFeatEvent
    regist_event CheckAddMadripoolFeatEvent
    regist_event CheckRotateMadripoolFeatEvent

    # マドリプールの雑踏が使用される
    # 有効の場合必殺技IDを返す
    def use_madripool_feat()
    end
    regist_event UseMadripoolFeatEvent

    # マドリプールの雑踏が使用終了される
    def finish_madripool_feat()
      if @feats_enable[FEAT_MADRIPOOL]
        @feats_enable[FEAT_MADRIPOOL] = false
        use_feat_event(@feats[FEAT_MADRIPOOL])
        hps = get_hps(foe)
        if Feat.pow(@feats[FEAT_MADRIPOOL]) == 99
          attribute_party_damage(foe, hps, 1, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM, 2)
          attribute_party_damage(foe, get_hps(foe), 1+(@cc.status[STATE_MOVE_UP][0]/3), ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        else
          attribute_party_damage(foe, hps, 1, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM, Feat.pow(@feats[FEAT_MADRIPOOL])) if hps.count > 0
        end
      end
    end
    regist_event FinishMadripoolFeatEvent


    # ------------------
    # エイジャの曙光
    # ------------------

    # エイジャの曙光が使用されたかのチェック
    def check_asia_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ASIA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ASIA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAsiaFeatEvent
    regist_event CheckAddAsiaFeatEvent
    regist_event CheckRotateAsiaFeatEvent

    # エイジャの曙光が使用される
    # 有効の場合必殺技IDを返す
    def use_asia_feat()
    end
    regist_event UseAsiaFeatEvent

    # エイジャの曙光が使用終了される
    def finish_asia_feat()
      if @feats_enable[FEAT_ASIA]
        @feats_enable[FEAT_ASIA] = false
        use_feat_event(@feats[FEAT_ASIA])
        hps = []
        foe.hit_points.each_with_index do |v,i|
          hps << i if v > 0
        end

        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_ASIA]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL) if hps.size > 0

      end
    end
    regist_event FinishAsiaFeatEvent

    # ------------------
    # デモニック
    # ------------------
    # デモニックが使用されたかのチェック
    def check_demonic_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEMONIC)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DEMONIC)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDemonicFeatEvent
    regist_event CheckAddDemonicFeatEvent
    regist_event CheckRotateDemonicFeatEvent

    # 必殺技の状態
    def use_demonic_feat()
      if @feats_enable[FEAT_DEMONIC]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DEMONIC])
      end
    end
    regist_event UseDemonicFeatEvent

    # デモニックが使用される
    def finish_demonic_feat()
      if @feats_enable[FEAT_DEMONIC]
        use_feat_event(@feats[FEAT_DEMONIC])
      end
    end
    regist_event FinishDemonicFeatEvent

    # デモニックが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_demonic_feat_damage()
      if @feats_enable[FEAT_DEMONIC]
        foe.cured_event()
        @feats_enable[FEAT_DEMONIC] = false
      end
    end
    regist_event UseDemonicFeatDamageEvent

    # ------------------
    # 残像剣
    # ------------------

    # 残像剣が使用されたかのチェック
    def check_shadow_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHADOW_SWORD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SHADOW_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShadowSwordFeatEvent
    regist_event CheckAddShadowSwordFeatEvent
    regist_event CheckRotateShadowSwordFeatEvent

    # 残像剣が使用される
    # 有効の場合必殺技IDを返す
    def use_shadow_sword_feat()
      if @feats_enable[FEAT_SHADOW_SWORD]
        if Feat.pow(@feats[FEAT_SHADOW_SWORD]) == 1
          @cc.owner.tmp_power = 0
        end
      end
    end
    regist_event UseShadowSwordFeatEvent

    # 残像剣が使用終了される
    def finish_shadow_sword_feat()
      if @feats_enable[FEAT_SHADOW_SWORD]
        @feats_enable[FEAT_SHADOW_SWORD] = false
        use_feat_event(@feats[FEAT_SHADOW_SWORD])
        foe.damaged_event(attribute_damage(ATTRIBUTE_HALF,foe))
        if Feat.pow(@feats[FEAT_SHADOW_SWORD]) == 3
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(Feat.pow(@feats[FEAT_SHADOW_SWORD])).each{ |c| @cc.owner.dealed_event(c)})
          foe.special_dealed_event(duel.deck.draw_cards_event(Feat.pow(@feats[FEAT_SHADOW_SWORD])).each{ |c| foe.dealed_event(c)})
        end
      end
    end
    regist_event FinishShadowSwordFeatEvent

    # ------------------
    # パーフェクトデッド
    # ------------------
    # パーフェクトデッドが使用されたかのチェック
    def check_perfect_dead_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_PERFECT_DEAD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PERFECT_DEAD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePerfectDeadFeatEvent
    regist_event CheckAddPerfectDeadFeatEvent
    regist_event CheckRotatePerfectDeadFeatEvent

    # パーフェクトデッドが使用される
    # 有効の場合必殺技IDを返す
    def use_perfect_dead_feat()
    end
    regist_event UsePerfectDeadFeatEvent

    # パーフェクトデッドが使用終了
    def finish_perfect_dead_feat()
      if @feats_enable[FEAT_PERFECT_DEAD]
        use_feat_event(@feats[FEAT_PERFECT_DEAD])
      end
    end
    regist_event FinishPerfectDeadFeatEvent

    # パーフェクトデッドが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_perfect_dead_feat_damage()
      if @feats_enable[FEAT_PERFECT_DEAD]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if owner.hit_point <= duel.tmp_damage
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION, foe, duel.tmp_damage))
        end
        @feats_enable[FEAT_PERFECT_DEAD] = false
      end
    end
    regist_event UsePerfectDeadFeatDamageEvent

    # ------------------
    # 破壊の歯車
    # ------------------
    # 破壊の歯車が使用されたかのチェック
    def check_destruct_gear_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DESTRUCT_GEAR)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DESTRUCT_GEAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDestructGearFeatEvent
    regist_event CheckAddDestructGearFeatEvent
    regist_event CheckRotateDestructGearFeatEvent

    # 破壊の歯車が使用される
    # 有効の場合必殺技IDを返す
    def use_destruct_gear_feat()
    end
    regist_event UseDestructGearFeatEvent

    # 精密射撃が使用終了
    def finish_destruct_gear_feat()
      if @feats_enable[FEAT_DESTRUCT_GEAR]
        use_feat_event(@feats[FEAT_DESTRUCT_GEAR])
      end
    end
    regist_event FinishDestructGearFeatEvent

    # 破壊の歯車が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_destruct_gear_feat_damage()
      if @feats_enable[FEAT_DESTRUCT_GEAR]
        if duel.tmp_damage > 0
          duel.tmp_damage = duel.tmp_damage*Feat.pow(@feats[FEAT_DESTRUCT_GEAR])
        end
        owner.damaged_event(owner.hit_point - owner.hit_point/2,IS_NOT_HOSTILE_DAMAGE)
        @feats_enable[FEAT_DESTRUCT_GEAR] = false
      end
    end
    regist_event UseDestructGearFeatDamageEvent

    # ------------------
    # パワーシフト
    # ------------------
    # パワーシフトが使用されたかのチェック
    def check_power_shift_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_POWER_SHIFT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_POWER_SHIFT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePowerShiftFeatEvent
    regist_event CheckAddPowerShiftFeatEvent
    regist_event CheckRotatePowerShiftFeatEvent

    # パワーシフトが使用される
    # 有効の場合必殺技IDを返す
    def use_power_shift_feat()
    end
    regist_event UsePowerShiftFeatEvent

    # パワーシフトが使用終了
    def finish_power_shift_feat()
      if @feats_enable[FEAT_POWER_SHIFT]
        use_feat_event(@feats[FEAT_POWER_SHIFT])
      end
    end
    regist_event FinishPowerShiftFeatEvent

    # パワーシフトが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_power_shift_feat_damage()
      if @feats_enable[FEAT_POWER_SHIFT]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
          end
          if hps.size > 0
            attribute_party_damage(owner, hps, duel.tmp_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
          else
            duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,owner,duel.tmp_damage))
          end
          duel.tmp_damage = 0
        end
        @feats_enable[FEAT_POWER_SHIFT] = false
      end
    end
    regist_event UsePowerShiftFeatDamageEvent

    # ------------------
    # キルショット
    # ------------------
    # キルショットが使用されたかのチェック
    def check_kill_shot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KILL_SHOT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KILL_SHOT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKillShotFeatEvent
    regist_event CheckAddKillShotFeatEvent
    regist_event CheckRotateKillShotFeatEvent

    # キルショットが使用される
    # 有効の場合必殺技IDを返す
    def use_kill_shot_feat()
      if @feats_enable[FEAT_KILL_SHOT]
        @cc.owner.tmp_power = foe.tmp_power
      end
    end
    regist_event UseKillShotFeatEvent

    # 精密射撃が使用終了
    def finish_kill_shot_feat()
      if @feats_enable[FEAT_KILL_SHOT]
        use_feat_event(@feats[FEAT_KILL_SHOT])
      end
    end
    regist_event FinishKillShotFeatEvent

    # キルショットが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_kill_shot_feat_damage()
      if @feats_enable[FEAT_KILL_SHOT]
        if duel.tmp_damage > 0
          duel.tmp_damage = duel.tmp_damage*Feat.pow(@feats[FEAT_KILL_SHOT])
        end
        @feats_enable[FEAT_KILL_SHOT] = false
      end
    end
    regist_event UseKillShotFeatDamageEvent

    # ------------------
    # ディフレクト
    # ------------------
    # ディフレクトが使用されたかのチェック
    def check_defrect_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_DEFRECT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DEFRECT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDefrectFeatEvent
    regist_event CheckAddDefrectFeatEvent
    regist_event CheckRotateDefrectFeatEvent

    # ディフレクトが使用される
    # 有効の場合必殺技IDを返す
    def use_defrect_feat()
    end
    regist_event UseDefrectFeatEvent

    # ディフレクトが使用終了
    def finish_defrect_feat()
      if @feats_enable[FEAT_DEFRECT]
        use_feat_event(@feats[FEAT_DEFRECT])
      end
    end
    regist_event FinishDefrectFeatEvent

    # ディフレクトが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_defrect_feat_damage()
      if @feats_enable[FEAT_DEFRECT]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          # 相手のカードを回転する
          if duel.tmp_damage > Feat.pow(@feats[FEAT_DEFRECT])
            duel.tmp_damage = Feat.pow(@feats[FEAT_DEFRECT])
          end
        end
        @feats_enable[FEAT_DEFRECT] = false
      end
    end
    regist_event UseDefrectFeatDamageEvent

    # ------------------
    # 炎の供物
    # ------------------

    # 炎の供物が使用されたかのチェック
    def check_flame_offering_feat
      @cc.owner.reset_feat_on_cards(FEAT_FLAME_OFFERING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FLAME_OFFERING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFlameOfferingFeatEvent
    regist_event CheckAddFlameOfferingFeatEvent
    regist_event CheckRotateFlameOfferingFeatEvent

    # 炎の供物が使用される
    def use_flame_offering_feat()
      if @feats_enable[FEAT_FLAME_OFFERING]
        use_feat_event(@feats[FEAT_FLAME_OFFERING])
        # 相手のカードを奪う
        if owner.cards.size > 0
          ct = 0
          tmp_cards = owner.cards.dup
          tmp_cards.each do |c|
            if c.u_type == ActionCard::ARW || c.b_type == ActionCard::ARW
              ct+=discard(owner, c)
            end
          end
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(ct).each{ |c| @cc.owner.dealed_event(c)}) if ct > 0
        end
        @feats_enable[FEAT_FLAME_OFFERING] = false
      end
    end
    regist_event UseFlameOfferingFeatEvent

    # ------------------
    # 黄金の手
    # ------------------
    # 黄金の手が使用されたかのチェック
    def check_drain_hand_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DRAIN_HAND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DRAIN_HAND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDrainHandFeatEvent
    regist_event CheckAddDrainHandFeatEvent
    regist_event CheckRotateDrainHandFeatEvent

    # 黄金の手が使用される
    # 有効の場合必殺技IDを返す
    def use_drain_hand_feat()
      if @feats_enable[FEAT_DRAIN_HAND]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DRAIN_HAND])
      end
    end
    regist_event UseDrainHandFeatEvent

    # 黄金の手が使用終了
    def finish_drain_hand_feat()
      if @feats_enable[FEAT_DRAIN_HAND]
        use_feat_event(@feats[FEAT_DRAIN_HAND])
      end
    end
    regist_event FinishDrainHandFeatEvent

    # 黄金の手が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_drain_hand_feat_damage()
      if @feats_enable[FEAT_DRAIN_HAND]
        # ダメージがマイナス
        if duel.tmp_damage > 0
          @cc.owner.healed_event(duel.tmp_damage)
        end
        @feats_enable[FEAT_DRAIN_HAND] = false
      end
    end
    regist_event UseDrainHandFeatDamageEvent

    # ------------------
    # 焔の監獄
    # ------------------
    # 焔の監獄が使用されたかのチェック
    def check_fire_prizon_feat
      @cc.owner.reset_feat_on_cards(FEAT_FIRE_PRIZON)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FIRE_PRIZON)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFirePrizonFeatEvent
    regist_event CheckAddFirePrizonFeatEvent
    regist_event CheckRotateFirePrizonFeatEvent

    # 焔の監獄が使用される
    def use_fire_prizon_feat()
      if @feats_enable[FEAT_FIRE_PRIZON]
        use_feat_event(@feats[FEAT_FIRE_PRIZON])
        # 手札を捨ててドロー
        if foe.cards.size > Feat.pow(@feats[FEAT_FIRE_PRIZON])
          ct = 0
          tmp_cards = foe.cards.shuffle
          tmp_cards.count.times do |i|
            ct+=discard(foe, tmp_cards[i])
            break unless foe.cards.size > Feat.pow(@feats[FEAT_FIRE_PRIZON])
          end
          @cc.owner.special_dealed_event(duel.deck.draw_cards_event(ct).each{ |c| @cc.owner.dealed_event(c)})
        end
        @feats_enable[FEAT_FIRE_PRIZON] = false
      end
    end
    regist_event UseFirePrizonFeatEvent

    # ------------------
    # 時間停止
    # ------------------

    # 時間停止が使用されたかのチェック
    def check_time_stop_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_STOP)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TIME_STOP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveTimeStopFeatEvent
    regist_event CheckAddTimeStopFeatEvent
    regist_event CheckRotateTimeStopFeatEvent

    # 時間停止を使用
    def finish_time_stop_feat()
      if @feats_enable[FEAT_TIME_STOP]
        use_feat_event(@feats[FEAT_TIME_STOP])
        @feats_enable[FEAT_TIME_STOP] = false
        if !instant_kill_guard?(foe)
          buffed = set_state(foe.current_chara_card.status[STATE_STOP], 1, Feat.pow(@feats[FEAT_TIME_STOP]));
          on_buff_event(false, foe.current_chara_card_no, STATE_STOP, foe.current_chara_card.status[STATE_STOP][0], foe.current_chara_card.status[STATE_STOP][1]) if buffed
        end
      end
    end
    regist_event FinishTimeStopFeatEvent

    # ------------------
    # 即死防御
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_dead_guard_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_DEAD_GUARD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DEAD_GUARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeadGuardFeatEvent
    regist_event CheckAddDeadGuardFeatEvent
    regist_event CheckRotateDeadGuardFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_dead_guard_feat()
      if @feats_enable[FEAT_DEAD_GUARD]
      end
    end
    regist_event UseDeadGuardFeatEvent

    # 必殺技が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dead_guard_feat_damage()
      if @feats_enable[FEAT_DEAD_GUARD]
        if duel.tmp_damage >= @cc.owner.hit_point + Feat.pow(@feats[FEAT_DEAD_GUARD])
          duel.tmp_damage = 0
        end
        @feats_enable[FEAT_DEAD_GUARD] = false
      end
    end
    regist_event UseDeadGuardFeatDamageEvent


    # 必殺技が使用終了
    def finish_dead_guard_feat()
      if @feats_enable[FEAT_DEAD_GUARD]
        use_feat_event(@feats[FEAT_DEAD_GUARD])
      end
    end
    regist_event FinishDeadGuardFeatEvent

    # ------------------
    # 奇数即死
    # ------------------
    # 奇数即死が使用されたかのチェック
    def check_dead_blue_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_DEAD_BLUE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DEAD_BLUE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeadBlueFeatEvent
    regist_event CheckAddDeadBlueFeatEvent
    regist_event CheckRotateDeadBlueFeatEvent

    # 奇数即死が使用される
    # 有効の場合必殺技IDを返す
    def use_dead_blue_feat()
    end
    regist_event UseDeadBlueFeatEvent

    # 奇数即死が使用終了
    def finish_dead_blue_feat()
      if @feats_enable[FEAT_DEAD_BLUE]
        use_feat_event(@feats[FEAT_DEAD_BLUE])
      end
    end
    regist_event FinishDeadBlueFeatEvent

    # 奇数即死が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dead_blue_feat_damage()
      if @feats_enable[FEAT_DEAD_BLUE]
        # レベルが奇数なら即死
        if foe.current_chara_card.level % 2 == 1
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_DEATH,foe))
        end
        @feats_enable[FEAT_DEAD_BLUE] = false
      end
    end
    regist_event UseDeadBlueFeatDamageEvent


    # ------------------
    # 善悪の彼岸
    # ------------------
    # 善悪の彼岸が使用されたかのチェック
    def check_evil_guard_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_EVIL_GUARD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_EVIL_GUARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEvilGuardFeatEvent
    regist_event CheckAddEvilGuardFeatEvent
    regist_event CheckRotateEvilGuardFeatEvent

    # 善悪の彼岸が使用される
    # 有効の場合必殺技IDを返す
    def use_evil_guard_feat()
      if @feats_enable[FEAT_EVIL_GUARD]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_EVIL_GUARD])
      end
    end
    regist_event UseEvilGuardFeatEvent


    # 善悪の彼岸が使用終了
    def finish_evil_guard_feat()
      if @feats_enable[FEAT_EVIL_GUARD]
        use_feat_event(@feats[FEAT_EVIL_GUARD])
      end
    end
    regist_event FinishEvilGuardFeatEvent

    # 善悪の彼岸が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_evil_guard_feat_damage()
      if @feats_enable[FEAT_EVIL_GUARD]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage < 0 && foe.tmp_power > 0
          hps = []
          duel.first_entrant.hit_points.each_index do |i|
            hps << i if duel.first_entrant.hit_points[i] > 0
          end
          attribute_party_damage(foe, hps, 2, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        end
        @feats_enable[FEAT_EVIL_GUARD] = false
      end
    end
    regist_event UseEvilGuardFeatDamageEvent


    # ------------------
    # 道連れ
    # ------------------
    # 道連れが使用されたかのチェック
    def check_abyss_eyes_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_ABYSS_EYES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ABYSS_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAbyssEyesFeatEvent
    regist_event CheckAddAbyssEyesFeatEvent
    regist_event CheckRotateAbyssEyesFeatEvent

    # 道連れが使用される
    # 有効の場合必殺技IDを返す
    def use_abyss_eyes_feat()
      if @feats_enable[FEAT_ABYSS_EYES]
      end
    end
    regist_event UseAbyssEyesFeatEvent


    # 道連れが使用終了
    def finish_abyss_eyes_feat()
      if @feats_enable[FEAT_ABYSS_EYES]
        use_feat_event(@feats[FEAT_ABYSS_EYES])
      end
    end
    regist_event FinishAbyssEyesFeatEvent

    # 道連れが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_abyss_eyes_feat_damage()
      if @feats_enable[FEAT_ABYSS_EYES]
        # HPがマイナスで1度だけ発動
        if duel.tmp_damage >= @cc.owner.hit_point
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_DYING,foe,1))
        end
        @feats_enable[FEAT_ABYSS_EYES] = false
      end
    end
    regist_event UseAbyssEyesFeatDamageEvent

    # ------------------
    # 偶数即死
    # ------------------

    # 偶数即死が使用されたかのチェック
    def check_dead_red_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEAD_RED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DEAD_RED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeadRedFeatEvent
    regist_event CheckAddDeadRedFeatEvent
    regist_event CheckRotateDeadRedFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_dead_red_feat()
    end
    regist_event UseDeadRedFeatEvent


    # 偶数即死が使用終了される
    def finish_dead_red_feat()
      if @feats_enable[FEAT_DEAD_RED]
        @feats_enable[FEAT_DEAD_RED] = false
        use_feat_event(@feats[FEAT_DEAD_RED])
        if foe.current_chara_card.level % 2 == 0
          duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_DEATH,foe))
        end
      end
    end
    regist_event FinishDeadRedFeatEvent


    # ------------------
    # 幽冥の夜
    # ------------------
    # 幽冥の夜が使用されたかのチェック
    def check_night_ghost_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_NIGHT_GHOST)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_NIGHT_GHOST)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveNightGhostFeatEvent
    regist_event CheckAddNightGhostFeatEvent
    regist_event CheckRotateNightGhostFeatEvent

    # 幽冥の夜が使用される
    # 有効の場合必殺技IDを返す
    def use_night_ghost_feat()
      if @feats_enable[FEAT_NIGHT_GHOST]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_NIGHT_GHOST])
      end
    end
    regist_event UseNightGhostFeatEvent

    # 精密射撃が使用終了
    def finish_night_ghost_feat()
      if @feats_enable[FEAT_NIGHT_GHOST]
        use_feat_event(@feats[FEAT_NIGHT_GHOST])
      end
    end
    regist_event FinishNightGhostFeatEvent

    # 幽冥の夜が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_night_ghost_feat_damage()
      if @feats_enable[FEAT_NIGHT_GHOST]
        # ダメージがプラスなら
        if duel.tmp_damage > 0
          owner.cards_max = owner.cards_max + 1
        end
        @feats_enable[FEAT_NIGHT_GHOST] = false
      end
    end
    regist_event UseNightGhostFeatDamageEvent

    # ------------------
    # 人形の軍勢
    # ------------------
    # 人形の軍勢が使用されたかのチェック
    def check_avatar_war_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_AVATAR_WAR)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_AVATAR_WAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAvatarWarFeatEvent
    regist_event CheckAddAvatarWarFeatEvent
    regist_event CheckRotateAvatarWarFeatEvent

    # 必殺技の状態
    def use_avatar_war_feat()
    end
    regist_event UseAvatarWarFeatEvent

    # 人形の軍勢が使用される
    def finish_avatar_war_feat()
      if @feats_enable[FEAT_AVATAR_WAR]
        use_feat_event(@feats[FEAT_AVATAR_WAR])
      end
    end
    regist_event FinishAvatarWarFeatEvent

    # 人形の軍勢が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_avatar_war_feat_damage()
      if @feats_enable[FEAT_AVATAR_WAR]
        buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, Feat.pow(@feats[FEAT_AVATAR_WAR]));
        on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, Feat.pow(@feats[FEAT_AVATAR_WAR]));
        on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed
        buffed = set_state(foe.current_chara_card.status[STATE_STONE], 1, Feat.pow(@feats[FEAT_AVATAR_WAR]));
        on_buff_event(false, foe.current_chara_card_no, STATE_STONE, foe.current_chara_card.status[STATE_STONE][0], foe.current_chara_card.status[STATE_STONE][1]) if buffed
        @feats_enable[FEAT_AVATAR_WAR] = false
      end
    end
    regist_event UseAvatarWarFeatDamageEvent

    # ------------------
    # 混沌の渦
    # ------------------
    # 混沌の渦が使用されたかのチェック
    def check_confuse_pool_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CONFUSE_POOL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CONFUSE_POOL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveConfusePoolFeatEvent
    regist_event CheckAddConfusePoolFeatEvent
    regist_event CheckRotateConfusePoolFeatEvent

    # 混沌の渦が使用される
    # 有効の場合必殺技IDを返す
    def use_confuse_pool_feat()
    end
    regist_event UseConfusePoolFeatEvent

    # 混沌の渦が使用終了
    def finish_confuse_pool_feat()
      if @feats_enable[FEAT_CONFUSE_POOL]
        use_feat_event(@feats[FEAT_CONFUSE_POOL])
      end
    end
    regist_event FinishConfusePoolFeatEvent

    # 混沌の渦が使用される
    # 有効の場合必殺技IDを返す
    def use_confuse_pool_feat_damage()
      if @feats_enable[FEAT_CONFUSE_POOL]
        aca = owner.cards.shuffle
        dmg = 0
        aca.count.times do |i|
          if aca[i]
            dmg += discard(owner, aca[i])
          end
        end
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg))
        @feats_enable[FEAT_CONFUSE_POOL] = false
      end
    end
    regist_event UseConfusePoolFeatDamageEvent

    # ------------------
    # プロミネンス
    # ------------------
    # プロミネンスが使用されたかのチェック
    def check_prominence_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PROMINENCE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PROMINENCE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveProminenceFeatEvent
    regist_event CheckAddProminenceFeatEvent
    regist_event CheckRotateProminenceFeatEvent

    # プロミネンスが使用される
    def use_prominence_feat()
      if @feats_enable[FEAT_PROMINENCE]
        use_feat_event(@feats[FEAT_PROMINENCE])
        @feats_enable[FEAT_PROMINENCE] = false
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_PROMINENCE])))
        owner.healed_event(Feat.pow(@feats[FEAT_PROMINENCE])) if owner.hit_point > 0
      end
    end
    regist_event UseProminenceFeatEvent

    # プロミネンスを使用
    def finish_prominence_feat()
      if @feats_enable[FEAT_PROMINENCE]
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(Feat.pow(@feats[FEAT_PROMINENCE])).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishProminenceFeatEvent


    # ------------------
    # バトルアックス
    # ------------------

    # バトルアックスが使用されたかのチェック
    def check_battle_axe_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BATTLE_AXE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_BATTLE_AXE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBattleAxeFeatEvent
    regist_event CheckAddBattleAxeFeatEvent
    regist_event CheckRotateBattleAxeFeatEvent

    # 必殺技の状態
    def use_battle_axe_feat()
      if @feats_enable[FEAT_BATTLE_AXE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_BATTLE_AXE])
      end
    end
    regist_event UseBattleAxeFeatEvent

    # バトルアックスが使用される
    def finish_battle_axe_feat()
      if @feats_enable[FEAT_BATTLE_AXE]
        use_feat_event(@feats[FEAT_BATTLE_AXE])
      end
    end
    regist_event FinishBattleAxeFeatEvent

    # バトルアックスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_battle_axe_feat_damage()
      if @feats_enable[FEAT_BATTLE_AXE]
        if @cc.status[STATE_PARALYSIS][1] > 0
          duel.tmp_damage = duel.tmp_damage * 2
        end
        @feats_enable[FEAT_BATTLE_AXE] = false
      end
    end
    regist_event UseBattleAxeFeatDamageEvent

    # ------------------
    # MOAB
    # ------------------

    # MOABが使用されたかのチェック
    def check_moab_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MOAB)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MOAB)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMoabFeatEvent
    regist_event CheckAddMoabFeatEvent
    regist_event CheckRotateMoabFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_moab_feat()
    end
    regist_event UseMoabFeatEvent

    # MOABが使用終了される
    def finish_moab_feat()
      if @feats_enable[FEAT_MOAB]
        @feats_enable[FEAT_MOAB] = false
        use_feat_event(@feats[FEAT_MOAB])
        # 敵デッキ全体にダメージ
        hps = []
        foe.hit_points.each_with_index do |v,i|
          hps << i if v > 0
        end
        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_MOAB]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        duel.first_entrant.damaged_event(Feat.pow(@feats[FEAT_MOAB]),IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishMoabFeatEvent

    # ------------------
    # オーバーヒート
    # ------------------

    # オーバーヒートが使用されたかのチェック
    def check_over_heat_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_OVER_HEAT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_OVER_HEAT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveOverHeatFeatEvent
    regist_event CheckAddOverHeatFeatEvent
    regist_event CheckRotateOverHeatFeatEvent

    # オーバーヒートを使用
    def finish_over_heat_feat()
      if @feats_enable[FEAT_OVER_HEAT]
        use_feat_event(@feats[FEAT_OVER_HEAT])
        @feats_enable[FEAT_OVER_HEAT] = false
        para_turn = Feat.pow(@feats[FEAT_OVER_HEAT]) == 8 ? 3 : 9
        set_state(@cc.status[STATE_PARALYSIS], 1, para_turn)
        on_buff_event(true, owner.current_chara_card_no, STATE_PARALYSIS, @cc.status[STATE_PARALYSIS][0], @cc.status[STATE_PARALYSIS][1])
        set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_OVER_HEAT]), 9)
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
      end
    end
    regist_event FinishOverHeatFeatEvent


    # ------------------
    # 蒼き薔薇
    # ------------------
    # 蒼き薔薇が使用されたかのチェック
    def check_blue_rose_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_BLUE_ROSE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLUE_ROSE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlueRoseFeatEvent
    regist_event CheckAddBlueRoseFeatEvent
    regist_event CheckRotateBlueRoseFeatEvent

    # 蒼き薔薇が使用される
    # 有効の場合必殺技IDを返す
    def use_blue_rose_feat()
      def_max = 99
      if @feats_enable[FEAT_BLUE_ROSE]
        tmp = foe.hit_point + Feat.pow(@feats[FEAT_BLUE_ROSE])
        @cc.owner.tmp_power += tmp > def_max ? def_max : tmp
      end
    end
    regist_event UseBlueRoseFeatEvent


    # 蒼き薔薇が使用終了
    def finish_blue_rose_feat()
      if @feats_enable[FEAT_BLUE_ROSE]
        use_feat_event(@feats[FEAT_BLUE_ROSE])
      end
    end
    regist_event FinishBlueRoseFeatEvent

    # 蒼き薔薇が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_blue_rose_feat_damage()
      if @feats_enable[FEAT_BLUE_ROSE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          d = attribute_damage(ATTRIBUTE_HALF,duel.first_entrant)
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_SPECIAL_COUNTER, duel.first_entrant, d))
        end
        @feats_enable[FEAT_BLUE_ROSE] = false
      end
    end
    regist_event UseBlueRoseFeatDamageEvent

    # ------------------
    # 白鴉
    # ------------------

    # 白鴉が使用されたかのチェック
    def check_white_crow_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WHITE_CROW)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_WHITE_CROW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveWhiteCrowFeatEvent
    regist_event CheckAddWhiteCrowFeatEvent
    regist_event CheckRotateWhiteCrowFeatEvent

    # 白鴉を使用
    def finish_white_crow_feat()
      if @feats_enable[FEAT_WHITE_CROW]
        @feats_enable[FEAT_WHITE_CROW] = false
        use_feat_event(@feats[FEAT_WHITE_CROW])
        point = 0
        @cc.status.each_with_index do |c,i|
          point+=1 if c[1] > 0 && i != STATE_CONTROL
        end
        foe.current_chara_card.status.each_with_index do |c,i|
          point+=1 if c[1] > 0 && i != STATE_CONTROL
        end
        # 状態初期化
        owner.cured_event()
        foe.cured_event()
        @cc.owner.healed_event(point*Feat.pow(@feats[FEAT_WHITE_CROW]))
      end
    end
    regist_event FinishWhiteCrowFeatEvent

    # ------------------
    # 深紅の月
    # ------------------
    # 深紅の月が使用されたかのチェック
    def check_red_moon_feat
      f_no = @feats[FEAT_RED_MOON] ? FEAT_RED_MOON : FEAT_EX_RED_MOON
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(f_no)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(f_no)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRedMoonFeatEvent
    regist_event CheckAddRedMoonFeatEvent
    regist_event CheckRotateRedMoonFeatEvent

    # 深紅の月 攻撃力変更 このメソッドは一度だけ攻撃力を計算する
    def use_red_moon_feat()
      if @feats_enable[FEAT_RED_MOON] || @feats_enable[FEAT_EX_RED_MOON]
        unless @lock
          f_id = @feats[FEAT_RED_MOON] ? @feats[FEAT_RED_MOON] : @feats[FEAT_EX_RED_MOON]
          @cc.owner.tmp_power += foe.tmp_power + Feat.pow(f_id)
          @lock = true
          @locked_value = foe.tmp_power + Feat.pow(f_id)
        else
          @cc.owner.tmp_power += @locked_value
        end
      end
    end
    regist_event UseRedMoonFeatEvent

    # 深紅の月 攻撃力変更 双方のcalc_resolve終了後、一度だけ攻撃力を再計算し変更する
    def use_red_moon_feat_dice_attr()
      if @feats_enable[FEAT_RED_MOON] || @feats_enable[FEAT_EX_RED_MOON]
        f_id = @feats[FEAT_RED_MOON] ? @feats[FEAT_RED_MOON] : @feats[FEAT_EX_RED_MOON]
        @cc.owner.tmp_power = owner.battle_point_calc(owner.attack_type, owner.attack_point) + foe.tmp_power + Feat.pow(f_id)
        @lock = false
        owner.point_rewrite_event
      end
    end
    regist_event UseRedMoonFeatDiceAttrEvent
    regist_event UseExRedMoonFeatDiceAttrEvent

    # 深紅の月が使用終了
    def finish_red_moon_feat()
      if @feats_enable[FEAT_RED_MOON] || @feats_enable[FEAT_EX_RED_MOON]
        f_id = @feats[FEAT_RED_MOON] ? @feats[FEAT_RED_MOON] : @feats[FEAT_EX_RED_MOON]
        use_feat_event(f_id)
      end
    end
    regist_event FinishRedMoonFeatEvent

    # 深紅の月が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_red_moon_feat_damage()
      if @feats_enable[FEAT_RED_MOON] || @feats_enable[FEAT_EX_RED_MOON]
        # ダメージが1以上
        if duel.tmp_damage > 1
          @cc.owner.healed_event((duel.tmp_damage/2).to_i)
        end
        f_no = @feats[FEAT_RED_MOON] ? FEAT_RED_MOON : FEAT_EX_RED_MOON
        @feats_enable[f_no] = false
      end
    end
    regist_event UseRedMoonFeatDamageEvent

    # ------------------
    # 黒い太陽
    # ------------------
    # 黒い太陽が使用されたかのチェック
    def check_black_sun_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLACK_SUN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BLACK_SUN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlackSunFeatEvent
    regist_event CheckAddBlackSunFeatEvent
    regist_event CheckRotateBlackSunFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_black_sun_feat()
    end
    regist_event UseBlackSunFeatEvent

    # 黒い太陽が使用終了される
    def finish_black_sun_feat()
      if @feats_enable[FEAT_BLACK_SUN]
        @feats_enable[FEAT_BLACK_SUN] = false
        use_feat_event(@feats[FEAT_BLACK_SUN])
        if Feat.pow(@feats[FEAT_BLACK_SUN]) == 4
          guard_hp = 8
          if owner.hit_point > guard_hp
            sp_dmg = @cc.owner.get_battle_table_point(ActionCard::SPC) + 4
            dmg_max = owner.hit_point - guard_hp
            dmg = dmg_max < sp_dmg ? dmg_max : sp_dmg
            duel.first_entrant.damaged_event(dmg,IS_NOT_HOSTILE_DAMAGE)
          end
        else
          if @cc.owner.get_battle_table_point(ActionCard::SPC) >= owner.hit_point
            duel.first_entrant.damaged_event(owner.hit_point-1,IS_NOT_HOSTILE_DAMAGE)
          else
            duel.first_entrant.damaged_event(@cc.owner.get_battle_table_point(ActionCard::SPC),IS_NOT_HOSTILE_DAMAGE)
          end
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@cc.owner.get_battle_table_point(ActionCard::SPC)+Feat.pow(@feats[FEAT_BLACK_SUN])))
      end
    end
    regist_event FinishBlackSunFeatEvent


    # ------------------
    # ジラソーレ
    # ------------------
    # ジラソーレが使用されたかのチェック
    def check_girasole_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GIRASOLE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GIRASOLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGirasoleFeatEvent
    regist_event CheckAddGirasoleFeatEvent
    regist_event CheckRotateGirasoleFeatEvent

    # ジラソーレが使用される
    # 有効の場合必殺技IDを返す
    def use_girasole_feat()
      if @feats_enable[FEAT_GIRASOLE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_GIRASOLE])
      end
    end
    regist_event UseGirasoleFeatEvent

    # 精密射撃が使用終了
    def finish_girasole_feat()
      if @feats_enable[FEAT_GIRASOLE]
        use_feat_event(@feats[FEAT_GIRASOLE])
      end
    end
    regist_event FinishGirasoleFeatEvent

    # ジラソーレが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_girasole_feat_damage()
      if @feats_enable[FEAT_GIRASOLE]
        # ダメージがマイナス
        if duel.tmp_damage > 0
          @girasole_damage = duel.tmp_damage
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
          end
          duel.tmp_damage = 0
        end
      end
    end
    regist_event UseGirasoleFeatDamageEvent

    def use_girasole_feat_const_damage()
      if @feats_enable[FEAT_GIRASOLE]
        # ダメージがマイナス
        @passives_enable[PASSIVE_ROCK_CRUSHER] = false if @passives_enable[PASSIVE_ROCK_CRUSHER]
        @passives_enable[PASSIVE_DAMAGE_MULTIPLIER] = false if @passives_enable[PASSIVE_DAMAGE_MULTIPLIER]
        if @girasole_damage && @girasole_damage > 0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
          end
          if hps.size > 0
            attribute_party_damage(foe, hps, @girasole_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
          else
            duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@girasole_damage))
          end
        end
        @feats_enable[FEAT_GIRASOLE] = false
        @girasole_damage = 0
      end
    end
    regist_event UseGirasoleFeatConstDamageEvent

    # ------------------
    # ビオレッタ
    # ------------------

    # ビオレッタが使用されたかのチェック
    def check_violetta_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_VIOLETTA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_VIOLETTA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveViolettaFeatEvent
    regist_event CheckAddViolettaFeatEvent
    regist_event CheckRotateViolettaFeatEvent

    # ビオレッタを使用
    def finish_violetta_feat()
      if @feats_enable[FEAT_VIOLETTA]
        use_feat_event(@feats[FEAT_VIOLETTA])
        @feats_enable[FEAT_VIOLETTA] = false
        # かかる効果一覧
        buffs = [[STATE_POISON, 1, 2], [STATE_PARALYSIS, 1, 2], [STATE_ATK_DOWN, 5, 2], [STATE_DEF_DOWN, 5, 2],
                 [STATE_SEAL, 1, 1], [STATE_STONE, 1, 2], [STATE_BIND, 1, 2], [STATE_DEAD_COUNT, 1, 5]]
        buffs.pop if Feat.pow(@feats[FEAT_VIOLETTA]) > 2 && foe.current_chara_card.status[STATE_DEAD_COUNT][1] > 0
        sbuffs = buffs.shuffle
        Feat.pow(@feats[FEAT_VIOLETTA]).times do |i|
          st = sbuffs.pop
          buffed = set_state(foe.current_chara_card.status[st[0]], st[1], st[2])
          on_buff_event(false, foe.current_chara_card_no, st[0], foe.current_chara_card.status[st[0]][0], foe.current_chara_card.status[st[0]][1]) if buffed
        end
      end
    end
    regist_event FinishViolettaFeatEvent

    # ------------------
    # ディジタリス
    # ------------------

    # ディジタリスが使用されたかのチェック
    def check_digitale_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DIGITALE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DIGITALE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDigitaleFeatEvent
    regist_event CheckAddDigitaleFeatEvent
    regist_event CheckRotateDigitaleFeatEvent

    # 必殺技の状態
    def use_digitale_feat()
      if @feats_enable[FEAT_DIGITALE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DIGITALE]) == 9 ? 7 : Feat.pow(@feats[FEAT_DIGITALE])
      end
    end
    regist_event UseDigitaleFeatEvent

    # ディジタリスが使用される
    def finish_digitale_feat()
      if @feats_enable[FEAT_DIGITALE]
        use_feat_event(@feats[FEAT_DIGITALE])
      end
    end
    regist_event FinishDigitaleFeatEvent

    # ディジタリスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_digitale_feat_damage()
      if @feats_enable[FEAT_DIGITALE]
        foe.current_chara_card.status.each_index do |i|
          next if i == STATE_TARGET

          if foe.current_chara_card.status[i][1] > 0
            add_num = Feat.pow(@feats[FEAT_DIGITALE]) == 9 ? 3 : 2
            if i == STATE_BLESS && (add_num + foe.current_chara_card.status[i][1]) > BLESS_MAX
              add_num = (BLESS_MAX - foe.current_chara_card.status[i][1])
            end
            buffed = set_state(foe.current_chara_card.status[i], foe.current_chara_card.status[i][0], foe.current_chara_card.status[i][1]+add_num)
            if foe.current_chara_card.status_update
              update_buff_event(false, i, foe.current_chara_card.status[i][0], foe.current_chara_card_no, add_num) if buffed
            else
              on_buff_event(false, foe.current_chara_card_no, i, foe.current_chara_card.status[i][0], foe.current_chara_card.status[i][1]) if buffed
            end
          end
        end
        @feats_enable[FEAT_DIGITALE] = false
      end
    end
    regist_event UseDigitaleFeatDamageEvent

    # ------------------
    # ロスマリーノ
    # ------------------

    # ロスマリーノが使用されたかのチェック
    def check_rosmarino_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ROSMARINO)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ROSMARINO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRosmarinoFeatEvent
    regist_event CheckAddRosmarinoFeatEvent
    regist_event CheckRotateRosmarinoFeatEvent

    # ロスマリーノが使用される
    # 有効の場合必殺技IDを返す
    def use_rosmarino_feat()
    end
    regist_event UseRosmarinoFeatEvent


    # ロスマリーノが使用終了される
    def finish_rosmarino_feat()
      if @feats_enable[FEAT_ROSMARINO]
        @feats_enable[FEAT_ROSMARINO] = false
        use_feat_event(@feats[FEAT_ROSMARINO])
        dmg = (duel.first_entrant.hit_point-duel.second_entrant.hit_point).abs
        if duel.first_entrant.hit_point > duel.second_entrant.hit_point
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_HP_EXCHANGE,duel.first_entrant,dmg),IS_NOT_HOSTILE_DAMAGE)
          duel.second_entrant.healed_event(dmg)
        else
          duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_HP_EXCHANGE,duel.second_entrant,dmg))
          duel.first_entrant.healed_event(dmg)
        end
      end
    end
    regist_event FinishRosmarinoFeatEvent


    # ------------------
    # 八葉
    # ------------------

    # 八葉が使用されたかのチェック
    def check_hachiyou_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HACHIYOU)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HACHIYOU)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveHachiyouFeatEvent
    regist_event CheckAddHachiyouFeatEvent
    regist_event CheckRotateHachiyouFeatEvent

    # 八葉を使用
    def finish_hachiyou_feat()
      if @feats_enable[FEAT_HACHIYOU]
        use_feat_event(@feats[FEAT_HACHIYOU])
        @feats_enable[FEAT_HACHIYOU] = false
        mhp = 0
        owner.hit_points_max.each { |i| mhp += i }

        mhp_criteria = []
        if Feat.pow(@feats[FEAT_HACHIYOU]) != 4
          mhp_criteria = [20, 27, 34, 40]
        else
          mhp_criteria = [1, 20, 27, 34, 40]
        end

        updated_state = []
        if mhp >= mhp_criteria[0]
          set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_HACHIYOU]), Feat.pow(@feats[FEAT_HACHIYOU]))
          updated_state << STATE_ATK_UP
        end
        if mhp >= mhp_criteria[1]
          set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_HACHIYOU]), Feat.pow(@feats[FEAT_HACHIYOU]))
          updated_state << STATE_DEF_UP
        end
        if mhp >= mhp_criteria[2]
          set_state(@cc.status[STATE_REGENE], 1, Feat.pow(@feats[FEAT_HACHIYOU]))
          updated_state << STATE_REGENE
        end
        if mhp >= mhp_criteria[3]
          set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_HACHIYOU])+2, Feat.pow(@feats[FEAT_HACHIYOU]))
          set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_HACHIYOU])+1, Feat.pow(@feats[FEAT_HACHIYOU]))
        end
        if Feat.pow(@feats[FEAT_HACHIYOU]) == 4 && mhp >= mhp_criteria[4]
          set_state(@cc.status[STATE_MOVE_UP], 1,  Feat.pow(@feats[FEAT_HACHIYOU]))
          updated_state << STATE_MOVE_UP
        end

        updated_state.sort.each do |s|
          on_buff_event(true, owner.current_chara_card_no, s, @cc.status[s][0], @cc.status[s][1])
        end
      end
    end
    regist_event FinishHachiyouFeatEvent


    # ------------------
    # 鉄石の構え
    # ------------------
    # 鉄石の構えが使用されたかのチェック
    def check_stone_care_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_STONE_CARE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_STONE_CARE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveStoneCareFeatEvent
    regist_event CheckAddStoneCareFeatEvent
    regist_event CheckRotateStoneCareFeatEvent

    # 鉄石の構えが使用
    def use_stone_care_feat()
      if @feats_enable[FEAT_STONE_CARE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_STONE_CARE])
      end
    end
    regist_event UseStoneCareFeatEvent

    # 鉄石の構えが使用終了される
    def finish_stone_care_feat()
      if @feats_enable[FEAT_STONE_CARE]
        @feats_enable[FEAT_STONE_CARE] = false
        use_feat_event(@feats[FEAT_STONE_CARE])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << [i, duel.second_entrant.hit_points[i]] if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
        end
        duel.second_entrant.party_healed_event(hps.sort{ |a,b| a[1] <=> b[1] }[0][0], 3) if hps.size > 0
      end
    end
    regist_event FinishStoneCareFeatEvent

    # ------------------
    # 絶塵剣
    # ------------------
    # 絶塵剣が使用されたかのチェック
    def check_dust_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DUST_SWORD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DUST_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDustSwordFeatEvent
    regist_event CheckAddDustSwordFeatEvent
    regist_event CheckRotateDustSwordFeatEvent

    # 絶塵剣が使用される
    # 有効の場合必殺技IDを返す
    def use_dust_sword_feat()
      if @feats_enable[FEAT_DUST_SWORD]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DUST_SWORD])
      end
    end
    regist_event UseDustSwordFeatEvent

    # 絶塵剣が使用終了
    def finish_dust_sword_feat()
      if @feats_enable[FEAT_DUST_SWORD]
        use_feat_event(@feats[FEAT_DUST_SWORD])
      end
    end
    regist_event FinishDustSwordFeatEvent

    # 絶塵剣が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dust_sword_feat_damage()
      if @feats_enable[FEAT_DUST_SWORD]
        # ダメージが1以上
        if duel.tmp_damage > 1
          duel.first_entrant.hit_points.each_index do |i|
            @cc.owner.party_healed_event(i, (duel.tmp_damage/2).to_i) if i != @cc.owner.current_chara_card_no && @cc.owner.hit_points[i] > 0
          end
        end
        @feats_enable[FEAT_DUST_SWORD] = false
      end
    end
    regist_event UseDustSwordFeatDamageEvent

    # ------------------
    # 夢幻
    # ------------------
    # 夢幻が使用されたかのチェック
    def check_illusion_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ILLUSION)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ILLUSION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIllusionFeatEvent
    regist_event CheckAddIllusionFeatEvent
    regist_event CheckRotateIllusionFeatEvent

    # 夢幻が使用される
    # 有効の場合必殺技IDを返す
    def use_illusion_feat()
      if @feats_enable[FEAT_ILLUSION]
        mhp = 0
        owner.hit_points_max.each { |i| mhp += i }
        @cc.owner.tmp_power += mhp + Feat.pow(@feats[FEAT_ILLUSION])
      end
    end
    regist_event UseIllusionFeatEvent

    # 夢幻が使用終了
    def finish_illusion_feat()
      if @feats_enable[FEAT_ILLUSION]
        use_feat_event(@feats[FEAT_ILLUSION])
      end
    end
    regist_event FinishIllusionFeatEvent

    # 夢幻が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_illusion_feat_damage()
      if @feats_enable[FEAT_ILLUSION]
        hps = []
        duel.first_entrant.hit_points.each_index do |i|
          hps << i if duel.first_entrant.hit_points[i] > 0
        end
        attribute_party_damage(owner, hps, 99, ATTRIBUTE_DEATH, TARGET_TYPE_HP_MIN, 1, IS_HOSTILE_DAMAGE) if hps.size > 0
        @feats_enable[FEAT_ILLUSION] = false
      end
    end
    regist_event UseIllusionFeatDamageEvent


    # ------------------
    # 絶望の叫び
    # ------------------

    # 絶望の叫びが使用されたかのチェック
    def check_despair_shout_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DESPAIR_SHOUT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DESPAIR_SHOUT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDespairShoutFeatEvent
    regist_event CheckAddDespairShoutFeatEvent
    regist_event CheckRotateDespairShoutFeatEvent

    # 絶望の叫びを使用
    def finish_despair_shout_feat()
      if @feats_enable[FEAT_DESPAIR_SHOUT]
        use_feat_event(@feats[FEAT_DESPAIR_SHOUT])
        @feats_enable[FEAT_DESPAIR_SHOUT] = false
        if foe.current_chara_card.status[STATE_ATK_DOWN][1] > 0
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], (foe.current_chara_card.status[STATE_ATK_DOWN][0]+Feat.pow(@feats[FEAT_DESPAIR_SHOUT])), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        else
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_DESPAIR_SHOUT]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        end
        if foe.current_chara_card.status[STATE_DEF_DOWN][1] > 0
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], (foe.current_chara_card.status[STATE_DEF_DOWN][0]+Feat.pow(@feats[FEAT_DESPAIR_SHOUT])), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        else
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_DESPAIR_SHOUT]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        end
      end
    end
    regist_event FinishDespairShoutFeatEvent

    # ------------------
    # 暗黒神の歌
    # ------------------
    # 暗黒神の歌が使用されたかのチェック
    def check_darkness_song_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DARKNESS_SONG)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DARKNESS_SONG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDarknessSongFeatEvent
    regist_event CheckAddDarknessSongFeatEvent
    regist_event CheckRotateDarknessSongFeatEvent

    # 暗黒神の歌が使用される
    # 有効の場合必殺技IDを返す
    def use_darkness_song_feat()
      if @feats_enable[FEAT_DARKNESS_SONG]
        foe.tmp_power = (foe.tmp_power/Feat.pow(@feats[FEAT_DARKNESS_SONG])).to_i
      end
    end
    regist_event UseDarknessSongFeatEvent

    # 暗黒神の歌が使用終了
    def finish_darkness_song_feat()
      if @feats_enable[FEAT_DARKNESS_SONG]
        @feats_enable[FEAT_DARKNESS_SONG] = false
        use_feat_event(@feats[FEAT_DARKNESS_SONG])
      end
    end
    regist_event FinishDarknessSongFeatEvent

    # ------------------
    # 守護霊の魂
    # ------------------

    # 守護霊の魂が使用されたかのチェック
    def check_guard_spirit_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GUARD_SPIRIT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GUARD_SPIRIT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveGuardSpiritFeatEvent
    regist_event CheckAddGuardSpiritFeatEvent
    regist_event CheckRotateGuardSpiritFeatEvent

    # 守護霊の魂を使用
    def finish_guard_spirit_feat()
      if @feats_enable[FEAT_GUARD_SPIRIT]
        use_feat_event(@feats[FEAT_GUARD_SPIRIT])
        @feats_enable[FEAT_GUARD_SPIRIT] = false
        if @cc.status[STATE_DEF_UP][1] > 0
          set_state(@cc.status[STATE_DEF_UP], (@cc.status[STATE_DEF_UP][0]+Feat.pow(@feats[FEAT_GUARD_SPIRIT])), 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        else
          set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_GUARD_SPIRIT]), 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        end
      end
    end
    regist_event FinishGuardSpiritFeatEvent


    # ------------------
    # 殺戮器官
    # ------------------

    # 殺戮器官が使用されたかのチェック
    def check_slaughter_organ_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SLAUGHTER_ORGAN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SLAUGHTER_ORGAN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveSlaughterOrganFeatEvent
    regist_event CheckAddSlaughterOrganFeatEvent
    regist_event CheckRotateSlaughterOrganFeatEvent

    # 殺戮器官の効果が発揮される
    def use_slaughter_organ_feat()
      if @feats_enable[FEAT_SLAUGHTER_ORGAN]
        @cc.owner.tmp_power += @cc.owner.tmp_power
      end
    end
    regist_event UseSlaughterOrganFeatEvent

    # 殺戮器官を使用
    def finish_slaughter_organ_feat()
      if @feats_enable[FEAT_SLAUGHTER_ORGAN]
        use_feat_event(@feats[FEAT_SLAUGHTER_ORGAN])
        on_transform_sequence(true)
      end
    end
    regist_event FinishSlaughterOrganFeatEvent

    # 殺戮器官が終了
    def finish_turn_slaughter_organ_feat()
      if @feats_enable[FEAT_SLAUGHTER_ORGAN]
        @feats_enable[FEAT_SLAUGHTER_ORGAN] = false
        off_transform_sequence(true)
      end
    end
    regist_event FinishTurnSlaughterOrganFeatEvent

    # ------------------
    # 愚者の手
    # ------------------
    # 愚者の手が使用されたかのチェック
    def check_fools_hand_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOOLS_HAND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FOOLS_HAND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFoolsHandFeatEvent
    regist_event CheckAddFoolsHandFeatEvent
    regist_event CheckRotateFoolsHandFeatEvent

    # 愚者の手が使用される
    # 有効の場合必殺技IDを返す
    def use_fools_hand_feat()
      if @feats_enable[FEAT_FOOLS_HAND]
        @cc.owner.tmp_power += foe.hit_points.select{ |h| h > 0 }.count * Feat.pow(@feats[FEAT_FOOLS_HAND])
      end
    end
    regist_event UseFoolsHandFeatEvent

    # 愚者の手が使用終了
    def finish_fools_hand_feat()
      if @feats_enable[FEAT_FOOLS_HAND]
        use_feat_event(@feats[FEAT_FOOLS_HAND])
      end
    end
    regist_event FinishFoolsHandFeatEvent

    # 愚者の手が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_fools_hand_feat_damage()
      if @feats_enable[FEAT_FOOLS_HAND]
        if @feats_enable[FEAT_SLAUGHTER_ORGAN]
          owner.damaged_event(foe.hit_points.select{ |h| h > 0 }.count, IS_NOT_HOSTILE_DAMAGE)
        end
        @feats_enable[FEAT_FOOLS_HAND] = false
      end
    end
    regist_event UseFoolsHandFeatDamageEvent

    # ------------------
    # 時の種子
    # ------------------

    # 時の種子が使用されたかのチェック
    def check_time_seed_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_SEED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TIME_SEED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTimeSeedFeatEvent
    regist_event CheckAddTimeSeedFeatEvent
    regist_event CheckRotateTimeSeedFeatEvent

    # 時の種子が使用
    def use_time_seed_feat()
    end
    regist_event UseTimeSeedFeatEvent

    # 時の種子が使用終了される
    def finish_time_seed_feat()
      if @feats_enable[FEAT_TIME_SEED]
        @feats_enable[FEAT_TIME_SEED] = false
        use_feat_event(@feats[FEAT_TIME_SEED])
        h = (duel.turn * 0.5).to_i
        h = Feat.pow(@feats[FEAT_TIME_SEED]) if h > Feat.pow(@feats[FEAT_TIME_SEED])
        h = (h * 0.5).to_i if @feats_enable[FEAT_SLAUGHTER_ORGAN]
        duel.second_entrant.healed_event(h) if owner.hit_point > 0
      end
    end
    regist_event FinishTimeSeedFeatEvent


    # ------------------
    # 運命の鉄門
    # ------------------
    # 運命の鉄門が使用されたかのチェック
    def check_irongate_of_fate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_IRONGATE_OF_FATE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_IRONGATE_OF_FATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIrongateOfFateFeatEvent
    regist_event CheckAddIrongateOfFateFeatEvent
    regist_event CheckRotateIrongateOfFateFeatEvent

    # 運命の鉄門が使用される
    # 有効の場合必殺技IDを返す
    def use_irongate_of_fate_feat()
      if @feats_enable[FEAT_IRONGATE_OF_FATE]
      end
    end
    regist_event UseIrongateOfFateFeatEvent

    # 運命の鉄門が使用終了
    def finish_irongate_of_fate_feat()
      if @feats_enable[FEAT_IRONGATE_OF_FATE]
        use_feat_event(@feats[FEAT_IRONGATE_OF_FATE])
      end
    end
    regist_event FinishIrongateOfFateFeatEvent

    # 運命の鉄門が使用される
    # 有効の場合必殺技IDを返す
    def use_irongate_of_fate_feat_damage()
      if @feats_enable[FEAT_IRONGATE_OF_FATE]
        hps_f = []
        hps_s = []
        owner.hit_points.each_index do |i|
          hps_f << [i, owner.hit_points[i]] if owner.current_chara_card_no != i && owner.hit_points[i] > 0
        end
        foe.hit_points.each_index do |i|
          hps_s << [i, foe.hit_points[i]] if foe.hit_points[i] > 0
        end
        # 同率HPの場合、自パーティを優先して倒す
        if hps_f.size > 0 && hps_f.sort{ |a,b| a[1] <=> b[1] }[0][1] <= hps_s.sort{ |a,b| a[1] <=> b[1] }[0][1]
          attribute_party_damage(owner, hps_f.sort{  |a,b| a[1] <=> b[1] }[0][0], 99 ,ATTRIBUTE_DEATH, TARGET_TYPE_SINGLE, 1, IS_NOT_HOSTILE_DAMAGE) if hps_f.size > 0
        else
          foe.party_damaged_event(hps_s.sort{ |a,b| a[1] <=> b[1] }[0][0], attribute_damage(ATTRIBUTE_DEATH, foe)) if hps_s.size > 0
        end
        # 殺戮状態で回復
        owner.healed_event(Feat.pow(@feats[FEAT_IRONGATE_OF_FATE])) if (@feats_enable[FEAT_SLAUGHTER_ORGAN] && owner.hit_point > 0)
        @feats_enable[FEAT_IRONGATE_OF_FATE] = false
      end
    end
    regist_event UseIrongateOfFateFeatDamageEvent

    # ------------------
    # ザ・ギャザラー
    # ------------------

    # ザ・ギャザラーが使用されたかのチェック
    def check_gatherer_feat
      @cc.owner.reset_feat_on_cards(FEAT_GATHERER)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GATHERER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveGathererFeatEvent
    regist_event CheckAddGathererFeatEvent
    regist_event CheckRotateGathererFeatEvent

    # ザ・ギャザラーが使用される
    def use_gatherer_feat()
        if @feats_enable[FEAT_GATHERER]
        use_feat_event(@feats[FEAT_GATHERER])
        owner.healed_event(Feat.pow(@feats[FEAT_GATHERER])) if owner.hit_point > 0
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, Feat.pow(@feats[FEAT_GATHERER])))
      end
    end
    regist_event UseGathererFeatEvent

    # ザ・ギャザラーの回収予約
    def use_next_gatherer_feat()
      if @feats_enable[FEAT_GATHERER]
        # 提出したカードを回収
        @gatherer_tmp_table = owner.battle_table.clone
        owner.battle_table = [] # ここでOwnerのテーブルをからにしないと墓場と手元で二重になる
      end
    end
    regist_event UseNextGathererFeatEvent

    # ザ・ギャザラーが使用される
    def finish_gatherer_feat()
      if @feats_enable[FEAT_GATHERER]
        @cc.owner.grave_dealed_event(@gatherer_tmp_table) if @gatherer_tmp_table
        @gatherer_tmp_table =nil
        @feats_enable[FEAT_GATHERER] = false
      end
    end
    regist_event FinishGathererFeatEvent
    regist_event FinishCharaChangeGathererFeatEvent
    regist_event FinishFoeCharaChangeGathererFeatEvent

    # ザ・ギャザラーで死亡時とキャラチェンジにカード取得部分の必殺技を外す
    def finish_dead_gatherer_feat()
      if @feats_enable[FEAT_GATHERER]
        # ギャザラー中に死んだり、キャラチェンジしたときもカードを返さないと場からカードがなくなってしまう！
        # カードをきちんと墓場に戻す場合
        @gatherer_tmp_table.each { |c| c.throw} if @gatherer_tmp_table

        @gatherer_tmp_table =nil
        @feats_enable[FEAT_GATHERER] = false
      end
    end

    # ------------------
    # ザ・ジャッジ
    # ------------------
    # ザ・ジャッジが使用されたかのチェック
    def check_judge_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_JUDGE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_JUDGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveJudgeFeatEvent
    regist_event CheckAddJudgeFeatEvent
    regist_event CheckRotateJudgeFeatEvent

    # ザ・ジャッジが使用される
    # 有効の場合必殺技IDを返す
    def use_judge_feat()
      if @feats_enable[FEAT_JUDGE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_JUDGE])
      end
    end
    regist_event UseJudgeFeatEvent

    # ザ・ジャッジが使用終了
    def finish_judge_feat()
      if @feats_enable[FEAT_JUDGE]
        use_feat_event(@feats[FEAT_JUDGE])
        if foe.tmp_power >= 10
          foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, (foe.tmp_power*0.1).to_i))
        end
        @feats_enable[FEAT_JUDGE] = false
      end
    end
    regist_event FinishJudgeFeatEvent

    # ザ・ジャッジが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_judge_feat_damage()
      if @feats_enable[FEAT_JUDGE]
      end
    end
    regist_event UseJudgeFeatDamageEvent


    # ------------------
    # ザ・ドリーム
    # ------------------
    # ザ・ドリームが使用されたかのチェック
    def check_dream_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DREAM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DREAM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDreamFeatEvent
    regist_event CheckAddDreamFeatEvent
    regist_event CheckRotateDreamFeatEvent

    # ザ・ドリームが使用される
    # 有効の場合必殺技IDを返す
    def use_dream_feat()
      if @feats_enable[FEAT_DREAM]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DREAM]) * foe.battle_table.count
      end
    end
    regist_event UseDreamFeatEvent

    # ザ・ドリームが使用終了
    def finish_dream_feat()
      if @feats_enable[FEAT_DREAM]
        use_feat_event(@feats[FEAT_DREAM])
      end
    end
    regist_event FinishDreamFeatEvent

    # ザ・ドリームが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dream_feat_damage()
      if @feats_enable[FEAT_DREAM]
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,foe.cards.count))
        @feats_enable[FEAT_DREAM] = false
      end
    end
    regist_event UseDreamFeatDamageEvent

    # ------------------
    # ジ・ワン・アボヴ・オール
    # ------------------

    # ジ・ワン・アボヴ・オールが使用されたかのチェック
    def check_one_above_all_feat
      @cc.owner.reset_feat_on_cards(FEAT_ONE_ABOVE_ALL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ONE_ABOVE_ALL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveOneAboveAllFeatEvent
    regist_event CheckAddOneAboveAllFeatEvent
    regist_event CheckRotateOneAboveAllFeatEvent

    # ジ・ワン・アボヴ・オールが使用される
    def use_one_above_all_feat()
      if @feats_enable[FEAT_ONE_ABOVE_ALL]
        use_feat_event(@feats[FEAT_ONE_ABOVE_ALL])
        # 相手のカードを奪う
        (99).times do
          if foe.cards.size > 0
            steal_deal(foe.cards[foe.cards.size-1])
          end
        end
        owner.damaged_event((owner.current_hit_point_max*0.5).to_i,IS_NOT_HOSTILE_DAMAGE)
        @feats_enable[FEAT_ONE_ABOVE_ALL] = false
      end
    end
    regist_event UseOneAboveAllFeatEvent


    # ------------------
    # アンチセプティック・F
    # ------------------
    # アンチセプティック・Fが使用されたかのチェック
    def check_antiseptic_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ANTISEPTIC)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ANTISEPTIC) if @cc.special_status[SPECIAL_STATE_ANTISEPTIC][1] < 1
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAntisepticFeatEvent
    regist_event CheckAddAntisepticFeatEvent
    regist_event CheckRotateAntisepticFeatEvent

    def use_antiseptic_feat
      if @feats_enable[FEAT_ANTISEPTIC] && Feat.pow(@feats[FEAT_ANTISEPTIC]) > 0

        @antiseptic_sp_count = owner.get_battle_table_point(ActionCard::SPC)
      end
    end
    regist_event UseAntisepticFeatEvent

    # アンチセプティック・Fを使用
    def finish_antiseptic_feat()
      if @feats_enable[FEAT_ANTISEPTIC]

        if Feat.pow(@feats[FEAT_ANTISEPTIC]) > 0

          if @antiseptic_sp_count >= 2
            set_state(@cc.special_status[SPECIAL_STATE_ANTISEPTIC], 1, 3)
          end

        else
          set_state(@cc.special_status[SPECIAL_STATE_ANTISEPTIC], 1, 1)

        end
      end
    end
    regist_event FinishAntisepticFeatEvent

    # アンチセプティック・Fが終了
    def finish_turn_antiseptic_feat()
      if @feats_enable[FEAT_ANTISEPTIC]
        use_feat_event(@feats[FEAT_ANTISEPTIC])
        # 状態初期化/PT回復
        owner.cured_event()
        @cc.owner.hit_points.each_index do |i|
          @cc.owner.party_healed_event(i, 1) if @cc.owner.hit_points[i] > 0
        end
      end
    end
    regist_event FinishTurnAntisepticFeatEvent

    # ------------------
    # シルバーマシン
    # ------------------
    # シルバーマシンが使用されたかのチェック
    def check_silver_machine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SILVER_MACHINE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SILVER_MACHINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSilverMachineFeatEvent
    regist_event CheckAddSilverMachineFeatEvent
    regist_event CheckRotateSilverMachineFeatEvent

    # シルバーマシンが使用される
    # 有効の場合必殺技IDを返す
    def use_silver_machine_feat()
      if @feats_enable[FEAT_SILVER_MACHINE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SILVER_MACHINE])
      end
    end
    regist_event UseSilverMachineFeatEvent

    # シルバーマシンが使用終了
    def finish_silver_machine_feat()
    end
    regist_event FinishSilverMachineFeatEvent

    # シルバーマシンが使用される
    # 有効の場合必殺技IDを返す
    def finish_turn_silver_machine_feat()
      if @feats_enable[FEAT_SILVER_MACHINE]
        use_feat_event(@feats[FEAT_SILVER_MACHINE])
        # ダメージがプラスなら
        foe.hit_points.each_index do |i|
          # 0~2damage
          dmg = rand(3)
          # 対峙中の相手だけは絶対に殺せない仕様
          dmg = foe.hit_points[i] - 1 if foe.current_chara_card_no == i && foe.hit_points[i] <= dmg
          attribute_party_damage(foe, i, dmg) if dmg > 0
        end
        @feats_enable[FEAT_SILVER_MACHINE] = false
      end
    end
    regist_event FinishTurnSilverMachineFeatEvent

    # ------------------
    # アトムハート
    # ------------------
    # アトムハートが使用されたかのチェック
    def check_atom_heart_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_ATOM_HEART)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ATOM_HEART)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAtomHeartFeatEvent
    regist_event CheckAddAtomHeartFeatEvent
    regist_event CheckRotateAtomHeartFeatEvent

    # アトムハートが使用される
    # 有効の場合必殺技IDを返す
    def use_atom_heart_feat()
      if @feats_enable[FEAT_ATOM_HEART]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_ATOM_HEART])
      end
    end
    regist_event UseAtomHeartFeatEvent

    # アトムハートが使用される
    # 有効の場合必殺技IDを返す
    def use_next_atom_heart_feat()
      if @feats_enable[FEAT_ATOM_HEART]
        use_feat_event(@feats[FEAT_ATOM_HEART])
        # 一応変身も解除
        off_transform_sequence(false)
      end
    end
    regist_event UseNextAtomHeartFeatEvent

    # アトムハートが使用終了
    def finish_atom_heart_feat()
      if @feats_enable[FEAT_ATOM_HEART]
        # 相手の必殺技を解除
        foe_pow_before = foe.tmp_power
        owner_pow_before = owner.tmp_power
        foe.current_chara_card.reset_override_feats
        foe.current_chara_card.reset_special_status()
        off_field_effect(false)
        foe.current_chara_card.remove_singlton_method_rakshasa_stance_feat()
        foe.sealed_event()
        foe.point_check(Entrant::POINT_CHECK_BATTLE)
        owner.point_check(Entrant::POINT_CHECK_BATTLE)
        foe.point_rewrite_event if foe_pow_before != foe.tmp_power
        owner.point_rewrite_event if owner_pow_before != owner.tmp_power
      end
    end
    regist_event FinishAtomHeartFeatEvent
    regist_event FinishResultAtomHeartFeatEvent
    regist_event FinishCalcAtomHeartFeatEvent

    # アトムハートが使用される
    # 有効の場合必殺技IDを返す
    def disable_atom_heart_feat()
      if @feats_enable[FEAT_ATOM_HEART]
        @feats_enable[FEAT_ATOM_HEART] = false
      end
    end
    regist_event DisableAtomHeartFeatEvent
    regist_event DisableNextAtomHeartFeatEvent

    # ------------------
    # エレクトロサージェリー
    # ------------------

    # エレクトロサージェリーが使用されたかのチェック
    def check_electric_surgery_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ELECTRIC_SURGERY)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_ELECTRIC_SURGERY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveElectricSurgeryFeatEvent
    regist_event CheckAddElectricSurgeryFeatEvent
    regist_event CheckRotateElectricSurgeryFeatEvent

    # 必殺技の状態
    def use_electric_surgery_feat()
      if @feats_enable[FEAT_ELECTRIC_SURGERY]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ELECTRIC_SURGERY])
      end
    end
    regist_event UseElectricSurgeryFeatEvent

    # エレクトロサージェリーが使用される
    def finish_electric_surgery_feat()
      if @feats_enable[FEAT_ELECTRIC_SURGERY]
        use_feat_event(@feats[FEAT_ELECTRIC_SURGERY])
      end
    end
    regist_event FinishElectricSurgeryFeatEvent

    # エレクトロサージェリーが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_electric_surgery_feat_damage()
      if @feats_enable[FEAT_ELECTRIC_SURGERY]
        set_state(owner.current_chara_card.status[STATE_PARALYSIS], 1, 3);
        on_buff_event(true, owner.current_chara_card_no, STATE_PARALYSIS, owner.current_chara_card.status[STATE_PARALYSIS][0], owner.current_chara_card.status[STATE_PARALYSIS][1])
        buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 3);
        on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        @feats_enable[FEAT_ELECTRIC_SURGERY] = false
      end
    end
    regist_event UseElectricSurgeryFeatDamageEvent


    # ------------------
    # アシッドイーター
    # ------------------
    # アシッドイーターが使用されたかのチェック
    def check_acid_eater_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ACID_EATER)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ACID_EATER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAcidEaterFeatEvent
    regist_event CheckAddAcidEaterFeatEvent
    regist_event CheckRotateAcidEaterFeatEvent

    # アシッドイーターを使用
    def finish_used_acid_eater_feat()
      if @feats_enable[FEAT_ACID_EATER]
        @acid_eater_used = true
      end
    end
    regist_event FinishUsedDetermineAcidEaterFeatEvent

    # アシッドイーターを使用
    def finish_acid_eater_feat()
      if @acid_eater_used
        # 相手の必殺技を解除
        foe.sealed_event()
      end
    end
    regist_event FinishDetermineAcidEaterFeatEvent
    regist_event FinishCalcAcidEaterFeatEvent


    # アシッドイーターを使用
    def finish_next_acid_eater_feat()
      if @acid_eater_used
        use_feat_event(@feats[FEAT_ACID_EATER])
        @cc.owner.move_action(-1)
        @cc.foe.move_action(-1)
      end
      @feats_enable[FEAT_ACID_EATER] = false
      @acid_eater_used = false
    end
    regist_event FinishNextAcidEaterFeatEvent


    # ------------------
    # デッドロック
    # ------------------
    # デッドロックが使用されたかのチェック
    def check_dead_lock_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEAD_LOCK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DEAD_LOCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeadLockFeatEvent
    regist_event CheckAddDeadLockFeatEvent
    regist_event CheckRotateDeadLockFeatEvent

    # デッドロックが使用される
    # 有効の場合必殺技IDを返す
    def use_dead_lock_feat()
      if @feats_enable[FEAT_DEAD_LOCK]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DEAD_LOCK])
      end
    end
    regist_event UseDeadLockFeatEvent

    # デッドロックが使用終了
    def finish_dead_lock_feat()
      if @feats_enable[FEAT_DEAD_LOCK]
        use_feat_event(@feats[FEAT_DEAD_LOCK])
      end
    end
    regist_event FinishDeadLockFeatEvent

    # デッドロックが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dead_lock_feat_damage()
      if @feats_enable[FEAT_DEAD_LOCK]
        # buff処理
        if !instant_kill_guard?(foe)
          buffed = set_state(foe.current_chara_card.status[STATE_STOP], 1, 1);
          on_buff_event(false, foe.current_chara_card_no, STATE_STOP, foe.current_chara_card.status[STATE_STOP][0], foe.current_chara_card.status[STATE_STOP][1]) if buffed
        end
        @feats_enable[FEAT_DEAD_LOCK] = false
      end
    end
    regist_event UseDeadLockFeatDamageEvent


    # ------------------
    # ベガーズバンケット
    # ------------------

    # ベガーズバンケットが使用されたかのチェック
    def check_beggars_banquet_feat
      @cc.owner.reset_feat_on_cards(FEAT_BEGGARS_BANQUET)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BEGGARS_BANQUET)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBeggarsBanquetFeatEvent
    regist_event CheckAddBeggarsBanquetFeatEvent
    regist_event CheckRotateBeggarsBanquetFeatEvent

    # ベガーズバンケットが使用される
    def use_beggars_banquet_feat()
      if @feats_enable[FEAT_BEGGARS_BANQUET]
        @feats_enable[FEAT_BEGGARS_BANQUET] = false unless Feat.pow(@feats[FEAT_BEGGARS_BANQUET]) == 50
        use_feat_event(@feats[FEAT_BEGGARS_BANQUET])
        hps = []
        foe.hit_points.each_index do |i|
          hps << i if foe.hit_points[i] > 0
        end
        d = Feat.pow(@feats[FEAT_BEGGARS_BANQUET]) == 50 ? 5 : Feat.pow(@feats[FEAT_BEGGARS_BANQUET])
        attribute_party_damage(foe, hps, 1, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM, d) if hps.count > 0
      end
    end
    regist_event UseBeggarsBanquetFeatEvent

    # ザ・ギャザラーの回収予約
    def ex_beggars_banquet_tmp_feat
      if @feats_enable[FEAT_BEGGARS_BANQUET] && Feat.pow(@feats[FEAT_BEGGARS_BANQUET]) == 50
        # 提出したカードを回収
        @beggars_keep_card = owner.battle_table.clone.sort_by { |c| c.get_value_max }.pop
        owner.battle_table = []
      end
    end
    regist_event ExBeggarsBanquetTmpFeatEvent

    # ザ・ギャザラーが使用される
    def finish_ex_beggars_banquet_feat()
      if @feats_enable[FEAT_BEGGARS_BANQUET] && Feat.pow(@feats[FEAT_BEGGARS_BANQUET]) == 50
        @cc.owner.grave_dealed_event([@beggars_keep_card]) if @beggars_keep_card
        @beggars_keep_card = nil
        @feats_enable[FEAT_BEGGARS_BANQUET] = false
      end
    end
    regist_event FinishExBeggarsBanquetFeatEvent
    regist_event FinishCharaChangeExBeggarsBanquetFeatEvent
    regist_event FinishFoeCharaChangeExBeggarsBanquetFeatEvent


    # ------------------
    # スワンソング
    # ------------------

    # スワンソングが使用されたかのチェック
    def check_swan_song_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SWAN_SONG)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SWAN_SONG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSwanSongFeatEvent
    regist_event CheckAddSwanSongFeatEvent
    regist_event CheckRotateSwanSongFeatEvent

    # 必殺技の状態
    def use_swan_song_feat()
    end
    regist_event UseSwanSongFeatEvent

    # スワンソングが使用される
    def finish_swan_song_feat()
      if @feats_enable[FEAT_SWAN_SONG]
        use_feat_event(@feats[FEAT_SWAN_SONG])
        if owner.hit_point >= Feat.pow(@feats[FEAT_SWAN_SONG])
          owner.damaged_event(owner.hit_point-1, IS_NOT_HOSTILE_DAMAGE)
          foe.damaged_event(attribute_damage(ATTRIBUTE_DYING,foe,1))
        end
        @feats_enable[FEAT_SWAN_SONG] = false
      end
    end
    regist_event FinishSwanSongFeatEvent

    # ------------------
    # 懶惰の墓標
    # ------------------

    # 懶惰の墓標が使用されたかのチェック
    def check_idle_grave_feat
      @cc.owner.reset_feat_on_cards(FEAT_IDLE_GRAVE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_IDLE_GRAVE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveIdleGraveFeatEvent
    regist_event CheckAddIdleGraveFeatEvent
    regist_event CheckRotateIdleGraveFeatEvent

    # 懶惰の墓標が使用される
    def use_idle_grave_feat()
      if @feats_enable[FEAT_IDLE_GRAVE]
        use_feat_event(@feats[FEAT_IDLE_GRAVE])
        tmp_cards = foe.cards.shuffle
        cards_num_before = owner.cards.size
        deal_count = 0
        steal_count = 2
        # 相手のカードを奪う
        if foe.cards.size > 0
          tmp_cards.each do |c|
            if steal_count > deal_count
              if @cc.owner.distance == 1 &&(c.u_type == ActionCard::SWD || c.b_type == ActionCard::SWD)
                steal_deal(c)
                deal_count += 1
              elsif @cc.owner.distance > 1 &&(c.u_type == ActionCard::ARW || c.b_type == ActionCard::ARW)
                steal_deal(c)
                deal_count += 1
              end
            else
              break
            end
          end
        end
        # 自身を能力低下
        @feats_enable[FEAT_IDLE_GRAVE] = false
        return if Feat.pow(@feats[FEAT_IDLE_GRAVE]) > 2 && (deal_count < 2 || (cards_num_before + 2) != owner.cards.size)

        if @cc.status[STATE_STATE_DOWN][1] > 0
          @cc.status[STATE_STATE_DOWN][1] += 1
          @cc.status[STATE_STATE_DOWN][1] = 9 if @cc.status[STATE_STATE_DOWN][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        else
          set_state(@cc.status[STATE_STATE_DOWN], 1, 1)
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        end
      end
    end
    regist_event UseIdleGraveFeatEvent


    # ------------------
    # 慟哭の歌
    # ------------------
    # 慟哭の歌が使用されたかのチェック
    def check_sorrow_song_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SORROW_SONG)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SORROW_SONG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSorrowSongFeatEvent
    regist_event CheckAddSorrowSongFeatEvent
    regist_event CheckRotateSorrowSongFeatEvent

    def use_sorrow_song_feat()
      if @feats_enable[FEAT_SORROW_SONG]
        unless (foe.current_chara_card.get_enable_feats(PHASE_ATTACK).keys & THIRTEEN_EYES).size > 0
          foe.tmp_power = (foe.tmp_power/2).to_i
          foe.point_rewrite_event
        end
      end
    end
    regist_event UseSorrowSongFeatEvent

    # 慟哭の歌が使用終了
    def finish_sorrow_song_feat()
      if @feats_enable[FEAT_SORROW_SONG]
        use_feat_event(@feats[FEAT_SORROW_SONG])

        return if Feat.pow(@feats[FEAT_SORROW_SONG]) == 0
        @feats_enable[FEAT_SORROW_SONG] = false
        # 自身を能力低下
        if @cc.status[STATE_STATE_DOWN][1] > 0
          @cc.status[STATE_STATE_DOWN][1] += Feat.pow(@feats[FEAT_SORROW_SONG])
          @cc.status[STATE_STATE_DOWN][1] = 9 if @cc.status[STATE_STATE_DOWN][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        else
          set_state(@cc.status[STATE_STATE_DOWN], 1, Feat.pow(@feats[FEAT_SORROW_SONG]))
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        end
      end
    end
    regist_event FinishSorrowSongFeatEvent

    # ex慟哭の歌が終了
    def finish_ex_sorrow_song_feat()
      if @feats_enable[FEAT_SORROW_SONG]
        @feats_enable[FEAT_SORROW_SONG] = false
        # 自身を能力低下
        if Feat.pow(@feats[FEAT_SORROW_SONG]) == 0 && duel.tmp_damage <= 0
          if @cc.status[STATE_STATE_DOWN][1] > 0
            @cc.status[STATE_STATE_DOWN][1] += 1
            @cc.status[STATE_STATE_DOWN][1] = 9 if @cc.status[STATE_STATE_DOWN][1] > 9
            on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
          else
            set_state(@cc.status[STATE_STATE_DOWN], 1, 1)
            on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
          end
        end
      end
    end
    regist_event FinishExSorrowSongFeatEvent

    # ------------------
    # 紅蓮の車輪
    # ------------------
    # 紅蓮の車輪が使用されたかのチェック
    def check_red_wheel_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RED_WHEEL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RED_WHEEL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRedWheelFeatEvent
    regist_event CheckAddRedWheelFeatEvent
    regist_event CheckRotateRedWheelFeatEvent

    # 紅蓮の車輪が使用される
    # 有効の場合必殺技IDを返す
    def use_red_wheel_feat()
      if @feats_enable[FEAT_RED_WHEEL]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_RED_WHEEL])
      end
    end
    regist_event UseRedWheelFeatEvent

    # 紅蓮の車輪が使用終了
    def finish_red_wheel_feat()
      if @feats_enable[FEAT_RED_WHEEL]
        use_feat_event(@feats[FEAT_RED_WHEEL])
      end
    end
    regist_event FinishRedWheelFeatEvent

    # 紅蓮の車輪が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_red_wheel_feat_damage()
      if @feats_enable[FEAT_RED_WHEEL]
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << i if duel.second_entrant.hit_points[i] > 0
        end
        attribute_party_damage(foe, hps, (owner.tmp_power/10).to_i, ATTRIBUTE_CONSTANT, TARGET_TYPE_HP_MIN)
        # 自身を能力低下
        if @cc.status[STATE_STATE_DOWN][1] > 0
          @cc.status[STATE_STATE_DOWN][1] += 1
          @cc.status[STATE_STATE_DOWN][1] = 9 if @cc.status[STATE_STATE_DOWN][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        else
          set_state(@cc.status[STATE_STATE_DOWN], 1,  1)
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        end
        @feats_enable[FEAT_RED_WHEEL] = false
      end
    end
    regist_event UseRedWheelFeatDamageEvent


    # ------------------
    # 赤い石榴
    # ------------------

    # 赤い石榴が使用されたかのチェック
    def check_red_pomegranate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RED_POMEGRANATE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RED_POMEGRANATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRedPomegranateFeatEvent
    regist_event CheckAddRedPomegranateFeatEvent
    regist_event CheckRotateRedPomegranateFeatEvent

    # 柘榴用のメッセージ定数と番号を合わせる
    RED_PEMEGRANTE_MESS_SET = [
                               :RED_POMEGRANATE_RANDOM_HP_1,
                               :RED_POMEGRANATE_RANDOM_HP_5,
                               :RED_POMEGRANATE_RANDOM_HP_MAX,
                               :RED_POMEGRANATE_RANDOME_HAND_0,
                               :RED_POMEGRANATE_RANDOME_HAND_8,
                               :RED_POMEGRANATE_RANDOME_HAND_15,
                               nil,
                               :RED_POMEGRANATE_RANDOME_DAMEGE_ALL_1,
                               :RED_POMEGRANATE_RANDOME_DAMEGE_ALL_3,
                               :RED_POMEGRANATE_RANDOME_DAMEGE_ALL_5,
                               :RED_POMEGRANATE_RANDOME_HEAL_ALL_1,
                               :RED_POMEGRANATE_RANDOME_HEAL_ALL_3,
                               :RED_POMEGRANATE_RANDOME_HEAL_ALL_5,
                               :RED_POMEGRANATE_RANDOM_BOSS_HP_1,
                               :RED_POMEGRANATE_RANDOM_BOSS_HP_5,
                               :RED_POMEGRANATE_RANDOM_BOSS_HP_MAX
                              ]

    # 赤い石榴を使用
    def finish_red_pomegranate_feat()
      if @feats_enable[FEAT_RED_POMEGRANATE]
        @feats_enable[FEAT_RED_POMEGRANATE] = false
        use_feat_event(@feats[FEAT_RED_POMEGRANATE])
        # 状態初期化
        owner.cured_event()
        # ランダム効果一覧
        effects = [[:random_hp, 1], # 0
                   [:random_hp, 5], # 1
                   [:random_hp, 99], # 2
                   [:random_hand, 0], # 3
                   [:random_hand, 8], # 4
                   [:random_hand, 15], # 5
                   [:random_move, 0],  # 6
                   [:random_damage_all, 1], # 7
                   [:random_damage_all, 3], # 8
                   [:random_damage_all, 5], # 9
                   [:random_heal_all, 1],   # 10
                   [:random_heal_all, 3],   # 11
                   [:random_heal_all, 5]]   # 12
        # ランダム効果決定
        no = rand(effects.size)
        # ラダンム効果を発揮
        self.send(effects[no][0], effects[no][1])
        if no < 3 && instant_kill_guard?(foe)                                                   # HP固定 && BOSS
          no += effects.size                                                                    # BOSS用メッセージに切り替える
        end
        owner.special_message_event(RED_PEMEGRANTE_MESS_SET[no]) if RED_PEMEGRANTE_MESS_SET[no] # 移動だけ別途送る

      end
    end
    regist_event FinishRedPomegranateFeatEvent

    # HPを固定させる
    def random_hp(v = 0)
      if owner.hit_point > v
        owner.damaged_event(owner.hit_point-v,IS_NOT_HOSTILE_DAMAGE)
      elsif owner.hit_point < v
        owner.healed_event(v-owner.hit_point)
      end
      if v == 99
        foe.healed_event(attribute_damage(ATTRIBUTE_ZAKURO,foe,v))
      elsif foe.hit_point > v
        foe.damaged_event(attribute_damage(ATTRIBUTE_ZAKURO,foe,v))
      elsif foe.hit_point > v
        foe.healed_event(foe.hit_point-v)
      elsif foe.hit_point < v
        foe.healed_event(v-foe.hit_point)
      end
    end

    # 手札を固定させる
    def random_hand(v = 0)
      if owner.cards.count < v
        owner.special_dealed_event(duel.deck.draw_cards_event(v-owner.cards.count).each{ |c| owner.dealed_event(c)})
      elsif owner.cards.count > v
        aca = owner.cards.shuffle
        (owner.cards.count-v).times{ |a| discard(owner, aca[a]) if aca[a] }
      end
      if foe.cards.count < v
        foe.special_dealed_event(duel.deck.draw_cards_event(v-foe.cards.count).each{ |c| foe.dealed_event(c)})
      elsif foe.cards.count > v
        aca = foe.cards.shuffle
        (foe.cards.count-v).times{ |a| discard(foe, aca[a]) if aca[a] }
      end
    end

    # 柘榴用のメッセージ定数と番号を合わせる
    RED_PEMEGRANTE_RAND_MOVE_MESS_SET = [
                                         :RED_POMEGRANATE_RANDOME_MOVE_M2,
                                         :RED_POMEGRANATE_RANDOME_MOVE_M1,
                                         :RED_POMEGRANATE_RANDOME_MOVE_0,
                                         :RED_POMEGRANATE_RANDOME_MOVE_2,
                                         :RED_POMEGRANATE_RANDOME_MOVE_1,
                                        ]
    # ランダムに移動
    def random_move(v = 0)
      mp = rand(4) -2
      @cc.owner.move_action(mp)
      @cc.foe.move_action(mp)
      owner.special_message_event(RED_PEMEGRANTE_RAND_MOVE_MESS_SET[mp+2])
    end

    # 全てにダメージ
    def random_damage_all(v = 0)
      hps = []
      owner.hit_points.each_with_index do |v,i|
        hps << i if v > 0
      end
      attribute_party_damage(owner, hps, v, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL, 1, IS_NOT_HOSTILE_DAMAGE) if hps.size > 0

      hps = []
      foe.hit_points.each_with_index do |v,i|
        hps << i if v > 0
      end
      attribute_party_damage(foe, hps, v, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL) if hps.size > 0
    end

    # 全てを回復
    def random_heal_all(v = 0)
      owner.hit_points.each_index do |i|
        owner.party_healed_event(i, v) if owner.hit_points[i] > 0
      end
      foe.hit_points.each_index do |i|
        foe.party_healed_event(i, v) if foe.hit_points[i] > 0
      end
    end


    # ------------------
    # クロックワークス
    # ------------------
    # クロックワークスが使用されたかのチェック
    def check_clock_works_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CLOCK_WORKS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CLOCK_WORKS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveClockWorksFeatEvent
    regist_event CheckAddClockWorksFeatEvent
    regist_event CheckRotateClockWorksFeatEvent

    # クロックワークスを使用
    def finish_clock_works_feat()
      if @feats_enable[FEAT_CLOCK_WORKS]
        use_feat_event(@feats[FEAT_CLOCK_WORKS])
        @feats_enable[FEAT_CLOCK_WORKS] = false
        # イベントカードを引く
        num = Feat.pow(@feats[FEAT_CLOCK_WORKS]) == 1 ? owner.get_battle_table_point(ActionCard::SPC) : Feat.pow(@feats[FEAT_CLOCK_WORKS])
        num = 2 if num > 2
        @cc.owner.special_event_card_dealed_event(duel.get_event_deck(owner).draw_cards_event(num).each{ |c| @cc.owner.dealed_event(c)})
        # ターンを加算する
        duel.set_turn(duel.turn+num)
      end
    end
    regist_event FinishClockWorksFeatEvent

    # ------------------
    # タイムハント
    # ------------------
    # タイムハントが使用されたかのチェック
    def check_time_hunt_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_HUNT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_TIME_HUNT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTimeHuntFeatEvent
    regist_event CheckAddTimeHuntFeatEvent
    regist_event CheckRotateTimeHuntFeatEvent

    def use_ex_time_hunt_feat()
      if @feats_enable[FEAT_TIME_HUNT] && Feat.pow(@feats[FEAT_TIME_HUNT]) == 5
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_TIME_HUNT])
      end
    end
    regist_event UseExTimeHuntFeatEvent

    # タイムハントが使用される
    # 有効の場合必殺技IDを返す
    def use_time_hunt_feat()
      if @feats_enable[FEAT_TIME_HUNT]
        unless (foe.current_chara_card.get_enable_feats(PHASE_ATTACK).keys & THIRTEEN_EYES).size > 0
          foe.tmp_power -= duel.turn
          foe.tmp_power = 0 if foe.tmp_power < 0
          foe.point_rewrite_event
        end
      end
    end
    regist_event UseTimeHuntFeatEvent

    # タイムハントが使用終了
    def finish_time_hunt_feat()
      if @feats_enable[FEAT_TIME_HUNT]
        @feats_enable[FEAT_TIME_HUNT] = false
        use_feat_event(@feats[FEAT_TIME_HUNT])
      end
    end
    regist_event FinishTimeHuntFeatEvent

    # ------------------
    # タイムボム
    # ------------------

    # タイムボムが使用されたかのチェック
    def check_time_bomb_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_BOMB)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TIME_BOMB)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTimeBombFeatEvent
    regist_event CheckAddTimeBombFeatEvent
    regist_event CheckRotateTimeBombFeatEvent

    # タイムボムが使用される
    # 有効の場合必殺技IDを返す
    def use_time_bomb_feat()
      if @feats_enable[FEAT_TIME_BOMB]
        if Feat.pow(@feats[FEAT_TIME_BOMB]) == 11 && ![2,3,5,7,11,13,17].include?(duel.turn)
            @cc.owner.tmp_power+=7
        else
          @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_TIME_BOMB])
        end
      end
    end
    regist_event UseTimeBombFeatEvent

    # タイムボムが使用終了される
    def finish_time_bomb_feat()
      if @feats_enable[FEAT_TIME_BOMB]
        @feats_enable[FEAT_TIME_BOMB] = false
        use_feat_event(@feats[FEAT_TIME_BOMB])
        if [2,3,5,7,11,13,17].include?(duel.turn)
          d = Feat.pow(@feats[FEAT_TIME_BOMB]) > 7 ? 4 : 3
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,d))
        end
      end
    end
    regist_event FinishTimeBombFeatEvent

    # ------------------
    # インジイブニング
    # ------------------
    # インジイブニングが使用されたかのチェック
    def check_in_the_evening_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_IN_THE_EVENING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_IN_THE_EVENING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveInTheEveningFeatEvent
    regist_event CheckAddInTheEveningFeatEvent
    regist_event CheckRotateInTheEveningFeatEvent

    #  インジイブニングを使用
    def finish_in_the_evening_feat()
      if @feats_enable[FEAT_IN_THE_EVENING]
        use_feat_event(@feats[FEAT_IN_THE_EVENING])
        @feats_enable[FEAT_IN_THE_EVENING] = false
        @cc.owner.chara_cards.each_index do |i|
          @cc.owner.party_healed_event(i, ((@cc.owner.chara_cards[i].rarity-4)/2).to_i) if @cc.owner.hit_points[i] > 0 && @cc.owner.chara_cards[i].rarity > 5
        end
      end
    end
    regist_event FinishInTheEveningFeatEvent

    # ------------------
    # 終局のワルツ
    # ------------------

    # 終局のワルツが使用されたかのチェック
    def check_final_waltz_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FINAL_WALTZ)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_FINAL_WALTZ)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFinalWaltzFeatEvent
    regist_event CheckAddFinalWaltzFeatEvent
    regist_event CheckRotateFinalWaltzFeatEvent

    # 必殺技の状態
    def use_final_waltz_feat()
      if @feats_enable[FEAT_FINAL_WALTZ]
        @cc.owner.tmp_power += 5
      end
    end
    regist_event UseFinalWaltzFeatEvent

    # 終局のワルツが使用される
    def finish_final_waltz_feat()
      if @feats_enable[FEAT_FINAL_WALTZ]
        use_feat_event(@feats[FEAT_FINAL_WALTZ])
      end
    end
    regist_event FinishFinalWaltzFeatEvent

    # 終局のワルツが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_final_waltz_feat_damage()
      if @feats_enable[FEAT_FINAL_WALTZ]
        if foe.current_chara_card.status[STATE_DEAD_COUNT][1] > 0
          if foe.current_chara_card.status[STATE_DEAD_COUNT][1] <= 3
            if @cc.status_update
              off_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0])
              foe.current_chara_card.status[STATE_DEAD_COUNT][1] = 0
              foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))
            else
              (foe.current_chara_card.status[STATE_DEAD_COUNT][1]).times{ update_buff_event(false, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0]) }
              # レイド戦の場合は、OnBuffイベントで更新するのみ
              on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], 0)
              foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))
            end
          else
            (3).times{ update_buff_event(false, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0]) }
            foe.current_chara_card.status[STATE_DEAD_COUNT][1] -= 3
            # レイドの場合は3まで短縮
            unless @cc.status_update
              buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, 3)
              on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed
            end
          end
        else
          buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, Feat.pow(@feats[FEAT_FINAL_WALTZ]));
          on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed
        end
        @feats_enable[FEAT_FINAL_WALTZ] = false
      end
    end
    regist_event UseFinalWaltzFeatDamageEvent


    # ------------------
    # 自棄のソナタ
    # ------------------

    # 自棄のソナタが使用されたかのチェック
    def check_desperate_sonata_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DESPERATE_SONATA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DESPERATE_SONATA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDesperateSonataFeatEvent
    regist_event CheckAddDesperateSonataFeatEvent
    regist_event CheckRotateDesperateSonataFeatEvent

    # 自棄のソナタが使用される
    # 有効の場合必殺技IDを返す
    def use_desperate_sonata_feat()
      if @feats_enable[FEAT_DESPERATE_SONATA]
        @cc.owner.tmp_power += 1
      end
    end
    regist_event UseDesperateSonataFeatEvent

    # 自棄のソナタを使用
    def finish_desperate_sonata_feat()
      if @feats_enable[FEAT_DESPERATE_SONATA]
        # 待機のとき状態異常
        if foe.get_direction == Entrant::DIRECTION_STAY
          turn = Feat.pow(@feats[FEAT_DESPERATE_SONATA]) == 2 ? 5 : 3
          buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, turn)
          on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        end
        use_feat_event(@feats[FEAT_DESPERATE_SONATA])
      end
    end
    regist_event FinishDesperateSonataFeatEvent

    # 自棄のソナタを終了
    def finish_turn_desperate_sonata_feat()
      if @feats_enable[FEAT_DESPERATE_SONATA]
        @feats_enable[FEAT_DESPERATE_SONATA] = false
      end
    end
    regist_event FinishTurnDesperateSonataFeatEvent

    # ------------------
    # 剣闘士のマーチ
    # ------------------

    # 剣闘士のマーチが使用されたかのチェック
    def check_gladiator_march_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GLADIATOR_MARCH)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GLADIATOR_MARCH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGladiatorMarchFeatEvent
    regist_event CheckAddGladiatorMarchFeatEvent
    regist_event CheckRotateGladiatorMarchFeatEvent

    # 剣闘士のマーチが使用
    def use_gladiator_march_feat()
      if @feats_enable[FEAT_GLADIATOR_MARCH]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_GLADIATOR_MARCH])
      end
    end
    regist_event UseGladiatorMarchFeatEvent

    # 剣闘士のマーチが使用終了される
    def finish_gladiator_march_feat()
      if @feats_enable[FEAT_GLADIATOR_MARCH]
        @feats_enable[FEAT_GLADIATOR_MARCH] = false
        use_feat_event(@feats[FEAT_GLADIATOR_MARCH])
        heal = ((duel.turn-1) / 6).to_i + 1
        @cc.owner.hit_points.each_index do |i|
          @cc.owner.party_healed_event(i, heal) if @cc.owner.hit_points[i] > 0
        end
        foe.hit_points.each_index do |i|
          foe.party_healed_event(i, 1) if foe.hit_points[i] > 0
        end
      end
    end
    regist_event FinishGladiatorMarchFeatEvent

    # ------------------
    # 恩讐のレクイエム
    # ------------------

    # 恩讐のレクイエムが使用されたかのチェック
    def check_requiem_of_revenge_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_REQUIEM_OF_REVENGE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_REQUIEM_OF_REVENGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRequiemOfRevengeFeatEvent
    regist_event CheckAddRequiemOfRevengeFeatEvent
    regist_event CheckRotateRequiemOfRevengeFeatEvent

    # 恩讐のレクイエムが使用される
    # 有効の場合必殺技IDを返す
    def use_requiem_of_revenge_feat()
      if @feats_enable[FEAT_REQUIEM_OF_REVENGE]
        @cc.owner.tmp_power += 5
      end
    end
    regist_event UseRequiemOfRevengeFeatEvent

    # 恩讐のレクイエムが使用終了される
    def finish_requiem_of_revenge_feat()
      if @feats_enable[FEAT_REQUIEM_OF_REVENGE]
        @feats_enable[FEAT_REQUIEM_OF_REVENGE] = false
        use_feat_event(@feats[FEAT_REQUIEM_OF_REVENGE])
        if duel.turn == BATTLE_TIMEOUT_TURN
          attribute_party_damage(foe, get_hps(foe), Feat.pow(@feats[FEAT_REQUIEM_OF_REVENGE]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end
      end
    end
    regist_event FinishRequiemOfRevengeFeatEvent

    # ------------------
    # おいしいミルク
    # ------------------

    # おいしいミルクが使用されたかのチェック
    def check_delicious_milk_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DELICIOUS_MILK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DELICIOUS_MILK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDeliciousMilkFeatEvent
    regist_event CheckAddDeliciousMilkFeatEvent
    regist_event CheckRotateDeliciousMilkFeatEvent

    # おいしいミルクの効果が発揮される
    def use_delicious_milk_feat()
      if @feats_enable[FEAT_DELICIOUS_MILK]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DELICIOUS_MILK])
      end
    end
    regist_event UseDeliciousMilkFeatEvent

    # おいしいミルクの効果が発揮される
    def use_ex_delicious_milk_feat()
      if @feats_enable[FEAT_DELICIOUS_MILK] && Feat.pow(@feats[FEAT_DELICIOUS_MILK]) > 10
        @cc.owner.tmp_power += 4
      end
    end
    regist_event UseExDeliciousMilkFeatEvent

    # おいしいミルクを使用
    def finish_change_delicious_milk_feat()
      if @feats_enable[FEAT_DELICIOUS_MILK]
        # 自分ひとりでキャラチェンジしたとき移動方向を制御
        owner.set_direction(Entrant::DIRECTION_STAY) if owner.hit_points.select{ |h| h > 0 }.count <= 1 && owner.direction == Entrant::DIRECTION_CHARA_CHANGE
      end
    end
    regist_event FinishChangeDeliciousMilkFeatEvent

    # おいしいミルクを使用
    def finish_delicious_milk_feat()
      if @feats_enable[FEAT_DELICIOUS_MILK]
        use_feat_event(@feats[FEAT_DELICIOUS_MILK])
        on_transform_sequence(true)
        # 味方へのダメージは自傷ダメージとして取り扱う
        attribute_party_damage(owner, get_hps(owner, true), 1, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL, 1, IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishDeliciousMilkFeatEvent

    # おいしいミルクが終了
    def finish_turn_delicious_milk_feat()
      if @feats_enable[FEAT_DELICIOUS_MILK]
        @feats_enable[FEAT_DELICIOUS_MILK] = false
        off_transform_sequence(true)
      end
    end
    regist_event FinishTurnDeliciousMilkFeatEvent

    # ------------------
    # やさしいお注射
    # ------------------

    # やさしいお注射が使用されたかのチェック
    def check_easy_injection_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_EASY_INJECTION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_EASY_INJECTION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEasyInjectionFeatEvent
    regist_event CheckAddEasyInjectionFeatEvent
    regist_event CheckRotateEasyInjectionFeatEvent

    # やさしいお注射が使用
    def use_easy_injection_feat()
      if @feats_enable[FEAT_EASY_INJECTION]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_EASY_INJECTION])
      end
    end
    regist_event UseEasyInjectionFeatEvent

    # やさしいお注射が使用終了される
    def finish_easy_injection_feat()
      if @feats_enable[FEAT_EASY_INJECTION]
        @feats_enable[FEAT_EASY_INJECTION] = false
        use_feat_event(@feats[FEAT_EASY_INJECTION])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << [i, duel.second_entrant.hit_points[i]] if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
        end
        if hps.size > 0
          hps.shuffle! if hps.size ==2 && hps[0][1] == hps[1][1] # 残り二人のhpが同じ値ならばランダムに入れ替える
          chp = hps.sort{ |a,b| a[1] <=> b[1] }[0]
          if chp[1] < owner.hit_point
            duel.second_entrant.party_healed_event(chp[0], owner.hit_point-chp[1])
          elsif chp[1] > owner.hit_point
            duel.second_entrant.party_damaged_event(chp[0], chp[1]-owner.hit_point)
          end
        end
      end
    end
    regist_event FinishEasyInjectionFeatEvent

    # ------------------
    # たのしい採血
    # ------------------

    # たのしい採血が使用されたかのチェック
    def check_blood_collecting_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLOOD_COLLECTING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLOOD_COLLECTING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBloodCollectingFeatEvent
    regist_event CheckAddBloodCollectingFeatEvent
    regist_event CheckRotateBloodCollectingFeatEvent

    # たのしい採血が使用される
    # 有効の場合必殺技IDを返す
    def use_blood_collecting_feat()
      if @feats_enable[FEAT_BLOOD_COLLECTING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BLOOD_COLLECTING])*@cc.owner.get_battle_table_point(ActionCard::SPC)
      end
    end
    regist_event UseBloodCollectingFeatEvent

    # たのしい採血が使用終了
    def finish_blood_collecting_feat()
      if @feats_enable[FEAT_BLOOD_COLLECTING]
        @feats_enable[FEAT_BLOOD_COLLECTING] = false
        use_feat_event(@feats[FEAT_BLOOD_COLLECTING])
        hps = []
        owner.hit_points.each_index do |i|
          hps << [i, owner.hit_points[i]] if i != owner.current_chara_card_no && owner.hit_points[i] > 0
        end
        if hps.size > 0
          hps.shuffle! if hps.size ==2 && hps[0][1] == hps[1][1] # 残り二人のhpが同じ値ならばランダムに入れ替える
          # オーナー側は自傷ダメージとして取り扱う
          attribute_party_damage(owner,
                                 hps.sort{ |a,b| a[1] <=> b[1] }[0][0],
                                 owner.get_battle_table_point(ActionCard::SPC).to_i,
                                 ATTRIBUTE_CONSTANT,
                                 TARGET_TYPE_SINGLE,
                                 1,
                                 IS_NOT_HOSTILE_DAMAGE)
        else
          owner.damaged_event(owner.get_battle_table_point(ActionCard::SPC).to_i, IS_NOT_HOSTILE_DAMAGE)
        end
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishBloodCollectingFeatEvent

    # ------------------
    # ひみつのお薬
    # ------------------

    # ひみつのお薬が使用されたかのチェック
    def check_secret_medicine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SECRET_MEDICINE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SECRET_MEDICINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSecretMedicineFeatEvent
    regist_event CheckAddSecretMedicineFeatEvent
    regist_event CheckRotateSecretMedicineFeatEvent

    # ひみつのお薬が使用
    def use_secret_medicine_feat()
    end
    regist_event UseSecretMedicineFeatEvent

    # ひみつのお薬が使用終了される
    def finish_secret_medicine_feat()
      if @feats_enable[FEAT_SECRET_MEDICINE]
        @feats_enable[FEAT_SECRET_MEDICINE] = false
        use_feat_event(@feats[FEAT_SECRET_MEDICINE])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << [i, duel.second_entrant.hit_points[i]] if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
        end
        # 控えを全回復
        if hps.size > 0
          hps.each do |h|
            duel.second_entrant.party_healed_event(h[0], Feat.pow(@feats[FEAT_SECRET_MEDICINE]))
          end
        end
        # 変身時の効果
        owner.cards_max = owner.cards_max + 1 if @feats_enable[FEAT_DELICIOUS_MILK]
        # 自身は死亡
        owner.damaged_event(99,IS_NOT_HOSTILE_DAMAGE)
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishSecretMedicineFeatEvent

    # ------------------
    # 氷の門
    # ------------------

    # 氷の門が使用されたかのチェック
    def check_ice_gate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ICE_GATE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ICE_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIceGateFeatEvent
    regist_event CheckAddIceGateFeatEvent
    regist_event CheckRotateIceGateFeatEvent

    # 氷の門が使用される
    # 有効の場合必殺技IDを返す
    def use_ice_gate_feat()
      if @feats_enable[FEAT_ICE_GATE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ICE_GATE])
      end
    end
    regist_event UseIceGateFeatEvent


    # 氷の門が使用終了される
    def finish_ice_gate_feat()
      if @feats_enable[FEAT_ICE_GATE]
        @feats_enable[FEAT_ICE_GATE] = false
        use_feat_event(@feats[FEAT_ICE_GATE])
        if (foe.current_chara_card.level % 2) == 1 && (duel.turn % 2) == 1
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_ICE_GATE])))
        end
      end
    end
    regist_event FinishIceGateFeatEvent

    # ------------------
    # 炎の門
    # ------------------

    # 炎の門が使用されたかのチェック
    def check_fire_gate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FIRE_GATE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FIRE_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFireGateFeatEvent
    regist_event CheckAddFireGateFeatEvent
    regist_event CheckRotateFireGateFeatEvent

    # 炎の門が使用される
    # 有効の場合必殺技IDを返す
    def use_fire_gate_feat()
      if @feats_enable[FEAT_FIRE_GATE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FIRE_GATE])
      end
    end
    regist_event UseFireGateFeatEvent


    # 炎の門が使用終了される
    def finish_fire_gate_feat()
      if @feats_enable[FEAT_FIRE_GATE]
        @feats_enable[FEAT_FIRE_GATE] = false
        use_feat_event(@feats[FEAT_FIRE_GATE])
        if (foe.current_chara_card.level % 2) == 0 && (duel.turn % 2) == 0
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_FIRE_GATE])))
        end
      end
    end
    regist_event FinishFireGateFeatEvent

    # ------------------
    # 崩れる門
    # ------------------

    # 崩れる門が使用されたかのチェック
    def check_break_gate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BREAK_GATE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BREAK_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBreakGateFeatEvent
    regist_event CheckAddBreakGateFeatEvent
    regist_event CheckRotateBreakGateFeatEvent

    # 崩れる門が使用される
    # 有効の場合必殺技IDを返す
    def use_break_gate_feat()
    end
    regist_event UseBreakGateFeatEvent

    # 崩れる門が使用終了される
    def finish_break_gate_feat()
      if @feats_enable[FEAT_BREAK_GATE]
        @feats_enable[FEAT_BREAK_GATE] = false
        use_feat_event(@feats[FEAT_BREAK_GATE])
        mp = rand(4) -2
        @cc.owner.move_action(mp)
        @cc.foe.move_action(mp)
        if duel.turn % 5 == 0
          owner.damaged_event(Feat.pow(@feats[FEAT_BREAK_GATE]),IS_NOT_HOSTILE_DAMAGE)
        end
      end
    end
    regist_event FinishBreakGateFeatEvent

    # ------------------
    # 叫ぶ門
    # ------------------
    # 叫ぶ門が使用されたかのチェック
    def check_shout_of_gate_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SHOUT_OF_GATE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SHOUT_OF_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShoutOfGateFeatEvent
    regist_event CheckAddShoutOfGateFeatEvent
    regist_event CheckRotateShoutOfGateFeatEvent

    # 叫ぶ門が使用される
    # 有効の場合必殺技IDを返す
    def use_shout_of_gate_feat()
    end
    regist_event UseShoutOfGateFeatEvent

    # 叫ぶ門が使用終了
    def finish_shout_of_gate_feat()
      if @feats_enable[FEAT_SHOUT_OF_GATE]
        use_feat_event(@feats[FEAT_SHOUT_OF_GATE])
      end
    end
    regist_event FinishShoutOfGateFeatEvent

    # 叫ぶ門が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_shout_of_gate_feat_damage()
      if @feats_enable[FEAT_SHOUT_OF_GATE]
        # ダメージが0以下でダメージ
        if duel.tmp_damage <= 0
          attribute_party_damage(foe, get_hps(foe), Feat.pow(@feats[FEAT_SHOUT_OF_GATE]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end
        @feats_enable[FEAT_SHOUT_OF_GATE] = false
      end
    end
    regist_event UseShoutOfGateFeatDamageEvent


    # ------------------
    # フュリアスアンガー
    # ------------------

    # フュリアスアンガーが使用されたかのチェック
    def check_ferreous_anger_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FERREOUS_ANGER)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_FERREOUS_ANGER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFerreousAngerFeatEvent
    regist_event CheckAddFerreousAngerFeatEvent
    regist_event CheckRotateFerreousAngerFeatEvent

    # 必殺技の状態
    def use_ferreous_anger_feat()
      if @feats_enable[FEAT_FERREOUS_ANGER]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FERREOUS_ANGER])
      end
    end
    regist_event UseFerreousAngerFeatEvent

    # フュリアスアンガーが使用される
    def finish_ferreous_anger_feat()
      if @feats_enable[FEAT_FERREOUS_ANGER]
      end
    end
    regist_event FinishFerreousAngerFeatEvent

    # フュリアスアンガーが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_ferreous_anger_feat_damage()
      if @feats_enable[FEAT_FERREOUS_ANGER]
        use_feat_event(@feats[FEAT_FERREOUS_ANGER])
        if @cc.status[STATE_STICK][1] > 0
          if @cc.status[STATE_STICK][0] == 1
            foe.cured_event()
          elsif Feat.pow(@feats[FEAT_FERREOUS_ANGER]) == 10 && @cc.status[STATE_STICK][0] == 2
            @cc.status.each_with_index do |s,i|
              if s[1] > 0 && i != STATE_STICK && (! CharaCard::IRREMEDIABLE_STATE.include?(i))
                s[1] = 0
                off_buff_event(true, owner.current_chara_card_no, i, s[0])
              end
            end
          end
          change_stick_state
          on_buff_event(true, owner.current_chara_card_no, STATE_STICK, @cc.status[STATE_STICK][0], @cc.status[STATE_STICK][1])
        end
        @feats_enable[FEAT_FERREOUS_ANGER] = false
      end
    end
    regist_event UseFerreousAngerFeatDamageEvent

    # ------------------
    # ネームオブチャリティ
    # ------------------

    # ネームオブチャリティが使用されたかのチェック
    def check_name_of_charity_feat
      @cc.owner.reset_feat_on_cards(FEAT_NAME_OF_CHARITY)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_NAME_OF_CHARITY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveNameOfCharityFeatEvent
    regist_event CheckAddNameOfCharityFeatEvent
    regist_event CheckRotateNameOfCharityFeatEvent

    # ネームオブチャリティが使用される
    def use_name_of_charity_feat()
      if @feats_enable[FEAT_NAME_OF_CHARITY]
        use_feat_event(@feats[FEAT_NAME_OF_CHARITY])
        if foe.current_chara_card.kind == CC_KIND_MONSTAR ||
            foe.current_chara_card.kind == CC_KIND_BOSS_MONSTAR ||
            foe.current_chara_card.kind == CC_KIND_PROFOUND_BOSS ||
            foe.current_chara_card.kind == CC_KIND_RARE_MONSTER ||
            foe.current_chara_card.special_status[SPECIAL_STATE_CAT][1] > 0

          buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, Feat.pow(@feats[FEAT_NAME_OF_CHARITY]))
          on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        end
        if @cc.status[STATE_STICK][1] > 0
          change_stick_state
          on_buff_event(true, owner.current_chara_card_no, STATE_STICK, @cc.status[STATE_STICK][0], @cc.status[STATE_STICK][1])
        else
          set_state(@cc.status[STATE_STICK], 1+rand(2), 1)
          on_buff_event(true, owner.current_chara_card_no, STATE_STICK, @cc.status[STATE_STICK][0], @cc.status[STATE_STICK][1])
        end

        @feats_enable[FEAT_NAME_OF_CHARITY] = false
      end
    end
    regist_event UseNameOfCharityFeatEvent

    # ------------------
    # グッドウィル
    # ------------------

    # グッドウィルが使用されたかのチェック
    def check_good_will_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GOOD_WILL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GOOD_WILL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGoodWillFeatEvent
    regist_event CheckAddGoodWillFeatEvent
    regist_event CheckRotateGoodWillFeatEvent

    # グッドウィルが使用
    def use_good_will_feat()
      if @feats_enable[FEAT_GOOD_WILL]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_GOOD_WILL])+1
      end
    end
    regist_event UseGoodWillFeatEvent

    # グッドウィルが使用終了される
    def finish_good_will_feat()
      if @feats_enable[FEAT_GOOD_WILL]
        @feats_enable[FEAT_GOOD_WILL] = false
        use_feat_event(@feats[FEAT_GOOD_WILL])
        if @cc.status[STATE_STICK][1] > 0
          if @cc.status[STATE_STICK][0] == 2
            owner.healed_event(Feat.pow(@feats[FEAT_GOOD_WILL]))
          end
          change_stick_state
          on_buff_event(true, owner.current_chara_card_no, STATE_STICK, @cc.status[STATE_STICK][0], @cc.status[STATE_STICK][1])
        end
      end
    end
    regist_event FinishGoodWillFeatEvent

    # ------------------
    # グレードベンジェンス
    # ------------------
    # グレードベンジェンスが使用されたかのチェック
    def check_great_vengeance_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GREAT_VENGEANCE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GREAT_VENGEANCE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGreatVengeanceFeatEvent
    regist_event CheckAddGreatVengeanceFeatEvent
    regist_event CheckRotateGreatVengeanceFeatEvent

    # グレードベンジェンスが使用される
    # 有効の場合必殺技IDを返す
    def use_great_vengeance_feat()
      if @feats_enable[FEAT_GREAT_VENGEANCE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_GREAT_VENGEANCE])
      end
    end
    regist_event UseGreatVengeanceFeatEvent

    # 精密射撃が使用終了
    def finish_great_vengeance_feat()
      if @feats_enable[FEAT_GREAT_VENGEANCE]
      end
    end
    regist_event FinishGreatVengeanceFeatEvent

    # グレードベンジェンスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_great_vengeance_feat_damage()
      if @feats_enable[FEAT_GREAT_VENGEANCE]
        use_feat_event(@feats[FEAT_GREAT_VENGEANCE])
        @great_vengence_const_damage = 0
        if @cc.status[STATE_STICK][1] > 0
          if @cc.status[STATE_STICK][0] == 1
            @great_vengence_const_damage = duel.tmp_damage if duel.tmp_damage > 0
          end
          change_stick_state
          on_buff_event(true, owner.current_chara_card_no, STATE_STICK, @cc.status[STATE_STICK][0], @cc.status[STATE_STICK][1])
        end
      end
    end
    regist_event UseGreatVengeanceFeatDamageEvent

    def use_great_vengeance_feat_const_damage()
      if @feats_enable[FEAT_GREAT_VENGEANCE]
        if @great_vengence_const_damage && @great_vengence_const_damage > 0
          attribute_party_damage(foe, get_hps(foe), @great_vengence_const_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        end
        @feats_enable[FEAT_GREAT_VENGEANCE] = false
        @great_vengence_const_damage = 0
      end
    end
    regist_event UseGreatVengeanceFeatConstDamageEvent

    # ------------------
    # 無辜の魂(無縫天衣)
    # ------------------
    # 無辜の魂が使用されたかのチェック
    def check_innocent_soul_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_INNOCENT_SOUL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_INNOCENT_SOUL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveInnocentSoulFeatEvent
    regist_event CheckAddInnocentSoulFeatEvent
    regist_event CheckRotateInnocentSoulFeatEvent

    # 無辜の魂を使用
    def finish_innocent_soul_feat()
      if @feats_enable[FEAT_INNOCENT_SOUL]
        use_feat_event(@feats[FEAT_INNOCENT_SOUL])
        @feats_enable[FEAT_INNOCENT_SOUL] = false
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(Feat.pow(@feats[FEAT_INNOCENT_SOUL])).each{ |c| @cc.owner.dealed_event(c)})
        d = Feat.pow(@feats[FEAT_INNOCENT_SOUL]) > 4 ? 3 : Feat.pow(@feats[FEAT_INNOCENT_SOUL]) - 1
        owner.damaged_event(d, IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishInnocentSoulFeatEvent

    # ------------------
    # 無謬の行い(光彩陸離)
    # ------------------

    # 無謬の行いが使用されたかのチェック
    def check_infallible_deed_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_INFALLIBLE_DEED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_INFALLIBLE_DEED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveInfallibleDeedFeatEvent
    regist_event CheckAddInfallibleDeedFeatEvent
    regist_event CheckRotateInfallibleDeedFeatEvent

    # 無謬の行いが使用される
    # 有効の場合必殺技IDを返す
    def use_infallible_deed_feat()
      if @feats_enable[FEAT_INFALLIBLE_DEED]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_INFALLIBLE_DEED])
      end
    end
    regist_event UseInfallibleDeedFeatEvent

    # 無謬の行いを使用
    def finish_infallible_deed_feat()
      if @feats_enable[FEAT_INFALLIBLE_DEED]
        if owner.move_point > foe.move_point
          # 移動方向を制御
          foe.set_direction(Entrant::DIRECTION_CHARA_CHANGE)
        end
      end
    end
    regist_event FinishInfallibleDeedFeatEvent

    # 無謬の行いを使用
    def finish_effect_infallible_deed_feat()
      if @feats_enable[FEAT_INFALLIBLE_DEED]
        use_feat_event(@feats[FEAT_INFALLIBLE_DEED])
      end
    end
    regist_event FinishEffectInfallibleDeedFeatEvent

    # 無謬の行いを使用
    def finish_chara_change_infallible_deed_feat()
      foe.chara_change_index = nil
      foe.chara_change_force = nil
    end
    regist_event FinishCharaChangeInfallibleDeedFeatEvent

    # 無謬の行いを使用
    def finish_change_infallible_deed_feat()
      if @feats_enable[FEAT_INFALLIBLE_DEED]
        if owner.move_point > foe.move_point
          hps = []
          foe.hit_points.each_index do |i|
            if foe.hit_points[i] > 0
              hps << [i, foe.hit_points[i]]
            end
          end
          foe.chara_change_index = hps.sort{ |a,b| a[1] <=> b[1] }[0][0]
          foe.chara_change_force = true
        end
      end
      @feats_enable[FEAT_INFALLIBLE_DEED] = false
    end
    regist_event FinishFoeChangeInfallibleDeedFeatEvent
    regist_event FinishOwnerChangeInfallibleDeedFeatEvent
    regist_event FinishDeadChangeInfallibleDeedFeatEvent

    # 無謬の行いを使用
    def finish_turn_infallible_deed_feat()
      if @feats_enable[FEAT_INFALLIBLE_DEED]
        @feats_enable[FEAT_INFALLIBLE_DEED] = false
      end
    end
    regist_event FinishTurnInfallibleDeedFeatEvent

    # ------------------
    # 無為の運命(転生輪廻)
    # ------------------
    # 無為の運命が使用されたかのチェック
    def check_idle_fate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_IDLE_FATE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_IDLE_FATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIdleFateFeatEvent
    regist_event CheckAddIdleFateFeatEvent
    regist_event CheckRotateIdleFateFeatEvent

    # 無為の運命が使用される
    # 有効の場合必殺技IDを返す
    def use_idle_fate_feat()
      if @feats_enable[FEAT_IDLE_FATE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_IDLE_FATE])
      end
    end
    regist_event UseIdleFateFeatEvent

    # 無為の運命が使用終了
    def finish_idle_fate_feat()
      if @feats_enable[FEAT_IDLE_FATE]
        use_feat_event(@feats[FEAT_IDLE_FATE])
      end
    end
    regist_event FinishIdleFateFeatEvent

    # 無為の運命が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_idle_fate_feat_damage()
      if @feats_enable[FEAT_IDLE_FATE]
        if duel.tmp_damage >= foe.hit_point
          foe.cards_max = foe.cards_max - 1
        end
        @feats_enable[FEAT_IDLE_FATE] = false
      end
    end
    regist_event UseIdleFateFeatDamageEvent

    # ------------------
    # 無念の裁き(往生極楽)
    # ------------------
    # 無念の裁きが使用されたかのチェック
    def check_regrettable_judgment_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_REGRETTABLE_JUDGMENT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_REGRETTABLE_JUDGMENT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRegrettableJudgmentFeatEvent
    regist_event CheckAddRegrettableJudgmentFeatEvent
    regist_event CheckRotateRegrettableJudgmentFeatEvent

    # 無念の裁きが使用される
    # 有効の場合必殺技IDを返す
    def use_regrettable_judgment_feat()
    end
    regist_event UseRegrettableJudgmentFeatEvent


    # 無念の裁きが使用終了
    def finish_regrettable_judgment_feat()
      if @feats_enable[FEAT_REGRETTABLE_JUDGMENT]
        use_feat_event(@feats[FEAT_REGRETTABLE_JUDGMENT])
      end
    end
    regist_event FinishRegrettableJudgmentFeatEvent

    # 無念の裁きが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_regrettable_judgment_feat_damage()
      if @feats_enable[FEAT_REGRETTABLE_JUDGMENT]
        # HPがマイナスで1度だけ発動
        if duel.tmp_damage >= @cc.owner.hit_point
          d = attribute_damage(ATTRIBUTE_DEATH,duel.first_entrant)
          duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_SPECIAL_COUNTER, duel.first_entrant, d))
        end
      end
      @feats_enable[FEAT_REGRETTABLE_JUDGMENT] = false
    end
    regist_event UseRegrettableJudgmentFeatDamageEvent


    # ------------------
    # 罪業の蠢き
    # ------------------
    # 罪業の蠢きが使用されたかのチェック
    def check_sin_wriggle_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SIN_WRIGGLE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SIN_WRIGGLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSinWriggleFeatEvent
    regist_event CheckAddSinWriggleFeatEvent
    regist_event CheckRotateSinWriggleFeatEvent

    # 罪業の蠢きが使用される
    # 有効の場合必殺技IDを返す
    def use_sin_wriggle_feat()
      if @feats_enable[FEAT_SIN_WRIGGLE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SIN_WRIGGLE])
      end
    end
    regist_event UseSinWriggleFeatEvent

    # 罪業の蠢きが使用終了
    def finish_sin_wriggle_feat()
      if @feats_enable[FEAT_SIN_WRIGGLE]
        use_feat_event(@feats[FEAT_SIN_WRIGGLE])
      end
    end
    regist_event FinishSinWriggleFeatEvent

    # 罪業の蠢きが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_sin_wriggle_feat_damage()
      if @feats_enable[FEAT_SIN_WRIGGLE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          # 対戦相手のイベントカードを腐らせる
          duel.get_event_deck(foe).replace_event_cards(USELESS_EVENT_CARD_ID,duel.tmp_damage)
        end
        @feats_enable[FEAT_SIN_WRIGGLE] = false
      end
    end
    regist_event UseSinWriggleFeatDamageEvent


    # ------------------
    # 懶惰の呻き
    # ------------------
    # 懶惰の呻きが使用されたかのチェック
    def check_idle_groan_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_IDLE_GROAN)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_IDLE_GROAN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveIdleGroanFeatEvent
    regist_event CheckAddIdleGroanFeatEvent
    regist_event CheckRotateIdleGroanFeatEvent

    # 必殺技の状態
    def use_idle_groan_feat()
      if @feats_enable[FEAT_IDLE_GROAN]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_IDLE_GROAN])
      end
    end
    regist_event UseIdleGroanFeatEvent

    # 懶惰の呻きが使用される
    def finish_idle_groan_feat()
      if @feats_enable[FEAT_IDLE_GROAN]
        use_feat_event(@feats[FEAT_IDLE_GROAN])
      end
    end
    regist_event FinishIdleGroanFeatEvent

    # 懶惰の呻きが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_idle_groan_feat_damage()
      if @feats_enable[FEAT_IDLE_GROAN]
        power = Feat.pow(@feats[FEAT_IDLE_GROAN]) == 10 ? 7 : 5
        if (duel.deck.size % 2) == 1
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], power, 3)
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        else
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], power, 3)
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        end
        @feats_enable[FEAT_IDLE_GROAN] = false
      end
    end
    regist_event UseIdleGroanFeatDamageEvent

    # 懶惰の呻きを使用
    def finish_turn_idle_groan_feat()
      if @feats_enable[FEAT_IDLE_GROAN]
        @feats_enable[FEAT_IDLE_GROAN] = false
      end
    end
    regist_event FinishTurnIdleGroanFeatEvent

    # ------------------
    # 汚濁の囁き
    # ------------------

    # 汚濁の囁きが使用されたかのチェック
    def check_contamination_sorrow_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CONTAMINATION_SORROW)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CONTAMINATION_SORROW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveContaminationSorrowFeatEvent
    regist_event CheckAddContaminationSorrowFeatEvent
    regist_event CheckRotateContaminationSorrowFeatEvent

    # 汚濁の囁きを使用
    def finish_contamination_sorrow_feat()
      if @feats_enable[FEAT_CONTAMINATION_SORROW]
        @feats_enable[FEAT_CONTAMINATION_SORROW] = false
        use_feat_event(@feats[FEAT_CONTAMINATION_SORROW])
        num = (((owner.cards.count - foe.cards.count).abs+1) / 2).to_i
        cards_num_before = foe.cards.size
        if owner.cards.count < foe.cards.count
          # 相手のカードを奪う
          num.times do
            steal_deal(foe.cards[rand(foe.cards.size)])
          end
        elsif owner.cards.count > foe.cards.count
          # 相手にカードを与える
          num.times do
            foe.current_chara_card.steal_deal(owner.cards[rand(owner.cards.size)])
          end
        end
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, num)) if cards_num_before != foe.cards.size
      end
    end
    regist_event FinishContaminationSorrowFeatEvent


    # ------------------
    # 蹉跌の犇めき
    # ------------------

    # 蹉跌の犇めきが使用されたかのチェック
    def check_failure_groan_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FAILURE_GROAN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FAILURE_GROAN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFailureGroanFeatEvent
    regist_event CheckAddFailureGroanFeatEvent
    regist_event CheckRotateFailureGroanFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_failure_groan_feat()
    end
    regist_event UseFailureGroanFeatEvent


    # 蹉跌の犇めきが使用終了される
    def finish_failure_groan_feat()
      if @feats_enable[FEAT_FAILURE_GROAN]
        @feats_enable[FEAT_FAILURE_GROAN] = false
        use_feat_event(@feats[FEAT_FAILURE_GROAN])
        dmg = Feat.pow(@feats[FEAT_FAILURE_GROAN]) - duel.deck.size
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
    end
    regist_event FinishFailureGroanFeatEvent


    # ------------------
    # 大聖堂
    # ------------------

    # 大聖堂が使用されたかのチェック
    def check_cathedral_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CATHEDRAL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CATHEDRAL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCathedralFeatEvent
    regist_event CheckAddCathedralFeatEvent
    regist_event CheckRotateCathedralFeatEvent

    # 大聖堂が使用
    def use_cathedral_feat()
      if @feats_enable[FEAT_CATHEDRAL]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_CATHEDRAL])
      end
    end
    regist_event UseCathedralFeatEvent

    # 大聖堂が使用終了される
    def finish_cathedral_feat()
      if @feats_enable[FEAT_CATHEDRAL]
        @feats_enable[FEAT_CATHEDRAL] = false
        use_feat_event(@feats[FEAT_CATHEDRAL])
        # １回目のダイスを振ってダメージを保存
        rec_damage = duel.tmp_damage
        rec_dice_heads_atk = duel.tmp_dice_heads_atk
        # ダメージ計算をもう１度実行
        foe.dice_roll_event(duel.battle_result)
        # ダメージが小さいほう結果を適用
        if duel.tmp_damage > rec_damage
          duel.tmp_damage = rec_damage
          duel.tmp_dice_heads_atk = rec_dice_heads_atk
        end
      end
    end
    regist_event FinishCathedralFeatEvent

    # ------------------
    # 冬の夢
    # ------------------
    # 冬の夢が使用されたかのチェック
    def check_winter_dream_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WINTER_DREAM)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_WINTER_DREAM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWinterDreamFeatEvent
    regist_event CheckAddWinterDreamFeatEvent
    regist_event CheckRotateWinterDreamFeatEvent

    # 必殺技の状態
    def use_winter_dream_feat()
      if @feats_enable[FEAT_WINTER_DREAM]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_WINTER_DREAM])
      end
    end
    regist_event UseWinterDreamFeatEvent

    # 冬の夢が使用される
    def finish_winter_dream_feat()
      if @feats_enable[FEAT_WINTER_DREAM]
        use_feat_event(@feats[FEAT_WINTER_DREAM])
      end
    end
    regist_event FinishWinterDreamFeatEvent

    # 冬の夢が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_winter_dream_feat_damage()
      if @feats_enable[FEAT_WINTER_DREAM]
        # 自身のイベントカードを強化
        replace_num = Feat.pow(@feats[FEAT_WINTER_DREAM]) == 10 ? 3 : 2
        duel.get_event_deck(owner).replace_event_cards(S5A5_EVENT_CARD_ID,replace_num)
        @feats_enable[FEAT_WINTER_DREAM] = false
      end
    end
    regist_event UseWinterDreamFeatDamageEvent

    # ------------------
    # 夜はやさし
    # ------------------
    # 夜はやさしが使用されたかのチェック
    def check_tender_night_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TENDER_NIGHT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TENDER_NIGHT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveTenderNightFeatEvent
    regist_event CheckAddTenderNightFeatEvent
    regist_event CheckRotateTenderNightFeatEvent

    # 夜はやさしを使用
    def finish_tender_night_feat()
      if @feats_enable[FEAT_TENDER_NIGHT]
        use_feat_event(@feats[FEAT_TENDER_NIGHT])
        @feats_enable[FEAT_TENDER_NIGHT] = false
        replace_num = Feat.pow(@feats[FEAT_TENDER_NIGHT]) == 2 ? 3 : 1
        duel.get_event_deck(owner).replace_event_cards(HP5_EVENT_CARD_ID,replace_num)
        owner.healed_event(1)
      end
    end
    regist_event FinishTenderNightFeatEvent

    # ------------------
    # しあわせの理由
    # ------------------
    # しあわせの理由が使用されたかのチェック
    def check_fortunate_reason_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FORTUNATE_REASON)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FORTUNATE_REASON)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFortunateReasonFeatEvent
    regist_event CheckAddFortunateReasonFeatEvent
    regist_event CheckRotateFortunateReasonFeatEvent

    # しあわせの理由を使用
    def finish_fortunate_reason_feat()
      if @feats_enable[FEAT_FORTUNATE_REASON]
        use_feat_event(@feats[FEAT_FORTUNATE_REASON])
        @feats_enable[FEAT_FORTUNATE_REASON] = false
        duel.get_event_deck(owner).replace_event_cards(CHANCE5_EVENT_CARD_ID,Feat.pow(@feats[FEAT_FORTUNATE_REASON]))
        owner.cards_max = owner.cards_max - 1 if owner.cards_max > 1
      end
    end
    regist_event FinishFortunateReasonFeatEvent

    # ------------------
    # RudNum
    # ------------------

    # RudNumが使用されたかのチェック
    def check_rud_num_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RUD_NUM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RUD_NUM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRudNumFeatEvent
    regist_event CheckAddRudNumFeatEvent
    regist_event CheckRotateRudNumFeatEvent

    # RudNumが使用される
    # 有効の場合必殺技IDを返す
    def use_rud_num_feat()
      if @feats_enable[FEAT_RUD_NUM]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_RUD_NUM])
      end
    end
    regist_event UseRudNumFeatEvent

    # RudNumが使用終了
    def finish_rud_num_feat()
      if @feats_enable[FEAT_RUD_NUM]
        @feats_enable[FEAT_RUD_NUM] = false
        use_feat_event(@feats[FEAT_RUD_NUM])
        @cc.owner.move_action(2)
        @cc.foe.move_action(2)
      end
    end
    regist_event FinishRudNumFeatEvent

    # ------------------
    # von541
    # ------------------
    # von541が使用されたかのチェック
    def check_von_num_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_VON_NUM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_VON_NUM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveVonNumFeatEvent
    regist_event CheckAddVonNumFeatEvent
    regist_event CheckRotateVonNumFeatEvent

    # von541が使用される
    # 有効の場合必殺技IDを返す
    def use_von_num_feat()
      if @feats_enable[FEAT_VON_NUM]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_VON_NUM])
      end
    end
    regist_event UseVonNumFeatEvent

    # von541が使用終了
    def finish_von_num_feat()
      if @feats_enable[FEAT_VON_NUM]
        use_feat_event(@feats[FEAT_VON_NUM])
      end
    end
    regist_event FinishVonNumFeatEvent

    # von541が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_von_num_feat_damage()
      if @feats_enable[FEAT_VON_NUM]
        damage_line = Feat.pow(@feats[FEAT_VON_NUM]) == 6 ? 8 : 10
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage >= damage_line
          foe.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION,foe,duel.tmp_damage))
          duel.tmp_damage = 0
        end
        @feats_enable[FEAT_VON_NUM] = false
      end
    end
    regist_event UseVonNumFeatDamageEvent


    # ------------------
    # ChrNum
    # ------------------

    # ChrNumが使用されたかのチェック
    def check_chr_num_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CHR_NUM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CHR_NUM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveChrNumFeatEvent
    regist_event CheckAddChrNumFeatEvent
    regist_event CheckRotateChrNumFeatEvent

    # ChrNumが使用される
    # 有効の場合必殺技IDを返す
    def use_chr_num_feat()
      if @feats_enable[FEAT_CHR_NUM]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CHR_NUM])
      end
    end
    regist_event UseChrNumFeatEvent

    # 吸収するステータス
    DRAIN_STATE_SET = [[STATE_ATK_UP,STATE_ATK_DOWN,3],
                       [STATE_DEF_UP,STATE_DEF_DOWN,3],
                       [STATE_MOVE_UP,STATE_MOVE_DOWN,1]]

    # ChrNumが使用終了
    def finish_chr_num_feat()
      if @feats_enable[FEAT_CHR_NUM]
        @feats_enable[FEAT_CHR_NUM] = false
        ds = DRAIN_STATE_SET[rand(3)]
        use_feat_event(@feats[FEAT_CHR_NUM])
        set_state(owner.current_chara_card.status[ds[0]], ds[2], 5);
        on_buff_event(true, owner.current_chara_card_no, ds[0], owner.current_chara_card.status[ds[0]][0], owner.current_chara_card.status[ds[0]][1])
        buffed = set_state(foe.current_chara_card.status[ds[1]], ds[2], 5);
        on_buff_event(false, foe.current_chara_card_no, ds[1], foe.current_chara_card.status[ds[1]][0], foe.current_chara_card.status[ds[1]][1]) if buffed
      end
    end
    regist_event FinishChrNumFeatEvent

    # ------------------
    # WilNum
    # ------------------

    # WilNumが使用されたかのチェック
    def check_wil_num_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WIL_NUM)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_WIL_NUM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWilNumFeatEvent
    regist_event CheckAddWilNumFeatEvent
    regist_event CheckRotateWilNumFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_wil_num_feat()
    end
    regist_event UseWilNumFeatEvent
    # 吸収するステータス
    POWER_UP_STATE_SET = [STATE_ATK_UP,STATE_ATK_DOWN,STATE_DEF_UP,STATE_DEF_DOWN,STATE_MOVE_UP,STATE_MOVE_DOWN]

    # WilNumが使用終了される
    def finish_wil_num_feat()
      if @feats_enable[FEAT_WIL_NUM]
        @feats_enable[FEAT_WIL_NUM] = false
        use_feat_event(@feats[FEAT_WIL_NUM])
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_WIL_NUM])))

        # 状態異常を強化
        POWER_UP_STATE_SET.each do |p|
          if owner.current_chara_card.status[p][1] > 0
            set_state(owner.current_chara_card.status[p], 9, owner.current_chara_card.status[p][1]);
            on_buff_event(true, owner.current_chara_card_no, p, owner.current_chara_card.status[p][0], owner.current_chara_card.status[p][1])
          end
          if foe.current_chara_card.status[p][1] > 0
            buffed = set_state(foe.current_chara_card.status[p], 9, foe.current_chara_card.status[p][1]);
            on_buff_event(false, foe.current_chara_card_no, p, foe.current_chara_card.status[p][0], foe.current_chara_card.status[p][1]) if buffed
          end
        end
      end
    end
    regist_event FinishWilNumFeatEvent

    # ------------------
    # クトネシリカ(フォイルニスゼーレ)
    # ------------------
    # クトネシリカが使用されたかのチェック
    def check_kutunesirka_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KUTUNESIRKA)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_KUTUNESIRKA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKutunesirkaFeatEvent
    regist_event CheckAddKutunesirkaFeatEvent
    regist_event CheckRotateKutunesirkaFeatEvent

    # 必殺技の状態
    def use_kutunesirka_feat()
      if @feats_enable[FEAT_KUTUNESIRKA]
        @cc.owner.tmp_power +=Feat.pow(@feats[FEAT_KUTUNESIRKA])
      end
    end
    regist_event UseKutunesirkaFeatEvent

    # クトネシリカが使用終了
    def finish_kutunesirka_feat()
      if @feats_enable[FEAT_KUTUNESIRKA]
        use_feat_event(@feats[FEAT_KUTUNESIRKA])
      end
    end
    regist_event FinishKutunesirkaFeatEvent

    # クトネシリカが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_kutunesirka_feat_damage()
      if @feats_enable[FEAT_KUTUNESIRKA]
        turn = Feat.pow(@feats[FEAT_KUTUNESIRKA]) > 6 ? 5 : 3
        buffed = set_state(foe.current_chara_card.status[STATE_BIND], 1, turn);
        on_buff_event(false, foe.current_chara_card_no, STATE_BIND, foe.current_chara_card.status[STATE_BIND][0], foe.current_chara_card.status[STATE_BIND][1]) if buffed
        @feats_enable[FEAT_KUTUNESIRKA] = false
      end
    end
    regist_event UseKutunesirkaFeatDamageEvent


    # ------------------
    # ヘルメスの靴(ドゥンケルハイト)
    # ------------------
    # ヘルメスの靴が使用されたかのチェック
  def check_feet_of_hermes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FEET_OF_HERMES)
      # テーブルにアクションカードがおかれていてかつ、距離が中・遠距離の時
      check_feat(FEAT_FEET_OF_HERMES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFeetOfHermesFeatEvent
    regist_event CheckAddFeetOfHermesFeatEvent
    regist_event CheckRotateFeetOfHermesFeatEvent

    # ヘルメスの靴が使用される
    # 有効の場合必殺技IDを返す
    def use_feet_of_hermes_feat()
      if @feats_enable[FEAT_FEET_OF_HERMES]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_FEET_OF_HERMES])
      end
    end
    regist_event UseFeetOfHermesFeatEvent

    #ヘルメスの靴が使用される
    # 有効の場合必殺技IDを返す
    def use_feet_of_hermes_feat_damage()
      if @feats_enable[FEAT_FEET_OF_HERMES]
        use_feat_event(@feats[FEAT_FEET_OF_HERMES])
        @feats_enable[FEAT_FEET_OF_HERMES] = false
        if Feat.pow(@feats[FEAT_FEET_OF_HERMES]) == 9 && foe.current_chara_card.status[STATE_BIND][1] > 0
          foe.current_chara_card.status[STATE_BIND][0] += 1
        end
        @cc.owner.move_action(-3)
        @cc.foe.move_action(-3)
        if Feat.pow(@feats[FEAT_FEET_OF_HERMES]) == 9 && foe.current_chara_card.status[STATE_BIND][1] > 0
          foe.current_chara_card.status[STATE_BIND][0] -= 1
        end
      end
    end
    regist_event UseFeetOfHermesFeatDamageEvent

    # ------------------
    # イージスの翼(シャッテンフリューゲル)
    # ------------------
    # イージスの翼が使用されたかのチェック
    def check_aegis_wing_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_AEGIS_WING)
      # テーブルにアクションカードがおかれていてかつ、距離が近・中距離の時
      check_feat(FEAT_AEGIS_WING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAegisWingFeatEvent
    regist_event CheckAddAegisWingFeatEvent
    regist_event CheckRotateAegisWingFeatEvent

    # イージスの翼が使用される
    # 有効の場合必殺技IDを返す
    def use_aegis_wing_feat()
      if @feats_enable[FEAT_AEGIS_WING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_AEGIS_WING])
      end
    end
    regist_event UseAegisWingFeatEvent

    # イージスの翼の使用を終了
    # 有効の場合必殺技IDを返す
    def finish_aegis_wing_feat()
      if @feats_enable[FEAT_AEGIS_WING]
        use_feat_event(@feats[FEAT_AEGIS_WING])
      end
    end
    regist_event FinishAegisWingFeatEvent

    # イージスの翼で防御成功した場合HP+1
    # 有効の場合必殺技IDを返す
    def use_aegis_wing_feat_damage()
      if @feats_enable[FEAT_AEGIS_WING]
        @cc.owner.move_action(2)
        @cc.foe.move_action(2)
        # ダメージが0以下(防御成功)のときに回復処理
        if duel.tmp_damage < 1
          # 回復処理
          heal_pt = Feat.pow(@feats[FEAT_AEGIS_WING]) == 9 ? 2 : 1
          @cc.owner.healed_event(heal_pt)
        end
        @feats_enable[FEAT_AEGIS_WING] = false
      end
    end
    regist_event UseAegisWingFeatDamageEvent

    # ------------------
    # クラウ・ソラウ(ヴィルベルリッテル)
    # ------------------
    # クラウ・ソラウが使用されたかのチェック
    def check_claiomh_solais_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CLAIOMH_SOLAIS)
      # テーブルにアクションカードがおかれていてかつ、距離が遠距離の時
      check_feat(FEAT_CLAIOMH_SOLAIS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveClaiomhSolaisFeatEvent
    regist_event CheckAddClaiomhSolaisFeatEvent
    regist_event CheckRotateClaiomhSolaisFeatEvent

    # クラウ・ソラウが使用される
    def use_claiomh_solais_feat()
      if @feats_enable[FEAT_CLAIOMH_SOLAIS]
        p = Feat.pow(@feats[FEAT_CLAIOMH_SOLAIS])
        p += (Feat.pow(@feats[FEAT_CLAIOMH_SOLAIS]) / 8 + 4) * @cc.owner.get_type_table_count(ActionCard::SWD)
        @cc.owner.tmp_power += p
      end
    end
    regist_event UseClaiomhSolaisFeatEvent

    # クラウ・ソラウが使用終了される
    def finish_claiomh_solais_feat()
      if @feats_enable[FEAT_CLAIOMH_SOLAIS]
        @feats_enable[FEAT_CLAIOMH_SOLAIS] = false
        use_feat_event(@feats[FEAT_CLAIOMH_SOLAIS])
      end
    end
    regist_event FinishClaiomhSolaisFeatEvent


    # ------------------
    # 細胞変異
    # ------------------

    # 細胞変異が使用されたかのチェック
    def check_mutation_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MUTATION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MUTATION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMutationFeatEvent
    regist_event CheckAddMutationFeatEvent
    regist_event CheckRotateMutationFeatEvent

    def use_mutation_feat()
      if @feats_enable[FEAT_MUTATION]
        p = Feat.pow(@feats[FEAT_MUTATION])
        p = 2 if p > 2
        @cc.owner.tmp_power += p
      end
    end
    regist_event UseMutationFeatEvent

    def finish_mutation_feat
      if @feats_enable[FEAT_MUTATION]
        p = Feat.pow(@feats[FEAT_MUTATION])
        p = 2 if p > 2
        @cc.owner.tmp_power += p
        owner.mp_calc_resolve
        foe.mp_calc_resolve
      end
    end
    regist_event FinishMutationFeatEvent

    # 細胞変異を使用
    def finish_effect_mutation_feat
      if @feats_enable[FEAT_MUTATION]
        use_feat_event(@feats[FEAT_MUTATION])
        rand_num = 1 + rand(2)
        rand_num = 2 if Feat.pow(@feats[FEAT_MUTATION]) > 2
        @feats_enable[FEAT_MUTATION] = false
        if @cc.status[STATE_STATE_DOWN][1] > 0
          @cc.status[STATE_STATE_DOWN][1] += rand_num
          @cc.status[STATE_STATE_DOWN][1] = 9 if @cc.status[STATE_STATE_DOWN][1] > 9
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        else
          set_state(@cc.status[STATE_STATE_DOWN], 1, rand_num)
          on_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0], @cc.status[STATE_STATE_DOWN][1])
        end
      end
    end
    regist_event FinishEffectMutationFeatEvent

    # ------------------
    # 指嗾する仔
    # ------------------
    # 指嗾する仔が使用されたかのチェック
    def check_rampancy_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_RAMPANCY)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RAMPANCY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRampancyFeatEvent
    regist_event CheckAddRampancyFeatEvent
    regist_event CheckRotateRampancyFeatEvent

    # 指嗾する仔が使用終了
    def use_rampancy_feat_damage()
      if @feats_enable[FEAT_RAMPANCY]
        use_feat_event(@feats[FEAT_RAMPANCY])
      end
    end
    regist_event UseRampancyFeatDamageEvent

    # 指嗾する仔が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def finish_rampancy_feat()
      if @feats_enable[FEAT_RAMPANCY]
        dmg = owner.current_hit_point_max - duel.tmp_dice_heads_atk
        dmg = 0 if dmg < 0
        if @cc.status[STATE_UNDEAD][1] > 0
          foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, ((dmg+Feat.pow(@feats[FEAT_RAMPANCY]))/2).to_i))
        else
          duel.tmp_damage = foe.tmp_power > 0 ? dmg : owner.hit_point - 1
        end
        @feats_enable[FEAT_RAMPANCY] = false
      end
    end
    regist_event FinishRampancyFeatEvent

    # ------------------
    # 魂魄の贄
    # ------------------
    # 魂魄の贄が使用されたかのチェック
    def check_sacrifice_of_soul_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SACRIFICE_OF_SOUL)
      # 使用条件のチェック
      check_feat(FEAT_SACRIFICE_OF_SOUL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSacrificeOfSoulFeatEvent
    regist_event CheckAddSacrificeOfSoulFeatEvent
    regist_event CheckRotateSacrificeOfSoulFeatEvent

    # 魂魄の贄が使用される
    # 有効の場合必殺技IDを返す
    def use_sacrifice_of_soul_feat()
      if @feats_enable[FEAT_SACRIFICE_OF_SOUL]
         @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SACRIFICE_OF_SOUL])
      end
    end
    regist_event UseSacrificeOfSoulFeatEvent

    def use_sacrifice_of_soul_feat_heal()
      if @feats_enable[FEAT_SACRIFICE_OF_SOUL]
        if @cc.status[STATE_UNDEAD][1] < 1
          @cc.owner.healed_event(2)
        end
      end
    end
    regist_event UseSacrificeOfSoulFeatHealEvent

    # 魂魄の贄が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_sacrifice_of_soul_feat_damage()
      if @feats_enable[FEAT_SACRIFICE_OF_SOUL]
        use_feat_event(@feats[FEAT_SACRIFICE_OF_SOUL])
        duel.tmp_damage = attribute_damage(ATTRIBUTE_DIFF, foe, duel.tmp_dice_heads_atk * 2)
        down_point = @cc.status[STATE_STATE_DOWN][1]

        rand_num = rand(100)
        if rand_num < down_point*10
          @cc.status[STATE_STATE_DOWN][1] = 0
          off_buff_event(true, owner.current_chara_card_no, STATE_STATE_DOWN, @cc.status[STATE_STATE_DOWN][0])

          if foe.current_chara_card.status[STATE_STATE_DOWN][1] > 0
            buffed = set_state(foe.current_chara_card.status[STATE_STATE_DOWN], 1, foe.current_chara_card.status[STATE_STATE_DOWN][1]+down_point)
            on_buff_event(false, foe.current_chara_card_no, STATE_STATE_DOWN, foe.current_chara_card.status[STATE_STATE_DOWN][0], foe.current_chara_card.status[STATE_STATE_DOWN][1]) if buffed
          else
            buffed = set_state(foe.current_chara_card.status[STATE_STATE_DOWN], 1, down_point)
            on_buff_event(false, foe.current_chara_card_no, STATE_STATE_DOWN, foe.current_chara_card.status[STATE_STATE_DOWN][0], foe.current_chara_card.status[STATE_STATE_DOWN][1]) if buffed
          end

        end

        @feats_enable[FEAT_SACRIFICE_OF_SOUL] = false
      end
    end
    regist_event UseSacrificeOfSoulFeatDamageEvent

    # ------------------
    # 銀の弾丸
    # ------------------
    # 銀の弾丸が使用されたかのチェック
    def check_silver_bullet_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SILVER_BULLET)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SILVER_BULLET)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSilverBulletFeatEvent
    regist_event CheckAddSilverBulletFeatEvent
    regist_event CheckRotateSilverBulletFeatEvent


    # 銀の弾丸が使用終了
    def finish_silver_bullet_feat()
      if @feats_enable[FEAT_SILVER_BULLET]
        @feats_enable[FEAT_SILVER_BULLET] = false
        use_feat_event(@feats[FEAT_SILVER_BULLET])
        owner.damaged_event(3,IS_NOT_HOSTILE_DAMAGE)
        set_state(@cc.status[STATE_UNDEAD], 1, Feat.pow(@feats[FEAT_SILVER_BULLET]));
        on_buff_event(true, owner.current_chara_card_no, STATE_UNDEAD, @cc.status[STATE_UNDEAD][0], @cc.status[STATE_UNDEAD][1])
      end
    end
    regist_event FinishSilverBulletFeatEvent

    # ------------------
    # かぼちゃ落とし
    # ------------------
    # かぼちゃ落としが使用されたかのチェック
    def check_pumpkin_drop_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PUMPKIN_DROP)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PUMPKIN_DROP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePumpkinDropFeatEvent
    regist_event CheckAddPumpkinDropFeatEvent
    regist_event CheckRotatePumpkinDropFeatEvent

    # かぼちゃ落としが使用される
    # 有効の場合必殺技IDを返す
    def use_pumpkin_drop_feat()
      if @feats_enable[FEAT_PUMPKIN_DROP]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PUMPKIN_DROP])
        # 素数ターンで攻撃力増加
        if [2,3,5,7,11,13,17].include?(duel.turn)
          @cc.owner.tmp_power += duel.turn
        end
      end
    end
    regist_event UsePumpkinDropFeatEvent

    # かぼちゃ落としが使用終了
    def finish_pumpkin_drop_feat()
      if @feats_enable[FEAT_PUMPKIN_DROP]
        use_feat_event(@feats[FEAT_PUMPKIN_DROP])
      end
    end
    regist_event FinishPumpkinDropFeatEvent

    # かぼちゃ落としが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_pumpkin_drop_feat_damage()
      if @feats_enable[FEAT_PUMPKIN_DROP]
        # 素数ターンでPTダメージ
        pumpkin_drop_const_actuated = [2,3,5,7,11,13,17].include?(duel.turn) && duel.tmp_damage > 0
        @pumpkin_drop_const_damage = pumpkin_drop_const_actuated ? (((duel.second_entrant.current_hit_point<duel.tmp_damage ? duel.second_entrant.current_hit_point : duel.tmp_damage)+1)/2).to_i : 0
      end
    end
    regist_event UsePumpkinDropFeatDamageEvent

    def use_pumpkin_drop_feat_const_damage()
      if @feats_enable[FEAT_PUMPKIN_DROP]
        if @pumpkin_drop_const_damage > 0
          attribute_party_damage(foe,get_hps(foe),@pumpkin_drop_const_damage,ATTRIBUTE_CONSTANT,TARGET_TYPE_ALL)
        end
        @feats_enable[FEAT_PUMPKIN_DROP] = false
      end
    end
    regist_event UsePumpkinDropFeatConstDamageEvent

    # ------------------
    # 彷徨う羽(ドリームステッキ)
    # ------------------
    # 彷徨う羽が使用されたかのチェック
    def check_wandering_feather_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WANDERING_FEATHER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_WANDERING_FEATHER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWanderingFeatherFeatEvent
    regist_event CheckAddWanderingFeatherFeatEvent
    regist_event CheckRotateWanderingFeatherFeatEvent

    # 彷徨う羽が使用される
    # 有効の場合必殺技IDを返す
    def use_wandering_feather_feat()
      if @feats_enable[FEAT_WANDERING_FEATHER]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_WANDERING_FEATHER])
      end
    end
    regist_event UseWanderingFeatherFeatEvent

    # 彷徨う羽が使用終了
    def finish_wandering_feather_feat()
      if @feats_enable[FEAT_WANDERING_FEATHER]
        if duel.tmp_damage < 1
          down_point = Feat.pow(@feats[FEAT_WANDERING_FEATHER]) < 5 ? 3 : Feat.pow(@feats[FEAT_WANDERING_FEATHER])
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], down_point, 3)
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        end

        @feats_enable[FEAT_WANDERING_FEATHER] = false
      end
    end
    regist_event FinishWanderingFeatherFeatEvent

    def cutin_wandering_feather_feat
      if @feats_enable[FEAT_WANDERING_FEATHER]
        use_feat_event(@feats[FEAT_WANDERING_FEATHER])
        # 確率でダイスを倍化
        rand_num = rand(100)
        multi_num = 1
        if rand_num < Feat.pow(@feats[FEAT_WANDERING_FEATHER]) * 2
          multi_num = 4
        elsif rand_num < Feat.pow(@feats[FEAT_WANDERING_FEATHER]) * 8
          multi_num = 2
        end
        owner.tmp_power *= multi_num
        case multi_num
        when 2
          owner.special_message_event(:DREAM_STICK_X2)
        when 3
          owner.special_message_event(:DREAM_STICK_X3)
        when 4
          owner.special_message_event(:DREAM_STICK_X4)
        when 6
          owner.special_message_event(:DREAM_STICK_X6)
        end
      end
    end
    regist_event CutinWanderingFeatherFeatEvent

    # ------------------
    # ひつじ数え歌(彷徨う羽)
    # ------------------
    # ひつじ数え歌が使用されたかのチェック
    def check_sheep_song_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SHEEP_SONG)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SHEEP_SONG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSheepSongFeatEvent
    regist_event CheckAddSheepSongFeatEvent
    regist_event CheckRotateSheepSongFeatEvent

    # ひつじ数え歌が使用される
    # 有効の場合必殺技IDを返す
    def use_sheep_song_feat()
      if @feats_enable[FEAT_SHEEP_SONG]
        @cc.owner.tmp_power+= Feat.pow(@feats[FEAT_SHEEP_SONG]) < 5 ? 0 : 3
      end
    end
    regist_event UseSheepSongFeatEvent

    # ひつじ数え歌が使用終了
    def finish_sheep_song_feat()
      if @feats_enable[FEAT_SHEEP_SONG]
        @cc.owner.healed_event(((Feat.pow(@feats[FEAT_SHEEP_SONG])+1)/3).to_i)
        use_feat_event(@feats[FEAT_SHEEP_SONG])
        rand_num = rand(100)
        div_num = 1
        if rand_num < Feat.pow(@feats[FEAT_SHEEP_SONG]) * 2
          div_num = 0
          duel.bp[duel.initi[0]] = 0
          foe.tmp_power = 0
          if Feat.pow(@feats[FEAT_SHEEP_SONG]) > 4
            owner.healed_event(owner.current_hit_point_max - owner.hit_point)
          end
        elsif rand_num < Feat.pow(@feats[FEAT_SHEEP_SONG]) * 8
          div_num = Feat.pow(@feats[FEAT_SHEEP_SONG]) < 5 ? 2 : 3
          foe.tmp_power = (foe.tmp_power/div_num).to_i
          duel.bp[duel.initi[0]] = foe.tmp_power
        else
          div_num = 4
          foe.tmp_power = (foe.tmp_power*2/3).to_i
          duel.bp[duel.initi[0]] = foe.tmp_power
        end

        case div_num
        when 0
          owner.special_message_event(:WANDERING_FEATHER_0)
        when 2
          owner.special_message_event(:WANDERING_FEATHER_1D2)
        when 3
          owner.special_message_event(:WANDERING_FEATHER_1D3)
        when 4
          owner.special_message_event(:WANDERING_FEATHER_2D3)
        end
        @feats_enable[FEAT_SHEEP_SONG] = false
      end
    end
    regist_event FinishSheepSongFeatEvent

    # ------------------
    # オヴェリャの夢
    # ------------------
    # オヴェリャの夢が使用されたかのチェック
    def check_dream_of_ovuerya_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DREAM_OF_OVUERYA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DREAM_OF_OVUERYA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDreamOfOvueryaFeatEvent
    regist_event CheckAddDreamOfOvueryaFeatEvent
    regist_event CheckRotateDreamOfOvueryaFeatEvent

    # オヴェリャの夢
    def finish_dream_of_ovuerya_feat()
      if @feats_enable[FEAT_DREAM_OF_OVUERYA]
        use_feat_event(@feats[FEAT_DREAM_OF_OVUERYA])
        @feats_enable[FEAT_DREAM_OF_OVUERYA] = false
        draw_card_num = owner.hit_point >= Feat.pow(@feats[FEAT_DREAM_OF_OVUERYA]) ? 4 : 2
        @cc.owner.special_dealed_event(duel.deck.draw_cards_event(draw_card_num).each{ |c| @cc.owner.dealed_event(c)})
        owner.damaged_event(1,IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishDreamOfOvueryaFeatEvent

    # ------------------
    # メリーズシープ
    # ------------------
    # メリーズシープが使用されたかのチェック
    def check_marys_sheep_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MARYS_SHEEP)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MARYS_SHEEP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMarysSheepFeatEvent
    regist_event CheckAddMarysSheepFeatEvent
    regist_event CheckRotateMarysSheepFeatEvent

    # メリーズシープが使用される
    # 有効の場合必殺技IDを返す
    def use_marys_sheep_feat()
      if @feats_enable[FEAT_MARYS_SHEEP]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_MARYS_SHEEP])
      end
    end
    regist_event UseMarysSheepFeatEvent

    # メリーズシープが使用終了
    def finish_marys_sheep_feat()
      if @feats_enable[FEAT_MARYS_SHEEP]
        use_feat_event(@feats[FEAT_MARYS_SHEEP])
      end
    end
    regist_event FinishMarysSheepFeatEvent

    # メリーズシープが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_marys_sheep_feat_damage()
      if @feats_enable[FEAT_MARYS_SHEEP]
        damage_point = owner.hit_point < 3 ? 4 : 1
        if Feat.pow(@feats[FEAT_MARYS_SHEEP]) > 4
          damage_point += 1
        end
        attribute_party_damage(foe, get_hps(foe), damage_point, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        @feats_enable[FEAT_MARYS_SHEEP] = false
      end
    end
    regist_event UseMarysSheepFeatDamageEvent

    # ------------------
    # 光り輝く邪眼
    # ------------------
    # 光り輝く邪眼が使用されたかのチェック
    def check_evil_eye_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_EVIL_EYE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_EVIL_EYE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEvilEyeFeatEvent
    regist_event CheckAddEvilEyeFeatEvent
    regist_event CheckRotateEvilEyeFeatEvent

    # 必殺技の状態
    def use_evil_eye_feat()
      if @feats_enable[FEAT_EVIL_EYE]
        @cc.owner.tmp_power +=Feat.pow(@feats[FEAT_EVIL_EYE])
      end
    end
    regist_event UseEvilEyeFeatEvent

    # 光り輝く邪眼が使用終了
    def finish_evil_eye_feat()
      if @feats_enable[FEAT_EVIL_EYE]

        use_feat_event(@feats[FEAT_EVIL_EYE])

        if Feat.pow(@feats[FEAT_EVIL_EYE]) > 5

          if foe.current_chara_card.status[STATE_CURSE][1] > 0

            buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, foe.current_chara_card.status[STATE_CURSE][1]+1);
            on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

          else

            buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, 1);
            on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

          end

        end

      end
    end
    regist_event FinishEvilEyeFeatEvent

    # 光り輝く邪眼が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_evil_eye_feat_damage()
      if @feats_enable[FEAT_EVIL_EYE]

        if duel.tmp_damage > 0
          add_pt = Feat.pow(@feats[FEAT_EVIL_EYE]) == 9 ? 2 : 1
          if foe.current_chara_card.status[STATE_CURSE][1] > 0

            buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, foe.current_chara_card.status[STATE_CURSE][1]+add_pt);
            on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

          else

            buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, add_pt);
            on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

          end

        end

        @feats_enable[FEAT_EVIL_EYE] = false
      end
    end
    regist_event UseEvilEyeFeatDamageEvent

    # ------------------
    # 超越者の邪法
    # ------------------
    # 超越者の邪法が使用されたかのチェック
    def check_black_arts_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLACK_ARTS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BLACK_ARTS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBlackArtsFeatEvent
    regist_event CheckAddBlackArtsFeatEvent
    regist_event CheckRotateBlackArtsFeatEvent

    # 超越者の邪法を使用
    def finish_black_arts_feat()
      if @feats_enable[FEAT_BLACK_ARTS]

        use_feat_event(@feats[FEAT_BLACK_ARTS])
        @feats_enable[FEAT_BLACK_ARTS] = false

        set_state(@cc.status[STATE_DEF_UP], Feat.pow(@feats[FEAT_BLACK_ARTS]), 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])

        if foe.current_chara_card.status[STATE_CURSE][1] > 0

          buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, foe.current_chara_card.status[STATE_CURSE][1]+1);
          on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

        else

          buffed = set_state(foe.current_chara_card.status[STATE_CURSE], 1, 1);
          on_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0], foe.current_chara_card.status[STATE_CURSE][1]) if buffed

        end

        alpha = Feat.pow(@feats[FEAT_BLACK_ARTS]) == 7 ? 10 : 5
        rand_num = rand(100)
        if foe.direction == 3

          foe.set_direction(Entrant::DIRECTION_PEND) if rand_num < 50 + alpha * foe.current_chara_card.status[STATE_CURSE][1]

        end
      end
    end
    regist_event FinishBlackArtsFeatEvent

    # ------------------
    # 冒涜する呪詛
    # ------------------
    # 冒涜する呪詛が使用されたかのチェック
    def check_blasphemy_curse_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLASPHEMY_CURSE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_BLASPHEMY_CURSE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlasphemyCurseFeatEvent
    regist_event CheckAddBlasphemyCurseFeatEvent
    regist_event CheckRotateBlasphemyCurseFeatEvent

    # 必殺技の状態
    def use_blasphemy_curse_feat()
      if @feats_enable[FEAT_BLASPHEMY_CURSE]
        @cc.owner.tmp_power +=Feat.pow(@feats[FEAT_BLASPHEMY_CURSE])
      end
    end
    regist_event UseBlasphemyCurseFeatEvent

    # 冒涜する呪詛が使用終了
    def finish_blasphemy_curse_feat()
      if @feats_enable[FEAT_BLASPHEMY_CURSE]
        use_feat_event(@feats[FEAT_BLASPHEMY_CURSE])
      end
    end
    regist_event FinishBlasphemyCurseFeatEvent

    # 冒涜する呪詛が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_blasphemy_curse_feat_damage()
      if @feats_enable[FEAT_BLASPHEMY_CURSE]

        pow = foe.current_chara_card.status[STATE_CURSE][1]

        if pow > 0

          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,pow))
          owner.healed_event(pow)
          foe.current_chara_card.status[STATE_CURSE][1] = 0
          off_buff_event(false, foe.current_chara_card_no, STATE_CURSE, foe.current_chara_card.status[STATE_CURSE][0])

        end

        @feats_enable[FEAT_BLASPHEMY_CURSE] = false
      end
    end
    regist_event UseBlasphemyCurseFeatDamageEvent

    # ------------------
    # 終焉の果て
    # ------------------
    # 終焉の果てが使用されたかのチェック
    def check_end_of_end_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_END_OF_END)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_END_OF_END)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEndOfEndFeatEvent
    regist_event CheckAddEndOfEndFeatEvent
    regist_event CheckRotateEndOfEndFeatEvent

    # 必殺技の状態
    def use_end_of_end_feat()
      if @feats_enable[FEAT_END_OF_END]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_END_OF_END]) + foe.current_chara_card.status[STATE_CURSE][1] * 5
      end
    end
    regist_event UseEndOfEndFeatEvent

    # 終焉の果てが使用終了
    def finish_end_of_end_feat()
      if @feats_enable[FEAT_END_OF_END]
        use_feat_event(@feats[FEAT_END_OF_END])
      end
    end
    regist_event FinishEndOfEndFeatEvent

    # 終焉の果てが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_end_of_end_feat_damage()
      if @feats_enable[FEAT_END_OF_END]
        @feats_enable[FEAT_END_OF_END] = false
      end
    end
    regist_event UseEndOfEndFeatDamageEvent

    # ------------------
    # 玉座の凱旋門
    # ------------------
    # 玉座の凱旋門が使用されたかのチェック
    def check_thrones_gate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THRONES_GATE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_THRONES_GATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThronesGateFeatEvent
    regist_event CheckAddThronesGateFeatEvent
    regist_event CheckRotateThronesGateFeatEvent

    # 必殺技の状態
    def use_thrones_gate_feat()
      if @feats_enable[FEAT_THRONES_GATE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_THRONES_GATE])
      end
    end
    regist_event UseThronesGateFeatEvent

    # 玉座の凱旋門が使用終了
    def finish_thrones_gate_feat()
      if @feats_enable[FEAT_THRONES_GATE]
        use_feat_event(@feats[FEAT_THRONES_GATE])
      end
    end
    regist_event FinishThronesGateFeatEvent

    # 玉座の凱旋門が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_thrones_gate_feat_damage()
      if @feats_enable[FEAT_THRONES_GATE]
        @feats_enable[FEAT_THRONES_GATE] = false
        foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH,foe)) if duel.turn % foe.current_chara_card.level == 0
      end
    end
    regist_event UseThronesGateFeatDamageEvent

    # ------------------
    # 幽愁暗恨
    # ------------------
    # 幽愁暗恨が使用されたかのチェック
    def check_ghost_resentment_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GHOST_RESENTMENT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GHOST_RESENTMENT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGhostResentmentFeatEvent
    regist_event CheckAddGhostResentmentFeatEvent
    regist_event CheckRotateGhostResentmentFeatEvent

    # 幽愁暗恨が使用される
    # 有効の場合必殺技IDを返す
    def use_ghost_resentment_feat()
      if @feats_enable[FEAT_GHOST_RESENTMENT]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_GHOST_RESENTMENT])
      end
    end
    regist_event UseGhostResentmentFeatEvent

    # 精密射撃が使用終了
    def finish_ghost_resentment_feat()
      if @feats_enable[FEAT_GHOST_RESENTMENT]
        use_feat_event(@feats[FEAT_GHOST_RESENTMENT])
      end
    end
    regist_event FinishGhostResentmentFeatEvent

    # 幽愁暗恨が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_ghost_resentment_feat_damage()
      if @feats_enable[FEAT_GHOST_RESENTMENT]
        # ダメージがプラスなら
        if duel.tmp_damage > 0
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], 6, Feat.pow(@feats[FEAT_GHOST_RESENTMENT]))
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], 4, Feat.pow(@feats[FEAT_GHOST_RESENTMENT]))
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
          buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, Feat.pow(@feats[FEAT_GHOST_RESENTMENT]))
          on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        end
        @feats_enable[FEAT_GHOST_RESENTMENT] = false
      end
    end
    regist_event UseGhostResentmentFeatDamageEvent

    # ------------------
    # 受け流し
    # ------------------
    # 受け流しが使用されたかのチェック
    def check_sword_avoid_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SWORD_AVOID)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SWORD_AVOID)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSwordAvoidFeatEvent
    regist_event CheckAddSwordAvoidFeatEvent
    regist_event CheckRotateSwordAvoidFeatEvent

    # 受け流しが使用される
    # 有効の場合必殺技IDを返す
    def use_sword_avoid_feat()
      if @feats_enable[FEAT_SWORD_AVOID]
      end
    end
    regist_event UseSwordAvoidFeatEvent

    # 受け流しが使用終了
    def finish_sword_avoid_feat()
      if @feats_enable[FEAT_SWORD_AVOID]
        @feats_enable[FEAT_SWORD_AVOID] = false
        use_feat_event(@feats[FEAT_SWORD_AVOID])
        duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION,foe,@sword_avoid_foe_damage)) if @sword_avoid_foe_damage
        @sword_avoid_foe_damage = 0
      end
    end
    regist_event FinishSwordAvoidFeatEvent

    # 受け流しが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_sword_avoid_feat_damage()
      if @feats_enable[FEAT_SWORD_AVOID]
        if duel.tmp_damage > 0
          owner_damage = ((duel.tmp_damage+1)/2).to_i
          @sword_avoid_foe_damage = duel.tmp_damage - owner_damage

          duel.tmp_damage = owner_damage
        end
      end
    end
    regist_event UseSwordAvoidFeatDamageEvent

    # ------------------
    # Ex呪剣
    # ------------------

    # Ex呪剣が使用されたかのチェック
    def check_curse_sword_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CURSE_SWORD)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_CURSE_SWORD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCurseSwordFeatEvent
    regist_event CheckAddCurseSwordFeatEvent
    regist_event CheckRotateCurseSwordFeatEvent

    # 必殺技の状態
    def use_curse_sword_feat()
      if @feats_enable[FEAT_CURSE_SWORD]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_CURSE_SWORD])
      end
    end
    regist_event UseCurseSwordFeatEvent

    # Ex呪剣が使用される
    def finish_curse_sword_feat()
      if @feats_enable[FEAT_CURSE_SWORD]
        use_feat_event(@feats[FEAT_CURSE_SWORD])
        set_state(@cc.status[STATE_POISON], 1, 1)
        on_buff_event(true, owner.current_chara_card_no, STATE_POISON, @cc.status[STATE_POISON][0], @cc.status[STATE_POISON][1])
      end
    end
    regist_event FinishCurseSwordFeatEvent

    # Ex呪剣が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_curse_sword_feat_damage()
      if @feats_enable[FEAT_CURSE_SWORD]
        if duel.tmp_damage>0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            if duel.second_entrant.hit_points[i] > 0
              buffed = set_state(foe.chara_cards[i].status[STATE_POISON], 1, 3)
              on_buff_event(false, i, STATE_POISON, foe.chara_cards[i].status[STATE_POISON][0], foe.chara_cards[i].status[STATE_POISON][1]) if buffed
            end
          end
        end
        @feats_enable[FEAT_CURSE_SWORD] = false
      end
    end
    regist_event UseCurseSwordFeatDamageEvent

    # ------------------
    # 怒りの一撃(復活)
    # ------------------

    # 怒りの一撃(復活)が使用されたかのチェック
    def check_anger_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ANGER_R)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ANGER_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAngerRFeatEvent
    regist_event CheckAddAngerRFeatEvent
    regist_event CheckRotateAngerRFeatEvent

    # 怒りの一撃(復活)が使用される
    def use_anger_r_feat()
      if @feats_enable[FEAT_ANGER_R]
        mod = (@cc.hp - @cc.owner.current_hit_point) * 2 + Feat.pow(@feats[FEAT_ANGER_R])
        mod_max = 99
        @cc.owner.tmp_power += (mod > mod_max)? mod_max : mod
      end
    end
    regist_event UseAngerRFeatEvent

    # 怒りの一撃(復活)が使用終了される
    def finish_anger_r_feat()
      if @feats_enable[FEAT_ANGER_R]
        @feats_enable[FEAT_ANGER_R] = false
        use_feat_event(@feats[FEAT_ANGER_R])
      end
    end
    regist_event FinishAngerRFeatEvent

    # ------------------
    # ヴォリッションディフレクト
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_volition_deflect_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_VOLITION_DEFLECT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_VOLITION_DEFLECT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveVolitionDeflectFeatEvent
    regist_event CheckAddVolitionDeflectFeatEvent
    regist_event CheckRotateVolitionDeflectFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_volition_deflect_feat()
      if @feats_enable[FEAT_VOLITION_DEFLECT]
        owner.const_damage_guard=(true)
        use_feat_event(@feats[FEAT_VOLITION_DEFLECT])
      end
    end
    regist_event UseVolitionDeflectFeatEvent

    # attribute_damageが任意のタイミングで使う
    def use_volition_deflect_feat_damage(d)
        rand_num = rand(100)
        if rand_num < 33
          owner.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION,owner,d))
        end
    end

    # 必殺技が使用終了
    def finish_volition_deflect_feat()
      if @feats_enable[FEAT_VOLITION_DEFLECT]
        owner.const_damage_guard=(false)
        @feats_enable[FEAT_VOLITION_DEFLECT] = false
      end
    end
    regist_event FinishVolitionDeflectFeatEvent
    regist_event FinishVolitionDeflectFeatDeadCharaChangeEvent


    # ------------------
    # 影撃ち(復活)
    # ------------------

    # 影撃ちが使用されたかのチェック
    def check_shadow_shot_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHAROW_SHOT_R)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SHAROW_SHOT_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShadowShotRFeatEvent
    regist_event CheckAddShadowShotRFeatEvent
    regist_event CheckRotateShadowShotRFeatEvent

    # 必殺技の状態
    def use_shadow_shot_r_feat()
      if @feats_enable[FEAT_SHAROW_SHOT_R]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SHAROW_SHOT_R]) * @cc.owner.distance
      end
    end
    regist_event UseShadowShotRFeatEvent

    # 影撃ちが使用される
    def finish_shadow_shot_r_feat()
      if @feats_enable[FEAT_SHAROW_SHOT_R]
        use_feat_event(@feats[FEAT_SHAROW_SHOT_R])
      end
    end
    regist_event FinishShadowShotRFeatEvent

    # 影撃ちが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_shadow_shot_r_feat_damage()
      if @feats_enable[FEAT_SHAROW_SHOT_R]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_SHAROW_SHOT_R] = false
      end
    end
    regist_event UseShadowShotRFeatDamageEvent

    # ------------------
    # 嚇灼の尾
    # ------------------
    # 嚇灼の尾が使用されたかのチェック
    def check_burning_tail_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BURNING_TAIL)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BURNING_TAIL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBurningTailFeatEvent
    regist_event CheckAddBurningTailFeatEvent
    regist_event CheckRotateBurningTailFeatEvent


    def use_burning_tail_feat()
      if @feats_enable[FEAT_BURNING_TAIL]
        @burning_tail_mode_pow = @cc.owner.greater_check_of_type(ActionCard::SWD, 1)
      end
    end
    regist_event UseBurningTailFeatEvent

    # 嚇灼の尾が使用される
    def finish_burning_tail_feat()
      if @feats_enable[FEAT_BURNING_TAIL]
        use_feat_event(@feats[FEAT_BURNING_TAIL])

        if foe.battle_table.size > 0

          ids = []
          feats_nums = []
          feats_index_sums = []
          powers = []

          attack_phase_feats = []

          # 相手が攻撃フェイズで使う可能性のある技を全て拾う
          foe.current_chara_card.get_feat_ids.each do |fid|
            f = Unlight::Feat[fid]
            attack_phase_feats << f.feat_no if f.caption.include?("[攻撃:")
          end

          foe.battle_table.each_with_index do |c,i|
            foe.battle_card_rotate_silence(c.id, !c.up?)
            attack_phase_feats.each do |f|
              foe.reset_feat_on_cards(f)
              foe.current_chara_card.check_feat_bg(f)
            end
            foe.point_check_silence(Entrant::POINT_CHECK_BATTLE)
            now_on_feats = foe.current_chara_card.get_enable_feats

            ids << c.id

            feats_nums << now_on_feats.length

            feats_index_sum_tmp = 0
            now_on_feats.each do |key, value|
              attack_phase_feats.each_with_index do |a,i|
                feats_index_sum_tmp += i if a == key.to_i
              end
            end
            feats_index_sums << feats_index_sum_tmp

            powers << foe.tmp_power

            foe.battle_card_rotate_silence(c.id, !c.up?)

          end

          selection_guideline = []

          # スキル優先か威力優先か
          if @burning_tail_mode_pow
            selection_guideline << powers
            selection_guideline << feats_nums
            selection_guideline << feats_index_sums
          else
            selection_guideline << feats_nums
            selection_guideline << feats_index_sums
            selection_guideline << powers
          end

          selected_cards = get_min_values(selection_guideline[0])
          i = 1
          while selected_cards.length > 1 && i < 3

            guideline_tmp = []

            selected_cards.each do |idx|
              guideline_tmp << selection_guideline[i][idx]
            end

            guideline_tmp = get_min_values(guideline_tmp)

            selected_cards_tmp = []
            guideline_tmp.each do |i|
              selected_cards_tmp << selected_cards[i]
            end
            selected_cards = selected_cards_tmp
            i += 1
          end

          selected_card_index = selected_cards[rand(selected_cards.length)]
          foe.battle_table.each do |a|
            if a.id == ids[selected_card_index]
              foe.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, !a.up?)
              break
            end
          end

          now_on_feats = foe.current_chara_card.get_enable_feats
          attack_phase_feats.each do |f|
            foe.current_chara_card.off_feat_event(f) if !now_on_feats.include?(f)
          end
        end

        @feats_enable[FEAT_BURNING_TAIL] = false
      end
    end
    regist_event FinishBurningTailFeatEvent

    def get_min_values(a)
      ret = []
      min_val = a.min
      a.each_with_index do |c, i|
        ret << i if c == min_val
      end
      ret
    end

    # ------------------
    # 震歩
    # ------------------

    # 震歩が使用されたかのチェック
    def check_quake_walk_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_QUAKE_WALK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_QUAKE_WALK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveQuakeWalkFeatEvent
    regist_event CheckAddQuakeWalkFeatEvent
    regist_event CheckRotateQuakeWalkFeatEvent

    # 震歩を使用
    def finish_quake_walk_feat()
      if @feats_enable[FEAT_QUAKE_WALK]

        use_feat_event(@feats[FEAT_QUAKE_WALK])
        @feats_enable[FEAT_QUAKE_WALK] = false

        if (foe.get_direction == Entrant::DIRECTION_FORWARD || foe.get_direction == Entrant::DIRECTION_BACKWARD)

          foe.set_direction(Entrant::DIRECTION_PEND)

        end
      end
    end
    regist_event FinishQuakeWalkFeatEvent

    # ------------------
    # ドレナージ
    # ------------------

    # ドレナージが使用されたかのチェック
    def check_drainage_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DRAINAGE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DRAINAGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDrainageFeatEvent
    regist_event CheckAddDrainageFeatEvent
    regist_event CheckRotateDrainageFeatEvent

    # 必殺技の状態
    def use_drainage_feat()
      if @feats_enable[FEAT_DRAINAGE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DRAINAGE])
      end
    end
    regist_event UseDrainageFeatEvent

    # ドレナージが使用される
    def finish_drainage_feat()
      if @feats_enable[FEAT_DRAINAGE]
        use_feat_event(@feats[FEAT_DRAINAGE])
      end
    end
    regist_event FinishDrainageFeatEvent

    # ドレナージが使用される
    # 有効の場合必殺技IDを返す
    def use_drainage_feat_damage()
      if @feats_enable[FEAT_DRAINAGE]
        use_feat_event(@feats[FEAT_DRAINAGE])
        if @cc.owner.current_chara_card.status
          os = @cc.owner.current_chara_card.status
          # 全ての状態をコピーする
          os.each_index do |i|
            if os[i][1] > 0
              # 能力低下, 詛呪以外を相手に移す
              if i != STATE_STATE_DOWN && i != STATE_CURSE
                foe.current_chara_card.status[i][0] = os[i][0]
                foe.current_chara_card.status[i][1] = os[i][1]
                on_buff_event(false, foe.current_chara_card_no, i, foe.current_chara_card.status[i][0], foe.current_chara_card.status[i][1])
              end
            end
          end
          # 状態初期化
        end
        @cc.owner.cured_event()
      end
    end
    regist_event UseDrainageFeatDamageEvent

    # ドレナージが使用される
    # 有効の場合必殺技IDを返す
    def use_drainage_feat_const_damage()
      if @feats_enable[FEAT_DRAINAGE]
        attribute_party_damage(foe, get_hps(foe), 1, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        @feats_enable[FEAT_DRAINAGE] = false
      end
    end
    regist_event UseDrainageFeatConstDamageEvent

    # -----------------
    # やさしい微笑み
    # -----------------

    # やさしい微笑みが使用されたかのチェック
    def check_smile_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SMILE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SMILE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSmileFeatEvent
    regist_event CheckAddSmileFeatEvent
    regist_event CheckRotateSmileFeatEvent

    # 必殺技の状態
    def use_smile_feat()
      if @feats_enable[FEAT_SMILE]
        @cc.owner.tmp_power = 0
      end
    end
    regist_event UseSmileFeatEvent

    #  やさしい微笑みを使用
    def finish_smile_feat()
      if @feats_enable[FEAT_SMILE]
        use_feat_event(@feats[FEAT_SMILE])
      end
    end
    regist_event FinishSmileFeatEvent

    #  やさしい微笑みを使用
    def use_smile_feat_damage()
      if @feats_enable[FEAT_SMILE]
        @feats_enable[FEAT_SMILE] = false
        foe.healed_event(Feat.pow(@feats[FEAT_SMILE]))
      end
    end
    regist_event UseSmileFeatDamageEvent

    # ------------------
    # 血統汚染(レイド用)
    # ------------------

    # 血統汚染が使用されたかのチェック
    def check_blutkontamina_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLUTKONTAMINA)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_BLUTKONTAMINA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlutkontaminaFeatEvent
    regist_event CheckAddBlutkontaminaFeatEvent
    regist_event CheckRotateBlutkontaminaFeatEvent

    # 必殺技の状態
    def use_blutkontamina_feat()
      if @feats_enable[FEAT_BLUTKONTAMINA]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_BLUTKONTAMINA])
      end
    end
    regist_event UseBlutkontaminaFeatEvent

    # 血統汚染が使用される
    def finish_blutkontamina_feat()
      if @feats_enable[FEAT_BLUTKONTAMINA]
         use_feat_event(@feats[FEAT_BLUTKONTAMINA])
      end
    end
    regist_event FinishBlutkontaminaFeatEvent

    # 血統汚染が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_blutkontamina_feat_damage()
      if @feats_enable[FEAT_BLUTKONTAMINA]
        if duel.tmp_damage>0

          foe_dead_count_num = foe.current_chara_card.status[STATE_DEAD_COUNT][1]

          if foe_dead_count_num == 0
            buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, 5);
            on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed

          else

            if foe.current_chara_card.status[STATE_DEAD_COUNT][1] <= 2

              off_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0])
              foe.current_chara_card.status[STATE_DEAD_COUNT][1] = 0
              foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))

            else

              foe.current_chara_card.status[STATE_DEAD_COUNT][1] -= 2
              update_buff_event(false, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0])

            end

          end

        end
        @feats_enable[FEAT_BLUTKONTAMINA] = false
      end
    end
    regist_event UseBlutkontaminaFeatDamageEvent



    # ------------------
    # つめたい視線
    # ------------------
    # つめたい視線が使用されたかのチェック
    def check_cold_eyes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COLD_EYES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_COLD_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveColdEyesFeatEvent
    regist_event CheckAddColdEyesFeatEvent
    regist_event CheckRotateColdEyesFeatEvent

    # つめたい視線が使用終了
    def finish_cold_eyes_feat()
      if @feats_enable[FEAT_COLD_EYES]
        use_feat_event(@feats[FEAT_COLD_EYES])
      end
    end
    regist_event FinishColdEyesFeatEvent

    # つめたい視線が使用される
    # 有効の場合必殺技IDを返す
    def use_cold_eyes_feat_damage()
      if @feats_enable[FEAT_COLD_EYES]
        foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))
        @feats_enable[FEAT_COLD_EYES] = false
      end
    end
    regist_event UseColdEyesFeatDamageEvent

    # ------------------
    # 奸侫の鉄槌
    # ------------------

    # feat1が使用されたかのチェック
    def check_feat1_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FEAT1)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_FEAT1)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFeat1FeatEvent
    regist_event CheckAddFeat1FeatEvent
    regist_event CheckRotateFeat1FeatEvent

    # 必殺技の状態
    def use_feat1_feat()
      if @feats_enable[FEAT_FEAT1]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FEAT1])
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FEAT1]) if @feats_enable[FEAT_FEAT4]
      end
    end
    regist_event UseFeat1FeatEvent


    # feat1が使用される
    def finish_feat1_feat()
      if @feats_enable[FEAT_FEAT1]
        use_feat_event(@feats[FEAT_FEAT1])

        reduce_num = @feats_enable[FEAT_FEAT4] ? 2 : 1
        min_turn = foe.current_chara_card.kind == CC_KIND_PROFOUND_BOSS ? 1 : 0

        foe.current_chara_card.status.each_index do |i|

          reduce_count = 0
          while foe.current_chara_card.status[i][1] > min_turn && reduce_count < reduce_num

            foe.current_chara_card.status[i][1] -= 1
            update_buff_event(false, i, foe.current_chara_card.status[i][0])

            # ターンが0になったとき。特例として、自壊・操想なら死なせてあげる
            if foe.current_chara_card.status[i][1] == 0
              off_buff_event(false, foe.current_chara_card_no, i, foe.current_chara_card.status[i][0])
              if i == STATE_DEAD_COUNT || i == STATE_CONTROL
                foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))
              end
            end

            reduce_count += 1
          end
        end
      end
    end
    regist_event FinishFeat1FeatEvent

    def use_feat1_feat_damage
      if @feats_enable[FEAT_FEAT1]
        if duel.tmp_damage > 0 && @feats_enable[FEAT_FEAT4]

          if @cc.status[STATE_BLESS][1] > 0

            @cc.status[STATE_BLESS][1] += rand(3)
            @cc.status[STATE_BLESS][1] = BLESS_MAX if @cc.status[STATE_BLESS][1] > BLESS_MAX

          else

            set_state(@cc.status[STATE_BLESS], 1, 1)

          end

          on_buff_event(true, owner.current_chara_card_no, STATE_BLESS, @cc.status[STATE_BLESS][0], @cc.status[STATE_BLESS][1])
        end

        cool_down_feat4_feat if @feats_enable[FEAT_FEAT4]
        @feats_enable[FEAT_FEAT1] = false
      end
    end
    regist_event UseFeat1FeatDamageEvent

    # ------------------
    # 不善なる信仰
    # ------------------

    # feat2が使用されたかのチェック
    def check_feat2_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FEAT2)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FEAT2)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFeat2FeatEvent
    regist_event CheckAddFeat2FeatEvent
    regist_event CheckRotateFeat2FeatEvent

    # feat2が使用される
    # 有効の場合必殺技IDを返す
    def use_feat2_feat()
      if @feats_enable[FEAT_FEAT2]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FEAT2])
      end
    end
    regist_event UseFeat2FeatEvent

    # feat2が使用終了
    def finish_feat2_feat()
      if @feats_enable[FEAT_FEAT2]
        use_feat_event(@feats[FEAT_FEAT2])
        filtering = []
        filtering << (@feats_enable[FEAT_FEAT4] ? 2 : Feat.pow(@feats[FEAT_FEAT2]))
        filtering << 3 if @feats_enable[FEAT_FEAT4] && Feat.pow(@feats[FEAT_FEAT2]) == 2
        duel.tmp_damage = 0 if filtering.any? { |div| duel.tmp_damage % div == 0 }
      end
    end
    regist_event FinishFeat2FeatEvent

    # feat2が使用される(ダメージ時)
    def use_feat2_feat_damage()
      if @feats_enable[FEAT_FEAT2]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0 && owner.current_chara_card.deck_cost > 20 && @feats_enable[FEAT_FEAT4]
          # buff処理
          if @cc.status[STATE_BLESS][1] > 0

            @cc.status[STATE_BLESS][1] += rand(3)
            @cc.status[STATE_BLESS][1] = BLESS_MAX if @cc.status[STATE_BLESS][1] > BLESS_MAX

          else

            set_state(@cc.status[STATE_BLESS], 1, rand(3))

          end

          on_buff_event(true, owner.current_chara_card_no, STATE_BLESS, @cc.status[STATE_BLESS][0], @cc.status[STATE_BLESS][1])
        end
        cool_down_feat4_feat if @feats_enable[FEAT_FEAT4]
        @feats_enable[FEAT_FEAT2] = false
      end
    end
    regist_event UseFeat2FeatDamageEvent

    # ------------------
    # 曲悪の安寧
    # ------------------

    # feat3が使用されたかのチェック
    def check_feat3_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FEAT3)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_FEAT3)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFeat3FeatEvent
    regist_event CheckAddFeat3FeatEvent
    regist_event CheckRotateFeat3FeatEvent

    # 必殺技の状態
    def use_feat3_feat()
      if @feats_enable[FEAT_FEAT3]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FEAT3])
      end
    end
    regist_event UseFeat3FeatEvent

    # feat3が使用される
    def finish_feat3_feat()
      if @feats_enable[FEAT_FEAT3]
        use_feat_event(@feats[FEAT_FEAT3])
        if @feats_enable[FEAT_FEAT4]

          @cc.owner.hit_points.each_index do |i|
            @cc.owner.party_healed_event(i, 2) if @cc.owner.hit_points[i] > 0
          end

          if @cc.status[STATE_BLESS][1] > 0

            @cc.status[STATE_BLESS][1] -= 1
            if @cc.status[STATE_BLESS][1] == 0
              off_buff_event(true, owner.current_chara_card_no, STATE_BLESS, @cc.status[STATE_BLESS][0])
            else
              update_buff_event(true, STATE_BLESS, @cc.status[STATE_BLESS][0])
            end

          end

          cool_down_feat4_feat
        else

          @cc.owner.healed_event(2)

        end
        @feats_enable[FEAT_FEAT3] = false
      end
    end
    regist_event FinishFeat3FeatEvent

    # ------------------
    # オーバードライブ
    # ------------------

    # feat4が使用されたかのチェック
    def check_feat4_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FEAT4)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FEAT4)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFeat4FeatEvent
    regist_event CheckAddFeat4FeatEvent
    regist_event CheckRotateFeat4FeatEvent

    # feat4を使用
    def use_feat4_feat()
      if @feats_enable[FEAT_FEAT4]
        @over_drive = true
        @over_drive_five = false
        use_feat_event(@feats[FEAT_FEAT4])
        on_feat_event(FEAT_FEAT4)

        if @cc.status[STATE_BLESS][1] > 0

          if @cc.status[STATE_BLESS][1] == BLESS_MAX

            # 臨界が5のとき、自身を封印、フラグを立てておく
            @over_drive_five = true
            set_state(@cc.status[STATE_SEAL], 1, 1)
            on_buff_event(true, owner.current_chara_card_no, STATE_SEAL, @cc.status[STATE_SEAL][0], @cc.status[STATE_SEAL][1])

            return

          else

            @cc.status[STATE_BLESS][1] += Feat.pow(@feats[FEAT_FEAT4])
            @cc.status[STATE_BLESS][1] = BLESS_MAX if @cc.status[STATE_BLESS][1] > BLESS_MAX
            on_buff_event(true, owner.current_chara_card_no, STATE_BLESS, @cc.status[STATE_BLESS][0], @cc.status[STATE_BLESS][1])

          end

        else

          set_state(@cc.status[STATE_BLESS], 1, 1)
          on_buff_event(true, owner.current_chara_card_no, STATE_BLESS, @cc.status[STATE_BLESS][0], @cc.status[STATE_BLESS][1])

        end

      end
    end
    regist_event UseFeat4FeatEvent

    def check_bp_feat4_feat
      if @feats_enable[FEAT_FEAT4] &&  @cc && @cc.index == owner.current_chara_card_no && @over_drive_five
        owner.tmp_power *= 2
      end
    end
    regist_event CheckBpFeat4AttackFeatEvent
    regist_event CheckBpFeat4DefenceFeatEvent

    def finish_change_feat4_feat
      if @over_drive
        @feats_enable[FEAT_FEAT4] = true
        on_feat_event(FEAT_FEAT4)
        @over_drive = false
      end
    end
    regist_event FinishChangeFeat4FeatEvent

    def finish_feat4_feat()
      if @feats_enable[FEAT_FEAT4]
        cool_down_feat4_feat
        owner.cured_event() if @over_drive_five
        @over_drive_five = false
        @over_drive = false
      end
    end
    regist_event FinishFeat4FeatEvent

    def start_feat4_feat()
        @over_drive_five = false
        @over_drive = false
    end
    regist_event StartFeat4FeatEvent

    def cool_down_feat4_feat
      off_feat_event(FEAT_FEAT4)
      @over_drive = false
      @feats_enable[FEAT_FEAT4] = false
    end

    # ------------------
    # 見えざる白群の鼬
    # ------------------
    # 見えざる白群の鼬が使用されたかのチェック
    def check_weasel_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WEASEL)
      check_feat(FEAT_WEASEL)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWeaselFeatEvent
    regist_event CheckAddWeaselFeatEvent
    regist_event CheckRotateWeaselFeatEvent

    # 見えざる白群の鼬が使用される
    # 有効の場合必殺技IDを返す
    def use_weasel_feat()
      if @feats_enable[FEAT_WEASEL]
        @cc.owner.tmp_power+=2
      end
    end
    regist_event UseWeaselFeatEvent

    def use_weasel_feat_deal()
      if @feat_weasel_deff_card_list
        if duel.turn > 1 && @feat_weasel_deff_card_list["#{duel.turn-1}"]
          owner.battle_table = []
          deal_list = []
          @feat_weasel_deff_card_list["#{duel.turn-1}"].each do |c|
            deal_list << c if (!duel.deck.exist?(c) && !foe.cards.include?(c) && !owner.cards.include?(c))  # 山札・手札になければ引く
          end
          @cc.owner.grave_dealed_event(deal_list)
        end
      end
      init_weasel()
    end
    regist_event UseWeaselFeatDealEvent

    # 見えざる白群の鼬が使用終了
    def check_table_weasel_feat_move
      return if Feat.pow(@feats[FEAT_WEASEL]) == 0

      unless @feat_weasel_deff_card_list
        init_weasel()
      end
      keep_list = @feat_weasel_deff_card_list["#{duel.turn}"]
      keep_list = [] if keep_list.nil?
      foe.battle_table.clone.each do |c|
        if c.u_type == ActionCard::DEF || c.b_type == ActionCard::DEF
          keep_list << c
        end
      end
      @feat_weasel_deff_card_list["#{duel.turn}"] = keep_list
    end
    regist_event CheckTableWeaselFeatMoveEvent

    # 見えざる白群の鼬が使用終了
    def check_table_weasel_feat_battle
      return if Feat.pow(@feats[FEAT_WEASEL]) == 0 && owner.initiative

      unless @feat_weasel_deff_card_list
        init_weasel()
      end
      keep_list = @feat_weasel_deff_card_list["#{duel.turn}"]
      keep_list = [] if keep_list.nil?
      foe.battle_table.clone.each do |c|
        if c.u_type == ActionCard::DEF || c.b_type == ActionCard::DEF
          keep_list << c
        end
      end
      @feat_weasel_deff_card_list["#{duel.turn}"] = keep_list
    end
    regist_event CheckTableWeaselFeatBattleEvent

    # 見えざる白群の鼬が使用終了
    def finish_weasel_feat()
      if @feats_enable[FEAT_WEASEL] && !owner.initiative
        use_feat_event(@feats[FEAT_WEASEL])
      end
    end
    regist_event FinishWeaselFeatEvent

    # 見えざる白群の鼬が使用される
    # 有効の場合必殺技IDを返す
    def use_weasel_feat_damage()
      if @feats_enable[FEAT_WEASEL] && !owner.initiative
        delete_num = 8
        aca = foe.cards.shuffle
        keep_list = @feat_weasel_deff_card_list["#{duel.turn}"]
        keep_list = [] if keep_list.nil?
        delete_num.times do |i|
          if aca[i]
            result = discard(foe, aca[i])
            if Feat.pow(@feats[FEAT_WEASEL]) == 0 && (aca[i].u_type == ActionCard::DEF || aca[i].b_type == ActionCard::DEF) && result == 1
              keep_list << aca[i].clone
            end
          end
        end
        @feat_weasel_deff_card_list["#{duel.turn}"] = keep_list
      end
    end
    regist_event UseWeaselFeatDamageEvent

    # 技を発動したかのチェック
    def check_ending_weasel_feat()
      if @feats_enable[FEAT_WEASEL]
        @feats_enable[FEAT_WEASEL] = false
      else
        init_weasel()
      end
    end
    regist_event CheckEndingWeaselFeatEvent

    def init_weasel
        @feat_weasel_deff_card_list = { }
    end

    # ------------------
    # 暗黒の渦(復活)
    # ------------------

    # DarkProfoundが使用されたかのチェック
    def check_dark_profound_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DARK_PROFOUND)
      check_feat(FEAT_DARK_PROFOUND)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDarkProfoundFeatEvent
    regist_event CheckAddDarkProfoundFeatEvent
    regist_event CheckRotateDarkProfoundFeatEvent

    # DarkProfoundが使用される
    # 有効の場合必殺技IDを返す
    def use_dark_profound_feat()
      if @feats_enable[FEAT_DARK_PROFOUND]
        @cc.owner.tmp_power+=4
        @cc.owner.tmp_power+=4 * Feat.pow(@feats[FEAT_DARK_PROFOUND]) if @cc.using && owner.initiative && @cc.owner.distance == 3
      end
    end
    regist_event UseDarkProfoundFeatEvent

    # 暗黒の渦を使用する。深淵の威力を増やす
    def use_dark_profound_feat_bornus()
      if @feats_enable[FEAT_DARK_PROFOUND] && @feats_enable[FEAT_ABYSS]
        @feat_abyss_bornus_damage = 1
      end
    end
    regist_event UseDarkProfoundFeatBornusEvent

    # DarkProfoundが使用終了
    def finish_dark_profound_feat()
      if @feats_enable[FEAT_DARK_PROFOUND]
        @feats_enable[FEAT_DARK_PROFOUND] = false
        use_feat_event(@feats[FEAT_DARK_PROFOUND])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishDarkProfoundFeatEvent

    # ------------------
    # 因果の扉
    # ------------------

    # 因果の扉が使用されたかのチェック
    def check_karmic_dor_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KARMIC_DOR)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KARMIC_DOR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKarmicDorFeatEvent
    regist_event CheckAddKarmicDorFeatEvent
    regist_event CheckRotateKarmicDorFeatEvent

    # 因果の扉に使用された特殊カードをチェック
    def check_point_karmic_dor_feat()
      if @feats_enable[FEAT_KARMIC_DOR]
        @karmic_dor_eight_and_more = owner.table_point_check(ActionCard::SPC) >= 8
      end
    end
    regist_event CheckPointKarmicDorFeatEvent

    # 因果の扉が使用される
    def use_karmic_dor_feat()
      if @feats_enable[FEAT_KARMIC_DOR]
        use_feat_event(@feats[FEAT_KARMIC_DOR])
        # 相手のカードを回転する
        if Feat.pow(@feats[FEAT_KARMIC_DOR]) > 0
          foe.battle_table.each do |a|
            foe.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, (a.up?)? false : true)
          end
        else
          foe.battle_table.each do |a|
            foe.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, (rand(2) == 1)? true : false)
          end
        end
      end
    end
    regist_event UseKarmicDorFeatEvent

    # 因果の扉が使用終了される
    def finish_karmic_dor_feat()
      if @feats_enable[FEAT_KARMIC_DOR]
        @feats_enable[FEAT_KARMIC_DOR] = false
        if @karmic_dor_eight_and_more
          tmp_table = foe.battle_table.clone
          foe.battle_table = []
          tmp_table = tmp_table + owner.battle_table.clone
          owner.battle_table = []
          @cc.owner.grave_dealed_event(tmp_table)
        end
        @karmic_dor_eight_and_more = false
      end
    end
    regist_event FinishKarmicDorFeatEvent
    regist_event FinishCharaChangeKarmicDorFeatEvent
    regist_event FinishFoeCharaChangeKarmicDorFeatEvent

    # ------------------
    # アラーネウム
    # ------------------

    # batafly_movが使用されたかのチェック
    def check_batafly_mov_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BATAFLY_MOV)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BATAFLY_MOV)
      # ポイントの変更をチェック
      if @feats_enable[FEAT_BATAFLY_MOV]
        owner.table_cards_lock=(true)
        owner.reset_on_list_by_type_set(FEAT_BATAFLY_MOV, "SAD", 3)
        owner.point_update_event
      else
        owner.clear_feat_battle_table_on_list(FEAT_BATAFLY_MOV)
        owner.table_cards_lock=(false)
      end
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBataflyMovFeatEvent
    regist_event CheckAddBataflyMovFeatEvent
    regist_event CheckRotateBataflyMovFeatEvent

    # batafly_movが使用される
    # トラップをセットする
    def determine_distance_batafly_mov_feat
      if @feats_enable[FEAT_BATAFLY_MOV]
        use_feat_event(@feats[FEAT_BATAFLY_MOV])
        d = batafly_feat_type_to_distance(owner.get_max_value_type("SAD", 3))
        trap_status = { TRAP_STATUS_DISTANCE => d,
                        TRAP_STATUS_POW => Feat.pow(@feats[FEAT_BATAFLY_MOV]),
                        TRAP_STATUS_TURN => TRAP_KEEP_TURN-1,
                        TRAP_STATUS_STATE => TRAP_STATE_READY,
                        TRAP_STATUS_VISIBILITY => false
                      }
        set_trap(foe, FEAT_BATAFLY_MOV, trap_status)
      end
    end
    regist_event DetermineDistanceBataflyMovFeatEvent

    def finish_batafly_mov_feat
      if @feats_enable[FEAT_BATAFLY_MOV]
        @feats_enable[FEAT_BATAFLY_MOV] = false
        owner.table_cards_lock=(false)
      end
    end
    regist_event FinishBataflyMovFeatEvent

    # ------------------
    # アルウス
    # ------------------

    # batafly_atkが使用されたかのチェック
    def check_batafly_atk_feat
      update_skip = false
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BATAFLY_ATK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BATAFLY_ATK)
      # ポイントの変更をチェック
      if @feats_enable[FEAT_BATAFLY_ATK]
        owner.table_cards_lock=(true)
        min_val = 3
        min_val = 2 if @easing_feat_list && @easing_feat_list.key?(@feats[FEAT_BATAFLY_ATK])
        owner.reset_on_list_by_type_set(FEAT_BATAFLY_ATK, "SAD", min_val)
        owner.point_update_event
      else
        owner.clear_feat_battle_table_on_list(FEAT_BATAFLY_ATK)
        owner.table_cards_lock=(false)
      end
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBataflyAtkFeatEvent
    regist_event CheckAddBataflyAtkFeatEvent
    regist_event CheckRotateBataflyAtkFeatEvent

    # batafly_atkが使用される
    # 有効の場合必殺技IDを返す
    def use_batafly_atk_feat
      if @feats_enable[FEAT_BATAFLY_ATK]
        owner.tmp_power = owner.table_count * 4
        owner.tmp_power = 16 if owner.tmp_power > 16
      end
    end
    regist_event UseBataflyAtkFeatEvent

    # batafly_atkが使用終了される
    def finish_batafly_atk_feat
      if @feats_enable[FEAT_BATAFLY_ATK]
        @feats_enable[FEAT_BATAFLY_ATK] = false
        use_feat_event(@feats[FEAT_BATAFLY_ATK])
        min_val = 3
        min_val = 2 if @easing_feat_list && @easing_feat_list.key?(@feats[FEAT_BATAFLY_ATK])
        d = batafly_feat_type_to_distance(owner.get_max_value_type("SAD", min_val))
        trap_status = { TRAP_STATUS_DISTANCE => d,
                        TRAP_STATUS_POW => Feat.pow(@feats[FEAT_BATAFLY_ATK]),
                        TRAP_STATUS_TURN => TRAP_KEEP_TURN,
                        TRAP_STATUS_STATE => TRAP_STATE_WAIT,
                        TRAP_STATUS_VISIBILITY => false
                      }
        set_trap(foe, FEAT_BATAFLY_ATK, trap_status)
      end
    end
    regist_event FinishBataflyAtkFeatEvent

    # ------------------
    # パピリオサルタンス
    # ------------------

    # batafly_defが使用されたかのチェック
    def check_batafly_def_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BATAFLY_DEF)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BATAFLY_DEF)
      # ポイントの変更をチェック
      if @feats_enable[FEAT_BATAFLY_DEF]
        owner.table_cards_lock=(true)
        owner.reset_on_list_by_type_set(FEAT_BATAFLY_DEF, "SAD", 3)
        owner.point_update_event
      else
        owner.table_cards_lock=(false) if !@feats_enable[FEAT_BATAFLY_SLD]
        owner.clear_feat_battle_table_on_list(FEAT_BATAFLY_DEF)
      end
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBataflyDefFeatEvent
    regist_event CheckAddBataflyDefFeatEvent
    regist_event CheckRotateBataflyDefFeatEvent

    # batafly_defが使用される
    # 有効の場合必殺技IDを返す
    def use_batafly_def_feat
      if @feats_enable[FEAT_BATAFLY_DEF]
        owner.tmp_power += owner.table_count * 2 - owner.table_point_check(ActionCard::DEF)
      end
    end
    regist_event UseBataflyDefFeatEvent

    # batafly_defが使用終了される
    def finish_batafly_def_feat
      if @feats_enable[FEAT_BATAFLY_DEF]
        @feats_enable[FEAT_BATAFLY_DEF] = false
        use_feat_event(@feats[FEAT_BATAFLY_DEF])
        d = batafly_feat_type_to_distance(owner.get_max_value_type("SAD", 3))
        trap_status = { TRAP_STATUS_DISTANCE => d,
                        TRAP_STATUS_POW => Feat.pow(@feats[FEAT_BATAFLY_DEF]),
                        TRAP_STATUS_TURN => TRAP_KEEP_TURN,
                        TRAP_STATUS_STATE => TRAP_STATE_WAIT,
                        TRAP_STATUS_VISIBILITY => false }
        set_trap(foe, FEAT_BATAFLY_DEF, trap_status)
      end
    end
    regist_event FinishBataflyDefFeatEvent

    # ------------------
    # インセクタービア
    # ------------------

    # batafly_sldが使用されたかのチェック
    def check_batafly_sld_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BATAFLY_SLD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BATAFLY_SLD)
      # ポイントの変更をチェック
      if @feats_enable[FEAT_BATAFLY_SLD]
        owner.table_cards_lock=(true)
        owner.reset_on_list_by_type_set(FEAT_BATAFLY_SLD, "SAD", 1, true)
        owner.point_update_event
      else
        owner.table_cards_lock=(false) if !@feats[FEAT_BATAFLY_DEF]
        owner.clear_feat_battle_table_on_list(FEAT_BATAFLY_SLD)
      end
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBataflySldFeatEvent
    regist_event CheckAddBataflySldFeatEvent
    regist_event CheckRotateBataflySldFeatEvent

    # batafly_sldが使用される
    # 有効の場合必殺技IDを返す
    def use_batafly_sld_feat
      if @feats_enable[FEAT_BATAFLY_SLD]
        owner.tmp_power += 4
      end
    end
    regist_event UseBataflySldFeatEvent

    # batafly_sldが使用終了される
    def finish_batafly_sld_feat
      if @feats_enable[FEAT_BATAFLY_SLD]
        @feats_enable[FEAT_BATAFLY_SLD] = false
        use_feat_event(@feats[FEAT_BATAFLY_SLD])
        d = batafly_feat_type_to_distance(owner.get_max_value_type("SAD", 1, true))
        pow = Feat.pow(@feats[FEAT_BATAFLY_SLD])
        trap_status = { TRAP_STATUS_DISTANCE => d,
                        TRAP_STATUS_POW => pow,
                        TRAP_STATUS_TURN => TRAP_KEEP_TURN,
                        TRAP_STATUS_STATE => TRAP_STATE_WAIT,
                        TRAP_STATUS_VISIBILITY => true }
        set_trap(owner, FEAT_BATAFLY_SLD, trap_status)
        owner.invincible=(false)
      end
    end
    regist_event FinishBataflySldFeatEvent

    # ------------------
    # ベンダーカクテル
    # ------------------
    # ベンダーカクテルが使用されたかのチェック
    def check_grace_cocktail_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GRACE_COCKTAIL)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_GRACE_COCKTAIL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGraceCocktailFeatEvent
    regist_event CheckAddGraceCocktailFeatEvent
    regist_event CheckRotateGraceCocktailFeatEvent

    # 必殺技の状態
    def use_grace_cocktail_feat()
      if @feats_enable[FEAT_GRACE_COCKTAIL]
        @cc.owner.tmp_power += 4
      end
    end
    regist_event UseGraceCocktailFeatEvent

    # ベンダーカクテルが使用される
    def finish_grace_cocktail_feat()
      if @feats_enable[FEAT_GRACE_COCKTAIL]
        use_feat_event(@feats[FEAT_GRACE_COCKTAIL])
        @feat_grace_cocktail_cnt ? @feat_grace_cocktail_cnt += 1 : @feat_grace_cocktail_cnt = 1

        # 使用回数+2を最大値として、ランダムにステータスを増減する
        max_val = @feat_grace_cocktail_cnt
        rand_atk = rand(max_val+1) + max_val
        atk_sign = rand(2)
        rand_def = rand(max_val+1) + max_val
        def_sign = rand(2)
        status_list = [STATE_ATK_UP, STATE_ATK_DOWN, STATE_DEF_UP, STATE_DEF_DOWN]
        on_buff_status = { } # 有効にするステータス

        if atk_sign > 0
          on_buff_status[STATE_ATK_UP] = rand_atk
        else
          on_buff_status[STATE_ATK_DOWN] = rand_atk
        end

        if def_sign > 0
          on_buff_status[STATE_DEF_UP] = rand_def
        else
          on_buff_status[STATE_DEF_DOWN] = rand_def
        end

        status_list.each do |s|
          if on_buff_status.key?(s)
            set_state(@cc.status[s], on_buff_status[s], 2);
            on_buff_event(true, @cc.owner.current_chara_card_no, s, @cc.status[s][0], @cc.status[s][1])

          # 有効リストに無ければ消す
          elsif @cc.owner.current_chara_card.status[s][1] > 0
            off_buff_event(true, owner.current_chara_card_no, s, @cc.owner.current_chara_card.status[s][0])
            @cc.owner.current_chara_card.status[s][1] = 0
          end
        end
      end
    end
    regist_event FinishGraceCocktailFeatEvent

    # ベンダーカクテルが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_grace_cocktail_feat_damage()
      if @feats_enable[FEAT_GRACE_COCKTAIL]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_GRACE_COCKTAIL] = false
      end
    end
    regist_event UseGraceCocktailFeatDamageEvent

    # ------------------
    # ランドマイン（復活）
    # ------------------
    # 地雷が使用されたかのチェック
    def check_land_mine_r_feat
      @cc.owner.reset_feat_on_cards(FEAT_LAND_MINE_R)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_LAND_MINE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveLandMineRFeatEvent
    regist_event CheckAddLandMineRFeatEvent
    regist_event CheckRotateLandMineRFeatEvent

    # 因果の糸が使用される
    def use_land_mine_r_feat()
      if @feats_enable[FEAT_LAND_MINE_R]
        @feats_enable[FEAT_LAND_MINE_R] = false
        use_feat_event(@feats[FEAT_LAND_MINE_R])
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_LAND_MINE_R])))
      end
    end
    regist_event UseLandMineRFeatEvent


    # ------------------
    # ナパーム・デス
    # ------------------
    # ナパーム・デスが使用されたかのチェック
    def check_napalm_death_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_NAPALM_DEATH)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_NAPALM_DEATH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveNapalmDeathFeatEvent
    regist_event CheckAddNapalmDeathFeatEvent
    regist_event CheckRotateNapalmDeathFeatEvent

    # ナパーム・デスが使用される
    # 有効の場合必殺技IDを返す
    def use_napalm_death_feat()
      if @feats_enable[FEAT_NAPALM_DEATH]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_NAPALM_DEATH])
      end
    end
    regist_event UseNapalmDeathFeatEvent

    # ナパーム・デスが使用終了
    def finish_napalm_death_feat()
      if @feats_enable[FEAT_NAPALM_DEATH]
        @feats_enable[FEAT_NAPALM_DEATH] = false
        use_feat_event(@feats[FEAT_NAPALM_DEATH])
        total_cnt = @feat_grace_cocktail_cnt ? @feat_grace_cocktail_cnt : 0
        used_cnt = @feat_grace_cocktail_used ? @feat_grace_cocktail_used : 0
        new_cocktail = total_cnt - used_cnt
        if new_cocktail > 0
          attribute_party_damage(foe, get_hps(foe), 2, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM, new_cocktail)
          @feat_grace_cocktail_used = @feat_grace_cocktail_cnt
        end
      end
    end
    regist_event FinishNapalmDeathFeatEvent


    # ------------------
    # スーサイダル・F
    # ------------------

    # スーサイダル・Fが使用されたかのチェック
    def check_suicidal_failure_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SUICIDAL_FAILURE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SUICIDAL_FAILURE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSuicidalFailureFeatEvent
    regist_event CheckAddSuicidalFailureFeatEvent
    regist_event CheckRotateSuicidalFailureFeatEvent

    # スーサイダル・Fが使用される
    # 有効の場合必殺技IDを返す
    def use_suicidal_failure_feat()
      if @feats_enable[FEAT_SUICIDAL_FAILURE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SUICIDAL_FAILURE])*@cc.owner.get_battle_table_point(ActionCard::SPC)
      end
    end
    regist_event UseSuicidalFailureFeatEvent

    # スーサイダル・Fが使用終了
    def finish_suicidal_failure_feat()
      if @feats_enable[FEAT_SUICIDAL_FAILURE]
        @feats_enable[FEAT_SUICIDAL_FAILURE] = false
        use_feat_event(@feats[FEAT_SUICIDAL_FAILURE])
        btp_spc = @cc.owner.get_battle_table_point(ActionCard::SPC).to_i
        @feat_big_bragg_pow = @feat_big_bragg_pow ? @feat_big_bragg_pow + btp_spc : btp_spc
        owner.damaged_event(attribute_damage(ATTRIBUTE_SELF_INJURY,owner,btp_spc), IS_NOT_HOSTILE_DAMAGE)
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishSuicidalFailureFeatEvent

    # ------------------
    # ビッグブラッグ(復活)
    # ------------------
    # ビッグブラッグが使用されたかのチェック
    def check_big_bragg_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BIG_BRAGG_R)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BIG_BRAGG_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBigBraggRFeatEvent
    regist_event CheckAddBigBraggRFeatEvent
    regist_event CheckRotateBigBraggRFeatEvent

    # ビッグブラッグを使用
    def finish_big_bragg_r_feat()
      if @feats_enable[FEAT_BIG_BRAGG_R]
        use_feat_event(@feats[FEAT_BIG_BRAGG_R])
        @feats_enable[FEAT_BIG_BRAGG_R] = false

        if !@feat_big_bragg_pow || @feat_big_bragg_pow < 4
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        elsif @feat_big_bragg_pow < 9
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], 3, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        elsif @feat_big_bragg_pow < 14
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R]), 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 1))
          owner.healed_event(1)
        else
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R])+1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_BIG_BRAGG_R])+1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed

          if @feat_big_bragg_pow < 19
            foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 2))
            owner.healed_event(2)
          else
            foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, (@feat_big_bragg_pow/5).to_i))
            owner.healed_event((@feat_big_bragg_pow/5).to_i)
          end
        end
      end
    end
    regist_event FinishBigBraggRFeatEvent

    # ------------------
    # レッツナイフ(復活)
    # ------------------
    # レッツナイフが使用されたかのチェック
    def check_lets_knife_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LETS_KNIFE_R)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_LETS_KNIFE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLetsKnifeRFeatEvent
    regist_event CheckAddLetsKnifeRFeatEvent
    regist_event CheckRotateLetsKnifeRFeatEvent

    # レッツナイフが使用される
    # 有効の場合必殺技IDを返す
    def use_lets_knife_r_feat()
      if @feats_enable[FEAT_LETS_KNIFE_R]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_LETS_KNIFE_R])*@cc.owner.battle_table.count
      end
    end
    regist_event UseLetsKnifeRFeatEvent

    # レッツナイフが使用終了
    def finish_lets_knife_r_feat()
      if @feats_enable[FEAT_LETS_KNIFE_R]
        @feats_enable[FEAT_LETS_KNIFE_R] = false
        use_feat_event(@feats[FEAT_LETS_KNIFE_R])
      end
    end
    regist_event FinishLetsKnifeRFeatEvent

    # ------------------
    # 捕食
    # ------------------
    # 捕食が使用されたかのチェック
    def check_prey_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PREY)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PREY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemovePreyFeatEvent
    regist_event CheckAddPreyFeatEvent
    regist_event CheckRotatePreyFeatEvent

    # 捕食が使用される
    def use_prey_feat()
      if @feats_enable[FEAT_PREY]
        use_feat_event(@feats[FEAT_PREY])
        @feats_enable[FEAT_PREY] = false
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,2))
        if foe.hit_point < 1
          buffed = foe.current_chara_card.set_state(@cc.status[STATE_CHAOS], 1, Feat.pow(@feats[FEAT_PREY]))
          foe.current_chara_card.on_buff_event(false, owner.current_chara_card_no, STATE_CHAOS, @cc.status[STATE_CHAOS][0], @cc.status[STATE_CHAOS][1]) if buffed
        end
      end
    end
    regist_event UsePreyFeatEvent

    # ------------------
    # 反芻
    # ------------------

    # 反芻が使用されたかのチェック
    def check_rumination_feat
      @cc.owner.reset_feat_on_cards(FEAT_RUMINATION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_RUMINATION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveRuminationFeatEvent
    regist_event CheckAddRuminationFeatEvent
    regist_event CheckRotateRuminationFeatEvent

    # 反芻が使用される
    def use_rumination_feat()
      if @feats_enable[FEAT_RUMINATION]
        use_feat_event(@feats[FEAT_RUMINATION])
        # 相手のカードを奪う
        @feat_rumination_deal_list = nil
        if owner.battle_table.size > 0
          @feat_rumination_deal_list = owner.battle_table.clone
          owner.battle_table = []
        end

        if foe.cards.size > 0
          tmp_cards = foe.cards.dup.sort_by{rand}
          tmp_cards.each do |c|
            if (c.u_type == ActionCard::ARW || c.b_type == ActionCard::ARW || c.u_type == ActionCard::SWD || c.b_type == ActionCard::SWD) && (c.u_value >= Feat.pow(@feats[FEAT_RUMINATION]) || c.b_value >= Feat.pow(@feats[FEAT_RUMINATION]))
              steal_deal(c)
            end
          end
        end
      end
    end
    regist_event UseRuminationFeatEvent

    # 反芻が使用される
    def finish_rumination_feat()
      if @feats_enable[FEAT_RUMINATION]
        # 相手がカードを取得
        if @feat_rumination_deal_list
          foe.grave_dealed_event(@feat_rumination_deal_list)
        end
        @feats_enable[FEAT_RUMINATION] = false
      end
    end
    regist_event FinishRuminationFeatEvent
    regist_event FinishRuminationFeatFoeCharaChangeEvent
    regist_event FinishRuminationFeatOwnerCharaChangeEvent

    # ------------------
    # ピルム
    # ------------------
    # ピルムが使用されたかのチェック
    def check_pilum_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PILUM)
      # テーブルにアクションカードがおかれていてかつ、距離が遠距離の時
      check_feat(FEAT_PILUM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePilumFeatEvent
    regist_event CheckAddPilumFeatEvent
    regist_event CheckRotatePilumFeatEvent

    # ピルムが使用される
    def use_pilum_feat()
      if @feats_enable[FEAT_PILUM]
        p = Feat.pow(@feats[FEAT_PILUM])
        s = owner.get_type_point_table_count(ActionCard::SWD, 5)
        a = owner.get_type_point_table_count(ActionCard::ARW, 5)
        p += s * 3 * Feat.pow(@feats[FEAT_PILUM]) + a * 3 * Feat.pow(@feats[FEAT_PILUM])
        @cc.owner.tmp_power += p
      end
    end
    regist_event UsePilumFeatEvent

    # ピルムが使用終了される
    def finish_pilum_feat()
      if @feats_enable[FEAT_PILUM]
        use_feat_event(@feats[FEAT_PILUM])
      end
    end
    regist_event FinishPilumFeatEvent

    # ピルムが使用終了される
    def use_pilum_feat_damage()
      if @feats_enable[FEAT_PILUM]
        @feats_enable[FEAT_PILUM] = false
        if duel.tmp_damage >= foe.hit_point
          duel.tmp_damage = foe.hit_point - 1
        end
      end
    end
    regist_event UsePilumFeatDamageEvent

    # ------------------
    # 地中の路
    # ------------------
    # 地中の路が使用されたかのチェック
    def check_road_of_underground_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ROAD_OF_UNDERGROUND)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ROAD_OF_UNDERGROUND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRoadOfUndergroundFeatEvent
    regist_event CheckAddRoadOfUndergroundFeatEvent
    regist_event CheckRotateRoadOfUndergroundFeatEvent

    # 地中の路が使用される
    # 使用中は移動しない
    def use_road_of_underground_feat
      if foe.trap.size > 0 && foe.trap.key?(FEAT_BATAFLY_ATK.to_s)
        owner.set_direction(Entrant::DIRECTION_PEND)
      end
    end
    regist_event UseRoadOfUndergroundFeatEvent

    # かからなかったら撤去する
    def use_road_of_underground_feat_finish_move
      if foe.trap.size > 0 && foe.trap.key?(FEAT_BATAFLY_ATK.to_s)
        foe.trap[FEAT_BATAFLY_ATK.to_s][TRAP_STATUS_STATE] = TRAP_STATE_WAIT
        foe.trap[FEAT_BATAFLY_ATK.to_s][TRAP_STATUS_TURN] = 1
      end
    end
    regist_event UseRoadOfUndergroundFeatFinishMoveEvent

    # 地中の路が使用終了される
    def finish_road_of_underground_feat
      if @feats_enable[FEAT_ROAD_OF_UNDERGROUND]
        buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, 1);
        on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        @feats_enable[FEAT_ROAD_OF_UNDERGROUND] = false
        use_feat_event(@feats[FEAT_ROAD_OF_UNDERGROUND])
        d = owner.distance
        trap_status = { TRAP_STATUS_DISTANCE => d,
                        TRAP_STATUS_POW => Feat.pow(@feats[FEAT_ROAD_OF_UNDERGROUND]),
                        TRAP_STATUS_TURN => 2,
                        TRAP_STATUS_STATE => TRAP_STATE_WAIT,
                        TRAP_STATUS_VISIBILITY => false
                      }
        set_trap(foe, FEAT_BATAFLY_ATK, trap_status)
      end
    end
    regist_event FinishRoadOfUndergroundFeatEvent

    # ------------------
    # 狐分身
    # ------------------

    # 狐分身が使用されたかのチェック
    def check_fox_shadow_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOX_SHADOW)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FOX_SHADOW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFoxShadowFeatEvent
    regist_event CheckAddFoxShadowFeatEvent
    regist_event CheckRotateFoxShadowFeatEvent

    # 狐分身が使用される
    # 有効の場合必殺技IDを返す
    def use_fox_shadow_feat()
      if @feats_enable[FEAT_FOX_SHADOW]
        multi_pt = Feat.pow(@feats[FEAT_FOX_SHADOW]) > 2 ? Feat.pow(@feats[FEAT_FOX_SHADOW]) : Feat.pow(@feats[FEAT_FOX_SHADOW]) + 1
        add_pt = Feat.pow(@feats[FEAT_FOX_SHADOW])
        ret = owner.get_same_number_both_sides_table_count(1)
        owner.tmp_power += add_pt + multi_pt * ret[0]
      end
    end
    regist_event UseFoxShadowFeatEvent

    # 狐分身が使用終了
    def finish_fox_shadow_feat()
      if @feats_enable[FEAT_FOX_SHADOW]
        use_feat_event(@feats[FEAT_FOX_SHADOW])
        @feats_enable[FEAT_FOX_SHADOW] = false
      end
    end
    regist_event FinishFoxShadowFeatEvent

    # ------------------
    # 狐シュート
    # ------------------

    # 狐ショットが使用されたかのチェック
    def check_fox_shoot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOX_SHOOT)
      # テーブルにアクションカードがおかれていてかつ、距離が遠距離の時
      check_feat(FEAT_FOX_SHOOT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFoxShootFeatEvent
    regist_event CheckAddFoxShootFeatEvent
    regist_event CheckRotateFoxShootFeatEvent

    # 狐ショットが使用される
    def use_fox_shoot_feat()
      if @feats_enable[FEAT_FOX_SHOOT]
        multi_pt = Feat.pow(@feats[FEAT_FOX_SHOOT]) > 2 ? Feat.pow(@feats[FEAT_FOX_SHOOT]) : Feat.pow(@feats[FEAT_FOX_SHOOT]) + 1
        add_pt = Feat.pow(@feats[FEAT_FOX_SHOOT]) * 2 - 2
        ret = @cc.owner.get_same_number_both_sides_table_count(1)    # ret = [count:int, paralysis, poison]
        @fox_shoot_feat_paralysis_turn = ret[1]
        @fox_shoot_feat_poison_turn = ret[2]
        @cc.owner.tmp_power += add_pt + multi_pt * ret[0]
      end
    end
    regist_event UseFoxShootFeatEvent

    # 狐ショットが使用終了される
    def finish_fox_shoot_feat()
      if @feats_enable[FEAT_FOX_SHOOT]
        use_feat_event(@feats[FEAT_FOX_SHOOT])
      end
    end
    regist_event FinishFoxShootFeatEvent

    # 狐ショットが使用終了される
    def use_fox_shoot_feat_damage()
      if @feats_enable[FEAT_FOX_SHOOT]
        @feats_enable[FEAT_FOX_SHOOT] = false
        if duel.tmp_damage > 0
          if @fox_shoot_feat_paralysis_turn > 0
            buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, @fox_shoot_feat_paralysis_turn);
            on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
          end
          if @fox_shoot_feat_poison_turn > 0
            buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, @fox_shoot_feat_poison_turn);
            on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
          end
        end
        @fox_shoot_feat_paralysis_turn = 0
        @fox_shoot_feat_poison_turn = 0
      end
    end
    regist_event UseFoxShootFeatDamageEvent

    # ------------------
    # 狐空間
    # ------------------
    # 狐空間が使用されたかのチェック
    def check_fox_zone_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOX_ZONE)
      # テーブルにアクションカードがおかれている
      if owner.get_battle_table_point(ActionCard::ARW) > 0
        check_feat(FEAT_FOX_ZONE)
      else
        off_feat_event(FEAT_FOX_ZONE)
        @feats_enable[FEAT_FOX_ZONE] = false
      end
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFoxZoneFeatEvent
    regist_event CheckAddFoxZoneFeatEvent
    regist_event CheckRotateFoxZoneFeatEvent

    # 狐空間を使用
    def use_fox_zone_feat_attack_deal()
      if @feats_enable[FEAT_FOX_ZONE] && owner.initiative
        deal_num = @fox_zone_arrow_set.size == @fox_zone_arrow_set_size ? ((@fox_zone_arrow_set_size+1)/2).to_i : @fox_zone_arrow_set.size
        deal_arrow(deal_num, true) if deal_num > 0
      end
    end
    regist_event UseFoxZoneFeatAttackDealDetCharaChangeEvent
    regist_event UseFoxZoneFeatAttackDealChangeInitiativeEvent

    def use_fox_zone_feat_defense_deal()
      if @feats_enable[FEAT_FOX_ZONE]
        deal_num = @fox_zone_arrow_set.size == @fox_zone_arrow_set_size ? ((@fox_zone_arrow_set_size+1)/2).to_i : @fox_zone_arrow_set.size
        deal_arrow(deal_num) if deal_num > 0
      end
    end
    regist_event UseFoxZoneFeatDefenseDealEvent

    def use_fox_zone_feat()
      if @feats_enable[FEAT_FOX_ZONE]
        @fox_zone_arrow_set = owner.convert_to_arrow(ActionCard::ARW)
        @fox_zone_arrow_set_size = @fox_zone_arrow_set.size
        use_feat_event(@feats[FEAT_FOX_ZONE])
        foe.tmp_power -= 1 if foe.tmp_power > 0
      end
    end
    regist_event UseFoxZoneFeatEvent

    def finish_fox_zone_feat()
      if @feats_enable[FEAT_FOX_ZONE]
        @feats_enable[FEAT_FOX_ZONE] = false
      end
    end
    regist_event FinishFoxZoneFeatEvent

    def deal_arrow(n, pop=false)
      cid = 0
      n.times do
        if pop
          cid = @fox_zone_arrow_set.pop
        else
          cid = @fox_zone_arrow_set.shift
        end

        ret = duel.get_event_deck(owner).replace_event_cards(cid,1,true)
        if ret > 0
          @cc.owner.special_event_card_dealed_event(duel.get_event_deck(owner).draw_cards_event(1).each{ |c| @cc.owner.dealed_event(c)})
        end
      end
    end

    # ------------------
    # アローレイン
    # ------------------
    # アローレインが使用されたかのチェック
    def check_arrow_rain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ARROW_RAIN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ARROW_RAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveArrowRainFeatEvent
    regist_event CheckAddArrowRainFeatEvent
    regist_event CheckRotateArrowRainFeatEvent

    # アローレインが使用される
    # 有効の場合必殺技IDを返す
    def use_arrow_rain_feat()
      if @feats_enable[FEAT_ARROW_RAIN]
        ret = @cc.owner.get_same_number_both_sides_table_count(1)
        @arrow_rain_feat_num = ret[0]
      end
    end
    regist_event UseArrowRainFeatEvent

    # アローレインが使用終了
    def finish_arrow_rain_feat()
      if @feats_enable[FEAT_ARROW_RAIN]
        @feats_enable[FEAT_ARROW_RAIN] = false
        use_feat_event(@feats[FEAT_ARROW_RAIN])
        rain_num = @arrow_rain_feat_num < foe.current_chara_card.rarity ? @arrow_rain_feat_num : foe.current_chara_card.rarity

        if rain_num > 0

          paralysis_targets = []
          poison_targets = []

          rain_num.times do |c|
            hps = []
            duel.second_entrant.hit_points.each_index do |i|
              hps << i if duel.second_entrant.hit_points[i] > 0
            end

            if hps.count > 0

              idx = hps[rand(hps.size)]

              attribute_party_damage(foe, idx, 1)

              # 夜雨が使われている場合に状態異常を撒く
              if @feats_enable[FEAT_FOX_SHOOT]
                if @fox_shoot_feat_paralysis_turn > 0
                  paralysis_targets << idx unless paralysis_targets.include?(idx)
                  @fox_shoot_feat_paralysis_turn -= 1
                elsif @fox_shoot_feat_poison_turn > 0
                  poison_targets << idx unless poison_targets.include?(idx)
                  @fox_shoot_feat_poison_turn -= 1
                end
              end
            end
          end

          paralysis_targets.each do |i|
            buffed = set_state(foe.chara_cards[i].status[STATE_PARALYSIS], 1, 1);
            on_buff_event(false,
                          i,
                          STATE_PARALYSIS,
                          foe.chara_cards[i].status[STATE_PARALYSIS][0],
                          foe.chara_cards[i].status[STATE_PARALYSIS][1]) if buffed
          end

          poison_targets.each do |i|
            buffed = set_state(foe.chara_cards[i].status[STATE_POISON], 1, 1);
            on_buff_event(false,
                          i,
                          STATE_POISON,
                          foe.chara_cards[i].status[STATE_POISON][0],
                          foe.chara_cards[i].status[STATE_POISON][1]) if buffed
          end

        end
      end
    end
    regist_event FinishArrowRainFeatEvent

    # ------------------
    # 光輝強迫
    # ------------------

    # 光輝強迫が使用されたかのチェック
    def check_atemwende_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ATEMWENDE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ATEMWENDE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAtemwendeFeatEvent
    regist_event CheckAddAtemwendeFeatEvent
    regist_event CheckRotateAtemwendeFeatEvent

    # 光輝強迫の効果が発揮される
    def use_atemwende_feat()
      if @feats_enable[FEAT_ATEMWENDE]
        @atemwende_on = true
        use_feat_event(@feats[FEAT_ATEMWENDE])
      end
    end
    regist_event UseAtemwendeFeatEvent

    # キャラチェンジで出てきた場合の処理
    def finish_change_atemwende_feat()
      if @atemwende_on
        @feats_enable[FEAT_ATEMWENDE] = true
        on_feat_event(FEAT_ATEMWENDE)
      end
    end
    regist_event FinishChangeAtemwendeFeatEvent

    # 光輝強迫が終了
    def finish_turn_atemwende_feat()
      if @feats_enable[FEAT_ATEMWENDE]
        @feats_enable[FEAT_ATEMWENDE] = false
        @atemwende_on = false
      end
    end
    regist_event FinishTurnAtemwendeFeatEvent

    # ------------------
    # 雪の重唱
    # ------------------
    # 雪の重唱が使用されたかのチェック
    def check_fadensonnen_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FADENSONNEN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FADENSONNEN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFadensonnenFeatEvent
    regist_event CheckAddFadensonnenFeatEvent
    regist_event CheckRotateFadensonnenFeatEvent

    # 雪の重唱が使用される
    # 有効の場合必殺技IDを返す
    def use_fadensonnen_feat()
      if @feats_enable[FEAT_FADENSONNEN]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FADENSONNEN])
      end
    end
    regist_event UseFadensonnenFeatEvent

    # 雪の重唱が使用終了
    def finish_fadensonnen_feat()
      if @feats_enable[FEAT_FADENSONNEN]
        use_feat_event(@feats[FEAT_FADENSONNEN])
        @feats_enable[FEAT_FADENSONNEN] = false
        const_damage = 4
        trigger = @feats_enable[FEAT_ATEMWENDE] ? 20 * Feat.pow(@feats[FEAT_ATEMWENDE]) : 20
        r = rand(100)
        duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, const_damage)) if trigger > r
      end
    end
    regist_event FinishFadensonnenFeatEvent

    # ------------------
    # 紡がれる陽
    # ------------------

    # 紡がれる陽が使用されたかのチェック
    def check_lichtzwang_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LICHTZWANG)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_LICHTZWANG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLichtzwangFeatEvent
    regist_event CheckAddLichtzwangFeatEvent
    regist_event CheckRotateLichtzwangFeatEvent

    # 紡がれる陽が使用される
    # 有効の場合必殺技IDを返す
    def use_lichtzwang_feat()
      if @feats_enable[FEAT_LICHTZWANG]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_LICHTZWANG])
      end
    end
    regist_event UseLichtzwangFeatEvent

    # 紡がれる陽が使用終了される
    def finish_lichtzwang_feat()
      if @feats_enable[FEAT_LICHTZWANG]
        use_feat_event(@feats[FEAT_LICHTZWANG])

        atk_count = 3
        const_damage = 3
        trigger = @feats_enable[FEAT_ATEMWENDE] ? 20 * Feat.pow(@feats[FEAT_ATEMWENDE]) : 20

        total_const_damage = 0
        atk_count.times do |c|

          r = rand(100)
          if trigger > r
            hps = []
            duel.second_entrant.hit_points.each_index do |i|
              hps << i if duel.second_entrant.hit_points[i] > 0
            end

            if hps.count > 0
              attribute_party_damage(foe, hps[rand(hps.size)], const_damage)
              if @feats_enable[FEAT_SCHNEEPART]
                total_const_damage += const_damage
              end
            end
          end
        end
        heal_pt = (total_const_damage / Feat.pow(@feats[FEAT_SCHNEEPART])).to_i
        owner.healed_event(heal_pt) if heal_pt > 0
      end
    end
    regist_event FinishLichtzwangFeatEvent

    # 紡がれる陽を終了
    # 溜息のの終了に合せて終わらせる
    def use_lichtzwang_feat_damage()
      if @feats_enable[FEAT_LICHTZWANG]
        @feats_enable[FEAT_LICHTZWANG] = false
      end
    end
    regist_event UseLichtzwangFeatDamageEvent

    # ------------------
    # 溜息の転換
    # ------------------
    # 溜息の転換が使用されたかのチェック
    def check_schneepart_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SCHNEEPART)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SCHNEEPART)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSchneepartFeatEvent
    regist_event CheckAddSchneepartFeatEvent
    regist_event CheckRotateSchneepartFeatEvent

    # 溜息の転換が使用される
    # 有効の場合必殺技IDを返す
    def use_schneepart_feat()
    end
    regist_event UseSchneepartFeatEvent

    # 溜息の転換が使用終了
    def finish_schneepart_feat()
      if @feats_enable[FEAT_SCHNEEPART] && @feats_enable[FEAT_SCHNEEPART]
        use_feat_event(@feats[FEAT_SCHNEEPART])
      end
    end
    regist_event FinishSchneepartFeatEvent

    # 溜息の転換が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_schneepart_feat_damage()
      if @feats_enable[FEAT_SCHNEEPART] && @feats_enable[FEAT_SCHNEEPART]
        # ダメージが1以上
        if duel.tmp_damage > 1 && @feats_enable[FEAT_LICHTZWANG]
          @cc.owner.healed_event((duel.tmp_damage/Feat.pow(FEAT_SCHNEEPART)).to_i) if owner.hit_point>0
        end
        @feats_enable[FEAT_SCHNEEPART] = false
      end
    end
    regist_event UseSchneepartFeatDamageEvent

    # ------------------
    # ハイゲート
    # ------------------
    # ハイゲートが使用されたかのチェック
    def check_highgate_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HIGHGATE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HIGHGATE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveHighgateFeatEvent
    regist_event CheckAddHighgateFeatEvent
    regist_event CheckRotateHighgateFeatEvent

    # ハイゲートの効果が発揮される
    def use_highgate_feat()
      if @feats_enable[FEAT_HIGHGATE]
        owner.is_highgate = true
        use_feat_event(@feats[FEAT_HIGHGATE])
        set_state(@cc.status[STATE_SEAL], 1, 1)
        on_buff_event(true, owner.current_chara_card_no, STATE_SEAL, @cc.status[STATE_SEAL][0], @cc.status[STATE_SEAL][1])
        @feats_enable[FEAT_HIGHGATE] = false
      end
    end
    regist_event UseHighgateFeatEvent

    # ダメージ軽減処理
    def check_harbour
      if @cc.using && !owner.initiative && owner.is_highgate && duel.tmp_damage > 0
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << i if duel.second_entrant.hit_points[i] > 0 && duel.second_entrant.chara_cards[i].charactor_id == 4010
        end

        if hps.count > 0
          attribute_party_damage(owner, hps[0], (duel.tmp_damage/2).to_i)
          # ToDo 状態クリア
          duel.tmp_damage = 0
          set_state(owner.chara_cards[hps[0]].status[STATE_SEAL], 1, 0)
          off_buff_event(true, hps[0], STATE_SEAL, owner.chara_cards[hps[0]].status[STATE_SEAL][0])
        end

        owner.is_highgate = false
      end
    end
    regist_event CheckHarbourEvent

    # ------------------
    # ドルフルフト
    # ------------------
    # ドルフルフトが使用されたかのチェック
    def check_dorfloft_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DORFLOFT)
      # テーブルにアクションカードがおかれていてかつ、距離が中・遠距離の時
      check_feat(FEAT_DORFLOFT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDorfloftFeatEvent
    regist_event CheckAddDorfloftFeatEvent
    regist_event CheckRotateDorfloftFeatEvent

    # ドルフルフトが使用される
    # 有効の場合必殺技IDを返す
    def use_dorfloft_feat()
      if @feats_enable[FEAT_DORFLOFT]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DORFLOFT])
      end
    end
    regist_event UseDorfloftFeatEvent

    #ドルフルフトが使用される
    # 有効の場合必殺技IDを返す
    def use_dorfloft_feat_damage()
      if @feats_enable[FEAT_DORFLOFT]
        use_feat_event(@feats[FEAT_DORFLOFT])
        @feats_enable[FEAT_DORFLOFT] = false
        m = @cc.owner.get_battle_table_point(ActionCard::MOVE)
        @cc.owner.move_action(-m)
        @cc.foe.move_action(-m)
        if owner.distance == 1 && !instant_kill_guard?(foe)
          buffed = set_state(foe.current_chara_card.status[STATE_STOP], 1, 1);
          on_buff_event(false, foe.current_chara_card_no, STATE_STOP, foe.current_chara_card.status[STATE_STOP][0], foe.current_chara_card.status[STATE_STOP][1]) if buffed
        end
      end
    end
    regist_event UseDorfloftFeatDamageEvent

    # ------------------
    # ルミネセンス
    # ------------------
    # ルミネセンスが使用されたかのチェック
    def check_lumines_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LUMINES)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LUMINES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLuminesFeatEvent
    regist_event CheckAddLuminesFeatEvent
    regist_event CheckRotateLuminesFeatEvent

    # ルミネセンスの状態
    def use_lumines_feat()
      if @feats_enable[FEAT_LUMINES]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_LUMINES]) + owner.get_battle_table_point(ActionCard::DEF)*4
      end
    end
    regist_event UseLuminesFeatEvent

    # ルミネセンスが使用される
    def finish_lumines_feat()
      if @feats_enable[FEAT_LUMINES]
        use_feat_event(@feats[FEAT_LUMINES])
      end
    end
    regist_event FinishLuminesFeatEvent

    # ルミネセンスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_lumines_feat_damage()
      if @feats_enable[FEAT_LUMINES]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_SEAL], 1, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_SEAL, foe.current_chara_card.status[STATE_SEAL][0], foe.current_chara_card.status[STATE_SEAL][1]) if buffed
        end
        @feats_enable[FEAT_LUMINES] = false
      end
    end
    regist_event UseLuminesFeatDamageEvent

    # ------------------
    # スーパーヒロイン(復活)
    # ------------------

    # スーパーヒロインが使用されたかのチェック
    def check_super_heroine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SUPER_HEROINE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SUPER_HEROINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveSuperHeroineFeatEvent
    regist_event CheckAddSuperHeroineFeatEvent
    regist_event CheckRotateSuperHeroineFeatEvent

    # スーパーヒロインを使用
    def finish_super_heroine_feat()
      if @feats_enable[FEAT_SUPER_HEROINE]
        use_feat_event(@feats[FEAT_SUPER_HEROINE])
        @feats_enable[FEAT_SUPER_HEROINE] = false
        set_state(@cc.status[STATE_ATK_UP], 6, Feat.pow(@feats[FEAT_SUPER_HEROINE]))
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        set_state(@cc.status[STATE_DEF_UP], 4, Feat.pow(@feats[FEAT_SUPER_HEROINE]))
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        set_state(@cc.status[STATE_MOVE_UP], 1, Feat.pow(@feats[FEAT_SUPER_HEROINE]));
        on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
      end
    end
    regist_event FinishSuperHeroineFeatEvent

    # ------------------
    # スタンピード
    # ------------------
    # スタンピードが使用されたかのチェック
    def check_stampede_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_STAMPEDE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_STAMPEDE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveStampedeFeatEvent
    regist_event CheckAddStampedeFeatEvent
    regist_event CheckRotateStampedeFeatEvent

    # 必殺技の状態
    def use_stampede_feat()
      if @feats_enable[FEAT_STAMPEDE]
      end
    end
    regist_event UseStampedeFeatEvent

    # スタンピードが使用される
    def finish_stampede_feat()
      if @feats_enable[FEAT_STAMPEDE]
        use_feat_event(@feats[FEAT_STAMPEDE])
      end
    end
    regist_event FinishStampedeFeatEvent

    # スタンピードが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_stampede_feat_damage()
      if @feats_enable[FEAT_STAMPEDE]
        if duel.tmp_damage>0
          buff_list = { STATE_PARALYSIS => 2, STATE_POISON => 3, STATE_SEAL => 2, STATE_DEAD_COUNT => 4 }
          dead_count_turn = 4
          other_buff_turn = 2
          buff_list.delete(STATE_DEAD_COUNT) if foe.current_chara_card.status[STATE_DEAD_COUNT][1] > 0
          cnt = rand(2) + 1
          shuffled_list = buff_list.sort_by{rand}

          shuffled_list.each_with_index do |b, i|
            buff = b[0]
            turn = b[1]
            buffed = set_state(foe.current_chara_card.status[buff], 1, turn);
            on_buff_event(false, foe.current_chara_card_no, buff, foe.current_chara_card.status[buff][0], foe.current_chara_card.status[buff][1]) if buffed
            break if i == cnt - 1
          end

        end
        @feats_enable[FEAT_STAMPEDE] = false
      end
    end
    regist_event UseStampedeFeatDamageEvent

    # ------------------
    # D・コントロール(復活)
    # ------------------
    # D・コントロールが使用されたかのチェック
    def check_death_control2_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DEATH_CONTROL2)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DEATH_CONTROL2)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeathControl2FeatEvent
    regist_event CheckAddDeathControl2FeatEvent
    regist_event CheckRotateDeathControl2FeatEvent

    # 必殺技の状態
    def use_death_control2_feat()
      if @feats_enable[FEAT_DEATH_CONTROL2]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DEATH_CONTROL2])
      end
    end
    regist_event UseDeathControl2FeatEvent

    # D・コントロールが使用される
    def finish_death_control2_feat()
      if @feats_enable[FEAT_DEATH_CONTROL2]
      end
    end
    regist_event FinishDeathControl2FeatEvent

    # D・コントロールが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_death_control2_feat_damage()
      if @feats_enable[FEAT_DEATH_CONTROL2]
        use_feat_event(@feats[FEAT_DEATH_CONTROL2])
        if duel.tmp_damage>0

          foe_dead_count_num = foe.current_chara_card.status[STATE_DEAD_COUNT][1]
          own_dead_count_num = owner.current_chara_card.status[STATE_DEAD_COUNT][1]

          if foe_dead_count_num == 0

            foe_dead_count_num = Feat.pow(@feats[FEAT_DEATH_CONTROL2]) >= 15 ? 4 : 5
            buffed = set_state(foe.current_chara_card.status[STATE_DEAD_COUNT], 1, foe_dead_count_num);
            on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], foe.current_chara_card.status[STATE_DEAD_COUNT][1]) if buffed

          else

            # レイド戦の場合。ステータスArray[1]を1以下にしない(0で通常戦闘時の挙動をするため)。
            foe.current_chara_card.status[STATE_DEAD_COUNT][1] -= 1 unless (!@cc.status_update && foe_dead_count_num == 1)
            update_buff_event(false, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0])

            if own_dead_count_num > 0 && own_dead_count_num < 9

              @cc.status[STATE_DEAD_COUNT][1] += 1
              update_buff_event(true, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0], owner.current_chara_card_no, 1)

            end

            if foe_dead_count_num == 1

              # レイド戦の場合。表示上の残り時間を0にする。
              if @cc.status_update
                off_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, @cc.status[STATE_DEAD_COUNT][0])
                foe.current_chara_card.status[STATE_DEAD_COUNT][1] = 0
              else
                on_buff_event(false, foe.current_chara_card_no, STATE_DEAD_COUNT, foe.current_chara_card.status[STATE_DEAD_COUNT][0], 0)
              end
              foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, foe))

            end
          end
        end
        @feats_enable[FEAT_DEATH_CONTROL2] = false
      end
    end
    regist_event UseDeathControl2FeatDamageEvent

    # ------------------
    # 俺様の剣技に見惚れろ
    # ------------------
    # 俺様の剣技に見惚れろが使用されたかのチェック
    def check_kengi_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KENGI)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_KENGI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKengiFeatEvent
    regist_event CheckAddKengiFeatEvent
    regist_event CheckRotateKengiFeatEvent

    # 俺様の剣技に見惚れろが使用
    def use_kengi_feat()
      if @feats_enable[FEAT_KENGI]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_KENGI])
        @kengi_feat_count = owner.get_type_point_table_count(ActionCard::BLNK, 1, true)
      end
    end
    regist_event UseKengiFeatEvent

    def use_kengi_feat_roll_chancel
      if @feats_enable[FEAT_KENGI]
        # 通常のダイスロールはキャンセルする
        duel.roll_cancel=(true)
      end
    end
    regist_event UseKengiFeatRollChancelEvent

    # 俺様の剣技に見惚れろが使用
    def use_kengi_feat_battle_result
      if @feats_enable[FEAT_KENGI]
        use_feat_event(@feats[FEAT_KENGI])

        # 実際に見せるダイスロール
        result = duel.battle_result

        fumble_cnt = 0
        @kengi_feat_count.times do |n|
          idx = result[1].index{ |elem| elem > 3 }
          if idx.nil?
            break
          else
            result[1][idx] = -1
            fumble_cnt += 1
          end
        end
        duel.tmp_dice_heads_def -= fumble_cnt if duel.tmp_dice_heads_def > 0

        if @feats_enable[FEAT_HONTOU]
          result[0] = Array.new(result[0].length, 6)
          duel.tmp_dice_heads_atk = result[0].length
        end

        result[1].shuffle! if fumble_cnt
        owner.dice_roll_event(result)
        dmg = duel.tmp_dice_heads_atk - duel.tmp_dice_heads_def
        duel.tmp_damage = dmg > 0 ? dmg : 0

      end
    end
    regist_event UseKengiFeatBattleResultEvent

    # 俺様の剣技に見惚れろが使用終了される
    def finish_kengi_feat
      if @feats_enable[FEAT_KENGI]
        @feats_enable[FEAT_KENGI] = false
      end
    end
    regist_event FinishKengiFeatEvent

    # ------------------
    # 何処を見てやがる
    # ------------------
    # 何処をみてやがるが使用されたかのチェック
    def check_dokowo_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DOKOWO)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DOKOWO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDokowoFeatEvent
    regist_event CheckAddDokowoFeatEvent
    regist_event CheckRotateDokowoFeatEvent

    # 何処をみてやがるを使用
    def finish_dokowo_feat()
      if @feats_enable[FEAT_DOKOWO]
        use_feat_event(@feats[FEAT_DOKOWO])
        @feats_enable[FEAT_DOKOWO] = false
        # 移動方向を制御
        if foe.direction == Entrant::DIRECTION_FORWARD
          foe.set_direction(Entrant::DIRECTION_BACKWARD)
        elsif foe.direction == Entrant::DIRECTION_BACKWARD
          foe.set_direction(Entrant::DIRECTION_FORWARD)
        end
      end
    end
    regist_event FinishDokowoFeatEvent

    # ------------------
    # お前の技は見切った
    # ------------------
    # お前の技は見切ったが使用されたかのチェック
    def check_mikitta_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MIKITTA)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MIKITTA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMikittaFeatEvent
    regist_event CheckAddMikittaFeatEvent
    regist_event CheckRotateMikittaFeatEvent

    # お前の技は見切ったが使用終了
    def finish_mikitta_feat()
      if @feats_enable[FEAT_MIKITTA]
        use_feat_event(@feats[FEAT_MIKITTA])
        duel.tmp_damage = 0
        owner.damaged_event(1,IS_NOT_HOSTILE_DAMAGE)
        @feats_enable[FEAT_MIKITTA] = false
      end
    end
    regist_event FinishMikittaFeatEvent

    # ------------------
    # これが俺様の本当の力だ
    # ------------------
    # これが俺様の本当の力だが使用されたかのチェック
    def check_hontou_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HONTOU)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_HONTOU)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHontouFeatEvent
    regist_event CheckAddHontouFeatEvent
    regist_event CheckRotateHontouFeatEvent

    # これが俺様の本当の力だが使用
    def use_hontou_feat()
      if @feats_enable[FEAT_HONTOU]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_HONTOU])
      end
    end
    regist_event UseHontouFeatEvent

    def use_hontou_feat_roll_chancel
      if @feats_enable[FEAT_HONTOU] && !@feats_enable[FEAT_KENGI]
        # 通常のダイスロールはキャンセルする
        duel.roll_cancel=(true)
      end
    end
    regist_event UseHontouFeatRollChancelEvent

    # これが俺様の本当の力だが使用
    def use_hontou_feat_battle_result
      if @feats_enable[FEAT_HONTOU]
        use_feat_event(@feats[FEAT_HONTOU])

        if !@feats_enable[FEAT_KENGI]
          # 実際に見せるダイスロール
          result = duel.battle_result

          result[0] = Array.new(result[0].length, 6)
          duel.tmp_dice_heads_atk = result[0].length

          owner.dice_roll_event(result)
          dmg = duel.tmp_dice_heads_atk - duel.tmp_dice_heads_def
          duel.tmp_damage = dmg > 0 ? dmg : 0
        end

      end
    end
    regist_event UseHontouFeatBattleResultEvent

    # これが俺様の本当の力だが終了
    def finish_hontou_feat
      if @feats_enable[FEAT_HONTOU]
        @feats_enable[FEAT_HONTOU] = false
      end
    end
    regist_event FinishHontouFeatEvent

    # ------------------
    # 招かれしものども
    # ------------------
    # 招かれしものどもが使用されたかのチェック
    def check_invited_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_INVITED)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_INVITED)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveInvitedFeatEvent
    regist_event CheckAddInvitedFeatEvent
    regist_event CheckRotateInvitedFeatEvent

    # 招かれしものどもを使用
    def finish_invited_feat()
      if @feats_enable[FEAT_INVITED]
        use_feat_event(@feats[FEAT_INVITED])
        @feats_enable[FEAT_INVITED] = false
        @cc.owner.special_dealed_event(duel.deck.draw_low_cards_event(Feat.pow(@feats[FEAT_INVITED])).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishInvitedFeatEvent

    # ------------------
    # 透き通る手
    # ------------------
    # 透き通る手が使用されたかのチェック
    def check_through_hand_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THROUGH_HAND)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_THROUGH_HAND)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveThroughHandFeatEvent
    regist_event CheckAddThroughHandFeatEvent
    regist_event CheckRotateThroughHandFeatEvent

    # 透き通る手が使用される
    def use_through_hand_feat()
      if @feats_enable[FEAT_THROUGH_HAND]
        use_feat_event(@feats[FEAT_THROUGH_HAND])
        @feats_enable[FEAT_THROUGH_HAND] = false
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_THROUGH_HAND])))
        owner.healed_event(1) if owner.hit_point > 0
      end
    end
    regist_event UseThroughHandFeatEvent

    # ------------------
    # 深遠なる息
    # ------------------
    # 深遠なる息が使用されたかのチェック
    def check_prof_breath_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PROF_BREATH)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PROF_BREATH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveProfBreathFeatEvent
    regist_event CheckAddProfBreathFeatEvent
    regist_event CheckRotateProfBreathFeatEvent

    # 深遠なる息を使用
    def finish_prof_breath_feat()
      if @feats_enable[FEAT_PROF_BREATH]
        use_feat_event(@feats[FEAT_PROF_BREATH])
        @feats_enable[FEAT_PROF_BREATH] = false
        ret = duel.get_event_deck(owner).replace_event_cards(FOCUS_EVENT_CARD_MOVE20,1,true)
        if ret > 0
          @cc.owner.special_event_card_dealed_event(duel.get_event_deck(owner).draw_cards_event(1).each{ |c| @cc.owner.dealed_event(c)})
        end
      end
    end
    regist_event FinishProfBreathFeatEvent

    # ------------------
    # 7つの願い
    # ------------------
    # 7つの願いが使用されたかのチェック
    def check_seven_wish_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SEVEN_WISH)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SEVEN_WISH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSevenWishFeatEvent
    regist_event CheckAddSevenWishFeatEvent
    regist_event CheckRotateSevenWishFeatEvent

    def use_seven_wish_feat
      if @feats_enable[FEAT_SEVEN_WISH]
        @seven_wish_feat_pow = @cc.owner.get_battle_table_point(ActionCard::SPC) + 1
      end
    end
    regist_event UseSevenWishFeatEvent

    # 7つの願いが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_seven_wish_feat_damage()
      if @feats_enable[FEAT_SEVEN_WISH]
        # HPがマイナスで1度だけ発動, レイドボス・ボスに無効
        if owner.hit_point <= Feat.pow(@feats[FEAT_SEVEN_WISH]) &&
            foe.current_chara_card.kind != CC_KIND_BOSS_MONSTAR &&
            foe.current_chara_card.kind != CC_KIND_PROFOUND_BOSS

          set_state(foe.current_chara_card.special_status[SPECIAL_STATE_CAT], 1, @seven_wish_feat_pow)
          on_transform_sequence(false, TRANSFORM_TYPE_CAT)
        end
        use_feat_event(@feats[FEAT_SEVEN_WISH])
        @feats_enable[FEAT_SEVEN_WISH] = false
      end
    end
    regist_event UseSevenWishFeatDamageEvent

    # ------------------
    # 13の眼(復活)
    # ------------------
    # 13の眼が使用されたかのチェック
    def check_thirteen_eyes_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THIRTEEN_EYES_R)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_THIRTEEN_EYES_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThirteenEyesRFeatEvent
    regist_event CheckAddThirteenEyesRFeatEvent
    regist_event CheckRotateThirteenEyesRFeatEvent

    # 13の眼が使用される
    # 有効の場合必殺技IDを返す
    def use_thirteen_eyes_r_feat()
      if @feats_enable[FEAT_THIRTEEN_EYES_R]
        owner.tmp_power = 13
        foe.tmp_power = 0
      end
    end
    regist_event UseOwnerThirteenEyesRFeatEvent
    regist_event UseFoeThirteenEyesRFeatEvent

    # 13の眼が使用終了
    def finish_thirteen_eyes_r_feat()
      if @feats_enable[FEAT_THIRTEEN_EYES_R]
        use_feat_event(@feats[FEAT_THIRTEEN_EYES_R])
        owner.tmp_power = 13
        foe.tmp_power = 0
        owner.point_rewrite_event
        foe.point_rewrite_event
      end
    end
    regist_event FinishThirteenEyesRFeatEvent

    # 13の眼追加ダメージ
    def use_thirteen_eyes_r_feat_damage()
      if @feats_enable[FEAT_THIRTEEN_EYES_R]
        @feats_enable[FEAT_THIRTEEN_EYES_R] = false

        if duel.tmp_damage <= Feat.pow(@feats[FEAT_THIRTEEN_EYES_R])
          rec_damage = duel.tmp_damage
          @cc.owner.dice_roll_event(duel.battle_result)
          owner.special_message_event(:EX_THIRTEEN_EYES, duel.tmp_damage.to_s)
          duel.tmp_damage += rec_damage
        end
      end
    end
    regist_event UseThirteenEyesRFeatDamageEvent

    # ------------------
    # 茨の構え(復活)
    # ------------------
    # 茨の構え(復活)が使用されたかのチェック
    def check_thorn_care_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THORN_CARE_R)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_THORN_CARE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThornCareRFeatEvent
    regist_event CheckAddThornCareRFeatEvent
    regist_event CheckRotateThornCareRFeatEvent

    # 茨の構え(復活)が使用される
    # 有効の場合必殺技IDを返す
    def use_thorn_care_r_feat()
      if @feats_enable[FEAT_THORN_CARE_R]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::MOVE)*Feat.pow(@feats[FEAT_THORN_CARE_R]))
      end
    end
    regist_event UseThornCareRFeatEvent

    # 茨の構え(復活)が使用終了
    def finish_thorn_care_r_feat()
      if @feats_enable[FEAT_THORN_CARE_R]
        use_feat_event(@feats[FEAT_THORN_CARE_R])
      end
    end
    regist_event FinishThornCareRFeatEvent

    # 茨の構え(復活)が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_thorn_care_r_feat_damage()
      if @feats_enable[FEAT_THORN_CARE_R]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          # buff処理
          buff_pow = 4
          set_state(@cc.status[STATE_ATK_UP], buff_pow, 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
          set_state(@cc.status[STATE_DEF_UP], buff_pow, 3)
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        end
        @feats_enable[FEAT_THORN_CARE_R] = false
      end
    end
    regist_event UseThornCareRFeatDamageEvent


    # ------------------
    # 解放剣(復活)
    # ------------------
    # 解放剣(復活)が使用されたかのチェック
    def check_liberating_sword_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LIBERATING_SWORD_R)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_LIBERATING_SWORD_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLiberatingSwordRFeatEvent
    regist_event CheckAddLiberatingSwordRFeatEvent
    regist_event CheckRotateLiberatingSwordRFeatEvent

    # 必殺技の状態
    def use_liberating_sword_r_feat()
      if @feats_enable[FEAT_LIBERATING_SWORD_R]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_LIBERATING_SWORD_R])
      end
    end
    regist_event UseLiberatingSwordRFeatEvent

    # 解放剣(復活)が使用される
    def finish_liberating_sword_r_feat()
      if @feats_enable[FEAT_LIBERATING_SWORD_R]
        use_feat_event(@feats[FEAT_LIBERATING_SWORD_R])
      end
    end
    regist_event FinishLiberatingSwordRFeatEvent

    # 解放剣(復活)が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_liberating_sword_r_feat_damage()
      if @feats_enable[FEAT_LIBERATING_SWORD_R]
        dmg = 0
        foe.current_chara_card.status.each do |i|
          dmg+=1 if i[1] > 0
        end
        @cc.status.each do |i|
          dmg+=1 if i[1] > 0
        end
        dmg = (dmg*1.5).to_i
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg))
        @feats_enable[FEAT_LIBERATING_SWORD_R] = false
      end
    end
    regist_event UseLiberatingSwordRFeatDamageEvent

    # ------------------
    # 呪剣(復活)
    # ------------------
    # 呪剣(復活)が使用されたかのチェック
    def check_curse_sword_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CURSE_SWORD_R)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_CURSE_SWORD_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCurseSwordRFeatEvent
    regist_event CheckAddCurseSwordRFeatEvent
    regist_event CheckRotateCurseSwordRFeatEvent

    # 必殺技の状態
    def use_curse_sword_r_feat()
      if @feats_enable[FEAT_CURSE_SWORD_R]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_CURSE_SWORD_R])
      end
    end
    regist_event UseCurseSwordRFeatEvent

    # 呪剣(復活)が使用される
    def finish_curse_sword_r_feat()
      if @feats_enable[FEAT_CURSE_SWORD_R]
        use_feat_event(@feats[FEAT_CURSE_SWORD_R])

        if @cc.status[STATE_POISON][1] > 0
          set_state(@cc.status[STATE_POISON2], 1, @cc.status[STATE_POISON][1])
          on_buff_event(true, owner.current_chara_card_no, STATE_POISON2, @cc.status[STATE_POISON2][0], @cc.status[STATE_POISON2][1])
        else
          set_state(@cc.status[STATE_POISON], 1, 2)
          on_buff_event(true, owner.current_chara_card_no, STATE_POISON, @cc.status[STATE_POISON][0], @cc.status[STATE_POISON][1])
        end
      end
    end
    regist_event FinishCurseSwordRFeatEvent

    # 呪剣(復活)が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_curse_sword_r_feat_damage()
      if @feats_enable[FEAT_CURSE_SWORD_R]
        if duel.tmp_damage>0
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            if duel.second_entrant.hit_points[i] > 0
              poison = @cc.status[STATE_POISON2][1] > 0 ? STATE_POISON2 : STATE_POISON
              buffed = set_state(foe.chara_cards[i].status[poison], 1, 3)
              on_buff_event(false, i, poison, foe.chara_cards[i].status[poison][0], foe.chara_cards[i].status[poison][1]) if buffed
            end
          end
        end
        @feats_enable[FEAT_CURSE_SWORD_R] = false
      end
    end
    regist_event UseCurseSwordRFeatDamageEvent

    # ------------------
    # 火の輪くぐり
    # ------------------
    # 火の輪くぐりが使用されたかのチェック
    def check_flame_ring_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FLAME_RING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FLAME_RING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFlameRingFeatEvent
    regist_event CheckAddFlameRingFeatEvent
    regist_event CheckRotateFlameRingFeatEvent

    # 火の輪くぐりが使用される
    # 有効の場合必殺技IDを返す
    def use_flame_ring_feat()
      if @feats_enable[FEAT_FLAME_RING]
        atk = 0
        if foe.current_chara_card.status[STATE_ATK_DOWN][1] > 0
          @cc.owner.tmp_power+=foe.current_chara_card.status[STATE_ATK_DOWN][0]
        end
        if foe.current_chara_card.status[STATE_DEF_DOWN][1] > 0
          @cc.owner.tmp_power+=foe.current_chara_card.status[STATE_DEF_DOWN][0]
        end
        if (foe.current_chara_card.status[STATE_STATE_DOWN][1] > 0)
          @cc.owner.tmp_power+=foe.current_chara_card.status[STATE_STATE_DOWN][1]*2
        end
      end
    end
    regist_event UseFlameRingFeatEvent

    # 火の輪くぐりが使用終了
    def finish_flame_ring_feat()
      if @feats_enable[FEAT_FLAME_RING]
        use_feat_event(@feats[FEAT_FLAME_RING])
        # 破棄候補のカード
        aca = []
        # 規定枚数を超えて所持している場合
        if foe.cards.length > Feat.pow(@feats[FEAT_FLAME_RING])
          foe.cards.shuffle.each do |c|
            aca << c
          end
          # 規定枚数を残して捨てる
          (foe.cards.length - Feat.pow(@feats[FEAT_FLAME_RING])).times do |a|
            if aca[a]
              discard(foe, aca[a])
            end
          end
        end

        aca = []
        # 規定枚数を超えて所持している場合
        if owner.cards.length > Feat.pow(@feats[FEAT_FLAME_RING])
          owner.cards.shuffle.each do |c|
            aca << c
          end
          # 規定枚数を残して捨てる
          (owner.cards.length - Feat.pow(@feats[FEAT_FLAME_RING])).times do |a|
            if aca[a]
              discard(owner, aca[a])
            end
          end
        end

      end
      @feats_enable[FEAT_FLAME_RING] = false
    end
    regist_event FinishFlameRingFeatEvent

    # ------------------
    # ピアノ
    # ------------------
    # ピアノが使用されたかのチェック
    def check_piano_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PIANO)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PIANO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePianoFeatEvent
    regist_event CheckAddPianoFeatEvent
    regist_event CheckRotatePianoFeatEvent

    # ピアノが使用される
    # 有効の場合必殺技IDを返す
    def use_piano_feat()
      if @feats_enable[FEAT_PIANO]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PIANO])
      end
    end
    regist_event UsePianoFeatEvent

    # ピアノが使用終了
    def finish_piano_feat()
      if @feats_enable[FEAT_PIANO]
        @feats_enable[FEAT_PIANO] = false
        use_feat_event(@feats[FEAT_PIANO])
      end
    end
    regist_event FinishPianoFeatEvent

    # ピアノが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_piano_feat_damage()
      if @feats_enable[FEAT_PIANO]
        cnt = foe.table_count
        if cnt > 0
          # buff処理
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], cnt, 2);
          on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        end
      end
    end
    regist_event UsePianoFeatDamageEvent

    # ------------------
    # 玉乗り
    # ------------------
    # 玉乗りが使用されたかのチェック
    def check_ona_ball_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ONA_BALL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ONA_BALL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveOnaBallFeatEvent
    regist_event CheckAddOnaBallFeatEvent
    regist_event CheckRotateOnaBallFeatEvent

    # 玉乗りを使用
    def finish_next_ona_ball_feat()
      if @feats_enable[FEAT_ONA_BALL]
        use_feat_event(@feats[FEAT_ONA_BALL])
        movability = []
        case owner.distance
        when 1
          movability = [1, 2]
        when 2
          movability = [-1, 1]
        when 3
          movability = [-1, -2]
        end
        move_point = movability[rand(movability.length)]
        @cc.owner.move_action(move_point)
        @cc.foe.move_action(move_point)
        mp_abs = move_point < 0 ? -move_point : move_point
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,mp_abs))
      end
      @feats_enable[FEAT_ONA_BALL] = false
    end
    regist_event FinishNextOnaBallFeatEvent

    # ------------------
    # 暴れる
    # ------------------
    # 暴れるが使用されたかのチェック
    def check_violent_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_VIOLENT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_VIOLENT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveViolentFeatEvent
    regist_event CheckAddViolentFeatEvent
    regist_event CheckRotateViolentFeatEvent

    # 暴れるが使用終了される
    def finish_violent_feat()
      if @feats_enable[FEAT_VIOLENT] && owner.initiative?
        use_feat_event(@feats[FEAT_VIOLENT])
        atk_times = owner.hit_point <= owner.current_chara_card.hp/2 ? 3 : 1
        atk_times.times do |c|
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if duel.second_entrant.hit_points[i] > 0
          end
          if hps.count > 0
            target_index = hps[rand(hps.size)]
            attribute_party_damage(foe, target_index, (foe.hit_points[target_index]/2).to_i, ATTRIBUTE_HALF)
          end
        end
      end
    end
    regist_event FinishViolentFeatEvent

    # 暴れるが使用される
    # 有効の場合必殺技IDを返す
    def finish_violent_feat_change()
      if @feats_enable[FEAT_VIOLENT]
        @feats_enable[FEAT_VIOLENT] = false
      end
    end
    regist_event FinishViolentFeatChangeEvent

    # ------------------
    # バランスライフ (白妙の仔山羊)
    # ------------------
    # バランスライフが使用されたかのチェック
    def check_balance_life_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_BALANCE_LIFE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BALANCE_LIFE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBalanceLifeFeatEvent
    regist_event CheckAddBalanceLifeFeatEvent
    regist_event CheckRotateBalanceLifeFeatEvent

    # バランスライフが使用される
    # 有効の場合必殺技IDを返す
    def use_balance_life_feat()
      if @feats_enable[FEAT_BALANCE_LIFE]
        hps = []
        owner.hit_points.each_index do |i|
          hps << i if owner.hit_points[i] > 0
        end

        multi_pt = 3
        @cc.owner.tmp_power += hps.size * multi_pt
      end
    end
    regist_event UseBalanceLifeFeatEvent

    # バランスライフが使用終了
    def finish_balance_life_feat()
      if @feats_enable[FEAT_BALANCE_LIFE]
        use_feat_event(@feats[FEAT_BALANCE_LIFE])
      end
    end
    regist_event FinishBalanceLifeFeatEvent

    # バランスライフが使用される(ダメージ時)
    # ダメージを分配する
    def use_balance_life_feat_damage()
      if @feats_enable[FEAT_BALANCE_LIFE]
        @feats_enable[FEAT_BALANCE_LIFE] = false

        hps = []
        owner.hit_points.each_index do |i|
          hps << [i, owner.hit_points[i]] if owner.current_chara_card_no != i && owner.hit_points[i] > 0
        end

        # 控えがいなければ終了
        return if hps.size < 1

        # ソートしておく
        if hps.size > 1
          # hp降順、index昇順
          hps = hps.sort! do |a, b|
            (b[1] <=> a[1]).nonzero? ||
              (a[0] <=> b[0])
          end
        end

        # ダメージを分割する
        if duel.tmp_damage > 0
          d = (duel.tmp_damage / (hps.size + 1)).to_i

          mod = 0
          # 剰余を切り捨てない場合、高HP、低indexへ優先的に適用
          if (Feat.pow(@feats[FEAT_BALANCE_LIFE]) < 2)
            mod = duel.tmp_damage % (hps.size + 1)
          end

          duel.tmp_damage = d

          # 受け持つダメージをhpsに追加
          hps.size.times do |i|
            if mod > 0
              hps[i] << d + 1
              mod -= 1
            else
              hps[i] << d
            end
          end

          hps.each do |h|
            if Feat.pow(@feats[FEAT_BALANCE_LIFE]) > 2
              h[2] = h[1]-1 if h[1] <= h[2]
            end
            attribute_party_damage(owner, h[0], h[2])
          end
        end
      end
    end
    regist_event UseBalanceLifeFeatDamageEvent

    # ------------------
    # ライフタイムサウンド (万物の杖)
    # ------------------
    # ライフタイムサウンドが使用されたかのチェック
    def check_lifetime_sound_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_LIFETIME_SOUND)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      if owner.get_battle_table_point(ActionCard::SPC) > 0
        check_feat(FEAT_LIFETIME_SOUND)
      else
        off_feat_event(FEAT_LIFETIME_SOUND)
        @feats_enable[FEAT_LIFETIME_SOUND] = false
      end
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveLifetimeSoundFeatEvent
    regist_event CheckAddLifetimeSoundFeatEvent
    regist_event CheckRotateLifetimeSoundFeatEvent

    # ライフタイムサウンドが使用される
    # HPを取る味方がいるときATK増加
    def use_lifetime_sound_feat()
      if @feats_enable[FEAT_LIFETIME_SOUND]
        hps = []
        owner.hit_points.each_index do |i|
          hps << i if owner.current_chara_card_no != i && owner.hit_points[i] > 0
        end

        @lifetime_sound_sp_count = owner.get_battle_table_point(ActionCard::SPC)
        if hps.size > 0
          @cc.owner.tmp_power += @lifetime_sound_sp_count * 4
        end
      end
    end
    regist_event UseLifetimeSoundFeatEvent


    # ライフタイムサウンドが使用終了
    def finish_lifetime_sound_feat()
      if @feats_enable[FEAT_LIFETIME_SOUND]
        use_feat_event(@feats[FEAT_LIFETIME_SOUND])

        # 最低限残すHP
        save_hp = Feat.pow(@feats[FEAT_LIFETIME_SOUND]) > 0 ? 1 : 0

        hps = []
        owner.hit_points.each_index do |i|
          hps << [i, owner.hit_points[i]] if owner.current_chara_card_no != i && owner.hit_points[i] > 0
        end

        absorb = 0
        if hps.size > 0
          # hp降順、index昇順
          hps = hps.sort! do |a, b|
            (b[1] <=> a[1]).nonzero? ||
              (a[0] <=> b[0])
          end

          # 味方へのダメージは自傷ダメージとして取り扱う
          absorb = hps[0][1] - save_hp < @lifetime_sound_sp_count ? hps[0][1] - save_hp : @lifetime_sound_sp_count
          attribute_party_damage(owner, hps.sort{ |a,b| b[1] <=> a[1] }[0][0], absorb, ATTRIBUTE_CONSTANT, TARGET_TYPE_SINGLE, 1, IS_NOT_HOSTILE_DAMAGE) if absorb > 0
        end

        owner.healed_event(absorb) if absorb > 0
      end
    end
    regist_event FinishLifetimeSoundFeatEvent

    def finish_lifetime_sound_feat_damage()
      if @feats_enable[FEAT_LIFETIME_SOUND]
        @feats_enable[FEAT_LIFETIME_SOUND] = false
      end
    end
    regist_event FinishLifetimeSoundFeatDamageEvent

    # ------------------
    # コマホワイト (白き永劫)
    # ------------------
    # コマホワイトが使用されたかのチェック
    def check_coma_white_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COMA_WHITE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_COMA_WHITE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveComaWhiteFeatEvent
    regist_event CheckAddComaWhiteFeatEvent
    regist_event CheckRotateComaWhiteFeatEvent

    # コマホワイトが使用される
    def use_coma_white_feat()
      if @feats_enable[FEAT_COMA_WHITE]
        d = 0
        owner.hit_points.each_index do |i|
          d += owner.hit_points_max[i] - owner.hit_points[i] if owner.hit_points[i] > 0
        end

        @cc.owner.tmp_power += d
      end
    end
    regist_event UseComaWhiteFeatEvent

    # コマホワイトが使用終了される
    def finish_coma_white_feat()
      if @feats_enable[FEAT_COMA_WHITE]
        @feats_enable[FEAT_COMA_WHITE] = false
        use_feat_event(@feats[FEAT_COMA_WHITE])
      end
    end
    regist_event FinishComaWhiteFeatEvent

    # ------------------
    # ゴーズトゥダーク (豊穣の口づけ)
    # ------------------
    # ゴーズトゥダークが使用されたかのチェック
    def check_goes_to_dark_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GOES_TO_DARK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GOES_TO_DARK) unless @goes_to_dark_used
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveGoesToDarkFeatEvent
    regist_event CheckAddGoesToDarkFeatEvent
    regist_event CheckRotateGoesToDarkFeatEvent

    # ゴーズトゥダークを使用
    def finish_goes_to_dark_feat()
      if @feats_enable[FEAT_GOES_TO_DARK] && get_hps(owner).size > 0
        @goes_to_dark_used = true
        use_feat_event(@feats[FEAT_GOES_TO_DARK])
        owner.cards_max = owner.cards_max - 1

        hps = []

        owner.hit_points.each_index do |i|
          hps << i if owner.current_chara_card_no != i && owner.hit_points[i] < 1
        end

        hps.each do |i|
          owner.revive_event(i, 1);

          set_state(owner.chara_cards[i].status[STATE_CONTROL], 1, 2);
          on_buff_event(true,
                        i,
                        STATE_CONTROL,
                        owner.chara_cards[i].status[STATE_CONTROL][0],
                        owner.chara_cards[i].status[STATE_CONTROL][1])

          unless Charactor.attribute(owner.chara_cards[i].charactor_id).include?("revisers")

            buffed = set_state(owner.chara_cards[i].status[STATE_SEAL], 1, 3);
            on_buff_event(true,
                          i,
                          STATE_SEAL,
                          owner.chara_cards[i].status[STATE_SEAL][0],
                          owner.chara_cards[i].status[STATE_SEAL][1]) if buffed

          end
        end

      end
      @feats_enable[FEAT_GOES_TO_DARK] = false
    end
    regist_event FinishGoesToDarkFeatEvent

    # ------------------
    # 霧隠れ
    # ------------------
    # 霧隠れが使用されたかのチェック
    def check_kirigakure_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KIRIGAKURE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_KIRIGAKURE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveKirigakureFeatEvent
    regist_event CheckAddKirigakureFeatEvent
    regist_event CheckRotateKirigakureFeatEvent

    # 相手のAC提出に合せて範囲をガイドする
    def check_kirigakure_feat_foe
      if @feats_enable[FEAT_KIRIGAKURE]
        phase = foe.initiative ? PHASE_ATTACK : PHASE_DEFENSE
        if foe.current_chara_card.get_enable_feats(phase).length == 0
          range = get_battle_table_range(false)
          foe.current_chara_card.in_the_fog_event(true, range)
        end
      end
    end
    regist_event CheckRemoveKirigakureFeatFoeAttackEvent
    regist_event CheckAddKirigakureFeatFoeAttackEvent
    regist_event CheckRotateKirigakureFeatFoeAttackEvent
    regist_event CheckRemoveKirigakureFeatFoeDefenseEvent
    regist_event CheckAddKirigakureFeatFoeDefenseEvent
    regist_event CheckRotateKirigakureFeatFoeDefenseEvent

    # mp計算
    def use_kirigakure_feat_calc
      if @feats_enable[FEAT_KIRIGAKURE]
        if owner.tmp_power > 0
          owner.seconds = true
        else
          owner.seconds = false
        end
        owner.tmp_power = owner.get_type_point_cards_both_faces(ActionCard::MOVE)
        owner.tmp_power += 1 if Feat.pow(@feats[FEAT_KIRIGAKURE]) == 2
      end
    end
    regist_event UseKirigakureFeatCalcEvent

    # 霧隠れを使用 カットイン 霧状態にする
    def use_kirigakure_feat()
      if @feats_enable[FEAT_KIRIGAKURE]
        use_feat_event(@feats[FEAT_KIRIGAKURE])
        on_feat_event(FEAT_KIRIGAKURE)
        # フィールドの状態を設定する
        @kirigakure_cc_selected = false
        owner.hiding_was_finished = false
        if owner.direction != Entrant::DIRECTION_CHARA_CHANGE
          owner.set_field_status_event(Entrant::FIELD_STATUS["FOG"], 1, 1)
        else
          @kirigakure_cc_selected = true
        end
      end
    end
    regist_event UseKirigakureFeatEvent

    # 霧隠れを有効化 場に残るなら発動する
    def use_kirigakure_feat_det_change
      if @feats_enable[FEAT_KIRIGAKURE]
        if @kirigakure_cc_selected
          on_feat_event(FEAT_KIRIGAKURE)
          owner.set_field_status_event(Entrant::FIELD_STATUS["FOG"], 1, 1)
        end
        # 分身。距離表示を伏せる
        on_lost_in_the_fog_event(true)
        @hiding = true
        foe.current_chara_card.check_feat_range_free = true
        foe.bp_calc_range_free = true
      end
    end
    regist_event UseKirigakureFeatDetChangeEvent

    # フェイズの頭、自分が分身中なら、相手の距離制限を解除
    def use_kirigakure_feat_phase_init
      if @feats_enable[FEAT_KIRIGAKURE] && @hiding
        foe.current_chara_card.in_the_fog_event(true, [])
        foe.current_chara_card.check_feat_range_free = true
        foe.bp_calc_range_free = true
      end
    end
    regist_event UseKirigakureFeatPhaseInitEvent

    def check_feat_range_free=(f)
      @check_feat_range_free = f
    end

    def check_feat_range_free?
      @check_feat_range_free
    end

    # 攻守提出完了時、相手の距離制限を復帰、再評価
    def use_kirigakure_feat_defense_done
      if @cc && @cc.using && foe.current_chara_card.check_feat_range_free?
        foe.current_chara_card.check_feat_range_free = false
        foe.bp_calc_range_free = false
        phase = owner.initiative ? "防御" : "攻撃"
        foe.current_chara_card.recheck_battle_point(foe, phase)
      end
    end
    regist_event UseKirigakureFeatDefenseDoneOwnerEvent
    regist_event UseKirigakureFeatDefenseDoneFoeEvent

    # 攻撃力の再評価関数
    def recheck_battle_point(target, phase)
      phase_key_str = "[" + phase + ":"
      feats = get_feats_list_as_for(target, phase)

      feats.each do |f|
        target.reset_feat_on_cards(f)
        target.current_chara_card.check_feat(f)
      end

      target.bp_calc_unenabled = (!@target_range || @target_range.length == 0) || !@target_range.include?(foe.distance)
      target.point_check(Entrant::POINT_CHECK_BATTLE)
    end

    # 指定したフェイズで使用可能な技を列挙する
    def get_feats_list_as_for(target, phase)
      phase_key_str = "[" + phase + ":"
      feats = []
      target.current_chara_card.get_feat_ids.each do |fid|
        f = Unlight::Feat[fid]
        feats << f.feat_no if f.caption.include?(phase_key_str)
      end

      feats
    end

    # 霧隠れ終了 (ダメージを受けた場合の解除)
    def finish_kirigakure_feat_owner_damaged
      if @feats_enable[FEAT_KIRIGAKURE]
        if @hiding && owner.determined_damage > 0
          finish_kirigakure_effect
        end
      end
    end
    regist_event FinishKirigakureFeatOwnerDamagedEvent

    # 霧隠れ終了 (ダメージを与えた場合の解除)
    def finish_kirigakure_feat_do_damage
      if @feats_enable[FEAT_KIRIGAKURE]
        if @hiding && owner.initiative && foe.determined_damage > 0
          finish_kirigakure_effect
        end
      end
    end
    regist_event FinishKirigakureFeatDoDamageEvent

    # 霧隠れ終了(ターンエンド)
    def finish_kirigakure_feat_finish_turn
      if @feats_enable[FEAT_KIRIGAKURE] || @hiding
        finish_kirigakure_effect
      end
    end
    regist_event FinishKirigakureFeatFinishTurnEvent

    # 霧の恩恵による効果を切る
    def finish_kirigakure_effect
      @feats_enable[FEAT_KIRIGAKURE] = false
      off_feat_event(FEAT_KIRIGAKURE)
      off_lost_in_the_fog_event(true)
      @hiding = false
      foe.current_chara_card.check_feat_range_free = false
      foe.bp_calc_range_free = false
    end

    def hiding?
      @hiding
    end

    # ------------------
    # 水鏡
    # ------------------
    # 水鏡が使用されたかのチェック
    def check_mikagami_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MIKAGAMI)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MIKAGAMI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMikagamiFeatEvent
    regist_event CheckAddMikagamiFeatEvent
    regist_event CheckRotateMikagamiFeatEvent

    def use_mikagami_feat()
      if @feats_enable[FEAT_MIKAGAMI]

        if @my_table_size.nil? || owner.battle_table.size < 2
          @my_table_size = 0
          @mikagami_match_cnt = 0
        end

        # 極力再計算しないための処理 単調追加の場合は追加分のみ新規に計算
        if @my_table_size == owner.battle_table.size
        elsif @my_table_size + 1 == owner.battle_table.size
          pac = owner.battle_table.last
          foe.battle_table.each do |fac|
            @mikagami_match_cnt += 1 if same_card?(pac, fac)
          end
        else
          @mikagami_match_cnt = 0
          owner.battle_table.each do |pac|
            foe.battle_table.each do |fac|
              @mikagami_match_cnt += 1 if same_card?(pac, fac)
            end
          end
        end

        @my_table_size = owner.battle_table.size

        @cc.owner.tmp_power += @mikagami_match_cnt * 5
      end
    end
    regist_event UseMikagamiFeatEvent

    def same_card?(pac, fac)
      (pac.u_type == fac.u_type && pac.b_type == fac.b_type) &&
        (pac.u_value == fac.u_value && pac.b_value == fac.b_value) ||
        (pac.u_type == fac.b_type && pac.b_type == fac.u_type) &&
        (pac.u_value == fac.b_value && pac.b_value == fac.u_value)
    end

    # 水鏡が使用される
    def finish_mikagami_feat()
      if @feats_enable[FEAT_MIKAGAMI]
        use_feat_event(@feats[FEAT_MIKAGAMI])
        if duel.tmp_damage < 1 && @mikagami_match_cnt > 0
          foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, @mikagami_match_cnt + Feat.pow(@feats[FEAT_MIKAGAMI])))
        end
        @feats_enable[FEAT_MIKAGAMI] = false
      end
    end
    regist_event FinishMikagamiFeatEvent

    # ------------------
    # 落花流水
    # ------------------
    # 落花流水が使用されたかのチェック
    def check_mutual_love_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MUTUAL_LOVE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MUTUAL_LOVE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMutualLoveFeatEvent
    regist_event CheckAddMutualLoveFeatEvent
    regist_event CheckRotateMutualLoveFeatEvent

    # 落花流水が使用される
    # 有効の場合必殺技IDを返す
    def use_mutual_love_feat()
      if @feats_enable[FEAT_MUTUAL_LOVE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_MUTUAL_LOVE])
      end
    end
    regist_event UseMutualLoveFeatEvent

    # 落花流水が使用終了
    def finish_mutual_love_feat()
      if @feats_enable[FEAT_MUTUAL_LOVE]
        use_feat_event(@feats[FEAT_MUTUAL_LOVE])
      end
    end
    regist_event FinishMutualLoveFeatEvent

    # 落花流水が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_mutual_love_feat_damage()
      if @feats_enable[FEAT_MUTUAL_LOVE]
        # ダメージが通った場合
        if @feats_enable[FEAT_KIRIGAKURE] && duel.tmp_damage > 0
          @mutual_love_damage = duel.tmp_damage
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
          end
          duel.tmp_damage = 0
        else
          @mutual_love_damage = 0
        end
      end
    end
    regist_event UseMutualLoveFeatDamageEvent

    def use_mutual_love_feat_const_damage()
      if @feats_enable[FEAT_MUTUAL_LOVE]
        @passives_enable[PASSIVE_ROCK_CRUSHER] = false if @passives_enable[PASSIVE_ROCK_CRUSHER]
        @passives_enable[PASSIVE_DAMAGE_MULTIPLIER] = false if @passives_enable[PASSIVE_DAMAGE_MULTIPLIER]
        if @mutual_love_damage && @mutual_love_damage > 0
          hps = get_hps(foe, true)
          if hps.size > 0
            attribute_party_damage(foe, hps, @mutual_love_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
          else
            duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@mutual_love_damage))
          end
        end
        @feats_enable[FEAT_MUTUAL_LOVE] = false
        @mutual_love_damage = 0
      end
    end
    regist_event UseMutualLoveFeatConstDamageEvent

    # ------------------
    # 鏡花水月
    # ------------------
    # 鏡花水月が使用されたかのチェック
    def check_mere_shadow_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MERE_SHADOW)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MERE_SHADOW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
     end
    regist_event CheckRemoveMereShadowFeatEvent
    regist_event CheckAddMereShadowFeatEvent
    regist_event CheckRotateMereShadowFeatEvent

    # 鏡花水月が使用される
    def use_mere_shadow_feat()
      if @feats_enable[FEAT_MERE_SHADOW]
        atk_pt = @feats_enable[FEAT_KIRIGAKURE] ? 5 + Feat.pow(@feats[FEAT_MERE_SHADOW]) : 5
        @cc.owner.tmp_power+=atk_pt
      end
    end
    regist_event UseMereShadowFeatEvent

    # 鏡花水月が使用終了される
    def finish_mere_shadow_feat()
      if @feats_enable[FEAT_MERE_SHADOW]
        use_feat_event(@feats[FEAT_MERE_SHADOW])
        if @feats_enable[FEAT_KIRIGAKURE]
          num = Feat.pow(@feats[FEAT_MERE_SHADOW]) > 10 ? 3 : 1
          # テーブルをシャッフル
          aca = foe.battle_table.shuffle
          # カードを捨てる
          num.times{ |a| foe.discard_table_event(aca[a]) if aca[a] }
          foe.current_chara_card.recheck_battle_point(foe, PHASE_DEFENSE)
        end
      end
    end
    regist_event FinishMereShadowFeatEvent


    def finish_mere_shadow_feat_dice_attr
      if @feats_enable[FEAT_MERE_SHADOW]
        foe.point_rewrite_event
        @feats_enable[FEAT_MERE_SHADOW] = false
      end
    end
    regist_event FinishMereShadowFeatDiceAttrEvent

    # ------------------
    # 亀占い
    # ------------------
    # 亀占いが使用されたかのチェック
    def check_scapulimancy_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SCAPULIMANCY)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SCAPULIMANCY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveScapulimancyFeatEvent
    regist_event CheckAddScapulimancyFeatEvent
    regist_event CheckRotateScapulimancyFeatEvent

    # 亀占いを使用
    def finish_scapulimancy_feat()
      if @feats_enable[FEAT_SCAPULIMANCY]
        use_feat_event(@feats[FEAT_SCAPULIMANCY])
        @feats_enable[FEAT_SCAPULIMANCY] = false
        # 自分
        cid = TORTO_EVENT_CARDS[rand(TORTO_EVENT_CARDS.length)]
        ret = duel.get_event_deck(owner).replace_event_cards(cid, Feat.pow(@feats[FEAT_SCAPULIMANCY]), true)
        if ret > 0
          @cc.owner.special_event_card_dealed_event(duel.get_event_deck(owner).draw_cards_event(ret).each{ |c| @cc.owner.dealed_event(c)})
        end

        ret = duel.get_event_deck(foe).replace_event_cards(cid, Feat.pow(@feats[FEAT_SCAPULIMANCY]), true)
        if ret > 0
          foe.special_event_card_dealed_event(duel.get_event_deck(foe).draw_cards_event(ret).each{ |c| foe.dealed_event(c)})
        end
      end
    end
    regist_event FinishScapulimancyFeatEvent

    # ------------------
    # 土盾
    # ------------------
    # 土盾が使用されたかのチェック
    def check_soil_guard_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SOIL_GUARD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SOIL_GUARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSoilGuardFeatEvent
    regist_event CheckAddSoilGuardFeatEvent
    regist_event CheckRotateSoilGuardFeatEvent

    # 土盾が使用される
    # 有効の場合必殺技IDを返す
    def use_soil_guard_feat()
      if @feats_enable[FEAT_SOIL_GUARD]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::DEF)*Feat.pow(@feats[FEAT_SOIL_GUARD]))
      end
    end
    regist_event UseSoilGuardFeatEvent

    # 土盾が使用される
    # 有効の場合必殺技IDを返す
    def use_soil_guard_feat_damage()
      if @feats_enable[FEAT_SOIL_GUARD]
        use_feat_event(@feats[FEAT_SOIL_GUARD])
        foe.current_chara_card.set_state(@cc.status[STATE_PARALYSIS], 1, 1)
        foe.current_chara_card.on_buff_event(false, owner.current_chara_card_no, STATE_PARALYSIS, @cc.status[STATE_PARALYSIS][0], @cc.status[STATE_PARALYSIS][1])
        @feats_enable[FEAT_SOIL_GUARD] = false
      end
    end
    regist_event UseSoilGuardFeatDamageEvent

    # ------------------
    # 甲羅スピン
    # ------------------
    # 甲羅スピンが使用されたかのチェック
    def check_carapace_spin_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CARAPACE_SPIN)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CARAPACE_SPIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCarapaceSpinFeatEvent
    regist_event CheckAddCarapaceSpinFeatEvent
    regist_event CheckRotateCarapaceSpinFeatEvent

    # 甲羅スピンが使用される
    # 有効の場合必殺技IDを返す
    def use_carapace_spin_feat()
    end
    regist_event UseCarapaceSpinFeatEvent

    # 甲羅スピンが使用終了される
    def finish_carapace_spin_feat()
      if @feats_enable[FEAT_CARAPACE_SPIN]
        @feats_enable[FEAT_CARAPACE_SPIN] = false
        use_feat_event(@feats[FEAT_CARAPACE_SPIN])
        attribute_party_damage(foe, get_hps(foe), Feat.pow(@feats[FEAT_CARAPACE_SPIN]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
      end
    end
    regist_event FinishCarapaceSpinFeatEvent

    # ------------------
    # リタリエイション
    # ------------------
    # リタリエイションが使用されたかのチェック
    def check_vendetta_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_VENDETTA)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_VENDETTA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveVendettaFeatEvent
    regist_event CheckAddVendettaFeatEvent
    regist_event CheckRotateVendettaFeatEvent

    # リタリエイションが使用される
    def use_vendetta_feat()
      if @feats_enable[FEAT_VENDETTA]
        @cc.owner.tmp_power += owner.before_damage * Feat.pow(@feats[FEAT_VENDETTA])
      end
    end
    regist_event UseVendettaFeatEvent

    # リタリエイションが使用終了
    def finish_vendetta_feat()
      if @feats_enable[FEAT_VENDETTA]
        @feats_enable[FEAT_VENDETTA] = false
        use_feat_event(@feats[FEAT_VENDETTA])
      end
    end
    regist_event FinishVendettaFeatEvent

    # ------------------
    # マリスデザイア
    # ------------------
    # マリスデザイアが使用されたかのチェック
    def check_avengers_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_AVENGERS)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_AVENGERS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAvengersFeatEvent
    regist_event CheckAddAvengersFeatEvent
    regist_event CheckRotateAvengersFeatEvent

    # マリスデザイアが使用される
    # 有効の場合必殺技IDをgす
    def use_avengers_feat()
      if @feats_enable[FEAT_AVENGERS]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_AVENGERS])
      end
    end
    regist_event UseAvengersFeatEvent

    # マリスデザイアが使用終了
    def finish_avengers_feat()
      if @feats_enable[FEAT_AVENGERS]
        use_feat_event(@feats[FEAT_AVENGERS])
        div = @cc.status[STATE_CONTROL][1] > 0 ? 5 : 10
        if foe.tmp_power >= div
          buff_pow = foe.tmp_power / div
          hps = []
          duel.second_entrant.hit_points.each_index do |i|
            hps << i
          end
          hps.size.times do |i|
            pow = owner.chara_cards[i].status[STATE_ATK_UP][1] > 0 ? owner.chara_cards[i].status[STATE_ATK_UP][0]+buff_pow : buff_pow
            turn = i == owner.current_chara_card_no ? 3 : 2
            set_state(owner.chara_cards[i].status[STATE_ATK_UP], pow, turn)
            on_buff_event(true, i, STATE_ATK_UP, owner.chara_cards[i].status[STATE_ATK_UP][0], owner.chara_cards[i].status[STATE_ATK_UP][1])
          end

        end
        @feats_enable[FEAT_AVENGERS] = false
      end
    end
    regist_event FinishAvengersFeatEvent

    # ------------------
    # ホロウメモリー
    # ------------------
    # ホロウメモリーが使用されたかのチェック
    def check_sharpen_edge_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHARPEN_EDGE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SHARPEN_EDGE) if @cc.special_status[SPECIAL_STATE_SHARPEN_EDGE][1] < 1
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveSharpenEdgeFeatEvent
    regist_event CheckAddSharpenEdgeFeatEvent
    regist_event CheckRotateSharpenEdgeFeatEvent

    # ホロウメモリーを使用
    def use_sharpen_edge_feat()
      if @feats_enable[FEAT_SHARPEN_EDGE]
        pow = owner.current_chara_card.status[STATE_ATK_UP][1] > 0 ? owner.current_chara_card.status[STATE_ATK_UP][0]+Feat.pow(@feats[FEAT_SHARPEN_EDGE])  : Feat.pow(@feats[FEAT_SHARPEN_EDGE])
        set_state(owner.current_chara_card.status[STATE_ATK_UP], pow, 3)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, owner.current_chara_card.status[STATE_ATK_UP][0], owner.current_chara_card.status[STATE_ATK_UP][1])
        set_state(@cc.special_status[SPECIAL_STATE_SHARPEN_EDGE], 1, Feat.pow(@feats[FEAT_SHARPEN_EDGE]))
        use_feat_event(@feats[FEAT_SHARPEN_EDGE])
        on_feat_event(FEAT_SHARPEN_EDGE)
      end
    end
    regist_event UseSharpenEdgeFeatEvent

    # ホロウメモリー終了
    def finish_sharpen_edge_feat()
      off_feat_event(FEAT_SHARPEN_EDGE)
      @feats_enable[FEAT_SHARPEN_EDGE] = false
    end

    # ------------------
    # ブラックマゲイア
    # ------------------
    # ブラックマゲイアが使用されたかのチェック
    def check_hacknine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HACKNINE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HACKNINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHacknineFeatEvent
    regist_event CheckAddHacknineFeatEvent
    regist_event CheckRotateHacknineFeatEvent

    # 必殺技の状態
    def use_hacknine_feat()
      if @feats_enable[FEAT_HACKNINE]
      end
    end
    regist_event UseHacknineFeatEvent

    # ブラックマゲイアが使用される
    def finish_hacknine_feat()
      if @feats_enable[FEAT_HACKNINE]
        use_feat_event(@feats[FEAT_HACKNINE])
        limit_hp_at_control = Feat.pow(@feats[FEAT_HACKNINE]) < 13 ? 0 : 1
        aim_hp = 0
        if @cc.status[STATE_CONTROL][1] > 0
          aim_hp = limit_hp_at_control
        else
          aim_hp = (Feat.pow(@feats[FEAT_HACKNINE]) - owner.damaged_times)
          aim_hp = 1 if aim_hp < 1
        end
        foe.damaged_event(attribute_damage(ATTRIBUTE_DYING,foe,aim_hp)) if foe.hit_point > aim_hp
        @feats_enable[FEAT_HACKNINE] = false
      end
    end
    regist_event FinishHacknineFeatEvent

    # ------------------
    # ブラックマゲイア
    # ------------------
    # ブラックマゲイアが使用されたかのチェック
    def check_black_mageia_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLACK_MAGEIA)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BLACK_MAGEIA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlackMageiaFeatEvent
    regist_event CheckAddBlackMageiaFeatEvent
    regist_event CheckRotateBlackMageiaFeatEvent

    # ブラックマゲイアが使用終了される
    def finish_black_mageia_feat()
      if @feats_enable[FEAT_BLACK_MAGEIA]
        @feats_enable[FEAT_BLACK_MAGEIA] = false
        use_feat_event(@feats[FEAT_BLACK_MAGEIA])

        hps_f = get_hps(owner, true)
        hps_s = get_hps(foe)
        # 自パーティを優先して攻撃する
        if hps_f.size > 0
          attribute_party_damage(owner, hps_f, Feat.pow(@feats[FEAT_BLACK_MAGEIA]), ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM, 1, IS_NOT_HOSTILE_DAMAGE)
        elsif hps_s.size > 0
          attribute_party_damage(foe, hps_s, Feat.pow(@feats[FEAT_BLACK_MAGEIA]), ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
        end

      end
    end
    regist_event FinishBlackMageiaFeatEvent

    # ------------------
    # コープスドレイン
    # ------------------
    # コープスドレインが使用されたかのチェック
    def check_corps_drain_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CORPS_DRAIN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CORPS_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCorpsDrainFeatEvent
    regist_event CheckAddCorpsDrainFeatEvent
    regist_event CheckRotateCorpsDrainFeatEvent

    # コープスドレインが使用終了される
    def finish_corps_drain_feat()
      if @feats_enable[FEAT_CORPS_DRAIN]
        use_feat_event(@feats[FEAT_CORPS_DRAIN])
      end
    end
    regist_event FinishCorpsDrainFeatEvent

    # コープスドレインＨＰ吸収
    def use_corps_drain_feat_damage()
      if @feats_enable[FEAT_CORPS_DRAIN]
        @feats_enable[FEAT_CORPS_DRAIN] = false

        hps = []
        owner.hit_points.each_index do |i|
          hps << i if owner.current_chara_card_no != i && owner.hit_points[i] <= 0
        end
        foe.hit_points.each_index do |i|
          hps << i if foe.hit_points[i] <= 0
        end

        tmp_hp_before = foe.hit_point
        if hps.size > 0
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, hps.size))
        end

        tmp_hp_after = foe.hit_point
        owner.healed_event(tmp_hp_before - tmp_hp_after)
      end
    end
    regist_event UseCorpsDrainFeatDamageEvent

    # ------------------
    # インヴァート
    # ------------------
    # インヴァートが使用されたかのチェック
    def check_invert_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_INVERT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_INVERT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveInvertFeatEvent
    regist_event CheckAddInvertFeatEvent
    regist_event CheckRotateInvertFeatEvent

    # インヴァートが使用終了される
    def finish_invert_feat()
      if @feats_enable[FEAT_INVERT]
        @feats_enable[FEAT_INVERT] = false
        use_feat_event(@feats[FEAT_INVERT])
        if owner.current_chara_card.hp / 2 > owner.hit_point

          heal_pt = owner.current_chara_card.hp - owner.hit_point * 2
          duel.second_entrant.healed_event(heal_pt) if owner.hit_point > 0
        end
      end
    end
    regist_event FinishInvertFeatEvent

    # ------------------
    # 追跡する夜鷹
    # ------------------
    # 追跡する夜鷹が使用されたかのチェック
    def check_night_hawk_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_NIGHT_HAWK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_NIGHT_HAWK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveNightHawkFeatEvent
    regist_event CheckAddNightHawkFeatEvent
    regist_event CheckRotateNightHawkFeatEvent

    # 追跡する夜鷹を使用
    def use_night_hawk_feat()
      if @feats_enable[FEAT_NIGHT_HAWK]
        mp = Feat.pow(@feats[FEAT_NIGHT_HAWK])
        mp -= 1 if mp > 1
        @cc.owner.tmp_power += mp
      end
    end
    regist_event UseNightHawkFeatEvent

    # 追跡する夜鷹を使用
    def use_night_hawk_feat_det_mp_before1()
      if @feats_enable[FEAT_NIGHT_HAWK]

        use_feat_event(@feats[FEAT_NIGHT_HAWK])

        if foe.current_chara_card.status[STATE_TARGET][1] == 0

          buffed = set_state(foe.current_chara_card.status[STATE_TARGET], 1, 1);
          on_buff_event(false,
                        foe.current_chara_card_no,
                        STATE_TARGET,
                        foe.current_chara_card.status[STATE_TARGET][0],
                        foe.current_chara_card.status[STATE_TARGET][1]) if buffed
          @night_hawk_already_targeted = false
        else
          @night_hawk_already_targeted = true
        end

      end
    end
    regist_event UseNightHawkFeatDetMpBefore1Event

    # 追跡する夜鷹を使用を使用 強制キャラチェンジ
    def use_night_hawk_feat_det_mp_before2()
      if @feats_enable[FEAT_NIGHT_HAWK] && @night_hawk_already_targeted
        if owner.initiative?
          foe.set_direction(Entrant::DIRECTION_CHARA_CHANGE)
        end
      end
    end
    regist_event UseNightHawkFeatDetMpBefore2Event

    # 追跡する夜鷹を使用
    def use_night_hawk_feat_change()
      if @feats_enable[FEAT_NIGHT_HAWK] && @night_hawk_already_targeted
        if owner.initiative?

          hps = []
          foe.chara_cards.each_with_index do |c,i|
            hps << i if i != foe.current_chara_card_no && c.status[STATE_TARGET][1] == 0 && foe.hit_points[i] > 0
          end

          if hps.size > 0
            foe.chara_change_index = hps[rand(hps.size)]
          end

          if hps.size == 1
            foe.chara_change_force = true
          end
        end
      end
      @feats_enable[FEAT_NIGHT_HAWK] = false
      @night_hawk_already_targeted = false
    end
    regist_event UseNightHawkFeatFoeChangeEvent
    regist_event UseNightHawkFeatOwnerChangeEvent
    regist_event UseNightHawkFeatDeadChangeEvent

    # 追跡する夜鷹を使用
    def finish_night_hawk_feat_change()
      foe.chara_change_index = nil
      foe.chara_change_force = nil
      @night_hawk_already_targeted == false
    end
    regist_event FinishNightHawkFeatChangeEvent

    # ------------------
    # 幽幻の剛弾
    # ------------------
    # 幽幻の剛弾が使用されたかのチェック
    def check_phantom_barrett_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_PHANTOM_BARRETT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PHANTOM_BARRETT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePhantomBarrettFeatEvent
    regist_event CheckAddPhantomBarrettFeatEvent
    regist_event CheckRotatePhantomBarrettFeatEvent

    # 幽幻の剛弾が使用される
    def use_phantom_barrett_feat()
      if @feats_enable[FEAT_PHANTOM_BARRETT]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PHANTOM_BARRETT])
      end
    end
    regist_event UsePhantomBarrettFeatEvent

    # 幽幻の剛弾が使用終了
    def finish_phantom_barrett_feat()
      if @feats_enable[FEAT_PHANTOM_BARRETT]
        @feats_enable[FEAT_PHANTOM_BARRETT] = false
        use_feat_event(@feats[FEAT_PHANTOM_BARRETT])
        if duel.tmp_damage > 0

          target_count = 0
          hps = []
          foe.chara_cards.each_with_index do |c,i|
            hps << i if c.status[STATE_TARGET][1] > 0 && foe.hit_points[i] > 0
          end

          return if hps.size == 0

          dmg = (duel.tmp_damage + hps.size - 1) / hps.size

          # 目の前の相手が正鵠ならダメージを調整, そうでなければ0に
          if hps.include?(foe.current_chara_card_no)
            duel.tmp_damage = dmg
            hps.delete(foe.current_chara_card_no)
          else
            duel.tmp_damage = 0
          end

          # パーティダメージ
          attribute_party_damage(foe, hps, dmg, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)  if hps.size > 0

        end
      end
    end
    regist_event FinishPhantomBarrettFeatEvent


    # ------------------
    # 惑わしの一幕
    # ------------------
    # 惑わしの一幕が使用されたかのチェック
    def check_one_act_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ONE_ACT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ONE_ACT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveOneActFeatEvent
    regist_event CheckAddOneActFeatEvent
    regist_event CheckRotateOneActFeatEvent


    def use_one_act_feat()
      if @feats_enable[FEAT_ONE_ACT]
        @cc.owner.tmp_power +=4
        @one_act_card_types = @cc.owner.get_table_card_types
        @one_act_card_types.delete(ActionCard::DEF)
      end
    end
    regist_event UseOneActFeatEvent

    # 惑わしの一幕が使用される
    def finish_one_act_feat()
      if @feats_enable[FEAT_ONE_ACT]
        use_feat_event(@feats[FEAT_ONE_ACT])
        @feats_enable[FEAT_ONE_ACT] = false
        return if @one_act_card_types.size == 0

        if foe.battle_table.size > 0

          foe_card_types = foe.get_table_card_types
          foe_card_types.delete(ActionCard::DEF)
          target_type = @one_act_card_types & foe_card_types
          return if target_type.size == 0

          # 候補が複数ある場合はランダム選出
          target_type = target_type[rand(target_type.size)]

          # 対象のカードのみにする
          aca = []
          foe.battle_table.shuffle.each do |c|
            aca << c if c.current_type == target_type
          end

          # カードを規定回数伏せる
          Feat.pow(@feats[FEAT_ONE_ACT]).times do |n|
            if aca[n]
              foe.discard_table_event(aca[n])
            end
          end

          feats = get_feats_list_as_for(foe, PHASE_ATTACK)

          feats.each do |f|
            foe.reset_feat_on_cards(f)
            foe.current_chara_card.check_feat(f)
          end

          foe.point_check(Entrant::POINT_CHECK_BATTLE)
          foe.point_rewrite_event
        end
      end
    end
    regist_event FinishOneActFeatEvent

    # ------------------
    # 終極の烈弾
    # ------------------
    # 終極の烈弾が使用されたかのチェック
    def check_final_barrett_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FINAL_BARRETT)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FINAL_BARRETT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFinalBarrettFeatEvent
    regist_event CheckAddFinalBarrettFeatEvent
    regist_event CheckRotateFinalBarrettFeatEvent

    # 終極の烈弾が使用される
    # 有効の場合必殺技IDを返す
    def use_final_barrett_feat()
    end
    regist_event UseFinalBarrettFeatEvent

    # 終極の烈弾が使用終了される
    def finish_final_barrett_feat()
      if @feats_enable[FEAT_FINAL_BARRETT]
        @feats_enable[FEAT_FINAL_BARRETT] = false
        use_feat_event(@feats[FEAT_FINAL_BARRETT])
        target_count = 0
        hps = []
        foe.chara_cards.each_with_index do |c,i|
          if c.status[STATE_TARGET][1] > 0
            target_count += 1
            hps << i if foe.hit_points[i] > 0
          end
        end

        dmg = Feat.pow(@feats[FEAT_FINAL_BARRETT])
        dmg += 1 if target_count == foe.chara_cards.size

        attribute_party_damage(foe, hps, dmg, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL) if hps.size > 0
      end
    end
    regist_event FinishFinalBarrettFeatEvent

    # ------------------
    # グリムデッド(バーベッドヴィクティム)
    # ------------------
    # グリムデッドが使用されたかのチェック
    def check_grimmdead_feat
      @cc.owner.reset_feat_on_cards(FEAT_GRIMMDEAD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_GRIMMDEAD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveGrimmdeadFeatEvent
    regist_event CheckAddGrimmdeadFeatEvent
    regist_event CheckRotateGrimmdeadFeatEvent

    # グリムデッドの補正
    def use_grimmdead_feat_calc()
      if @feats_enable[FEAT_GRIMMDEAD]
        @cc.owner.tmp_power += 1 if owner.direction == Entrant::DIRECTION_BACKWARD
      end
    end
    regist_event UseGrimmdeadFeatCalcEvent

    # グリムデッドが使用される
    def use_grimmdead_feat()
      if @feats_enable[FEAT_GRIMMDEAD]
        use_feat_event(@feats[FEAT_GRIMMDEAD])
      end
    end
    regist_event UseGrimmdeadFeatEvent

    # グリムデッドが使用される
    def use_grimmdead_feat_move_before()
      if @feats_enable[FEAT_GRIMMDEAD]
        @grimmdead_tmp_dist = owner.distance
      end
    end
    regist_event UseGrimmdeadFeatMoveBeforeEvent

    # グリムデッドが使用される
    def use_grimmdead_feat_move_after()
      if @feats_enable[FEAT_GRIMMDEAD]
        dmg = owner.distance - @grimmdead_tmp_dist
        dmg += Feat.pow(@feats[FEAT_GRIMMDEAD]) if dmg > 0
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
    end
    regist_event UseGrimmdeadFeatMoveAfterEvent

    # グリムデッド終了
    def finish_grimmdead_feat()
      if @feats_enable[FEAT_GRIMMDEAD]
        @feats_enable[FEAT_GRIMMDEAD] = false
      end
    end
    regist_event FinishGrimmdeadFeatEvent

    # ------------------
    # ヴンダーカンマー
    # ------------------
    # ヴンダーカンマーが使用されたかのチェック
    def check_wunderkammer_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WUNDERKAMMER)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_WUNDERKAMMER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWunderkammerFeatEvent
    regist_event CheckAddWunderkammerFeatEvent
    regist_event CheckRotateWunderkammerFeatEvent

    # ヴンダーカンマーが使用される
    def use_wunderkammer_feat()
      if @feats_enable[FEAT_WUNDERKAMMER]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_WUNDERKAMMER])
      end
    end
    regist_event UseWunderkammerFeatEvent

    # ヴンダーカンマーが使用される
    def finish_wunderkammer_feat()
      if @feats_enable[FEAT_WUNDERKAMMER]
        use_feat_event(@feats[FEAT_WUNDERKAMMER])
      end
    end
    regist_event FinishWunderkammerFeatEvent

    # ヴンダーカンマーが使用される(ダメージ時)
    # 状態異常で時限治癒される
    def use_wunderkammer_feat_damage()
      if @feats_enable[FEAT_WUNDERKAMMER]
        if duel.tmp_damage>0
          pow = 0
          if @cc.status[STATE_CONTROL][1] > 0
            c = Feat.pow(@feats[FEAT_WUNDERKAMMER]) > 6 ? 1 : 0
            pow = ((foe.cards_max + c)/2).to_i
          else
            pow = Feat.pow(@feats[FEAT_WUNDERKAMMER]) > 6 ? 2 : 1
          end
          set_state(owner.current_chara_card.special_status[SPECIAL_STATE_DEALING_RESTRICTION], pow, 1);
        end
        @feats_enable[FEAT_WUNDERKAMMER] = false
      end
    end
    regist_event UseWunderkammerFeatDamageEvent

    # ------------------
    # コンストレイント
    # ------------------
    # コンストレイントが使用されたかのチェック
    def check_constraint_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_CONSTRAINT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CONSTRAINT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveConstraintFeatEvent
    regist_event CheckAddConstraintFeatEvent
    regist_event CheckRotateConstraintFeatEvent

    # コンストレイントが使用される
    # 有効の場合必殺技IDを返す
    def use_constraint_feat()
      if @feats_enable[FEAT_CONSTRAINT]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CONSTRAINT])
      end
    end
    regist_event UseConstraintFeatEvent

    # コンストレイントが使用終了
    def finish_constraint_feat()
      if @feats_enable[FEAT_CONSTRAINT]
        use_feat_event(@feats[FEAT_CONSTRAINT])
      end
    end
    regist_event FinishConstraintFeatEvent

    # コンストレイントが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_constraint_feat_damage()
      if @feats_enable[FEAT_CONSTRAINT]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0
          # 何を禁止するかはビットで指定
          c_num = 1 # いくつ禁止するか
          case Feat.pow(@feats[FEAT_CONSTRAINT])
          when 7
            c_num = 2
          when 12
            c_num = 3
          else
            c_num = 1
          end
          bits = 0

          c_list = [CONSTRAINT_FORWARD,CONSTRAINT_BACKWARD,CONSTRAINT_STAY,CONSTRAINT_CHARA_CHANGE]
          c_list.delete(CONSTRAINT_CHARA_CHANGE) if get_hps(foe).size == 1
          c_num.times do
            constraint_type = c_list.delete_at(rand(c_list.length))
            bits |= constraint_type
          end

          foe.current_chara_card.special_status[SPECIAL_STATE_CONSTRAINT][0] = bits
          foe.current_chara_card.special_status[SPECIAL_STATE_CONSTRAINT][1] = 1
          foe.duel_message_event(DUEL_MSGDLG_CONSTRAINT, bits)
        end
        @feats_enable[FEAT_CONSTRAINT] = false
      end
    end
    regist_event UseConstraintFeatDamageEvent

    # ------------------
    # リノベートアトランダム
    # ------------------
    # リノベートアトランダムが使用されたかのチェック
    def check_renovate_atrandom_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RENOVATE_ATRANDOM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RENOVATE_ATRANDOM)
       # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRenovateAtrandomFeatEvent
    regist_event CheckAddRenovateAtrandomFeatEvent
    regist_event CheckRotateRenovateAtrandomFeatEvent

    # ヴンダーカンマーが使用される
    def use_renovate_atrandom_feat()
      if @feats_enable[FEAT_RENOVATE_ATRANDOM]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_RENOVATE_ATRANDOM])
      end
    end
    regist_event UseRenovateAtrandomFeatEvent

    # リノベートアトランダム使用終了
    def finish_renovate_atrandom_feat()
      if @feats_enable[FEAT_RENOVATE_ATRANDOM]
        use_feat_event(@feats[FEAT_RENOVATE_ATRANDOM])
        @cc.owner.move_action(-3)
        @cc.foe.move_action(-3)
      end
    end
    regist_event FinishRenovateAtrandomFeatEvent

    # リノベートアトランダム使用
    # 対象とするバッドステータス(軽度)
    # ステータスの選択には一定の優先順位がある
    BAD_STATUS_REVOVARE = [
                  [
                   STATE_MOVE_DOWN,
                   STATE_BIND,
                  ],  # HIGH
                  [
                   STATE_PARALYSIS,
                   STATE_ATK_DOWN,
                   STATE_DEF_DOWN,
                   STATE_POISON,
                   STATE_SEAL,
                   STATE_DARK,
                   ], # MID
                  [
                   STATE_BERSERK,
                   STATE_STONE,
                  ],  # LOW
               ]
    def use_renovate_atrandom_feat_damage()
      if @feats_enable[FEAT_RENOVATE_ATRANDOM]

       # 状態異常のチェック順を決定する
        status_list = []
        status_list.concat(BAD_STATUS_REVOVARE[0].shuffle)
        status_list.concat(BAD_STATUS_REVOVARE[1].shuffle)
        status_list.concat(BAD_STATUS_REVOVARE[2].shuffle)

        # 自PTメンバーの処理順を決定する
        members_num = owner.hit_points.size
        other_members = []
        owner.hit_points.each_index do |i|
          other_members << i if owner.current_chara_card_no != i
        end
        proc_order = []
        proc_order.push(owner.current_chara_card_no)
        proc_order.concat(other_members.shuffle!)

        if @cc.status[STATE_CONTROL][1] == 0
          # 平常時 １ヒットで抜ける
          catch :exit do
            status_list.each do |s|
              proc_order.each do |i|

                if owner.chara_cards[i].status[s][1] > 0
                  foe.current_chara_card.status[s][0] = owner.chara_cards[i].status[s][0]
                  foe.current_chara_card.status[s][1] = owner.chara_cards[i].status[s][1]
                  on_buff_event(false, foe.current_chara_card_no, s, foe.current_chara_card.status[s][0], foe.current_chara_card.status[s][1])
                  owner.chara_cards[i].status[s][1] = 0
                  off_buff_event(true, i, s, owner.chara_cards[i].status[s][0])
                  throw :exit
                end

              end
            end
          end
        else
          # 操想時 一旦集計して重複を省く
          proc_list = { }
          status_list.each do |s|
            proc_list[s] = [1 ,0]
          end

          status_list.each do |s|
            proc_order.each do |i|

              if owner.chara_cards[i].status[s][1] > 0
                proc_list[s][0] = owner.chara_cards[i].status[s][0] if proc_list[s][0] < owner.chara_cards[i].status[s][0]
                proc_list[s][1] = owner.chara_cards[i].status[s][1] if proc_list[s][1] < owner.chara_cards[i].status[s][1]

                owner.chara_cards[i].status[s][1] = 0
                off_buff_event(true, i, s, owner.chara_cards[i].status[s][0])
              end

            end
          end

          proc_list.each do |s, val|
            if val[1] > 0
              foe.current_chara_card.status[s][0] = val[0]
              foe.current_chara_card.status[s][1] = val[1]
              on_buff_event(false, foe.current_chara_card_no, s, foe.current_chara_card.status[s][0], foe.current_chara_card.status[s][1])
            end
          end

        end

        @feats_enable[FEAT_RENOVATE_ATRANDOM] = false
      end
    end
    regist_event UseRenovateAtrandomFeatDamageEvent

    # ------------------
    # 催眠術
    # ------------------
    # 催眠術が使用されたかのチェック
    def check_backbeard_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_BACKBEARD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BACKBEARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBackbeardFeatEvent
    regist_event CheckAddBackbeardFeatEvent
    regist_event CheckRotateBackbeardFeatEvent

    # 催眠術が使用終了
    def finish_backbeard_feat()
      if @feats_enable[FEAT_BACKBEARD]
        use_feat_event(@feats[FEAT_BACKBEARD])
      end
    end
    regist_event FinishBackbeardFeatEvent

    # 催眠術が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_backbeard_feat_damage()
      if @feats_enable[FEAT_BACKBEARD]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage > 0
          attribute_party_damage(foe, get_hps(foe), duel.tmp_damage, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM)
          duel.tmp_damage = 0
        end
        @feats_enable[FEAT_BACKBEARD] = false
      end
    end
    regist_event UseBackbeardFeatDamageEvent

    # ------------------
    # 影縫い
    # ------------------
    # 影縫いが使用されたかのチェック
    def check_shadow_stitch_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SHADOW_STITCH)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_SHADOW_STITCH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveShadowStitchFeatEvent
    regist_event CheckAddShadowStitchFeatEvent
    regist_event CheckRotateShadowStitchFeatEvent

    # 必殺技の状態
    def use_shadow_stitch_feat()
      if @feats_enable[FEAT_SHADOW_STITCH]
        @cc.owner.tmp_power-=Feat.pow(@feats[FEAT_SHADOW_STITCH])
        @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
      end
    end
    regist_event UseShadowStitchFeatEvent

    # 影縫いが使用される
    def finish_shadow_stitch_feat()
      if @feats_enable[FEAT_SHADOW_STITCH]
        use_feat_event(@feats[FEAT_SHADOW_STITCH])
      end
    end
    regist_event FinishShadowStitchFeatEvent

    # 影縫いが使用される(非ダメージ時)
    # 有効の場合必殺技IDを返す
    SHADOW_STITCH_TURNS=[1,4,7,10,13,16]
    def use_shadow_stitch_feat_damage()
      if @feats_enable[FEAT_SHADOW_STITCH]
        if SHADOW_STITCH_TURNS.include?(duel.turn)
          t = Feat.pow(@feats[FEAT_SHADOW_STITCH]) > 10 ? 3 : 2
          buffed = set_state(foe.current_chara_card.status[STATE_PARALYSIS], 1, t);
          on_buff_event(false, foe.current_chara_card_no, STATE_PARALYSIS, foe.current_chara_card.status[STATE_PARALYSIS][0], foe.current_chara_card.status[STATE_PARALYSIS][1]) if buffed
        end
        @feats_enable[FEAT_SHADOW_STITCH] = false
      end
    end
    regist_event UseShadowStitchFeatDamageEvent

    # ------------------
    # ミキストリ
    # ------------------
    # ミキストリが使用されたかのチェック
    def check_mextli_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MEXTLI)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MEXTLI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMextliFeatEvent
    regist_event CheckAddMextliFeatEvent
    regist_event CheckRotateMextliFeatEvent

    # ミキストリを使用
    def use_mextli_feat()
      if @feats_enable[FEAT_MEXTLI]
        set_state(@cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE], Feat.pow(@feats[FEAT_MEXTLI]), 1)
        use_feat_event(@feats[FEAT_MEXTLI])
        on_feat_event(FEAT_MEXTLI)
      end
    end
    regist_event UseMextliFeatEvent

    # ミキストリ終了 常態イベント側から使う
    def finish_mextli_feat()
      off_feat_event(FEAT_MEXTLI)
      @cc.special_status[SPECIAL_STATE_DAMAGE_INSURANCE][1] = 0
      @feats_enable[FEAT_MEXTLI] = false
    end

    # ------------------
    # リベットアンドサージ
    # ------------------
    # リベットアンドサージが使用されたかのチェック
    def check_rivet_and_surge_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_RIVET_AND_SURGE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RIVET_AND_SURGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRivetAndSurgeFeatEvent
    regist_event CheckAddRivetAndSurgeFeatEvent
    regist_event CheckRotateRivetAndSurgeFeatEvent

    # リベットアンドサージが使用される
    def use_rivet_and_surge_feat()
      if @feats_enable[FEAT_RIVET_AND_SURGE]
        add_pt = owner.initiative ? (Feat.pow(@feats[FEAT_RIVET_AND_SURGE]) * 2 + 1) : 0
        @cc.owner.tmp_power+=(owner.get_effective_weapon_status * (Feat.pow(@feats[FEAT_RIVET_AND_SURGE]) - 1) + add_pt)
      end
    end
    regist_event UseRivetAndSurgeFeatAttackEvent
    regist_event UseRivetAndSurgeFeatDefenseEvent

    # リベットアンドサージ 攻撃するときカットイン
    def cutin_rivet_and_surge_feat()
      if @feats_enable[FEAT_RIVET_AND_SURGE] && owner.initiative
        use_feat_event(@feats[FEAT_RIVET_AND_SURGE])
        on_feat_event(FEAT_RIVET_AND_SURGE)
      end
    end
    regist_event CutinRivetAndSurgeFeatEvent

    # ターン終了時に切る
    def finish_rivet_and_surge_feat()
      @feats_enable[FEAT_RIVET_AND_SURGE] = false
      off_feat_event(FEAT_RIVET_AND_SURGE)
    end
    regist_event FinishRivetAndSurgeFeatEvent

    # ------------------
    # ファントマ
    # ------------------
    # ファントマが使用されたかのチェック
    def check_phantomas_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PHANTOMAS)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PHANTOMAS)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePhantomasFeatEvent
    regist_event CheckAddPhantomasFeatEvent
    regist_event CheckRotatePhantomasFeatEvent

    # ファントマが使用終了される
    def finish_phantomas_feat()
      if @feats_enable[FEAT_PHANTOMAS]

        @feats_enable[FEAT_PHANTOMAS] = false
        use_feat_event(@feats[FEAT_PHANTOMAS])

        stealed = false # メッセージ用フラグ
        # 武器性能を盗む
        if foe.has_weapon_status
          # 奪う
          # 既に奪っている場合、上書きする
          owner.reset_current_weapon_bonus()
          owner.set_current_default_weapon_bonus()
          owner.add_current_weapon_bonus(foe.current_weapon_bonus)
          foe.reset_current_weapon_bonus()
          foe.reset_current_default_weapon_bonus()
          stealed = true
        else
          # 手札破棄
          ac = foe.cards.shuffle[0]

          up_list = { }
          if ac
            return if discard(foe, ac) == 0

            case ac.u_type
            when ActionCard::SWD
              up_list[WeaponCard::BORNUS_TYPE_SWORD_AP] = ac.u_value
            when ActionCard::ARW
              up_list[WeaponCard::BORNUS_TYPE_ARROW_AP] = ac.u_value
            when ActionCard::DEF
              up_list[WeaponCard::BORNUS_TYPE_SWORD_DP] = ac.u_value
              up_list[WeaponCard::BORNUS_TYPE_ARROW_DP] = ac.u_value
            end

            if ac.u_type != ac.b_type
              case ac.b_type
              when ActionCard::SWD
                up_list[WeaponCard::BORNUS_TYPE_SWORD_AP] = ac.b_value
              when ActionCard::ARW
                up_list[WeaponCard::BORNUS_TYPE_ARROW_AP] = ac.b_value
              when ActionCard::DEF
                up_list[WeaponCard::BORNUS_TYPE_SWORD_DP] = ac.b_value
                up_list[WeaponCard::BORNUS_TYPE_ARROW_DP] = ac.b_value
              end
            end

          else
            return
          end

          owner.reset_current_weapon_bonus()
          owner.set_current_default_weapon_bonus()

          18.times do
            bornus = [0,0,0,0,0,0,0,0,""]

            # 9 未満のステータスをリストアップ
            under_nine_statuses = []
            for i in [WeaponCard::BORNUS_TYPE_SWORD_AP,WeaponCard::BORNUS_TYPE_ARROW_AP,WeaponCard::BORNUS_TYPE_SWORD_DP,WeaponCard::BORNUS_TYPE_ARROW_DP]
              under_nine_statuses << i if owner.current_weapon_bonus_at(i) < 9
            end

            # 破棄したカードのタイプをリストアップ
            discard_statuses = []
            up_list.each do |key, val|
              discard_statuses << key if val > 0
            end

            # 向上できるステータスは、破棄したカード関連のステータスと9未満のステータスの積集合
            risable_states = discard_statuses & under_nine_statuses
            if risable_states.size > 0
              selected_type = risable_states[rand(risable_states.size)]
              case selected_type
              when WeaponCard::BORNUS_TYPE_SWORD_DP, WeaponCard::BORNUS_TYPE_ARROW_DP
                up_list[WeaponCard::BORNUS_TYPE_SWORD_DP] -= 1
                up_list[WeaponCard::BORNUS_TYPE_ARROW_DP] -= 1
              else
                up_list[selected_type] -= 1
              end
              bornus[selected_type] += 1
              owner.add_current_weapon_bonus([bornus])
              stealed = true
            else
              break
            end
          end
        end

        unless owner.has_weapon
          owner.set_dummy_weapon()
        end
        owner.update_weapon_event
        foe.update_weapon_event
        if stealed
          owner.duel_message_event(DUEL_MSGDLG_WEAPON_STATUS_UP)
          owner.special_gem_bonus_multi=3
        end
      end
    end
    regist_event FinishPhantomasFeatEvent

    # ------------------
    # 危険ドラッグ
    # ------------------
    # 危険ドラッグが使用されたかのチェック
    def check_danger_drug_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DANGER_DRUG)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DANGER_DRUG)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDangerDrugFeatEvent
    regist_event CheckAddDangerDrugFeatEvent
    regist_event CheckRotateDangerDrugFeatEvent

    # 危険ドラッグを使用
    def finish_danger_drug_feat()
      if @feats_enable[FEAT_DANGER_DRUG]
        use_feat_event(@feats[FEAT_DANGER_DRUG])
        @feats_enable[FEAT_DANGER_DRUG] = false
        set_state(@cc.status[STATE_REGENE], 1, Feat.pow(@feats[FEAT_DANGER_DRUG]));
        on_buff_event(true, owner.current_chara_card_no, STATE_REGENE, @cc.status[STATE_REGENE][0], @cc.status[STATE_REGENE][1])
        set_state(@cc.status[STATE_STONE], 1, Feat.pow(@feats[FEAT_DANGER_DRUG]));
        on_buff_event(true, owner.current_chara_card_no, STATE_STONE, @cc.status[STATE_STONE][0], @cc.status[STATE_STONE][1])
      end
    end
    regist_event FinishDangerDrugFeatEvent

    # ------------------
    # HP3サンダー
    # ------------------
    # HP3サンダーが使用されたかのチェック
    def check_three_thunder_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THREE_THUNDER)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_THREE_THUNDER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThreeThunderFeatEvent
    regist_event CheckAddThreeThunderFeatEvent
    regist_event CheckRotateThreeThunderFeatEvent

    # HP3サンダーが使用される 攻撃対象を決めて保持する
    def use_three_thunder_feat()
      if @feats_enable[FEAT_THREE_THUNDER]
        @three_thunder_own_hps = []
        owner.hit_points.each_with_index do |hp, i|
          @three_thunder_own_hps << i if hp > 0 && hp % 3 == 0
        end

        @three_thunder_foe_hps = []
        foe.hit_points.each_with_index do |hp, i|
          @three_thunder_foe_hps << i if hp > 0 && hp % 3 == 0
        end
      end
    end
    regist_event UseThreeThunderFeatEvent

    # HP3サンダーが使用終了される
    def finish_three_thunder_feat()
      if @feats_enable[FEAT_THREE_THUNDER]
        @feats_enable[FEAT_THREE_THUNDER] = false
        use_feat_event(@feats[FEAT_THREE_THUNDER])

        d = Feat.pow(@feats[FEAT_THREE_THUNDER])
        d += 2 if @cc.status[STATE_CONTROL][1] > 0

        if @three_thunder_own_hps.size > 0
          attribute_party_damage(owner, @three_thunder_own_hps, d, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end

        if @three_thunder_foe_hps.size > 0
          attribute_party_damage(foe, @three_thunder_foe_hps, d, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end
      end
    end
    regist_event FinishThreeThunderFeatEvent

    # ------------------
    # 素数ヒール
    # ------------------
    # 素数ヒールが使用されたかのチェック
    def check_prime_heal_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PRIME_HEAL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_PRIME_HEAL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePrimeHealFeatEvent
    regist_event CheckAddPrimeHealFeatEvent
    regist_event CheckRotatePrimeHealFeatEvent

    # 素数ヒールが使用される 攻撃対象を決めて保持する
    def use_prime_heal_feat()
      if @feats_enable[FEAT_PRIME_HEAL]
        @prime_heal_own_hps = []
        owner.hit_points.each_with_index do |hp, i|
          @prime_heal_own_hps << i if hp > 0 && Prime.prime?(hp)
        end

        @prime_heal_foe_hps = []
        foe.hit_points.each_with_index do |hp, i|
          @prime_heal_foe_hps << i if hp > 0 && Prime.prime?(hp)
        end
      end
    end
    regist_event UsePrimeHealFeatEvent

    # 素数ヒールが使用終了される
    def finish_prime_heal_feat()
      if @feats_enable[FEAT_PRIME_HEAL]
        @feats_enable[FEAT_PRIME_HEAL] = false
        use_feat_event(@feats[FEAT_PRIME_HEAL])

        heal_pt = owner.get_battle_table_point(ActionCard::SPC)
        heal_pt = Feat.pow(@feats[FEAT_PRIME_HEAL]) if heal_pt > Feat.pow(@feats[FEAT_PRIME_HEAL])

        @prime_heal_own_hps.each do |i|
          if owner.chara_cards[i].status[STATE_DARK][1] > 0
            attribute_party_damage(owner, i, heal_pt)
          else
            owner.party_healed_event(i, heal_pt)
          end
        end

        @prime_heal_foe_hps.each do |i|
          if foe.chara_cards[i].status[STATE_DARK][1] > 0
            attribute_party_damage(foe, i, heal_pt)
          else
            foe.party_healed_event(i, heal_pt)
          end
        end
      end
    end
    regist_event FinishPrimeHealFeatEvent

    # ------------------
    # HP4コメット
    # ------------------
    # HP4コメットが使用されたかのチェック
    def check_four_comet_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOUR_COMET)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FOUR_COMET)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFourCometFeatEvent
    regist_event CheckAddFourCometFeatEvent
    regist_event CheckRotateFourCometFeatEvent

    # HP4コメットが使用される 攻撃対象を決めて保持する
    def use_four_comet_feat()
      if @feats_enable[FEAT_FOUR_COMET]
        @four_comet_own_hps = []
        owner.hit_points.each_with_index do |hp, i|
          @four_comet_own_hps << i if hp > 0 && hp % 4 == 0
        end

        @four_comet_foe_hps = []
        foe.hit_points.each_with_index do |hp, i|
          @four_comet_foe_hps << i if hp > 0 && hp % 4 == 0
        end
      end
    end
    regist_event UseFourCometFeatEvent

    # HP4コメットが使用終了される
    def finish_four_comet_feat()
      if @feats_enable[FEAT_FOUR_COMET]
        @feats_enable[FEAT_FOUR_COMET] = false
        use_feat_event(@feats[FEAT_FOUR_COMET])

        d = Feat.pow(@feats[FEAT_FOUR_COMET])
        d += 3 if @cc.status[STATE_CONTROL][1] > 0

        if @four_comet_own_hps.size > 0
          attribute_party_damage(owner, @four_comet_own_hps, d, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end

        if @four_comet_foe_hps.size > 0
          attribute_party_damage(foe, @four_comet_foe_hps, d, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        end
      end
    end
    regist_event FinishFourCometFeatEvent

    # ------------------
    # クラブジャグ
    # ------------------
    # クラブジャグが使用されたかのチェック
    def check_club_jugg_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CLUB_JUGG)
      check_feat(FEAT_CLUB_JUGG)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveClubJuggFeatEvent
    regist_event CheckAddClubJuggFeatEvent
    regist_event CheckRotateClubJuggFeatEvent

    # クラブジャグが使用される
    # 有効の場合必殺技IDを返す
    def use_club_jugg_feat()
      if @feats_enable[FEAT_CLUB_JUGG]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_CLUB_JUGG])
      end
    end
    regist_event UseClubJuggFeatEvent

    # 使用したカードからホールドするカードを選び、引く
    def use_club_jugg_feat_deal
      @club_jugg_phase_count = @club_jugg_phase_count ? @club_jugg_phase_count+1 : 1
      if @feats_enable[FEAT_CLUB_JUGG]
        use_feat_event(@feats[FEAT_CLUB_JUGG])
        # 効果発揮は後手のときのみ
        if @club_jugg_phase_count == 2
          deal_list=[]
          owner.battle_table.clone.shuffle.each do |ac|
            deal_list << ac if ac.u_type == ActionCard::DEF || ac.b_type == ActionCard::DEF
            break if deal_list.size > 2
          end
          owner.battle_table = []
          owner.grave_dealed_event(deal_list) unless deal_list.empty?
          finish_club_jugg_feat
        end
      end
    end
    regist_event UseClubJuggFeatDealEvent

    # フェイズカウントリセット
    def finish_club_jugg_feat
      @feats_enable[FEAT_CLUB_JUGG] = false
      @club_jugg_phase_count = nil
    end
    regist_event FinishClubJuggFeatEvent

    # ------------------
    # ナイフジャグ
    # ------------------
    # ナイフジャグが使用されたかのチェック
    def check_knife_jugg_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KNIFE_JUGG)
      check_feat(FEAT_KNIFE_JUGG)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKnifeJuggFeatEvent
    regist_event CheckAddKnifeJuggFeatEvent
    regist_event CheckRotateKnifeJuggFeatEvent

    # ナイフジャグが使用される
    # 有効の場合必殺技IDを返す
    def use_knife_jugg_feat()
      if @feats_enable[FEAT_KNIFE_JUGG]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_KNIFE_JUGG])
      end
    end
    regist_event UseKnifeJuggFeatEvent

    # 使用したカードからホールドするカードを選び、引く
    def use_knife_jugg_feat_deal
      @knife_jugg_phase_count = @knife_jugg_phase_count ? @knife_jugg_phase_count+1 : 1
      if @feats_enable[FEAT_KNIFE_JUGG]
        use_feat_event(@feats[FEAT_KNIFE_JUGG])

        # 効果発揮は後手のときのみ
        if @knife_jugg_phase_count == 2
          deal_list=[]
          owner.battle_table.clone.shuffle.each do |ac|
            deal_list << ac if ac.u_type == ActionCard::SWD || ac.b_type == ActionCard::SWD
            break if deal_list.size > 2
          end
          owner.battle_table = []
          owner.grave_dealed_event(deal_list) unless deal_list.empty?
          finish_knife_jugg_feat
        end
      end
    end
    regist_event UseKnifeJuggFeatDealEvent

    # フェイズカウントリセット
    def finish_knife_jugg_feat
      @feats_enable[FEAT_KNIFE_JUGG] = false
      @knife_jugg_phase_count = nil
    end
    regist_event FinishKnifeJuggFeatEvent

    # ------------------
    # 火吹き
    # ------------------
    # 火吹きが使用されたかのチェック
    def check_blowing_fire_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLOWING_FIRE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BLOWING_FIRE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlowingFireFeatEvent
    regist_event CheckAddBlowingFireFeatEvent
    regist_event CheckRotateBlowingFireFeatEvent

    # 火吹きが使用される
    # 有効の場合必殺技IDを返す
    def use_blowing_fire_feat()
      if @feats_enable[FEAT_BLOWING_FIRE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_BLOWING_FIRE])
      end
    end
    regist_event UseBlowingFireFeatEvent

    # 火吹きが使用終了
    def finish_blowing_fire_feat()
      if @feats_enable[FEAT_BLOWING_FIRE]
        use_feat_event(@feats[FEAT_BLOWING_FIRE])
        # 与えるダメージ
        dmg = 0
        aca = []
        # 剣カードのみにする
        foe.cards.shuffle.each do |c|
           aca << c if c.u_type == ActionCard::SWD || c.b_type == ActionCard::SWD
        end

        discard_num = Feat.pow(@feats[FEAT_BLOWING_FIRE]) > 6 ? 2 : 1
        discard_num.times do |a|
          if aca[a]
            if Feat.pow(@feats[FEAT_BLOWING_FIRE]) > 8
              dmg += discard(foe, aca[a])
            else
              discard(foe, aca[a])
            end
          end
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
      @feats_enable[FEAT_BLOWING_FIRE] = false
    end
    regist_event FinishBlowingFireFeatEvent

    # ------------------
    # バランスボール
    # ------------------
    # バランスボールが使用されたかのチェック
    def check_balance_ball_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BALANCE_BALL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BALANCE_BALL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBalanceBallFeatEvent
    regist_event CheckAddBalanceBallFeatEvent
    regist_event CheckRotateBalanceBallFeatEvent

    # バランスボールを使用
    def use_balance_ball_feat()
      if @feats_enable[FEAT_BALANCE_BALL]
        use_feat_event(@feats[FEAT_BALANCE_BALL])
        owner_direction = owner.get_direction
        foe_direction = foe.get_direction
        case owner_direction
        when Entrant::DIRECTION_FORWARD
          use_feat_event(@feats[FEAT_BALANCE_BALL])
          if foe_direction == Entrant::DIRECTION_BACKWARD
            return
          end
        when Entrant::DIRECTION_BACKWARD
          if foe_direction == Entrant::DIRECTION_FORWARD
            return
          end
        when Entrant::DIRECTION_PEND, Entrant::DIRECTION_STAY, Entrant::DIRECTION_CHARA_CHANGE
          if foe_direction != Entrant::DIRECTION_FORWARD && foe_direction != Entrant::DIRECTION_BACKWARD
            return
          end
        end
        @feats_enable[FEAT_BALANCE_BALL] = false
      end
    end
    regist_event UseBalanceBallFeatEvent

    # バランスボールを使用
    def finish_balance_ball_feat()
      if @feats_enable[FEAT_BALANCE_BALL]
        @feats_enable[FEAT_BALANCE_BALL] = false
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,Feat.pow(@feats[FEAT_BALANCE_BALL])))
      end
    end
    regist_event FinishBalanceBallFeatEvent

    # ------------------
    # 劣化ミルク
    # ------------------
    # 劣化ミルクが使用されたかのチェック
    def check_bad_milk_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BAD_MILK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BAD_MILK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBadMilkFeatEvent
    regist_event CheckAddBadMilkFeatEvent
    regist_event CheckRotateBadMilkFeatEvent

    # 劣化ミルクの効果が発揮される
    def use_bad_milk_feat()
      if @feats_enable[FEAT_BAD_MILK]
        @cc.owner.tmp_power += (foe.chara_cards[foe.current_chara_card_no].ap - Feat.pow(@feats[FEAT_BAD_MILK])) * 2
        @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
      end
    end
    regist_event UseBadMilkFeatEvent

    RECALC_FEATS=
      [
       FEAT_RED_MOON,
       FEAT_EX_RED_MOON,
       FEAT_WHITE_MOON
      ]
    # ベース攻撃力をもとに再計算する技を奪っているとき、再計算終了後に再度足す
    def use_bad_milk_feat_recalc()
      if @feats_enable[FEAT_BAD_MILK] && (@cc.get_enable_feats(PHASE_ATTACK).keys & RECALC_FEATS).size > 0
        @cc.owner.tmp_power += (foe.chara_cards[foe.current_chara_card_no].ap - Feat.pow(@feats[FEAT_BAD_MILK])) * 2
        @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
        owner.point_rewrite_event
      end
    end
    regist_event UseBadMilkFeatRecalcEvent

    # 劣化ミルクの効果が発揮される
    def use_ex_bad_milk_feat()
      if @feats_enable[FEAT_BAD_MILK]
        @cc.owner.tmp_power += (foe.chara_cards[foe.current_chara_card_no].dp - Feat.pow(@feats[FEAT_BAD_MILK])) * 2
        @cc.owner.tmp_power = 0 if @cc.owner.tmp_power < 0
      end
    end
    regist_event UseExBadMilkFeatEvent

    # 劣化ミルクを使用
    def finish_change_bad_milk_feat()
      if @feats_enable[FEAT_BAD_MILK]
        # 自分ひとりでキャラチェンジしたとき移動方向を制御
        owner.set_direction(Entrant::DIRECTION_STAY) if owner.hit_points.select{ |h| h > 0 }.count <= 1 && owner.direction == Entrant::DIRECTION_CHARA_CHANGE
      end
    end
    regist_event FinishChangeBadMilkFeatEvent

    # 劣化ミルクを使用
    def finish_bad_milk_feat()
      if @feats_enable[FEAT_BAD_MILK]
        use_feat_event(@feats[FEAT_BAD_MILK])
        on_feat_event(FEAT_BAD_MILK)
      end
    end
    regist_event FinishBadMilkFeatEvent

    # 劣化ミルクが終了
    def finish_turn_bad_milk_feat()
      if @feats_enable[FEAT_BAD_MILK]
        @feats_enable[FEAT_BAD_MILK] = false
        off_feat_event(FEAT_BAD_MILK)
      end
    end
    regist_event FinishTurnBadMilkFeatEvent

    # ------------------
    # ミラHP
    # ------------------
    # ミラHPが使用されたかのチェック
    def check_mira_hp_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MIRA_HP)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_MIRA_HP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMiraHpFeatEvent
    regist_event CheckAddMiraHpFeatEvent
    regist_event CheckRotateMiraHpFeatEvent

    # 必殺技の状態
    def use_mira_hp_feat()
      if @feats_enable[FEAT_MIRA_HP]
      end
    end
    regist_event UseMiraHpFeatEvent

    # ミラHPが使用される
    def finish_mira_hp_feat()
      if @feats_enable[FEAT_MIRA_HP]
        @mira_hp_before_hp = owner.current_hit_point
        heal_pt = foe.current_hit_point - owner.current_hit_point
        @cc.owner.healed_event(heal_pt) if heal_pt > 0
        owner.damaged_event(-heal_pt, IS_NOT_HOSTILE_DAMAGE) if heal_pt < 0
        use_feat_event(@feats[FEAT_MIRA_HP])
      end
    end
    regist_event FinishMiraHpFeatEvent

    # ミラHPが使用される(ダメージ後)
    # 有効の場合必殺技IDを返す
    def use_mira_hp_feat_damage()
      if @feats_enable[FEAT_MIRA_HP]
        if owner.current_hit_point > @mira_hp_before_hp
          owner.hit_point_changed_event(@mira_hp_before_hp)
        end
        @feats_enable[FEAT_MIRA_HP] = false
      end
    end
    regist_event UseMiraHpFeatDamageEvent

    # ------------------
    # スキルドレイン
    # ------------------
    # スキルドレインが使用されたかのチェック
    def check_skill_drain_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_SKILL_DRAIN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SKILL_DRAIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSkillDrainFeatEvent
    regist_event CheckAddSkillDrainFeatEvent
    regist_event CheckRotateSkillDrainFeatEvent

    # スキルドレインが使用される
    def use_skill_drain_feat()
      if @feats_enable[FEAT_SKILL_DRAIN]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SKILL_DRAIN])
      end
    end
    regist_event UseSkillDrainFeatEvent

    # スキルドレインが使用終了
    def finish_skill_drain_feat()
      if @feats_enable[FEAT_SKILL_DRAIN] && owner.initiative
        use_feat_event(@feats[FEAT_SKILL_DRAIN])
      end
    end
    regist_event FinishSkillDrainFeatEvent

    def use_skill_drain_feat_damage()
      if @feats_enable[FEAT_SKILL_DRAIN] && owner.initiative
        # 相手がだれなのか覚えておく
        @skill_drain_target_chara_index = duel.tmp_damage > 0 ? foe.current_chara_card_no : nil
      end
    end
    regist_event UseSkillDrainFeatDamageEvent

    # 技を上書きする
    COFFIN_DAMAGE=1264
    COFFIN_BAD_STATUS=1266
    COFFIN_ATK=1265
    def finish_skill_drain_feat_finish()
      if @feats_enable[FEAT_SKILL_DRAIN] && @skill_drain_target_chara_index
        @feats_enable[FEAT_SKILL_DRAIN] = false

        return if foe.chara_cards[@skill_drain_target_chara_index].get_feat_ids.size == 0

        if foe.chara_cards[@skill_drain_target_chara_index].charactor_id == GREGOR
          owner.current_chara_card.override_my_feats(3, COFFIN_ATK, true)
        else
          case Feat.pow(@feats[FEAT_SKILL_DRAIN])
          when 4
            owner.current_chara_card.override_my_feats(3, 0, true)
            target_index = rand(foe.chara_cards[@skill_drain_target_chara_index].feat_inventories.size)
            foe.chara_cards[@skill_drain_target_chara_index].override_my_feats(target_index, COFFIN_BAD_STATUS)
          when 5
            target_index = rand(foe.chara_cards[@skill_drain_target_chara_index].feat_inventories.size)
            fi = foe.chara_cards[@skill_drain_target_chara_index].feat_inventories[target_index]
            owner.current_chara_card.override_my_feats(3, fi.feat_id, true)
            foe.chara_cards[@skill_drain_target_chara_index].override_my_feats(target_index, COFFIN_DAMAGE)
          end
        end
      end
    end
    regist_event FinishSkillDrainFeatFinishEvent

    # 現在使用可能なfeat_idの配列をインベントリ順で返す
    def get_feat_ids
      ret = []
      @cc.feat_inventories.each_with_index do |fi, i|
        ret << ((@override_feats && @override_feats.key?(i)) ? @override_feats[i][:feat_id] : fi.feat_id)
      end
      ret
    end

    # 現在使用可能なfeat_noの配列をインベントリ順で返す
    def get_feat_nos
      ret = []
      @cc.feat_inventories.each_with_index do |fi, i|
        ret << ((@override_feats && @override_feats.key?(i)) ? @override_feats[i][:feat_no] : fi.feat.feat_no)
      end
      ret
    end


    # スキル上書き actorは行使者側を示す
    def override_my_feats(index, f_id_src, actor=false)
      @override_feats = { } unless @override_feats

      f_no_src = 0
      actor_index = actor ? owner.current_chara_card_no : nil
      foe_index = @skill_drain_target_chara_index && (foe.chara_cards[@skill_drain_target_chara_index].charactor_id != GREGOR) ? @skill_drain_target_chara_index : nil
      other_feats = { }

      if actor
        if foe_index && @override_feats.size > 0 && @override_feats[3][:foe_index]
          # 現在誰かから借りている場合には返却する
          if @cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL][1] > 0
            foe.chara_cards[@override_feats[3][:foe_index]].reset_override_my_feats()
            @override_feats[3][:other_feats].each_key { |fno| @feats.delete(fno) }
          end

          other_feats = get_other_feats(foe_index, f_id_src)
        end
      else
        @override_feats.each do |index, val|
          @cc.reset_override_my_feats()
        end
      end

      if @cc.feat_inventories[index]
        fi_dist = get_feat_ids[index]
        f_no_dist = get_feat_nos[index]
        f_no_src = Feat[f_id_src].feat_no
        other_feats = get_other_feats(foe_index, f_id_src) if foe_index
        @feats.delete(f_no_dist)
        other_feats.each_key { |fno| @feats.delete(fno) }
        @feats_enable.delete(f_no_dist)
        @feats[f_no_src] = f_id_src
        other_feats.each { |fno, fid| @feats[fno] = fid }

        # 当該スキルのhookを全削
        delete_feat_hook(f_no_dist)

        # 新たにhookを登録
        regist_feat_hook(f_no_src)

        change_feat_event(@cc.index, index, f_id_src, f_no_src)
      end
      set_state(@cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL], 1, 3) if actor
      @override_feats[index] = {
        :feat_id => f_id_src,
        :feat_no=> f_no_src,
        :owner_index=>actor_index,
        :foe_index=>foe_index,
        :other_feats=>other_feats
      }
    end

    # 相手のfeat_id以外の技のリストを返す
    def get_other_feats(chara_index, feat_id)
      others = { }

      foe.chara_cards[chara_index].feat_inventories.each do |fi|
        if fi.feat_id != feat_id
          others[fi.feat.feat_no] = fi.feat_id
        end
      end

      others
    end

    # スキル上書きを解除
    def reset_override_my_feats()
      @override_feats = { } unless @override_feats

      @override_feats.each_key do |index|
        if @cc.feat_inventories[index]
          f_id_dist = @override_feats[index][:feat_id]
          f_no_dist = @override_feats[index][:feat_no]
          fi_src = @cc.feat_inventories[index]
          f_id_src = fi_src.feat_id
          f_no_src = fi_src.feat.feat_no

          @feats.delete(f_no_dist)
          @override_feats[index][:other_feats].each_key { |fno| @feats.delete(fno) } if @override_feats.size > 0
          @feats_enable.delete(f_no_dist)
          @feats[f_no_src] = f_id_src

          delete_feat_hook(f_no_dist)
          regist_feat_hook(f_no_src)

          change_feat_event(@cc.index, index, f_id_src, f_no_src)
          set_state(@cc.special_status[SPECIAL_STATE_OVERRIDE_SKILL], 1, 0)
        end
      end
      @override_feats = { }
    end

    # 技のhookを全て削除する
    def delete_feat_hook(f_no)
      CHARA_FEAT_EVENT_NO[f_no].each do |fe|
        cap = fe.to_s.split('_').collect!{ |w| w.capitalize }.join
        func_name = eval(cap).func_name
        hook_func_name = eval(cap).hook_func_name
        eval("#{hook_func_name}").delete_if{ |method_set| method_set[0] == eval("self.method(:#{func_name})")}
      end
    end

    # 技のhookを登録
    def regist_feat_hook(f_no)
      CHARA_FEAT_EVENT_NO[f_no].each do |g|
        @cc.event.send(g)
      end
    end

    # ------------------
    # コフィン
    # ------------------
    # コフィンが使用されたかのチェック
    def check_coffin_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COFFIN)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_COFFIN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCoffinFeatEvent
    regist_event CheckAddCoffinFeatEvent
    regist_event CheckRotateCoffinFeatEvent

    # コフィンが使用される
    # 有効の場合必殺技IDを返す
    def use_coffin_feat()
      if @feats_enable[FEAT_COFFIN] && Feat.pow(@feats[FEAT_COFFIN]) == 1
        @cc.owner.tmp_power += 10
      end
    end
    regist_event UseCoffinFeatEvent

    # コフィンが使用終了
    GREGOR = 64
    def finish_coffin_feat()
      if @feats_enable[FEAT_COFFIN]
        @feats_enable[FEAT_COFFIN] = false
        if owner.current_chara_card.charactor_id == GREGOR
          use_feat_event(@feats[FEAT_COFFIN])
        else
          off_feat_event(FEAT_COFFIN)
        end

        case Feat.pow(@feats[FEAT_COFFIN])
        when 0
          owner.damaged_event(1, IS_NOT_HOSTILE_DAMAGE)
        when 1
          owner.damaged_event(2, IS_NOT_HOSTILE_DAMAGE)
        when 2
          st_list = [STATE_PARALYSIS, STATE_POISON, STATE_SEAL, STATE_BIND]
          st = st_list[rand(st_list.size)]
          buffed = set_state(owner.current_chara_card.status[st], 1, 3);
          on_buff_event(true, owner.current_chara_card_no, st, owner.current_chara_card.status[st][0], owner.current_chara_card.status[st][1]) if buffed
        end
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishCoffinFeatEvent

    # ------------------
    # 玄青眼
    # ------------------
    # 玄青眼が使用されたかのチェック
    def check_dark_eyes_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DARK_EYES)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DARK_EYES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDarkEyesFeatEvent
    regist_event CheckAddDarkEyesFeatEvent
    regist_event CheckRotateDarkEyesFeatEvent

    # 玄青眼が使用される
    # 有効の場合必殺技IDを返す
    def use_dark_eyes_feat()
      if @feats_enable[FEAT_DARK_EYES]
        owner.tmp_power += Feat.pow(@feats[FEAT_DARK_EYES])
      end
    end
    regist_event UseDarkEyesFeatEvent

    # 玄青眼の靴が使用される
    def use_dark_eyes_feat_move()
      if @feats_enable[FEAT_DARK_EYES]
        use_feat_event(@feats[FEAT_DARK_EYES])
        mov_point = Feat.pow(@feats[FEAT_DARK_EYES]) == 15 ? -2 : -1
        @cc.owner.move_action(mov_point)
        @cc.foe.move_action(mov_point)
      end
    end
    regist_event UseDarkEyesFeatMoveEvent

    # 玄青眼の靴が使用される
    def use_dark_eyes_feat_damage()
      if @feats_enable[FEAT_DARK_EYES]
        if !owner.initiative && duel.tmp_damage > 0
          @cc.owner.move_action(1)
          @cc.foe.move_action(1)
        end
        @feats_enable[FEAT_DARK_EYES] = false
      end
    end
    regist_event UseDarkEyesFeatDamageEvent


    # ------------------
    # 烏爪一転
    # ------------------
    # 烏爪一転が使用されたかのチェック
    def check_crows_claw_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_CROWS_CLAW)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CROWS_CLAW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCrowsClawFeatEvent
    regist_event CheckAddCrowsClawFeatEvent
    regist_event CheckRotateCrowsClawFeatEvent

    # 烏爪一転が使用される
    def use_crows_claw_feat()
      if @feats_enable[FEAT_CROWS_CLAW]
        @feat_crows_clow_level = 0

        if owner.get_type_point_table_count(ActionCard::BLNK, 1, true) > 1
          @feat_crows_clow_level += 1
          if owner.get_type_point_table_count(ActionCard::BLNK, 2, true) > 1
            @feat_crows_clow_level += 1
            if Feat.pow(@feats[FEAT_CROWS_CLAW]) > 0 && owner.get_type_point_table_count(ActionCard::BLNK, 3, true) > 1
              @feat_crows_clow_level += 1
            end
          end
        end

        @cc.owner.tmp_power=5*(3+@feat_crows_clow_level) if @feat_crows_clow_level > 0
      end
    end
    regist_event UseCrowsClawFeatEvent

    # 烏爪一転が使用終了
    def finish_crows_claw_feat()
      if @feats_enable[FEAT_CROWS_CLAW]

        feat_nos = get_feat_nos
        if feat_nos.include?(FEAT_DARK_EYES) && @feat_crows_clow_level > 1
          @feats_enable[FEAT_DARK_EYES] = true
        end
        if feat_nos.include?(FEAT_DARK_EYES) && feat_nos.include?(FEAT_SUNSET) && @feat_crows_clow_level > 2
          @feats_enable[FEAT_SUNSET] = true
        end

        @feats_enable[FEAT_CROWS_CLAW] = false
        use_feat_event(@feats[FEAT_CROWS_CLAW])
      end
    end
    regist_event FinishCrowsClawFeatEvent

    # ------------------
    # 土竜縛符
    # ------------------
    # 土竜縛符が使用されたかのチェック
    def check_mole_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_MOLE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MOLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMoleFeatEvent
    regist_event CheckAddMoleFeatEvent
    regist_event CheckRotateMoleFeatEvent

    # 土竜縛符が使用される
    # 有効の場合必殺技IDを返す
    def use_mole_feat()
      if @feats_enable[FEAT_MOLE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_MOLE])
      end
    end
    regist_event UseMoleFeatEvent

    # 土竜縛符が使用終了
    def finish_mole_feat()
      if @feats_enable[FEAT_MOLE]
        use_feat_event(@feats[FEAT_MOLE])
      end
    end
    regist_event FinishMoleFeatEvent

    # 土竜縛符が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_mole_feat_damage()
      if @feats_enable[FEAT_MOLE]
        # ダメージがマイナス（ダイスの結果防御点の方が上回った場合）
        if duel.tmp_damage <= 0

          counter_dmg = Feat.pow(@feats[FEAT_MOLE])/2
          foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, counter_dmg))

          buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, 2)
          on_buff_event(false,
                        foe.current_chara_card_no,
                        STATE_MOVE_DOWN,
                        foe.current_chara_card.status[STATE_MOVE_DOWN][0],
                        foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        end
        @feats_enable[FEAT_MOLE] = false
      end
    end
    regist_event UseMoleFeatDamageEvent

    # ------------------
    # 五彩晩霞
    # ------------------
    # 五彩晩霞が使用されたかのチェック
    def check_sunset_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SUNSET)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SUNSET)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSunsetFeatEvent
    regist_event CheckAddSunsetFeatEvent
    regist_event CheckRotateSunsetFeatEvent

    # 五彩晩霞が使用される
    # 有効の場合必殺技IDを返す
    def use_sunset_feat()
      if @feats_enable[FEAT_SUNSET]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SUNSET])
      end
    end
    regist_event UseSunsetFeatEvent

    def use_sunset_feat_result
      if @feats_enable[FEAT_SUNSET]
        use_feat_event(@feats[FEAT_SUNSET])
      end
    end
    regist_event UseSunsetFeatResultEvent

    # ダメージ参照
    def use_sunset_feat_damage_check
      if @feats_enable[FEAT_SUNSET]
        @feat_sunset_damage = duel.tmp_damage
      end
    end
    regist_event UseSunsetFeatDamageCheckEvent

    def use_sunset_feat_const_damage()
      if @feats_enable[FEAT_SUNSET]
        @feats_enable[FEAT_SUNSET] = false
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << i if duel.second_entrant.hit_points[i] > 0 && i != foe.current_chara_card_no
        end

        d = @feat_sunset_damage > Feat.pow(@feats[FEAT_SUNSET]) ? Feat.pow(@feats[FEAT_SUNSET]) : @feat_sunset_damage
        attribute_party_damage(foe, hps, d, ATTRIBUTE_CONSTANT, TARGET_TYPE_RANDOM) if d > 0
      end
    end
    regist_event UseSunsetFeatConstDamageEvent

    # ------------------
    # 蔓縛り
    # ------------------
    # 蔓縛りが使用されたかのチェック
    def check_vine_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_VINE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_VINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveVineFeatEvent
    regist_event CheckAddVineFeatEvent
    regist_event CheckRotateVineFeatEvent

    # 必殺技の状態
    def use_vine_feat()
      if @feats_enable[FEAT_VINE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_VINE])
        @feat_vine_distance = owner.distance
      end
    end
    regist_event UseVineFeatEvent

    # 蔓縛りが使用される
    def finish_vine_feat()
      if @feats_enable[FEAT_VINE]
        use_feat_event(@feats[FEAT_VINE])
      end
    end
    regist_event FinishVineFeatEvent

    # 蔓縛りが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_vine_feat_damage()
      if @feats_enable[FEAT_VINE]
        buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 1, 5);
        on_buff_event(false, foe.current_chara_card_no, STATE_MOVE_DOWN, foe.current_chara_card.status[STATE_MOVE_DOWN][0], foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
      end
    end
    regist_event UseVineFeatDamageEvent

    def finish_vine_feat_turn()
      if @feats_enable[FEAT_VINE]
        @feat_vine_distance = nil
        @feats_enable[FEAT_VINE] = false
      end
    end
    regist_event FinishVineFeatTurnEvent

    # ------------------
    # 吸収
    # ------------------
    # 吸収が使用されたかのチェック
    def check_grape_vine_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_GRAPE_VINE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GRAPE_VINE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGrapeVineFeatEvent
    regist_event CheckAddGrapeVineFeatEvent
    regist_event CheckRotateGrapeVineFeatEvent

    # 吸収が使用される
    # 有効の場合必殺技IDを返す
    def use_grape_vine_feat()
      if @feats_enable[FEAT_GRAPE_VINE]
        if @feat_vine_distance && @feat_vine_distance == owner.distance
          @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_GRAPE_VINE])
        else
          off_feat_event(FEAT_GRAPE_VINE)
          @feats_enable[FEAT_GRAPE_VINE] = false
        end
      end
    end
    regist_event UseGrapeVineFeatEvent

    # 吸収使用される
    def use_grape_vine_feat_foe()
      if @feats_enable[FEAT_GRAPE_VINE]
        foe.tmp_power -= Feat.pow(@feats[FEAT_GRAPE_VINE])
        foe.tmp_power = 0 if foe.tmp_power < 0
        foe.point_rewrite_event
        use_feat_event(@feats[FEAT_GRAPE_VINE])
      end
    end
    regist_event UseGrapeVineFeatFoeEvent

    # 吸収が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_grape_vine_feat_damage()
      if @feats_enable[FEAT_GRAPE_VINE]
        @feats_enable[FEAT_GRAPE_VINE] = false
      end
    end
    regist_event UseGrapeVineFeatDamageEvent


    # ------------------
    # サンダーストラック
    # ------------------
    # サンダーストラックが使用されたかのチェック
    def check_thunder_struck_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THUNDER_STRUCK)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_THUNDER_STRUCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThunderStruckFeatEvent
    regist_event CheckAddThunderStruckFeatEvent
    regist_event CheckRotateThunderStruckFeatEvent

    # サンダーストラックが使用される
    def use_thunder_struck_feat()
      if @feats_enable[FEAT_THUNDER_STRUCK]
        mod = @cc.owner.current_hit_point*2
        mod_max = Feat.pow(@feats[FEAT_THUNDER_STRUCK])
        @cc.owner.tmp_power += (mod > mod_max)? mod_max:mod
      end
    end
    regist_event UseThunderStruckFeatEvent

    # サンダーストラックが使用終了される
    def finish_thunder_struck_feat()
      if @feats_enable[FEAT_THUNDER_STRUCK]
        use_feat_event(@feats[FEAT_THUNDER_STRUCK])
        owner.damaged_event(1,IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishThunderStruckFeatEvent

    # サンダーストラックが使用終了される
    def finish_thunder_struck_feat_end()
      if @feats_enable[FEAT_THUNDER_STRUCK]
        @feats_enable[FEAT_THUNDER_STRUCK] = false
      end
    end
    regist_event FinishThunderStruckFeatEndEvent


    # ------------------
    # ウィーヴワールド
    # ------------------
    # ウィーヴワールドが使用されたかのチェック
    def check_weave_world_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WEAVE_WORLD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_WEAVE_WORLD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWeaveWorldFeatEvent
    regist_event CheckAddWeaveWorldFeatEvent
    regist_event CheckRotateWeaveWorldFeatEvent

    # ウィーヴワールドが使用される
    # 有効の場合必殺技IDを返す
    def use_weave_world_feat()
      if @feats_enable[FEAT_WEAVE_WORLD]
        @cc.owner.tmp_power+=5
      end
    end
    regist_event UseWeaveWorldFeatEvent

    # ウィーヴワールドが使用終了される
    def finish_weave_world_feat()
      if @feats_enable[FEAT_WEAVE_WORLD]
        @feats_enable[FEAT_WEAVE_WORLD] = false
        use_feat_event(@feats[FEAT_WEAVE_WORLD])
        dmg = @cc.owner.get_battle_table_point(ActionCard::ARW) + foe.get_type_point_cards_both_faces(ActionCard::SWD)
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,(dmg/Feat.pow(@feats[FEAT_WEAVE_WORLD])).to_i))
      end
    end
    regist_event FinishWeaveWorldFeatEvent

    # ------------------
    # コレクション
    # ------------------
    # コレクションが使用されたかのチェック
    def check_collection_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_COLLECTION)
      check_feat(FEAT_COLLECTION)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCollectionFeatEvent
    regist_event CheckAddCollectionFeatEvent
    regist_event CheckRotateCollectionFeatEvent

    # コレクションが使用される
    # 有効の場合必殺技IDを返す
    def use_collection_feat()
      if @feats_enable[FEAT_COLLECTION]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_COLLECTION])
      end
    end
    regist_event UseCollectionFeatEvent

    def use_collection_feat_deal()
      if @feat_collection_card_list
        if duel.turn > 1 && @feat_collection_card_list["#{duel.turn-1}"]
          owner.battle_table = []
          deal_list = []
          cnt = 0
          @feat_collection_card_list["#{duel.turn-1}"].sort_by{ |c| c.get_value_max }.reverse_each do |c|
            deal_list << c if (!duel.deck.exist?(c) && !foe.cards.include?(c) && !owner.cards.include?(c))  # 山札・手札になければ引く
            break if deal_list.size > 1
          end
          @cc.owner.grave_dealed_event(deal_list)
        end
      end
      init_collection()
    end
    regist_event UseCollectionFeatDealEvent

    # コレクションが使用終了
    def check_table_collection_feat_move
      unless @feat_collection_card_list
        init_collection()
      end
      keep_list = @feat_collection_card_list["#{duel.turn}"]
      keep_list = [] if keep_list.nil?
      foe.battle_table.clone.each do |c|
        keep_list << c
      end
      @feat_collection_card_list["#{duel.turn}"] = keep_list
    end
    regist_event CheckTableCollectionFeatMoveEvent

    # コレクションが使用終了
    def check_table_collection_feat_battle
      unless @feat_collection_card_list
        init_collection()
      end
      keep_list = @feat_collection_card_list["#{duel.turn}"]
      keep_list = [] if keep_list.nil?
      foe.battle_table.clone.each do |c|
        keep_list << c
      end
      @feat_collection_card_list["#{duel.turn}"] = keep_list
    end
    regist_event CheckTableCollectionFeatBattleEvent

    # コレクションが使用終了
    def finish_collection_feat()
      if @feats_enable[FEAT_COLLECTION] && owner.initiative
        use_feat_event(@feats[FEAT_COLLECTION])
      end
    end
    regist_event FinishCollectionFeatEvent

    # 技を発動したかのチェック
    def check_ending_collection_feat()
      if @feats_enable[FEAT_COLLECTION]
        @feats_enable[FEAT_COLLECTION] = false
      else
        init_collection()
      end
    end
    regist_event CheckEndingCollectionFeatEvent

    def init_collection
        @feat_collection_card_list = { }
    end

    # ------------------
    # Dリストリクション
    # ------------------
    # Dリストリクションが使用されたかのチェック
    def check_restriction_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RESTRICTION)
      check_feat(FEAT_RESTRICTION)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRestrictionFeatEvent
    regist_event CheckAddRestrictionFeatEvent
    regist_event CheckRotateRestrictionFeatEvent

    # DEF++
    def use_restriction_feat()
      if @feats_enable[FEAT_RESTRICTION]
        @cc.owner.tmp_power+=owner.get_type_table_count(ActionCard::DEF)
      end
    end
    regist_event UseRestrictionFeatEvent

    # 墓地から距離に応じたタイプのカードをランダムに引く
    def finish_restriction_feat()
      if @feats_enable[FEAT_RESTRICTION]
        use_feat_event(@feats[FEAT_RESTRICTION])
        ac_type = owner.distance == 1 ? ActionCard::SWD : ActionCard::ARW
        num = (duel.deck.get_grave_card_count()/15).to_i+1
        @cc.owner.grave_dealed_event(duel.deck.draw_grave_cards(num, ac_type))
        @feats_enable[FEAT_RESTRICTION] = false
      end
    end
    regist_event FinishRestrictionFeatEvent

    # ------------------
    # DABS
    # ------------------
    # DABS使用されたかのチェック
    def check_dabs_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DABS)
      check_feat(FEAT_DABS)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDabsFeatEvent
    regist_event CheckAddDabsFeatEvent
    regist_event CheckRotateDabsFeatEvent

    # ATK++
    def use_dabs_feat()
      if @feats_enable[FEAT_DABS]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DABS])
      end
    end
    regist_event UseDabsFeatEvent

    # 墓地から距離に応じたタイプのカードをランダムに引く
    def finish_dabs_feat()
      if @feats_enable[FEAT_DABS]
        use_feat_event(@feats[FEAT_DABS])
        num = (duel.deck.get_grave_card_count()/15).to_i+1
        @cc.owner.grave_dealed_event(duel.deck.draw_grave_cards(num, ActionCard::DEF))
        @feats_enable[FEAT_DABS] = false
      end
    end
    regist_event FinishDabsFeatEvent

    # ------------------
    # VIBRATION
    # ------------------
    # VIBRATION使用されたかのチェック
    def check_vibration_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_VIBRATION)
      check_feat(FEAT_VIBRATION)
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveVibrationFeatEvent
    regist_event CheckAddVibrationFeatEvent
    regist_event CheckRotateVibrationFeatEvent

    # ATK++
    def use_vibration_feat()
      if @feats_enable[FEAT_VIBRATION]
        @cc.owner.tmp_power+=duel.deck.get_grave_card_count(4)*Feat.pow(@feats[FEAT_VIBRATION])
      end
    end
    regist_event UseVibrationFeatEvent

    # 墓地から距離に応じたタイプのカードをランダムに引く
    def finish_vibration_feat()
      if @feats_enable[FEAT_VIBRATION]
        use_feat_event(@feats[FEAT_VIBRATION])
        @feats_enable[FEAT_VIBRATION] = false
      end
    end
    regist_event FinishVibrationFeatEvent

    # ------------------
    # Trick or Treat
    # ------------------
    # ToTが使用されたかのチェック
    def check_tot_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TOT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_TOT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTotFeatEvent
    regist_event CheckAddTotFeatEvent
    regist_event CheckRotateTotFeatEvent

    # ToTが使用される
    # 有効の場合必殺技IDを返す
    def use_tot_feat()
      if @feats_enable[FEAT_TOT]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_TOT])
      end
    end
    regist_event UseTotFeatEvent

    # ToTが使用終了
    def finish_tot_feat()
      if @feats_enable[FEAT_TOT]
        use_feat_event(@feats[FEAT_TOT])
      end
    end
    regist_event FinishTotFeatEvent

    # ToTが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_tot_feat_damage()
      if @feats_enable[FEAT_TOT]

        discard_max = 2
        discarded_count = 0
        target_ac_type = owner.distance == 1 ? ActionCard::SWD : ActionCard::ARW
        # 手持ちのカードを複製してシャッフル
        aca =foe.cards.shuffle
        # 最大2枚カードを捨てる
        aca.each do |ac|

          if ac.get_types.include?(target_ac_type)
            discarded_count += discard(foe, ac)
          end

          break if discarded_count >= discard_max

        end

        # 捨てた数が足りなければ
        if discarded_count < discard_max
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, Feat.pow(@feats[FEAT_TOT])))
          buffed = set_state(foe.current_chara_card.status[STATE_STONE], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_STONE, foe.current_chara_card.status[STATE_STONE][0], foe.current_chara_card.status[STATE_STONE][1]) if buffed
        end

        @feats_enable[FEAT_TOT] = false
      end
    end
    regist_event UseTotFeatDamageEvent

    # ------------------
    # ダックアップル
    # ------------------
    # ダックアップルが使用されたかのチェック
    def check_duck_apple_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DUCK_APPLE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DUCK_APPLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveDuckAppleFeatEvent
    regist_event CheckAddDuckAppleFeatEvent
    regist_event CheckRotateDuckAppleFeatEvent

    # ダックアップルを使用
    def finish_duck_apple_feat()
      if @feats_enable[FEAT_DUCK_APPLE]
        use_feat_event(@feats[FEAT_DUCK_APPLE])
        @feats_enable[FEAT_DUCK_APPLE] = false
        target_ac_type = ActionCard::SWD
        type_point = 0
        owner.cards.each do |ac|
          r = ac.get_exist_value?(target_ac_type)
          type_point += r[1] if r
        end

        # 剣が足りなければ引く
        dealed_count = 0
        max_deal_count = 6
        max_deal_count += 2 if Feat.pow(@feats[FEAT_DUCK_APPLE]) == 5
        max_deal_count += 4 if Feat.pow(@feats[FEAT_DUCK_APPLE]) == 7
        while type_point < Feat.pow(@feats[FEAT_DUCK_APPLE]) do
          owner.special_dealed_event(duel.deck.draw_cards_event(1).each{ |c|
                                       r = c.get_exist_value?(target_ac_type)
                                       type_point += r[1] if r
                                       owner.dealed_event(c)
                                     })
          dealed_count += 1
          break if dealed_count >= max_deal_count
        end
      end
    end
    regist_event FinishDuckAppleFeatEvent

    # ------------------
    # ランページ
    # ------------------
    # ランページが使用されたかのチェック
    def check_rampage_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RAMPAGE)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_RAMPAGE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRampageFeatEvent
    regist_event CheckAddRampageFeatEvent
    regist_event CheckRotateRampageFeatEvent

    # 必殺技の状態
    def use_rampage_feat()
      if @feats_enable[FEAT_RAMPAGE]
      end
    end
    regist_event UseRampageFeatEvent

    # ランページが使用される
    def finish_rampage_feat()
      if @feats_enable[FEAT_RAMPAGE]
        use_feat_event(@feats[FEAT_RAMPAGE])
      end
    end
    regist_event FinishRampageFeatEvent

    # ランページが使用される(ダメージ時)
    RAMPAGE_DAMAGE_SET = [
                          (-2..5).to_a,
                          (-1..5).to_a,
                          (1..8).to_a
                         ]
    def use_rampage_feat_damage()
      if @feats_enable[FEAT_RAMPAGE]
        additional_damage = RAMPAGE_DAMAGE_SET[Feat.pow(@feats[FEAT_RAMPAGE])].sample
        additional_damage_str = additional_damage.to_s
        if @cc.status[STATE_CONTROL][1] > 0
          additional_damage += 4
          additional_damage_str = additional_damage_str + "+4"
        end
        owner.special_message_event(:EX_THIRTEEN_EYES, additional_damage_str)
        duel.tmp_damage += additional_damage
        duel.tmp_damage = 0 if duel.tmp_damage < 0
        @feats_enable[FEAT_RAMPAGE] = false
      end
    end
    regist_event UseRampageFeatDamageEvent


    # ------------------
    # スクラッチファイア
    # ------------------
    # スクラッチファイアが使用されたかのチェック
    def check_scratch_fire_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SCRATCH_FIRE)
      # テーブルにアクションカードがおかれていてかつ
      if owner.get_battle_table_point(ActionCard::SWD) > 0
        check_feat(FEAT_SCRATCH_FIRE)
      else
        off_feat_event(FEAT_SCRATCH_FIRE)
        @feats_enable[FEAT_SCRATCH_FIRE] = false
      end
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveScratchFireFeatEvent
    regist_event CheckAddScratchFireFeatEvent
    regist_event CheckRotateScratchFireFeatEvent

    # 必殺技の状態
    def use_scratch_fire_feat()
      if @feats_enable[FEAT_SCRATCH_FIRE]
        @cc.owner.tmp_power+=@cc.owner.table_point_check(ActionCard::SWD)
      end
    end
    regist_event UseScratchFireFeatEvent

    # スクラッチファイアが使用される
    def finish_scratch_fire_feat()
      if @feats_enable[FEAT_SCRATCH_FIRE]
        use_feat_event(@feats[FEAT_SCRATCH_FIRE])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishScratchFireFeatEvent

    # スクラッチファイアが使用される(ダメージ時)
    SCRATCH_FIRE_DAMAGE_SET = [
                          (0..2).to_a,
                          (0..3).to_a,
                          (1..4).to_a
                         ]
    def use_scratch_fire_feat_damage()
      if @feats_enable[FEAT_SCRATCH_FIRE]
        additional_damage = SCRATCH_FIRE_DAMAGE_SET[Feat.pow(@feats[FEAT_SCRATCH_FIRE])].sample
        duel.tmp_damage += additional_damage
        owner.special_message_event(:EX_THIRTEEN_EYES, additional_damage)
        @feats_enable[FEAT_SCRATCH_FIRE] = false
      end
    end
    regist_event UseScratchFireFeatDamageEvent

    # ------------------
    # ブルールーイン
    # ------------------
    # ブルールーインが使用されたかのチェック
    def check_blue_ruin_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BLUE_RUIN)
      if owner.get_battle_table_point(ActionCard::ARW) > 0
        check_feat(FEAT_BLUE_RUIN)
      else
        off_feat_event(FEAT_BLUE_RUIN)
        @feats_enable[FEAT_BLUE_RUIN] = false
      end
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBlueRuinFeatEvent
    regist_event CheckAddBlueRuinFeatEvent
    regist_event CheckRotateBlueRuinFeatEvent

    # ブルールーインが使用される
    # 有効の場合必殺技IDを返す
    def use_blue_ruin_feat()
      if @feats_enable[FEAT_BLUE_RUIN]
      end
    end
    regist_event UseBlueRuinFeatEvent

    # ブルールーインが使用終了
    def finish_blue_ruin_feat()
      if @feats_enable[FEAT_BLUE_RUIN]
        @feats_enable[FEAT_BLUE_RUIN] = false
        use_feat_event(@feats[FEAT_BLUE_RUIN])

        bullets_num = 0
        bullets_num = (1..@cc.owner.table_point_check(ActionCard::ARW)).to_a.sample if @cc.owner.table_point_check(ActionCard::ARW) > 0

        target_indexies = []

        bullets_num.times do |i|
          hps = []
          foe.hit_points.each_index do |i|
            hps << i if foe.hit_points[i] > 0
          end

          break if hps.size == 0

          idx = hps[rand(hps.size)]

          target_indexies << idx unless target_indexies.include?(idx)

          attribute_party_damage(foe, idx, 1)
        end

        # 対象にデバフ
        dark_turn = Feat.pow(@feats[FEAT_BLUE_RUIN]) > 1 ? 5 : 4
        target_indexies.each do |i|
          buffed = set_state(foe.chara_cards[i].status[STATE_DARK], 1, dark_turn);
          on_buff_event(false,
                        i,
                        STATE_DARK,
                        foe.chara_cards[i].status[STATE_DARK][0],
                        foe.chara_cards[i].status[STATE_DARK][1]) if buffed
        end

      end
    end
    regist_event FinishBlueRuinFeatEvent

    # ------------------
    # サードステップ
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_third_step_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THIRD_STEP)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_THIRD_STEP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThirdStepFeatEvent
    regist_event CheckAddThirdStepFeatEvent
    regist_event CheckRotateThirdStepFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_third_step_feat()
      if @feats_enable[FEAT_THIRD_STEP]
      end
    end
    regist_event UseThirdStepFeatEvent

    # 必殺技が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_third_step_feat_damage()
      if @feats_enable[FEAT_THIRD_STEP]
        reduced_damage = (Feat.pow(@feats[FEAT_THIRD_STEP])..@cc.owner.table_point_check(ActionCard::DEF)).to_a.sample
        reduced_damage_str = reduced_damage.to_s
        if @cc.status[STATE_CONTROL][1] > 0
          reduced_damage += 3
          reduced_damage_str = reduced_damage_str + "+3"
        end
        owner.special_message_event(:THIRD_STEP, reduced_damage_str)
        duel.tmp_damage -= reduced_damage
        duel.tmp_damage = 0 if duel.tmp_damage < 0
        @feats_enable[FEAT_THIRD_STEP] = false
      end
    end
    regist_event UseThirdStepFeatDamageEvent

    # 必殺技が使用終了
    def finish_third_step_feat()
      if @feats_enable[FEAT_THIRD_STEP]
        use_feat_event(@feats[FEAT_THIRD_STEP])
        @cc.owner.move_action(-1)
        @cc.foe.move_action(-1)
      end
    end
    regist_event FinishThirdStepFeatEvent

    # ------------------
    # メタルシールド
    # ------------------
    # 突撃が使用されたかのチェック
    def check_metal_shield_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_METAL_SHIELD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_METAL_SHIELD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMetalShieldFeatEvent
    regist_event CheckAddMetalShieldFeatEvent
    regist_event CheckRotateMetalShieldFeatEvent


    # メタルシールドが使用される
    # 有効の場合必殺技IDを返す
    def use_metal_shield_feat()
      if @feats_enable[FEAT_METAL_SHIELD] && !@cc.owner.initiative
        def_pt = @awcs.include?(owner.distance) ? Feat.pow(@feats[FEAT_METAL_SHIELD]) : 1
        @cc.owner.tmp_power += def_pt
      end
    end
    regist_event UseMetalShieldFeatEvent


    # メタルシールドが使用終了
    def finish_metal_shield_feat()
      @metal_shield_checked = false
      if @feats_enable[FEAT_METAL_SHIELD]
        @feats_enable[FEAT_METAL_SHIELD] = false
        use_feat_event(@feats[FEAT_METAL_SHIELD])
      end
    end
    regist_event FinishMetalShieldFeatEvent

    # ------------------
    # 滞留する光波
    # ------------------
    def check_magnetic_field_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MAGNETIC_FIELD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_MAGNETIC_FIELD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMagneticFieldFeatEvent
    regist_event CheckAddMagneticFieldFeatEvent
    regist_event CheckRotateMagneticFieldFeatEvent

    def use_magnetic_field_feat()
      if @feats_enable[FEAT_MAGNETIC_FIELD] && !@cc.owner.initiative
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MAGNETIC_FIELD])
      end
    end
    regist_event UseMagneticFieldFeatEvent

    # 使用終了
    def finish_magnetic_field_feat()
      if @feats_enable[FEAT_MAGNETIC_FIELD]
        use_feat_event(@feats[FEAT_MAGNETIC_FIELD])

        set_state(foe.current_chara_card.special_status[SPECIAL_STATE_MAGNETIC_FIELD], 1, 1)
      end
    end
    regist_event FinishMagneticFieldFeatEvent

    # 使用終了
    def final_magnetic_field_feat()
      if @feats_enable[FEAT_MAGNETIC_FIELD]
        @feats_enable[FEAT_MAGNETIC_FIELD] = false
      end
    end
    regist_event FinalMagneticFieldFeatEvent


    # ------------------
    # 拒絶の余光
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_afterglow_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_AFTERGLOW)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_AFTERGLOW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAfterglowFeatEvent
    regist_event CheckAddAfterglowFeatEvent
    regist_event CheckRotateAfterglowFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_afterglow_feat()
      if @feats_enable[FEAT_AFTERGLOW]
      end
    end
    regist_event UseAfterglowFeatEvent

    # 必殺技が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_afterglow_feat_damage()
      if @feats_enable[FEAT_AFTERGLOW]
        pt = @cc.owner.table_point_check(ActionCard::DEF)
        if duel.tmp_damage >= pt && duel.tmp_damage <= pt + Feat.pow(@feats[FEAT_AFTERGLOW])
          foe.damaged_event(attribute_damage(ATTRIBUTE_REFLECTION, foe, duel.tmp_damage))
          duel.tmp_damage = 0
        end
        @feats_enable[FEAT_AFTERGLOW] = false
      end
    end
    regist_event UseAfterglowFeatDamageEvent

    # 必殺技が使用終了
    def finish_afterglow_feat()
      if @feats_enable[FEAT_AFTERGLOW]
        use_feat_event(@feats[FEAT_AFTERGLOW])
      end
    end
    regist_event FinishAfterglowFeatEvent

    # ------------------
    # 夕暉の番人
    # ------------------
    # 必殺技が使用されたかのチェック
    def check_keeper_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_KEEPER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_KEEPER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKeeperFeatEvent
    regist_event CheckAddKeeperFeatEvent
    regist_event CheckRotateKeeperFeatEvent

    # 必殺技が使用される
    # 有効の場合必殺技IDを返す
    def use_keeper_feat()
      if @feats_enable[FEAT_KEEPER]
        set_state(@cc.special_status[SPECIAL_STATE_CONST_COUNTER], owner.table_point_check(ActionCard::SPC), 1)
        use_feat_event(@feats[FEAT_KEEPER])
      end
    end
    regist_event UseKeeperFeatEvent

    # 必殺技が使用終了
    def finish_keeper_feat()
      if @feats_enable[FEAT_KEEPER]
        @cc.special_status[SPECIAL_STATE_CONST_COUNTER][1] = 0
        @feats_enable[FEAT_KEEPER] = false
      end
    end
    regist_event FinishKeeperFeatEvent
    regist_event FinishKeeperFeatDeadCharaChangeEvent

    # ------------------
    # ヒーリングショック
    # ------------------

    # ヒーリングショックが使用されたかのチェック
    def check_healing_schock_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HEALING_SCHOCK)
      # テーブルにアクションカードがおかれているhealing_schockhealing_schock
      check_feat(FEAT_HEALING_SCHOCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHealingSchockFeatEvent
    regist_event CheckAddHealingSchockFeatEvent
    regist_event CheckRotateHealingSchockFeatEvent

    # ヒーリングショックが使用
    def use_healing_schock_feat()
    end
    regist_event UseHealingSchockFeatEvent

    # ヒーリングショックが使用終了される
    def finish_healing_schock_feat()
      if @feats_enable[FEAT_HEALING_SCHOCK]
        @feats_enable[FEAT_HEALING_SCHOCK] = false
        use_feat_event(@feats[FEAT_HEALING_SCHOCK])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << [i, duel.second_entrant.hit_points[i]] if i != duel.second_entrant.current_chara_card_no && duel.second_entrant.hit_points[i] > 0
        end
        # 控えを回復
        if hps.size > 0
          hps.each do |h|
            duel.second_entrant.party_healed_event(h[0], Feat.pow(@feats[FEAT_HEALING_SCHOCK]))
          end
        end
        # 変身時の効果
        owner.cards_max = owner.cards_max + 1
        # 自身は死亡
        owner.damaged_event(99,IS_NOT_HOSTILE_DAMAGE)
        # HP0以下になったら相手の必殺技を解除
        foe.sealed_event() if owner.hit_point <= 0
      end
    end
    regist_event FinishHealingSchockFeatEvent

    # ------------------
    # クレイモア
    # ------------------
    # クレイモアが使用されたかのチェック
    def check_claymore_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CLAYMORE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CLAYMORE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveClaymoreFeatEvent
    regist_event CheckAddClaymoreFeatEvent
    regist_event CheckRotateClaymoreFeatEvent

    # クレイモアが使用終了される
    def finish_claymore_feat
      if @feats_enable[FEAT_CLAYMORE]
        @feats_enable[FEAT_CLAYMORE] = false
        use_feat_event(@feats[FEAT_CLAYMORE])
        trap_status = { TRAP_STATUS_DISTANCE => 2,
                        TRAP_STATUS_POW => Feat.pow(@feats[FEAT_CLAYMORE]),
                        TRAP_STATUS_TURN => 1,
                        TRAP_STATUS_STATE => TRAP_STATE_READY,
                        TRAP_STATUS_VISIBILITY => false,
                      }
        set_trap(foe, FEAT_CLAYMORE, trap_status)
      end
    end
    regist_event FinishClaymoreFeatEvent

    def claymore_exploded()
      @claymore_exploded = true
    end

    # ------------------
    # トラップチェイス
    # ------------------
    # トラップチェイスが使用されたかのチェック
    def check_trap_chase_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TRAP_CHASE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_TRAP_CHASE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTrapChaseFeatEvent
    regist_event CheckAddTrapChaseFeatEvent
    regist_event CheckRotateTrapChaseFeatEvent

    # トラップチェイス 連携
    # トラップから呼ばれる
    CHARACTOR_ID_RAUL = 70
    def use_trap_chase_feat_chain()
      if @cc.charactor_id == CHARACTOR_ID_RAUL && get_feat_nos.include?(FEAT_TRAP_CHASE)
        # 1枚以上手札がなければ終了
        return if owner.cards.size == 0

        use_feat_event(@feats[FEAT_TRAP_CHASE])

        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 2))

        buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], Feat.pow(@feats[FEAT_TRAP_CHASE]), 2);
        on_buff_event(false, foe.current_chara_card_no, STATE_DEF_DOWN, foe.current_chara_card.status[STATE_DEF_DOWN][0], foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed

        # 手持ちのカードを1枚破棄 数値の低い剣優先
        1.times { |i|
          saca = owner.cards.select { |c| c.get_types.include?(ActionCard::SWD) }
          ac = nil
          if saca.size > 0
            ac = saca.sort_by{ |c| c.get_value_max(ActionCard::SWD) }[0]
          else
            ac = owner.cards.shuffle[0]
          end
          discard(owner, ac) if ac
        }
      end
    end

    def use_trap_chase_feat()
      if @feats_enable[FEAT_TRAP_CHASE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_TRAP_CHASE])
      end
    end
    regist_event UseTrapChaseFeatEvent

    # トラップチェイスが使用終了
    def finish_trap_chase_feat()
      if @feats_enable[FEAT_TRAP_CHASE]
        use_feat_event(@feats[FEAT_TRAP_CHASE])
      end
    end
    regist_event FinishTrapChaseFeatEvent

    # トラップチェイスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_trap_chase_feat_damage()
      if @feats_enable[FEAT_TRAP_CHASE]
        if duel.tmp_damage>0
          # 手持ちのカードを複製してシャッフル
          aca =foe.cards.shuffle
          # ダメージの分だけカードを捨てる
          duel.tmp_damage.times{ |a| discard(foe, aca[a]) if aca[a] }
        end
        @feats_enable[FEAT_TRAP_CHASE] = false
      end
    end
    regist_event UseTrapChaseFeatDamageEvent

    # ------------------
    # パニックグレネード
    # ------------------
    # パニックグレネードが使用されたかのチェック
    def check_panic_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PANIC)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_PANIC)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemovePanicFeatEvent
    regist_event CheckAddPanicFeatEvent
    regist_event CheckRotatePanicFeatEvent

    def use_panic_feat_chain()
      if @cc.charactor_id == CHARACTOR_ID_RAUL && get_feat_nos.include?(FEAT_TRAP_CHASE)
        # 1枚以上手札がなければ終了
        return if (owner.cards.size == 0 || @feats[FEAT_PANIC].nil?)

        use_feat_event(@feats[FEAT_PANIC])

        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 3))

        buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], Feat.pow(@feats[FEAT_PANIC]), 2);
        on_buff_event(false, foe.current_chara_card_no, STATE_ATK_DOWN, foe.current_chara_card.status[STATE_ATK_DOWN][0], foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed

        # 手持ちのカードを1枚破棄 数値の低い銃優先
        1.times { |i|
          aaca = owner.cards.select { |c| c.get_types.include?(ActionCard::ARW) }
          ac = nil
          if aaca.size > 0
            ac = aaca.sort_by{ |c| c.get_value_max(ActionCard::ARW) }[0]
          else
            ac = owner.cards.shuffle[0]
          end
          discard(owner, ac) if ac
        }
      end
    end

    # 必殺技の状態
    def use_panic_feat()
      if @feats_enable[FEAT_PANIC]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_PANIC])
      end
    end
    regist_event UsePanicFeatEvent

    # パニックグレネードが使用される
    def finish_panic_feat()
      if @feats_enable[FEAT_PANIC]
        use_feat_event(@feats[FEAT_PANIC])
      end
    end
    regist_event FinishPanicFeatEvent

    # パニックグレネードが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_panic_feat_damage()
      if @feats_enable[FEAT_PANIC]
        if duel.tmp_damage>0
          buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
        end
        @feats_enable[FEAT_PANIC] = false
      end
    end
    regist_event UsePanicFeatDamageEvent

    # ------------------
    # バレットカウンター
    # ------------------
    # バレットカウンターが使用されたかのチェック
    def check_bullet_counter_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BULLET_COUNTER)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BULLET_COUNTER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBulletCounterFeatEvent
    regist_event CheckAddBulletCounterFeatEvent
    regist_event CheckRotateBulletCounterFeatEvent

    # バレットカウンターが使用される
    # 有効の場合必殺技IDを返す
    def use_bullet_counter_feat()
      if @feats_enable[FEAT_BULLET_COUNTER]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_BULLET_COUNTER])
      end
    end
    regist_event UseBulletCounterFeatEvent

    # バレットカウンターが使用終了
    def finish_bullet_counter_feat()
      if @feats_enable[FEAT_BULLET_COUNTER]
        use_feat_event(@feats[FEAT_BULLET_COUNTER])
        @feats_enable[FEAT_BULLET_COUNTER] = false
        if duel.tmp_damage <= 0
          hps = []
          foe.chara_cards.each_with_index do |c,i|
            hps << i if (c.status[STATE_POISON][1] > 0 || c.status[STATE_POISON2][1] > 0) && foe.hit_points[i] > 0
          end
          # パーティダメージ
          attribute_party_damage(foe, hps, 3, ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)  if hps.size > 0
        end
      end
    end
    regist_event FinishBulletCounterFeatEvent

    # ------------------
    # 大菽嵐
    # ------------------
    # 大菽嵐が使用されたかのチェック
    def check_bean_storm_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_BEAN_STORM)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_BEAN_STORM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveBeanStormFeatEvent
    regist_event CheckAddBeanStormFeatEvent
    regist_event CheckRotateBeanStormFeatEvent

    # 大菽嵐が使用される
    # 有効の場合必殺技IDを返す
    def use_bean_storm_feat()
      if @feats_enable[FEAT_BEAN_STORM]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_BEAN_STORM])
        @cc.owner.tmp_power += 5 if foe.current_chara_card.status[STATE_BIND][1] > 0
      end
    end
    regist_event UseBeanStormFeatEvent

    # 大菽嵐が使用終了
    def finish_bean_storm_feat()
      if @feats_enable[FEAT_BEAN_STORM]
        use_feat_event(@feats[FEAT_BEAN_STORM])
        @feats_enable[FEAT_BEAN_STORM] = false
      end
    end
    regist_event FinishBeanStormFeatEvent

    # ------------------
    # ジョーカー
    # ------------------
    # ジョーカーが使用されたかのチェック
    def check_joker_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_JOKER)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_JOKER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveJokerFeatEvent
    regist_event CheckAddJokerFeatEvent
    regist_event CheckRotateJokerFeatEvent

    # ジョーカーが使用終了
    def finish_joker_feat()
      if @feats_enable[FEAT_JOKER]
        duel.deck.append_joker_card_event
        Feat.pow(@feats[FEAT_JOKER])
        use_feat_event(@feats[FEAT_JOKER])
        @feats_enable[FEAT_JOKER] = false
      end
    end
    regist_event FinishJokerFeatEvent

    # ------------------
    # ファミリア
    # ------------------
    # ファミリアが使用されたかのチェック
    def check_familiar_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FAMILIAR)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FAMILIAR)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFamiliarFeatEvent
    regist_event CheckAddFamiliarFeatEvent
    regist_event CheckRotateFamiliarFeatEvent

    # ファミリアが使用される
    # 有効の場合必殺技IDを返す
    def use_familiar_feat()
      if @feats_enable[FEAT_FAMILIAR]
        num = @cc.owner.cards.count{|ac| ac.joker? }
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_FAMILIAR]) + 6 * num
      end
    end
    regist_event UseFamiliarFeatEvent

    # ファミリアが使用終了
    def finish_familiar_feat()
      if @feats_enable[FEAT_FAMILIAR]
        use_feat_event(@feats[FEAT_FAMILIAR])
        tmp_card = owner.cards.find{|ac| ac.joker?}
        if tmp_card
          discard(owner, tmp_card)
        end
        @feats_enable[FEAT_FAMILIAR] = false
      end
    end
    regist_event FinishFamiliarFeatEvent


    # ------------------
    # クラウンクラウン
    # ------------------
    # クラウンクラウンが使用されたかのチェック
    def check_crown_crown_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CROWN_CROWN)
      check_feat(FEAT_CROWN_CROWN)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCrownCrownFeatEvent
    regist_event CheckAddCrownCrownFeatEvent
    regist_event CheckRotateCrownCrownFeatEvent

    # クラウンクラウンが使用される
    # 有効の場合必殺技IDを返す
    def use_crown_crown_feat()
      if @feats_enable[FEAT_CROWN_CROWN]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_CROWN_CROWN])
      end
    end
    regist_event UseCrownCrownFeatEvent

    # クラウンクラウンが使用終了
    def finish_crown_crown_feat()
      if @feats_enable[FEAT_CROWN_CROWN]
        use_feat_event(@feats[FEAT_CROWN_CROWN])
      end
    end
    regist_event FinishCrownCrownFeatEvent


    # クラウンクラウンが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_crown_crown_feat_damage()
      if @feats_enable[FEAT_CROWN_CROWN]
        num = @cc.owner.cards.count{|ac| ac.joker? }
        duel.tmp_damage += num *2
        tmp_card = owner.cards.find{|ac| ac.joker?}
        if tmp_card
          discard(owner, tmp_card)
        end
        @feats_enable[FEAT_CROWN_CROWN] = false
      end
    end
    regist_event UseCrownCrownFeatDamageEvent


    # ------------------
    # リドルボックス
    # ------------------
    # リドルボックスが使用されたかのチェック
    def check_riddle_box_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RIDDLE_BOX)
      check_feat(FEAT_RIDDLE_BOX)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRiddleBoxFeatEvent
    regist_event CheckAddRiddleBoxFeatEvent
    regist_event CheckRotateRiddleBoxFeatEvent

    # リドルボックスが使用される
    # 有効の場合必殺技IDを返す
    def use_riddle_box_feat()
      if @feats_enable[FEAT_RIDDLE_BOX]

      end
    end
    regist_event UseRiddleBoxFeatEvent

    # リドルボックスが使用終了
    def finish_riddle_box_feat()
      if @feats_enable[FEAT_RIDDLE_BOX]
        use_feat_event(@feats[FEAT_RIDDLE_BOX])
      end
    end
    regist_event FinishRiddleBoxFeatEvent


    # リドルボックスが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_riddle_box_feat_damage()
      if @feats_enable[FEAT_RIDDLE_BOX]
        # 自分
        num = owner.cards.count{|ac| ac.joker?}
        # 最大１５枚までしか増えない
        num = (num * Feat.pow(@feats[FEAT_RIDDLE_BOX]) > 15 )? (15 - num) : num * (Feat.pow(@feats[FEAT_RIDDLE_BOX])-1)
        if num > 0
          # デッキに足してから引く
          num.times do |i|
            duel.deck.append_joker_card_event(true)
          end
          owner.special_dealed_event(duel.deck.draw_cards_event(num).each{ |c| owner.dealed_event(c)})
        end

        # 相手
        num = foe.cards.count{|ac| ac.joker?}
        # 最大１５枚までしか増えない
        num = (num * Feat.pow(@feats[FEAT_RIDDLE_BOX])> 15) ?  (15 - num) : num * (Feat.pow(@feats[FEAT_RIDDLE_BOX])-1)
        if num > 0
          # デッキに足してから引く
          num.times do |i|
            duel.deck.append_joker_card_event(true)
          end
          foe.special_dealed_event(duel.deck.draw_cards_event(num).each{ |c| foe.dealed_event(c)})
        end
      end
      @feats_enable[FEAT_RIDDLE_BOX] = false
    end
    regist_event UseRiddleBoxFeatDamageEvent

    # ------------------
    # 翻る剣舞
    # ------------------
    # 翻る剣舞が使用されたかのチェック
    def check_flutter_sword_dance_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FLUTTER_SWORD_DANCE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FLUTTER_SWORD_DANCE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFlutterSwordDanceFeatEvent
    regist_event CheckAddFlutterSwordDanceFeatEvent
    regist_event CheckRotateFlutterSwordDanceFeatEvent

    # 翻る剣舞を使用
    def finish_flutter_sword_dance_feat()
      if @feats_enable[FEAT_FLUTTER_SWORD_DANCE]
        use_feat_event(@feats[FEAT_FLUTTER_SWORD_DANCE])
        @feats_enable[FEAT_FLUTTER_SWORD_DANCE] = false
        # 移動方向を制御
        owner_tmp = owner.tmp_power
        owner.tmp_power = @cc.status[STATE_PARALYSIS][1] > 0 ? 0 : foe.tmp_power
        foe.tmp_power = owner_tmp
      end
    end
    regist_event FinishFlutterSwordDanceFeatEvent

    # ------------------
    # 勇猛の儀
    # ------------------
    # 勇猛の儀が使用されたかのチェック
    def check_ritual_of_bravery_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_RITUAL_OF_BRAVERY)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_RITUAL_OF_BRAVERY)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveRitualOfBraveryFeatEvent
    regist_event CheckAddRitualOfBraveryFeatEvent
    regist_event CheckRotateRitualOfBraveryFeatEvent

    # 勇猛の儀が使用される
    # 有効の場合必殺技IDを返す
    def use_ritual_of_bravery_feat()
      if @feats_enable[FEAT_RITUAL_OF_BRAVERY]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_RITUAL_OF_BRAVERY])
        @cc.owner.tmp_power += (owner.cards.size - foe.cards.size).abs * 2
      end
    end
    regist_event UseRitualOfBraveryFeatEvent

    # 勇猛の儀が使用終了
    def finish_ritual_of_bravery_feat()
      if @feats_enable[FEAT_RITUAL_OF_BRAVERY]
        use_feat_event(@feats[FEAT_RITUAL_OF_BRAVERY])
      end
      @feats_enable[FEAT_RITUAL_OF_BRAVERY] = false
    end
    regist_event FinishRitualOfBraveryFeatEvent


    # ------------------
    # 狩猟豹の剣
    # ------------------
    # 狩猟豹の剣が使用されたかのチェック
    def check_hunting_cheetah_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HUNTING_CHEETAH)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HUNTING_CHEETAH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHuntingCheetahFeatEvent
    regist_event CheckAddHuntingCheetahFeatEvent
    regist_event CheckRotateHuntingCheetahFeatEvent

    # 必殺技の状態
    def use_hunting_cheetah_feat()
      if @feats_enable[FEAT_HUNTING_CHEETAH]
        @cc.owner.tmp_power += owner.battle_table.size
      end
    end
    regist_event UseHuntingCheetahFeatEvent

    # 狩猟豹の剣が使用される
    def finish_hunting_cheetah_feat()
      if @feats_enable[FEAT_HUNTING_CHEETAH]
        use_feat_event(@feats[FEAT_HUNTING_CHEETAH])
      end
    end
    regist_event FinishHuntingCheetahFeatEvent

    # 狩猟豹の剣が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_hunting_cheetah_feat_damage()
      if @feats_enable[FEAT_HUNTING_CHEETAH]
        foe_size = foe.battle_table ? foe.battle_table.size : 0
        own_size = owner.battle_table ? owner.battle_table.size : 0
        if own_size - foe_size >= 2
          # １回目のダイスを振ってダメージを保存
          rec_damage = duel.tmp_damage
          rec_dice_heads_atk = duel.tmp_dice_heads_atk
          rec_dice_heads_def = duel.tmp_dice_heads_def
          # ダメージ計算をもう１度実行
          @cc.owner.dice_roll_event(duel.battle_result)
          # ダメージをプラス
          duel.tmp_damage += rec_damage
          duel.tmp_dice_heads_atk += rec_dice_heads_atk
          duel.tmp_dice_heads_def += rec_dice_heads_def
        end
        @feats_enable[FEAT_HUNTING_CHEETAH] = false
      end
    end
    regist_event UseHuntingCheetahFeatDamageEvent

    # ------------------
    # 探りの一手
    # ------------------
    # 探りの一手が使用されたかのチェック
    def check_probe_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_PROBE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_PROBE)
      # ポイントの変更をチェoック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveProbeFeatEvent
    regist_event CheckAddProbeFeatEvent
    regist_event CheckRotateProbeFeatEvent

    # 有効の場合必殺技IDを返す
    def use_probe_feat_pow()
      if @feats_enable[FEAT_PROBE]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_PROBE])
      end
    end
    regist_event UseProbeFeatPowEvent

    # 探りの一手が使用される
    def use_probe_feat()
      if @feats_enable[FEAT_PROBE]
        use_feat_event(@feats[FEAT_PROBE])
        @feats_enable[FEAT_PROBE] = false
        return if owner.cards.size == 0

        # 相手に手札を渡す
        # 剣と特殊に重み付け
        sorted_cards = owner.cards.sort_by { |c| c.get_value_max(ActionCard::SWD)*10 + c.get_value_max(ActionCard::SPC) > 1 ? c.get_value_max(ActionCard::SPC) * 9 : 3 + c.get_value_max(ActionCard::ARW)}
        3.times do
          if owner.cards.size > 0
            foe.current_chara_card.steal_deal(owner.cards[owner.cards.index(sorted_cards.shift)])
          end
        end
      end
    end
    regist_event UseProbeFeatEvent

    # 探りの一手が使用終了される
    def finish_probe_feat()
      if @feats_enable[FEAT_PROBE]
      end
    end
    regist_event FinishProbeFeatEvent


    # ------------------
    # 仕立
    # ------------------
    # 仕立が使用されたかのチェック
    def check_tailoring_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TAILORING)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_TAILORING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTailoringFeatEvent
    regist_event CheckAddTailoringFeatEvent
    regist_event CheckRotateTailoringFeatEvent

    # 必殺技の状態
    def use_tailoring_feat()
      if @feats_enable[FEAT_TAILORING]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_TAILORING])
      end
    end
    regist_event UseTailoringFeatEvent

    # 仕立が使用される
    def finish_tailoring_feat()
      if @feats_enable[FEAT_TAILORING]
        @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] += 1 if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] < 3
        stuffed_toys_set_event(true, @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1])
        use_feat_event(@feats[FEAT_TAILORING])
      end
    end
    regist_event FinishTailoringFeatEvent

    # 仕立が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_tailoring_feat_damage()
      if @feats_enable[FEAT_TAILORING]
        if duel.tmp_damage > 0
          buffed = set_state(foe.current_chara_card.status[STATE_POISON], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_POISON, foe.current_chara_card.status[STATE_POISON][0], foe.current_chara_card.status[STATE_POISON][1]) if buffed
        end
        @feats_enable[FEAT_TAILORING] = false
      end
    end
    regist_event UseTailoringFeatDamageEvent

    # ------------------
    # 裁断
    # ------------------
    # 裁断が使用されたかのチェック
    def check_cut_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CUT)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CUT)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCutFeatEvent
    regist_event CheckAddCutFeatEvent
    regist_event CheckRotateCutFeatEvent

    # 裁断が使用される
    # 有効の場合必殺技IDを返す
    def use_cut_feat()
      if @feats_enable[FEAT_CUT]
        multi_num = @cc.status[STATE_CONTROL][1] > 0 ? 3 : 2
        @cc.owner.tmp_power+=@cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] * multi_num
      end
    end
    regist_event UseCutFeatEvent

    # 裁断が使用終了
    def finish_cut_feat()
      if @feats_enable[FEAT_CUT]
        if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 1
          buffed = set_state(foe.current_chara_card.status[STATE_BIND], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_BIND, foe.current_chara_card.status[STATE_BIND][0], foe.current_chara_card.status[STATE_BIND][1]) if buffed
        end
        @feats_enable[FEAT_CUT] = false
        use_feat_event(@feats[FEAT_CUT])
      end
    end
    regist_event FinishCutFeatEvent

    # ------------------
    # 縫製
    # ------------------
    # 縫製が使用されたかのチェック
    def check_sewing_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SEWING)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_SEWING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSewingFeatEvent
    regist_event CheckAddSewingFeatEvent
    regist_event CheckRotateSewingFeatEvent

    # 縫製が使用
    def use_sewing_feat()
      if @feats_enable[FEAT_SEWING]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SEWING]) + @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1]*3
      end
    end
    regist_event UseSewingFeatEvent

    # 縫製が使用終了される
    def finish_sewing_feat()
      if @feats_enable[FEAT_SEWING]
        @feats_enable[FEAT_SEWING] = false
        use_feat_event(@feats[FEAT_SEWING])
        if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] == 3
          duel.second_entrant.healed_event(3)
          buffed = set_state(foe.current_chara_card.status[STATE_DOLL], 1, 3);
          on_buff_event(false, foe.current_chara_card_no, STATE_DOLL, foe.current_chara_card.status[STATE_DOLL][0], foe.current_chara_card.status[STATE_DOLL][1]) if buffed
          @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] = 0
        end
        @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] += 1 if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] < 3
        stuffed_toys_set_event(true, @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1])
      end
    end
    regist_event FinishSewingFeatEvent

    # ------------------
    # 破棄
    # ------------------
    # 破棄が使用されたかのチェック
    def check_cancellation_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CANCELLATION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CANCELLATION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCancellationFeatEvent
    regist_event CheckAddCancellationFeatEvent
    regist_event CheckRotateCancellationFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_cancellation_feat()
    end
    regist_event UseCancellationFeatEvent

    # 破棄が使用終了される
    def finish_cancellation_feat()
      if @feats_enable[FEAT_CANCELLATION]
        @feats_enable[FEAT_CANCELLATION] = false
        use_feat_event(@feats[FEAT_CANCELLATION])
        if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 0
          buffed = set_state(foe.current_chara_card.status[STATE_DEF_DOWN], 6, 5);
          on_buff_event(false,
                        foe.current_chara_card_no,
                        STATE_DEF_DOWN,
                        foe.current_chara_card.status[STATE_DEF_DOWN][0],
                        foe.current_chara_card.status[STATE_DEF_DOWN][1]) if buffed
        end
        if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 1
          buffed = set_state(foe.current_chara_card.status[STATE_ATK_DOWN], 6, 5);
          on_buff_event(false,
                        foe.current_chara_card_no,
                        STATE_ATK_DOWN,
                        foe.current_chara_card.status[STATE_ATK_DOWN][0],
                        foe.current_chara_card.status[STATE_ATK_DOWN][1]) if buffed
        end
        if @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] > 2
          buffed = set_state(foe.current_chara_card.status[STATE_MOVE_DOWN], 2, 5);
          on_buff_event(false,
                        foe.current_chara_card_no,
                        STATE_MOVE_DOWN,
                        foe.current_chara_card.status[STATE_MOVE_DOWN][0],
                        foe.current_chara_card.status[STATE_MOVE_DOWN][1]) if buffed
        end
        multi_num = @cc.status[STATE_CONTROL][1] > 0 ? 3 : 2
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] * multi_num))
        @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1] = 0
        stuffed_toys_set_event(true, @cc.special_status[SPECIAL_STATE_STUFFED_TOYS][1])
      end
    end
    regist_event FinishCancellationFeatEvent

    # ------------------
    # 整法
    # ------------------
    # 整法が使用されたかのチェック
    def check_seiho_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SEIHO)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SEIHO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSeihoFeatEvent
    regist_event CheckAddSeihoFeatEvent
    regist_event CheckRotateSeihoFeatEvent

    # 整法が使用される
    # 有効の場合必殺技IDを返す
    def use_seiho_feat()
      if @feats_enable[FEAT_SEIHO]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_SEIHO])
      end
    end
    regist_event UseSeihoFeatEvent

    # 整法が使用終了
    def finish_seiho_feat()
      if @feats_enable[FEAT_SEIHO]
        use_feat_event(@feats[FEAT_SEIHO])
        @feats_enable[FEAT_SEIHO] = false
        owner.cards.each do |c|
          if (1..60).include?(c.id)
            if c.u_type == ActionCard::SWD && c.u_value < 4
              c.rewrite_u_value(c.u_value+1)
            end
            if c.b_type == ActionCard::SWD && c.b_value < 4
              c.rewrite_b_value(c.b_value+1)
            end
          end
        end
      end

    end
    regist_event FinishSeihoFeatEvent

    # ------------------
    # 独鈷
    # ------------------
    # 独鈷が使用されたかのチェック
    def check_dokko_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DOKKO)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DOKKO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDokkoFeatEvent
    regist_event CheckAddDokkoFeatEvent
    regist_event CheckRotateDokkoFeatEvent

    # 独鈷が使用される
    # 有効の場合必殺技IDを返す
    def use_dokko_feat()
      if @feats_enable[FEAT_DOKKO]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_DOKKO])
      end
    end
    regist_event UseDokkoFeatEvent

    # 使用終了
    def finish_dokko_feat()
      if @feats_enable[FEAT_DOKKO]
        use_feat_event(@feats[FEAT_DOKKO])
      end
    end
    regist_event FinishDokkoFeatEvent

    # 独鈷が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_dokko_feat_damage()
      if @feats_enable[FEAT_DOKKO]
        @feats_enable[FEAT_DOKKO] = false
        owner.cards.each do |c|
          if (1..60).include?(c.id)
            if c.u_type == ActionCard::SWD && (c.u_value == 4 || c.u_value == 5)
              c.rewrite_u_value(6)
            end
            if c.b_type == ActionCard::SWD && (c.b_value == 4 || c.b_value == 5)
              c.rewrite_b_value(6)
            end
          end
        end
      end
    end
    regist_event UseDokkoFeatDamageEvent

    # ------------------
    # 如意
    # ------------------
    # 如意が使用されたかのチェック
    def check_nyoi_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_NYOI)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_NYOI)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveNyoiFeatEvent
    regist_event CheckAddNyoiFeatEvent
    regist_event CheckRotateNyoiFeatEvent

    # 如意が使用される
    # 有効の場合必殺技IDを返す
    def use_nyoi_feat()
      if @feats_enable[FEAT_NYOI]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_NYOI])
      end
    end
    regist_event UseNyoiFeatEvent

    # 使用終了
    def finish_nyoi_feat()
      if @feats_enable[FEAT_NYOI]
        use_feat_event(@feats[FEAT_NYOI])
      end
    end
    regist_event FinishNyoiFeatEvent

    # 如意が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_nyoi_feat_damage()
      if @feats_enable[FEAT_NYOI]
        @feats_enable[FEAT_NYOI] = false
        owner.cards.each do |c|
          if (1..60).include?(c.id)
            if c.u_type == ActionCard::SWD && c.u_value == 6
              c.rewrite_u_value(9)
            end
            if c.b_type == ActionCard::SWD && c.b_value == 6
              c.rewrite_b_value(9)
            end
          end
        end
        if duel.tmp_damage > 0
          foe.cards.each do |c|
            if (1..60).include?(c.id)
              if c.u_value > 1
                c.rewrite_u_value(c.u_value-1)
              end
              if c.b_value > 1
                c.rewrite_b_value(c.b_value-1)
              end
            end
          end
        end
      end
    end
    regist_event UseNyoiFeatDamageEvent

    # ------------------
    # 金剛
    # ------------------
    # 金剛が使用されたかのチェック
    def check_kongo_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_KONGO)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_KONGO)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveKongoFeatEvent
    regist_event CheckAddKongoFeatEvent
    regist_event CheckRotateKongoFeatEvent

    # 金剛の状態
    def use_kongo_feat()
      if @feats_enable[FEAT_KONGO]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_KONGO]) if owner.distance == 3
      end
    end
    regist_event UseKongoFeatEvent

    # 金剛が使用される
    def finish_kongo_feat()
      if @feats_enable[FEAT_KONGO]
        use_feat_event(@feats[FEAT_KONGO])
      end
    end
    regist_event FinishKongoFeatEvent

    # 金剛が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_kongo_feat_damage()
      if @feats_enable[FEAT_KONGO]
        if owner.distance == 1
          duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,8))
        end

        if !instant_kill_guard?(foe)
          buffed = set_state(foe.current_chara_card.status[STATE_STOP], 1, 1);
          on_buff_event(false, foe.current_chara_card_no, STATE_STOP, foe.current_chara_card.status[STATE_STOP][0], foe.current_chara_card.status[STATE_STOP][1]) if buffed
        end
        @feats_enable[FEAT_KONGO] = false
      end
    end
    regist_event UseKongoFeatDamageEvent

    # ------------------
    # 鯉震
    # ------------------
    # 鯉震が使用されたかのチェック
    def check_carp_quake_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CARP_QUAKE)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CARP_QUAKE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveCarpQuakeFeatEvent
    regist_event CheckAddCarpQuakeFeatEvent
    regist_event CheckRotateCarpQuakeFeatEvent

    # 鯉震を使用
    def finish_carp_quake_feat()
      if @feats_enable[FEAT_CARP_QUAKE]
        use_feat_event(@feats[FEAT_CARP_QUAKE])
        @feats_enable[FEAT_CARP_QUAKE] = false
        r = rand(Feat.pow(@feats[FEAT_CARP_QUAKE])) + 1
        foe.special_dealed_event(duel.deck.draw_cards_event(r).each{ |c| @cc.foe.dealed_event(c)})
        r = rand(Feat.pow(@feats[FEAT_CARP_QUAKE])) + 1
        owner.special_dealed_event(duel.deck.draw_cards_event(r).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishCarpQuakeFeatEvent

    # ------------------
    # 鯉光
    # ------------------
    # 鯉光が使用されたかのチェック
    def check_carp_lightning_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CARP_LIGHTNING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CARP_LIGHTNING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCarpLightningFeatEvent
    regist_event CheckAddCarpLightningFeatEvent
    regist_event CheckRotateCarpLightningFeatEvent

    # 鯉光が使用される
    # 有効の場合必殺技IDを返す
    def use_carp_lightning_feat()
      if @feats_enable[FEAT_CARP_LIGHTNING]
        @cc.owner.tmp_power+=(4+Feat.pow(@feats[FEAT_CARP_LIGHTNING])*4)
      end
    end
    regist_event UseCarpLightningFeatEvent

    # 使用終了
    def finish_carp_lightning_feat()
      if @feats_enable[FEAT_CARP_LIGHTNING]
        use_feat_event(@feats[FEAT_CARP_LIGHTNING])
      end
    end
    regist_event FinishCarpLightningFeatEvent

    # 鯉光が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_carp_lightning_feat_damage()
      if @feats_enable[FEAT_CARP_LIGHTNING]
        @feats_enable[FEAT_CARP_LIGHTNING] = false

        max_num = 7
        cnt = 0
        # 数値をpow分増やす
        if duel.tmp_damage < 5
          foe.cards.shuffle.each do |c|
             break if cnt >= max_num
            if (1..60).include?(c.id)
              rewrite_count = false
              if c.u_value < 9
                tmp = c.u_value + Feat.pow(@feats[FEAT_CARP_LIGHTNING])
                c.rewrite_u_value(tmp > 9 ? 9 : tmp)
                rewrite_count = true
              end
              if c.b_value < 9
                tmp = c.b_value + Feat.pow(@feats[FEAT_CARP_LIGHTNING])
                c.rewrite_b_value(tmp > 9 ? 9 : tmp)
                rewrite_count = true
              end
              if rewrite_count
                cnt+=1
              end
            end
          end
        else
          foe.cards.shuffle.each do |c|
             break if cnt >= max_num
            if (1..60).include?(c.id)
              rewrite_count = false
              if c.u_value > 1
                tmp = c.u_value - Feat.pow(@feats[FEAT_CARP_LIGHTNING])
                c.rewrite_u_value(tmp < 1 ? 1 : tmp)
                rewrite_count = true
              end
              if c.b_value > 1
                tmp = c.b_value - Feat.pow(@feats[FEAT_CARP_LIGHTNING])
                c.rewrite_b_value(tmp < 1 ? 1 : tmp)
                rewrite_count = true
              end
              if rewrite_count
                cnt+=1
              end
            end
          end
        end

      end
    end
    regist_event UseCarpLightningFeatDamageEvent

    # ------------------
    # フィールドロック
    # ------------------
    # フィールドロックが使用されたかのチェック
    def check_field_lock_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FIELD_LOCK)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FIELD_LOCK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveFieldLockFeatEvent
    regist_event CheckAddFieldLockFeatEvent
    regist_event CheckRotateFieldLockFeatEvent

    # フィールドロックの効果が発揮される
    def use_field_lock_feat()
      if @feats_enable[FEAT_FIELD_LOCK]
        owner.set_field_status_event(Entrant::FIELD_STATUS["AC_LOCK"], 1, 1)
        use_feat_event(@feats[FEAT_FIELD_LOCK])
        @feats_enable[FEAT_FIELD_LOCK] = false
      end
    end
    regist_event UseFieldLockFeatEvent


    # ------------------
    # 捕縛
    # ------------------
    # 捕縛が使用されたかのチェック
    def check_arrest_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_ARREST)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ARREST)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveArrestFeatEvent
    regist_event CheckAddArrestFeatEvent
    regist_event CheckRotateArrestFeatEvent

    # 捕縛が使用される
    # 有効の場合必殺技IDを返す
    def use_arrest_feat()
      if @feats_enable[FEAT_ARREST]
        @cc.owner.tmp_power+= (Feat.pow(@feats[FEAT_ARREST]) * owner.distance)
      end
    end
    regist_event UseArrestFeatEvent


    # 捕縛が使用終了
    def finish_arrest_feat()
      if @feats_enable[FEAT_ARREST]
        use_feat_event(@feats[FEAT_ARREST])
      end
    end
    regist_event FinishArrestFeatEvent

    # 捕縛が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_arrest_feat_damage()
      if @feats_enable[FEAT_ARREST]
        @feats_enable[FEAT_ARREST] = false
        if duel.tmp_damage <= 0 && foe.tmp_power > 0
          lock_cards_num = (duel.tmp_dice_heads_def - duel.tmp_dice_heads_atk)
          card_id_list = foe.cards.map { |c| c.id }
          return if lock_cards_num < 1 || card_id_list.size == 0

          lock_id_list = card_id_list.shuffle.shift(lock_cards_num)
          lock_id_list.each { |id| foe.card_lock_event(id) }
        end
      end
    end
    regist_event UseArrestFeatDamageEvent

    # ------------------
    # クイックドロー
    # ------------------
    # クイックドローが使用されたかのチェック
    def check_quick_draw_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_QUICK_DRAW)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_QUICK_DRAW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveQuickDrawFeatEvent
    regist_event CheckAddQuickDrawFeatEvent
    regist_event CheckRotateQuickDrawFeatEvent

    # クイックドローが使用される
    def use_quick_draw_feat()
      if @feats_enable[FEAT_QUICK_DRAW]
        @cc.owner.tmp_power+= (Feat.pow(@feats[FEAT_QUICK_DRAW]) + owner.distance * 2)
      end
    end
    regist_event UseQuickDrawFeatEvent

    # クイックドローが使用終了
    def finish_quick_draw_feat()
      if @feats_enable[FEAT_QUICK_DRAW]
        @feats_enable[FEAT_QUICK_DRAW] = false
        use_feat_event(@feats[FEAT_QUICK_DRAW])
      end
    end
    regist_event FinishQuickDrawFeatEvent

    # ------------------
    # ゲイズ
    # ------------------
    # ゲイズが使用されたかのチェック
    def check_gaze_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_GAZE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_GAZE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveGazeFeatEvent
    regist_event CheckAddGazeFeatEvent
    regist_event CheckRotateGazeFeatEvent

    def use_gaze_feat()
      if @feats_enable[FEAT_GAZE]
        @cc.owner.tmp_power+= (Feat.pow(@feats[FEAT_GAZE]) * foe.battle_table.size)
      end
    end
    regist_event UseGazeFeatEvent

    # ゲイズが使用される
    def finish_gaze_feat()
      if @feats_enable[FEAT_GAZE]
        @feats_enable[FEAT_GAZE] = false
        use_feat_event(@feats[FEAT_GAZE])
        tmp_table = foe.battle_table.clone.sort_by { |c| [c.u_value, c.b_value] }
        gaze_cnt = 2
        draw_table = []
        gaze_cnt.times do |n|
          break if tmp_table.size == 0
          draw_table << tmp_table.shift
        end
        foe.battle_table = []
        lock_id_list = draw_table.map { |c| c.id }
        foe.grave_dealed_event(draw_table)

        lock_id_list.each { |id| foe.card_lock_event(id) }
      end
    end
    regist_event FinishGazeFeatEvent
    regist_event FinishCharaChangeGazeFeatEvent
    regist_event FinishFoeCharaChangeGazeFeatEvent

    # ------------------
    # 監視
    # ------------------
    # 監視が使用されたかのチェック
    def check_monitoring_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MONITORING)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_MONITORING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveMonitoringFeatEvent
    regist_event CheckAddMonitoringFeatEvent
    regist_event CheckRotateMonitoringFeatEvent

    # 必殺技の状態
    def use_monitoring_feat()
      if @feats_enable[FEAT_MONITORING]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MONITORING]) if owner.distance == 1
      end
    end
    regist_event UseMonitoringFeatEvent

    # 監視が使用される
    def finish_monitoring_feat()
      if @feats_enable[FEAT_MONITORING]
        use_feat_event(@feats[FEAT_MONITORING])
        @feats_enable[FEAT_MONITORING] = false
      end
    end
    regist_event FinishMonitoringFeatEvent

    # 有効の場合必殺技IDを返す
    def use_monitoring_feat_damage()
      if @feats_enable[FEAT_MONITORING]
        foe.monitoring = true
        set_state(foe.current_chara_card.special_status[SPECIAL_STATE_MONITORING], 0, 1)
      end
    end
    regist_event UseMonitoringFeatDamageEvent

    # ------------------
    # 時差ドロー
    # ------------------
    # 時差ドローが使用されたかのチェック
    def check_time_lag_draw_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_LAG_DRAW)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TIME_LAG_DRAW)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTimeLagDrawFeatEvent
    regist_event CheckAddTimeLagDrawFeatEvent
    regist_event CheckRotateTimeLagDrawFeatEvent

    def use_time_lag_draw_feat
      if @feats_enable[FEAT_TIME_LAG_DRAW]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_TIME_LAG_DRAW])
      end
    end
    regist_event UseTimeLagDrawFeatEvent

    # 時差ドローを使用
    def finish_time_lag_draw_feat()
      if @feats_enable[FEAT_TIME_LAG_DRAW]
        use_feat_event(@feats[FEAT_TIME_LAG_DRAW])
        @feats_enable[FEAT_TIME_LAG_DRAW] = false
        set_state(@cc.special_status[SPECIAL_STATE_TIME_LAG_DROW], 0, 1)
      end
    end
    regist_event FinishTimeLagDrawFeatEvent

    # ------------------
    # 時差バフ
    # ------------------
    # 時差バフが使用されたかのチェック
    def check_time_lag_buff_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_TIME_LAG_BUFF)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_TIME_LAG_BUFF)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveTimeLagBuffFeatEvent
    regist_event CheckAddTimeLagBuffFeatEvent
    regist_event CheckRotateTimeLagBuffFeatEvent

    def use_time_lag_buff_feat
      if @feats_enable[FEAT_TIME_LAG_BUFF]
      end
    end
    regist_event UseTimeLagBuffFeatEvent

    # 時差バフを使用
    def finish_time_lag_buff_feat()
      if @feats_enable[FEAT_TIME_LAG_BUFF]
        use_feat_event(@feats[FEAT_TIME_LAG_BUFF])
        @feats_enable[FEAT_TIME_LAG_BUFF] = false
        owner.hit_points.each_index do |i|
          if owner.hit_points[i] > 0
            set_state(owner.chara_cards[i].special_status[SPECIAL_STATE_TIME_LAG_BUFF], Feat.pow(@feats[FEAT_TIME_LAG_BUFF]), 1)
          end
        end
      end
    end
    regist_event FinishTimeLagBuffFeatEvent

    # ------------------
    # 移転
    # ------------------
    # 移転が使用されたかのチェック
    def check_damage_transfer_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DAMAGE_TRANSFER)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_DAMAGE_TRANSFER)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDamageTransferFeatEvent
    regist_event CheckAddDamageTransferFeatEvent
    regist_event CheckRotateDamageTransferFeatEvent

    # 移転が使用
    def use_damage_transfer_feat()
      if @feats_enable[FEAT_DAMAGE_TRANSFER]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DAMAGE_TRANSFER])
      end
    end
    regist_event UseDamageTransferFeatEvent

    # 移転が使用終了される
    def finish_damage_transfer_feat()
      if @feats_enable[FEAT_DAMAGE_TRANSFER]
        @feats_enable[FEAT_DAMAGE_TRANSFER] = false
        use_feat_event(@feats[FEAT_DAMAGE_TRANSFER])
        hps = []
        duel.second_entrant.hit_points.each_index do |i|
          hps << [i, duel.second_entrant.hit_points[i], duel.second_entrant.chara_cards[i].hp - duel.second_entrant.hit_points[i]] if duel.second_entrant.hit_points[i] > 0
        end
        if hps.size > 1
          hps.shuffle! if hps.size ==2 && hps[0][1] == hps[1][1] # 残り二人のhpが同じ値ならばランダムに入れ替える
          chp = hps.sort!{ |a,b| a[1] <=> b[1] }.shift

          dmg = 0
          hps.each do |hp|
            @cc.owner.party_healed_event(hp[0], hp[2])
            dmg += hp[2]
          end

          duel.second_entrant.party_damaged_event(chp[0], dmg)
        end
      end
    end
    regist_event FinishDamageTransferFeatEvent

    # ------------------
    # シガレット
    # ------------------
    # シガレットが使用されたかのチェック
    def check_cigarette_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CIGARETTE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_CIGARETTE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveCigaretteFeatEvent
    regist_event CheckAddCigaretteFeatEvent
    regist_event CheckRotateCigaretteFeatEvent

    # シガレットが使用される
    # 有効の場合必殺技IDを返す
    def use_cigarette_feat()
      if @feats_enable[FEAT_CIGARETTE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_CIGARETTE])
      end
    end
    regist_event UseCigaretteFeatEvent

    # シガレットが使用終了
    def finish_cigarette_feat()
      if @feats_enable[FEAT_CIGARETTE]
        use_feat_event(@feats[FEAT_CIGARETTE])
        @feats_enable[FEAT_CIGARETTE] = false
        return if duel.tmp_damage < 1

        num = 0
        aca = []
        owner.cards.shuffle.each do |c|
          if (c.u_value < 3 && c.b_value < 3)
            duel.tmp_damage -= 1
            aca << c
          end
          break if duel.tmp_damage == 0 || aca.size == 2
        end

        aca.each do |c|
          discard(owner, c)
        end
      end
    end
    regist_event FinishCigaretteFeatEvent

    # ------------------
    # スリーカード
    # ------------------
    # スリーカードが使用されたかのチェック
    def check_three_card_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_THREE_CARD)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_THREE_CARD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveThreeCardFeatEvent
    regist_event CheckAddThreeCardFeatEvent
    regist_event CheckRotateThreeCardFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_three_card_feat()
      if @feats_enable[FEAT_THREE_CARD]
        add_pt = 0
        if owner.get_type_point_table_count(ActionCard::ARW, 2, true) > 2
          add_pt = 14
        end
        if owner.get_type_point_table_count(ActionCard::ARW, 1, true) > 2
          add_pt += 7
        end
        @cc.owner.tmp_power += add_pt
      end
    end
    regist_event UseThreeCardFeatEvent

    # スリーカードが使用終了される
    def finish_three_card_feat()
      if @feats_enable[FEAT_THREE_CARD]
        @feats_enable[FEAT_THREE_CARD] = false
        use_feat_event(@feats[FEAT_THREE_CARD])

        if owner.get_type_point_table_count(ActionCard::SWD, 2, true) > 2
          set_state(owner.current_chara_card.status[STATE_ATK_UP], 7, 4);
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        elsif owner.get_type_point_table_count(ActionCard::SWD, 1, true) > 2
          set_state(owner.current_chara_card.status[STATE_ATK_UP], 5, 3);
          on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
        end

        if owner.get_type_point_table_count(ActionCard::DEF, 2, true) > 2
          set_state(owner.current_chara_card.status[STATE_DEF_UP], 7, 4);
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        elsif owner.get_type_point_table_count(ActionCard::DEF, 1, true) > 2
          set_state(owner.current_chara_card.status[STATE_DEF_UP], 5, 3);
          on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
        end

        if owner.get_type_point_table_count(ActionCard::MOVE, 2, true) > 2
          set_state(owner.current_chara_card.status[STATE_MOVE_UP], 2, 4);
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        elsif owner.get_type_point_table_count(ActionCard::MOVE, 1, true) > 2
          set_state(owner.current_chara_card.status[STATE_MOVE_UP], 1, 3);
          on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        end

        d = 0
        if owner.get_type_point_table_count(ActionCard::SPC, 2, true) > 2
          d += 7
        end
        if owner.get_type_point_table_count(ActionCard::SPC, 1, true) > 2
          d += 3
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,d)) if d > 0
      end
    end
    regist_event FinishThreeCardFeatEvent

    # ------------------
    # カードサーチ
    # ------------------
    # カードサーチが使用されたかのチェック
    def check_card_search_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_CARD_SEARCH)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_CARD_SEARCH)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveCardSearchFeatEvent
    regist_event CheckAddCardSearchFeatEvent
    regist_event CheckRotateCardSearchFeatEvent

    # カードサーチを使用
    def finish_card_search_feat()
      if @feats_enable[FEAT_CARD_SEARCH]
        use_feat_event(@feats[FEAT_CARD_SEARCH])
        @feats_enable[FEAT_CARD_SEARCH] = false
        @cc.owner.special_dealed_event(duel.deck.draw_low_cards_event(Feat.pow(@feats[FEAT_CARD_SEARCH]), 2).each{ |c| @cc.owner.dealed_event(c)})
      end
    end
    regist_event FinishCardSearchFeatEvent

    # ------------------
    # オールインワン
    # ------------------
    # オールインワンが使用されたかのチェック
    def check_all_in_one_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ALL_IN_ONE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_ALL_IN_ONE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAllInOneFeatEvent
    regist_event CheckAddAllInOneFeatEvent
    regist_event CheckRotateAllInOneFeatEvent

    def use_all_in_one_feat_power()
      if @feats_enable[FEAT_ALL_IN_ONE]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ALL_IN_ONE])
      end
    end
    regist_event UseAllInOneFeatPowerEvent

    # オールインワンが使用される
    def use_all_in_one_feat()
      if @feats_enable[FEAT_ALL_IN_ONE]
        # 自分のカードを回転する
        owner.battle_table.each do |a|
          owner.event_card_rotate_action(a.id, Entrant::TABLE_BATTLE, 0, (rand(2) == 1)? true : false)
        end
      end
    end
    regist_event UseAllInOneFeatEvent

    # オールインワンが使用終了される
    def finish_all_in_one_feat()
      if @feats_enable[FEAT_ALL_IN_ONE]
        use_feat_event(@feats[FEAT_ALL_IN_ONE])
        duel.tmp_damage *= 2
        @feats_enable[FEAT_ALL_IN_ONE] = false
      end
    end
    regist_event FinishAllInOneFeatEvent

    # ------------------
    # 焼鳥
    # ------------------
    # 焼鳥が使用されたかのチェック
    def check_fire_bird_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FIRE_BIRD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FIRE_BIRD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFireBirdFeatEvent
    regist_event CheckAddFireBirdFeatEvent
    regist_event CheckRotateFireBirdFeatEvent

    # 焼鳥が使用される
    # 有効の場合必殺技IDを返す
    def use_fire_bird_feat()
    end
    regist_event UseFireBirdFeatEvent

    # 焼鳥が使用される
    def use_after_fire_bird_feat()
      if @feats_enable[FEAT_FIRE_BIRD]
        use_feat_event(@feats[FEAT_FIRE_BIRD])
        aca = []
        dmg = 0
        # 手持ちのカードを複製してシャッフル
        aca = foe.cards.shuffle
        # カードを全て捨てる
        aca.count.times do |a|
          if aca[a]
            dmg+=discard(foe, aca[a])
          end
        end
        foe.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, dmg * Feat.pow(@feats[FEAT_FIRE_BIRD])))
        owner.healed_event(dmg * Feat.pow(@feats[FEAT_FIRE_BIRD])) if owner.hit_point > 0
      end
      @feats_enable[FEAT_FIRE_BIRD] = false
    end
    regist_event UseAfterFireBirdFeatEvent

    # 焼鳥が使用終了される
    def finish_fire_bird_feat()
      if @feats_enable[FEAT_FIRE_BIRD]
      end
    end
    regist_event FinishFireBirdFeatEvent

    # ------------------
    # 苔蔦
    # ------------------
    # 苔蔦が使用されたかのチェック
    def check_brambles_feat
      @cc.owner.reset_feat_on_cards(FEAT_BRAMBLES)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_BRAMBLES)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveBramblesFeatEvent
    regist_event CheckAddBramblesFeatEvent
    regist_event CheckRotateBramblesFeatEvent

    # 苔蔦が使用される
    def use_brambles_feat()
      if @feats_enable[FEAT_BRAMBLES]
        use_feat_event(@feats[FEAT_BRAMBLES])
      end
    end
    regist_event UseBramblesFeatEvent

    # 苔蔦が使用される
    def use_brambles_feat_move_before()
      if @feats_enable[FEAT_BRAMBLES]
        @brambles_tmp_dist = owner.distance
      end
    end
    regist_event UseBramblesFeatMoveBeforeEvent

    # 苔蔦が使用される
    def use_brambles_feat_move_after()
      if @feats_enable[FEAT_BRAMBLES]
        dmg = (owner.distance - @brambles_tmp_dist).abs * 2
        foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,dmg)) if dmg > 0
      end
    end
    regist_event UseBramblesFeatMoveAfterEvent

    # 苔蔦終了
    def finish_brambles_feat()
      if @feats_enable[FEAT_BRAMBLES]
        @feats_enable[FEAT_BRAMBLES] = false
      end
    end
    regist_event FinishBramblesFeatEvent

    # ------------------
    # フランケンタックル
    # ------------------
    # フランケンタックルが使用されたかのチェック
    def check_franken_tackle_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FRANKEN_TACKLE)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FRANKEN_TACKLE)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFrankenTackleFeatEvent
    regist_event CheckAddFrankenTackleFeatEvent
    regist_event CheckRotateFrankenTackleFeatEvent

    # フランケンタックルが使用される
    # 有効の場合必殺技IDを返す
    def use_franken_tackle_feat()
      if @feats_enable[FEAT_FRANKEN_TACKLE] && owner.battle_table.count >= foe.battle_table.count
        foe.tmp_power = foe.tmp_power/2
      end
    end
    regist_event UseOwnerFrankenTackleFeatEvent
    regist_event UseFoeFrankenTackleFeatEvent

    def use_franken_tackle_feat_dice_attr()
      if @feats_enable[FEAT_FRANKEN_TACKLE]
        foe.point_check_silence(Entrant::POINT_CHECK_BATTLE)
        foe.point_rewrite_event
      end
    end
    regist_event UseFrankenTackleFeatDiceAttrEvent

    # フランケンタックルが使用終了
    def finish_franken_tackle_feat()
      if @feats_enable[FEAT_FRANKEN_TACKLE]
        use_feat_event(@feats[FEAT_FRANKEN_TACKLE])
        @feats_enable[FEAT_FRANKEN_TACKLE] = false
      end
    end
    regist_event FinishFrankenTackleFeatEvent


    # ------------------
    # フランケン充電
    # ------------------
    # フランケン充電が使用されたかのチェック
    def check_franken_charging_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FRANKEN_CHARGING)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_FRANKEN_CHARGING)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFrankenChargingFeatEvent
    regist_event CheckAddFrankenChargingFeatEvent
    regist_event CheckRotateFrankenChargingFeatEvent

    # フランケン充電が使用される
    # 有効の場合必殺技IDを返す
    def use_franken_charging_feat()
      if @feats_enable[FEAT_FRANKEN_CHARGING]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_FRANKEN_CHARGING])*@cc.owner.battle_table.count
      end
    end
    regist_event UseFrankenChargingFeatEvent

    # フランケン充電が使用終了
    def finish_franken_charging_feat()
      if @feats_enable[FEAT_FRANKEN_CHARGING]
        use_feat_event(@feats[FEAT_FRANKEN_CHARGING])
      end
    end
    regist_event FinishFrankenChargingFeatEvent

    def use_franken_charging_feat_damage()
      if @feats_enable[FEAT_FRANKEN_CHARGING]
        if @cc.owner.battle_table.count > 3
          # １回目のダイスを振ってダメージを保存
          rec_damage = duel.tmp_damage
          rec_dice_heads_atk = duel.tmp_dice_heads_atk
          rec_dice_heads_def = duel.tmp_dice_heads_def
          # ダメージ計算をもう１度実行
          @cc.owner.dice_roll_event(duel.battle_result)
          # ダメージをプラス
          duel.tmp_damage += rec_damage
          duel.tmp_dice_heads_atk += rec_dice_heads_atk
          duel.tmp_dice_heads_def += rec_dice_heads_def
        end
        @feats_enable[FEAT_FRANKEN_CHARGING] = false
      end
    end
    regist_event UseFrankenChargingFeatDamageEvent

    # ------------------
    # 挑みかかるものR
    # ------------------
    # 近距離移動が使用されたかのチェック
    def check_moving_one_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MOVING_ONE_R)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MOVING_ONE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMovingOneRFeatEvent
    regist_event CheckAddMovingOneRFeatEvent
    regist_event CheckRotateMovingOneRFeatEvent

    # 必殺技の状態
    def use_moving_one_r_feat()
      if @feats_enable[FEAT_MOVING_ONE_R]
        @moving_one_r_feat_tmp_hp = owner.hit_point
        @moving_one_r_feat_tmp_mv = @cc.owner.table_point_check(ActionCard::MOVE)
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_MOVING_ONE_R]) if foe.hit_point > owner.hit_point
      end
    end
    regist_event UseMovingOneRFeatEvent

    # おいしいミルクの効果が発揮される
    def use_moving_one_r_feat_attack()
      if @feats_enable[FEAT_MOVING_ONE_R]
        @cc.owner.tmp_power += 10
      end
    end
    regist_event UseMovingOneRFeatAttackEvent

    # おいしいミルクの効果が発揮される
    def use_moving_one_r_feat_defense()
      if @feats_enable[FEAT_MOVING_ONE_R]
        @cc.owner.tmp_power -= 5
      end
    end
    regist_event UseMovingOneRFeatDefenseEvent

    # 近距離移動を使用
    def finish_moving_one_r_feat()
      if @feats_enable[FEAT_MOVING_ONE_R]
        use_feat_event(@feats[FEAT_MOVING_ONE_R])
        if @moving_one_r_feat_tmp_mv > 0
          @feats_enable[FEAT_MOVING_ONE_R] = false
        else
          on_transform_sequence(true)
        end
        @cc.owner.move_action(-3)
        @cc.foe.move_action(-3)
      end
    end
    regist_event FinishMovingOneRFeatEvent

    def finish_turn_moving_one_r_feat()
      if @feats_enable[FEAT_MOVING_ONE_R]
        @feats_enable[FEAT_MOVING_ONE_R] = false
        owner.healed_event((@moving_one_r_feat_tmp_hp - owner.hit_point + 1)/2) if @moving_one_r_feat_tmp_hp > owner.hit_point && owner.hit_point > 0
        off_transform_sequence(true)
      end
    end
    regist_event FinishTurnMovingOneRFeatEvent

    # ------------------
    # 驕りたかぶるもの
    # ------------------
    # 驕りたかぶるものが使用されたかのチェック
    def check_arrogant_one_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ARROGANT_ONE_R)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ARROGANT_ONE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveArrogantOneRFeatEvent
    regist_event CheckAddArrogantOneRFeatEvent
    regist_event CheckRotateArrogantOneRFeatEvent

    # 驕りたかぶるものが使用される
    # 有効の場合必殺技IDを返す
    def use_arrogant_one_r_feat()
      if @feats_enable[FEAT_ARROGANT_ONE_R]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_ARROGANT_ONE_R])
      end
    end
    regist_event UseArrogantOneRFeatEvent

    # 驕りたかぶるものが使用終了
    def finish_arrogant_one_r_feat()
      if @feats_enable[FEAT_ARROGANT_ONE_R]
        use_feat_event(@feats[FEAT_ARROGANT_ONE_R])
        @feats_enable[FEAT_ARROGANT_ONE_R] = false
        buffed = set_state(foe.current_chara_card.status[STATE_STONE], 1, 3)
        on_buff_event(false, foe.current_chara_card_no, STATE_STONE, foe.current_chara_card.status[STATE_STONE][0], foe.current_chara_card.status[STATE_STONE][1]) if buffed
        const_damage = 2
        duel.first_entrant.damaged_event(attribute_damage(ATTRIBUTE_COUNTER, foe, const_damage)) if foe.hit_point > owner.hit_point
      end
    end
    regist_event FinishArrogantOneRFeatEvent

    # ------------------
    # 貪り食うもの
    # ------------------
    # 貪り食うものが使用されたかのチェック
    def check_eating_one_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_EATING_ONE_R)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_EATING_ONE_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveEatingOneRFeatEvent
    regist_event CheckAddEatingOneRFeatEvent
    regist_event CheckRotateEatingOneRFeatEvent

    # 貪り食うものが使用される
    # 有効の場合必殺技IDを返す
    def use_eating_one_r_feat()
      if @feats_enable[FEAT_EATING_ONE_R]
        @cc.owner.tmp_power+=(@cc.owner.table_point_check(ActionCard::MOVE)*Feat.pow(@feats[FEAT_EATING_ONE_R]))
      end
    end
    regist_event UseEatingOneRFeatEvent

    # 貪り食うものが使用終了
    def finish_eating_one_r_feat()
      if @feats_enable[FEAT_EATING_ONE_R]
        @feats_enable[FEAT_EATING_ONE_R] = false
        use_feat_event(@feats[FEAT_EATING_ONE_R])
        @cc.owner.move_action(1)
        @cc.foe.move_action(1)
      end
    end
    regist_event FinishEatingOneRFeatEvent

    # ------------------
    # ハーフデッド
    # ------------------
    # ハーフデッドが使用されたかのチェック
    def check_harf_dead_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HARF_DEAD)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_HARF_DEAD)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHarfDeadFeatEvent
    regist_event CheckAddHarfDeadFeatEvent
    regist_event CheckRotateHarfDeadFeatEvent

    # ハーフデッドが使用終了
    def use_harf_dead_feat()
      if @feats_enable[FEAT_HARF_DEAD]
        use_feat_event(@feats[FEAT_HARF_DEAD])
        # 移動方向を制御
        if foe.direction == Entrant::DIRECTION_STAY || foe.direction == Entrant::DIRECTION_CHARA_CHANGE
          foe.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, foe, 4))
          foe.set_direction(Entrant::DIRECTION_PEND) if foe.get_direction == 0
        end
      end
    end
    regist_event UseHarfDeadFeatEvent

    # ハーフデッドが使用終了
    def finish_harf_dead_feat()
      if @feats_enable[FEAT_HARF_DEAD]
        @feats_enable[FEAT_HARF_DEAD] = false
        # HPのチェック
        if @cc.owner.current_hit_point_max/2 > @cc.owner.hit_point
          heal_num = @cc.owner.current_hit_point_max/2 - @cc.owner.hit_point
          @cc.owner.healed_event(heal_num)
        end
      end
    end
    regist_event FinishHarfDeadFeatEvent

    # ------------------
    # 指向性エネルギー兵器
    # ------------------
    # 指向性エネルギー兵器が使用されたかのチェック
    def check_directional_beam_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DIRECTIONAL_BEAM)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_DIRECTIONAL_BEAM)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDirectionalBeamFeatEvent
    regist_event CheckAddDirectionalBeamFeatEvent
    regist_event CheckRotateDirectionalBeamFeatEvent

    # 必殺技の状態
    def use_directional_beam_feat()
      if @feats_enable[FEAT_DIRECTIONAL_BEAM]
      end
    end
    regist_event UseDirectionalBeamFeatEvent

    # 指向性エネルギー兵器が使用される
    def finish_directional_beam_feat()
      if @feats_enable[FEAT_DIRECTIONAL_BEAM]
        use_feat_event(@feats[FEAT_DIRECTIONAL_BEAM])
      end
    end
    regist_event FinishDirectionalBeamFeatEvent

    # 指向性エネルギー兵器が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_directional_beam_feat_damage()
      if @feats_enable[FEAT_DIRECTIONAL_BEAM]
        if duel.tmp_damage>0
          duel.tmp_damage += duel.tmp_damage * rand(Feat.pow(@feats[FEAT_DIRECTIONAL_BEAM]))
        end
        @feats_enable[FEAT_DIRECTIONAL_BEAM] = false
      end
    end
    regist_event UseDirectionalBeamFeatDamageEvent

    # ------------------
    # ヒートシーカー R
    # ------------------
    # ヒートシーカーが使用されたかのチェック
    def check_heat_seeker_r_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_HEAT_SEEKER_R)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_HEAT_SEEKER_R)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveHeatSeekerRFeatEvent
    regist_event CheckAddHeatSeekerRFeatEvent
    regist_event CheckRotateHeatSeekerRFeatEvent

    # ヒートシーカーが使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_heat_seeker_r_feat_damage()
      if @feats_enable[FEAT_HEAT_SEEKER_R]
        use_feat_event(@feats[FEAT_HEAT_SEEKER_R])

        if @cc.status[STATE_DEF_DOWN][1] > 0
          @cc.status[STATE_DEF_DOWN][1] = 0
          off_buff_event(true, owner.current_chara_card_no, STATE_DEF_DOWN, @cc.status[STATE_DEF_DOWN][0])
        end

        buff_turn = 4
        set_state(@cc.status[STATE_ATK_UP], Feat.pow(@feats[FEAT_HEAT_SEEKER_R]), buff_turn)
        on_buff_event(true, owner.current_chara_card_no, STATE_ATK_UP, @cc.status[STATE_ATK_UP][0], @cc.status[STATE_ATK_UP][1])
      end
    end
    regist_event UseHeatSeekerRFeatDamageEvent

    def finish_heat_seeker_r_feat_damage()
      if @feats_enable[FEAT_HEAT_SEEKER_R]
        owner.point_rewrite_event
        @feats_enable[FEAT_HEAT_SEEKER_R] = false
      end
    end
    regist_event FinishHeatSeekerRFeatDamageEvent


    # ------------------
    # マシンセル
    # ------------------
    # マシンセルが使用されたかのチェック
    def check_machine_cell_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_MACHINE_CELL)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_MACHINE_CELL)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveMachineCellFeatEvent
    regist_event CheckAddMachineCellFeatEvent
    regist_event CheckRotateMachineCellFeatEvent

    # マシンセルを使用
    def finish_machine_cell_feat()
      if @feats_enable[FEAT_MACHINE_CELL]
        use_feat_event(@feats[FEAT_MACHINE_CELL])
        @feats_enable[FEAT_MACHINE_CELL] = false

        owner.healed_event(Feat.pow(@feats[FEAT_MACHINE_CELL]))

        set_state(@cc.status[STATE_MOVE_UP], 2, 2)
        on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])

        set_state(@cc.special_status[SPECIAL_STATE_MACHINE_CELL], 0, 1)
      end
    end
    regist_event FinishMachineCellFeatEvent


    # ------------------
    # デルタ
    # ------------------
    # デルタが使用されたかのチェック
    def check_delta_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_DELTA)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_DELTA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveDeltaFeatEvent
    regist_event CheckAddDeltaFeatEvent
    regist_event CheckRotateDeltaFeatEvent

    # デルタが使用される
    # 有効の場合必殺技IDを返す
    def use_delta_feat()
      if @feats_enable[FEAT_DELTA]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_DELTA])
      end
    end
    regist_event UseDeltaFeatEvent

    # デルタが使用終了
    def finish_delta_feat()
      if @feats_enable[FEAT_DELTA]
        use_feat_event(@feats[FEAT_DELTA])
        @feats_enable[FEAT_DELTA] = false
        d = foe.current_chara_card.status[STATE_BIND][1]
        d += 1 if d > 0
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,d))
      end
    end
    regist_event FinishDeltaFeatEvent

    # ------------------
    # シグマ
    # ------------------
    # シグマが使用されたかのチェック
    def check_sigma_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_SIGMA)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_SIGMA)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveSigmaFeatEvent
    regist_event CheckAddSigmaFeatEvent
    regist_event CheckRotateSigmaFeatEvent

    # シグマが使用される
    # 有効の場合必殺技IDを返す
    def use_sigma_feat()
      if @feats_enable[FEAT_SIGMA]
        @cc.owner.tmp_power += Feat.pow(@feats[FEAT_SIGMA])
      end
    end
    regist_event UseSigmaFeatEvent

    # シグマが使用終了
    def ex_sigma0_feat()
      if @feats_enable[FEAT_SIGMA]
        spp = @cc.owner.get_battle_table_point(ActionCard::SPC)
        if spp > 0 && (foe.current_chara_card.status[STATE_BIND][1] > 0)
          @cc.owner.move_action(spp)
          @cc.foe.move_action(spp)
        end
      end
    end
    regist_event ExSigma0FeatEvent

    # シグマが使用終了
    def ex_sigma_feat()
      if @feats_enable[FEAT_SIGMA]
        @cc.owner.move_action(-2)
        @cc.foe.move_action(-2)
      end
    end
    regist_event ExSigmaFeatEvent

    # シグマが使用終了
    def finish_sigma_feat()
      if @feats_enable[FEAT_SIGMA]
        @feats_enable[FEAT_SIGMA] = false
        use_feat_event(@feats[FEAT_SIGMA])
        @cc.owner.move_action(2)
        @cc.foe.move_action(2)
      end
    end
    regist_event FinishSigmaFeatEvent

    # ------------------
    # スタンプ
    # ------------------
    # スタンプが使用されたかのチェック
    def check_stamp_feat
      # カードをON情報をリセットしてから
        @cc.owner.reset_feat_on_cards(FEAT_STAMP)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_STAMP)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveStampFeatEvent
    regist_event CheckAddStampFeatEvent
    regist_event CheckRotateStampFeatEvent

    # スタンプが使用される
    def use_stamp_feat()
      if @feats_enable[FEAT_STAMP]
        @cc.owner.tmp_power+=Feat.pow(@feats[FEAT_STAMP])
      end
    end
    regist_event UseStampFeatEvent

    # スタンプが使用終了
    def finish_stamp_feat()
      if @feats_enable[FEAT_STAMP]
        set_state(@cc.special_status[SPECIAL_STATE_AX_GUARD], 1, 1)
        use_feat_event(@feats[FEAT_STAMP])
        @feats_enable[FEAT_STAMP] = false
      end
    end
    regist_event FinishStampFeatEvent

    # ------------------
    # アクセラレーション
    # ------------------
    # アクセラレーションが使用されたかのチェック
    def check_acceleration_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ACCELERATION)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_ACCELERATION)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_MOVE)
    end
    regist_event CheckRemoveAccelerationFeatEvent
    regist_event CheckAddAccelerationFeatEvent
    regist_event CheckRotateAccelerationFeatEvent

    # 必殺技の状態
    def use_acceleration_feat()
      if @feats_enable[FEAT_ACCELERATION]
        @cc.owner.tmp_power = 0
      end
    end
    regist_event UseAccelerationFeatEvent

    # アクセラレーションを使用
    def finish_acceleration_feat()
      if @feats_enable[FEAT_ACCELERATION]
        use_feat_event(@feats[FEAT_ACCELERATION])
        @feats_enable[FEAT_ACCELERATION] = false
        set_state(@cc.status[STATE_MOVE_UP], 2, 3);
        on_buff_event(true, owner.current_chara_card_no, STATE_MOVE_UP, @cc.status[STATE_MOVE_UP][0], @cc.status[STATE_MOVE_UP][1])
        set_state(@cc.status[STATE_DEF_UP], 6, 3);
        on_buff_event(true, owner.current_chara_card_no, STATE_DEF_UP, @cc.status[STATE_DEF_UP][0], @cc.status[STATE_DEF_UP][1])
      end
    end
    regist_event FinishAccelerationFeatEvent

    # ------------------
    # FOAB
    # ------------------
    # FOABが使用されたかのチェック
    def check_foab_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_FOAB)
      # テーブルにアクションカードがおかれている
      check_feat(FEAT_FOAB)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveFoabFeatEvent
    regist_event CheckAddFoabFeatEvent
    regist_event CheckRotateFoabFeatEvent

    # 狂気の眼窩が使用される
    # 有効の場合必殺技IDを返す
    def use_foab_feat()
    end
    regist_event UseFoabFeatEvent

    # FOABが使用終了される
    def finish_foab_feat()
      if @feats_enable[FEAT_FOAB]
        @feats_enable[FEAT_FOAB] = false
        use_feat_event(@feats[FEAT_FOAB])
        # 敵デッキ全体にダメージ
        hps = []
        foe.hit_points.each_with_index do |v,i|
          hps << i if v > 0
        end
        attribute_party_damage(foe, hps, Feat.pow(@feats[FEAT_FOAB]), ATTRIBUTE_CONSTANT, TARGET_TYPE_ALL)
        own_dmg = @cc.special_status[SPECIAL_STATE_AX_GUARD][1] > 0 ? (Feat.pow(@feats[FEAT_FOAB])/2).to_i : Feat.pow(@feats[FEAT_FOAB])
        duel.first_entrant.damaged_event(own_dmg,IS_NOT_HOSTILE_DAMAGE)
      end
    end
    regist_event FinishFoabFeatEvent

    # ------------------
    # 白き玉桂
    # ------------------
    # 白き玉桂が使用されたかのチェック
    def check_white_moon_feat
      f_no = @feats[FEAT_WHITE_MOON]
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_WHITE_MOON)
      # テーブルにアクションカードがおかれていてかつ、距離が近距離の時
      check_feat(FEAT_WHITE_MOON)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveWhiteMoonFeatEvent
    regist_event CheckAddWhiteMoonFeatEvent
    regist_event CheckRotateWhiteMoonFeatEvent

    # 白き玉桂 攻撃力変更 このメソッドは一度だけ攻撃力を計算する
    def use_white_moon_feat()
      if @feats_enable[FEAT_WHITE_MOON]
        unless @lock
          f_id = @feats[FEAT_WHITE_MOON]
          @cc.owner.tmp_power += foe.tmp_power + Feat.pow(f_id)
          @lock = true
          @locked_value = foe.tmp_power + Feat.pow(f_id)
        else
          @cc.owner.tmp_power += @locked_value
        end
      end
    end
    regist_event UseWhiteMoonFeatEvent

    # 白き玉桂 攻撃力変更 双方のcalc_resolve終了後、一度だけ攻撃力を再計算し変更する
    def use_white_moon_feat_dice_attr()
      if @feats_enable[FEAT_WHITE_MOON]
        f_id = @feats[FEAT_WHITE_MOON]
        @cc.owner.tmp_power = owner.battle_point_calc(owner.attack_type, owner.attack_point) + foe.tmp_power + Feat.pow(f_id)
        @lock = false
        owner.point_rewrite_event
      end
    end
    regist_event UseWhiteMoonFeatDiceAttrEvent

    # 白き玉桂が使用終了
    def finish_white_moon_feat()
      if @feats_enable[FEAT_WHITE_MOON]
        f_id = @feats[FEAT_WHITE_MOON]
        use_feat_event(f_id)
        if @cc.owner.get_battle_table_point(ActionCard::SPC) >= owner.hit_point && @cc.status[STATE_BERSERK][1] > 0
          duel.first_entrant.damaged_event(owner.hit_point-1,IS_NOT_HOSTILE_DAMAGE)
        else
          duel.first_entrant.damaged_event(@cc.owner.get_battle_table_point(ActionCard::SPC),IS_NOT_HOSTILE_DAMAGE)
        end
        duel.second_entrant.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT,foe,@cc.owner.get_battle_table_point(ActionCard::SPC)))
      end
    end
    regist_event FinishWhiteMoonFeatEvent

    # 白き玉桂が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_white_moon_feat_damage()
      if @feats_enable[FEAT_WHITE_MOON]
        # ダメージが1以上
        f_no = FEAT_WHITE_MOON
        @feats_enable[f_no] = false
      end
    end
    regist_event UseWhiteMoonFeatDamageEvent

    # ------------------
    # 憤怒の背中
    # ------------------
    # 静謐な背中が使用されたかのチェック
    def check_anger_back_feat
      # カードをON情報をリセットしてから
      @cc.owner.reset_feat_on_cards(FEAT_ANGER_BACK)
      # テーブルにアクションカードがおかれていてかつ
      check_feat(FEAT_ANGER_BACK)
      # ポイントの変更をチェック
      @cc.owner.point_check(Entrant::POINT_CHECK_BATTLE)
    end
    regist_event CheckRemoveAngerBackFeatEvent
    regist_event CheckAddAngerBackFeatEvent
    regist_event CheckRotateAngerBackFeatEvent

    # 必殺技の状態
    def use_anger_back_feat()
      if @feats_enable[FEAT_ANGER_BACK]
        s = @cc.owner.get_battle_table_point(ActionCard::SPC)
        s = 6 if s > 6
        if s > 0
          if @cc.status[STATE_STIGMATA][1] > 0
            @cc.status[STATE_STIGMATA][1] = s
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          else
            set_state(@cc.status[STATE_STIGMATA], 1, s);
            on_buff_event(true, owner.current_chara_card_no, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0], @cc.status[STATE_STIGMATA][1])
          end
        end
      end
    end
    regist_event UseAngerBackFeatEvent

    # 静謐な背中が使用される
    def finish_anger_back_feat()
      if @feats_enable[FEAT_ANGER_BACK]
        use_feat_event(@feats[FEAT_ANGER_BACK])
      end
    end
    regist_event FinishAngerBackFeatEvent

    # 静謐な背中が使用される(ダメージ時)
    # 有効の場合必殺技IDを返す
    def use_anger_back_feat_damage()
      if @feats_enable[FEAT_ANGER_BACK]
        if @cc.status[STATE_STIGMATA][1] > 0
          damage_bonus = Feat.pow(@feats[FEAT_ANGER_BACK])
          duel.tmp_damage += @cc.status[STATE_STIGMATA][1] + damage_bonus
          @cc.status[STATE_STIGMATA][1] -= 1
          @cc.status[STATE_STIGMATA][1] = 0 if @cc.status[STATE_STIGMATA][1] < 0
          update_buff_event(true, STATE_STIGMATA, @cc.status[STATE_STIGMATA][0])
        end
        @feats_enable[FEAT_ANGER_BACK] = false
      end
    end
    regist_event UseAngerBackFeatDamageEvent



    # ===========================================
    # トラップ用イベント等
    # ===========================================
    TRAP_KEEP_TURN = 3                            # 罠の有効ターン

    TRAP_STATUS_KIND = "kind"                     # 罠のステータス。種類
    TRAP_STATUS_TURN = "turn"                     # 罠のステータス。残ターン
    TRAP_STATUS_DISTANCE = "distance"             # 罠のステータス。位置
    TRAP_STATUS_VISIBILITY = "visibility"         # 罠のステータス。可視性
    TRAP_STATUS_POW = "pow"                       # 罠のステータス。威力
    TRAP_STATUS_STATE = "state"                   # 罠のステータス。ステート

    TRAP_STATE_WAIT = "wait"                      # 罠のステート。待機状態
    TRAP_STATE_READY = "ready"                    # 罠のステート。有効状態

    STABLE_TRAP_KINDS = [FEAT_BATAFLY_SLD]
    INSTANT_TRAP_KINDS = [FEAT_BATAFLY_ATK, FEAT_BATAFLY_DEF, FEAT_BATAFLY_MOV, FEAT_CLAYMORE]
    TRAP_KINDS = STABLE_TRAP_KINDS + INSTANT_TRAP_KINDS

    # 起動可能なトラップを起動する(各フェイズの後
    def open_trap_check
      if @cc.using && @cc.index == owner.current_chara_card_no

        # 常設型
        STABLE_TRAP_KINDS.each do |kind|
          case kind
          when FEAT_BATAFLY_SLD
            if check_trap_state(owner, FEAT_BATAFLY_SLD, owner.distance, TRAP_STATE_READY)
              if !owner.invincible
                owner.trap_action_event(kind, owner.distance)
                open_trap(kind, owner.trap[kind.to_s])
              end
            else
              owner.invincible=(false)
            end
          end
        end

        # 揮発型
        INSTANT_TRAP_KINDS.each do |kind|
          if owner.trap.key?(kind.to_s)
            if check_trap_state(owner, kind, owner.distance, TRAP_STATE_READY)
              owner.trap_update_event(kind, owner.distance, 0, false)
              owner.trap_action_event(kind, owner.distance)
              open_trap(kind, owner.trap[kind.to_s])
            end
          end
        end

        # 場に残っており、有効状態のものを最通知する
        owner.trap.each do |kind, status|
          if status[TRAP_STATUS_TURN] > 0 && status[TRAP_STATUS_STATE] == TRAP_STATE_READY
            owner.trap_update_event(kind.to_i, status[TRAP_STATUS_DISTANCE], status[TRAP_STATUS_TURN], status[TRAP_STATUS_VISIBILITY])
          end
        end
      end
    end
    regist_event CheckStartedTrapDetBpBeforeEvent
    regist_event CheckStartedTrapDetBpEvent
    regist_event CheckStartedTrapBattleResultEvent
    regist_event CheckStartedTrapDamageEvent
    regist_event CheckStartedTrapFinishMoveEvent
    regist_event CheckStartedTrapDetChangeEvent

    # トラップの状態を進行する。残ターンをデクリメント、待機状態から有効状態へ
    def progress_trap
      if @cc.using && @cc.index == owner.current_chara_card_no
        @trap_updated = false
        trap = owner.trap
        return if trap.size == 0

        delete_list = []
        trap.each do |kind, status|

          trap["#{kind}"][TRAP_STATUS_TURN] -= 1

          # ターンを進める。規定ターン経過したものは消す
          if status[TRAP_STATUS_TURN] < 1
            delete_list << kind
          end

          if status[TRAP_STATUS_STATE] == TRAP_STATE_WAIT
            trap["#{kind}"][TRAP_STATUS_STATE] = TRAP_STATE_READY
          end

          owner.trap_update_event(kind.to_i, trap["#{kind}"][TRAP_STATUS_DISTANCE], trap["#{kind}"][TRAP_STATUS_TURN], trap["#{kind}"][TRAP_STATUS_VISIBILITY])
        end

        delete_list.each do |kind|
          trap.delete(kind)
        end

        owner.invincible=(false)
      end
    end
    regist_event ProgressTrapEvent

    # 距離にトラップを仕掛ける
    def set_trap(target, kind, status)
      trap = target.trap
      # 既に出ているものがあれば引っ込める
      if status[TRAP_STATUS_STATE] == TRAP_STATE_WAIT && trap.key?(kind.to_s) && trap["#{kind}"][TRAP_STATUS_TURN] > 0
        target.trap_update_event(kind.to_i, trap["#{kind}"][TRAP_STATUS_DISTANCE], 0, trap["#{kind}"][TRAP_STATUS_VISIBILITY])
      end
      trap["#{kind}"] = status
    end

    # そのトラップがその状態でそこに存在するか
    def check_trap_state(target, kind, distance, state)
      trap = target.trap
      return (trap.key?(kind.to_s) && trap["#{kind}"][TRAP_STATUS_DISTANCE] == distance && trap["#{kind}"][TRAP_STATUS_TURN] > 0 && trap["#{kind}"][TRAP_STATUS_STATE] == state)
    end

    # トラップのステータスをセットする
    def set_trap_status(target, kind, status_name, state)
      target.trap["#{kind}"]["#{status_name}"] = state if target.trap.key?(kind.to_s)
    end

    def get_trap_status(target, kind, status_name)
      target.trap["#{kind}"]["#{status_name}"] if target.trap.key?(kind.to_s)
    end

    # 全てのトラップをクライアントに再送する
    def update_trap_all(target)
      trap = target.trap
      trap.each do |kind, status|
        target.trap_update_event(kind.to_i, trap["#{kind}"][TRAP_STATUS_DISTANCE], trap["#{kind}"][TRAP_STATUS_TURN], trap["#{kind}"][TRAP_STATUS_VISIBILITY])
      end
    end

    # トラップを起動
    def open_trap(kind, status)

      case kind.to_i
      when FEAT_BATAFLY_MOV
        buffed = foe.current_chara_card.set_state(@cc.status[STATE_SEAL], 1, status[TRAP_STATUS_POW]);
        foe.current_chara_card.on_buff_event(false, owner.current_chara_card_no, STATE_SEAL, @cc.status[STATE_SEAL][0], @cc.status[STATE_SEAL][1]) if buffed

      when FEAT_BATAFLY_ATK
        owner.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, owner, status[TRAP_STATUS_POW]))

      when FEAT_BATAFLY_DEF
        buffed = foe.current_chara_card.set_state(@cc.status[STATE_STONE], 1, 2);
        foe.current_chara_card.on_buff_event(false, owner.current_chara_card_no, STATE_STONE, @cc.status[STATE_STONE][0], @cc.status[STATE_STONE][1]) if buffed
        aca = owner.cards.shuffle
        status[TRAP_STATUS_POW].times{ |a| discard(owner, aca[a]) if aca[a] }

      when FEAT_BATAFLY_SLD
        owner.invincible=(true)

      when FEAT_CLAYMORE
        owner.damaged_event(attribute_damage(ATTRIBUTE_CONSTANT, owner, status[TRAP_STATUS_POW]))
        d = 0
        swd_num = foe.get_type_cards_count_both_faces(ActionCard::SWD)
        arw_num = foe.get_type_cards_count_both_faces(ActionCard::ARW)
        if swd_num > arw_num
          d = -1
        elsif swd_num < arw_num
          d = 1
        else
          d = [-1, 1].shuffle.pop
        end
        owner.move_action(d)
        foe.move_action(d)
        if d == -1
          foe.current_chara_card.use_trap_chase_feat_chain
        else
          foe.current_chara_card.use_panic_feat_chain
        end

      end

      close_trap(owner, kind) unless status[TRAP_STATUS_VISIBILITY]
    end

    # 罠を解除する
    def close_trap(target, kind)
      target.trap.delete(kind.to_s)
    end

    # 提出したカードの種類を距離に変換する。複数渡された場合はランダム。
    def batafly_feat_type_to_distance(types)
      return 0 if types.size == 0

      case types[rand(types.size)]
      when ActionCard::SWD
        return 1
      when ActionCard::ARW
        return 3
      else
        return 2
      end
    end


    # ===========================================
    # 必殺技の汎用イベント
    # ===========================================
    # 必殺技が使用されたときのイベント
    COFFIN_ID=1264
    GREGOR_FEAT_BEGIN=1255
    GREGOR_FEAT_END=1267
    def use_feat(id)
      unless @used_feats[id]
        @cc.owner.duel_bonus_event(DUEL_BONUS_FEAT,@used_feats.size+1) if @cc&&@cc.owner&&origin_feat?(id)
        @used_feats[id] = true
      end

      if @cc.charactor_id == GREGOR
        case id
        when GREGOR_FEAT_BEGIN .. GREGOR_FEAT_END
        else
          off_feat_event(Feat[id].feat_no)
          return use_feat(COFFIN_ID)
        end
      end

      id
    end
    regist_event UseFeatEvent

    # キャクター本来の技か否か
    def origin_feat?(feat_id)
      @cc.feat_inventories.each do |fi|
        return true if fi.feat_id == feat_id
      end
      false
    end

    def use_passive(id)
      id
    end
    regist_event UsePassiveEvent

    # カレントキャラカードを強制的に更新する。変身用。
    def change_chara_card(id)
      id
    end
    regist_event ChangeCharaCardEvent

    # 必殺技が実際に使用できるようになったときのイベント
    # 返値:必殺技の固有ID
    def on_feat(type)
      # ポイントに変化があったか再計算
      @feats[type]
    end
    regist_event OnFeatEvent

    # 強打がオフになったときのイベント
    # 返値:必殺技の固有ID
    def off_feat(type)
      # ポイントに変化があったか再計算
      @feats[type]
    end
    regist_event OffFeatEvent

    # 技名を書き換える
    def change_feat(chara_index, feat_index, feat_id, feat_no)
      [chara_index, feat_index, feat_id, feat_no]
    end
    regist_event ChangeFeatEvent

    # クライアントの技ラベルの点灯を全てリセットする
    def off_feat_all()
      @feats.each_key do |f_no|
        off_feat_event(f_no)
      end
    end

    # ===========================================
    # 特殊イベント
    # ===========================================
    TRANSFORM_TYPE_STANDARD=0
    TRANSFORM_TYPE_CAT=1
    # キャラカード変身イベント,トラップがあれば更新する
    def on_transform_sequence(player, type=TRANSFORM_TYPE_STANDARD)
      on_transform_event(player,type)
      target = player ? owner : foe
      update_trap_all(target)
    end

    def off_transform_sequence(player)
      target = player ? owner : foe
      off_transform_status_reset(target)
      off_transform_event(player)
      update_trap_all(target)
    end

    def on_transform(player, type=TRANSFORM_TYPE_STANDARD)
      if player
        owner.is_transforming = true
      else
        foe.is_transforming = true
      end
      [player, type]
    end
    regist_event OnTransformEvent

    def off_transform(player)
      if player
        owner.is_transforming = false
      else
        foe.is_transforming = false
      end
      player
    end
    regist_event OffTransformEvent

    # 強制解除を前提に、付随するステータスはここでリセットする
    def off_transform_status_reset(target)
      target.current_chara_card.special_status[SPECIAL_STATE_CAT][1] = 0
    end

    def off_field_effect(player)
      target = player ? owner : foe
      target.field_status.each_with_index { |val, i|
        if val[1] > 0
          case i
          when Entrant::FIELD_STATUS["FOG"]
            off_lost_in_the_fog_event(player)
            target.set_field_status_event(i, val[0], 0)
          when Entrant::FIELD_STATUS["AC_LOCK"]
            owner.clear_card_locks_event
            foe.clear_card_locks_event
            target.set_field_status_event(i, val[0], 0)
          end
        end
      }
    end

    # 霧で隠す
    def on_lost_in_the_fog(player)
      target = player ? owner : foe
      target.hiding_was_finished = false
      [player, 4, owner.distance]
    end
    regist_event OnLostInTheFogEvent

    # 霧でから出す
    def off_lost_in_the_fog(player)
      target = player ? owner : foe
      target.hiding_was_finished = true
      [player, owner.distance]
    end
    regist_event OffLostInTheFogEvent

    # 霧を照らす
    def in_the_fog(player, range)
      if @target_range != range
        @target_range = range
        [player, range.join(",")]
      else
        [player, nil]
      end
    end
    regist_event InTheFogEvent

    # クライアントの発動条件を更新する
    def update_feat_condition(player, chara_index, feat_index, condition)
      [player, chara_index, feat_index, Feat.sign_to_string(condition)]
    end
    regist_event UpdateFeatConditionEvent

    def owner
      @cc.owner
    end

    def foe
      @cc.foe
    end

    def duel
      @cc.duel
    end

    def deck
      duel.deck
    end

    def move_feat_forbidden?(feat_no)
      ret = false
      if owner.current_chara_card.status[STATE_DOLL][1] > 0
        ret = get_feats_list_as_for(owner, PHASE_MOVE).include?(feat_no)
      end
      ret
    end

    # 条件付きで発動する技のチェックスキップ判定
    def skip_check_feat(feat_no)
      # 移動技禁止状態のチェック
      if move_feat_forbidden?(feat_no)
        return true
      end

      case feat_no
      when FEAT_CARAPACE_SPIN
        # パッシブ中でない場合
        ! @passives_enable[PASSIVE_CARAPACE]

      when FEAT_ASIA
        # ターンがPOWの倍数でないとき
        duel.turn % Feat.pow(@feats[FEAT_ASIA]) != 0

      when FEAT_SMILE
        # 相手が女性ではない
        ! Charactor.attribute(foe.current_chara_card.charactor_id).include?("female")

      when FEAT_COLD_EYES
        # 相手が男性ではない
        ! Charactor.attribute(foe.current_chara_card.charactor_id).include?("male")

      when FEAT_INVERT
        # hpが1/2以上
        owner.current_chara_card.hp <= owner.hit_point * 2

      when FEAT_ONE_ACT
        # 銃しか出していない場合
        types = owner.get_table_card_types
        types.delete(ActionCard::DEF)
        types.size != 1

      when FEAT_FOX_ZONE
        # 銃を出してない場合
        types = owner.get_table_card_types
        !types.include?(ActionCard::ARW)

      when FEAT_SCRATCH_FIRE
        # 剣を出していない場合
        types = owner.get_table_card_types
        !types.include?(ActionCard::SWD)

      when FEAT_BLUE_RUIN
        # 銃を出していない場合
        types = owner.get_table_card_types
        !types.include?(ActionCard::ARW)

      when FEAT_KEEPER
        # 特を出していない場合
        types = owner.get_table_card_types
        !types.include?(ActionCard::SPC)

      when FEAT_THREE_CARD
        # 同色3枚が無い場合
        ret = true
        (ActionCard::SWD..ActionCard::SPC).each do |type|
          if owner.get_type_point_table_count(type, 1, true) > 2 || owner.get_type_point_table_count(type, 2, true) > 2
            ret = false
            break
          end
        end
        ret

      end
    end

    # 必殺技のON_OFFのイベントをおくる
    def check_feat(feat_no)
      # 現在OC使用中の場合のみチェックする
      if @cc.using
        # 条件付きで発動する技のチェックスキップ判定
        if skip_check_feat(feat_no)
          off_feat_event(feat_no)
          @feats_enable[feat_no] = false
          return
        end
        # 条件関数と封印状態をチェックする
        if check_feat_core(@feats[feat_no],@cc.owner,@check_feat_range_free) && @cc.status[STATE_SEAL][1] <= 0 && @cc.special_status[SPECIAL_STATE_CAT][1] <= 0
          unless  @feats_enable[feat_no]
            @feats_enable[feat_no] = true
            on_feat_event(feat_no)
          end
        else
          # OFFの場合有効カードをリセットする
          @cc.owner.reset_feat_on_cards(feat_no)
          if  @feats_enable[feat_no]
            @feats_enable[feat_no] = false
            off_feat_event(feat_no)
          end
        end
      else
        @cc.owner.reset_feat_on_cards(feat_no)
      end

      if @check_feat_range_free
        # 有効範囲を決定する
        phase = owner.initiative ? PHASE_ATTACK : PHASE_DEFENSE
        range = get_feats_range(owner, phase)
        in_the_fog_event(true, range) if range.length > 0
      end
    end

    # 使用中の技のレンジを取得する。phaseで絞込み
    def get_feats_range(entrant, phase)
      target = entrant ? owner : foe
      range = []
      now_on_feats = target.current_chara_card.get_enable_feats(phase)
      now_on_feats.each do |key, value|
        fid = @feats[key]
        tmp_range = Feat.send("ai_dist_condition_f#{fid}")
        range += tmp_range
      end

      range.uniq!
      range.sort! if range.length > 0
      range
    end

    # テーブルのACを元に、ハイド状態の相手への対応範囲を決定する
    def get_battle_table_range(entrant)
      target = entrant ? owner : foe
      range = []
      if target.initiative
        swd_pt = target.get_battle_table_point(ActionCard::SWD)
        arw_pt = target.get_battle_table_point(ActionCard::ARW)
        if swd_pt+arw_pt > 0
          range = swd_pt >= arw_pt ? AI_RANGE_SWORD : AI_RANGE_ARROW
        end
      else
        if target.get_battle_table_point(ActionCard::DEF) > 0
          range = AI_RANGE_ALL
        else
          range = AI_RANGE_NOTHING
        end
      end

      range
    end

    # FeatへのCondition問い合わせ, range_freeで距離を無視
    def check_feat_core(fid, target, range_free=false)
      Feat.check_feat(fid, target, range_free)
    end

    # 現在有効状態にある技 引数はフェイズによる絞込み
    def get_enable_feats(phase=nil, target=owner)
      ret = { }
      if phase.nil?
        ret = @feats_enable.select { |k, v| v == true }
      else
        feats = get_feats_list_as_for(target, phase)
        ret = @feats_enable.select { |k, v| v == true && feats.include?(k)}
      end
      ret
    end

    # 必殺技のON_OFFのイベントは送らず、可否のみチェック
    def check_feat_bg(feat_no)
      # 現在OC使用中の場合のみチェックする
      if @cc.using
        # 条件関数と封印状態をチェックする
        if Feat.check_feat(@feats[feat_no],@cc.owner) && @cc.status[STATE_SEAL][1] <= 0 && !skip_check_feat(feat_no)
          unless  @feats_enable[feat_no]
            @feats_enable[feat_no] = true
          end
        else
          # OFFの場合有効カードをリセットする
          @cc.owner.reset_feat_on_cards(feat_no)
          if  @feats_enable[feat_no]
            @feats_enable[feat_no] = false
          end
        end
      else
        @cc.owner.reset_feat_on_cards(feat_no)
      end
    end

    # パッシブの可否チェック 特別な事情で発動出来ない場合をここに記述
    def check_passive(passive_no)
      ret = !@passives_enable[passive_no] && @cc.special_status[SPECIAL_STATE_CAT][1] <= 0
      ret
    end

    # パッシブの可否チェック 発動可能ならそのままONにする
    def check_and_on_passive(passive_no)
      if check_passive(passive_no)
        @passives_enable[passive_no] = true
        on_passive_event(true, passive_no)
      end
    end

    # パッシブを発動する 細かい事情は無視してON。装備由来のスキル等で使う
    def force_on_passive(passive_no)
      @passives_enable[passive_no] = true
      on_passive_event(true, passive_no)
    end

    # パッシブを切る
    def force_off_passive(passive_no)
      @passives_enable[passive_no] = false
      off_passive_event(true, passive_no)
    end

    # ステータス状態を設定する
    def set_state(state, power, turn)
      if state
        r = rand(100)+1
        return false if state[2] > r
        state[0] = power
        state[0] = 9 if power > 9
        state[1] = turn
        state[1] = 9 if turn > 9
        return true
      end
    end

    # RAIDコントローラが使う。確立判定しない
    def set_state_raid(state, power, turn)
      if state
        state[0] = power
        state[0] = 9 if power > 9
        state[1] = turn
        state[1] = 9 if turn > 9
      end
    end

    # RAIDコントローラが使う。状態異常の終了処理
    def finish_state_proc(kind)
      case kind
      when STATE_DEAD_COUNT
        foe.current_chara_card.foe.damaged_event(attribute_damage(ATTRIBUTE_DEATH, owner))
      end
    end

    # 生存者のインデックスを配列で返す カレントインデックスを除外するか
    def get_hps(entrant, except_current=false)
      hps = []
      entrant.hit_points.each_with_index do |v,i|
        next if except_current && entrant.current_chara_card_no == i
        hps << i if v > 0
      end
      hps
    end

    # 使用が終わったか
    def use_end?
      !@cc.using if @cc
    end

    # 発動中のステータス取得
    def get_active_status
      ret = nil
      @cc.status.each_with_index do |s,i|
        if s[1] > 0
          ret = { } unless ret
          ret[i] = s
        end
      end
      ret
    end

    # 炎の聖女の変身
    def transform_of_fire
      owner.cured_event()
      owner.chara_change_force = true
      owner.chara_change_index = owner.current_chara_card_no
      owner.current_chara_card.remove_event
      owner.change_current_chara_card(20011)
      change_chara_card_event(20011)
      duel.init_chara_card(owner.current_chara_card, owner, foe, owner.current_chara_card_no)
      use_passive_event(@passives[PASSIVE_CREATOR])
    end

    # 相手のカードcを奪う
    def steal_deal(c)
      if foe.cards.size > 0 && !(owner.field_status[Entrant::FIELD_STATUS["AC_LOCK"]][1] > 0 || (foe.field_status[Entrant::FIELD_STATUS["AC_LOCK"]][1] > 0))
        @cc.owner.steal_dealed_event([foe.cards.delete(c)])
        1
      else
        0
      end
    end

    # entrantのカードcを破棄
    def discard(entrant, c)
      if entrant.cards.size > 0 && !(owner.field_status[Entrant::FIELD_STATUS["AC_LOCK"]][1] > 0 || (foe.field_status[Entrant::FIELD_STATUS["AC_LOCK"]][1] > 0))
        entrant.discard_event(c)
        1
      else
        0
      end
    end

    # 属性を登録する
    def regist_dice_attribute()
      dice_attribute_list = []
      now_on_feats = get_enable_feats
      # ON状態の技を取得して、その技ごとに属性をとりたい
      now_on_feats.each do |key, val|
        da = Feat.dice_attribute(@feats[key])
        da.each do |a|
          dice_attribute_list << a if !dice_attribute_list.include?(a)
        end
      end
      dice_attribute_list
    end

    EX_FEATS={ FEAT_RAZORS_EDGE=>FEAT_EX_RAZORS_EDGE }
    # 技の提出条件緩和する 数値2以上を必要とするタイプについて、必要条件-1
    def easing_card_condition(f_no, pow=-1)
      if EX_FEATS.key?(f_no) && @feats.key?(EX_FEATS[f_no])
        f_no = EX_FEATS[f_no]
      elsif !@feats.key?(f_no)
        return
      end

      f_id = @feats[f_no]
      @easing_feat_list = { } unless @easing_feat_list
      unless @easing_feat_list.has_key?(f_id)
        # 無ければ登録
        eased_condition = easing_condition_all_type(Feat[f_id].condition, pow)
        condition_check = Feat.condition_check_gen(eased_condition).gsub("__FEAT__", f_no.to_s)
        update_feat_condition_event(true, owner.current_chara_card_no, get_feat_inventories_index(f_id), eased_condition)
        @easing_feat_list[f_id] = {:f_no => f_no, :pow => pow, :condition => condition_check}
      end

      create_easing_check_feat(f_id, f_no)
    end


    # 条件緩和用特異メソッド定義
    def create_easing_check_feat(f_id, f_no)
      unless self.singleton_class.instance_methods(false).include?(:feat_check_core)
        def self.check_feat_core(f_id, target, range_free)
          ret = false
          if @easing_feat_list.has_key?(f_id)
            ret = instance_eval(@easing_feat_list[f_id][:condition])
          else
            ret = Feat.check_feat(f_id, target, range_free)
          end
          ret
        end
      end
    end

    # その技がfeat_invの中で何番目かを返す
    def get_feat_inventories_index(feat_id)
      ret = 0
      @feats.each do |no, id|
        break if id == feat_id
        ret += 1
      end
      ret
    end


    # 既定条件の値をnumだけ変動させた技条件文字列を返す
    COND_PTN = /([ASDMEW]|\[.*\])(\d?)([+=-]?)(?:\*(\d))?/
    REDUCTION_TYPE_PRIORITY = ["D", "M", "S", "A", "E", "W"]
    def easing_condition_all_type(condition, num=-1)
      return "" if condition == ""

      dist_cond, ac_cond = condition.split(":")

      # 既定の技のコンディションを文字列から解釈
      ac_cond_list = { }
      ac_cond.split(",").each_with_index do |c_str, i|
        ma = c_str.match(COND_PTN)
        ac_cond_list[i] = {
          :type_sign => ma[1],
          :value => ma[2].to_i,
          :op => ma[3],
          :num => ma[4]
        }
      end

      # 条件変動
      result = []

      # 全てのタイプの必要数が1or0の場合はタイプを1種減らす
      if ac_cond_list.select { |i, cond| cond[:value] > 1 }.size == 0

        REDUCTION_TYPE_PRIORITY.each do |t|
          if ac_cond_list.select { |i, cond| cond[:type_sign] == t }.size > 0
            ac_cond_list.each do |i, cond|
              if cond[:type_sign] == t
                ac_cond_list.delete(i)
                break
              end
            end
            break
          end
        end

      else

        # 2以上の数値は減算対象
        ac_cond_list.each do |i, cond|

          if (cond[:type_sign] != "W")
            if num < 0 && cond[:value] > 1
              cond[:value] += (cond[:op] == "-" ? -1*num : num)
              cond[:value] = 1 if cond[:value] < 1
              cond[:value] = 9 if cond[:value] > 9
            elsif cond[:value] == 0
            end
          end

        end
      end
      ac_cond = ac_cond_list.collect { |i, cond|
        if (cond[:type_sign] == "W" && cond[:num])
          ((cond[:type_sign] + "1+,") * cond[:num].to_i).chop
        else
          cond[:type_sign].to_s + cond[:value].to_s + cond[:op].to_s
        end
      }.join(",")
      ret = dist_cond + ":" + ac_cond
      ret
    end

  end
end
