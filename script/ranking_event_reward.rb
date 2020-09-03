$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'
$arg = ARGV.shift

module Unlight

  #######################################################################################
  ##
  ## TOTAL_EVENT_RANKING_TYPE_PRF_ALL_DMG
  ##
  puts "ミニレイドイベント報酬配付(y/n)"
  answer = gets.chomp
  if answer == "y"
    st = Time.new(2016,9,14,17).utc
    et = Time.new(2016,9,28,13).utc
    prf_list = Profound.filter([[:state,[PRF_ST_FINISH,PRF_ST_VANISH]]]).filter{created_at > st}.filter{created_at < et}.all
    prf_id_list = prf_list.map { |prf| prf.id}
    pi_set = ProfoundInventory.filter([[:profound_id,prf_id_list],[:state,PRF_INV_ST_SOLVED]]).filter{score > 0}.select_append{sum(damage_count).as(all_damage)}.all
    total_damage = pi_set.first.values[:all_damage]


    ITEM_SET_LIST = {
      250000  => { :genr => TG_SLOT_CARD, :id => 5025, :num => 1, :stype => SCT_WEAPON },
      750000  => { :genr => TG_SLOT_CARD, :id => 6000, :num => 1, :stype => SCT_WEAPON },
      1250000 => { :genr => TG_AVATAR_PART, :id => 752, :num => 1, :stype => SCT_WEAPON },
      1750000 => { :genr => TG_SLOT_CARD, :id => 6001, :num => 1, :stype => SCT_WEAPON },
      2500000 => { :genr => TG_AVATAR_PART, :id => 751, :num => 1, :stype => SCT_WEAPON },
      2750000 => { :genr => TG_AVATAR_ITEM, :id => 4, :num => 2, :stype => SCT_WEAPON },
      3000000 => { :genr => TG_AVATAR_ITEM, :id => 7, :num => 2, :stype => SCT_WEAPON },
      3250000 => { :genr => TG_AVATAR_ITEM, :id => 9, :num => 5, :stype => SCT_WEAPON },
    }

    puts "total_damage:#{total_damage}"
    puts "reward list ====================="
    ITEM_SET_LIST.each do |val,set|
      break if val > total_damage
      case set[:genr]
      when TG_AVATAR_ITEM
        puts "dmg:#{val} id:#{set[:id]} name:#{AvatarItem[set[:id]].name} num:#{set[:num]}"
      when TG_AVATAR_PART
        puts "dmg:#{val} id:#{set[:id]} name:#{AvatarPart[set[:id]].name} num:#{set[:num]}"
      when TG_SLOT_CARD
        puts "dmg:#{val} id:#{set[:id]} name:#{WeaponCard[set[:id]].name} num:#{set[:num]}"
      end
    end
    puts "reward list ====================="

    exit()

    puts "上記の内容を全アバターに配付しますか？(y/n)"
    lanswer = gets.chomp
    if lanswer == "y"

      item_import_list = []
      item_set_list = []
      item_columns = [:avatar_id,:avatar_item_id,:created_at,:updated_at]
      part_import_list = []
      part_set_list = []
      part_columns = [:avatar_id,:avatar_part_id,:created_at,:updated_at]
      weapon_import_list = []
      weapon_set_list = []
      weapon_columns = [:chara_card_deck_id,:kind,:card_id,:created_at,:updated_at]

      CLEARED_RECORD_ID = 1033
      list = AchievementInventory.filter([[:achievement_id,CLEARED_RECORD_ID],[:state,ACHIEVEMENT_STATE_FINISH]]).all
      aid_list = []
      list.each {  |l|
        puts "id:#{ l.id} aid:#{l.achievement_id} state:#{l.state}, avatar_id:#{l.avatar_id} before_avatar_id:#{l.before_avatar_id}"
        if l.avatar_id != 0
          aid_list << l.avatar_id
        else
          aid_list << l.before_avatar_id
        end
      }
      p aid_list
      p aid_list.size
      # avatars = Avatar.filter{ id > 1}.all
      avatars = Avatar.filter([[:id,aid_list]]).all

      exit()

      nt = Time.now.utc
      avatars.each do |ava|
        ITEM_SET_LIST.each do |val,set|
          break if val > total_damage
          set[:num].times do
            tmp = []
            case set[:genr]
            when TG_AVATAR_ITEM
              tmp << ava.id
              tmp << set[:id]
              tmp << nt
              tmp << nt
              item_set_list << tmp
              if item_set_list.size > 500
                item_import_list << item_set_list
                item_set_list = []
              end
            when TG_AVATAR_PART
              tmp << ava.id
              tmp << set[:id]
              tmp << nt
              tmp << nt
              part_set_list << tmp
              if part_set_list.size > 500
                part_import_list << part_set_list
                part_set_list = []
              end
            when TG_SLOT_CARD
              tmp << ava.binder.id
              tmp << set[:stype]
              tmp << set[:id]
              tmp << nt
              tmp << nt
              weapon_set_list << tmp
              if weapon_set_list.size > 500
                weapon_import_list << weapon_set_list
                weapon_set_list = []
              end
            end
          end
        end
      end

      if item_set_list.size > 0
        item_import_list << item_set_list
        item_set_list = []
      end
      if part_set_list.size > 0
        part_import_list << part_set_list
        part_set_list = []
      end
      if weapon_set_list.size > 0
        weapon_import_list << weapon_set_list
        weapon_set_list = []
      end

      DB.transaction do
        puts "item import."
        item_import_list.each do |import_set|
          ItemInventory.import(item_columns,import_set)
        end
        puts "part import."
        part_import_list.each do |import_set|
          PartInventory.import(part_columns,import_set)
        end
        puts "weapon import."
        weapon_import_list.each do |import_set|
          CharaCardSlotInventory.import(weapon_columns,import_set)
        end
      end

    end

  end

end
