# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # クジのログ
  class LotLog < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :player # アバターを持つ
    many_to_one :rare_card_lot, key: :geted_lot_no # アバターを持つ

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

    def self.create_log(p_id, l_type, l_no)
      LotLog.new do |i|
        i.player_id = p_id
        i.lot_type = l_type
        i.geted_lot_no = l_no
        i.description = "[#{i.rare_card_lot.article_kind}:#{i.rare_card_lot.article_id}]" + i.rare_card_lot.description
        d = "[#{i.rare_card_lot.article_kind}:#{i.rare_card_lot.article_id}]" + i.rare_card_lot.description
        t = Time.now.utc
        LotLog.dataset.insert(player_id: p_id, lot_type: l_type, geted_lot_no: l_no, description: d, created_at: t, updated_at: t)
      end
    end

    # リミットずつのログをもらう(1ページスタート)
    def self.get_page(a_id, page); end
  end
end
