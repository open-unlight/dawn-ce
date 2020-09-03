$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
$arg = ARGV.shift

module Unlight

  puts "すべてのセール期限をｈ時間のばす(y/n)"
  answer = gets.chomp
  if answer == "y"
    puts "何時間延ばしますか?（数字）"
    answer = gets.chomp
    if answer
      num = answer.to_i
      puts "#{num.to_i}時間伸ばします"
      yday = Date.today - 1
      st = Time.utc(yday.year, yday.month, yday.day)
      # 昨日以降に消えるはずのend_atを抽出
      set = Avatar.filter{sale_limit_at > st }.all
      puts set.size
      s = 0
      set.each do |pi|
        s+=1
        puts pi.id
        pi.sale_limit_at = pi.sale_limit_at + 60*60*num.to_i
        pi.sale_limit_at
        pi.save_changes
      end
    end
    puts "size is #{s}"
  end

  puts "すべての時限パーツの期限をｈ時間のばす(y/n)"
  answer = gets.chomp

  if answer == "y"
    puts "何時間延ばしますか?（数字）"
    answer = gets.chomp
    if answer
      num = answer.to_i
      puts "#{num.to_s}時間伸ばします"
      yday = Date.today - 1
      st = Time.utc(yday.year, yday.month, yday.day)
      # 昨日以降に消えるはずのend_atを抽出
      PartInventory.filter{end_at > st }.all.each do |pi|
        pi.end_at = pi.end_at+60*60*num
        pi.save_changes
      end
    end
  end

  puts "すべての渦の期限をｈ時間のばす(y/n)"
  answer = gets.chomp

  if answer == "y"
    puts "何時間延ばしますか?（数字）"
    answer = gets.chomp
    if answer
      num = answer.to_i
      puts "#{num.to_s}時間伸ばします"
      yday = Date.today - 1
      st = Time.utc(yday.year, yday.month, yday.day)
      # 昨日以降に消えるはずのend_atを抽出
      Profound.filter{close_at > st }.all.each do |p|
        p.close_at = p.close_at+60*60*num
        p.save_changes
      end
    end
  end

end
