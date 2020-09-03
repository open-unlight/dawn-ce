# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 必要カードの必要カード情報を構成するクラス
  class CharaCardRequirement < Sequel::Model

    many_to_one :chara_card        # プレイヤーに複数所持される

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :chara_card_id, :index=>true#, :table => :chara_cards,:key=>:id, :deferrable=>true
      integer :require_chara_card_id#, :table => :chara_cards, :key=>:id, :deferrable=>true
      integer     :require_num
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(CharaCardRequirement.table_exists?)
      CharaCardRequirement.create_table
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


  def CharaCardRequirement::up_tree(cc_id)
    ret = []
    cc = CharaCard[cc_id]
    # モンスターとキャラで分ける
    if cc && (cc.kind == CC_KIND_MONSTAR)
      ret = [COIN_SET[cc.level], EX_COIN_RATE, COIN_GOLD_ID, EX_COIN_GOLD_RATE, COIN_PLATINUM_ID, EX_COIN_PLATINUM_RATE]
    elsif
      CharaCardRequirement.filter({:require_chara_card_id=>cc_id}).all.each do |r|
        ret << r.chara_card_id
        ret << r.require_num
        end
    end
    # ケイオシウム変換
    if cc && cc.kind == CC_KIND_CHARA  && cc.rarity > 5
      ret << EX_TIPS_CARD_ID
      ret << EX_TIPS_RATE
    end
      ret
  end



  def CharaCardRequirement::down_tree(cc_id)
    ret = []
    if CharaCard[cc_id]
      CharaCardRequirement.filter({ :chara_card_id=> cc_id}).all.each do |r|
        ret << r.require_chara_card_id
        ret << r.require_num
      end
    end
    ret
  end

    def CharaCardRequirement::exchange(cc_id, list, c_id)
      ret = []
      cc = CharaCard[cc_id]
      cc2 =CharaCard[c_id]
      if cc
        req = []
        down_req = { }
        # モンスターカードで処理をわける
        if cc.kind == CC_KIND_COIN
          case cc_id
          when COIN_IRON_ID..COIN_SILVER_ID
            down_req[c_id] = EX_COIN_RATE
          when COIN_GOLD_ID
            down_req[c_id] = EX_COIN_GOLD_RATE
          when COIN_PLATINUM_ID
            CharaCard.filter({ :charactor_id=> cc2.charactor_id}).limit(3).each do |c|
              down_req[c.id] = EX_COIN_PLATINUM_RATE
            end
          end
        elsif cc_id == EX_TIPS_CARD_ID && cc2.kind == CC_KIND_CHARA && cc2.rarity > 5
          down_req[c_id] = EX_TIPS_RATE
        else
          CharaCardRequirement.filter({ :chara_card_id=> cc_id}).all.each do |r|
            down_req[r.require_chara_card_id] = r.require_num
          end
        end
        down_req.each do |k,v|
          if list[k]
            req << (list[k].size >= v)
          end
        end
        if req.length > 0
          ret[0] = not(req.include?(false))
        else
          ret[0] = false
        end
        ret[1] = down_req
      end
      ret==[]? [false]:ret
    end

    # 全体データバージョンを返す
    def CharaCardRequirement::data_version
      ret = cache_store.get("CharaCardRequirementVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("CharaCardRequirementVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CharaCardRequirement::refresh_data_versions
      m = CharaCardRequirement.order(:updated_at).last
      if m
        cache_store.set("CharaCardRequirementVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT if self
    end

end
