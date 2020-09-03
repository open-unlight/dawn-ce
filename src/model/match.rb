# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

require 'digest/md5'

module Unlight
  # マッチクラス
  class Match
    attr_accessor  :id, :name, :stage, :rule, :player_array, :state, :room_list, :option, :level, :cpu_card_data_id
    attr_reader  :avatar_ids

    # 部屋に入れる人数
    ROOM_CAP = 2

    # コンストラクタ
    def initialize(channel, player_id, name, stage, rule, option = 0, level = 0, cpu_card_data_id = 0)
      @id = Digest::MD5.hexdigest((Time.now.to_i+rand(1024)).to_s)[0..10]       # 部屋番号(主キー)
      @name = name                # 部屋の表示名
      @stage = stage
      @rule = rule               # 対戦ルール
      @option = option           # オプション、友達のみ、自由
      @level = level             # 制限レベル。自由 それ以下
      @player_array = []       # 対戦者のリスト
      @player_array << Player[player_id]
      @channel = channel
      @channel.room_list[@id] = self
      @cpu_card_data_id = cpu_card_data_id
      @dirty_flag = true
      @info_str = ""
    end

    def cpu?
      (@cpu_card_data_id != 0)
    end

    # 部屋を作る
    # 失敗ならNil,成功ならMatchObjを返す
    def Match::create_room(channel, player_id, name, stage, rule, option, level, cpu_card_data_id = PLAYER_MATCH)
      # すでにプレイヤーがマッチに入ってないか？
      if room_from_player_id(player_id, channel.id)
        # すでに作っていたら前の部屋から出る(べきか？？)
        exit_room(channel, player_id) if cpu_card_data_id == PLAYER_MATCH
      else
        # 作ってなかったら部屋を作る
        ret = Match.new(channel, player_id, name, stage, rule, option, level, cpu_card_data_id)
      end
      ret
    end

    # 部屋の中にPlayerがいるかIDで確認
    def include_player?(pl_id)
      ret = false
      @player_array.each do |pl|
        ret = true if pl.id == pl_id
      end
      ret
    end

    # 指定した部屋に入室する
    # 失敗ならnil、成功なら自分のプレイヤーの配列
    def Match::room_join(channel, room_id, player_id)
      ret = nil
      pl = Player[player_id]
      if DUEL_IP_CHECK&&pl&&channel.room_list[room_id].player_array.first&&pl.last_ip == channel.room_list[room_id].player_array.first.last_ip && (pl.role != ROLE_ADMIN )
        return false
      end
      if channel&&channel.room_list[room_id]
        a = channel.room_list[room_id].player_array
        # 部屋が満杯でなく、かつ他の部屋にすでに入室していない場合のみ入室する
        if a.size < ROOM_CAP&& !(room_from_player_id(player_id, channel.id))
          channel.room_list[room_id].enter_player(pl)
          ret = []
          a.each{ |c| ret << c.id}
          ret
        end
      end
      ret
    end

    def Match::initialize

    end

    # 部屋から出る
    def delete_player(player_id)
      d = @player_array.reject!{|pl|pl.id == player_id }
      # 人間が残っているかチェックする
      # 一人でも削除されていたら問答無用で全部削除
      # 削除が走ったがJOIN済みがおらずに、残ったプレイヤーがいるならば削除しない（作られた部屋なので）
      if d
        player_exist =false
      else
        player_exist =false
        @player_array.each{ |pl| player_exist = true if pl} # 一人も削除されずにプレイヤーが残っている？
        # プレイヤーが部屋から空ならばすべて空にする
      end
      # プレイヤーが存在しないならArrayをクリア
      unless  (player_exist)
        @player_array.clear
      end
      !player_exist
    end


    # 部屋をでる(exit_room)
    def Match::exit_room(channel, player_id)
      # 自身を退室
      ret = nil
      if channel
        channel.room_list.each_value do |r|
          if r.delete_player(player_id)
            # もし自分が最後の退出者ならば部屋を消す
            ret = delete_room(channel, r.id)
          end
        end
      end
      ret
    end

    # 部屋を消す
    def Match::delete_room(channel, room_id)
      channel.room_list.reject! { |id, room|
        room.player_array.size == 0
      }
    end


    # 指定した部屋にAIが入室する
    # 失敗ならnil、成功なら自分のプレイヤーの配列
    def Match::room_ai_join(channel, room_id, ai_id)
      ret = nil
      if channel&&channel.room_list[room_id]
        a = channel.room_list[room_id].player_array
        # 部屋が満杯でないなら入る
        if a.size < ROOM_CAP
          channel.room_list[room_id].enter_player(Player[ai_id])
          ret = []
          a.each{ |c| ret << c.id}
          ret = a       # 自分入った位置
        end
      end
      ret
    end

    # 指定した部屋のプレイヤーIDを返す
    def Match::get_players(channel, room_id)
      channel.room_list[room_id].player_array if channel.room_list[room_id]
    end

   # 指定したプレイヤーが存在する場合すでにある部屋を返す
    def Match::room_from_player_id(player_id,ch)
      ret = nil
      room =  Channel.channel_list[ch].player_exist?(player_id)
      ret =  room if room if player_id != AI_PLAYER_ID
      ret
    end

    # 部屋の数を返す
    def Match::room_size(channel)
      channel.room_list.size
    end

    def Match::room_list_info_str(channel)
      ret = []
      channel.room_list.each_value do |r|
        ret << r.room_info_str.force_encoding("UTF-8")
      end
      ret.join(",")
    end


    # 0:id
    # 1:room_name
    # 2:stage_no
    # 3:rule
    # 4:avatar1_id
    # 5:avatar1_name
    # 6:avatar1_level
    # 7:avatar1_point
    # 8:avatar1_win
    # 9:avatar1_lose
    # 10:avatar1_draw
    # 11:avatar1_cc_0
    # 12:avatar1_cc_1
    # 13:avatar1_cc_2
    # 14:avatar2_id
    # 15:avatar2_name
    # 16:avatar2_level
    # 17:avatar2_point
    # 18:avatar2_win
    # 19:avatar2_lose
    # 20:avatar2_draw
    # 21:avatar2_cc_0
    # 22:avatar2_cc_1
    # 23:avatar2_cc_2

    def room_info
      ret = []
      ret << id.force_encoding("UTF-8")
      ret << name.force_encoding("UTF-8")
      ret << stage
      ret << rule
      @avatar_ids = []
      i = 0
      while i < ROOM_CAP
        temp_player_avatar = nil
        temp_player = player_array[i]
        temp_player_avatar = temp_player.current_avatar if temp_player
        if temp_player_avatar
          @avatar_ids << temp_player_avatar.id
          ret << temp_player_avatar.id
          ret << temp_player_avatar.name.force_encoding("UTF-8")
          ret << temp_player_avatar.level
          ret << temp_player_avatar.point
          ret << temp_player_avatar.win
          ret << temp_player_avatar.lose
          ret << temp_player_avatar.draw
        else
          @avatar_ids << -1
          ret << -1
          ret << -1
          ret << -1
          ret << -1
          ret << -1
          ret << -1
          ret << -1
        end
        if i < player_array.size && player_array.size == ROOM_CAP && temp_player
          if temp_player.id == AI_PLAYER_ID
            ret << CpuCardData[cpu_card_data_id].current_cards_ids
          else
            ret << temp_player_avatar.current_cards_ids
          end
        else
          ret << [-1,-1,-1]
        end
        i += 1
      end
      ret
    end

    def room_info_str
      if @dirty_flag
        @info_str = room_info.join(",")
        @dirty_flag = false
      end
      @info_str
    end

    def enter_player(pl)
      @dirty_flag = true
      @player_array << pl
    end

  end

end
