# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # Infectionコラボイベントシリアル
  class InfectionCollaboSerial < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    # 他クラスのアソシエーション
    Sequel::Model.plugin :schema
    STATE_OK = 0             # 未払い
    STATE_DONE = 1           # 支払い済み

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :serial,:index=>true, :unique=>true
      integer     :player_id,:index=>true, :unique=>true
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(InfectionCollaboSerial.table_exists?)
      InfectionCollaboSerial.create_table
    end

    DB.alter_table :infection_collabo_serials do
      add_column :server_type, :integer, :default => 0 unless Unlight::InfectionCollaboSerial.columns.include?(:server_type)  # 新規追加 2016/12/5
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

    # 済んだかどうか
    def done?
      self.state>0
    end

    def self::present_names
      name_list = []
      INFECTION_COLLABO_PRESENTS.each do |item|
        case item[:type]
        when TG_CHARA_CARD
          cc = CharaCard[item[:id]]
          cc_name = cc.name
          if cc.level > 0
            cc_name += ":LV#{cc.level}"
            cc_name += "R" if cc.rarity>5
          end
          cc_name += "×#{item[:num]}" if item[:num] > 1
          name_list.push(cc_name)
        when TG_AVATAR_ITEM
          name = AvatarItem[item[:id]].name
          name += "×#{item[:num]}" if item[:num] > 1
          name_list.push(name)
        when TG_AVATAR_PART
          part_name = AvatarPart[item[:id]].name
          name_list.push(part_name)
        end
      end
      name_list.join("+")
    end

    # 取得可能か
    def self::check(serial,player_id,server_type)
      # 保存用にSerial文字列をコピー（意味がわからん…）
      set_serial = ""
      set_serial += serial.gsub("-","")
      ret = false
      # 同一シリアル、または同一プレイヤーのデータがあるか
      icss = self::filter(Sequel.|({:serial=>set_serial},{:player_id=>player_id})).filter(:server_type=>server_type).all
      # データがない
      if icss.size <= 0
        # Infectionコラボシリアル判定
        if self::check_infection_serial(serial)
          ret = InfectionCollaboSerial.new do |ics|
            ics.serial = set_serial
            ics.player_id = player_id
            ics.server_type = server_type
            ics.save
          end
        end
      end
      ret
    end

    # チェックサムをする値の組み合わせ
    ES_A =[2,6]
    ES_B =[8]
    ES_C = [4,0]

    # でたらめなチェックサムが当たる確率 1/4096
    # チェックサムに使用する基数
    ES_NUM_A = 8
    ES_NUM_B = 11
    ES_NUM_C = 14

    # シャッフルに使うバイト位置
    ES_SHUFFLE_NUM = [2,6]
    # 32回分のシャッフル配列(シャッフル値以外の値を混ぜていく)30までしかつかわねーか。。
    ES_SHUFFLE_SET = [
                   3,9,
                   0,5,
                   11,1,
                   4,12,
                   10,8,
                   4,3,
                   8,7,
                   9,11,
                   10,5,
                   0,12,
                   10,4,
                   12,8,
                   0,5,
                   11,3,
                   7,9,
                   1,0,
                   4,8,
                   9,11,
                   10,3,
                   7,12,
                   11,4,
                   1,5,
                   10,7,
                   9,12,
                   8,3,
                   3,8,
                   0,10,
                   7,12,
                   4,5,
                   9,11,
                   3,11,
                   1,12
                  ]

    def self::create_infection_serial(id_str)
      # check_sum 作成SHA1のHEXのうち最初の40bitを使用する
      s = Digest::SHA1.hexdigest(id_str)
      a_cs = s[ES_A[0]..ES_A[0]+1].hex + s[ES_A[1]..ES_A[1]+1].hex # 2byte目と6byte目を合計
      b_cs = s[(ES_B[0])..ES_B[0]+1].hex # 一個ずらして取る
      c_cs = s[ES_C[0]..ES_C[0]+1].hex + s[ES_C[1]..ES_C[1]+1].hex
      # 8bit x 5 (1/40bit) 1/1099511627776だから1兆分の1で衝突。
      # VVVV VVVV CVVCC <Vはハッシュの値 Cはチェックサム HEXのみ受け付ける。
      # ****-****-*****の形式
      ret = s[0..7] + (a_cs % ES_NUM_A).to_s(16) + s[8..9] + (b_cs % ES_NUM_B).to_s(16) + (c_cs % ES_NUM_C).to_s(16)
      # チェックサムの位置が分からぬようにshuffleする
      num =  s[ES_SHUFFLE_NUM[0]].hex + s[ES_SHUFFLE_NUM[1]].hex
      num.times do |i|
        ret[ES_SHUFFLE_SET[i*2]], ret[ES_SHUFFLE_SET[i*2+1]] = ret[ES_SHUFFLE_SET[i*2+1]], ret[ES_SHUFFLE_SET[i*2]]
      end
      ret = ret[0..3]+ "-" + ret[4..7] + "-" + ret[8..12]
      ret
    end

    # ****_****_*****の形式
    def self::check_infection_serial(s)
      s.gsub!("-","")
      ret = s.length == 13
      ret  = s.hex != 0 if ret # 0の時はじく
      num = ret ? s[ES_SHUFFLE_NUM[0]].hex + s[ES_SHUFFLE_NUM[1]].hex : 0
      (num-1).downto(0) do |i|
        s[ES_SHUFFLE_SET[i*2+1]], s[ES_SHUFFLE_SET[i*2]] = s[ES_SHUFFLE_SET[i*2]], s[ES_SHUFFLE_SET[i*2+1]]
      end
      # 正しく作られているかチェックサムを検証する
      ret = (s[ES_A[0]..ES_A[0]+1].hex + s[ES_A[1]..ES_A[1]+1].hex) % ES_NUM_A ==  s[8].hex if ret
      ret = (s[(ES_B[0]+1)..ES_B[0]+2].hex) % ES_NUM_B == s[11].hex if ret
      ret = (s[ES_C[0]..ES_C[0]+1].hex + s[ES_C[1]..ES_C[1]+1].hex) % ES_NUM_C== s[12].hex if ret
      ret
    end
  end
end
