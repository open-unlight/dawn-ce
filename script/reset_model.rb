# モデルを削除する
$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
$arg = ARGV.shift
puts $arg
  class String
      def camelize
          self.split(/[^a-z0-9]/i).map{ |w| w.capitalize}.join
      end
  end

require "model/#{$arg}"

module Unlight

  if eval("#{$arg.camelize}.table_exists?")
    col = eval ("#{$arg.camelize}.columns")
    puts "既存のモデルデータ#{$arg}のテーブルをリセットしますか(#{col})(y/n)"
    answer = gets.chomp
    if answer == "y"
      eval ("#{$arg.camelize}.create_table!")
    end
  else
    puts "モデルデータが存在しないのでテーブルを作ります"
    eval ("#{$arg.camelize}.create_table")
  end

end
