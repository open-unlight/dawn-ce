# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # クジのログ
  class LotLog < Sequel::Model

    # 他クラスのアソシエーション
    many_to_one :player         # アバターを持つ
    many_to_one :rare_card_lot,:key=>:geted_lot_no  # アバターを持つ

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      int         :player_id
      int         :lot_type
      String      :description
      int         :geted_lot_no
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる
    if !(LotLog.table_exists?)
      LotLog.create_table
    end


    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def LotLog::create_log(p_id, l_type, l_no)
      LotLog.new do |i|
        i.player_id = p_id
        i.lot_type = l_type
        i.geted_lot_no = l_no
        i.description = "[#{i.rare_card_lot.article_kind}:#{i.rare_card_lot.article_id}]"+i.rare_card_lot.description
        d = "[#{i.rare_card_lot.article_kind}:#{i.rare_card_lot.article_id}]"+i.rare_card_lot.description
        t = Time.now.utc
        LotLog.dataset.insert(:player_id=>p_id,:lot_type=>l_type, :geted_lot_no=>l_no, :description=>d, :created_at=>t, :updated_at=>t)
        end
    end

    # リミットずつのログをもらう(1ページスタート)
    def LotLog::get_page(a_id,page)
    end
  end
end
