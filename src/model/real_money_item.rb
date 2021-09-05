# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class RealMoneyItem < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
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
    def self.get_sale_list
      ret = cache_store.get('real_mone_item_sale_list:')
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
        ret << [ids, names, prices, item_types, item_ids, nums, orders, states, image_urls, tabs, descs, frames, extra_ids, sale_types, deck_image_urls]
        cache_store.set('real_mone_item_sale_list:', ret)
      end
      ret
    end
  end
end
