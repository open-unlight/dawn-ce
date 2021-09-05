# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # パッシブクラス
  class PassiveSkill < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
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
      Unlight::PassiveSkill.refresh_data_version
    end

    # 全体データバージョンを返す
    def self.data_version
      ret = cache_store.get('PassiveSkillVersion')
      unless ret
        ret = refresh_data_version
        cache_store.set('PassiveSkillVersion', ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def self.refresh_data_version
      m = Unlight::PassiveSkill.order(:updated_at).last
      if m
        cache_store.set('PassiveSkillVersion', m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      updated_at.to_i % MODEL_CACHE_INT
    end

    # 条件節の初期化
    def self.initialize_condition_method
      @@pow_set = []
      PassiveSkill.all.each do |f|
        # POWを作る
        @@pow_set[f.id] = f.pow
      end
    end

    # 実際のPOWを返す
    def self.pow(id)
      @@pow_set[id]
    end

    # caption文を返す
    def replaced_caption
      pow.to_s && caption ? caption.gsub('__POW__', pow.to_s).gsub('__NAME__', name.delete('+')) : caption
    end

    def get_data_csv_str
      ret = ''
      ret << id.to_s.force_encoding('UTF-8') << ','
      ret << passive_skill_no.to_s.force_encoding('UTF-8') << ','
      ret << '"' << (name || '').force_encoding('UTF-8') << '",'
      ret << '"' << (replaced_caption || '').force_encoding('UTF-8') << '",'
      ret << '"' << (effect_image || '').force_encoding('UTF-8') << '"'
      ret
    end

    # 読み込み時に初期化する
    initialize_condition_method
  end
end
