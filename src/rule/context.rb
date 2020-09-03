# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

# コンテキストModule
# イベントの文脈を管理する
# objで保持されてEventのインスタンスが使用する
# :return actの場合ひとつ上にあがる場合
# :suspend goalしておらず、繰り返す場合
# :active 実行中のコンテキスト

module Unlight
  module Context

    # コンストラクタ
    # 親となるオブジェが作る
    def create_context()
      @parent = self
      @current_context = ContextValue.new()
    end

    # コンテクストを共有する
    def share_context(context)
      @current_context = context
    end

    # イベントがスタートするときに呼ばれる
    # 返値はコンテキストチェーンの配列
    def event_start(method)
      # すでにコンテキスト上で実行されているのか？
      # 現在のコンテキストでアクティブなものを探す
      ret = @current_context.assoc(:active)
      # すでにアクティブなものがある場合
      if ret
        # アクティブなものに追加して返す
        ret << [self,self.class.name, method]
        @current_context.check_list_update
        ret
      else
        # アクティブなものがなかればreturn中のものを探す
        ret = @current_context.assoc(:return)
        # return中の場合は
        if ret
          # コンテキストを実行中に変更する
          ret[0] = :active
          ret << [self,self.class.name, method]
          @current_context.check_list_update
          ret
        else
          # returnでもないのなら新規にコンテキストに追加する
          @current_context << [:active, [self, self.class.name, method]]
          @current_context.check_list_update
          @current_context.last
        end
      end
    end

    # イベントがサスペンドするとき呼ばれる
    def event_suspend(list)
      if list[0]==:active ||list[0]==:return
        list[0] = :suspend
      else
        raise "This event is not active. Can't suspend."
      end
      @current_context.check_list_update()
    end

    # イベントが終了するとき呼ばれる
    def event_finish(list,init_method)
      if list[0]==:active||list[0]==:return
        list.pop
        if list.size == 1
          @current_context.delete(list)
          list.clear
          self.send(init_method)
        else
          list[0] =:return
          self.send(init_method)
          s = list[-1].last.to_s + "_action_increment"
          list[-1].first.send(s.to_sym)
          list[-1].first.send(list[-1].last) if @resumed
        end
        @current_context.check_list_update()
      end
    end

    def interrupt_event(method,c)
      ret = @current_context.assoc(:active)
      if ret
        ret << [self,self.class.name, method]
        c = []
        c << ret
        @current_context.check_list_update
      end
    end

    # イベントを再開
    def event_resume
      @resumed = true
      # 親以外レジュームできない
      if @parent == self
        @current_context.clone.each do |e|
          if e[0] == :suspend
            e[0] = :active
            e[-1].first.send(e[-1].last)
          end
        end
      end
      @current_context.delete([])
      @current_context.check_list_update()
      @resumed = false
    end
    # 現在のコンテキストを返す
    def context
      @current_context
    end

    # 実行中のコンテキストのチェック
    # Todo:ここで例外かアラートを出さないとまずい
    def context_check(cond)
      @current_context.check_list =~ /#{cond}/
    end

    # 現在のコンテキストを文字列で返す
    def context_to_s
      @current_context.check_list
    end

  end

class ContextValue < Array
  attr_accessor :check_list

  # コンテキストのチェック用文字列リストを更新する
  def check_list_update()
    @check_list = ""
    self.each do |c|
      a = []
      c[1..-1].each do |f|
        s = ""
        s << f[1].to_s << "::" << f.last.to_s
          a << s
        end
       @check_list << a.join("->")
       @check_list << "\n"
      end
     @check_list
 end

 def to_s
   check_list_update()
   @check_list
 end

end

end
