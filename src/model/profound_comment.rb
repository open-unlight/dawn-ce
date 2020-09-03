# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 渦のインベントリクラス
  class ProfoundComment < Sequel::Model
    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    one_to_many :quests         # 複数のクエストデータを保持

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :profound_id,:index=>true     # 渦のID
      integer     :avatar_id,:index=>true       # アバターID
      String      :name            # アバター名
      String      :comment         # 渦へのコメント
      datetime    :created_at
      datetime    :updated_at
    end

    # DBにテーブルをつくる
    if !(ProfoundComment.table_exists?)
      ProfoundComment.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # コメントのキャッシュ保存時間
    COMMENT_CACHE_TIME = 10

    # コメントの保存
    def ProfoundComment::set_comment(prf_id,a_id,a_name,comment)
      puts "#{__method__}"
      ret = ProfoundComment.new do |pc|
        pc.profound_id = prf_id
        pc.avatar_id   = a_id
        pc.name        = a_name
        pc.comment     = comment.force_encoding("UTF-8")
        pc.save
      end
      cache_key = "prf_comment_#{prf_id}"
      list = CACHE.get(cache_key)
      if list
        clone_list = list.clone
        clone_list << { :id => ret.id, :a_id => ret.avatar_id, :comment => ret.comment, :a_name => ret.name }
        CACHE.set(cache_key,clone_list,COMMENT_CACHE_TIME)
      end
      ret
    end

    # コメントの取得
    def ProfoundComment::get_comment(prf_id,last_id=0,cache=true)
      ret = []
      cache_key = "prf_comment_#{prf_id}"
      list = CACHE.get(cache_key) if cache
      st = Time.now.utc - 60*5
      unless list
        list = []
        ProfoundComment.limit(100).filter([:profound_id => prf_id]).filter{created_at > st }.order(:id).all.each do |pc|
          list << { :id => pc.id, :a_id => pc.avatar_id, :comment => pc.comment, :a_name => pc.name  }
        end
      end
      list.each do |pc|
        if pc[:id] > last_id
          ret << pc
          last_id = pc[:id]
        end
      end
      CACHE.set(cache_key,list,COMMENT_CACHE_TIME) if list&&list.size > 0
      [ret,last_id]
    end
  end
end
