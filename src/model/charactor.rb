# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # キャラクター本体のデータ
  class Charactor < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    def Charactor::initialize_charactor_param
      @@chara_attribute_set = []
      Charactor.all.each do |c|
        @@chara_attribute_set[c.id] = c.chara_attribute if c.chara_attribute
      end
    end

    def Charactor::attribute(id)
      @@chara_attribute_set[id].split(',') if @@chara_attribute_set[id]
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # データをとる
    def get_data_csv_str()
      ret = ''
      ret << self.id.to_s << ','
      ret << '"' << (self.name || '') << '",'
      ret << '"' << (self.lobby_image || '') << '",'
      ret << '"' << (self.chara_voice || '') << '",'
      ret << (self.parent_id || 0).to_s
      ret
    end

    initialize_charactor_param
  end
end
