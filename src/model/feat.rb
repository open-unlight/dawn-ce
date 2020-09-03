# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 必殺技クラス
  class Feat < Sequel::Model
    # 正規表現の組み合わせ一覧
    COND_DIST = [
                 # 遠距離
                 [/^S:/, "owner.distance == 1","近","[1]" ],
                 # 中距離
                 [/^M:/, "owner.distance == 2","中","[2]"],
                 # 遠距離
                 [/^L:/, "owner.distance == 3","遠","[3]" ],
                 # 中遠距離
                 [/(^LM:)|(^ML:)/, "owner.distance != 1","中,遠", "[2, 3]" ],
                 # 近中距離
                 [/(^MS:)|(^SM:)/, "owner.distance != 3","近,中", "[1, 2]" ],
                 # 近遠距離
                 [/(^LS:)|(^SL:)/, "owner.distance != 2","近,遠", "[1, 3]" ],
                 # 全距離
                 [/(^LMS:)|(^MLS:)/, "","近,中,遠", "[1, 2, 3]"]
                ]

    COND_CARD = [
                 # 近距離攻撃で以上
                 [/S([1-9])[+]/, 'owner.greater_check(__FEAT__,ActionCard::SWD,\1)','近\1+', "greater_card,#{ActionCard::SWD},\\1"],
                 # 遠距離攻撃で以上
                 [/A([1-9])[+]/, 'owner.greater_check(__FEAT__,ActionCard::ARW,\1)','遠\1+', "greater_card,#{ActionCard::ARW},\\1"],
                 # 特殊で以上
                 [/E([1-9])[+]/, 'owner.greater_check(__FEAT__,ActionCard::SPC,\1)','特\1+', "greater_card,#{ActionCard::SPC},\\1"],
                 # 防御で以上
                 [/D([1-9])[+]/, 'owner.greater_check(__FEAT__,ActionCard::DEF,\1)','防\1+', "greater_card,#{ActionCard::DEF},\\1"],
                 # 移動で以上
                 [/M([1-9])[+]/, 'owner.greater_check(__FEAT__,ActionCard::MOVE,\1)','移\1+',"greater_card,#{ActionCard::MOVE},\\1"],
                 # カードセットで以上
                 [/(\[([SAEDM]+)\])([1-9])[+]/, 'owner.greater_check_type_set(__FEAT__,"\2",\3)','\1\3+',"greater_card_set,\\1,\\3"],

                 # 近距離攻撃で以上
                 [/S([1-9])[-]/, 'owner.below_check(__FEAT__,ActionCard::SWD,\1)','近\1-', "below_card,#{ActionCard::SWD},\\1"],
                 # 遠距離攻撃で以上
                 [/A([1-9])[-]/, 'owner.below_check(__FEAT__,ActionCard::ARW,\1)','遠\1-', "below_card,#{ActionCard::ARW},\\1"],
                 # 特殊で以上
                 [/E([1-9])[-]/, 'owner.below_check(__FEAT__,ActionCard::SPC,\1)','特\1-', "below_card,#{ActionCard::SPC},\\1"],
                 # 防御で以上
                 [/D([1-9])[-]/, 'owner.below_check(__FEAT__,ActionCard::DEF,\1)','防\1-', "below_card,#{ActionCard::DEF},\\1"],
                 # 移動で以上
                 [/M([1-9])[-]/, 'owner.below_check(__FEAT__,ActionCard::MOVE,\1)','移\1-',"below_card,#{ActionCard::MOVE},\\1"],

                 # 近距離攻撃で特定
                 [/S([1-9])([^+\-*]|\z)/, 'owner.search_check(__FEAT__,ActionCard::SWD,\1)','近\1',"search_card,#{ActionCard::SWD},\\1"],
                 # 遠距離攻撃で特定
                 [/A([1-9])([^+\-*]|\z)/, 'owner.search_check(__FEAT__,ActionCard::ARW,\1)','遠\1',"search_card,#{ActionCard::ARW},\\1" ],
                 # 特殊で特定
                 [/E([1-9])([^+\-*]|\z)/, 'owner.search_check(__FEAT__,ActionCard::SPC,\1)','特\1',"search_card,#{ActionCard::SPC},\\1" ],
                 # 防御で特定
                 [/D([1-9])([^+\-*]|\z)/, 'owner.search_check(__FEAT__,ActionCard::DEF,\1)','防\1',"search_card,#{ActionCard::DEF},\\1"],
                 # 移動で特定
                 [/M([1-9])([^+\-*]|\z)/, 'owner.search_check(__FEAT__,ActionCard::MOVE,\1)','移\1',"search_card,#{ActionCard::MOVE},\\1" ],
                 # ワイルドカードで特定の数値
                 [/W([1-9])([^+\-*]|\z)/, 'owner.search_check_wld_card(__FEAT__,\1)','無\1',"search_wld_card,\\1"],

                 # 近距離攻撃で特定複数枚
                 [/S([1-9])[^+\-]([1-9])/, 'owner.search_check(__FEAT__,ActionCard::SWD,\1,\2)', '近\1 *\2',"search_card,#{ActionCard::SWD},\\1,\\2"],
                 # 遠距離攻撃で特定
                 [/A([1-9])[^+\-]([1-9])/, 'owner.search_check(__FEAT__,ActionCard::ARW,\1,\2)', '遠\1 *\2',"search_card,#{ActionCard::ARW},\\1,\\2"],
                 # 特殊で特定
                 [/E([1-9])[^+\-]([1-9])/, 'owner.search_check(__FEAT__,ActionCard::SPC,\1,\2)', '特\1 *\2',"search_card,#{ActionCard::SPC},\\1,\\2"],
                 # 防御で特定
                 [/D([1-9])[^+\-]([1-9])/, 'owner.search_check(__FEAT__,ActionCard::DEF,\1,\2)', '防\1 *\2',"search_card,#{ActionCard::DEF},\\1,\\2"],
                 # 移動で特定
                 [/M([1-9])[^+\-]([1-9])/, 'owner.search_check(__FEAT__,ActionCard::MOVE,\1,\2)', '移\1 *\2',"search_card,#{ActionCard::MOVE},\\1,\\2"],
                 # ワイルドカードで特定の数値を複数枚
                 [/W([1-9])[^+\-]([1-9])/, 'owner.search_check_wld_card(__FEAT__,\1,\2)','無\1 *\2',"search_wld_card,\\1,\\2"],
                 # ワイルドカード
                 [/W[*]([1-9])/, 'owner.table_count >= \1', '無1+ *\1',"wild_card,\\1"],

                 # 近距離攻撃で０
                 [/S([0])/, '!(owner.greater_check(__FEAT__,ActionCard::SWD,1))','近0',"" ],
                 # 遠距離攻撃で０
                 [/A([0])/, '!(owner.greater_check(__FEAT__,ActionCard::ARW,1))','遠0',"" ],
                 # 特殊で０
                 [/E([0])/, '!(owner.greater_check(__FEAT__,ActionCard::SPC,1))','特0',"" ],
                 # 防御で０
                 [/D([0])/, '!(owner.greater_check(__FEAT__,ActionCard::DEF,1))','防0',"" ],
                 # 移動で０
                 [/M([0])/, '!(owner.greater_check(__FEAT__,ActionCard::MOVE,1))','移0',"" ],

                ]

    COND_PHASE = [
                 # 攻撃、防御、移動のフェイズ分け（キャプションから作り出す）
                 [/攻撃:/, ":attack == phase"],
                 [/防御:/, ":deffence == phase"],
                 [/移動:/, ":move == phase"],

                ]

    WILD_TYPE_AND_CERTAIN_VALUE = 23
    WILD_CARD = 31



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
      String      :name, :index=>true
      integer     :feat_no
      integer     :pow
      String      :dice_attribute, :default=> ""
      String      :effect_image, :default => ""
      String      :caption, :default => ""
      String      :condition, :default => "", :text=>true
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # DBにテーブルをつくる
    if !(Feat.table_exists?)
      Feat.create_table
    end

    DB.alter_table :feats do
      add_column :dice_attribute, :string, :default =>"" unless Unlight::Feat.columns.include?(:dice_attribute) # 新規追加 2014/03/17
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
      Unlight::Feat::refresh_data_version
    end


    # 全体データバージョンを返す
    def Feat::data_version
      ret = cache_store.get("FeatVersion")
      unless ret
        ret = refresh_data_version
        cache_store.set("FeatVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def Feat::refresh_data_version
      m = Unlight::Feat.order(:updated_at).last
      if m
        cache_store.set("FeatVersion", m.version)
        m.version
      else
        0
      end
    end


    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # 条件節の初期化
    def self::initialize_condition_method
      @@condition_set = []
      @@condition_str_set = []
      @@pow_set = []
      @@dice_attribute_set = []
      @@ai_phase_cond_set = []
      @@ai_dist_cond_set = []
      @@ai_card_cond_set = []
      @@ai_anti_card_cond_set = []

      Feat.all.each do |f|
        # 文字列を作る
        cap_str = Feat::condition_str_gen(f.condition)
        # puts cap_str
        @@condition_str_set[f.id] = f.orig_caption.force_encoding("UTF-8").gsub("__CONDITION__", cap_str) if f.orig_caption
        @@condition_str_set[f.id] = @@condition_str_set[f.id].gsub("__POW__", f.pow.to_s) if f.pow.to_s&&@@condition_str_set[f.id]

        # チェック関数を作る
        method_name = "condisin_f#{f.id}"
        @@condition_set[f.id] = method_name.to_sym
        e = <<-EOF
        def self::#{method_name}(owner,range_free=false)
            #{condition_check_gen(f.condition).gsub("__FEAT__",f.feat_no.to_s)}
        end
        EOF
        instance_eval(e)

        # AI用距離チェック関数を作る（Ownerを渡して距離が合致しているか返す）
        method_name = "ai_dist_condition_f#{f.id}"
        @@ai_dist_cond_set[f.id] = method_name.to_sym
        e = <<-EOF
        def self::#{method_name}(range_free=false)
            #{ai_dist_cond_gen(f.condition).gsub("__FEAT__",f.feat_no.to_s)}
        end
        EOF
        instance_eval(e)
        # AI用フェイズチェック関数を作る（）
        method_name = "ai_phase_condition_f#{f.id}"
        @@ai_phase_cond_set[f.id] = method_name.to_sym
        e = <<-EOF
        def self::#{method_name}(phase)
            #{ai_phase_cond_gen(f.orig_caption)}
        end
        EOF
        instance_eval(e)

        # AI用カードチェック関数を作る（Ownerを渡して、持っているカードが条件を満たしていたら番号と表裏、満たしてなければFalseを返す）
        @@ai_card_cond_set[f.id] = []
        @@ai_card_cond_set[f.id] = ai_card_cond_gen(f.condition)

        # POWを作る
        @@pow_set[f.id] = f.pow
        @@dice_attribute_set[f.id] = f.dice_attribute
      end

    end

    # 条件説をプログラムに変換
    def self::condition_check_gen(str)
      s = []
      COND_DIST.each do |e|
        s << e[0].match(str).to_a[0]
        if s[-1]
          s[-1].sub!(e[0],e[1])
          if s[-1].strip.length > 0
            s[-1] = "(range_free || " + s[-1].to_s + ")"
          end
        end
      end

      COND_CARD.each do |e|
        m  = e[0].match(str)
        s << m.to_a[0]
        if s[-1]
          another_wild_cards = (s.size == WILD_CARD+1 && s[WILD_TYPE_AND_CERTAIN_VALUE]) ? 1 : 0
          cond = another_wild_cards > 0 ? e[1] + "+"+another_wild_cards.to_s : e[1]
          s[-1].sub!(e[0],cond)
        end
        while (m&&m.post_match)
          m = e[0].match(m.post_match)
          s << m.to_a[0]
          s[-1].sub!(e[0],e[1]) if s[-1]
        end
      end

      s.delete(nil)
      s.delete("")
      s.join(" && ")
    end

    # AI判定用の距離関数を返す
    def self::ai_dist_cond_gen(str)
      s = []
      COND_DIST.each do |e|
        s << e[0].match(str).to_a[0]
        if s[-1]
          s[-1].sub!(e[0],e[3])
          if s[-1].strip.length > 0 && s[-1] != "[1, 2, 3]"
            s[-1] = "range_free ? [1, 2, 3] : " + s[-1].to_s
          end
        end
      end
      s.delete(nil)
      s.delete("")
      s << "true" if s.size == 0
      s.join("")
    end

    # アクションカードの配列から特定カードを探し出す
    # 返り値は削除済みのカード配列と削除したカードのキーに裏表とそのバリューのハッシュ
    def self::search_card(cards,type,value)
      del = { }
      cards.each do |c|
        r = c.get_exist_value?(type, value)
        if r
          del[c] = r
          break
        end
      end
      del.each do |k,v|
        cards.delete(k)
      end
      [cards,del]
    end

    # アクションカードの配列から特定数値のカードを探し出す
    # 返り値は削除済みのカード配列と削除したカードのキーに裏表とそのバリューのハッシュ
    def self::search_wld_card(cards,value,dummy = 0)
      del = { }
      cards.each do |c|
        r = c.get_exist_wld_card_value?(value)
        if r
          del[c] = r
          break
        end
      end
      del.each do |k,v|
        cards.delete(k)
      end
      [cards,del]
    end

    # アクションカードの配列から特定タイプがValue以上かになるかを
    # 返り値は削除済みのカード配列と削除したカードの配列
    def self::greater_card(cards, type, value)
      del = { }
      cv = 0
      cards.each do |c|
        r = c.get_exist_value?(type)
        if r
          del[c] = r
          cv += r[1]
        end
        if cv >= value
          break
        end
      end
      if cv >= value
        del.each do |k,v|
          cards.delete(k)
        end
      else
        del =  {}
      end
      [cards,del]
    end

    def self::below_card(cards, type, value)
      del = { }
      cv = 0
      cards.each do |c|
        r = c.get_exist_value?(type)
        if r
          if cv + r[1] > value
            break
          end
          del[c] = r
          cv += r[1]
        end
      end
      if cv <= value
        del.each do |k,v|
          cards.delete(k)
        end
      else
        del =  {}
      end
      [cards,del]
    end

    # アクションカードの符号セットから特定タイプがValue以上かになるか
    # 返り値は削除済みのカード配列と削除したカードの配列
    def self::greater_card_set(cards, sign, value)
      del = { }
      return [cards,del] if sign == 0
      cv = 0
      type = nil

      cards.each do |c|

        break if cv >= value

        sign.each_char do |s|
          case s
          when "S"
            type = ActionCard::SWD
          when "A"
            type = ActionCard::ARW
          when "E"
            type = ActionCard::SPC
          when "D"
            type = ActionCard::DEF
          when "M"
            type = ActionCard::MOVE
          else
            type = ActionCard::SWD
          end

          r = c.get_exist_value?(type)
          if r
            del[c] = r
            cv += r[1]
          end

          break if cv >= value
        end
      end

      if cv >= value
        del.each do |k,v|
          cards.delete(k)
        end
      else
        del =  {}
      end

      [cards,del]
    end

    # アクションカードを表す符合(SAEDM)を漢字に変換して返す
    # クライアントでカード裏の表示に使う
    def self::sign_to_string(condition_str)
      dist_str = ""
      ac_str = ""

      if condition_str.include?(":")
        dist_str, ac_str = condition_str.split(":")
      else
        ac_str = condition_str
      end

      if dist_str != ""
        dist_str.gsub!("L", "遠")
        dist_str.gsub!("M", "中")
        dist_str.gsub!("S", "近")
        dist_str += ":"
      end

      ac_str.gsub!("S", "近")
      ac_str.gsub!("A", "遠")
      ac_str.gsub!("E", "特")
      ac_str.gsub!("D", "防")
      ac_str.gsub!("M", "移")
      ac_str.gsub!("W", "無")

      dist_str + ac_str

    end

    # アクションカードの配列からなんでもいいのでそのカードが存在するか？をチェック
    # 返り値は削除済みのカード配列と削除したカードの配列
    def self::wild_card(cards,value, opt)
      del = { }
      cv = 0
      cards.each do |c|
        del[c] = c
        cv += 1
        if cv >= value
          break
        end
      end
      if cv >= value
        del.each do |k,v|
          cards.delete(k)
        end
      else
        del = { }
      end
      [cards,del]
    end


    # 必殺技の条件が機能してるかを返す（失敗はfalse, 成功は元カードと使用するカードの配列）
    def self::ai_card_check(owner, feat_no)
      funcs = @@ai_card_cond_set[feat_no]
      c = owner.cards.clone
      ret = [[],{ }]
      funcs.each do |f|
        func = method(f[0])
        r = func.call(c, f[1], f[2])
        if r[1].size == 0
          ret = false
          break
        end
        c = r[0]
        ret = [r[0],ret[1].merge(r[1])] if ret
      end
      ret
    end

    # 必殺技の条件が機能してるかを返す（失敗はfalse, 成功は元カードと使用するカードの配列）
    def self::ai_dist_check(i, owner)
      method(@@ai_dist_cond_set[i]).call()
    end


    # AI判定用のカード条件を返す
    def self::ai_card_cond_gen(str)
      s = []
      str.delete!("M0","E0","S0","A0")
      COND_CARD.each do |e|
        m  = e[0].match(str)
        s << m.to_a[0]
        s[-1].sub!(e[0],e[3]) if s[-1]&&e[3]

        while (m&&m.post_match)
          m = e[0].match(m.post_match)
          s << m.to_a[0]
          s[-1].sub!(e[0],e[3]) if s[-1]&&e[3]
        end
      end
      s.delete(nil)
      s.delete("")
      ret = []
      s.each_index do |i|
        a = s[i].split(",")
        t = 1
        t = a[3].to_i if a[3]
        t.times do |x|
          ret << []
          ret.last <<  a[0].to_sym
          ret.last <<  a[1].to_i
          ret.last <<  a[2].to_i
        end
      end
      ret
    end

    # 必殺技の条件が機能してるかを返す（失敗はfalse, 成功は元カードと使用するカードの配列）
    def self::ai_phase_check(i,phase)
      method(@@ai_phase_cond_set[i]).call(phase)
    end

    # AI判定用のフェイズ条件を返す
    def self::ai_phase_cond_gen(str)
      s = []
      COND_PHASE.each do |e|
        s << e[0].match(str).to_a[0]
        s[-1].sub!(e[0],e[1]) if s[-1]
      end
      s.join
    end

    # AI判定用のアンチカード条件を返す
    def self::ai_anti_card_cond_gen(str)
    end

    # チェック関数呼び出し（ID,Entrant,DistCheck無効化）
    def self::check_feat(i, owner, range_free=false)
      method(@@condition_set[i]).call(owner, range_free)
    end

    # caption関数を差し替え
    alias :orig_caption :caption
    # initで作ったキャプションを返す
    def caption
      @@condition_str_set[self.id]
    end

    # 条件説を文字列に変換
    def self::condition_str_gen(str)
      ret = []
      COND_DIST.each do |e|
        ret << e[0].match(str).to_a[0]
        ret[-1].sub!(e[0],e[2]) if ret[-1]
      end
      ret.delete(nil)
      ret.delete("")

      s = []
      COND_CARD.each do |e|
        m  = e[0].match(str)
        s << m.to_a[0]
        s[-1].sub!(e[0],e[2]) if s[-1]
        while (m&&m.post_match)
          m = e[0].match(m.post_match)
          s << m.to_a[0]
          s[-1].sub!(e[0],e[2]) if s[-1]
        end
      end
      s.delete(nil)
      s.delete("")
      s.each_index do |i|
        a = /([遠|近|防|移|特|無]\d[+\-]?).*(\d)/.match(s[i]).to_a
        if a&&a[2]
          ar = []
          a[2].to_i.times{ar<<a[1] }
          s[i] = ar.join(",")
        end
      end
      ret2 =s.join(",")
      ret << ret2
      ret.join(":")
    end

    # 実際のPOWを返す
    def self::pow(id)
      @@pow_set[id]
    end

    # 属性を返す
    def self::dice_attribute(id)
      @@dice_attribute_set[id].split(",")
    end

    def get_data_csv_str
      ret = ""
      ret << self.id.to_s.force_encoding("UTF-8") << ","
      ret << '"' << (self.name||"").force_encoding("UTF-8") << '",'
      ret << '"' << (self.effect_image||"").force_encoding("UTF-8") << '",'
      ret << '"' << (self.caption||"").force_encoding("UTF-8") << '"'
      ret
    end

    # 読み込み時に初期化する
    initialize_condition_method
  end

end
