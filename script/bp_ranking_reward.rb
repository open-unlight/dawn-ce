# モデルを削除する
$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
$arg = ARGV.shift

module Unlight

  SV_TYPE_STR = ["sb"]
  puts "#{SV_TYPE_STR[THIS_SERVER]}サーバへ報酬を配布します。(y/n)"
  sns_check = gets.chomp
  fin = true
  if sns_check == "y" || sns_check == "Y" || sns_check == "yes" || sns_check == "Yes"
    fin = false
  end
  exit() if fin

  # ランキング上位者に対する報酬
  puts "BPランキング報酬の対象となる最低順位を入力してください(JP3/TCN30/SCN10)"
  top = gets.chomp
  puts "BPランキング上位者#{top}名に付与する装備アイテムのIDを入力してください"
  val = gets.chomp
  puts "BPランキング上位者#{top}名に装備id#{val}を与えます(y/n)"
  answer = gets.chomp
  if answer == "y"
    b = Avatar.filter(:server_type=>THIS_SERVER).order(Sequel.desc(:point)).limit(top).all.last.point
    puts "#{top}位のBP #{b}"
    ret = Avatar.filter{point >= b}.filter(:server_type=>THIS_SERVER).all
    ret.each do |a|
      puts "id:#{a.id}"
      a.get_slot_card(SCT_WEAPON, val)
    end
    p ret.size
  end

  # ランキング上位者に対する報酬
  puts "追加報酬の配付ランクの区切りを入力してください"
  puts "Format例：[1位～10位、11位～20位] => [10,20]"
  rank_list_str = gets.chomp
  puts "報酬内容を入力してください"
  puts "Format例：[1位～{5005魔の刀身2個+チケット2枚}、11位～{10021虚栄かけら1個}] => [2/5005/2/0-3/9/2/0,1/10021/1/0]"
  rew_list_str = gets.chomp
  puts "[#{rank_list_str}]の順位毎ににそれぞれ[#{rew_list_str}]を配付しますか？"
  answer = gets.chomp
  if answer == "y"
    ranks = []
    rewards = []

    rank_list_str.split(",").each do |rank_str|
      ranks << rank_str.to_i
    end
    rew_list_str.split(",").each do |rew_list_arr|
      rew_list = []
      rew_list_arr.split("-").each do |rew_str|
        rew_arr = rew_str.split("/")
        rew = { }
        rew[:type] = rew_arr.shift.to_i
        rew[:id] = rew_arr.shift.to_i
        rew[:num] = rew_arr.shift.to_i
        rew[:sct_type] = rew_arr.shift.to_i
        rew_list << rew
      end
      rewards << rew_list
    end

    # 上限は最初絶対こえない値
    upper = 10000000000
    ranks.each do |rank|
      puts "上限 #{upper}"
      b = Avatar.filter(:server_type=>THIS_SERVER).order(Sequel.desc(:point)).limit(rank).all.last.point
      puts "#{rank}位のBP #{b}"
      ret = Avatar.filter{ point < upper }.filter{ point >= b}.filter(:server_type=>THIS_SERVER).order(Sequel.desc(:point)).all
      rew_list = rewards.shift
      p rew_list
      ret.each do |a|
        puts "id:#{a.id} point:#{a.point}"
        rew_list.each do |rew|
          a.get_treasures(rew[:type],rew[:id],rew[:sct_type],rew[:num])
        end
      end
      p ret.size
      upper = b
    end

  end


  # BP1800以上対象者に対する報酬
  puts "BP1800以上の対象者に冥府の印章を与えます(y/n)"
  answer = gets.chomp
  if answer == "y"
    Avatar.filter{point >= 1800}.filter(:server_type=>THIS_SERVER).all.each do |a|
      puts "id:#{a.id}"
      a.get_chara_card(10011)
    end
  end

  # BPをリセット
  puts "全てのアバターのBPをリセットします(y/n)"
  answer = gets.chomp
  if answer == "y"
    Avatar.filter{point != 1500}.filter(:server_type=>THIS_SERVER).all.each do |a|
      a.point = 1500
      a.save_changes
    end
  end

  # ランキングをリセット
  puts "総合ランキングをリセットします(y/n)(!!! ヤバゲ・ニコはあとに回す方のみで実行 !!!)"
  answer = gets.chomp
  if answer == "y"
    TotalDuelRanking.filter{point != 1500}.all.each do |a|
      a.point = 1500
      a.save_changes
    end
  end

end
