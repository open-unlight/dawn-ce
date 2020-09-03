# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  module LobbyController

      # ======================================
      # 受信コマンド
      # =====================================

     # デッキ情報を設定
      def cs_update_deck_info(index, inv_id_0, inv_id_1, inv_id_2)
        erro_no = 0
        if @avatar
          inv_set = [inv_id_0, inv_id_1, inv_id_2]
          # デッキ内のカードそれぞれを移動
          3.times do |i|
            if inv_set[i] !=0
              erro_no = @avatar.update_chara_card_deck(inv_set[i], index, i)
            end
            break if erro_no != 0
          end
          if erro_no == 0
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_card_inventory_info] ///// update success ///// e:#{erro_no} #{index}, #{inv_id_0}, #{inv_id_1}, #{inv_id_2}")
            sc_update_deck_success(index, inv_id_0, inv_id_1, inv_id_2)
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_card_inventory_info] ///// error ///// e:#{erro_no}")
            sc_error_no(erro_no)
          end
        end
      end


      # カード情報を設定
      def cs_update_card_inventory_info(inv_id, index, position)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_card_inventory_info] id:#{inv_id} index:#{index} position:#{position} ")
        if @avatar
          CACHE.set("update_card_inventory_info_#{@avatar.player_id}",true,60*60*1)
          e = @avatar.update_chara_card_deck(inv_id, index, position)
          if e == 0
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_card_inventory_info] ///// update success ///// e:#{e} ")
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_card_inventory_info] ///// error ///// e:#{e}")
            sc_error_no(e)
          end
        end
        # 設定終了を報告
        CACHE.delete("update_card_inventory_info_#{@avatar.player_id}")
        sc_update_card_inventory_info_finish()
      end


      # カード情報を設定
      def cs_update_slot_card_inventory_info(kind, inv_id, index,  deck_position, card_position)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_slot_cardinventory_info] kind:#{kind} id:#{inv_id} index:#{index} position:#{deck_position}, cardPsition:#{card_position} ")
        if @avatar
          CACHE.set("update_slot_card_inventory_info_#{@avatar.player_id}",true,60*60*1)
          ret = @avatar.update_slot_card_deck(inv_id, index, kind, deck_position, card_position)
          unless ret[0] == 0
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_update_slot_cardinventory_info] ///// error ///// e:#{ret[0]}")
            sc_update_slot_card_inventory_failed( kind, ret[0],  ret[1].id, @avatar.get_deck_index(ret[1].chara_card_deck), ret[1].deck_position, ret[1].card_position )
          end
        end
        # 設定終了を報告
        CACHE.delete("update_slot_card_inventory_info_#{@avatar.player_id}")
        sc_update_slot_card_inventory_info_finish()
      end

      # カード情報更新中判定
      def cs_inventory_update_check()
        chara_card_inv_info = false
        slot_card_inv_info = false
        if @avatar
          cache_tmp = CACHE.get("update_card_inventory_info_#{@avatar.player_id}")
          chara_card_inv_info = (cache_tmp != nil) ? cache_tmp : false
          cache_tmp = CACHE.get("update_slot_card_inventory_info_#{@avatar.player_id}")
          slot_card_inv_info = (cache_tmp != nil) ? cache_tmp : false
        end
        sc_inventory_update_check(chara_card_inv_info, slot_card_inv_info)
      end

      # アバターを作成する
      def cs_create_avatar(name, parts, cards, invite_code)
        invite_player = Player[invite_code]
        invite_player.invite_friend(@player.name,false) if invite_player && @player && invite_player.server_type == @player.server_type
        if @player&&Avatar.regist(name, @player.id, parts.split(","), cards.split(","), @player.server_type)
          @player.refresh
          @avatar = @player.avatars[0]
          @avatar.rookie_present(@player,cards.split(",")) # 初心者キャンペーン
          regist_avatar_event
          sc_create_avatar_success(true)
          sc_avatar_info(*@avatar.get_avatar_info_set) if @avatar
          # すべての週間レコードをチェック
          @avatar.all_week_record_check if @avatar
          sc_activity_feed(ACTV_START)
        else
          sc_create_avatar_success(false)
        end
      end

      # アバター名のチェックをする
      def cs_check_avatar_name(name)
        ret = Avatar.name_check(name)
        sc_check_avatar_name(ret)
      end

      # デッキ名の設定
      def cs_update_deck_name(index, name)
        @avatar.update_deck_name(index, name) if @avatar
      end

      # 新規にデッキを作る
      def cs_create_deck()
      end

      # 既存デッキを削除する
      def cs_delete_deck(index)
        sc_delete_deck_success(index) if @avatar.delete_deck(index) if @avatar
        @avatar.update_current_deck_index(1) if @avatar
      end

      # カレントデッキを変更する
      def cs_update_current_deck_index(index)
        if @avatar
          @avatar.update_current_deck_index(index)
          sc_update_current_deck_index(@avatar.current_deck)
        end
      end

      # カード合成ツリーのリクエスト
      def cs_request_growth_tree_info(id)
        sc_growth_tree_info(id, CharaCard.up_tree(id).join(","), CharaCard.down_tree(id).join(","),CharaCardRequirement::data_version) if CharaCard[id]
      end

      # 合成可能か調べるのリクエスト
      def cs_request_exchangeable_info(id, c_id)
        if @avatar
          sc_exchangeble_info(id, @avatar.exchageable(id, c_id)) if CharaCard[id]
        end
      end

      # 合成リクエスト
      def cs_request_exchange(id, c_id)
        if @avatar
          if CharaCard[id]
            ret = @avatar.exchange(id, c_id)
            sc_exchange_result(ret[0],ret[1],ret[2],ret[3].join(","))
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_exchage_result] #{ret[0]} getedCC:#{ret[1]} invID:#{ret[2]} LostCardInvID#{ret[3]}, deckID:#{@avatar.binder.id}")
          end
        end
      end

      # 合成リクエスト
      def cs_request_combine(inv_id_list_str)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [:#{__method__}] #{inv_id_list_str}");
        if @avatar
          ret = @avatar.combine(inv_id_list_str.split(","))
          sc_combine_result(ret[0],ret[1],ret[2])
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [:#{__method__}] ret:#{ret}");
        end
      end

      # データの更新を調べる
      def cs_avatar_update_check
        @avatar.update_check if @avatar
      end

      # アイテムを使用する
      def cs_avatar_use_item(inv_id)
        if @avatar
          e = @avatar.use_item(inv_id)
          unless e >0
            it = ItemInventory[inv_id]
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [avatar_use_item] use_item_id:#{it.avatar_item_id}");
          end
        end
      end

      # ショップの情報を要求
      def cs_request_shop_info(shop_type)
        list = Shop.get_sale_list(shop_type)
        if list.size > 0
          sc_shop_info(shop_type,list.join(","))
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_shop_info] #{list.join(",")}")
        end
      end

      # アイテムを購入する
      def cs_avatar_buy_item(shop,inv_id,amount)
          sc_error_no(ERROR_GEM_DEFICIT) unless @avatar.buy_item(shop, inv_id, amount) if @avatar
      end

      # スロットカードを購入する
      def cs_avatar_buy_slot_card(shop, kind, inv_id,amount)
          sc_error_no(ERROR_GEM_DEFICIT) unless @avatar.buy_slot_card(shop, kind, inv_id, amount) if @avatar
      end

      # キャラカードを購入する
      def cs_avatar_buy_chara_card(shop, inv_id, amount)
          sc_error_no(ERROR_GEM_DEFICIT) unless @avatar.buy_chara_card(shop, inv_id, amount) if @avatar
      end

      # パーツを購入する
      def cs_avatar_buy_part(shop, part_id)
          if @avatar
            ret = @avatar.buy_part(shop, part_id)
            unless ret == 0
              sc_error_no(ret)
            end
          end
      end

      # 課金アイテムを取得する
      def cs_request_real_money_item_info
        list = RealMoneyItem.get_sale_list()
        if list[0] > 0
          sc_real_money_item_info(list[0],list[1].join(","))
        end
      end

      # 課金アイテムをチェックする
      def cs_real_money_item_result_check(id)
        if @avatar
          ret = @avatar.get_real_money_item()
          ret.each { |r|
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [real_money_item_get_result] result#{r}")
          }
        end
      end

      # フレンド申請
      def cs_friend_apply(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_friend_apply] #{id}")
        ret = ERROR_FRIEND_APPLY
        if @player&&@avatar
          ret = @player.create_friend_link(id)
        end
        if ret == 0
          sc_friend_apply_success(id)
        else
          sc_error_no(ret)
        end
      end

      # フレンド申請
      def cs_block_apply(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_block_apply] #{id}")
        ret = false
        if @player&&@avatar
          ret = @player.create_block_link(id)
        end
        if ret[0] == 0
          sc_friend_block_success(ret[1].related_player_id)
        else
          sc_error_no(ret[0])
        end
      end

      # フレンド許可
      def cs_friend_confirm(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_friend_confirm] #{id}")
        ret = false
        if @player
          ret = @player.confirm_friend_link(id)
        end
        if ret
          sc_friend_confirm_success(id)
        else
          sc_error_no(ERROR_FRIEND_CONFIRM)
        end
      end

      # フレンド削除
      def cs_friend_delete(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_friend_delete] #{id}")
        ret = false
        if @player
          ret = @player.delete_friend_link(id)
        end
        if ret
          sc_friend_delete_success(id)
        else
          sc_error_no(ERROR_FRIEND_DELETE)
        end
      end

      # レアカードクジを引く
      def cs_draw_lot(kind)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_draw_card] TYPE:#{kind}")
        if @avatar
          ret = @avatar.draw_lot(kind)
          if ret ==[]
            sc_error_no(ERROR_DRAW_LOT)
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [draw_lot_result] lot_kind:#{kind} got_item_kind:#{ret[0].article_kind} got_item_id:#{ret[0].article_id} ,blank:RCL_ID:#{ret[1].id},RCL_ID:#{ret[2].id}")
            LotLog.create_log(@uid, kind, ret[0].id)
            sc_draw_rare_card_success(ret[0].article_kind,ret[0].article_id,ret[0].num,ret[1].article_kind,ret[1].article_id,ret[1].num, ret[2].article_kind,ret[2].article_id,ret[2].num)
          end
        end
      end

      # カードを複製する
      def cs_copy_card(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [cs_copy_card] id:#{id}")
        if @avatar
          ret = @avatar.copy_card(id)
          if ret == false
            sc_error_no(ERROR_COPY_CARD)
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_copy_card_success] id::#{id}")
            sc_copy_card_success(id)
          end
        end
      end

      # パーツをとりかえする
      def cs_set_avatar_part(id)
        if@avatar
          ret = @avatar.equip_part(id)
          if ret[0]==0
            remainTime = ret[3] ? ret[3]:0
            used = ret[4] ? ret[4]:0
            sc_equip_change_succ(ret[1], ret[2].join(","),remainTime, used)
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_equip_change_succ] error id:#{id}, error_no:#{ret[0]}")
            sc_error_no(ret[0])
          end
        end
      end

      # パーツの消滅チェック
      def cs_parts_vanish_check
        @avatar.check_time_over_part if @avatar
      end

      # パーツを捨てる
      def cs_part_drop(id)
        if @avatar
          part = PartInventory[id]
          # 自分の持ってるパーツならば
          if part&&part.avatar_id == @avatar.id
            cs_set_avatar_part(id) if part.equiped? # パーツが装備されていたら外す
            @avatar.part_drop(part)                 # 捨てる
          end
        end
      end

      # アチーブメントクリアチェック
      def cs_achievement_clear_check(notice_check)
        if @avatar
          @avatar.achievement_check
          n = @avatar.get_notice if notice_check
          sc_add_notice(n) if n!=""&&n!=nil
        end
      end

      # アチーブメントクリアチェック
      def cs_achievement_special_clear_check(n)
        @avatar.achievement_check(n) if @avatar
      end

      # ロビーニュースをクリア
      def cs_notice_clear(n,args)
        @avatar.clear_notice(n,args) if @avatar
      end

      # セール時間情報を要求
      def cs_request_sale_limit_info
        ret = ""
        if @avatar
          ret = @avatar.get_sale_limit_rest_time(true)
          sc_update_sale_rest_time(@avatar.sale_type, ret)
        end
      end

      # アチーブメント情報の取得
      def cs_request_achievement_info()
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]")
        if @avatar
          ret = @avatar.get_achievement_info_set
          sc_update_achievement_info(ret[0],ret[1],ret[2],ret[3],ret[4])
        end
      end

      # イベントシリアルを送信
      def cs_event_serial_code(serial,pass)
        error_count = CACHE.get( "serial_error:#{@uid}" )
        if error_count && error_count > 20
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer:serial error_count [#{error_count}]")
          return
        end
        es = EventSerial::check(serial,pass)
        if es
          @avatar.real_money_item_to_item(es) if @avatar
          s = "#{es.name}"
          if es.extra_id > 0
            rmi = RealMoneyItem[es.extra_id]
            s += "+#{rmi.name}" if rmi
          end
          sc_serial_code_success(s)
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer:serial success [#{s}]")
        else
          sc_error_no(ERROR_EVENT_SERIAL_CODE)
          if error_count
            CACHE.set( "serial_error:#{@uid}",error_count+1, 60*30) # 20回まちがえると30分反応なしになる
          else
            CACHE.set( "serial_error:#{@uid}",1, 60*2) # 1回の間違いは一分で消える
          end
        end
      end


      # 新規渦チェック
      def cs_new_profound_inventory_check
        if @avatar
          @avatar.new_profound_inventory_check
          n = @avatar.get_profound_notice
          sc_add_notice(n) if n!=""&&n!=nil
        end
      end

      # お気に入りキャラIDを設定する
      def cs_change_favorite_chara_id(id)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set id:#{id}")
        @avatar.set_favorite_chara_id(id) if @avatar
      end

      # リザルト画像を設定する
      def cs_change_result_image(id, image_no)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set id:#{id}, image_no#{image_no}")
        @avatar.set_result_image(id, image_no) if @avatar
      end

      # ロビー会話のstart
      def cs_lobby_chara_dialogue_start
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]")
        if @avatar
          c = @avatar.start_lobby_chara_script
        end
        unless c.first == :stop
          self.send(c.first,*c.last)
        end
      end

      # ロビー会話のupdate
      def cs_lobby_chara_dialogue_update
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]")
        if @avatar
          c = @avatar.run_lobby_chara_script
          unless c.first == :stop
            self.send(c.first,*c.last)
          end
        end
      end

      # ロビー会話のパネルを選択して進む
      def cs_lobby_chara_select_panel(i)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set i:#{i}")
        if @avatar
          c = @avatar.run_lobby_chara_script
          if c.first == :stop
            jump_lobby_chara(c[1][i])
          end
        end
      end

      def finish_lobby_chara_command_set
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]}")
        if @avatar
          @avatar.finish_lobby_chara_script
        end
      end

      def flag_check_lobby_chara(flags)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set flags:#{flags}")
        if @avatar
          @avatar.flag_check_lobby_chara_script(flasg)
          cs_lobby_chara_dialogue_update
        end
      end

      def flag_set_lobby_chara(flags)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set flags:#{flags}")
        if @avatar
          @avatar.flag_set_lobby_chara(flags)
          cs_lobby_chara_dialogue_update
        end
      end

      def jump_lobby_chara(jump)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set jump:#{jump}")
        if @avatar
          @avatar.jump_lobby_chara(jump)
          cs_lobby_chara_dialogue_update
        end
      end

      def give_item_lobby_chara(item)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] set item:#{item}")
        if @avatar
          @avatar.give_item_lobby_chara(*item)
          cs_lobby_chara_dialogue_update
        end
      end

      # Infectionコラボイベントシリアルを送信
      def cs_infection_collabo_serial_code(serial)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] serial:#{serial}")
        error_count = CACHE.get( "collabo_serial_error:#{@uid}" )
        if error_count && error_count > 20
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer:collabo serial error_count [#{error_count}]")
          return
        end
        if @avatar
          ics = InfectionCollaboSerial::check(serial,@avatar.player_id,@avatar.server_type)
          if ics
            notice_str = ""
            item_no_set = []
            INFECTION_COLLABO_PRESENTS.each do |item|
              @avatar.get_treasures(item[:type],item[:id],item[:sct_type],item[:num])
              item_no_set << "#{item[:type]}_#{item[:id]}_#{item[:num]}"
            end
            sc_infection_collabo_serial_success(InfectionCollaboSerial::present_names)
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer:serial success [#{s}]")
          else
            SERVER_LOG.info("<UID:#{@uid}>LobbyServer:collabo serial failed!!!!")
            sc_error_no(ERROR_EVENT_SERIAL_CODE)
            if error_count
              CACHE.set( "collabo_serial_error:#{@uid}",error_count+1, 60*30) # 20回まちがえると30分反応なしになる
            else
              CACHE.set( "collabo_serial_error:#{@uid}",1, 60*2) # 1回の間違いは一分で消える
            end
          end
        end
      end

      # クランプス出現チェック 判定と通知
      def cs_clamps_appear_check
        sc_clamps_appear if clamps_appear?
      end

      # クランプス出現チェッカ本体
      def clamps_appear?
        # 経過時間によって判定回数を増やす
        num = @avatar.get_num_of_retries
        num.times do
          if rand(EVENT_201412_RATE) == 0
            @avatar.present_has_received = false
            return true
          end
        end

        return false
      end

      # クランプスクリック
      def cs_clamps_click()
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]")
        msg = ""

        if @avatar.present_has_received?

          ### irregular case for cheat
          msg = "ERROR"

        else

          name_list = []
          CLAMPS_CLICK_PRESENT.each do |item|

            case item[:type]
            when TG_CHARA_CARD
              cc = CharaCard[item[:id]]
              cc_name = cc.name
              if cc.level > 0
                cc_name += ":LV#{cc.level}"
                cc_name += "R" if cc.rarity>5
              end
              cc_name += "×#{item[:num]}" if item[:num] > 1
              name_list.push(cc_name)
            when TG_AVATAR_ITEM
              name = AvatarItem[item[:id]].name
              name += "×#{item[:num]}" if item[:num] > 1
              name_list.push(name)
            when TG_AVATAR_PART
              part_name = AvatarPart[item[:id]].name
              name_list.push(part_name)
            end
            @avatar.get_treasures(item[:type],item[:id],item[:sct_type],item[:num])
            @avatar.present_has_received = true
          end

          SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] #{name_list.join("+")}")
          msg = name_list.join("+").force_encoding('UTF-8')

        end

        sc_clamps_click_success(msg)
      end

      def cs_get_notice_selectable_item(args)
        SERVER_LOG.info("<UID:#{@uid}>#{$SERVER_NAME}: [#{__method__}] args:#{args}")
        if @avatar
          @avatar.get_notice_selectable_item(args)
        end
      end

      # 渦関連Noticeのみ削除
      def cs_profound_notice_clear(n)
        SERVER_LOG.info("<UID:#{@uid}>RaidDataServer: [#{__method__}] n:#{n}")
        if @avatar
          @avatar.profound_notice_clear(n)
        end
      end

      def cs_deck_max_check
        SERVER_LOG.info("*** deck max check")
        sc_deck_max_check_result(@avatar.get_all_deck_num_include_payment_log < Unlight::DECK_MAX)
      end

      # アバターにイベントを登録
      def regist_avatar_event
        @avatar.init
        @avatar.add_finish_listener_use_energy_event(method(:use_energy_event_handler))
        @avatar.add_finish_listener_use_free_duel_count_event(method(:use_free_duel_count_event_handler))
        @avatar.add_finish_listener_update_remain_time_event(method(:update_remain_time_event_handler))
        @avatar.add_finish_listener_update_energy_max_event(method(:update_energy_max_event_handler))
        @avatar.add_finish_listener_update_friend_max_event(method(:update_friend_max_event_handler))
        @avatar.add_finish_listener_update_part_max_event(method(:update_part_max_event_handler))
        @avatar.add_finish_listener_get_exp_event(method(:get_exp_event_handler))
        @avatar.add_finish_listener_level_up_event(method(:level_up_event_handler))
        @avatar.add_finish_listener_get_deck_exp_event(method(:get_deck_exp_event_handler))
        @avatar.add_finish_listener_deck_level_up_event(method(:deck_level_up_event_handler))
        @avatar.add_finish_listener_update_gems_event(method(:update_gems_event_handler))
        @avatar.add_finish_listener_item_get_event(method(:item_get_event_handler))
        @avatar.add_finish_listener_item_use_event(method(:item_use_event_handler))
        @avatar.add_finish_listener_part_get_event(method(:part_get_event_handler))
        @avatar.add_finish_listener_coin_use_event(method(:coin_use_event_handler))
        @avatar.add_finish_listener_slot_card_get_event(method(:slot_card_get_event_handler))
        @avatar.add_finish_listener_chara_card_get_event(method(:chara_card_get_event_handler))
        @avatar.add_finish_listener_update_result_event(method(:update_result_event_handler))

        @avatar.add_finish_listener_deck_get_event(method(:deck_get_event_handler))

        @avatar.add_finish_listener_update_recovery_interval_event(method(:update_recovery_interval_event_handler))
        @avatar.add_finish_listener_update_quest_inventory_max_event(method(:update_quest_inventory_max_event_handler))
        @avatar.add_finish_listener_update_exp_pow_event(method(:update_exp_pow_event_handler))
        @avatar.add_finish_listener_update_gem_pow_event(method(:update_gem_pow_event_handler))
        @avatar.add_finish_listener_update_quest_find_pow_event(method(:update_quest_find_pow_event_handler))
        @avatar.add_finish_listener_vanish_part_event(method(:vanish_part_event_handler))

        @avatar.add_finish_listener_achievement_clear_event(method(:achievement_clear_event_handler))
        @avatar.add_finish_listener_add_new_achievement_event(method(:add_new_achievement_event_handler))
        @avatar.add_finish_listener_delete_achievement_event(method(:delete_achievement_event_handler))

        @avatar.add_finish_listener_start_sale_event(method(:start_sale_event_handler))

        @avatar.add_finish_listener_update_achievement_info_event(method(:update_achievement_info_event_handler))
        @avatar.add_finish_listener_drop_achievement_event(method(:drop_achievement_event_handler))
        @avatar.add_finish_listener_change_favorite_chara_id_event(method(:change_favorite_chara_id_event_handler))

        @avatar.add_finish_listener_update_combine_weapon_data_event(method(:update_combine_weapon_data_event_handler))

      end

      # 行動力を使用する
      def use_energy_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_use_energy] #{ret}")
        sc_energy_info(ret[0],ret[1])
      end

      # フリーデュエル回数をアップデート
      def use_free_duel_count_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_use_fdc] #{ret}")
        sc_free_duel_count_info(ret)
      end

      # 行動力のMAXが更新
      def update_energy_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_energy_max] #{ret}")
        sc_update_energy_max(ret)
      end

      # フレンドのMAXが更新
      def update_friend_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_friend_max] #{ret}")
        sc_update_friend_max(ret)
      end

      # パーツのMAXが更新
      def update_part_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_part_max] #{ret}")
        sc_update_part_max(ret)
      end

      # 残り時間が更新
      def update_remain_time_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_remain_time_update] #{ret}")
        sc_energy_info(ret[0],ret[1])
      end

      # 経験値獲得
      def get_exp_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_exp] #{ret}")
        sc_get_exp(ret)
      end

      # レベルアップ
      def level_up_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_level_up] #{ret}")
        sc_level_up(ret)
      end

      # デッキ経験値獲得
      def get_deck_exp_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_deck_exp] #{ret}")
        sc_get_deck_exp(ret)
      end

      # デッキレベルアップ
      def deck_level_up_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_deck_level_up] #{ret}")
        sc_deck_level_up(ret)
      end

      # Gemの更新
      def update_gems_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_gems] #{ret}")
        sc_update_gems(ret)
      end

      # 勝敗の更新
      def update_result_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_result] #{ret}")
        sc_update_result(ret[0],ret[1],ret[2],ret[3])
      end

      # アイテムゲット
      def item_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_item] invID:#{ret[0]} itemID:#{ret[1]}")
        sc_get_item(ret[0], ret[1])
      end

      # アイテムを使用した
      def item_use_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_use_item] #{ret}")
        sc_use_item(ret)
      end

      # パーツゲット
      def part_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_part_item] invID:#{ret[0]} itemID:#{ret[1]}")
        sc_get_part(ret[0], ret[1])
      end
      # コインを使用した
      def coin_use_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_use_coin] #{ret}")
        sc_use_coin(ret.join(","))
      end

      # スロットカードを取得する
      def slot_card_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_slot_card] invID:#{ret[0]} type:#{ret[1]} cardID:#{ret[2]}")
        sc_get_slot_card(ret[0], ret[1], ret[2])
      end

      # キャラカードを取得する
      def chara_card_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_chara_card] invID:#{ret[0]} cardID:#{ret[1]}")
        sc_get_chara_card(ret[0], ret[1])
      end

      # AP回復時間が更新された
      def update_recovery_interval_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_rec_int] #{ret}")
        sc_update_recovery_interval(ret)
      end

      # クエスト所持数が更新された
      def update_quest_inventory_max_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_quest_inv_max] #{ret}")
        sc_update_quest_inv_max(ret)
      end

      # EXPの倍率が更新された
      def update_exp_pow_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_exp_pow] #{ret}")
        sc_update_exp_pow(ret)

      end

      # GEMの倍率が更新された
      def update_gem_pow_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_gem_pow] #{ret}")
        sc_update_gem_pow(ret)

      end

      # クエストゲット時間が更新された
      def update_quest_find_pow_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_find_pow] #{ret}")
        sc_update_quest_find_pow(ret)
      end

      # パーツが消滅した
      def vanish_part_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_vasnish_parts] invID #{ret}")
        sc_vanish_part(ret[0],ret[1])
      end

      # アチーブメントがクリアされた
      def achievement_clear_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_achievement_clear] #{ret}")
        sc_achievement_clear(*ret)
      end

      # アチーブメントが追加された
      def add_new_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_add_new_achievement] ID: #{ret}")
        sc_add_new_achievement(ret)
      end

      # アチーブメントが追加された
      def delete_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_delete_achievement] ID: #{ret}")
        sc_delete_achievement(ret)
      end

      # セールが開始された
      def start_sale_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_update_sale_rest_time] ret: #{ret}")
        sc_update_sale_rest_time(ret[0],ret[1])
      end

      # アイテムゲット
      def deck_get_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_get_deck] #{ret}")
        sc_create_deck_success(*ret)
      end

      # アチーブメントが更新された
      def update_achievement_info_event_handler(target,ret)
        sc_update_achievement_info(ret[0],ret[1],ret[2],ret[3],ret[4])
      end

      # アチーブメントを完全削除
      def drop_achievement_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_drop_achievement] ID: #{ret}")
        sc_drop_achievement(ret)
      end

      # お気に入りキャラIDを設定する
      def change_favorite_chara_id_event_handler(target, ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] ID: #{ret}")
        sc_change_favorite_chara_id(ret)
      end

      # 合成武器情報を更新する
      def update_combine_weapon_data_event_handler(target,ret)
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}]  #{ret}")
        sc_update_combine_weapon_data(*ret)
      end


      # ======================================
      # 送信コマンド
      # =====================================
      # 押し出し関数
      def pushout()
        online_list[@player.id].close_connection
        online_list[@player.id].player = nil
      end

      # ログイン時の処理
      def do_login
        if @player.avatars.size > 0
          @avatar = @player.avatars[0]
          regist_avatar_event
          # タグの収集イベントONの時のみログインしたときに
          tag_collect_event_set_initial_avatar_item if TAG_COLLECT_EVENT_ON
          # クリスマスイベントのアバター衣装配布
          send_event_avatar_part if XMAS_EVENT_ON
          # クリア済みのAchieventの再計算を一度だけ行う
          st = Time.local(2012, 12, 20, 15, 00)
          @avatar.cleared_achievement_progress_update if @player.login_at < st
          # クエストイベント中ならクエストイベント用フラグを作製（ない場合のみ）
          @avatar.create_event_quest_flag #if QUEST_EVENT_FLAG
          # イベント開始時アイテム配付処理
          event_start_item_send
          # # 1日セールスタート判定
          # 年内通算日が異なるならログインボーナス
          if @player.login_bonus_set
            # By_K2 (BP 1600 이상인 경우 무한의탑 입장권 지급 (기간제))
            if TOWER_LOGIN_BONUS_FLAG && @avatar.point >= 1600
                b = @avatar.get_login_tower_bonus
                sc_login_bonus(b[0], b[1], b[2])
                SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_login_tower_bonus] tg_type:#{b[0]} slot_type:#{b[1]} value or id:#{b[2]}")
            end

            bns = @avatar.get_login_bonus
            bns.each do |b|
              sc_login_bonus(b[0], b[1], b[2], b[3])
              SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_login_bonus] tg_type:#{b[0]} slot_type:#{b[1]} value or id:#{b[2]}")
            end
            @avatar.reset_free_duel_count
            # デイリーレコードチェック
            @avatar.check_set_end_at_records
            # すべての週間レコードチェック
            @avatar.all_week_record_check
          end

          @avatar.update_check(false)

          SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [sc_avatar_info] ##{@avatar.name} ap:#{@avatar.energy}, #{@avatar.get_next_recovery_time(false)}")
        else

        end
      end

      # ログアウト時の処理
      def do_logout
        delete_connection
      end

      #
      #
      def tag_collect_event_set_initial_avatar_item
        now = Time.now.utc
        st = TAG_INIT_CHECK_ST
        ed = TAG_INIT_CHECK_ED
        # 現在の2012/11/22日から2012/12/06の間のみ有功
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [tag_collent_event_set] st#{st}} :ed #{ed},now#{now}")
        if st < now && ed >now
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [tag_collent_event_set] login_at #{@player.login_at}st#{st}}")
          # 2012/11/22日より前にログインしていたら（一度だけアイテムを配る）
          if @player.login_at < st
            @avatar.get_item(EVENT_REWARD_ITEM[RESULT_3VS3_WIN][@avatar.id.to_s[-1].to_i])
          end
        end

      end

      # ログイン時にサンタ帽を配布する
      def send_event_avatar_part
        now = Time.now
        t = Time.local(2012, 12, 27, 15, 00)
        # 現在の2012/12/12日から有功
        if t < now
        SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [send_event_avatar_part]")
          # X人に1人サンタ帽配る
          if @player.login_at < t
            @avatar.get_part(QEV_XMAS_PART_ID)
          end
        end
      end

      # イベント開始時アイテム配付
      def event_start_item_send
        if @player.login_at < EVENT_START_ITEM_SEND_CHECK_AT
          SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] item_id:356")
          # ダウジングロッド改1
          @avatar.get_item(EVENT_START_ITEM_SEND_ID)

          if PLUS_EVENT_LOGIN_BONUS_FLAG
            if @player.login_at && (@player.login_at.utc + LOGIN_BONUS_OFFSET_TIME).yday != (Time.now.utc + LOGIN_BONUS_OFFSET_TIME).yday || @player.login_at.utc + 60*60*24 < Time.now.utc  # 60*60*9時間ずらす
            else
              SERVER_LOG.info("<UID:#{@uid}>LobbyServer: [#{__method__}] event login bonus send.")
              # 追加イベントログインボーナスアリで既にログインボーナス取得している場合、
              trs = EVENT_LOGIN_BONUS
              @avatar.get_treasures(trs[0], trs[2], trs[1], trs[3])
            end
          end
        end
      end
    end
  end
