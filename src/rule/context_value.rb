# frozen_string_literal: true

module Unlight
  class ContextValue < Array
    attr_accessor :check_list

    # コンテキストのチェック用文字列リストを更新する
    def check_list_update
      @check_list = map do |context|
        "#{context[1..].map { |func| "#{func[1]}::#{func.last}" }.join('->')}\n"
      end.join
    end

    alias to_s check_list_update
  end
end
