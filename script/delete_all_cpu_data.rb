$LOAD_PATH.unshift(File.join(File.expand_path('.'), 'src'))
require 'pathname'
require 'unlight'

module Unlight
  puts 'CPUデータを削除します(y/n)'
  answer = gets.chomp
  if answer == 'y'
    decks = CharaCardDeck.filter({ avatar_id: Unlight::Player.get_cpu_player.current_avatar.id }).filter(Sequel.like(:name, 'Monster: %')).all
    decks.each(&:destroy)
  end
end
