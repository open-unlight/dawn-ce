# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 台詞を保存するクラス
  class Scenario < Sequel::Model

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, :ignore_exceptions=>true

    attr_reader :command_set, :jump_set
    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :chara_id
      String      :script,:text=>true, :default => ""
      integer     :count
      integer     :priority     # 大きい方から出る。0ででない。
      datetime    :event_start_at
      datetime    :event_end_at
      datetime    :created_at
      datetime    :updated_at

    end

    @@script_str_set =[]
    @@script_set =[]

    # バリデーションの設定
     validates do
     end

   # DBにテーブルをつくる
    if !(Scenario.table_exists?)
      Scenario.create_table
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

    # スクリプトの命令リストを取得する
    def get_script_set
      if @@script_str_set[self.id] != self.script
        eval_script
        p command_set
        @@script_set[self.id] = [@command_set.clone, @jump_set.clone]
        @@script_str_set[self.id] == self.script
      end
      @@script_set[self.id]
    end

    # スクリプトを評価する
    def eval_script
      # コマンドの配列はコマンド名と引数の配列の組み合わせ
      @command_set =[]
      # 飛び先リスト ジャンプラベルとコマンドの配列の位置
      @jump_set ={ }
      num = 0
      self.script.each_line do |s|
        s = s.force_encoding("utf-8")
        s.gsub!("\r","")
        case s
          # ダイアログの場合
        when /^\s*"(.*)"\s*$/
          puts $1
          @command_set << dialogue_to_proc($1.gsub("AVATAR_NAME",'@avatar.name if @avatar'))
          num +=1
          # パネルの場合
        when /^Panel:(.*)\n$/
          set = eval("["+$1+"]")
          @command_set << panel_to_proc(set)
          num +=1
          @command_set <<  stop_to_proc(set)
          num +=1
          # ラベルの場合
        when /^=(.*)$/
          # 終わり
          if $1.size == 0
            @command_set << finish_to_proc
            num +=1
          else
            @jump_set[$1] = num
          end
        when /^FlagCheck:(.*)\n$/
          set = eval("["+$1+"]")
          @command_set << flag_check_to_proc(set)
          num +=1
        when /^FlagSet:(.*)\n$/
          set = eval($1)
          @command_set << flag_set_to_proc(set)
          num +=1
        when /^Jump:(.*)\n$/
          set =  $1.gsub("[", "").gsub("]", "")
          @command_set << jump_to_proc(set)
          num +=1
        when /^GiveItem:(.*)\n$/
          set = eval($1)
          @command_set << give_item_proc(set)
          num += 1
        end
      end
    end

    # ダイアログ文字列を受け取ってProcで返す
    def dialogue_to_proc(txt)
      [:sc_lobby_chara_dialogue, [txt]]
    end

    # パネル表示命令を受け取ってProcで返す
    def panel_to_proc(set)
      str_set = []
      set.each do |s|
        str_set << s[1]
      end
      [:sc_lobby_chara_select_panel,[str_set.join(",")]]
    end

    def stop_to_proc(set)
      str_set = []
      set.each do |s|
        str_set << s[0]
      end
      [:stop, str_set]
    end

    def finish_to_proc
      [:finish_lobby_chara_command_set,[]]
    end

    def flag_check_to_proc(flag)
      [:flag_check_lobby_chara,[flag[0..-2],flag[-1]]]
    end

    def flag_set_to_proc(flag)
      [:flag_set_lobby_chara,flag]
    end

    def jump_to_proc(flag)
      [:jump_lobby_chara,[flag]]
    end

    def give_item_proc(set)
      [:give_item_lobby_chara,[set]]
    end

    def self::get_scenarios(favorite_chara_id)
      ret =  []
      Scenario.filter(:chara_id =>favorite_chara_id).all do |s|
          t = Time.now
        if (s.event_start_at==nil)||s.event_start_at < t && s.event_end_at > t
          ret << s if s.count > 0
        end
      end
      ret
    end
  end
end
