# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 必要カードの必要カード情報を構成するクラス
  class CharaCardStory < Sequel::Model

    many_to_one:chara_card        # プレイヤーに複数所持される

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true, :ttl=>1200 # 10分だけキャッシュする･･･
    # スキーマの設定
    set_schema do
      primary_key :id
      integer :chara_card_id#, :table => :chara_cards
      integer     :book_type
      String      :title, :text=>true, :default => ""
      String      :content, :text=>true, :default => ""
      String      :image, :default => ""
      String      :age_no, :default => ""
      integer     :text_id
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

    # DBにテーブルをつくる
    if !(CharaCardStory.table_exists?)
      CharaCardStory.create_table
    end

    DB.alter_table :chara_card_stories do
     add_column :age_no, String, :default => "" unless Unlight::CharaCardStory.columns.include?(:age_no)  # 新規追加 2012/06/14
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
      Unlight::CharaCardStory::refresh_data_version
    end

    # 全体データバージョンを返す
    def CharaCardStory::data_version
      ret = cache_store.get("CharaCardStoryVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("CharaCardStoryVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CharaCardStory::refresh_data_version
      m = Unlight::CharaCardStory.order(:updated_at).last
      if m
        cache_store.set("CharaCardStoryVersion",m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # データを並べた文字列を返す
    def self::get_data_str(data)
      ret = ""
      ret << data.id.to_s << ","
      ret << '"' << (data.title||"") << '",'
      ret << '"' << (data.age_no||"") << '"'
      ret
    end

    # キャラIDからストーリー情報の一部を文字列で返す
    def self::get_data_csv_str(id)
      ret = "["
      list = CharaCardStory.filter(:chara_card_id => id).order(:id).all
      list.each { |ccs|
        ret << CharaCardStory.get_data_str(ccs) << ","
      }
      if list.length > 0
        ret.gsub!("\n", '')
        ret.chop! if ret
      end
      ret << "]"
    end

  end


end
