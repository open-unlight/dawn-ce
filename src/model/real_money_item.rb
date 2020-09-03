# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class RealMoneyItem < Sequel::Model
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
      String      :name, :default => "real_money_item"
      float     :price, :default => 0
      integer     :rm_item_type, :default => 0
      integer     :item_id, :default => 0
      integer     :num, :default => 0
      integer     :order, :default => 0
      integer     :state, :default => 0
      String      :image_url, :default => ""
      integer     :tab, :default => 0
      String      :description, :default => ""
      integer     :extra_id, :default => 0 #セット販売アイテムRealMoneyItem.ID
      integer     :view_frame, :default => 0
      integer     :sale_type, :default => 0 # セールタイプ 0:初心者,1:10%,2:15%,3:20%,4:30%,5:40%,6:Event
      String      :deck_image_url, :default => ""
      float     :twd, :default => 0
      float     :hkd, :default => 0
      float     :usd, :default => 0
      float     :eur, :default => 0
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(RealMoneyItem.table_exists?)
      RealMoneyItem.create_table
    end

    DB.alter_table :real_money_items do
       add_column :extra_id, :integer, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:extra_id) #new 2012/06/06
       add_column :view_frame, :integer, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:view_frame) #new 2012/06/20
       add_column :sale_type, :integer, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:sale_type) #new 2012/10/22
       add_column :deck_image_url, String, :default => ""  unless Unlight::RealMoneyItem.columns.include?(:deck_image_url) #new 2012/11/21
       add_column :twd, :float, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:twd) #new 2012/06/06
       add_column :hkd, :float, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:hkd) #new 2012/06/06
       add_column :usd, :float, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:usd) #new 2012/06/06
       add_column :eur, :float, :default => 0  unless Unlight::RealMoneyItem.columns.include?(:eur) #new 2012/06/06
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

    # 特定のショップのアイテムIDリストをもらえる
    def RealMoneyItem::get_sale_list
      ret = cache_store.get("real_mone_item_sale_list:")
      unless ret
        ret = []
        ids = []
        names = []
        prices = []
        item_types = []
        item_ids = []
        nums = []
        orders = []
        states = []
        image_urls = []
        tabs = []
        descs = []
        frames = []
        extra_ids = []
        sale_types = []
        deck_image_urls = []
        RealMoneyItem.all.each do |s|
          ids << s.id
          names << s.name
          prices << s.price
          item_types << s.rm_item_type
          item_ids << s.item_id
          nums << s.num
          orders << s.order
          states << s.state
          image_urls << s.image_url
          tabs << s.tab
          descs << s.description
          frames << s.view_frame
          extra_ids << s.extra_id
          sale_types << s.sale_type
          deck_image_urls << s.deck_image_url
        end
        ret << RealMoneyItem.all.size
        ret  << [ids, names, prices, item_types, item_ids, nums, orders, states, image_urls, tabs, descs, frames, extra_ids, sale_types, deck_image_urls]
        cache_store.set("real_mone_item_sale_list:",ret)
      end
      ret
    end

  end
end
