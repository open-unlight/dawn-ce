# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # カードのインベントリクラス
  class ScenarioInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :scenario # キャラカードを複数もてる

    plugin :validation_class_methods
    plugin :hook_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end
  end
end
