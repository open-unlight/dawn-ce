# Unlight
# Copyright (c) 2019 CPA
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

require 'constants'

module Unlight
  # 暗号化クラス
  class Crypt
    # 単純なXOR処理を行うクラス
    class XOR
      # コンストラクタ（セッションキーを渡す）
      def initialize(s_key)
        @session_key = [s_key].pack('H*').unpack('C*')
        @session_key_len = @session_key.length
      end

      # 暗号化（String->Array）
      def encrypt(data)
        a = data.unpack("C*")
        alen = a.length
        des_a = []
        i = 0
        while i < alen
          des_a[i] = a[i] ^ @session_key[(i) % @session_key_len]
          i += 1
        end
        des_a.pack('C*')
      end
      alias decrypt encrypt
    end

    # 暗号化をしない
    class None
      def encrypt(data)
        data
      end

      def decrypt(data)
        data
      end
    end
  end
end
