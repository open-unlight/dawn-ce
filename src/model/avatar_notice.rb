# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # ゲームセッションログ
  class AvatarNotice < Sequel::Model
    # 他クラスのアソシエーション
    one_to_one :avatar

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods
    plugin :caching, CACHE, ignore_exceptions: true

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    # 内容をクリア
    def clear_body(n)
      refresh
      ret = []
      s = body.split('|')
      if n
        n.times do
          ret.push(s.pop)
        end
        self.body = s.join('|').force_encoding('UTF-8')
        save_changes
      end
      ret
    end

    # ログを書く
    def self.write_notice(an, a_id, b)
      if an
        if an.body == ''.force_encoding('UTF-8')
          an.body = b.to_s.force_encoding('UTF-8')
        else
          an.body += "|#{b}".force_encoding('UTF-8')
        end
        an.save_changes
      else
        AvatarNotice.new do |d|
          d.avatar_id = a_id
          d.body = b.to_s.force_encoding('UTF-8')
          d.save_changes
        end
      end
    end

    # スタックしている未送信のメッセージを配列で取得
    def self.get_massage_notice(time)
      AvatarNotice.where(Sequel.cast_string(:updated_at) > time).where(~{ body: '' }).all
    end

    # 特定のタイプのノーティスを引き抜く
    def get_type_message(types = [])
      refresh
      ret = []
      if types && !types.empty?
        body_arr = body.split('|')
        leave_arr = []
        body_arr.each do |mes|
          mes_arr = mes.split(':') if mes
          if types.include?(mes_arr.first.to_i)
            ret << mes
          else
            leave_arr << mes
          end
        end
        reset_arr = leave_arr + ret
        # 指定のものを引き抜いた分を再度Bodyに入れなおす
        self.body = reset_arr.join('|').force_encoding('UTF-8')
        save_changes
      end
      ret.join('|')
    end

    # 指定したノーティス以外を取得
    def get_other_type_message(types = [])
      refresh
      ret = []
      if types && !types.empty?
        body_arr = body.split('|')
        leave_arr = []
        body_arr.each do |mes|
          mes_arr = mes.split(':') if mes
          if types.include?(mes_arr.first.to_i)
            leave_arr << mes
          else
            ret << mes
          end
        end
        reset_arr = leave_arr + ret
        # 指定のものを引き抜いた分を再度Bodyに入れなおす
        self.body = reset_arr.join('|').force_encoding('UTF-8')
        save_changes
      end
      ret.join('|')
    end
  end
end
