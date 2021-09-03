# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # ゲームセッションログ
  class QuestLog < Sequel::Model
    # ログのタイプ（書き込んだもの）
    TYPE_AVATAR, TYPE_CHARA, TYPE_QUEST, TYPE_DUEL, TYPE_SYSTEM = (0..4).to_a
    # アイコンを決めるクエスト用のID
    Q_NORMAL, Q_BATTLE, Q_ALART, Q_GOT, = (0..3).to_a
    # アイコンを決めるデュエル用のID
    D_WIN, D_LOSE = (0..1).to_a

    # 他クラスのアソシエーション
    many_to_one :avatar # アバターを持つ

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # バリデーションの設定
    validates do
    end

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def to_text
      ret = QuestLog::cache_store.get("quest_log:#{id}")
      unless ret
        a = []
        a << avatar_id
        a << type_no
        a << type_id
        a << name
        a << body
        a << created_at.to_i.to_s
        ret = a.join(',')
        QuestLog::cache_store.set("quest_log:#{id}", ret)
      end
      ret
    end

    # リミットずつのログをもらう(1ページスタート)
    def QuestLog::get_page(a_id, page)
      ret = []
      ids = []
      content = []
      QuestLog.filter(avatar_id: a_id).limit(QUEST_LOG_LIMIT, page * QUEST_LOG_LIMIT).order(Sequel.desc(:created_at)).all.each do |a|
        ids << a.id
      end
      ids.join(',')
    end

    # ログを書く
    def QuestLog::write_log(a_id, t, t_id, n, b)
      ret = 0
      QuestLog.new do |d|
        d.avatar_id = a_id
        d.type_no = t
        d.type_id = t_id
        d.name = n
        d.body = b
        d.save_changes
        ret = d.id
      end
      ret
    end
  end
end
