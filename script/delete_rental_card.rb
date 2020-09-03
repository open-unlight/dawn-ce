$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
require File.expand_path(".")+'/script/sql_create.rb'
$arg = ARGV.shift

module Unlight

  puts "レンタルカードを削除しますか？(y/n)"
  answer = gets.chomp
  if answer == "y"
    puts "有効なレンタルカードを全て取得"
    rental_cards = CardInventory.filter{ chara_card_id >= 50000 }.filter{ chara_card_id < 60000 }.exclude([:chara_card_deck_id=>0]).order(Sequel.asc(:chara_card_deck_id)).all
    puts "rental cards num:#{ rental_cards.size}"
    deck_rental_cards = { }
    rental_cards.each do |ci|
      deck_rental_cards[ci.chara_card_deck_id] = [] unless deck_rental_cards[ci.chara_card_deck_id]
      deck_rental_cards[ci.chara_card_deck_id] << ci
    end
    deck_ids = deck_rental_cards.keys
    # バインダーじゃないデッキIDを吸出し
    use_decks = CharaCardDeck.filter([[:id,deck_ids]]).exclude([:name=>"Binder"]).all
    deck_ava_ids = use_decks.map { |ccd| ccd.avatar_id}
    tmp_ava = Avatar.filter([[:id,deck_ava_ids]]).all
    avatars = { }
    tmp_ava.each { |ava| avatars[ava.id] = ava }
    puts "check deck num:#{use_decks.size}"
    puts "デッキにセットされてるカードをバインダーに移す"
    use_decks.each_with_index do |ccd,idx|
      if deck_rental_cards[ccd.id]
        deck_rental_cards[ccd.id].sort { |ci_a,ci_b| ci_b.position <=> ci_a.position }.each do |ci|
          # 先にセットされてるスロットカードをバインダーに入れる
          sci_list = CharaCardSlotInventory.filter([:chara_card_deck_id=>ccd.id,:deck_position=>ci.position]).all
          sci_list.sort { |sci_a,sci_b| sci_b.card_position <=> sci_a.card_position }.each do |sci|
            avatars[ccd.avatar_id].update_slot_card_deck(sci.id, 0, sci.kind, 0, sci.card_position)
          end
          # レンタルカードをバインダーに入れる
          avatars[ccd.avatar_id].update_chara_card_deck(ci.id, 0, ci.position)
        end
      end
      if idx > 0 && idx % 50 == 0
        puts "move to Binder ..."
      end
    end
    puts "レンタルカードを削除する"
    DB.transaction do
      CardInventory.where{chara_card_id >= 50000}.where{chara_card_id < 60000}.where{chara_card_deck_id > 1}.update(:before_deck_id=>:chara_card_deck_id,:chara_card_deck_id=>0)
    end
  end

end

