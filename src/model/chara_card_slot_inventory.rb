# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  require 'inline'

  # カードのインベントリクラス
  class CharaCardSlotInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :chara_card_deck        # デッキに複数所持される

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    PARAM2_DEFAULT = 0B0010_0000_0000_0000_0010_1000_0000_0000
    puts "param2 default #{PARAM2_DEFAULT}"
    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :chara_card_deck_id, :index=>true
      integer     :deck_position
      integer     :card_position
      integer     :kind
      integer     :card_id
      integer     :weapon_type, :default => WEAPON_TYPE_NORMAL
      integer     :before_deck_id
      integer      :combine_param1, :default =>0 # base(+-127) 8_8_8_8 mons(+-127) 8_8_8_8  64 bit
      integer      :combine_param2, :default =>PARAM2_DEFAULT # base_max(0-15) 4 passiveA cnt(0-31)5 passiveAmax_cnt(0-31)5 add_max 9(0-511) passive A 9(0-511) 32 bit
      String      :combine_param1_str, :default =>"0" # base(+-127) 8_8_8_8 mons(+-127) 8_8_8_8  64 bit String
      integer     :level, :default => 1
      integer     :exp, :default => 0
      integer     :combine_param3, :default =>0 # base_max(0-15) 4 passiveB cnt(0-31)5 passiveB max_cnt(0-31)5 add_max 9(0-511) passive B 9(0-511) 32 bit
      datetime    :created_at
      datetime    :updated_at
    end

    # param 計算用マスク
    COMB_PARAM_MASK_BASE_SA     = [0B1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000, 56] # +-127
    COMB_PARAM_MASK_BASE_SD     = [0B0000_0000_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000, 48] # +-127
    COMB_PARAM_MASK_BASE_AA     = [0B0000_0000_0000_0000_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000, 40] # +-127
    COMB_PARAM_MASK_BASE_AD     = [0B0000_0000_0000_0000_0000_0000_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000, 32] # +-127
    COMB_PARAM_MASK_ADD_SA      = [0B0000_0000_0000_0000_0000_0000_0000_0000_1111_1111_0000_0000_0000_0000_0000_0000, 24] # +-127
    COMB_PARAM_MASK_ADD_SD      = [0B0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1111_1111_0000_0000_0000_0000, 16] # +-127
    COMB_PARAM_MASK_ADD_AA      = [0B0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1111_1111_0000_0000, 8]  # +-127
    COMB_PARAM_MASK_ADD_AD      = [0B0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_1111_1111, 0]  # +-127
    COMB_PARAM_MASK_BASE_MAX    = [0B1111_0000_0000_0000_0000_0000_0000_0000, 28] # 0-15 BASE_MAX default:3
    COMB_PARAM_MASK_CNT_A       = [0B0000_1111_1000_0000_0000_0000_0000_0000, 23] # 0-31
    COMB_PARAM_MASK_CNT_A_MAX   = [0B0000_0000_0111_1100_0000_0000_0000_0000, 18] # 0-31
    COMB_PARAM_MASK_ADD_MAX     = [0B0000_0000_0000_0011_1111_1110_0000_0000, 9]  # 0-511 ADD_MAX defalt:20
    COMB_PARAM_MASK_PASS_A      = [0B0000_0000_0000_0000_0000_0001_1111_1111, 0]  # 0-511
    COMB_PARAM_MASK_PSV_NUM_MAX = [0B1111_0000_0000_0000_0000_0000_0000_0000, 28] # 0-15 PASSIVE_NUM default:0
    COMB_PARAM_MASK_CNT_B       = [0B0000_1111_1000_0000_0000_0000_0000_0000, 23] # 0-31
    COMB_PARAM_MASK_CNT_B_MAX   = [0B0000_0000_0111_1100_0000_0000_0000_0000, 18] # 0-31
    COMB_PARAM_MASK_PASS_B      = [0B0000_0000_0000_0000_0000_0001_1111_1111, 0]  # 0-511

    # パラメータ上限
    COMB_BASE_PARAM_MAX = 9
    COMB_BASE_PARAM_MIN = -2
    COMB_ADD_PARAM_UPPER_MAX = 20
    COMB_ADD_PARAM_ZERO_MAX  = 10
    COMB_ADD_PARAM_LOWER_MAX = 5
    COMB_ADD_PARAM_MIN = 0
    COMB_LEVEL_MAX = 20
    COMB_ADD_PARAM_REST_SET = 5 # 専用化されている場合の加算パラメータ

    # 回数限定パッシブ設定のセット
    COMB_PASSIVE_SET = [#id, cost, count
                        [43 ,0, 5],  # 0
                        [44 ,0, 5],  # 1
                        [45 ,0, 5],  # 2
                        [46 ,0, 5],  # 3
                        [47 ,0, 5],  # 4
                        [48 ,0, 5],  # 5
                        [49 ,0, 5],  # 6
                        [50 ,0, 5],  # 7
                        [51 ,0, 5],  # 8
                        [120,0, 5],  # 9 岩石割り*1.5
                        [121,0, 5],  # 10 岩石割り*2.0
                        [122,0, 5],  # 11 岩石割り*3.0
                        [129,0, 5],  # 12 ポイ*1.5
                        [130,0, 5],  # 13 ポイ*2.0
                        [131,0, 5],  # 14 ポイ*3.0
                       ]

    # BASE値の合計で基本コストは決まる
    COMB_BASE_COST_RULE = [3,   # 0-3:0
                           6,   # 4-6:1
                           9,   # 7-9+:2
                          ]

    # 合成レベルでのパッシブ枠解禁セット
    COMB_PASSIVE_RELEASE_LEVEL_RULE = [2,   # 0-2:0

                                       29,  # 10-29:1
                                      ]     # 19-:3

    # 汎用武器のパラメータ仕様
    COMB_NORMAL_TYPE_PARAM_ID_RULE = {
      :base_sap  => { 0=>9005,:base_sdp => 9000,:base_aap => 9002,:base_adp => 9005},
      :base_sdp  => { 0=>9003,:base_aap => 9004,:base_adp => 9003},
      :base_aap  => { 0=>9004,:base_adp => 9001},
      :base_adp  => { 0=>9003},
    }

    # 経験値移譲時調整係数
    COMB_SEND_EXP_COEFFICIENT = 2

    validates do
    end

    # DBにテーブルをつくる
    if !(CharaCardSlotInventory.table_exists?)
      CharaCardSlotInventory.create_table
    end

    DB.alter_table :chara_card_slot_inventories do
      add_column :weapon_type, :integer, :default => WEAPON_TYPE_NORMAL unless Unlight::CharaCardSlotInventory.columns.include?(:weapon_type) # 新規追加2015/04/09
      add_column :before_deck_id, :integer, :default => 0 unless Unlight::CharaCardSlotInventory.columns.include?(:before_deck_id)  # 新規追加2015/04/18
      add_column :combine_param1, :bignum, :default =>0 unless Unlight::CharaCardSlotInventory.columns.include?(:combine_param1)  # 新規追加2015/04/20
      add_column :combine_param2, :int, :default =>0 unless Unlight::CharaCardSlotInventory.columns.include?(:combine_param2)  # 新規追加2015/04/20
      add_column :combine_param1_str, String, :default =>0 unless Unlight::CharaCardSlotInventory.columns.include?(:combine_param1_str)  # 新規追加2015/06/25
      add_column :level, :integer, :default =>1 unless Unlight::CharaCardSlotInventory.columns.include?(:level)  # 新規追加2015/06/25
      add_column :exp, :integer, :default =>0 unless Unlight::CharaCardSlotInventory.columns.include?(:exp)  # 新規追加2015/06/25
      add_column :combine_param3, :int, :default =>0 unless Unlight::CharaCardSlotInventory.columns.include?(:combine_param3)  # 新規追加2015/04/20
    end

    # インサート時の前処理
    before_create do
      self.updated_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
      update_combine_param1(@combine_base_sap, *COMB_PARAM_MASK_BASE_SA) if @combine_base_sap
      update_combine_param1(@combine_base_sdp, *COMB_PARAM_MASK_BASE_SD) if @combine_base_sdp
      update_combine_param1(@combine_base_aap, *COMB_PARAM_MASK_BASE_AA) if @combine_base_aap
      update_combine_param1(@combine_base_adp, *COMB_PARAM_MASK_BASE_AD) if @combine_base_adp
      update_combine_param1(@combine_add_sap, *COMB_PARAM_MASK_ADD_SA) if @combine_add_sap
      update_combine_param1(@combine_add_sdp, *COMB_PARAM_MASK_ADD_SD) if @combine_add_sdp
      update_combine_param1(@combine_add_aap, *COMB_PARAM_MASK_ADD_AA) if @combine_add_aap
      update_combine_param1(@combine_add_adp, *COMB_PARAM_MASK_ADD_AD) if @combine_add_adp
      update_combine_param2(@combine_base_max, *COMB_PARAM_MASK_BASE_MAX) if @combine_base_max
      update_combine_param2(@combine_cnt_a, *COMB_PARAM_MASK_CNT_A) if @combine_cnt_a
      update_combine_param2(@combine_cnt_a_max, *COMB_PARAM_MASK_CNT_A_MAX) if @combine_cnt_a_max
      update_combine_param2(@combine_add_max, *COMB_PARAM_MASK_ADD_MAX) if @combine_add_max
      update_combine_param2(@combine_pass_a, *COMB_PARAM_MASK_PASS_A) if @combine_pass_a
      update_combine_param3(@combine_passive_num_max, *COMB_PARAM_MASK_PSV_NUM_MAX) if @combine_passive_num_max
      update_combine_param3(@combine_cnt_b, *COMB_PARAM_MASK_CNT_B) if @combine_cnt_b
      update_combine_param3(@combine_cnt_b_max, *COMB_PARAM_MASK_CNT_B_MAX) if @combine_cnt_b_max
      update_combine_param3(@combine_pass_b, *COMB_PARAM_MASK_PASS_B) if @combine_pass_b
    end


    def update_combine_param1(num, bit, shifter)
      if (num < 0 )
        num = -num + 128
      end
      param_num = self.combine_param1_str.to_i
      param_num = point_to_param64(param_num, num, bit, shifter)
      self.combine_param1_str = param_num.to_s
    end

    def update_combine_param2(num, bit, shifter)
      if (num < 0 )
        num = -num + 128
      end
      self.combine_param2 = point_to_param32(self.combine_param2, num, bit, shifter)
    end

    def update_combine_param3(num, bit, shifter)
      if (num < 0 )
        num = -num + 128
      end
      self.combine_param3 = point_to_param32(self.combine_param3, num, bit, shifter)
    end

    # CPU用のカードインベントリを作る
    def CharaCardSlotInventory.create_cpu_card(no, deck_id)
      no = 0 unless CpuCardData[no]
      if no != 0
        wc = CpuCardData[no].weapon_cards_id
        wc.each_index do |i|
          wc[i].each_index do |j|
            CharaCardSlotInventory.new do |c|
              c.chara_card_deck_id = deck_id
              c.card_id = wc[i][j]
              c.kind = SCT_WEAPON
              c.deck_position = i
              c.card_position = j
              c.save
            end
          end
        end

        qc = CpuCardData[no].equip_cards_id
        qc.each_index do |i|
          qc[i].each_index do |j|
            CharaCardSlotInventory.new do |c|
              c.chara_card_deck_id = deck_id
              c.card_id = qc[i][j]
              c.kind = SCT_EQUIP
              c.deck_position = i
              c.card_position = j
              c.save
            end
          end
        end

        ec = CpuCardData[no].event_cards_id
        ec.each_index do |i|
          ec[i].each_index do |j|
            CharaCardSlotInventory.new do |c|
              c.chara_card_deck_id = deck_id
              c.card_id = ec[i][j]
              c.kind = SCT_EVENT
              c.deck_position = i
              c.card_position = j
              c.save
            end
          end
        end
      end

    end

    def have_exp
      ret = 0
      if self.combined?
        ret = self.exp / COMB_SEND_EXP_COEFFICIENT if self.exp > 0
      end
      if self.card.material_exp > ret
        ret = self.card.material_exp
      end
      ret
    end
    def update_exp(sci_list,is_save=true)
      # exp
      add_exp = 0
      sci_list.each do |sci|
        puts "add_exp:#{add_exp} set_exp:#{sci.have_exp} sci_exp:#{sci.exp} mat_exp:#{sci.card.material_exp}"
        add_exp += sci.have_exp
      end
      self.exp += add_exp
      # level
      set_level = 0
      SC_LEVEL_EXP_TABLE.each_with_index do |prm,idx|
        break if self.exp < prm
        set_level += 1
      end
      set_level = COMB_LEVEL_MAX if set_level > COMB_LEVEL_MAX
      self.level = set_level if self.level < COMB_LEVEL_MAX
      # passive_num
      set_psv_num = 0
      COMB_PASSIVE_RELEASE_LEVEL_RULE.reverse.each_with_index do |l,i|
        if self.level > l
          set_psv_num = COMB_PASSIVE_RELEASE_LEVEL_RULE.length - i
          break
        end
      end
      self.combine_passive_num_max = set_psv_num
      self.save_changes if is_save
    end

    inline do |builder|
      builder.c <<-EOF
        VALUE
        param64_to_point(VALUE num, VALUE bit, VALUE shifter)
        {
          uint64_t n = (NUM2ULL(num) & NUM2ULL(bit)) >> NUM2INT(shifter);
          int x = (int)n;
          int s = x >> 7;
          int ret = x & 127;
          return INT2NUM(s ? -ret : ret);
        }
      EOF
    end

    inline do |builder|
      builder.c <<-EOF
        VALUE
        point_to_param64(VALUE num, VALUE p,  VALUE bit, VALUE shifter)
        {
          uint64_t n = NUM2ULL(num) & ~NUM2ULL(bit);
          uint64_t m= NUM2INT(p);
          m = m << NUM2INT(shifter);
          return ULL2NUM(m|n);
        }
      EOF
    end

    inline do |builder|
      builder.c <<-EOF
        VALUE
        point_to_param32(VALUE num, VALUE p,  VALUE bit, VALUE shifter)
        {
          uint32_t n = NUM2ULL(num) & ~NUM2ULL(bit);
          uint32_t m= NUM2INT(p);
          m = m << NUM2INT(shifter);
          return ULL2NUM(m|n);
        }
      EOF
    end
    # 32はunsignedのみ
    inline do |builder|
      builder.c <<-EOF
        VALUE
        param32_to_point(VALUE num, VALUE bit, VALUE shifter)
        {
          uint32_t n = (NUM2ULONG(num) & NUM2ULONG(bit)) >> NUM2INT(shifter);
          int ret = (int)n;
          return INT2NUM(ret);
        }
      EOF
    end


    def refresh
      @combine_base_sap = nil
      @combine_base_sdp = nil
      @combine_base_aap = nil
      @combine_base_adp = nil
      @combine_add_sap = nil
      @combine_add_sdp = nil
      @combine_add_aap = nil
      @combine_add_adp = nil
      @combine_cnt_a = nil
      @combine_cnt_a_max = nil
      @combine_add_max = nil
      @combine_base_max = nil
      @combine_pass_a = nil
      @combine_passive_num_max = nil
      @combine_cnt_b = nil
      @combine_cnt_b_max = nil
      @combine_pass_b = nil
      super
    end

    # expが0以上なら合成武器
    def combined?
      self.exp > 0
    end

    def combine_base_sap=(n)
      if @combine_base_sap != n
        @combine_base_sap = n
        #modified!(:combine_param1)
        modified!
      end
    end

    def param1_to_point(bit,shifter)
      param_num = self.combine_param1_str.to_i
      param64_to_point(param_num,bit,shifter)
    end

    def combine_base_sap
      @combine_base_sap ||= param1_to_point(*COMB_PARAM_MASK_BASE_SA)
      @combine_base_sap.to_i
    end

    def combine_base_sdp=(n)
      if @combine_base_sdp != n
        @combine_base_sdp = n
        modified!
      end
    end

    def combine_base_sdp
      @combine_base_sdp ||= param1_to_point(*COMB_PARAM_MASK_BASE_SD)
      @combine_base_sdp
    end

    def combine_base_aap=(n)
      if @combine_base_aap != n
        @combine_base_aap = n
        modified!
      end
    end

    def combine_base_aap
      @combine_base_aap ||= param1_to_point(*COMB_PARAM_MASK_BASE_AA)
      @combine_base_aap
    end

    def combine_base_adp=(n)
      if @combine_base_adp != n
        @combine_base_adp = n
        modified!
      end
    end

    def combine_base_adp
      @combine_base_adp ||= param1_to_point(*COMB_PARAM_MASK_BASE_AD)
      @combine_base_adp
    end

    def combine_base_sap=(n)
      if @combine_base_sap != n
        @combine_base_sap = n
        modified!
      end
    end

    # 合成専用武器の場合、合成パラメータに加算
    def restriction_add_param
      (self.card.restriction != "") ? COMB_ADD_PARAM_REST_SET : 0
    end

    def combine_add_sap=(n)
      if @combine_add_sap != n
        @combine_add_sap = n
        modified!
      end
    end

    def combine_add_sap
      @combine_add_sap ||= param1_to_point(*COMB_PARAM_MASK_ADD_SA)
      @combine_add_sap
    end

    def combine_add_sdp=(n)
      if @combine_add_sdp != n
        @combine_add_sdp = n
        modified!
      end
    end

    def combine_add_sdp
      @combine_add_sdp ||= param1_to_point(*COMB_PARAM_MASK_ADD_SD)
      @combine_add_sdp
    end

    def combine_add_aap=(n)
      if @combine_add_aap != n
        @combine_add_aap = n
        modified!
      end
    end

    def combine_add_aap
      @combine_add_aap ||= param1_to_point(*COMB_PARAM_MASK_ADD_AA)
      @combine_add_aap
    end

    def combine_add_adp=(n)
      if @combine_add_adp != n
        @combine_add_adp = n
        modified!
      end
    end

    def combine_add_adp
      @combine_add_adp ||= param1_to_point(*COMB_PARAM_MASK_ADD_AD)
      @combine_add_adp
    end


    def combine_cnt_a=(n)
      puts "#{__method__} @combine_cnt_a:#{@combine_cnt_a} n:#{n}"
      if @combine_cnt_a != n
        @combine_cnt_a = n
        modified!
      end
    end

    def combine_cnt_a
      @combine_cnt_a ||= param32_to_point(self.combine_param2,*COMB_PARAM_MASK_CNT_A)
      @combine_cnt_a
    end


    def combine_cnt_a_max=(n)
      puts "#{__method__} @combine_cnt_a_max:#{@combine_cnt_a_max} n:#{n}"
      if @combine_cnt_a_max != n
        @combine_cnt_a_max = n
        modified!
      end
    end

    def combine_cnt_a_max
      @combine_cnt_a_max ||= param32_to_point(self.combine_param2,*COMB_PARAM_MASK_CNT_A_MAX)
      @combine_cnt_a_max
    end

    def combine_cnt_b=(n)
      puts "#{__method__} @combine_cnt_b:#{@combine_cnt_b} n:#{n}"
      if @combine_cnt_b != n
        @combine_cnt_b = n
        modified!
      end
    end

    def combine_cnt_b
      @combine_cnt_b ||= param32_to_point(self.combine_param3,*COMB_PARAM_MASK_CNT_B)
      @combine_cnt_b
    end

    def combine_cnt_b_max=(n)
      puts "#{__method__} @combine_cnt_b_max:#{@combine_cnt_b_max} n:#{n}"
      if @combine_cnt_b_max != n
        @combine_cnt_b_max = n
        modified!
      end
    end

    def combine_cnt_b_max
      @combine_cnt_b_max ||= param32_to_point(self.combine_param3,*COMB_PARAM_MASK_CNT_B_MAX)
      @combine_cnt_b_max
    end

    def set_combine_cnt(n,idx=0)
      list = ["combine_cnt_a","combine_cnt_b"]
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])} n:#{n}"
      send(list[idx]+"=",n)
    end

    def combine_cnt(idx=0)
      list = ["combine_cnt_a","combine_cnt_b"]
      puts "#{__method__} idx:#{idx}"
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])}"
      send(list[idx])
    end

    def combine_cnt_str
      [combine_cnt_a,combine_cnt_b].join("|")
    end

    def set_combine_cnt_max(n,idx=0)
      list = ["combine_cnt_a_max","combine_cnt_b_max"]
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])} n:#{n}"
      send(list[idx]+"=",n)
    end

    def combine_cnt_max(idx=0)
      list = ["combine_cnt_a_max","combine_cnt_b_max"]
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])}"
      send(list[idx])
    end

    def combine_cnt_max_str
      [combine_cnt_a_max,combine_cnt_b_max].join("|")
    end

    def combine_base_max=(n)
      if @combine_base_max != n
        @combine_base_max = n
        modified!
      end
    end

    def combine_base_max
      @combine_base_max ||= param32_to_point(self.combine_param2,*COMB_PARAM_MASK_BASE_MAX)
      @combine_base_max
    end

    def combine_add_max=(n)
      if @combine_add_max != n
        @combine_add_max = n
        modified!
      end
    end

    def combine_add_max
      @combine_add_max ||= param32_to_point(self.combine_param2,*COMB_PARAM_MASK_ADD_MAX)
      @combine_add_max
    end

    def combine_pass_a=(n)
      puts "#{__method__} @combine_pass_a:#{@combine_pass_a} n:#{n}"
      if @combine_pass_a != n
        @combine_pass_a = n
        modified!
      end
    end

    def combine_pass_a
      @combine_pass_a ||= param32_to_point(self.combine_param2,*COMB_PARAM_MASK_PASS_A)
      @combine_pass_a
    end

    def combine_pass_b=(n)
      puts "#{__method__} @combine_pass_b:#{@combine_pass_b} n:#{n}"
      if @combine_pass_b != n
        @combine_pass_b = n
        modified!
      end
    end

    def combine_pass_b
      @combine_pass_b ||= param32_to_point(self.combine_param3,*COMB_PARAM_MASK_PASS_B)
      @combine_pass_b
    end

    def set_combine_pass(n,idx=0)
      list = ["combine_pass_a","combine_pass_b"]
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])} n:#{n}"
      send(list[idx]+"=",n)
    end

    def combine_pass(idx=0)
      list = ["combine_pass_a","combine_pass_b"]
      puts "#{__method__} idx:#{idx} list[idx]:#{send(list[idx])}"
      send(list[idx])
    end

    def combine_passive_num_max=(n)
      if @combine_passive_num_max != n
        @combine_passive_num_max = n
        modified!
      end
    end

    def combine_passive_num_max
      @combine_passive_num_max ||= param32_to_point(self.combine_param3,*COMB_PARAM_MASK_PSV_NUM_MAX)
      puts "#{__method__} @combine_num:#{@combine_passive_num_max}"
      @combine_passive_num_max
    end

    def combine_passive_num
      cnt = 0
      self.combine_passive_num_max.times do |i|
        cnt += 1 if self.combine_cnt(i) > 0
      end
      cnt
    end

    def combine_passive_set_idx
      list = []
      self.combine_passive_num_max.times do |i|
        list << combine_pass(i) if self.combine_cnt(i) > 0
      end
      puts "#{__method__} list.size:#{list.size}"
      list.size
    end

    def combine_passive_pass_set
      list = []
      self.combine_passive_num_max.times do |i|
        list << combine_pass(i) if self.combine_cnt(i) > 0
      end
      list
    end

    def combine_passive_id(idx=0)
      if COMB_PASSIVE_SET[combine_pass(idx)] && self.combine_cnt(idx) > 0
        COMB_PASSIVE_SET[combine_pass(idx)][0]
      else
        0
      end
    end

    def combine_passive_cost(idx=0)
      if COMB_PASSIVE_SET[combine_pass(idx)] && self.combine_cnt(idx) > 0
        COMB_PASSIVE_SET[combine_pass(idx)][1]
      else
        0
      end
    end

    # パッシブの効果が発揮されて、回数消費
    def use_combine_passive
      vani_psv_ids = []
      # カウントを減らす
      self.combine_passive_num.times do |i|
        a = self.combine_cnt(i)
        if a > 0
          self.set_combine_cnt(a - 1,i)
          if self.combine_cnt(i) <= 0
            # 使用回数が0になったから、パッシブを消す
            vani_psv_ids << COMB_PASSIVE_SET[self.combine_pass(i)][0] # 削除するpsvのIDを送る
            self.set_combine_pass(0,i)
            self.set_combine_cnt(0,i)
            self.set_combine_cnt_max(0,i)
          end
        end
      end
      # passiveAが消えてでpassiveBが残ってる場合移す
      if self.combine_cnt_a <= 0 && self.combine_cnt_b > 0
        v = self.combine_pass_b
        self.combine_pass_a = v
        v = self.combine_cnt_b
        self.combine_cnt_a = v
        v = self.combine_cnt_b_max
        self.combine_cnt_a_max = v
        # Bを削除
        self.combine_pass_b = 0
        self.combine_cnt_b = 0
        self.combine_cnt_b_max = 0
      end
      self.save_changes
      SERVER_LOG.info("CCSI [#{__method__}] after cntA:#{self.combine_cnt(0)} cntB:#{self.combine_cnt(1)} vani_id:#{vani_psv_ids}")
      vani_psv_ids
    end

    def combine_cost
      n = combine_base_sap + combine_base_sdp + combine_base_aap +  combine_base_adp
      ret = 0
      COMB_BASE_COST_RULE.reverse.each_with_index do |c,i|
        if n > c
          ret = COMB_BASE_COST_RULE.length - i
          break
        end
      end
      self.combine_passive_num_max.times do |i|
        ret + combine_passive_cost(i)
      end
      ret
    end

    def deck_cost
      ret =0
      case self.kind
      when SCT_WEAPON
        if self.combined?
          ret = self.combine_cost
          a = WeaponCard[card_id]
          ret += a.card_cost if a
        else
          a = WeaponCard[card_id]
          ret = a.card_cost if a
        end
      when SCT_EQUIP
        a = EquipCard[card_id]
        ret = a.card_cost if a
      when SCT_EVENT
        a = EventCard[card_id]
        ret = a.card_cost if a
      end
      ret
    end

    def card
      ret = nil
      case self.kind
      when SCT_WEAPON
        ret = WeaponCard[card_id]
      when SCT_EQUIP
        ret = EquipCard[card_id]
      when SCT_EVENT
        ret = EventCard[card_id]
      end
      ret
    end

    def delete_from_deck
      SERVER_LOG.info("CharaCardSlotInventory: [delete_from_deck] deck_id:#{self.chara_card_deck_id} inv_id:#{self.id}")
      self.before_deck_id = self.chara_card_deck_id
      self.chara_card_deck_id = 0
      self.save_changes
    end

    # 合成のパッシブIDを返す
    def get_passive_id(ai=:none)
      ret = card.get_passive_id
      if (ai == :quest_ai || ai == :profound_ai)
        self.combine_passive_num_max.times do |i|
          ret << self.combine_passive_id(i) if combine_cnt(i) > 0
        end
      end
      ret
    end

    # 合成のパッシブIDを返す 必ず全て
    def get_all_passive_id
      ret = card.get_passive_id
      self.combine_passive_num_max.times do |i|
        ret << self.combine_passive_id(i) if combine_cnt(i) > 0
      end
      ret
    end

    # 近距離攻撃力増加
    def sword_ap(ai=:none)
      (ai != :quest_ai && ai != :profound_ai) ? self.combine_base_sap : (self.combine_base_sap + self.combine_add_sap)
    end

    # 近距離ダイス攻撃力増加
    def sword_dice_bonus(ai=:none)
      0
    end

    # 近距離防御力増加
    def sword_dp(ai=:none)
      (ai != :quest_ai && ai != :profound_ai) ? self.combine_base_sdp : (self.combine_base_sdp + self.combine_add_sdp)
    end

    # 近距離ダイス防御力増加
    def sword_deffence_dice_bonus(ai=:none)
      0
    end

    # 遠距離攻撃力増加
    def arrow_ap(ai=:none)
      (ai != :quest_ai && ai != :profound_ai) ? self.combine_base_aap : (self.combine_base_aap + self.combine_add_aap)
    end

    # 遠距離ダイス増加
    def arrow_dice_bonus(ai=:none)
      0
    end

    # 遠距離防御力増加
    def arrow_dp(ai=:none)
      (ai != :quest_ai && ai != :profound_ai) ? self.combine_base_adp : (self.combine_base_adp + self.combine_add_adp)
    end

    # 遠距離ダイス防御力増加
    def arrow_deffence_dice_bonus(ai=:none)
      0
    end

    def combine_param1_upper
      param_num = self.combine_param1_str.to_i
      param_num >> 32
    end

    def combine_param1_lower
      param_num = self.combine_param1_str.to_i
      param_num & 0B0000_0000_0000_0000_0000_0000_0000_0000_1111_1111_1111_1111_1111_1111_1111_1111
    end

    def limit_check(v,max,min)
      if v > max
        v = max
      elsif v < min
        v = min
      end
      v
    end
    def add_param_limit_check(v,base_v)
      limit_check(v,self.level+restriction_add_param,COMB_ADD_PARAM_MIN)
    end
    def combine_update(result)
      incre_param_keys = []
      result.each do |k,v|
        case k
        when :base_sap
          a = self.combine_base_sap
          self.combine_base_sap = a + v
          self.combine_base_sap = limit_check(self.combine_base_sap,COMB_BASE_PARAM_MAX,COMB_BASE_PARAM_MIN)
        when :base_sdp
          a = self.combine_base_sdp
          self.combine_base_sdp = a + v
          self.combine_base_sdp = limit_check(self.combine_base_sdp,COMB_BASE_PARAM_MAX,COMB_BASE_PARAM_MIN)
        when :base_aap
          a = self.combine_base_aap
          self.combine_base_aap = a + v
          self.combine_base_aap = limit_check(self.combine_base_aap,COMB_BASE_PARAM_MAX,COMB_BASE_PARAM_MIN)
        when :base_adp
          a = self.combine_base_adp
          self.combine_base_adp = a + v
          self.combine_base_adp = limit_check(self.combine_base_adp,COMB_BASE_PARAM_MAX,COMB_BASE_PARAM_MIN)
        when :add_sap
          a = self.combine_add_sap
          self.combine_add_sap = a + v
          self.combine_add_sap = add_param_limit_check(self.combine_add_sap,self.combine_base_sap)
        when :add_sdp
          a = self.combine_add_sdp
          self.combine_add_sdp = a + v
          self.combine_add_sdp = add_param_limit_check(self.combine_add_sdp,self.combine_base_sdp)
        when :add_aap
          a = self.combine_add_aap
          self.combine_add_aap = a + v
          self.combine_add_aap = add_param_limit_check(self.combine_add_aap,self.combine_base_aap)
        when :add_adp
          a = self.combine_add_adp
          self.combine_add_adp = a + v
          self.combine_add_adp = add_param_limit_check(self.combine_add_adp,self.combine_base_adp)
        when :base_max
          self.combine_base_max = v
        when :add_max
          self.combine_add_max = v
        when :passive_id
          puts "#{__method__} passive_id idx:#{self.combine_passive_set_idx}"
          if self.combine_passive_set_idx > -1
            idx = self.combine_passive_set_idx
            puts "#{__method__} passive_id idx:#{idx}"
            self.set_combine_pass(v,idx)
            self.set_combine_cnt(COMB_PASSIVE_SET[v][2],idx)
            self.set_combine_cnt_max(COMB_PASSIVE_SET[v][2],idx)
          end
        when :new_weapon_id
          self.card_id = v
        end

        # 数値が上がったパラメータを記憶
        incre_param_keys << "combine_" + k.to_s if k != :set && v > 0
      end
      over_check(incre_param_keys)
      normal_combine_id_check
      true
    end

    # max をオーバーしていたら値を整える
    def over_check(keys)
      base_total = combine_base_sap+combine_base_sdp+combine_base_aap+combine_base_adp
      if base_total > combine_base_max
        l = ["combine_base_sap","combine_base_sdp","combine_base_aap","combine_base_adp"]
        decre_num = base_total-combine_base_max
        keys.each { |k| l.delete(k) } # 加算したパラメータは省く
        l = ["combine_base_sap","combine_base_sdp","combine_base_aap","combine_base_adp"] if l.size <= 0 # 全て加算されているなら、全部から参照
        while decre_num != 0
          r = rand(l.size)
          if send(l[r]) > COMB_BASE_PARAM_MIN
            send(l[r]+"=",send(l[r])-1 )
            decre_num -= 1
          else
            # これ以上マイナスできないので、リストから省く
            l.delete(l[r])
            l = ["combine_base_sap","combine_base_sdp","combine_base_aap","combine_base_adp"] if l.size <= 0 # リストがなくなってしまったなら、全て同条件に変更
          end
        end
      end
    end

    # 汎用合成武器のIDチェック
    def normal_combine_id_check
      # 専用武器ならこの処理はしない
      return if self.card.restriction != ""
      set_list = {:base_sap=>self.combine_base_sap,:base_sdp=>self.combine_base_sdp,:base_aap=>self.combine_base_aap,:base_adp=>self.combine_base_adp}
      max_key_list = [:base_sdp] # デフォルトはリング
      max = 0
      set_list.each do |k,v|
        if v > max
          max_key_list = []
          max_key_list << k
          max = v
        elsif v == max && v != 0
          max_key_list << k
        end
      end
      # 一つしか選択されてなければ、0を追加
      max_key_list << 0 if max_key_list.size <= 1
      first_key = max_key_list.shift()
      second_key = max_key_list.shift()
      self.card_id = COMB_NORMAL_TYPE_PARAM_ID_RULE[first_key][second_key]
    end

    # 汎用から専用武器に変化した際の処理
    def change_restriction_act
      a = self.combine_add_sap
      self.combine_add_sap = a + restriction_add_param
      self.combine_add_sap = add_param_limit_check(self.combine_add_sap,self.combine_base_sap)
      a = self.combine_add_sdp
      self.combine_add_sdp = a + restriction_add_param
      self.combine_add_sdp = add_param_limit_check(self.combine_add_sdp,self.combine_base_sdp)
      a = self.combine_add_aap
      self.combine_add_aap = a + restriction_add_param
      self.combine_add_aap = add_param_limit_check(self.combine_add_aap,self.combine_base_aap)
      a = self.combine_add_adp
      self.combine_add_adp = a + restriction_add_param
      self.combine_add_adp = add_param_limit_check(self.combine_add_adp,self.combine_base_adp)
      self.save_changes
    end

    # ログにパラメータを表示
    def write_log(pl_id,after=false)
      add_txt = "pre"
      add_txt = "after" if after
      set_param = []
      set_param << "inv_id:#{self.id}"
      set_param << "lv:#{self.level}"
      set_param << "exp:#{self.exp}"
      set_param << "restriction:#{self.card.restriction}"
      set_param << "base_max:#{self.combine_base_max}"
      set_param << "add_max:#{self.level+self.restriction_add_param}"
      set_param << "passive_slot:#{self.combine_passive_num_max}"
      set_param << "base_sap:#{self.combine_base_sap}"
      set_param << "base_sdp:#{self.combine_base_sdp}"
      set_param << "base_aap:#{self.combine_base_aap}"
      set_param << "base_adp:#{self.combine_base_adp}"
      set_param << "add_sap:#{self.combine_add_sap}"
      set_param << "add_sdp:#{self.combine_add_sdp}"
      set_param << "add_aap:#{self.combine_add_aap}"
      set_param << "add_adp:#{self.combine_add_adp}"
      self.combine_passive_num.times do |idx|
        set_param << "passive_id[#{idx+1}]:#{self.combine_passive_id(idx)}"
        set_param << "passive_cnt[#{idx+1}]:#{self.combine_cnt(idx)}"
        set_param << "passive_cnt_max[#{idx+1}]:#{self.combine_cnt_max(idx)}"
      end

      SERVER_LOG.info("<UID:#{pl_id}>Avatar: [combine_result_#{add_txt}_status] #{set_param.join(",")}")

    end


    # ================================================
    # 組み合わせが問題ないかチェックする関数関連
    # ================================================
    # 合成武器化素材ID
    CMB_BASE_WC_CHANGE_ID = 5000
    # パラメータアップ素材ID群
    CMB_BASE_PARAM_UP_IDS = [5001,5002,5003,5004]
    # パラメータシフト素材ID群
    CMB_BASE_PARAM_SHIFT_IDS = [5005,5006,5007,5008]
    # モンスパラメータアップ素材ID群
    CMB_MONSTER_PARAM_UP_IDS = [5009,5010,5011,5012,5013,5014,5015,5016,5017,5018,5019,5020]
    # パラメータ上限解放素材ID群
    CMB_BASE_PARAM_MAX_UP_IDS = [5021,5022,5023]
    # パラメータ上限解放数値
    CMB_BASE_PARAM_MAX_UP_NUM = [3,4,5]
    # 専用武器化素材ID群
    CMB_CREST_MATERIAL_IDS = [6000,6001,6002,6003]
    # 対パッシブ付加素材ID群
    CMB_PASSIVE_MATERIAL_IDS = [7000,7001,7002,7003,7004,7005]
    # 対パッシブ付加素材PASS群
    CMB_PASSIVE_MATERIAL_PASS_SET = {7000=>0,7001=>1,7002=>2,7003=>3,7004=>9,7005=>13}

    # 使用不可範囲
    CMB_BLOCK_WC_ID_START = 22
    CMB_BLOCK_WC_ID_END   = 300

    # 専用化可能レベル
    CMB_CREST_CAN_USE_LV = 5
    # 専用化アイテム使用可能数
    CMB_CREST_CAN_USE_NUM = 2


    def self::combine_check(base_sci,use_sci_list)
      # ベースが武器カードでないならアウト
      return false if base_sci.card.weapon_type == WEAPON_TYPE_MATERIAL
      # ベースの武器が未合成武器なら、素材がオルタサイトでないといけない
      if ! base_sci.combined?
        first_mat_sci = use_sci_list.first
        return false if first_mat_sci.card_id != CMB_BASE_WC_CHANGE_ID
      else
        # ベースが合成武器の場合、素材によって処置が変わってくる
        use_sci_id_list = { }
        use_sci_list.each do |sci|
          return false if sci.card_id == CMB_BASE_WC_CHANGE_ID # 合成武器にオルタサイトなら無効
          return false if sci.card_id >= CMB_BLOCK_WC_ID_START && sci.card_id <= CMB_BLOCK_WC_ID_END # 使用不可範囲のIDなら無効
          use_sci_id_list[sci.card_id] = [] unless use_sci_id_list[sci.card_id]
          use_sci_id_list[sci.card_id] << sci
        end
        # 最大値UP素材チェック
        base_max = base_sci.combine_base_max
        CMB_BASE_PARAM_MAX_UP_IDS.each_with_index do |id,idx|
          if use_sci_id_list[id]
            return false if use_sci_id_list[id].size > 1 # 複数追加されてれば無効
            set_max = CMB_BASE_PARAM_MAX_UP_NUM[idx]
            return false if base_max != (set_max-1) # 既に上昇済み,または飛ばしているなら無効
            base_max = set_max # 問題ないなら、今後の判定で反映される様に
          end
        end
        # パッシブ付加素材チェック
        return false if base_sci.combine_passive_num_max <= base_sci.combine_passive_set_idx # 既に最大数セットされているなら無効
        now_psv_ids = base_sci.get_all_passive_id
        CMB_PASSIVE_MATERIAL_IDS.each do |id|
          if use_sci_id_list[id]
            return false if use_sci_id_list[id].size > 1 # 複数追加されてれば無効
            set_pass = CMB_PASSIVE_MATERIAL_PASS_SET[id]
            set_psv_id = COMB_PASSIVE_SET[set_pass][0]
            return false if now_psv_ids.include?(set_psv_id) # 既にセットされているパッシブなら無効
          end
        end
        # クレスト素材チェック
        mat_num = 0
        CMB_CREST_MATERIAL_IDS.each do |id|
          if use_sci_id_list[id]
            return false if use_sci_id_list[id].size > 1 # 複数追加されてれば無効
            return false if base_sci.level < CMB_CREST_CAN_USE_LV # 使用可能レベル以下なら無効
            mat_num += 1
          end
        end
        return false if mat_num > CMB_CREST_CAN_USE_NUM # 使用可能個数を超えているなら無効
        # パラメータ関連素材チェック
        base_params = [0,0,0,0]
        base_params[0] += base_sci.combine_base_sap
        base_params[1] += base_sci.combine_base_sdp
        base_params[2] += base_sci.combine_base_aap
        base_params[3] += base_sci.combine_base_adp
        shift_param = 0
        add_params = [0,0,0,0]
        add_params[0] += base_sci.combine_add_sap
        add_params[1] += base_sci.combine_add_sdp
        add_params[2] += base_sci.combine_add_aap
        add_params[3] += base_sci.combine_add_adp
        base_total = base_params.inject(:+)
        add_max = base_sci.level+base_sci.restriction_add_param
        change_params = [0,0,0,0]
        CMB_BASE_PARAM_UP_IDS.each_with_index do |id,idx|
          if use_sci_id_list[id]
            num = use_sci_id_list[id].size
            change_params[idx] += num
          end
        end
        CMB_BASE_PARAM_SHIFT_IDS.each_with_index do |id,idx|
          if use_sci_id_list[id]
            num = use_sci_id_list[id].size
            change_params[idx] -= num
            shift_param += num
          end
        end
        change_params.each_with_index do |val,idx|
          if val != 0
            check_val = base_params[idx] + val
            return false if check_val > COMB_BASE_PARAM_MAX # 個々の最大値を超える場合は無効
            return false if check_val < COMB_BASE_PARAM_MIN # 個々の最低値を超える場合は無効
            base_total += val
          end
        end
        base_total += shift_param
        return false if base_total > base_max # 合計最大値を超える場合は無効
        use_sci_id_list.each do |id,list|
          sci = list.first
          # レイドパラメータ加算素材か素材以外の武器ならチェックする
          if CMB_MONSTER_PARAM_UP_IDS.include?(id) || sci.card.weapon_type != WEAPON_TYPE_MATERIAL
            num = list.size
            mat_add_param = sci.card.material_add_param_list
            add_params.each_with_index do |val,idx|
              return false if (val + (mat_add_param[idx] * num)) > add_max # 個々の最大値を超える場合は無効
            end
          end
        end
      end
      true
    end

  end

end
