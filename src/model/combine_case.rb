# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 合成条件
  class CombineCase < Sequel::Model
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
      integer     :weapon_card_id, :default =>0, :index=>true      # 追加側の武器ID
      String      :requirement, :default => ""                # 条件（ベース武器条件番号、範囲型、ベース以外番号、範囲型）andとorでつなげられる
      integer     :mod_type, :default => 0                    # 値の変更プログラム番号
      String      :mod_args, :default => ""                   # 値の変更プログラムへの引数
      integer     :limited, :default => 0                     # 排他条件（同じ番号のものには一つしか適用されない）
      integer     :priority, :default => 0                    # 複数選ばれた場合、優先順位の高いものを選ぶ
      integer     :combined_w_id, :default => 0               # 成功したときになる特定の新しい武器番号。0ならば変更なしまたは変プログラム依存
      integer     :pow, :default => 100                       # 成功の確率%
      datetime    :created_at
      datetime    :updated_at
    end

    # requrement 記法括弧はand同じものが複数必要ならなべる必要あり
    # 元武器のIDが1と3〜9,11〜1000{:base =>[1, 3..9, 11..1000]} # 範囲型か数字を並べる
    # 追加素材武器のIDが1001〜1100{:add =[[1001..1100]]} # 範囲型か数字を並べる
    # 追加素材武器のIDが1001〜1100が二つ{:add =[[1001..1100],[1001..1100]]} # 範囲型か数字を並べる

    MOD_LIST = [
                nil,
                :add_point,                # 1 ポイントを固定値上昇(引数 type:Symbol,num:int)
                :add_point_rnd,            # 2 ポイントをランダム上昇(引数 type:Symbol,min:int,max:int)
                :shift_base_point_rnd,     # 3 特定ポイントを他の特定ポイントにランダムで移す(引数 type:Symbol,num:int)
                :shift_add_point_rnd,      # 4 特定ポイントを他の特定ポイントにランダムで移す(引数 type:Symbol,num:int)
                :shift_base_point,         # 5 特定ポイントを他のポイントに移す(引数 from_type:Symbol,to_type:Symbol,num:int)
                :shift_add_point,          # 6 特定ポイントを他のポイントに移す(引数 from_type:Symbol,to_type:Symbol,num:int)
                :set_max,                  # 7 最大合計基本ポイントを特定値にセット(引数 type:Symbol,max:int)
                :set_passive,              # 8 一時パッシブをつけるになる(引数 passive_id:int)
                :change_weapon,            # 9 合成武器になるようパラメータ調整(引数 type:Symbol,num:int)
               ]
    MOD_POINT_BASE_LIST = [ :base_sap,:base_sdp,:base_aap,:base_adp]
    MOD_POINT_ADD_LIST = [ :add_sap,:add_sdp,:add_aap,:add_adp]
    MOD_POINT_LIST = MOD_POINT_ADD_LIST + MOD_POINT_BASE_LIST

    @@condition_base_proc = []
    @@condition_add_proc = []
    @@combine_param = []
    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end

    # DBにテーブルをつくる
    if !(CombineCase.table_exists?)
      CombineCase.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
      # self.condition
      # self.condition
    end

    # アップデート後の後理処
    after_save do
      Unlight::CombineCase::refresh_case_version
      Unlight::CombineCase::cache_store.delete("weapon_card:cond:#{id}")
    end

    # 全体データバージョンを返す
    def CombineCase::case_version
      ret = cache_store.get("CombineCaseVersion")
      unless ret
        ret = refresh_case_version
        cache_store.set("CombineCaseVersion",ret)
      end
      ret
    end

    # 全体データバージョンを更新（管理ツールが使う）
    def CombineCase::refresh_case_version
      m = Unlight::CombineCase.order(:updated_at).last
      if m
        cache_store.set("CombineCaseVersion", m.version)
        m.version
      else
        0
      end
    end

    # バージョン情報(３ヶ月で循環するのでそれ以上クライアント側で保持してはいけない)
    def version
      self.updated_at.to_i % MODEL_CACHE_INT
    end

    # 合成を行う。変更後のweaon_idと変化値をハッシュで返す
    def self::combine(base_id, add_id_list, case_list)
      case_list
      # ベースに適応するかチェック
      ok = { }
      # 排他条件順に集める
      case_list.each do |c|
        if c.check?(base_id,add_id_list)
          ok[c.limited]||=[]
          ok[c.limited] << c
        end
      end
      # 排他の条件から優先度の高いものを選ぶ
      list = { }
      ok.each_value do |o|
        max_priority = 0
        o.each do |c|
          list[c.limited] ||= []
          # 優先順があればそれのみ突っ込む
          if max_priority < c.priority
            list[c.limited] = []
            list[c.limited] << c
            max_priority = c.priority
          elsif max_priority == c.priority
            list[c.limited] << c
          end
        end
      end
      ret = []
      # 排他条件が重なるものが複数あるならば一つ選ぶ()
      list.each do |i,r|
        # 排他0はすべて重複、またはリストが1つならそのまま追加
        if i == 0||r.size < 2
          ret = ret + r
        else
          c = choose_one(r)
        end
        ret << c if c
      end
      get_update_param_hash(ret)
    end

    # 更新パラメータをまとめて返す
    def self::get_update_param_hash(r)
      ret ={ }
      r.each do |cc|
        ret = ret.merge(cc.get_result_combined_param){ |k,old,new|
          # ポイントならば合算してしまう
          if MOD_POINT_LIST.include?(k)
            new + old
          else
            new
          end
        }
      end
      ret
    end

    # 確率の重みから特定の値を引く
    def self::choose_one(set)
      prob = 0
      prob_list = Array.new(set.size){0}
      set.each_with_index do |s,i|
        prob_list[i] = prob
        prob += s.pow
      end
      ret = false
      prob = 100 if prob < 100
      rand = rand(prob)
      prob_list.reverse.each_with_index do |c,i|
        if rand > c
          ret = (prob_list.length-1) - i
          break
        end
      end
      # p set[ret]
      ret ? set[ret] : false
    end

    # 条件が適合するか
    def check?(base_id, add_id_list)
      add_list_used = Array.new(add_id_list.size){ false}
      base_cond = get_condition_base_proc
      add_cond = get_condition_add_proc
      ret  = base_cond.call(base_id)
      if ret
        add_cond.each do |ac|
          add_id_list.each_with_index do |a_id, i |
            ret = false
            r = ac.call(a_id) unless add_list_used[i]
            if r
              add_list_used[i] = true
              ret = r
              break
            end
          end
          break unless ret
        end
      end
      ret ? add_list_used:false
    end

    # 条件を取り出す
    def condition
      ret = CombineCase::cache_store.get("combine_case:cond:#{id}")
      unless ret
        ret ={:base=>[],:add=>[[]] }
        ret = ret.merge(eval(self.requirement.gsub('|',','))) if self.requirement.length > 0
        CombineCase::cache_store.set("combine_case:cond:#{id}", ret)
        @@condition_base_proc[self.id] = nil
        @@condition_add_proc[self.id] = nil
      end
      ret
    end

    def get_range_judge_proc(c)
        if c.class == Range
          Proc.new{ |base| c.include?(base) }
        else
          Proc.new{ |base| c == base }
        end
    end

    # baseアイテムの条件を取り出すことが出来る
    def get_condition_base_proc()
      return @@condition_base_proc[self.id] if @@condition_base_proc[self.id]
      cond_set = []
      condition[:base].each do |c|
        cond_set << get_range_judge_proc(c)
      end
      @@condition_base_proc[self.id] = Proc.new{ |base|
        ret = false
        cond_set.each do |prc|
          r = prc.call(base)
          ret = true if r
        end
        ret = true if cond_set.size == 0
        ret
      }
      @@condition_base_proc[self.id]
    end

    # baseアイテムの条件を取り出すことが出来る
    def get_condition_add_proc()
      return @@condition_add_proc[self.id] if @@condition_add_proc[self.id]
      @@condition_add_proc[self.id] = []
      condition[:add].each do |c|
        set = []
        c.each do |cc|
          set << get_range_judge_proc(cc)
        end
        set << Proc.new{  |base| true } if c.size == 0
        @@condition_add_proc[self.id] << Proc.new{ |base|
          rt = false
          set.each do |prc|
            r = prc.call(base)
            rt = true if r
          end
          rt
        }
      end
      @@condition_add_proc[self.id]
    end

    # 変更パラメータリスト
    def get_result_combined_param
      ret = { }
      ret = self.method(MOD_LIST[self.mod_type]).call(*self.get_mod_args) if self.mod_type > 0
      ret[:new_weapon_id] = self.combined_w_id if self.combined_w_id > 0
      ret
    end

    # mod の引数をとる
    def get_mod_args
      return @@combine_param[self.id] if @@combine_param[self.id]
      ret =[]
      self.mod_args.split("|").each do |c|
        if c[0] == ":"
          ret << c[1..-1].to_sym
        else
          ret << c.to_i
        end
      end
      @@combine_param[self.id] = ret
      ret
    end


    def add_point(t,n)          # 0
      ret ={t => n}
    end

    def add_point_rnd(t, min ,max)      # 1
      ret ={t => rand(max) + min}
    end

    def shift_point_rnd(list,t,n)
      l = list.clone
      l.delete(t)
      ret = {t => -n}
      n.times do |i|
        r = rand(l.size)
        ret[l[r]]||=0
        ret[l[r]]+=1
      end
      ret
    end

    def shift_base_point_rnd(t,n)   # 2
      shift_point_rnd(MOD_POINT_BASE_LIST,t,n)
    end

    def shift_add_point_rnd(t,n)    # 3
      shift_point_rnd(MOD_POINT_ADD_LIST,t,n)
    end

    def shift_base_point(f,t,n)   # 4
      {f => -n,t => n}
    end

    def shift_add_point(f,t,n)   # 5
      shift_base_point(f,t,n)
    end

    def set_max(t,n)    # 6
      ret ={:set => true, t => n}
    end

    def set_passive(n)    # 7
      ret ={:set => true,:passive_id => n}
    end

    def change_weapon(t,n)   # 9
      ret = shift_point_rnd(MOD_POINT_BASE_LIST,t,n) # パラメータが変更されるようシフト
      # 初期値が必要なものをセット
      ret[:base_max] = COMB_BASE_TOTAL_MAX
      ret[:add_max] = COMB_ADD_TOTAL_MAX
      ret
    end


  end





end
