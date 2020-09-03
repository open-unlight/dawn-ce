# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # クエストの１場所クラス
  class QuestLand < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :default => ""
      integer     :monstar_no, :default => 0
      integer     :treasure_no, :default => 0
      integer     :event_no, :default => 0
      integer     :stage, :default => 0
      String      :caption, :default => ""
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

    # DBにテーブルをつくる
    if !(QuestLand.table_exists?)
      QuestLand.create_table
    end

    # 全体データバージョンを返す
    def QuestLand::data_version
      ret = cache_store.get("QuestLandVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("QuestLandVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def QuestLand::refresh_data_version
      m = QuestLand.order(:updated_at).last
      if m
        cache_store.set("QuestLandVersion", m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # マップから見えるエネミー番号
    def enemy_chara_card_no
      if  CPU_CHARA_CARDS[self.monstar_no]
        CPU_CHARA_CARDS[self.monstar_no].first
      else
        0000
      end
    end

    # 宝箱のタイプを返す
    def treasure_genre
      ret = self.treasure_no
      if ret>0
         t = TreasureData[ret]
        if t
          ret = t.treasure_type
        end
      end
      ret
    end

    # 宝箱のタイプを返す
    def treasure_bonus_level
      ret = self.treasure_no
      if ret>0
         t = TreasureData[ret]
        if t
          ret = t.value
        end
      end
      ret
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

   def get_data_csv_str
     ret = ""
     ret << self.id.to_s << ","
     ret << '"' << (self.name||"") << '",'
     ret << (self.monstar_no||0).to_s<< ","
     ret << (self.treasure_genre||0).to_s << ","
     ret << (self.event_no||0).to_s << ","
     ret << (self.stage||0).to_s << ","
     ret << '"' << (self.caption||"")<< '"'
     ret
   end
  end
end
