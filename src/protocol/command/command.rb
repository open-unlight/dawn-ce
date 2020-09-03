# -*- coding: utf-8 -*-
# 通信コマンド生成クラス
# サーバごとの受信・送信コマンドを動的に生成する
require "zlib"
module Unlight
  class Command
    OUTPUT_EVAL = false         # Evalの内容を出力する
    attr_reader :method_list
    # コンストラクタ（Cはコマンドを追加するクラス）
    def initialize(c,type)
      @klass = c
      @cmd_val = Struct.new(:name, :type, :size)
      @method_list = []
      #      p type
      # サーバータイプによって生成するコマンドを切り換える
      case type
      when :Auth
        require 'protocol/command/authcommand'
      when :Lobby
        require 'protocol/command/lobbycommand'
      when :Chat
        require 'protocol/command/chatcommand'
      when :Game
        require 'protocol/command/gamecommand'
      when :Quest
        require 'protocol/command/questcommand'
      when :Match
        require 'protocol/command/matchcommand'
      when :Data
        require 'protocol/command/datacommand'
      when :Watch
        require 'protocol/command/watchcommand'
      when :Raid
        require 'protocol/command/raidcommand'
      when :RaidChat
        require 'protocol/command/raidchatcommand'
      when :RaidData
        require 'protocol/command/raiddatacommand'
      when :RaidRank
        require 'protocol/command/raidrankcommand'
      when :GlobalChat
        require 'protocol/command/globalchatcommand'
      end
      init_receive(RECEIVE_COMMANDS)
      init_send(SEND_COMMANDS)
    end

    # 受信コマンドの初期化
    def init_receive(cmd)
      cmd.each do |c|
        n = c[0].id2name+"_r"
        @method_list << n.intern
        ret = <<-EOF
          def #{n}(data)
           # p data
#{gen_receve_cmd(c[1],c[0])} 
          end
          EOF
      puts ret if OUTPUT_EVAL
       @klass.class_eval(ret)
      end
   end

    # 受信コマンドの中身の文字列を生成する
    def gen_receve_cmd(val, name)
      ret = ''
      pos = 0
      s = ''
      q = ''
      if val
        val.each do|i|
          c = @cmd_val.new(i[0], i[1],i[2])
          if c.size == 0
            ret << "            #{c.name}_len = data[#{s unless s==""}#{pos},2].unpack('n*')[0]\n"
#            ret << "p data[#{pos},2]\n"
            pos += 2
#            ret << "p #{c.name}_len\n"
            ret << "            #{c.name} = data[#{s unless s==""}#{pos},#{c.name}_len]#{type_rec_res(c.type)}\n"
            s << "#{c.name}_len+"
          else
            ret << "            #{c.name} = data[#{s unless s==""}#{pos},#{c.size}]#{type_rec_res(c.type)}\n"
            pos += c.size
          end
          q << c.name+","
        end
      end
      ret << "            #{name}(#{q.chop!})"
      ret
    end
    private :gen_receve_cmd

    # 型によって返す変換する文字列を返す
    def type_rec_res(t)
      case t
      when :String
        ""
      when :int
        ".unpack('N')[0]"
      when :char
        ".unpack('c')[0]"
      when :Boolean
        ".unpack('C')[0]==0? false:true"
       end
    end
    private :type_rec_res

    # 送信コマンドの初期化
    def init_send(cmd)
      cmd.each_index do |i|
        n = cmd[i][0].id2name
        ret = <<-EOF
          def #{n}(#{gen_arg(cmd[i][1])})
#            puts "#{n}が実行されました#{i}"
            data =""
            data << [#{i}].pack('n')
#{gen_send_cmd(cmd[i][1],cmd[i][2])}
            send_data(data)
          end
          EOF
          puts ret if OUTPUT_EVAL
       @klass.class_eval(ret)
      end

    end

    # 引数を生成して返す
    def gen_arg(val)
      ret =''
      if val
        val.each do |v|
          ret << v[0]
          ret << ","
        end
        ret.chop!
      end
      ret
    end

    # 送信コマンドの中身の文字列を生成
    def gen_send_cmd(val,comp)
      ret = ''
      d= "data"
      if comp
        d = "data2"
        ret <<     "            data2 = \"\"\n"
      end
      
      if val
        val.each do|i|
          c = @cmd_val.new(i[0], i[1], i[2])
          if c.size == 0&&c.type !=:int
            ret << "            #{d} << [#{c.name}.bytesize].pack('N')\n"
          end
          ret << ( "            #{c.name}.force_encoding"+'("ASCII-8BIT")'+"\n") if c.type ==:String
          ret <<   "            #{d} << #{type_send_res(c.type, c.name)}\n"
        end
      end

      if comp
#        ret << "            data2 = Zlib::Deflate.deflate(data2,Zlib::BEST_SPEED)\n"
        ret << "            data2 = Zlib::Deflate.deflate(data2)\n"
        ret << "            data << data2\n"
      end
#      puts ret
      ret
    end
    private :gen_receve_cmd

    # 型によって返す変換する文字列を返す
    def type_send_res(t,v)
      case t
      when :String
        v
      when :int
        "[#{v}].pack('N')"
      when :char
        "[#{v}].pack('c')"
      when :Boolean
        "[#{v}.to_i].pack('C')"
      end
    end
    private :type_send_res
  end
end

class TrueClass
  def to_i
    1
  end
end

class FalseClass
  def to_i
    0
  end
end

class NilClass
  def to_i
    0
  end
end
