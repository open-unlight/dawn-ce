# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # イベントカードクラス
  class EventCard < Sequel::Model
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
      integer     :event_no
      integer     :card_cost, :default => 0
      integer     :color, :default => 0
      integer     :max_in_deck, :default => 0
      String      :restriction, :default => ""
      String      :image, :default => ""
      String      :caption, :default => ""
      Boolean     :filler, :default =>false
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(EventCard.table_exists?)
      EventCard.create_table
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
      Unlight::EventCard::refresh_data_version
      Unlight::EventCard::cache_store.delete("event_card:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def EventCard::data_version
      ret = cache_store.get("EventCardVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("EventCardVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def EventCard::refresh_data_version
      m = Unlight::EventCard.order(:updated_at).last
      if m
        cache_store.set("EventCardVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # キャラで使えるかチェック
    def check_using_chara(chara_no)
      ret = true
      if restriction_charas.size>0
        ret = restriction_charas.include?(chara_no)
      end
      ret
    end

    # キャラ制限のリストを返す
    def restriction_charas
      ret = EventCard::cache_store.get("event_card:restricrt:#{id}")
      unless ret
        ret = []
        ret = self.restriction.split("|") if self.restriction
        EventCard::cache_store.set("event_card:restricrt:#{id}", ret)
      end
      ret
    end

    # キャラで使えるかチェック
    def check_using_color(color_no)
      ret = true
      unless color_no == 0
        ret = self.color == color
      end
      ret
    end

    # ランダムで埋め草カードを返す
   def self::get_random_filler_card()
      @@filler_cards[rand(@@filler_cards.size)]
    end

    def self::initialize_event_card()
      @@filler_cards = EventCard.filter(:filler =>true).all
      @@filler_cards << EventCard[1] if @@filler_cards.size == 0
    end

    initialize_event_card
  end
end
