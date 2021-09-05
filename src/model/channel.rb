# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # ゲームロビーのチャンネルクラス
  class Channel < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
    validates do
    end

    # 現在の部屋リスト
    @@channel_list = {}
    Channel.all.each { |a| @@channel_list[a.id] = a }

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def self.all_order
      order(:order)
    end

    def self.channel_list
      @@channel_list
    end

    def self.order_id(channel_id)
      @@channel_list.order(:order)[channel_id].id
    end

    def self.destroy_all_list
      # 現在の部屋リスト
      @@channel_list = {}
      Channel.all.each do |a|
        @@channel_list[a.id] = a
      end
    end

    def boot(update = true)
      self.count = 0 if update
      self.state = DSS_OK
      save_changes
    end

    # ゲームサーバ終了時に自分のIDのチャンネルを閉じる
    def shut_down
      self.state = DSS_DOWN
      save_changes
    end

    def room_list
      @room_list ||= OrderHash.new
    end

    def room_list_count
      @room_list.count
    end

    def player_list
      @player_list ||= []
    end

    # クイックマッチのチャンネルか判定
    def is_radder?
      (rule == CRULE_HIGH || rule == CRULE_RADDER || rule == CRULE_COST_A || rule == CRULE_COST_B)
    end

    # プレイヤーを入場させる
    def join_player(player_id)
      player_list << player_id unless player_list.include?(player_id)
    end

    # プレイヤーを排出する
    def exit_player(player_id)
      player_list.delete(player_id)
    end

    # 全てのチャンネル情報を取得する
    def self.get_channel_list_info(server_type)
      ret = CACHE.get("channel_list_info_#{server_type}")
      unless ret
        ret_id = []
        ret_name = []
        ret_rule = []
        ret_max = []
        ret_host = []
        ret_port = []
        ret_chat_host = []
        ret_chat_port = []
        ret_duel_host = []
        ret_duel_port = []
        ret_watch_host = []
        ret_watch_port = []
        ret_state = []
        ret_caption = []
        ret_count = []
        ret_penalty_type = []
        ret_cost_limit_min = []
        ret_cost_limit_max = []
        ret_watch_mode = []
        all_order.each do |c|
          if c.server_type == server_type
            ret_id << c.id
            ret_name << c.name
            ret_rule << c.rule
            ret_max << c.max
            ret_host << c.host
            ret_port << c.port
            ret_chat_host << c.chat_host
            ret_chat_port << c.chat_port
            ret_duel_host << c.duel_host
            ret_duel_port << c.duel_port
            ret_watch_host << c.watch_host
            ret_watch_port << c.watch_port
            ret_state << c.state
            ret_caption << c.caption
            ret_count << c.count
            ret_penalty_type << c.penalty_type
            ret_cost_limit_min << c.cost_limit_min
            ret_cost_limit_max << c.cost_limit_max
            ret_watch_mode << c.watch_mode
          end
        end
        ret = [
          ret_id.join(','),
          ret_name.join(','),
          ret_rule.join(','),
          ret_max.join(','),
          ret_host.join(','),
          ret_port.join(','),
          ret_duel_host.join(','),
          ret_duel_port.join(','),
          ret_chat_host.join(','),
          ret_chat_port.join(','),
          ret_watch_host.join(','),
          ret_watch_port.join(','),
          ret_state.join(','),
          ret_caption.join(','),
          ret_count.join(','),
          ret_penalty_type.join(','),
          ret_cost_limit_min.join(','),
          ret_cost_limit_max.join(','),
          ret_watch_mode.join(',')
        ]
        CACHE.set("channel_list_info_#{server_type}", ret, 120)
      end
      ret
    end

    # ルームリストにプレイヤーが存在するか？
    # 返値:存在する場合そのマッチクラスのID
    def player_exist?(player_id)
      ret = nil
      unless room_list.empty?
        room_list.each_value do |r|
          ret = r if r&.include_player?(player_id)
        end
      end
      ret
    end

    def update_count
      self.count = player_list.size
      save_changes
    end

    # 混雑率
    def congestion_rate
      count / max * 100
    end

    # 自分の次のチャンネルを返す存在しなければnil
    def next_channel
      ret = nil
      cs = Channel.filter({ rule: rule }).filter(server_type: server_type).order(:order).all
      i = false
      cs.each do |c|
        if i
          ret = c
        else
          i = true if c.id == id
        end
      end
      ret
    end

    # 自分の前のチャンネルを返す存在しなければnil
    def before_channel
      ret = nil
      cs = Channel.filter({ rule: rule }).filter(server_type: server_type).order(:order).all
      i = false
      cs.each_index do |i|
        if cs[i].id == id
          ret = cs[i - 1] if cs[i - 1] && i.positive?
        end
      end
      ret
    end

    def cpu_matching_type?
      cpu_matching_type
    end

    def cpu_matching_condition?
      cpu_matching_condition
    end
  end
end
