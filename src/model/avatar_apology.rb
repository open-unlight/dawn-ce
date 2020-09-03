# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # お詫び用データ
  class AvatarApology < Sequel::Model

    # 他クラスのアソシエーション
    one_to_one :avatar         # アバターと一対一

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :avatar_id,:index=>true #, :table => :avatars
      String      :body, :text=>true, :default => ""
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる

    if !(AvatarApology.table_exists?) #テーブルをリセットするときにコメントアウト
      AvatarApology.create_table
    end

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
      s = self.body.split("|")
      if n
        n.times do
          ret.push(s.pop)
        end
        self.body = s.join("|").force_encoding("UTF-8")
        self.save_changes
      end
      ret
    end

    # 内容全てをクリア
    def all_clear_body
      refresh
      self.body = "".force_encoding("UTF-8")
      self.save_changes
    end

    # 内容を取得
    def get_body
      refresh
      ret = { }
      self.body.split("|").each do |str|
        if str != ""
          date_str,item_str = str.split("_")
          y,m,d = date_str.split("-")
          date = Time.new(y,m,d)
          set_items = []
          item_str.split("+").each do |i|
            set_items.push([])
            i.split("/").each do |j|
              set_items.last.push(j.to_i)
            end
          end
          ret[date] = { :date=>date_str.gsub("-","/"), :items=>set_items}
        end
      end
      ret.sort
    end


  end
end
