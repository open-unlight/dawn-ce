# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # ショップクラス
  class Shop < Sequel::Model
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
      integer     :shop_type       # ショップのタイプ
      integer     :article_kind, :index=>true    # 売り物の種類(0:AvatarItem,1:AvatarParts,2:EventCard)
      integer     :article_id      # 販売物のID
      integer     :price, :default => 0           # 値段
      integer     :coin_0, :default => 0          # コイン価格0
      integer     :coin_1, :default => 0          # コイン価格1
      integer     :coin_2, :default => 0          # コイン価格2
      integer     :coin_3, :default => 0          # コイン価格3
      integer     :coin_4, :default => 0          # コイン価格4
      integer     :coin_ex, :default => 0         # コイン価格ex
      integer     :view_frame, :default => 0      # 表示フレーム
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(Shop.table_exists?)
      Shop.create_table
    end

    # テーブルの変更（履歴を残す）
    DB.alter_table :shops do
      add_column :coin_ex, :integer, :default => 0 unless Unlight::Shop.columns.include?(:coin_ex)  # 新規追加2012/05
      add_column :view_frame, :integer, :default => 0 unless Unlight::Shop.columns.include?(:view_frame)  # 新規追加2012/06/20
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end
  end

  # 特定のショップのアイテムIDリストをもらえる
  def Shop::get_sale_list(shop)
    ret = cache_store.get("shop_type:#{shop}")
    unless ret
      ret = []
      Shop.filter({:shop_type=>shop}).all.each do |s|
        ret << [s.article_kind, s.article_id, s.price, s.coin_0, s.coin_1, s.coin_2, s.coin_3, s.coin_4, s.coin_ex]
      end
      cache_store.set("shop_type:#{shop}",ret)
    end
    ret
  end

  def Shop::check_gems_coins_num(item,gems,coins,amount)
    ret = false
    if (item[2]*amount) <= gems && (item[3]*amount) <= coins[0].count && (item[4]*amount) <= coins[1].count && (item[5]*amount) <= coins[2].count && (item[6]*amount) <= coins[3].count && (item[7]*amount) <= coins[4].count && (item[8]*amount) <= coins[5].count
      ret = true
    end
    ret
  end

  # 商品を買う(種類とIDを指定して、ジェムと使用コインを渡す。返値は変えなかったらfalse, 買えたら残りのGems)
  def Shop::buy_article(shop, kind, id, gems, coins, amount=1)
    ret = [false,[]]
    # リストにあるなら買えるかつ、渡したGemより値段が安ければ買える
    get_sale_list(shop).each do |a|
      if a[0] == kind && a[1]==id && check_gems_coins_num(a,gems,coins,amount)
        ret = [gems - a[2]*amount, [a[3]*amount,a[4]*amount,a[5]*amount,a[6]*amount,a[7]*amount,a[8]*amount]]
      end
    end
    ret
  end

  # 特定ショップのキャッシュをクリア
  def Shop::refresh_cache(shop)
    cache_store.delete("shop_type:#{shop}")
  end

  def Shop::get_sale_list_str(type = 0)
    ret = ""
    ret += "["
    ret += "#{type},"
    ret += "["
    Shop.filter({:shop_type=>type}).all.each do |s|
      ret += "["
      ret2 = []
      ret2 << [s.article_kind, s.article_id, s.price, s.coin_0, s.coin_1, s.coin_2, s.coin_3, s.coin_4, s.coin_ex, s.view_frame]
      ret +=ret2.join(",")
      ret += "],"
    end
    ret.chop!
    ret += "]"
    ret += "]"
  end
end
