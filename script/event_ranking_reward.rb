$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
$arg = ARGV.shift

module Unlight

  REWARD_TYPE_STR = ["none","消費アイテム","アバター衣装","キャラカード","装備カード","イベントカード"]

  puts "イベントランキングを更新します（y/n）"
  answer = gets.chomp
  if answer == "y"
    TotalEventRanking::start_up
  end

  while true
    puts "イベントランキング報酬の対象となる最高順位を入力してください(1～)"
    max = gets.chomp
    puts "イベントランキング報酬の対象となる最低順位を入力してください(10000～)"
    min = gets.chomp
    puts "イベントランキング#{max}位から#{min}位に与える報酬のタイプを選んでください(1:消費アイテム/2:アバター衣装/3:キャラカード/4:装備カード/5:イベントカード)"
    t = gets.chomp.to_i
    puts "イベントランキング#{max}位から#{min}位に与える報酬のIDを選んでください"
    i = gets.chomp.to_i
    puts "イベントランキング#{max}位から#{min}位に#{REWARD_TYPE_STR[t]}ID:#{i}を与えます(y/n)"
    answer = gets.chomp
    if answer == "y"
      max_p = TotalEventRanking.order(:point.desc).limit(max).all.last.point
      min_p = TotalEventRanking.order(:point.desc).limit(min).all.last.point
      ret = TotalEventRanking.filter(:point.sql_string <= max_p).filter(:point.sql_string >= min_p).all
      ret.each do |a|
        puts "AvatarId:#{a.avatar_id}に#{REWARD_TYPE_STR[t]}ID:#{i}を付与"
        case t
        when 1
          a.avatar.get_item(i)
        when 2
          a.avatar.get_part(i)
        when 3
          a.avatar.get_chara_card(i)
        when 4
          a.avatar.get_slot_card(SCT_WEAPON, i)
        when 5
          a.avatar.get_slot_card(SCT_EVENT, i)
        end
      end
    end
    puts "続けて報酬アイテムを渡しますか？(y/n)"
    answer = gets.chomp
    break unless answer == "y"
  end

end
