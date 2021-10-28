$LOAD_PATH.unshift(File.join(File.expand_path('.'), 'src'))
require 'pathname'
require 'unlight'

module Unlight
  #######################################################################################
  ##
  ## TOTAL_EVENT_RANKING_TYPE_PRF_ALL_DMG
  ##
  puts 'ミニレイドイベント報酬配付(y/n)'
  answer = gets.chomp
  if answer == 'y'
    st = Time.new(2016, 9, 14, 17).utc
    et = Time.new(2016, 9, 28, 13).utc
    prf_list = Profound.filter([[:state, [PRF_ST_FINISH, PRF_ST_VANISH]]]).filter { created_at > st }.filter { created_at < et }.all
    prf_id_list = prf_list.map(&:id)
    pi_set = ProfoundInventory.filter([[:profound_id, prf_id_list], [:state, PRF_INV_ST_SOLVED]]).filter { score.positive? }.select_append { sum(damage_count).as(all_damage) }.all
    total_damage = pi_set.first.values[:all_damage]

    ITEM_SET_LIST = {
      250_000 => { genr: TG_SLOT_CARD, id: 5025, num: 1, stype: SCT_WEAPON },
      750_000 => { genr: TG_SLOT_CARD, id: 6000, num: 1, stype: SCT_WEAPON },
      1_250_000 => { genr: TG_AVATAR_PART, id: 752, num: 1, stype: SCT_WEAPON },
      1_750_000 => { genr: TG_SLOT_CARD, id: 6001, num: 1, stype: SCT_WEAPON },
      2_500_000 => { genr: TG_AVATAR_PART, id: 751, num: 1, stype: SCT_WEAPON },
      2_750_000 => { genr: TG_AVATAR_ITEM, id: 4, num: 2, stype: SCT_WEAPON },
      3_000_000 => { genr: TG_AVATAR_ITEM, id: 7, num: 2, stype: SCT_WEAPON },
      3_250_000 => { genr: TG_AVATAR_ITEM, id: 9, num: 5, stype: SCT_WEAPON }
    }

    puts "total_damage:#{total_damage}"
    puts 'reward list ====================='
    ITEM_SET_LIST.each do |val, set|
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
    puts 'reward list ====================='

    exit
  end
end
