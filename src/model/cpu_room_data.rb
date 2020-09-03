# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 管理用のCPUルームデータクラス
  class CpuRoomData < Sequel::Model(:cpu_room_datas)
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
      String      :name, :default => ""
      integer     :level, :default => 0
      integer     :cpu_card_data_no, :default => 0
      integer     :rule, :default => 0

      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(CpuRoomData.table_exists?)
      CpuRoomData.create_table
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
      Unlight::CpuRoomData::refresh_data_version
      Unlight::CpuRoomData::cache_store.delete("cpu_room_data:restricrt:#{id}")
    end

    # 全体データバージョンを返す
    def CpuRoomData::data_version
      ret = cache_store.get("CpuRoomDataVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("CpuRoomDataVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CpuRoomData::refresh_data_version
      m = Unlight::CpuRoomData.order(:updated_at).last
      if m
        cache_store.set("CpuRoomDataVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # CPUカードデータをかえす
    def cpu_card_data_id
      if self.cpu_card_data_no != ""
        self.cpu_card_data_no
      else
        101
      end
    end

  end
end
