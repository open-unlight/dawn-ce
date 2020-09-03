# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # パーツのインベントリクラス
  class PartInventory < Sequel::Model
    # 他クラスのアソシエーション
    many_to_one :avatar         # アバターを持つ
    many_to_one :avatar_part    # アバターパーツを持つ

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer :avatar_id, :index=>true #, :table => :avatars
      integer :avatar_part_id#, :table => :avatar_parts
      integer     :used,  :default => 0
      datetime    :end_at       # 新規追加2011/08/01
      integer     :before_avatar_id,:default => 0 #, :table => :avatars
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    validates do
    end

    # DBにテーブルをつくる
    if !(PartInventory.table_exists?)
      PartInventory.create_table
    end

   # # テーブル内容のアップデート
    DB.alter_table :part_inventories do
      add_column :end_at, :datetime  unless Unlight::PartInventory.columns.include?(:end_at)  # 新規追加2011/07/25
      add_column :before_avatar_id, :integer, :default => 0 unless Unlight::PartInventory.columns.include?(:before_avatar_id)  # 新規追加2011/07/25
    end

    # 装備しているか？
    def equiped?
      if self.avatar_id ==0
        false
      else
        self.used&Unlight::APS_USED == Unlight::APS_USED
      end
    end

    # アクティベートされているか
    def activated?
      if self.avatar_id ==0
        false
      else
        self.used&Unlight::APS_ACTIVATED == Unlight::APS_ACTIVATED
      end
    end


    # 装備する
    def equip(saving = true)
      self.used ||=0
      unless equiped?
        self.used |= Unlight::APS_USED
        activate
        self.avatar_part.attach(self.avatar) if self.avatar&&self.avatar_part
        self.save_changes if saving
      end
    end

    # 装備を外す
    def unequip( saving = true)
      # 装備していたら外す
      if equiped?
        self.used ^= Unlight::APS_USED
        self.avatar_part.detach(self.avatar)
        self.save_changes if saving
      end
    end


    # アクティベート（タイマーを動かす）
    def activate()
      # アクティベート済みでないなら
      unless  self.activated?
        if self.avatar_part&&self.avatar_part.duration !=0
          self.end_at = Time.now.utc + self.avatar_part.duration * 60
          self.used |= Unlight::APS_ACTIVATED
        end
      end
    end

    # 機能が消失したか？
    def work_end?
      ret = false
      if self.end_at
        ret = Time.now.utc >self.end_at
        if ret
          self.unequip(false)
          self.vanish_part
        end
      end
      ret
    end

    # パーツの消滅
    def vanish_part
      self.before_avatar_id = self.avatar_id
      self.avatar_id = 0
      self.save_changes
    end

    def get_end_at(now)
      ret = 0
        if self.end_at
          ret = (self.end_at - now).to_i
        else
          ret= 0
        end
      ret
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

  end
end
