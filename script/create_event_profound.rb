# イベント用の渦を作成
$:.unshift(File.join(File.expand_path("."), "src"))
require 'pathname'
require 'unlight'

module Unlight
  if PRF_AUTO_CREATE_EVENT_FLAG
    owner = Player.get_prf_owner_player
    # 渦が発生してない状態の時のみ追加
    if owner.current_avatar.get_prf_inv_num <= 0
      pr = Profound::get_new_profound_for_group(RAID_EVENT_AUTO_CREATE_GROUP_ID,10,PRF_TYPE_MMO_EVENT)
      inv = owner.current_avatar.get_profound(pr,true)
    end
  end
end
