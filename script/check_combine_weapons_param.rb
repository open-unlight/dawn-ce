# -*- coding: utf-8 -*-
$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
require File.expand_path(".")+'/script/sql_create.rb'
$arg = ARGV.shift

module Unlight

  puts "合成武器のパラメータチェックをしますか？（y/n）"
  answer = gets.chomp
  if answer == "y" || answer == "Y" || answer == "Yes" || answer == "yes"

    list = CharaCardSlotInventory.filter([[:kind,SCT_WEAPON]]).exclude([[:chara_card_deck_id,0],[:exp,0]]).order(Sequel.desc(:exp)).all

    puts_data = ["inv_id,card_id,lv,exp,base_sap,base_sdp,base_aap,base_adp,add_sap,add_sdp,add_aap,add_adp"]
    list.each do |ccs|
      str = "#{ccs.id},#{ccs.card_id},#{ccs.level},#{ccs.exp},#{ccs.combine_base_sap},#{ccs.combine_base_sdp},#{ccs.combine_base_aap},#{ccs.combine_base_adp},#{ccs.combine_add_sap},#{ccs.combine_add_sdp},#{ccs.combine_add_aap},#{ccs.combine_add_adp}"
      puts_data << str
    end

    FILE = "/home/unlight/tmp/csv/CombineWeaponParams.csv"

    file = Pathname.new(FILE)

    file.open('w') { |f|
      puts_data.each { |str| f.puts str }
    }

  end

end

