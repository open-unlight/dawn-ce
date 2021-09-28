# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # お詫び用データ
  class AvatarApology < Sequel::Model
    # 他クラスのアソシエーション
    one_to_one :avatar # アバターと一対一

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # 内容をクリア
    def clear_body(n)
      refresh
      ret = []
      s = body.split('|')
      if n
        n.times do
          ret.push(s.pop)
        end
        self.body = s.join('|').force_encoding('UTF-8')
        save_changes
      end
      ret
    end

    # 内容全てをクリア
    def all_clear_body
      refresh
      self.body = ''.force_encoding('UTF-8')
      save_changes
    end

    # 内容を取得
    def get_body
      refresh
      ret = {}
      body.split('|').each do |str|
        if str != ''
          date_str, item_str = str.split('_')
          y, m, d = date_str.split('-')
          date = Time.new(y, m, d)
          set_items = []
          item_str.split('+').each do |i|
            set_items.push([])
            i.split('/').each do |j|
              set_items.last.push(j.to_i)
            end
          end
          ret[date] = { date: date_str.tr('-', '/'), items: set_items }
        end
      end
      ret.sort
    end
  end
end
