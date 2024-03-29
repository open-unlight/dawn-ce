# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight
  # 課金アイテムクラス
  class PaymentLog < Sequel::Model
    many_to_one :player # プレイヤーに複数所持される
    many_to_one :real_money_item # プレイヤーに複数所持される

    STATE_CHECK = 0             # チェックしただけ
    STATE_PAYED = 1             # 支払い済み（アイテムまだ付与してない）
    STATE_END   = 2             # アイテム付与済み
    STATE_REFUND = 3 # 払い戻しの希望があると言うメッセージ
    STATE_NOT_ALLOW_ITEM = 4 # お金だけとってしまった状態。存在しない、またはセールが切れたのにセール品を買おうとした

    # プラグインの設定
    plugin :validation_class_methods
    plugin :hook_class_methods

    # バリデーションの設定
    Sequel::Model.plugin :validation_class_methods

    # インサート時の前処理
    before_create do
      self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
      self.updated_at = Time.now.utc
    end

    def item_got
      self.result = STATE_END
      save_changes
    end
  end
end
