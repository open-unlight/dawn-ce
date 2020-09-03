# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 1000000が基数
  puts "OLD_LOT IS  #{OLD_LOT}"
  if OLD_LOT
  LOT_REALITY=[
               1000000,        # Reality 1 32%     99
               679287,         # Reality 2 26%     66
               415285,         # Reality 3 17%     40
               236395,         # Reality 4 12%     23
               115177,         # Reality 5  6%     11
               47563,          # Reality 6  3%     5
               16517,          # Reality 7  1%     2 <-使わない
               4783,           # Reality 8  0.3%   1 <-使わない
               1132,           # Reality 9  0.1%
               197,            # Reality 10 0.02%
              ]
  else
    LOT_REALITY=[
               1000000,        # Reality 1 3%      100
                970000,        # Reality 2 5%      97
                920000,        # Reality 3 15%     92
                770000,        # Reality 4 30%     77
                470000,        # Reality 5  6%     47
                0,             # Reality 6  3%     5
                0,             # Reality 7  1%     2 <-使わない
                0,             # Reality 8  0.3%   1 <-使わない
                0,             # Reality 9  0.1%
                0,             # Reality 10 0.02%
              ]
  end

  LOT_REALITY_NUM = 1000000
  LOT_PERCENT = [
                 (LOT_REALITY[0]-LOT_REALITY[1])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[1]-LOT_REALITY[2])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[2]-LOT_REALITY[3])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[3]-LOT_REALITY[4])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[4]-LOT_REALITY[5])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[5]-LOT_REALITY[6])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[6]-LOT_REALITY[7])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[7]-LOT_REALITY[8])/LOT_REALITY_NUM.to_f,
                 (LOT_REALITY[8]-LOT_REALITY[9])/LOT_REALITY_NUM.to_f,
                 LOT_REALITY[9]/LOT_REALITY_NUM.to_f
                ]

  PERCENT_CASH = "percent_cash_#{File.dirname(__FILE__).gsub!("/","_")}"

  @@percent = Array.new(10,0)

  # ショップクラス
  class RareCardLot < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :lot_kind,    :default => 0, :index=>true  # クジの種類
      integer     :article_kind,:default => 0  # 渡す物の種類(0:AvatarItem,1:AvatarParts,2:EventCard)
      integer     :article_id                  # 渡すモノの種類
      integer     :order,       :default => 0  # カードの順番
      integer     :rarity,      :default => 0  # 出る確率
      integer     :visible,     :default => 0  # 見えるかどうか1以上で消す
      integer     :num,         :default => 1  # 個数
      String      :image_url,   :default => "" # 画像URL
      String      :description, :default => "" # 解説
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    plugin :validation_helpers
    def validate
      err1 =check_article(lot_kind, article_kind, article_id, id)
      err2 =check_order(self)
      errors.add(*err1) if err1
      errors.add(*err2) if err2
    end

    # 同じlot_kind内に同じarticle_kind/article_idがない
    def check_article(lk, a_k, a_i,id)
      ret = false
      Unlight::RareCardLot::get_lot_list(lk).each do |r|
        if r.article_kind == a_k && r.article_id == a_i && r.id != id
          ret = [:article_kind, "error article no ,id:#{r.id}"]
          puts "errr"
          break
        end
      end
      ret
    end

    # 同じlot_kind内に同じarticle_kind/article_idがない
    def check_order(r)
      ret = false
      r_str = r.rarity.to_s
      o_str = r.order.to_s[0]
      ret = [:order, "error order no, id:#{r.id}"] if r_str != o_str
      puts "errr #{r},#{r_str},#{o_str}" if ret
      ret
    end

    # DBにテーブルをつくる
    if !(RareCardLot.table_exists?)
      RareCardLot.create_table
    end

    DB.alter_table :rare_card_lots do
      add_column :num, :integer, :default => 1 unless Unlight::RareCardLot.columns.include?(:num)  # 新規追加2012/09/12
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # 特定クジの商品リストを返す
    def RareCardLot::get_lot_list(kind)
      ret  = false
      unless ret
        ret = []
        RareCardLot.filter({:lot_kind=>kind}).all.each do |s|
          ret << s
        end
      end
      ret
    end

    # レアリティを決定する
    def RareCardLot::get_realty()
      r = rand(LOT_REALITY_NUM)
      ret = 1
      if LOT_REALITY
        LOT_REALITY.each_index do |i|
          if LOT_REALITY[i] > r
            ret = i+1
          else
            break
          end
        end
      end
      ret
    end

    # 特定種類の 特定リアティのカードを返す
    def RareCardLot::get_card_in_reality(k, r)
      RareCardLot.filter({:rarity=>r, :lot_kind=>k}).all
    end



    # レアカードクジを引く
    def RareCardLot::draw_lot(k)
      r = RareCardLot::get_realty
      s = 0

      until s>0
        q = RareCardLot.get_card_in_reality(k, r)
        s = q.count if q
        r-=1
        break if r==0
      end
      ret = q[rand(q.count)] if q
      if ret
        ret
      else
        RareCardLot[1]
      end
    end

    # 特定ショップのキャッシュをクリア
    def RareCardLot::refresh_cache(k)
    end

    # 確率を返す
    def percent
      unless @@rarity
        RareCardLot::initialize_percent
      end
      rarity_set =   @@rarity

      unless rarity_set[self.lot_kind]&&rarity_set[self.lot_kind][self.rarity-1]
        return 0
      end
      (rarity_set[self.lot_kind][self.rarity-1]*100).round(1)
    end

    # 全体分の確率を保存する
    def RareCardLot::initialize_percent
      @@rarity = Array.new(10){ |i| Array.new(10,0)}
      rare_num = Array.new(10){ |i| Array.new(10,0)}

      RareCardLot.all.each do |rc|
        rc.refresh
        if rc.lot_kind && rc.rarity
          if rare_num[rc.lot_kind]&&rare_num[rc.lot_kind][rc.rarity-1]
            rare_num[rc.lot_kind][rc.rarity-1] +=1
          end
        end
      end
      rare_num.each_index do |r|
        rem = 0
        (rare_num[r].size-1).downto(0) do |i|
          if rare_num[r][i]== 0
            j = i-1 <0 ? 0 : i-1
            rem += (LOT_PERCENT[i])
          else
            @@rarity[r][i]+=(LOT_PERCENT[i])+rem
            rem =0
            @@rarity[r][i] = (@@rarity[r][i]/rare_num[r][i]).to_f
          end
        end
      end
      CACHE.set(PERCENT_CASH, @@rarity)
    end

    def RareCardLot::get_percent(lot_kind, rarity)
      r = CACHE.get(PERCENT_CASH)
      unless r
        puts "cache とるの失敗。#{PERCENT_CASH}更新します"
        RareCardLot::initialize_percent
        r = CACHE.get(PERCENT_CASH)
      end
      (r[lot_kind][rarity-1]*100).round(1)
    end

    initialize_percent
  end
end
