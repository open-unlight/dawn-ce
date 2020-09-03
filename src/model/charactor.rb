# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight


  # キャラクター本体のデータ
  class Charactor < Sequel::Model

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name
      integer     :parent_id, :default => 0 # 新規追加 2014/10/9
      String      :chara_attribute, :default => ""
      String      :lobby_image, :default => "" # 新規追加 2013/12/11
      String      :chara_voice, :default => ""
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # DBにテーブルをつくる

    if !(Charactor.table_exists?)
      Charactor.create_table
    end

    def Charactor::initialize_charactor_param
      @@chara_attribute_set = []
      Charactor.all.each do |c|
        @@chara_attribute_set[c.id] = c.chara_attribute if c.chara_attribute
      end
    end

    def Charactor::attribute(id)
      @@chara_attribute_set[id].split(",") if @@chara_attribute_set[id]
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    DB.alter_table :charactors do
      add_column :parent_id, :integer, :default => 0 unless Unlight::Charactor.columns.include?(:parent_id)  # 新規追加 2014/10/9
      add_column :lobby_image, String, :default => "" unless Unlight::Charactor.columns.include?(:lobby_image)  # 新規追加 2013/12/11
      add_column :chara_attribute, String, :default => "" unless Unlight::Charactor.columns.include?(:chara_attribute)  # 新規追加 2013/12/11
      add_column :chara_voice, String, :default => "" unless Unlight::Charactor.columns.include?(:chara_voice)  # 新規追加 2014/8/13
    end

    # データをとる
    def get_data_csv_str()
      ret = ""
      ret << self.id.to_s << ","
      ret << '"' << (self.name||"")<< '",'
      ret << '"' << (self.lobby_image||"")<< '",'
      ret << '"' << (self.chara_voice||"")<< '",'
      ret << (self.parent_id||0).to_s
      ret
    end

    initialize_charactor_param
  end

end
