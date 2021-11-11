# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'singleton'
require 'erb'

module Unlight
  EVAL_OUTPUT = false

  #
  # Eventの基礎クラス
  #
  # ルールからrequireされる
  # ゴール条件（終了条件の記述のみ）
  # よみこんだらゴール条件のオブジェを登録しなけらばならない
  #
  # イベント定義
  # dsc:
  #   説明文
  #     "説明"
  # context:*
  #   実行可能な文脈 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
  #     obj, event, ...
  # guard:*
  #   実行条件 （登録した条件の一つでも合致すれば実行）。指定なければ必ず実行。
  #   ["reciver",:method],...<-配列すべてがTrueの時のみTrue
  # goal:*
  #   終了条件 （登録した条件の一つでも成功すれば成功）。指定なければ必ず終了。Hookの場合は逆に終了しない。
  #   ["reciver",:method],...<-配列すべてがTrueの時のみTrue
  # type:
  #   関数はいつ実行されるのか
  #   直ちに実行           type=>:instant < default
  #   なにかの前に行われる type=>:before, :obj=>"reciver", :hook=>:method ,:priority =>0
  #   なにかの後に行われ   type=>:after, :obj=>"reciver", :hook=>:method,:priority =>0
  #   なにかを置き換える   type=>:proxy, :obj=>"reciver", :hook=>:method
  #   (priorityは値の低い順に実行される。使用可能なのは整数のみ)
  # duration:
  #   終了しない場合どれくらい続くか？(Hook系のイベントには使用できない)
  #   終わらない       :none <default
  #   複数回           type=>:times, value=>x
  #   秒               type=>:sec, value=>x
  # event: (Hook系のイベントには使用できない)
  #   イベントを発行するか？
  #   実行前     :start
  #   実行後     :finish
  #   発行しない :< default
  # func:
  #   実行関数（hookする関数）
  # act:
  #   追加実行されるイベント
  #========== Todo ================
  # 通信する場合の返値?
  # sync:
  #   なし             :none <Default
  #   する             [:type](返値の型)
  #

  class EventRule
    include Singleton

    attr_accessor :dsc, :allow_context, :func, :act_list, :goal_list, :guard_list, :type, :hook_func, :duration_type, :duration_value, :event_type

    def initialize
      # イベントの説明
      @dsc = ''
      # 実行可能コンテキスト
      @allow_context = []
      # ガード節のリスト
      @guard_list = []
      # ゴール節のリスト
      @goal_list = []
      # 追加実行関数
      @act_list = []
      # タイプ
      @type = :instant
      # フックする対象の関数名
      @hook_func = []
      # 関数
      @func = ''
      # Goalしない場合どこまでのタイムアウト
      @duration_type = :none
      @duration_value = 0
      # イベントタイプ
      @event_type = { start: false, finish: false }
    end

    # イベント定義の名前を登録
    def self.dsc(name)
      instance.dsc = name
    end

    # イベントとしてHookするメインの関数
    def self.func(f)
      instance.func = f
    end

    # ハンドラのメソッド名
    def self.func_name
      instance.func.to_s
    end

    # hook_funcの名称
    def self.hook_func_name
      "#{instance.hook_func[0]}.#{instance.hook_func[1]}_#{instance.type}_hook_func"
    end

    def self.dispose
      instance.func = nil
    end

    # 許可するコンテキストを登録
    def self.context(*cont)
      s = []
      cont.each do |a|
        s << "Unlight::#{a[0]}::#{a[1]}"
      end
      instance.allow_context << s.join('->')
    end

    # タイプの登録
    def self.type(t)
      t = { type: t, obj: nil, hook: nil, priority: 0 } if t.instance_of?(Symbol)
      pri = t[:priority] || 0
      instance.type = t[:type]
      instance.hook_func = [t[:obj], t[:hook], pri]
    end

    # タイムアウトの登録
    def self.duration(t)
      t = { type: t, value: 0 } if t.instance_of?(Symbol)
      instance.duration_type = t[:type]
      instance.duration_value = t[:value]
    end

    # イベントの登録
    def self.event(*arg)
      arg.each do |a|
        instance.event_type[:start] = true if a == :start
        instance.event_type[:finish] = true if a == :finish
      end
    end

    # ゴールの設定
    def self.goal(*args)
      add_decision(instance.goal_list, args)
    end

    # ガードの設定
    def self.guard(*args)
      add_decision(instance.guard_list, args)
    end

    # 追加実行関数
    def self.act(func)
      instance.act_list << func
    end

    # ガードとゴール関数登録関数
    def self.add_decision(list, args)
      ret = []
      args.each do |a|
        ret << a
      end
      list << ret unless ret == []
    end

    # イベントの説明
    def self.describe
      instance.dsc
    end

    # オブジェクトが含まれているか？
    def self.obj_list_include?(list, arg)
      list.index { |item| item[0].to_s == arg.to_s }
    end

    # クラスにインスタンスメソッドが存在するか？
    def self.instance_method_include?(klass_name, method_name)
      eval("Unlight::#{klass_name}.instance_methods.include?(:#{method_name}) # Unlight::OneToOneAi.instance_methods.include?(:desc)", binding, __FILE__, __LINE__)
    end
  end

  #= 実際のイベントオブジェ
  # ルールと結びついてバインドされたオブジェを保存する
  class BaseEvent
    include Context
    # 初期化メソッドのリスト
    @@init_list = {}
    # イベント削除メソッドのリスト
    @@event_removers = {}
    # Hook削除メソッドのリスト
    @@hook_removers = {}

    def self.init_list
      @@init_list
    end

    def initialize(*_args)
      # フックするイベントの初期化
      @@init_list[self.class.name].each { |a| send(a) } if @@init_list[self.class.name]
    end

    # フックされた関数を実行する
    def send_all_hook(list)
      li = list.clone
      all_end = true
      while all_end
        li.each_index do |i|
          li[i][0].call
          if li.size == list.size
            all_end = false if i + 1 == li.size
          else
            li = list.clone
            break
          end
        end
        all_end = false if li.empty?
      end
    end

    # 関数の実行
    def func_do(dist, func)
      dist_get(dist).send(func)
    end

    # 文字列からレシーバを返す
    def dist_get(dist)
      if dist == 'self'
        self
      else
        send(dist.to_sym)
      end
    end

    # 登録されたすべてのイベントをリムーブする
    def remove_all_event_listener
      @@event_removers[self.class.name].each { |a| send(a) } if @@event_removers[self.class.name]
    end

    # 登録されたすべてのイベントをフックをリムーブする
    def remove_all_hook
      @@hook_removers[self.class.name].each { |a| send(a) } if @@hook_removers[self.class.name]
    end

    # ゴールしたかをしらべる
    def list_check?(list)
      # 一つのまとまりとしてGoalを処理、すべてTRUEでなければTrueでない。
      ret = true
      list.each do |b|
        ret = true
        b.each do |c|
          unless  func_do(c[0], c[1]) # 一つでもfalseなら評価をやめる
            ret = false
            break
          end
        end
        break if ret # 一つでもtrueならば評価をやめる
      end
      ret
    end

    # 初期化部分を返す
    def self.init_gen
      <<~DSL
        # 初化期
              a = Module.nesting[0].to_s
              #　初期化リストのメソッドを登録
              @@init_list[a]||=[]
              @@init_list[a] << :#{@f}_init

              #　イベントのリムーバのメソッドを登録
              @@event_removers[a]||=[]
              @@event_removers[a] << :remove_listener_all_#{@f}

              #　イベントのリムーバのメソッドを登録
              @@hook_removers[a]||=[]
              @@hook_removers[a] << :remove_hook_all_#{@f}


              attr_accessor :#{@f}_before_hook_func, :#{@f}_after_hook_func, :#{@f}_proxy_func, :#{@f}_counter

              def #{@f}_init
                @#{@f}_context = []
                @#{@f}_before_hook_func = [] unless @#{@f}_before_hook_func
                @#{@f}_after_hook_func = [] unless @#{@f}_after_hook_func
                @#{@f}_proxy_func
                # スタートイベントを再設定する
                @#{@f}_start_event_handlers = [] unless  @#{@f}_start_event_handlers
                @#{@f}_start_event_handlers += @#{@f}_start_event_done_handlers if @#{@f}_start_event_done_handlers
                @#{@f}_start_event_handlers.uniq!
                @#{@f}_start_event_done_handlers = []
                # フィニッシュイベントを再設定
                @#{@f}_finish_event_handlers = [] unless @#{@f}_finish_event_handlers
                @#{@f}_counter = 0
                @#{@f}_timer = nil
                @#{@f}_act_counter = 0
              end

              def add_start_listener_#{@f}(m)
                @#{@f}_start_event_handlers||= []
                @#{@f}_start_event_handlers << m
              end

              def remove_start_listener_#{@f}(m)
                @#{@f}_start_event_handlers.delete(m)
              end

              def add_finish_listener_#{@f}(m)
                @#{@f}_finish_event_handlers||=[]
                @#{@f}_finish_event_handlers << m
              end

              def remove_finish_listener_#{@f}(m)
                @#{@f}_finish_event_handlers.delete(m)
              end

              def remove_listener_all_#{@f}
                @#{@f}_start_event_handlers.clear
                @#{@f}_start_event_done_handlers.clear
                @#{@f}_finish_event_handlers.clear
              end

              def remove_hook_all_#{@f}
        #        SERVER_LOG.info("BASE EVENT: ALL MOVE#{self} ");
                @#{@f}_before_hook_func =[]
                @#{@f}_after_hook_func = []
                @#{@f}_proxy_func =nil
              end

              def #{@f}_action_increment
                @#{@f}_act_counter +=1
              end

              def #{@f}_start_event_do
                # Start Eventの発行
                while @#{@f}_start_event_handlers.size > 0
                  m = @#{@f}_start_event_handlers.shift
                  m.call(self)
                  @#{@f}_start_event_done_handlers.push(m)
                end
              end

      DSL
    end

    # コンテキストチェック部分を返す
    def self.context_check_gen(doc)
      unless @event_rule.allow_context.empty?
        c = @event_rule.allow_context.map { |a| "context_check(\"#{a}\")" }.join('||')
        st = "if #{c}\n"
        en = "\n          else\n"
        en += '          end'
        doc = st + doc + en
      end
      doc
    end

    # 開始条件チェック部分を返す
    def self.guard_check_gen(doc)
      st = ''
      st += "guarded = false\n"
      en = ''
      unless @event_rule.guard_list.empty?
        c = @event_rule.guard_list.to_s
        st += "if list_check?(#{c})\n"
        en = "\n else\n"
        en += "          @#{@f}_context = event_start(:#{@f}) if @#{@f}_context == []\n"
        en += "          guarded = true\n"
        en += "          end\n"
      end
      doc = st + doc + en
      doc + goal_check_gen
    end

    # 終了条件チェック部分を返す
    def self.goal_check_gen
      if @event_rule.type == :instant
        if @event_rule.goal_list.empty?
          <<-DSL
        if (@#{@f}_context[0] == :active||@#{@f}_context.first == :return)&&(@#{@f}_context.last == nil ||@#{@f}_context.last.last == :#{@f})
            #{finish_event_gen}
            event_finish(@#{@f}_context,:#{@f}_init)
            #{@f}_init
        end
          DSL
        else
          c = @event_rule.goal_list.to_s
          <<~DSL
            # もしコンテキストが実行中でかつこのイベントが最後ならばイベントを終了する
                    if (@#{@f}_context.first == :active||@#{@f}_context.first == :return)&&(@#{@f}_context.last == nil ||@#{@f}_context.last.last == :#{@f})
                      if list_check?(#{c})#{duration_result_gen}
                       #{finish_event_gen}
                        event_finish(@#{@f}_context,:#{@f}_init)
                     else
                        @#{@f}_act_counter = 0
                        event_suspend(@#{@f}_context)
                      end

                    end
          DSL

        end
      else
        "\n"
      end
    end

    def self.finish_event_gen
      if @event_rule.event_type[:finish]
        <<-DSL
            @#{@f}_finish_event_handlers.each {|i| i.call(self, ret)}  unless guarded
        DSL
      end
    end

    def self.start_event_gen
      if @event_rule.event_type[:start]
        <<-DSL
        #{@f}_start_event_do
        DSL
      end
    end

    def self.type_main_gen
      case @event_rule.type
      when :instant
        instant_main_gen
      when :before
        before_main_gen
      when :after
        after_main_gen
      when :proxy
        proxy_main_gen
      end
    end

    # メイン実行部分を返す
    def self.instant_main_gen
      <<-DSL
          @#{@f}_context = event_start(:#{@f}) if @#{@f}_context == []
          if @#{@f}_context.first == :active
            #{start_event_gen}
            #{duration_check_gen}
            # Instantの場合
            send_all_hook(@#{@f}_before_hook_func)
            if #{@f}_proxy_func
              ret = #{@f}_proxy_func.call(*arg)
            else
              ret = #{@event_rule.func}(*arg)
            end
            send_all_hook(@#{@f}_after_hook_func)
          end
            #{act_list_gen}
      DSL
    end

    def self.act_list_gen
      ret = []
      ret << ' '
      ret << "      if @#{@f}_context.first == :active||@#{@f}_context.first == :return"
      @event_rule.act_list.each_index do |i|
        ret << "          if @#{@f}_act_counter == #{i}"
        ret << "            self.send(:#{@event_rule.act_list[i]})"
        ret << "            @#{@f}_act_counter +=1 if @#{@f}_context.first == :active"
        ret << '          end'
      end
      ret << '       end'
      ret = [] if @event_rule.act_list.empty?
      ret.join("\n")
    end

    def self.before_main_gen
      h = @event_rule.hook_func
      <<-DSL

        #{start_event_gen}
        ret = nil

        unless  #{h[0]}.#{h[1]}_before_hook_func.include?([method(:#{@event_rule.func}),#{h[2]}])
          #{h[0]}.#{h[1]}_before_hook_func.unshift([method(:#{@event_rule.func}),#{h[2]}])
        end

        #{h[0]}.#{h[1]}_before_hook_func.sort!{|a,b| a[1]<=>b[1]}
        #{hook_add_remove_gen}
      DSL
    end

    def self.after_main_gen
      h = @event_rule.hook_func
      <<-DSL

        #{start_event_gen}
        ret = nil
        unless #{h[0]}.#{h[1]}_after_hook_func.include?([method(:#{@event_rule.func}), #{h[2]}])
          #{h[0]}.#{h[1]}_after_hook_func << [method(:#{@event_rule.func}), #{h[2]}]
        end

        #{h[0]}.#{h[1]}_after_hook_func.sort!{|a,b| a[1]<=>b[1]}
        #{hook_add_remove_gen}
      DSL
    end

    def self.proxy_main_gen
      h = @event_rule.hook_func
      <<-DSL

            #{start_event_gen}
        ret = nil
        #{h[0]}.#{h[1]}_proxy_func = method(:#{@event_rule.func})
        #{hook_add_remove_gen}
      DSL
    end

    def self.hook_add_remove_gen
      h = @event_rule.hook_func
      unless @event_rule.goal_list.empty?
        case @event_rule.type
        when :before
          <<-DSL
        #{h[0]}.#{h[1]}_before_hook_func.unshift([method(:remove_before_hook_#{@f}),-1])
          DSL
        when :after
          <<-DSL

        #{h[0]}.#{h[1]}_before_hook_func.unshift([method(:remove_after_hook_#{@f}),-1])
          DSL
        when :proxy
          <<-DSL

        #{h[0]}.#{h[1]}_before_hook_func.unshift([method(:remove_proxy_hook_#{@f}),-1])
          DSL
        end
      end
    end

    def self.hook_remove_gen
      unless @event_rule.goal_list.empty?
        case @event_rule.type
        when :before
          before_remove_gen
        when :after
          after_remove_gen
        when :proxy
          proxy_remove_gen
        end
      end
    end

    def self.before_remove_gen
      h = @event_rule.hook_func
      c = @event_rule.goal_list
      <<-DSL
        def remove_before_hook_#{@f}
          if list_check?(#{c})
           #{finish_event_gen}
           #{h[0]}.#{h[1]}_before_hook_func.delete([method(:#{@event_rule.func}), #{h[2]}])
           #{@f}_init
           #{h[0]}.#{h[1]}_before_hook_func.delete([method(:remove_before_hook_#{@f}), -1])
          end
        end
      DSL
    end

    def self.after_remove_gen
      h = @event_rule.hook_func
      c = @event_rule.goal_list
      <<-DSL
        def remove_after_hook_#{@f}
          if list_check?(#{c})
          #{finish_event_gen}
           #{h[0]}.#{h[1]}_after_hook_func.delete([method(:#{@event_rule.func}), #{h[2]}])
          #{@f}_init
           #{h[0]}.#{h[1]}_before_hook_func.delete([method(:remove_after_hook_#{@f}), -1])
          end
        end
      DSL
    end

    def self.proxy_remove_gen
      h = @event_rule.hook_func
      c = @event_rule.goal_list
      <<-DSL

        def remove_proxy_hook_#{@f}
          if list_check?(#{c})
           #{finish_event_gen}
           #{h[0]}.#{h[1]}_proxy_func = nil
           #{@f}_init
           #{h[0]}.#{h[1]}_before_hook_func.delete([method(:remove_proxy_hook_#{@f}), -1])
          end
        end
      DSL
    end

    def self.duration_result_gen
      case @event_rule.duration_type
      when :times
        <<~DSL
          || (@#{@f}_counter >= #{@event_rule.duration_value})
        DSL
      when :sec
        <<~DSL
          ||(Time.now-(@#{@f}_timer|| @#{@f}_timer =Time.now)>#{@event_rule.duration_value})
        DSL
      end
    end

    def self.duration_check_gen
      case @event_rule.duration_type
      when :times
        <<-DSL
        @#{@f}_counter += 1
        DSL
      when :sec
        <<-DSL
        @#{@f}_timer || @#{@f}_timer =Time.now
        DSL
      end
    end

    def self.regist_event(eventrule)
      @event_rule = eventrule.instance
      @f = underscore(eventrule.to_s.gsub(/Unlight::|.*::/, ''))
      doc = <<-DSL
      #{init_gen}

      def #{@f}(*arg)
        #{context_check_gen(guard_check_gen(type_main_gen))}
        ret
      end

      #{hook_remove_gen}
      DSL
      module_eval doc
      @event_rule = nil
      EventRule.dispose
    end

    def self.underscore(camel_cased_word)
      camel_cased_word
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end
  end
end

__END__
