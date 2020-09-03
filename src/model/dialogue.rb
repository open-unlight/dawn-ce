# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 台詞を保存するクラス
  class Dialogue < Sequel::Model

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :content,:text=>true, :default => ""
      datetime    :created_at
      datetime    :updated_at


    end

    # バリデーションの設定
    #    include Validation
     validates do
     end

   # DBにテーブルをつくる
    if !(Dialogue.table_exists?)
      Dialogue.create_table
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
      Unlight::Dialogue::refresh_data_version
    end

    # 全体データバージョンを返す
    def Dialogue::data_version
      ret = cache_store.get("DialogueVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("DialogueVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def Dialogue::refresh_data_version
      m = Unlight::Dialogue.order(:updated_at).last
      if m
        cache_store.set("DialogueVersion",m.version)
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
