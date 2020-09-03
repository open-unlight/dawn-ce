# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 合成武器カードのインベントリクラス
  class CombineWeaponCardInventory < Sequel::Model
    # 他クラスのアソシエーション

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :combine_cnt, :default => 0
      integer     :combine_max, :default => 10
      integer     :base_sap,    :default => 0
      integer     :base_sdp,    :default => 0
      integer     :base_aap,    :default => 0
      integer     :base_adp,    :default => 0
      float       :add_sap,     :default => 0.0
      float       :add_sdp,     :default => 0.0
      float       :add_aap,     :default => 0.0
      float       :add_adp,     :default => 0.0
      integer     :card_cost,   :default => 0
      String      :passive_id,  :default => ""
      String      :restriction, :default => ""
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(CombineWeaponCardInventory.table_exists?)
      CombineWeaponCardInventory.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def CombineWeaponCardInventory::create_data(base_sap,base_sdp,base_aap,base_adp,sap,sdp,aap,adp,cost,passive_id="",restriction="")
      ret = CombineWeaponCardInventory.new do |d|
        d.combine_cnt = 1
        d.base_sap = base_sap
        d.base_sdp = base_sdp
        d.base_aap = base_aap
        d.base_adp = base_adp
        d.add_sap = sap
        d.add_sdp = sdp
        d.add_aap = aap
        d.add_adp = adp
        d.card_cost = cost
        d.passive_id = passive_id
        d.restriction = restriction
        d.save
      end
      SERVER_LOG.info("CombineWeaponCardInventory: [#{__method__}] create id:#{ret.id}")
      ret
    end

    def CombineWeaponCardInventory::combine(base_id,base_type,material_id_list)
      ret = nil
      base = nil
      if base_type == COMBINE_WEAPON_TYPE_COMBINE
        base = CombineWeaponCardInventory[base_id]
        return ret if base.combine_cnt >= base.combine_max
      else
        base = WeaponCard[base_id]
      end

      use_materials = { }
      material_num = material_id_list.size
      material_id_list.each do |set|
        m = nil
        if set[:type] == COMBINE_WEAPON_TYPE_COMBINE
          m = CombineWeaponCardInventory[set[:id]]
        else
          m = WeaponCard[set[:id]]
        end
        use_materials[set[:id]] = { :mat => m, :num => set[:num] }
      end

      # ここで特定の組み合わせをチェック
      ret = nil

      # 特定の組み合わせがない場合の処理
      add_params = []
      use_materials.each do |id,data|
        mat = data[:mat]
        num = data[:num]
        sap = mat.combine_sword_ap.to_f / 10 * num
        sdp = mat.combine_sword_dp.to_f / 10 * num
        aap = mat.combine_arrow_ap.to_f / 10 * num
        adp = mat.combine_arrow_dp.to_f / 10 * num
        param = { :sap => sap, :sdp => sdp, :aap => aap, :adp => adp, :special => false, :passive_id => mat.passive_id, :restriction => mat.restriction }
        add_params << param
      end

      set_param = { :sap => 0.0, :sdp => 0.0, :aap => 0.0, :adp => 0.0, :passive_id => [], :restriction => [] }
      add_params.each do |p|
        if p[:special]
          set_param[:sap] *= p[:sap]
          set_param[:sdp] *= p[:sdp]
          set_param[:aap] *= p[:aap]
          set_param[:adp] *= p[:adp]
        else
          set_param[:sap] += p[:sap]
          set_param[:sdp] += p[:sdp]
          set_param[:aap] += p[:aap]
          set_param[:adp] += p[:adp]
        end
        set_param[:passive_id].concat(p[:passive_id].split("|")) if p[:passive_id]&&p[:passive_id] != ""
        set_param[:restriction].concat(p[:restriction].split("|")) if p[:restriction]&&p[:restriction] != ""
      end

      set_param[:passive_id].concat(base.passive_id.split("|")) if base.passive_id&&base.passive_id != ""
      set_param[:restriction].concat(base.restriction.split("|")) if base.restriction&&base.restriction != ""
      passives = set_param[:passive_id].sort
      restrictions = set_param[:restriction].sort
      passives.uniq!
      restrictions.uniq!

      if base_type == COMBINE_WEAPON_TYPE_COMBINE
        ret = base.update_data((base.sword_ap+set_param[:sap]).round(2),
                               (base.sword_dp+set_param[:sdp]).round(2),
                               (base.arrow_ap+set_param[:aap]).round(2),
                               (base.arrow_dp+set_param[:adp]).round(2),
                               base.sword_ap+base.sword_dp+base.arrow_ap+base.arrow_dp,
                               passives.join("|"),
                               restrictions.join("|"))
      else
        ret = create_data(base.sword_ap,
                          base.sword_dp,
                          base.arrow_ap,
                          base.arrow_dp,
                          set_param[:sap],
                          set_param[:sdp],
                          set_param[:aap],
                          set_param[:adp],
                          base.sword_ap+base.sword_dp+base.arrow_ap+base.arrow_dp,
                          passives.join("|"),
                          restrictions.join("|"))
      end
      SERVER_LOG.info("<UID:#{}>CombineWeaponCardInventory [#{__method__}] ret:#{ret} ret id:#{ret.id}")
      { :type=>COMBINE_WEAPON_TYPE_COMBINE,:data=>ret}
    end

    def update_data(sap,sdp,aap,adp,cost,image,passive_id="",restriction="")
      data = CombineWeaponCardInventory[id]
      if data
        data.add_sap     = sap
        data.add_sdp     = sdp
        data.add_aap     = aap
        data.add_adp     = adp
        data.card_cost   = cost
        data.passive_id  = passive_id
        data.restriction = restriction
        data.combine_cnt += 1
        data.save_changes
      end
      data
    end


    # 近距離攻撃力
    def sword_ap(ai=:none)
      ret = self.base_sap
      if ai!=:none
        ret += self.add_sap.floor
      end
      ret
    end
    # 近距離ダイス攻撃力増加
    def sword_dice_bonus(ai=:none)
      0
    end
    # 近距離防御力
    def sword_dp(ai=:none)
      ret = self.base_sdp
      if ai!=:none
        ret += self.add_sdp.floor
      end
      ret
    end
    # 近距離ダイス防御力増加
    def sword_deffence_dice_bonus(ai=:none)
      0
    end

    # 遠距離攻撃力
    def arrow_ap(ai=:none)
      ret = self.base_aap
      if ai!=:none
        ret += self.add_aap.floor
      end
      ret
    end
    # 遠距離ダイス増加
    def arrow_dice_bonus(ai=:none)
      0
    end
    # 遠距離防御力
    def arrow_dp(ai=:none)
      ret = self.base_adp
      if ai!=:none
        ret += self.add_adp.floor
      end
      ret
    end
    # 遠距離ダイス防御力増加
    def arrow_deffence_dice_bonus(ai=:none)
      0
    end

    # パッシブIDを返す
    def get_passive_id(ai=:none)
      ret = []
      if ai != :none
        ret = self.passive_id.split("|") if self.passive_id
        ret.map!{ |p| p.to_i}
      end
      ret
    end

    # 近距離攻撃力
    def combine_sword_ap
      self.add_sap
    end
    # 近距離防御力
    def combine_sword_dp
      self.add_sdp
    end

    # 遠距離攻撃力
    def combine_arrow_ap
      self.add_aap
    end
    # 遠距離防御力
    def combine_arrow_dp
      self.add_adp
    end


  end

end
