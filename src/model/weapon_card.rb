# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # イベントカードクラス
  class WeaponCard < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    one_to_many :combine_cases               # 複数の合成情報を保持

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name
      integer     :weapon_no
      String      :passive_id, :default => ""
      integer     :card_cost, :default => 0
      String      :restriction, :default => ""
      String      :image, :default => ""
      String      :caption, :default => ""
      integer     :weapon_type, :default => WEAPON_TYPE_NORMAL
      integer     :material_use_cnt, :default => 0
      integer     :material_add_param, :default => 0 # mons(+-127) 8_8_8_8 32 bit
      integer     :material_exp, :default => 0
      datetime    :created_at
      datetime    :updated_at
    end

    MAT_ADD_PARAM_MASK_ADD_SA   = [0B1111_1111_0000_0000_0000_0000_0000_0000, 24] # +-127
    MAT_ADD_PARAM_MASK_ADD_SD   = [0B0000_0000_1111_1111_0000_0000_0000_0000, 16] # +-127
    MAT_ADD_PARAM_MASK_ADD_AA   = [0B0000_0000_0000_0000_1111_1111_0000_0000, 8]  # +-127
    MAT_ADD_PARAM_MASK_ADD_AD   = [0B0000_0000_0000_0000_0000_0000_1111_1111, 0]  # +-127

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(WeaponCard.table_exists?)
      WeaponCard.create_table
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
      Unlight::WeaponCard::refresh_data_version
      Unlight::WeaponCard::cache_store.delete("weapon_card:restricrt:#{id}")
      Unlight::WeaponCard::cache_store.delete("weapon_card:passive_id:#{id}")
    end

    DB.alter_table :weapon_cards do
      add_column :passive_id, String, :default => "" unless Unlight::WeaponCard.columns.include?(:passive_id)  # 新規追加 2014/8/13
      add_column :material_use_cnt, :integer, :default => 0 unless Unlight::WeaponCard.columns.include?(:material_use_cnt)  # 新規追加 2015/5/13
      add_column :material_add_param, :integer, :default => 0 unless Unlight::WeaponCard.columns.include?(:material_add_param)  # 新規追加 2015/5/15
      add_column :material_exp, :integer, :default => 0 unless Unlight::WeaponCard.columns.include?(:material_exp)  # 新規追加 2015/5/15
    end

    # 全体データバージョンを返す
    def WeaponCard::data_version
      ret = cache_store.get("WeaponCardVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("WeaponCardVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def WeaponCard::refresh_data_version
      m = Unlight::WeaponCard.order(:updated_at).last
      if m
        cache_store.set("WeaponCardVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # material_add_paramの数値変換用
    inline do |builder|
      builder.c <<-EOF
        VALUE
        param_to_point(VALUE num, VALUE bit, VALUE shifter)
        {
          uint64_t n = (NUM2ULL(num) & NUM2ULL(bit)) >> NUM2INT(shifter);
          int x = (int)n;
          int s = x >> 7;
          int ret = x & 127;
          return INT2NUM(s ? -ret : ret);
        }
      EOF
    end

    # CSVで返す
    def get_data_csv_str
      ret = ""
      ret << self.id.to_s << ","
      ret << '"' << (self.name||"") << '",'
      ret << (self.weapon_no||0).to_s << ","
      ret << (self.card_cost||0).to_s << ','
      ret << '[' << '"' << (self.restriction||"") << '"'  << '],'
      ret << '"' << (self.image||"") << '",'
      ret << '"' << (self.caption||"") << '",'
      ret << (self.weapon_type||0).to_s << ','
      ret << (self.material_use_cnt||0).to_s << ','
      ret << (param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_SA)||0).to_s << ','
      ret << (param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_SD)||0).to_s << ','
      ret << (param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_AA)||0).to_s << ','
      ret << (param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_AD)||0).to_s << ','
      ret << '[' << '"' << (self.passive_id||"") << '"'  << ']'
      ret
    end

    # キャラで使えるかチェック
    def check_using_chara(chara_no)
      ret = true
      if restriction_charas.size>0
        ret = restriction_charas.include?(chara_no)
      end
      ret
    end

    # キャラ制限のリストを返す
    def restriction_charas
      ret = WeaponCard::cache_store.get("weapon_card:restricrt:#{id}")
      unless ret
        ret = []
        if CHARA_GROUP_MEMBERS.key?(restriction)
          ret = CHARA_GROUP_MEMBERS[restriction]
        else
          ret = restriction.split("|") if restriction
        end
        ret.map!{ |c| c.to_i}
        WeaponCard::cache_store.set("weapon_card:restricrt:#{id}", ret)
      end
      ret
    end

    # パッシブIDを返す
    def get_passive_id(ai=:none)
      ret = WeaponCard::cache_store.get("weapon_card:passive_id:#{id}")
      unless ret
        ret = []
        ret = self.passive_id.split("|") if self.passive_id
        ret.map!{ |p| p.to_i}
        WeaponCard::cache_store.set("weapon_card:passive_id:#{id}", ret)
      end
      ret
    end

    # ウェポンボーナス配列におけるインデックス
    BORNUS_TYPE_SWORD_AP = 0
    BORNUS_TYPE_SWORD_DP = 2
    BORNUS_TYPE_ARROW_AP = 4
    BORNUS_TYPE_ARROW_DP = 6

    # ===============================
    # アイテム種別
    # 必要となるオブジェクトが種別によってきまる
    # 0:Avatarのみ
    # 1:Rewardのみ
    # 2:AutoPlayとAvatar
    #

    # イベントの効果、使用関数とValueのペア
    WEAPON_EFFECTS ={
                     1 => { :sword_ap => 1 },                                                    # 1
                     2 => { :arrow_ap => 1 },                                                    # 2
                     3 => { :sword_dp => 1, :arrow_dp => 1, :sword_ap => -1, :arrow_ap => -1 },  # 3
                     4 => { :sword_ap => 2, :sword_dp => -1, :arrow_dp => -1 },                  # 4
                     5 => { :arrow_ap => 2, :sword_dp => -1, :arrow_dp => -1 },                  # 5
                     6 => { :sword_ap => 2 },                                                    # 6
                     7 => { :arrow_ap => 2 },                                                    # 7
                     8 => { :sword_dp => 2, :arrow_dp => 2, :sword_ap => -2, :arrow_ap => -2 },  # 8
                     9 => { :sword_ap => 4, :sword_dp => -2, :arrow_dp => -2 },                  # 9
                     10 => { :arrow_ap => 4, :sword_dp => -2, :arrow_dp => -2 },                  # 10
                     11 => { :sword_ap => 3 },                                                    # 11
                     12 => { :arrow_ap => 3 },                                                    # 12
                     13 => { :sword_dp => 3, :arrow_dp => 3, :sword_ap => -3, :arrow_ap => -3 },  # 13
                     14 => { :sword_ap => 6, :sword_dp => -3, :arrow_dp => -3 },                  # 14
                     15 => { :arrow_ap => 6, :sword_dp => -3, :arrow_dp => -3 },                  # 15
                     16 => { :sword_ap => 1, :arrow_ap => 1 },                                    # 16
                     17 => { :sword_ap => 2, :arrow_ap => 2 },                                    # 17
                     18 => { :sword_ap => 1, :sword_dp => 1 },                                    # 18
                     19 => { :sword_ap => 2, :sword_dp => 2 },                                    # 19
                     20 => { :arrow_ap => 1, :arrow_dp => 1 },                                    # 20
                     21 => { :arrow_ap => 2, :arrow_dp => 2 },                                    # 21
                     22 => { :sword_ap => 4, :sword_dp => -2 },                                   # 22
                     23 => { :arrow_ap => 4, :arrow_dp => -2 },                                   # 23
                     24 => { :sword_dp => 1, :arrow_dp => 1 },                                    # 24
                     25 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 1, :arrow_dp => 1 },    # 25
                     26 => { :arrow_ap => 3, :sword_dp => 1 },                                    # 26
                     27 => { :sword_ap => 2, :sword_dp => 3 },                                    # 27
                     28 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 28
                     29 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 29
                     30 => { :sword_ap => 7, :sword_dp => -2 },                                   # 30
                     31 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 31
                     32 => { :sword_ap => 2, :sword_dp => 1, :arrow_dp => 1 },                    # 32
                     33 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1 },                    # 33
                     34 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 34
                     35 => { :sword_ap => 4 },                                                    # 35
                     36 => { :arrow_ap => 3, :sword_dp => 2 },                                    # 36
                     37 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 37
                     38 => { :sword_ap => 3, :sword_dp => 1 },                                    # 38
                     39 => { :sword_ap => 4, :arrow_ap => 4, :arrow_dp => -3 },                   # 39
                     40 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 40
                     41 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 41
                     42 => { :sword_ap => 2, :sword_dp => 3 },                                    # 42
                     43 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 43
                     44 => { :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },                    # 44
                     45 => { :sword_ap => 4, :arrow_ap => 4, :arrow_dp => -3 },                   # 45
                     46 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 46
                     47 => { :arrow_dp => 4 },                                                    # 47
                     48 => { :arrow_ap => 5 },                                                    # 48
                     49 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 49
                     50 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 50
                     51 => { :sword_ap => 4, :arrow_ap => 4, :arrow_dp => -3 },                   # 51
                     52 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 52
                     53 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 53
                     54 => { :sword_ap => 5 },                                                    # 54
                     55 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 55
                     56 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 56
                     57 => { :sword_ap => 1, :sword_dp => 2, :arrow_dp => 2 },                    # 57
                     58 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 58
                     59 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 59
                     60 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1 },                    # 60
                     61 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 61
                     62 => { :arrow_ap => 3, :sword_dp => 1},                                     # 62
                     63 => { :sword_ap => 2, :sword_dp => 3 },                                    # 63
                     64 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 64
                     65 => { :sword_ap => 3, :sword_dp => 1 },                                    # 65
                     66 => { :arrow_ap => 2, :arrow_dp => 3 },                                    # 66
                     67 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 67
                     68 => { :sword_ap => 1, :sword_dp => 3 },                                    # 68
                     69 => { :arrow_ap => 3, :arrow_dp => 2 },                                    # 69
                     70 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 70
                     71 => { :sword_dp => 2, :arrow_dp => 2 },                                    # 71
                     72 => { :sword_ap => 4, :sword_dp => 1 },                                    # 72
                     73 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 73
                     74 => { :sword_ap => 4 },                                                    # 74
                     75 => { :sword_ap => 3, :sword_dp => 2 },                                    # 75
                     76 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 76
                     77 => { :sword_ap => 4 },                                                    # 77
                     78 => { :sword_ap => 2, :arrow_dp => 3 },                                    # 78
                     79 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 79
                     80 => { :sword_dp => 2, :arrow_dp => 2 },                                    # 80
                     81 => { :sword_ap => 2, :sword_dp => 3 },                                    # 81
                     82 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 82
                     83 => { :sword_ap => 3, :sword_dp => 1 },                                    # 83
                     84 => { :arrow_ap => 3, :arrow_dp => 2 },                                    # 84
                     85 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 85
                     86 => { :sword_ap => 3, :sword_dp => 1 },                                    # 86
                     87 => { :arrow_ap => 2, :arrow_dp => 3 },                                    # 87
                     88 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 88
                     89 => { :sword_ap => 2, :arrow_ap => 2},                                     # 89
                     90 => { :arrow_ap => 1, :arrow_dp => 4 },                                    # 90
                     91 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 91
                     92 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 92
                     93 => { :arrow_ap => 5 },                                                    # 93
                     94 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 94
                     95 => { :sword_ap => 4 },                                                    # 95
                     96 => { :sword_ap => 2, :sword_dp => 3 },                                    # 96
                     97 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 97
                     98 => { :arrow_ap => 1, :arrow_dp => 3 },                                    # 98
                     99 => { :sword_ap => 2, :arrow_dp => 3 },                                    # 99
                     100 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 100
                     101 => { :sword_dp => 4 },                                                    # 101
                     102 => { :arrow_ap => 3, :arrow_dp => 2 },                                    # 102
                     103 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 103
                     104 => { :arrow_dp => 4 },                                                    # 104
                     105 => { :sword_ap => 5,},                                                    # 105
                     106 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 106
                     107 => { :sword_dp => 2, :arrow_dp => 2 },                                    # 107
                     108 => { :arrow_ap => 3, :sword_dp => 2 },                                    # 108
                     109 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 109
                     110 => { :sword_ap => 4 },                                                    # 110
                     111 => { :arrow_ap => 1, :arrow_dp => 4 },                                    # 111
                     112 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 112
                     113 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 113
                     114 => { :sword_ap => 1, :sword_dp => 2, :arrow_dp => 2 },                    # 114
                     115 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 115
                     116 => { :arrow_ap => 3, :arrow_dp => 1 },                                    # 116
                     117 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1 },                    # 117
                     118 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 118
                     119 => { :sword_dp => 2, :arrow_dp => 2 },                                    # 119
                     120 => { :arrow_ap => 4, :arrow_dp => 1 },                                    # 120
                     121 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 121
                     122 => { :arrow_ap => 7, :sword_dp => -1, :arrow_dp => -1, },                 # 122
                     123 => { :sword_ap => 3, :sword_dp => 1, :arrow_dp => 1 },                    # 123
                     124 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 124
                     125 => { :sword_dp => 2, :arrow_dp => 2, },                                   # 125
                     126 => { :sword_ap => 3, :sword_dp => 1, :arrow_dp => 1 },                    # 126
                     127 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 127
                     128 => { :arrow_ap => 4, },                                                   # 128
                     129 => { :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },                    # 129
                     130 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 130
                     131 => { :sword_ap => 2, :arrow_ap => 2, },                                   # 131
                     132 => { :arrow_ap => 2, :arrow_dp => 3  },                                   # 132
                     133 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 133
                     134 => { :sword_dp => 4, },                                                   # 134
                     135 => { :sword_ap => 2, :arrow_ap => 2, :arrow_dp => 1  },                   # 135
                     136 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 136
                     137 => { :arrow_ap => 5, :arrow_dp => -1},                                    # 137
                     138 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 3  },                   # 138
                     139 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 139
                     140 => { :sword_ap => 3, :sword_dp => 1, },                                   # 140
                     141 => { :sword_ap => 1, :arrow_ap => 1, :arrow_dp => 3  },                   # 141
                     142 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 142
                     143 => { :arrow_ap => 4, },                                                   # 143
                     144 => { :arrow_ap => 1, :sword_dp => 4  },                                   # 144
                     145 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 145
                     146 => { :sword_dp => 4, },                                                   # 146
                     147 => { :arrow_ap => 4, :arrow_dp => 1  },                                   # 147
                     148 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 148
                     149 => { :sword_dp => 2, :arrow_dp => 2, },                                   # 149
                     150 => { :sword_ap => 3, :arrow_ap => 3, :arrow_dp => -1  },                  # 150
                     151 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 151
                     152 => { :sword_ap => -1, :arrow_ap => -1, :sword_dp => 3, :arrow_dp => 3, }, # 152
                     153 => { :arrow_ap => 3, :sword_dp => 1, :arrow_dp => 1  },                   # 153
                     154 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 154
                     155 => { :sword_dp => 2, :arrow_dp => 2, },                                   # 155
                     156 => { :arrow_ap => 3, :sword_dp => 2  },                                   # 156
                     157 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 157
                     158 => { :sword_ap => 3, :arrow_ap => 3, :sword_dp => -1, },                  # 158
                     159 => { :sword_ap => 2, :sword_dp => 3, },                                   # 159
                     160 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 160
                     161 => { :arrow_dp => 4, },                                                   # 161
                     162 => { :arrow_ap => 4, :arrow_dp => 1, },                                   # 162
                     163 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 163
                     164 => { :sword_ap => 3, :arrow_ap => 3 },                                    # 164
                     165 => { :sword_ap => 4, :arrow_dp => -3 },                                   # 165
                     166 => { :arrow_ap => 4, :sword_dp => -3 },                                   # 166
                     167 => { :sword_ap => 4, },                                                   # 167
                     168 => { :sword_dp => 2, :arrow_ap => 3, },                                   # 168
                     169 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 169
                     170 => { :sword_dp => 2, :arrow_dp => 2 },                                    # 170
                     171 => { :sword_ap => -2, :arrow_dp => 3 },                                   # 171
                     172 => { :sword_ap => -3, :arrow_ap => -3, :sword_dp => -3, :arrow_dp => -3 },# 172
                     173 => { :sword_ap => 2, :arrow_ap => 2 },                                    # 173
                     174 => { :arrow_ap => 3, :arrow_dp => 2 },                                    # 174
                     175 => { :sword_ap => 3, :arrow_ap => 3 },                                    # 175
                     176 => { :sword_dp => 3, :arrow_dp => 3, :arrow_ap => -2 },                   # 176
                     177 => { :sword_dp => 5, },                                                   # 177
                     178 => { :sword_dp => 3, :arrow_dp => 3 },                                    # 178
                     179 => { :sword_ap => 2, :arrow_ap => 2 },                                    # 179
                     180 => { :sword_ap => 3, :arrow_dp => 2 },                                    # 180
                     181 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 181
                     182 => { :sword_dp => 4, },                                                   # 182
                     183 => { :arrow_ap => 5, },                                                   # 183
                     184 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 184
                     185 => { :arrow_dp => 4  },                                                   # 185
                     186 => { :arrow_ap => 3, :arrow_dp => 2 },                                    # 186
                     187 => { :arrow_ap => 5, :arrow_dp => 1 },                                    # 187
                     188 => { :sword_ap => 2  },                                                   # 188
                     189 => { :sword_dp => -1, :arrow_ap => 5},                                    # 189
                     190 => { :sword_ap => 3, :sword_dp => 2 },                                    # 190
                     191 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 191
                     192 => { :sword_dp => 1, :arrow_dp => 1},                                     # 192
                     193 => { :sword_dp => 1, :arrow_dp => 1},                                     # 193
                     194 => { :arrow_ap => 2, :arrow_dp => 3},                                     # 194
                     195 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1},     # 195
                     196 => { :sword_dp => 1, :arrow_dp => 1},                                     # 196
                     197 => { :sword_dp => 2, :arrow_ap => 3},                                     # 197
                     198 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2},     # 198
                     199 => { :sword_dp => 1, :arrow_dp => 1},                                     # 199
                     200 => { :sword_ap => 2, :arrow_dp => 3},                                     # 200
                     201 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2},     # 201
                     202 => { :sword_ap => 1},                                                     # 202
                     203 => { :sword_ap => 2},                                                     # 203
                     204 => { :sword_ap => 3, :sword_dp => 2},                                     # 204
                     205 => { :sword_ap => 1},                                                     # 205
                     206 => { :sword_ap => 3, :arrow_ap => 3, :arrow_dp => -1},                    # 206
                     207 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 207
                     208 => {},                                                                    # 208
                     209 => { :sword_ap => 1},                                                     # 209
                     210 => { :arrow_ap => 4, :arrow_dp => 1},                                     # 210
                     211 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 211
                     212 => { :sword_ap => 1},                                                     # 212
                     213 => { :arrow_ap => 1, :arrow_dp => 2, :sword_dp=>2},                       # 213
                     214 => { :sword_ap => 2, :arrow_ap => 2, :sword_dp => 1, :arrow_dp => 1 },    # 214
                     216 => { :sword_ap => -4, :arrow_ap => 3, :sword_dp=>3, :arrow_dp=>3 },
                     217 => { :sword_ap => 1, :arrow_ap => 1, :sword_dp => 2, :arrow_dp => 2 },    # 217
                     219 => { :sword_ap => 5, :arrow_ap => -4, :sword_dp=>2, :arrow_dp=>2 },
                     222 => { :arrow_ap => 1, :arrow_dp=>4 },
                     225 => { :arrow_ap => 2, :sword_dp=>3 },
                     227 => { :arrow_ap => 2},                                     # 227
                     229 => { :sword_ap => 5 },
                     231 => { },
                     233 => { :arrow_dp => 5 },
                     236 => { :sword_ap => 3, :arrow_ap => 2 },
                     239 => { :arrow_ap => 3, :arrow_dp => 3, :sword_dp => -1 },
                     242 => { :arrow_ap => 2, :sword_dp => 3 },
                     245 => { :sword_ap => -1, :arrow_dp => 6 },
                     248 => { :sword_ap => 6, :arrow_ap => -1 },
                     251 => { :sword_dp => 1, :arrow_dp => 4 },
                     254 => { :sword_ap => 5 },
                     256 => { :sword_ap => 1, :arrow_ap => 1 },    # 256
                     258 => { :sword_ap => 3, :arrow_ap => 3, :arrow_dp => -1 },
                     262 => { :sword_dp => 5 },
                     265 => { :sword_ap => 2, :arrow_dp => 3 },
                     267 => { :sword_ap => -1, :arrow_ap => -1 },
                     268 => { :sword_ap => 3, :sword_dp => -1 },
                     269 => { },
                     1001=> { },                                     # 1001
                     1002=> { },                                     # 1002
                     1003=> { },                                     # 1003
                     1004=> { },                                     # 1004
                     1005=> { },                                     # 1005
                     1006=> { },                                     # 1006
                     1007=> { },                                     # 1007
                     1008=> { },                                     # 1008
                     1009=> { },                                     # 1009
                     1010=> { },                                     # 1010
                     1011=> { },                                     # 1011
                     1012=> { },                                     # 1012
                     1013=> { },                                     # 1013
                     1014=> { },                                     # 1014
                     1015=> { },                                     # 1015
                     1016=> { },                                     # 1016
                    }


    # 近距離攻撃力増加
    def sword_ap(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:sword_ap] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 近距離ダイス攻撃力増加
    def sword_dice_bonus(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:sword_dice_bonus] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 近距離防御力増加
    def sword_dp(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:sword_dp] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 近距離ダイス防御力増加
    def sword_deffence_dice_bonus(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:sword_deffence_dice_bonus] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end

    # 遠距離攻撃力増加
    def arrow_ap(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:arrow_ap] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 遠距離ダイス増加
    def arrow_dice_bonus(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:arrow_dice_bonus] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 遠距離防御力増加
    def arrow_dp(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:arrow_dp] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end
    # 遠距離ダイス防御力増加
    def arrow_deffence_dice_bonus(ai=:none)
      (WEAPON_EFFECTS[self.weapon_no][:arrow_deffence_dice_bonus] || 0) if WEAPON_EFFECTS[self.weapon_no]
    end

    # 近距離攻撃力
    def combine_sword_ap
      sword_ap
    end
    # 近距離防御力
    def combine_sword_dp
      sword_dp
    end

    # 遠距離攻撃力
    def combine_arrow_ap
      arrow_ap
    end
    # 遠距離防御力
    def combine_arrow_dp
      arrow_dp
    end

    def material_add_param_list
      @material_add_params = CACHE.get("wc_mat_add_prm_#{self.id}")
      unless @material_add_params
        @material_add_params = []
        @material_add_params << param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_SA)
        @material_add_params << param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_SD)
        @material_add_params << param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_AA)
        @material_add_params << param_to_point(self.material_add_param,*MAT_ADD_PARAM_MASK_ADD_AD)
      end
      @material_add_params
    end

    def material_idx_add_param(idx=0)
      list = material_add_param_list
      list[idx]
    end

    WC_MAT_ADD_PRM_SAP_IDX = 0
    WC_MAT_ADD_PRM_SDP_IDX = 1
    WC_MAT_ADD_PRM_AAP_IDX = 2
    WC_MAT_ADD_PRM_ADP_IDX = 3

    def material_add_sap
      material_idx_add_param(WC_MAT_ADD_PRM_SAP_IDX)
    end
    def material_add_sdp
      material_idx_add_param(WC_MAT_ADD_PRM_SDP_IDX)
    end
    def material_add_aap
      material_idx_add_param(WC_MAT_ADD_PRM_AAP_IDX)
    end
    def material_add_adp
      material_idx_add_param(WC_MAT_ADD_PRM_ADP_IDX)
    end

  end

end
