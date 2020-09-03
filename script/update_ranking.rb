$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'

module Unlight
  case THIS_SERVER
  when SERVER_SB then
    WeeklyDuelRanking.update_ranking(SERVER_SB)
    EstimationRanking::update_total_duel_ranking(SERVER_SB)
    TotalEventRanking::start_up(SERVER_SB)
  end
end
