# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class ClearCode < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema
    STATE_UNUSE = 0           # 未使用
    STATE_USED  = 1           # 使用済み

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :code,:index=>true, :unique=>true
      integer     :kind, :default => 0
      integer     :state, :default => 0
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(ClearCode.table_exists?)
      ClearCode.create_table
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
    end

    # 済んだかどうか
    def done?
      self.state>0
    end

    # 済んだ
    def self::get_code(kind, max)
      ret = ""
      if self::filter(:kind =>kind,:state=>STATE_USED).count > max
        return ret
      else
        ccs = self::filter(:kind =>kind,:state=>STATE_UNUSE).all
        if ccs.size>0
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
