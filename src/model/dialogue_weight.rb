# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # 台詞の選択ウェイトのクラス
  class DialogueWeight < Sequel::Model

    many_to_one:charactor        # プレイヤーに複数所持される
    many_to_one:dialogue        # プレイヤーに複数所持される

    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    # スキーマの設定
    set_schema do
      primary_key :id
      integer     :dialogue_type, :default => 0                                        # 会話のタイプ
      integer     :chara_id#, :table => :charactor                       # 会話の主体
      integer     :other_chara_id, :default => 0                       # 会話の相手
      integer     :dialogue_id#, :table => :dialogue                     # 会話
      integer     :weight, :default => 1                               # 出現ウェイト(最低１ないと出現しない)
      integer     :level, :default => 1                               # 相手のレベル制限
      datetime    :created_at
      datetime    :updated_at
    end

    # バリデーションの設定
    #    include Validation
     validates do
     end

   # DBにテーブルをつくる
    if !(DialogueWeight.table_exists?)
      DialogueWeight.create_table
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # クエストバトル開始時のダイアログ
    def DialogueWeight::quest_start_dialogue(chara_id, other_id, map_id, land_id)
      ret = ""
      # 専用
      dw = DialogueWeight.filter({ :dialogue_type=>DLG_QUEST_START_CHARA,
                                   :chara_id=>chara_id,
                                   :other_chara_id=>other_id,
                                   :weight=>map_id,
                                   :level=>land_id}).first
      # 汎用 (専用が無いとき)
      dw = DialogueWeight.filter({ :dialogue_type=>DLG_QUEST_START_CHARA,
                                   :chara_id=>chara_id,
                                   :other_chara_id=>chara_id,
                                   :weight=>map_id,
                                   :level=>land_id}).
        first unless dw
      ret = Dialogue[dw.dialogue_id].content if dw
      ret
    end

    def DialogueWeight::quest_clear_dialogue(chara_id, map_no)
      ret = []
      DialogueWeight.filter({:chara_id=>chara_id, :level => map_no, :dialogue_type=>DLG_QUEST_END_CHARA..DLG_QUEST_END_AVATAR}).order(Sequel.asc(:weight)).all.each do |r|
        ret << [Dialogue[r.dialogue.id].content, r.id, r.dialogue_type ]
      end
      ret
    end

    # ダイアログのIDを返す
    def DialogueWeight::get_dialogue(type, my_parent_id, my_chara_id, other_parent_id, other_chara_id,level)
      d = DialogueWeight[get_dialogue_id(type, my_parent_id, my_chara_id, other_parent_id, other_chara_id, level)]
      d ? d.dialogue : nil
    end

    # ダイアログのIDを返す
    def DialogueWeight::get_dialogue_id(type, my_parent_id, my_chara_id, other_parent_id, other_chara_id,level)
      ret = []
      # oc = CharaCard[other_id]
      ret = DialogueWeight.where([[:dialogue_type, type], [:chara_id, [my_parent_id, my_chara_id]], [:other_chara_id, [other_parent_id, other_chara_id]]]).
        filter((Sequel.cast_string(:level) <= level)).
        order(:chara_id).
        order_more(:other_chara_id).all

      if ret.empty?
        default_dialogue(my_parent_id, my_chara_id, type, level)
      else
        select_dialogue_id(ret)
      end
    end

    # デフォルトをダイアログを返す
    def DialogueWeight::default_dialogue(parent_id, chara_id, type, level)
      ret = Array.new(level, 0)
      if parent_id != chara_id
        DialogueWeight.filter({:chara_id=>chara_id, :other_chara_id=>chara_id, :dialogue_type=>type}).
          filter((Sequel.cast_string(:level) <= level)).all do |r|

          ret[r.level-1] = r
        end
      end

      DialogueWeight.filter({:chara_id=>parent_id, :other_chara_id=>parent_id, :dialogue_type=>type}).
        filter((Sequel.cast_string(:level) <= level)).all do |r|

        ret[r.level-1] = r if ret[r.level-1] == 0
      end

      ret.delete(0)

      select_dialogue_id(ret)
    end

    # ウェイトの配列をもらってどれかをランダムで選択する
    def DialogueWeight::select_dialogue_id(a)
      # ウェイトの合計値
      len = 0
      # 各ダイアログののウェイト位置
      weights = [0]
      # 各ダイアログのID
      ids = []
      a.each do |d|
        len += d.weight
        weights << len
        ids << d.id
      end
      r = rand(len)
      ids[weights.rindex{ |w| w<=r}]
    end

    # 出現率
    def current_percent
      len = 0
      DialogueWeight.filter({:chara_id=>self.chara_id, :other_chara_id => self.other_chara_id, :dialogue_type=>self.dialogue_type}).all.each do |r|
        len += r.weight
      end
      if len == 0
        len
      else
        self.weight*100/len
      end
    end


  end
end
