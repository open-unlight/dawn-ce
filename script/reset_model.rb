# モデルを削除する
$LOAD_PATH.unshift(File.join(File.expand_path('.'), 'src'))
require 'pathname'
require 'unlight'
arg = ARGV.shift

class String
  def camelize
    split(/[^a-z0-9]/i).map(&:capitalize).join
  end
end

require "model/#{arg}"

module Unlight
  if eval("#{arg.camelize}.table_exists? # Unlight::CharacterCard.table_exists?", binding, __FILE__, __LINE__)
    col = eval("#{arg.camelize}.columns # Unlight::CharacterCard.columns", binding, __FILE__, __LINE__)
    puts "既存のモデルデータ#{arg}のテーブルをリセットしますか(#{col})(y/n)"
    answer = gets.chomp
    if answer == 'y'
      eval("#{arg.camelize}.create_table! # Unlight::CharacterCard.create_table!", binding, __FILE__, __LINE__)
    end
  else
    puts 'モデルデータが存在しないのでテーブルを作ります'
    eval("#{arg.camelize}.create_table # Unlight::CharacterCard.create_table", binding, __FILE__, __LINE__)
  end
end
