# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUカードデータクラス
  class RewardData < Sequel::Model(:reward_datas)
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
      integer     :exps,               :default => 0
      integer     :gems,               :default => 0
      integer     :item_id,            :default => 0
      integer     :item_num,           :default => 0
      integer     :own_card_lv,        :default => 0
      integer     :own_card_num,       :default => 0
      integer     :random_card_rarity, :default => 0
      integer     :random_card_num,    :default => 0
      integer     :rare_card_lv,       :default => 0
      integer     :event_card_id,      :default => 0
      integer     :event_card_num,     :default => 0
      integer     :weapon_card_id,     :default => 0
      integer     :weapon_card_num,    :default => 0


      datetime    :created_at
      datetime    :updated_at

    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(RewardData.table_exists?)
      RewardData.create_table
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
      Unlight::RewardData::refresh_data_version
      Unlight::RewardData::cache_store.delete("cpu_card_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def RewardData::data_version
      ret = cache_store.get("RewardDataVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("RewardDataVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def RewardData::refresh_data_version
      m = Unlight::RewardData.order(:updated_at).last
      if m
        cache_store.set("RewardDataVersion", m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end
  end
end
