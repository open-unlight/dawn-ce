# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module GlobalChatController

    HELP_CACHE_TTL         = 60*60*24*10 # 十日間
    HELP_SEND_SET_NUM      = 5           # 送信セット回数
    HELP_SEND_SET_CNT_MAX  = 1000        # 1回に送る最大人数
    HELP_SEND_SET_CNT_MIN  = 100         # 1回に送る最小人数
    HELP_SEND_SET_FRACTION_POW = 10      # 人数制限数/10が送信数

    # ======================================
    # 受信コマンド
    # =====================================

    def cs_add_help_list(key,help)
      if add_help_list(key,help)
        SERVER_LOG.info("GlobalChatController: [#{__method__}] add help success! key:#{key} help:#{help} stack help num:#{@@help_key_list.size}")
      else
        SERVER_LOG.info("GlobalChatController:: [#{__method__}] add help failed... key:#{key} help:#{help}")
      end
    end

    def pushout()
      if @player
        online_list[@player.id].logout
        @@recipient_list.delete(@player.id)
      end
    end

    def do_login
      if @player
        @@recipient_list[@player.id] = self
      end
    end

    def do_logout
      @@recipient_list.delete(@player.id) if @player
    end

    # 送信
    def sending_help(key,name,help)
      sc_send_help(key,name,help)
    end

    # リストに追加
    def add_help_list(key,help)
      success = false
      if !@@help_key_list.include?(key)
        set_help_cache(key,help)
        @@help_key_list << key
        success = true
      end
      success
    end

    # 現在送信予定のヘルプを呼び出し
    def get_now_help
      key = nil
      help = nil
      if @@help_key_list.size > 0
        key = @@help_key_list.first
        help = get_help_cache(key)
      end
      [key,help]
    end

    def self::init
      @@recipient_list = { }    # オンラインのリスト 管理の問題でonline_listとは別に用意
      @@help_key_list = []      # 保持しているヘルプを管理するキーリスト
      @@sending_key_list = []   # 送信時に使用するキーリスト
      @@sending_idx = 0         # 送信中のキーINDEX
      @@sending_set_cnt  = 0    # 1回の送信人数
    end

    def recipient_list
      @@recipient_list
    end
    def help_key_list
      @@help_key_list
    end

    # 一斉送信
    def self::sending_help_list
      # ヘルプが積まれているなら
      if @@help_key_list.size > 0
        key,help = sending_init # 送信管理変数の初期化判定

        # keyもhelpもとれなければ処理しない
        return if key == nil || help == nil

        # 受信者がいないなら処理しない
        SERVER_LOG.info("GlobalChatController: [#{__method__}] #{@@recipient_list.keys.size}")
        return if @@recipient_list.keys.size <= 0

        # 渦が終了済みなら処理しない
        prf = Profound::get_profound_for_hash(help)
        return if prf.is_finished?||prf.is_vanished?

        owner = Player[key.to_i]
        # オーナーがいないなら処理しない
        return unless owner
        name = owner.current_avatar.name.force_encoding("UTF-8")

        # 一定範囲に送信
        cnt = 0
        SERVER_LOG.info("GlobalChatController: [#{__method__}] help sending!! idx:#{@@sending_idx} set_cnt:#{@@sending_set_cnt}")
        SERVER_LOG.info("GlobalChatController: [#{__method__}] help sending!! key:#{key} help:#{help}")
        @@sending_key_list.each do |list_key|
          recipient = @@recipient_list[list_key]
          if recipient&&recipient.player.server_type == owner.server_type
            # 発見者のBlackListに入っていたら、送信しない
            if ! FriendLink::is_blocked(key.to_i,recipient.player.id,owner.server_type)
              recipient.sending_help(key,name,help) if recipient&&recipient.player.id != key.to_i
            end
            cnt += 1
          end
        end
        SERVER_LOG.info("GlobalChatController: [#{__method__}] help sending!! had sent num:#{cnt}")

        recipient_keys = @@recipient_list.keys
        @@sending_idx = recipient_keys.index(@@sending_key_list.last) + 1 # 最後のIDXの次を指定
        # 現在の最大値を越えてれば初期化
        if @@sending_idx >= recipient_keys.size
          @@sending_idx = 0
        end
      end
    end

    # 送信管理
    def self::sending_init
      init = false

      # 送信キーリストの最後まで送信した
      if @@sending_key_list&&@@sending_key_list.size > 0
        init = true
        pop_key = @@help_key_list.shift    # 先頭のキーを抜く
        del_help = get_help_cache(pop_key) # 削除予定のヘルプを一時取得 ログ表示の為
        delete_help_cache(pop_key)         # キーのヘルプをキャッシュから削除
        @@sending_key_list = []            # 送信キーリストもリセット
        SERVER_LOG.info("GlobalChatController: [#{__method__}] help cache delete!! key:#{pop_key} help:#{del_help}")
      end

      key = nil
      help = nil
      key = @@help_key_list.first
      help = get_help_cache(key) if key

      # 送信キーリストなどをリセット
      if key != nil && help != nil
        prf = Profound::get_profound_for_hash(help)
        if prf&&prf.p_data
          member_limit = prf.p_data.member_limit
        else
          member_limit = HELP_SEND_SET_CNT_MIN
        end
        # 人数制限の1/10を送信数に設定
        @@sending_set_cnt = member_limit/HELP_SEND_SET_FRACTION_POW
        # 送信数が最大値より大きい、または最小値より小さければ限界値に設定
        @@sending_set_cnt = HELP_SEND_SET_CNT_MIN if @@sending_set_cnt < HELP_SEND_SET_CNT_MIN
        @@sending_set_cnt = HELP_SEND_SET_CNT_MAX if @@sending_set_cnt > HELP_SEND_SET_CNT_MAX
        send_list_candidate = @@recipient_list.keys
        # 送信候補リストが送信数より少なければ全て候補
        if send_list_candidate.size < @@sending_set_cnt
          @@sending_key_list = send_list_candidate
        else
          # 現在IDXから送信数までを設定
          @@sending_key_list = send_list_candidate.slice(@@sending_idx,@@sending_set_cnt)
          # 必要数に足りてない為、先端から再度実行
          if @@sending_key_list.size < @@sending_set_cnt
            @@sending_idx = 0
            set_cnt = @@sending_set_cnt - @@sending_key_list.size
            @@sending_key_list.concat(send_list_candidate.slice(@@sending_idx,@@sending_set_cnt))
          end
        end
        SERVER_LOG.info("GlobalChatController: [#{__method__}] send data init!! list_num:#{@@sending_key_list.size} idx:#{@@sending_idx} set_cnt:#{@@sending_set_cnt}")
      end
      [key,help]
    end

    def self::get_help_cache(key)
      CACHE.get("global_chat_help_list:#{key}") if key
    end

    def self::set_help_cache(key,data)
      CACHE.set("global_chat_help_list:#{key}",data,HELP_CACHE_TTL) if key&&data
    end

    def self::delete_help_cache(key)
      CACHE.delete("global_chat_help_list:#{key}") if key
    end

    def get_help_cache(key)
      CACHE.get("global_chat_help_list:#{key}") if key
    end

    def set_help_cache(key,data)
      CACHE.set("global_chat_help_list:#{key}",data,HELP_CACHE_TTL) if key&&data
    end

    def delete_help_cache(key)
      CACHE.delete("global_chat_help_list:#{key}") if key
    end

    # 自動渦の発生
    def self::auto_create_prf
      # 曜日確認
      now = Time.now.utc
      if PRF_AUTO_PRF_WDAY.include?(now.wday)
        # 自動渦のオーナー取得
        owner = Player.get_prf_owner_player
        if owner&&owner.current_avatar
          if owner.current_avatar.get_prf_inv_num < PRF_AUTO_PRF_MAX
            pr = Profound::get_new_profound_for_group(owner.current_avatar.id,RAID_EVENT_AUTO_CREATE_GROUP_ID,10,PRF_TYPE_MMO_EVENT)
            pr = Profound::get_new_profound_for_group(owner.current_avatar.id,RAID_EVENT_AUTO_CREATE_GROUP_ID,owner.server_type,10,PRF_TYPE_MMO_EVENT)
            start_score = pr.p_data.finder_start_point
            inv = ProfoundInventory::get_new_profound_inventory(owner.current_avatar.id,pr.id,true,start_score)
            SERVER_LOG.info("GlobalChatController: [#{__method__}] create auto profound hash:#{pr.profound_hash}")
          end
        end
      end
    end

    # 自動渦の救援送信
    def self::auto_prf_send_help
      # 自動渦のオーナー取得
      owner = Player.get_prf_owner_player
      if owner&&owner.current_avatar
        # 渦情報取得
        prf_inv_list = owner.current_avatar.get_profound_inventory_list
        prf_inv_list.each do |pi|
          is_vanish = owner.current_avatar.is_vanished_profound(pi)
          if pi&&pi.profound&&pi.profound.state != PRF_ST_FINISH&&pi.profound.state != PRF_ST_VANISH && !is_vanish
            if !@@help_key_list.include?(owner.id.to_s)
              set_help_cache(owner.id.to_s,pi.profound.profound_hash)
              @@help_key_list << owner.id.to_s
              SERVER_LOG.info("GlobalChatController: [#{__method__}] set auto prf help hash:#{pr.profound_hash}")
            end
          end
        end
      end
    end

  end

end
