# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'digest/md5'

module Unlight
  # 渦クラス
  class Profound < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    many_to_one :p_data, class: Unlight::ProfoundData, key: :data_id # 複数のクエストデータを保持

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # 現在戦闘中の渦を全て取得
    def self.get_playing_prf(server_type)
      now = Time.now.utc
      Profound.filter([[:state, [PRF_ST_UNKNOWN, PRF_ST_BATTLE]], [:server_type, server_type]]).filter { close_at > now }.all
    end

    def self.make_profound_hash
      Digest::MD5.hexdigest("#{Time.now}profound#{rand(1024)}")[0..10]
    end

    def self.get_new_profound_for_map(found_avatar_id, map_id, server_type, pow = 0, type = PRF_TYPE_NORMAL)
      r = get_realty(pow)
      q = search_profound({ quest_map_id: map_id, prf_type: type, rarity: r }, r)
      data = q[rand(q.count)] if q
      if data
        ret = Profound.new do |pr|
          pr.data_id = data.id
          pr.profound_hash = make_profound_hash
          pr.close_at = Time.now.utc + data.ttl.to_f * 60 * 60
          pr.state = PRF_ST_UNKNOWN
          pr.map_id = rand(PRF_MAP_ID_MAX)
          pr.pos_idx = rand(PRF_POS_IDX_MAX)
          pr.copy_type = PRF_COPY_TYPE_OWNER
          pr.found_avatar_id = found_avatar_id
          pr.server_type = server_type
          pr.save_changes
          # 状態異常を作成
          pr.set_boss_buff
        end
      end
      ret
    end

    def self.get_new_profound_for_group(found_avatar_id, group_id, server_type, pow = 0, type = PRF_TYPE_NORMAL)
      r = get_realty(pow)
      q = search_profound({ group_id: group_id, prf_type: type, rarity: r }, r)
      data = q[rand(q.count)] if q
      if data
        ret = Profound.new do |pr|
          pr.data_id = data.id
          pr.profound_hash = make_profound_hash
          pr.close_at = Time.now.utc + data.ttl.to_f * 60 * 60
          pr.state = PRF_ST_UNKNOWN
          pr.map_id = rand(PRF_MAP_ID_MAX)
          pr.pos_idx = rand(PRF_POS_IDX_MAX)
          pr.copy_type = PRF_COPY_TYPE_OWNER
          pr.found_avatar_id = found_avatar_id
          pr.server_type = server_type
          pr.save_changes
          # 状態異常を作成
          pr.set_boss_buff
        end
      end
      ret
    end

    def self.search_profound(cond, rarity)
      r = rarity
      s = 0
      until s.positive?
        cond[:rarity] = r
        q = ProfoundData.filter(cond).all
        s = q.count if q
        r -= 1
        break if r.zero?
      end
      if q.size <= 0
        r = 10
        until s.positive?
          cond[:rarity] = r
          q = ProfoundData.filter(cond).all
          s = q.count if q
          r -= 1
          break if r.zero?
        end
      end
      q
    end

    def self.get_profound_for_hash(hash)
      ret = nil
      list = Profound.filter({ profound_hash: hash }).all
      ret = list.first if list
      ret
    end

    # レアリティを決定する
    def self.get_realty(pow = 0)
      r = rand(MAP_REALITY_NUM)
      ret = 1
      if MAP_REALITY[pow]
        MAP_REALITY[pow].each_index do |i|
          if MAP_REALITY[pow][i] > r
            ret = i + 1
          else
            break
          end
        end
      end
      ret
    end

    # Battle状態に変更
    def battle
      if state == PRF_ST_UNKNOWN
        self.state = PRF_ST_BATTLE
        save_changes
      end
    end

    # 終了状態に変更
    def finish
      if state != PRF_ST_VANISH
        self.state = PRF_ST_FINISH
        self.finish_at = Time.now.utc
        save_changes
      end
    end

    # 撃破しているか
    def is_finished?(r = true)
      refresh if r
      ret = false
      ret = true if is_vanished?
      ret = true if state == PRF_ST_FINISH
      now = Time.now.utc
      ret = true if finish_at && finish_at <= now
      ret
    end

    # 消滅しているか
    def is_vanished?(lt = 0)
      ret = (state == PRF_ST_VANISH || state == PRF_ST_VAN_DEFEAT)
      if !ret && close_at
        if Time.now.utc > (close_at + lt)
          # 今消滅を確認したので、Stateを変更
          vanish_profound
          ret = true
        end
      end
      ret
    end

    # 渦の消滅
    def vanish_profound
      if state != PRF_ST_VANISH && state != PRF_ST_VAN_DEFEAT
        self.state = state == PRF_ST_FINISH ? PRF_ST_VAN_DEFEAT : PRF_ST_VANISH
        save_changes
        # 状態異常を削除
        set_boss_buff(0, 0, 0, true)
      end
    end

    # 撃破判定
    def is_defeat?(r = true)
      refresh if r
      (state == PRF_ST_FINISH || state == PRF_ST_VAN_DEFEAT)
    end

    # 撃破後時間の設定
    def set_losstime
      if state == PRF_ST_FINISH
        self.close_at = Time.now.utc + PRF_LOSSTIME_TTL
        save_changes
      end
    end

    # 撃破者のアバターIDをセット
    def set_defeat_avatar_id(avatar_id)
      self.defeat_avatar_id = avatar_id
      save_changes
    end

    # パラメータ表示開始damage
    def param_view_start_damage
      max_hp = p_data.get_boss_max_hp
      ret = 0
      if max_hp.positive?
        ret = (max_hp / PRF_BOSS_NAME_VIEW_START_HP_VAL).ceil
      end
      ret
    end

    # 報酬リストを取得する
    def get_treasure_list
      ret = []
      prf_data = p_data
      if prf_data
        ret = ProfoundTreasureData.get_level_treasure_list(prf_data.treasure_level)
      end
      ret
    end

    # 状態異常を取得
    def get_boss_buff
      CACHE.get("prf_#{id}_buffs")
    end

    # 状態異常を保存
    def set_boss_buff(id = 0, value = 0, turn = 0, reset = false) # rubocop:disable Metrics/ParameterLists
      buffs = CACHE.get("prf_#{self.id}_buffs")
      set_time = p_data.ttl.to_f * 60 * 60
      if reset
        # 新規作成
        buffs = nil
        set_time = 1
      else
        buffs ||= {}
        # 保存 limitはturn*1分
        now = Time.now.utc
        buffs[id] = { value: value, turn: turn, limit: Time.now.utc + turn * 60 } if id != 0
      end
      CACHE.set("prf_#{self.id}_buffs", buffs, set_time)
      reset ? nil : [id, buffs[id]]
    end

    # 状態異常を削除
    def unset_boss_buff(id = 0, value = 0)
      buffs = CACHE.get("prf_#{self.id}_buffs")
      if buffs
        ret = {}
        buffs.each do |b_id, v|
          if id != b_id || value != v[:value]
            ret[b_id] = { value: v[:value], turn: v[:turn], limit: v[:limit] }
          end
        end
      else
        buffs = {}
      end
      CACHE.set("prf_#{self.id}_buffs", ret, p_data.ttl.to_f * 60 * 60)
    end

    # 状態異常を全て削除
    def reset_boss_buff
      buffs = {}
      CACHE.set("prf_#{id}_buffs", buffs, p_data.ttl.to_f * 60 * 60)
    end

    # 状態異常を更新(ターン経過で終了)
    def update_boss_buff(id = 0, value = 0, turn = 0)
      buffs = CACHE.get("prf_#{self.id}_buffs")
      if buffs
        ret = {}
        buffs.each do |b_id, v|
          if id == b_id && value == v[:value]
            if (v[:turn] - 1).positive?
              turn = v[:turn] - 1
              ret[b_id] = { value: v[:value], turn: turn }
            end
          else
            ret[b_id] = { value: v[:value], turn: v[:turn] }
          end
        end
      else
        buffs = {}
      end
      CACHE.set("prf_#{self.id}_buffs", ret, p_data.ttl.to_f * 60 * 60)
    end

    # 時間判定を行わない状態異常か
    def check_non_limit_buff(buff_id)
      ret = false
      case buff_id
      when CharaCardEvent::STATE_STIGMATA, CharaCardEvent::STATE_CURSE, CharaCardEvent::STATE_TARGET
        true
      else
        false
      end
    end

    # 渦のコピータイプを変更
    def change_copy_type(t)
      self.copy_type = t
      save_changes
    end

    # 渦の撃破報酬の有無を変更
    def change_set_defeat_reward(f)
      self.set_defeat_reward = f
      save_changes
    end
  end
end
