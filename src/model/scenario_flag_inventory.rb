# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # シナリオフラグインベントリクラス
  class ScenarioFlagInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :avatar # デッキに複数所持される
    many_to_one :scenario # キャラカードを複数もてる

    plugin :validation_class_methods
    plugin :hook_class_methods

    # バリデーションの設定
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

    def set_flag(key, value)
      if @flag_hash || self.get_flag
        unless @flag_hash[key] == value
          @flag_hash[key] = value
          self.flags = @flag_hash.to_s
        end
     end
    end

    def get_flag
      @flag_hash = eval(self.flags || '{}')
    end
  end
end
