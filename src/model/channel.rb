# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # ゲームロビーのチャンネルクラス
  class Channel < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :default => "新規サーバ"
      integer     :order,:default => 0
      integer     :rule,:default => 0
      integer     :max,:default => Unlight::DUEL_CHANNEL_MAX
      String      :host_name, :default => ""
      String      :host, :default => ""
      integer     :port, :default => 0
      String      :chat_host, :default => ""
      integer     :chat_port, :default => 0
      String      :duel_host, :default => ""
      integer     :duel_port, :default => 0
      String      :watch_host, :default => ""
      integer     :watch_port, :default => 0
      integer     :state,:default =>  Unlight::DSS_DOWN
      String      :caption, :default =>""
      integer     :count, :default => 0
      integer     :penalty_type, :default => 0           # 切断時のペナルティタイプ 0:AI,1:Abort
      integer     :watch_mode, :default => 0             # 観戦モード 0:OFF,1:ON
      integer     :cost_limit_min, :default => 0         # コスト制限つきの場合の最小値、maxが0の場合無効
      integer     :cost_limit_max, :default => 0         # コスト制限つきの場合の最大値、minが0の場合無効
      integer     :cpu_matching_type, :default => 0      # CPUとマッチする場合、何を基準に相手を決めるか
      String      :cpu_matching_condition, :default =>"" # マッチ条件
      integer     :server_type, :default => 0 # tinyint(DB側で変更) 新規追加 2016/11/24
      datetime    :created_at
      datetime    :updated_at
    end

    # DBにテーブルをつくる
    if !(Channel.table_exists?)
      Channel.create_table
    end


    DB.alter_table :channels do
      add_column :count, :integer, :default => 0 unless Unlight::Channel.columns.include?(:count)  # 新規追加2011/07/25
      add_column :penalty_type, :integer, :default => 0 unless Unlight::Channel.columns.include?(:penalty_type)  # 新規追加2012/06/21
      add_column :cost_limit_min, :integer, :default => 0 unless Unlight::Channel.columns.include?(:cost_limit_min)  # 新規追加2012/06/21
      add_column :cost_limit_max, :integer, :default => 0 unless Unlight::Channel.columns.include?(:cost_limit_max)  # 新規追加2012/06/21
      add_column :watch_mode, :integer, :default => 0 unless Unlight::Channel.columns.include?(:watch_mode)  # 新規追加2013/01/04
      add_column :cpu_matching_type, :integer, :default => 0 unless Unlight::Channel.columns.include?(:cpu_matching_type)  # 新規追加2015/07/13
      add_column :cpu_matching_condition, String, :default => "" unless Unlight::Channel.columns.include?(:cpu_matching_condition)  # 新規追加2015/07/13
      add_column :server_type, :integer, :default => 0 unless Unlight::Channel.columns.include?(:server_type)  # 新規追加 2016/11/24
    end

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods
     validates do
    end


    # 現在の部屋リスト
    @@channel_list = { }
    Channel.all.each{|a| @@channel_list[a.id] = a }

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    def Channel::all_order
      self.order(:order)
    end

    def Channel::channel_list
      @@channel_list
    end

    def Channel::order_id(channel_id)
      @@channel_list.order(:order)[channel_id].id
    end

    def Channel::destroy_all_list
      # 現在の部屋リスト
      @@channel_list ={ }
      Channel.all.each{|a|
        @@channel_list[a.id] = a }
    end

    def boot(update = true)
      self.count = 0 if update
      self.state = DSS_OK
      self.save_changes
    end

    # ゲームサーバ終了時に自分のIDのチャンネルを閉じる
    def shut_down
      self.state = DSS_DOWN
      self.save_changes
    end

    def room_list
      @room_list||=OrderHash.new
    end

    def room_list_count
      @room_list.count
    end

    def player_list
      @player_list||=[]
    end

    # クイックマッチのチャンネルか判定
    def is_radder?
      (self.rule == CRULE_HIGH || self.rule == CRULE_RADDER || self.rule == CRULE_COST_A || self.rule == CRULE_COST_B)
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
    def Channel::get_channel_list_info(server_type)
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
        self.all_order.each do |c|
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
        CACHE.set("channel_list_info_#{server_type}",ret, 120)
      end
      ret
    end

    # ルームリストにプレイヤーが存在するか？
    # 返値:存在する場合そのマッチクラスのID
    def player_exist?(player_id)
      ret = nil
      if room_list.size > 0
        room_list.each_value do |r|
          ret = r if r.include_player?(player_id) if r
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
      self.count/self.max*100
    end


    # 自分の次のチャンネルを返す存在しなければnil
    def next_channel
      ret = nil
      cs = Channel::filter({:rule => self.rule}).filter(:server_type=>self.server_type).order(:order).all
      i = false
      cs.each do |c|
        if i
          ret = c
        else
          i = true if c.id == self.id
        end
      end
      ret
    end

    # 自分の前のチャンネルを返す存在しなければnil
    def before_channel
      ret = nil
      cs = Channel::filter({:rule => self.rule}).filter(:server_type=>self.server_type).order(:order).all
      i = false
      cs.each_index do |i|
        if cs[i].id == self.id
          ret = cs[i-1] if cs[i-1]&& i>0
        end
      end
      ret
    end

    def cpu_matching_type?
      self.cpu_matching_type
    end

    def cpu_matching_condition?
      self.cpu_matching_condition
    end

  end


end
