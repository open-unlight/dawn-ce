# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module RaidRankController
    def cs_request_ranking_list(inv_id, offset, count)
      SERVER_LOG.info("<UID:#{@uid}>RaidRankServer: [#{__method__}] inv_id:#{inv_id} offset:#{offset} count:#{count}")
      @rank_prf_inv = ProfoundInventory[inv_id] if !@rank_prf_inv || @rank_prf_inv.id != inv_id
      if @rank_prf_inv
        @rank_prf_inv.init_ranking
        ret = @rank_prf_inv.get_ranking_str(offset,offset+count-1)
        sc_update_ranking_list(@rank_prf_inv.profound_id, offset, ret) if ret&&ret.size >1
      end
    end

    def cs_request_rank_info(inv_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidRankServer: [cs_request_rank_info] inv_id:#{inv_id}")
      d = @avatar.get_profound_rank(inv_id) if @avatar
      sc_update_rank(d[:prf_id], d[:ret][:rank], d[:ret][:score]) if d&&d[:prf_id] != 0
    end

    # 最終ランキングを取得
    def cs_get_profound_result_ranking(prf_id)
      SERVER_LOG.info("<UID:#{@uid}>RaidRankServer: [#{__method__}] prf_id:#{prf_id}")
      if @avatar
        self_inv = ProfoundInventory::get_avatar_profound_for_id(@avatar.id,prf_id)
        prf = Profound[prf_id]
        if self_inv&&prf
          defeat_avatar = Avatar[prf.found_avatar_id]
          if defeat_avatar
            ranking_str_list,self_rank = self_inv.get_finish_ranking_notice_str(defeat_avatar,false)
            if ranking_str_list.size > 0
              set_data = [prf_id,NOTICE_TYPE_FIN_PRF_RANKING,self_rank,ranking_str_list.join(",")]
              sc_profound_result_ranking(set_data.join("+"))
            end
          end
        end
      end
    end

    def pushout()
      online_list[@player.id].player.logout(true)
      online_list[@player.id].logout
    end

    def do_login
      SERVER_LOG.info("<UID:#{@uid}>RaidRankServer: [#{__method__}]")
      if @player.avatars.size > 0
        @avatar = @player.current_avatar
      end
    end

    def do_logout
      delete_connection
    end

  end
end
