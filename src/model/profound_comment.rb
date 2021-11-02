# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 渦のインベントリクラス
  class ProfoundComment < Sequel::Model
    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # 他クラスのアソシエーション
    one_to_many :quests # 複数のクエストデータを保持

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
    def self.set_comment(prf_id, a_id, a_name, comment)
      puts __method__.to_s
      ret = ProfoundComment.new do |pc|
        pc.profound_id = prf_id
        pc.avatar_id   = a_id
        pc.name        = a_name
        pc.comment     = comment.force_encoding('UTF-8')
        pc.save_changes
      end
      cache_key = "prf_comment_#{prf_id}"
      list = CACHE.get(cache_key)
      if list
        clone_list = list.clone
        clone_list << { id: ret.id, a_id: ret.avatar_id, comment: ret.comment, a_name: ret.name }
        CACHE.set(cache_key, clone_list, COMMENT_CACHE_TIME)
      end
      ret
    end

    # コメントの取得
    def self.get_comment(prf_id, last_id = 0, cache = true)
      ret = []
      cache_key = "prf_comment_#{prf_id}"
      list = CACHE.get(cache_key) if cache
      st = Time.now.utc - 60 * 5
      unless list
        list = []
        ProfoundComment.limit(100).where(profound_id: prf_id).where { created_at > st }.order(:id).all.each do |pc|
          list << { id: pc.id, a_id: pc.avatar_id, comment: pc.comment, a_name: pc.name }
        end
      end
      list.each do |pc|
        if pc[:id] > last_id
          ret << pc
          last_id = pc[:id]
        end
      end
      CACHE.set(cache_key, list, COMMENT_CACHE_TIME) if list && !list.empty?
      [ret, last_id]
    end
  end
end
