# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class ClearCode < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    STATE_UNUSE = 0           # 未使用
    STATE_USED  = 1           # 使用済み

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # 済んだかどうか
    def done?
      state.positive?
    end

    # 済んだ
    def self.get_code(kind, max)
      ret = ''
      if filter(kind: kind, state: STATE_USED).count > max
        return ret
      else
        ccs = filter(kind: kind, state: STATE_UNUSE).all
        unless ccs.empty?
          cc =  ccs.first
          ret = cc.code
          cc.state = STATE_USED
          cc.save_changes
        end
      end

      ret
    end
  end
end
