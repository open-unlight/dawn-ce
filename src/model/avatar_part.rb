# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # アバターパーツクラス
  class AvatarPart < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name
      String      :image, :text=>true, :default => ""

      integer     :parts_type,:default => 0

      integer     :power_type,:default => 0             # 装備したときの効果                     #new 2011/06/30
      integer     :power,:default => 0                  # 効果の力                               #new 2011/06/30
      integer     :duration, :default =>0               # 効果の持続時間（0の場合ずっと続く    ）#new 2011/06/30
      String      :caption, :text=>true, :default => "" # キャプション                           #new 2011/06/30

      integer     :color,:default => 0                  # イメージに適用するカラー
      integer     :offset_x, :default => 0              # アイコンのオフセット（未使用）
      integer     :offset_y, :default => 0              # アイコンのオフセット（未使用）
      integer     :offset_scale, :default => 100        # アイコンのオフセット（未使用）
      datetime    :created_at
      datetime    :updated_at

    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # DBにテーブルをつくる
    if !(AvatarPart.table_exists?)
      AvatarPart.create_table
    end

    # テーブルを変更する（履歴を残せ）
    DB.alter_table :avatar_parts do
    end

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
      Unlight::AvatarPart::refresh_data_version
    end

    # 全体データバージョンを返す
    def AvatarPart::data_version
      ret = cache_store.get("AvatarPartVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("AvatarPartVersion", ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def AvatarPart::refresh_data_version
      m = Unlight::AvatarPart.order(:updated_at).last
      if m
        cache_store.set("AvatarPartVersion", m.version)
      end
      if m
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # パラメータをCSVのデータで返す
    def get_data_csv_str
      ret = ""
      ret << self.id.to_s << ","
      ret << '"' << (self.name||"") << '",'
      ret << '"' << (self.image_extract||"")<< '",'
      ret << (self.parts_type||0).to_s<< ","
      ret << (self.color||0).to_s << ","
      ret << (self.offset_x||0).to_s << ","
      ret << (self.offset_y||0).to_s << ","
      ret << (self.offset_scale||0).to_s << ","
      ret << (self.power_type||0).to_s << ","
      ret << (self.power||0).to_s << ","
      ret << (self.duration||0).to_s << ","
      ret << '"' << (self.trans_caption||"")<< '"'
      ret
    end


    def image_extract
      self.image.gsub(/\+dummy_.{1,3}/,"")
    end

    # パーツを装備する
    def attach(a)
      @avatar = a
      if PART_EFFECTS[self.power_type]
        self.send(PART_EFFECTS[self.power_type],self.power, true)
      end
    end

    # パーツを装備から外す
    def detach(a)
      @avatar = a
      if PART_EFFECTS[self.power_type]
        self.send(PART_EFFECTS[self.power_type], self.power, false)
      end
      @avatar = nil
    end

    # パラメータの変更点をまとめて返す
    def self::all_params_check(parts_set)
      ret = { }
      ret[:recovery_interval=] = Unlight::AVATAR_RECOVERY_SEC
      ret[:quest_inventory_max=] = Unlight::QUEST_MAX
      ret[:exp_pow=] = 100
      ret[:gem_pow=] = 100
      ret[:quest_find_pow=] = 100

      parts_set.each do |part|
        case part.power_type
        when PART_EFFECTS.index(:shorten_recovery_time)
          ret[:recovery_interval=]-=(part.power*60)
          # もし60秒よりみじかかったら60秒
          ret[:recovery_interval=] = 60 if ret[:recovery_interval=] < 60
        when PART_EFFECTS.index(:increase_quest_inventory_max)
          ret[:quest_inventory_max=]+=part.power
        when PART_EFFECTS.index(:multiply_exp_pow)
          ret[:exp_pow=]+=part.power
        when PART_EFFECTS.index(:multiply_gem_pow)
          ret[:gem_pow=]+=part.power
        when PART_EFFECTS.index(:shorten_quest_find_time)
          ret[:quest_find_pow=]-=part.power
        end
      end
      ret
    end

    # アイテムの効果、使用関数
    PART_EFFECTS =[
                   nil,
                   :shorten_recovery_time,        # AP回復時間短縮           1 POWは秒数
                   :increase_quest_inventory_max, # クエストインベントリ増加 2
                   :multiply_exp_pow,             # EXP増加                  3
                   :multiply_gem_pow,             # GEM増加                  4
                   :shorten_quest_find_time,      # クエストゲット時間短縮
                  ]

    # AP回復時間を短くする
    def shorten_recovery_time(v, attached = true)
      if @avatar
        num = attached ? (-1*v) : v
        @avatar.recovery_interval += num*60
        @avatar.recovery_interval  = Unlight::AVATAR_RECOVERY_SEC  if @avatar.recovery_interval > Unlight::AVATAR_RECOVERY_SEC # 元のMAXより多かったらMAX
        @avatar.recovery_interval = 60 if @avatar.recovery_interval < 60
        @avatar.save_changes
        @avatar.energy_recovery_check(true) # 現在リカバリーが発生するかのチェック
        @avatar.update_recovery_interval_event if @avatar.event
      end
    end

    # クエストの探索数のMAX数を増やす
    def increase_quest_inventory_max(v, attached = true)
      if @avatar
        num = attached ? v:(-1*v)
        @avatar.quest_inventory_max += num
        @avatar.save_changes
        @avatar.update_quest_inventory_max_event if @avatar.event
      end
    end

    # EXPの倍率を増やす
    def multiply_exp_pow(v, attached = true)
      if @avatar
        num = attached ? v:(-1*v)
        @avatar.exp_pow += num
        @avatar.save_changes
        @avatar.update_exp_pow_event if @avatar.event
      end
    end

    # GEMの倍率を増やす
    def multiply_gem_pow(v, attached = true)
      if @avatar
        num = attached ? v:(-1*v)
        @avatar.gem_pow += num
        @avatar.save_changes
        @avatar.update_gem_pow_event if @avatar.event
      end
    end

    # クエスト時間をゲット時間を短縮
    def shorten_quest_find_time(v, attached = true)
      if @avatar
        num = attached ? (-1*v) : v
        @avatar.quest_find_pow += num
        @avatar.quest_find_pow  = 100  if @avatar.quest_find_pow > 100 # 元のMAXより多かったらMAX
        @avatar.save_changes
        @avatar.update_quest_find_pow_event if @avatar.event
      end
    end

    def trans_caption
      if self.caption
        self.caption.gsub("__POW__",self.power.to_s)
      else
        ""
      end
    end
  end
end
