# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

 # デッキクラス
  class Deck  < BaseEvent

    attr_reader :deck_cards

    def initialize(c,stage = 0)
      super
      share_context(c)
      @using_cards = [] # 使用中のカード配列
      @used_cards = []  # 使用済みカード配列
      @stage = stage
      init_cards
      @deck_cards = @cards.clone.shuffle!
    end

    def init_cards()
      @cards = ActionCard.deck_with_context(context,self,@stage) # デッキの保存カード
    end
    private :init_cards

    def deck_init()
      @used_cards.shuffle!
      @deck_cards = @used_cards.clone
      @used_cards =[]
      @deck_cards.size
    end
    regist_event DeckInitEvent

    def draw_cards(num)
      ret_cards = []
      # デッキの残りが引く数より少ない場合捨て札を再シャッフル
      while ret_cards.size != num
        if @deck_cards.size < 1
          break if deck_init_event == 0 # シャッフルしてもデッキがからならやめる
        end
        c = @deck_cards.last
        ret_cards << c
        use_card(c)
      end
      ret_cards
    end
    regist_event DrawCardsEvent

    # 墓地からランダムに指定枚数だけ引く。
    # 枚数,タイプを指定可能。ある分だけを返す
    def draw_grave_cards(num=1, type=0)
      ret_cards = []

      # デッキの残りが引く数より少ない場合捨て札を再シャッフル
      while ret_cards.size < num

        # 指定タイプがなくなり次第抜ける
        card_list = type == 0 ? @used_cards : @used_cards.select{ |c| c.get_types.include?(type) }

        break if card_list.size == 0
        c = card_list.shuffle.last

        ret_cards << c if c
        use_grave_card(c)

      end
      ret_cards
    end
    regist_event DrawCardsEvent

    # 数値の小さいカードを優先的に引く, num:枚数, borderline:特定数値以下(0なら指定無し)
    def draw_low_cards(num, borderline=0)
      ret_cards = []
      # デッキの残りが引く数より少ない場合捨て札を再シャッフル
      while ret_cards.size != num
        if @deck_cards.size < 1
          break if deck_init_event == 0 # シャッフルしてもデッキがからならやめる
        end

        c = nil
        if borderline > 0
          c = @deck_cards.shuffle.select{ |ac| ac.event_no == 0 && ac.u_value <= borderline && ac.b_value <= borderline }.first
        else
          c = @deck_cards.sort_by{ |ac| [ac.u_value, ac.b_value] }.first
        end

        break if c.nil?
        ret_cards << c
        use_card(c)
      end
      ret_cards
    end
    regist_event DrawLowCardsEvent

    # カードを使う(デッキから引く場合)
    def use_card(card)
      c = @deck_cards.delete(card)
      @using_cards<< c if c
    end
    private :use_card

    # カードを使う(墓地から引く場合)
    def use_grave_card(card)
      c = @used_cards.delete(card)
      @using_cards<< c if c
    end

    # 山札にカードがあるか
    def exist?(card)
      @deck_cards.include?(card)
    end

    # カードを捨てる
    def throw_card(card)
      c = @using_cards.delete(card)
      @used_cards << c if c
      c.throwed_event if c
    end

    def empty?
      @deck_cards.size == 0
    end

    # Specにしか使われていない関数注意されたし
    def get_card(id)
      @cards[id-1]
    end

    def size
      @deck_cards.size
    end

    # すべてのカードにイベントリスナーを登録する
    def all_cards_add_event_listener(event, listener)
      @cards.each{ |c| c.send(event,listener)}
    end

    # すべてのカードのイベントリスナーをリムーブする
    def all_cards_remove_all_event_listener()
      @cards.each{ |c|
        c.remove_all_event_listener
        c.remove_all_hook
        c.finalize_event
      }
    end

    # 墓地にあるカードの枚数を返す カード数値num以上
    def get_grave_card_count(num=1)
      ret = @used_cards.select{ |c| c.get_value_max >= num }.size
      ret
    end

    def get_joker_card
      @joker_num ||=0
      ret = ActionCard::get_joker_card(@joker_num, context, self)
      # Jokerが品切の場合そっと墓場から返す
      if ret
        @cards << ret
        @joker_num +=1
      else
        ret = @used_cards.find{|c| c.joker?}
        # デッキが完全シャッフル後は墓場に存在しない場合あり。append側で入れ替えが必要
        @used_cards.delete(ret) if ret
      end
      ret
    end

    # ジョーカーカードを最後の７枚にまぜる（７枚以下の場合も再シャッフルなしで追加）.(topの場合かならず最後に追加)
    def append_joker_card(top = false)
      jac = get_joker_card
      # カードを新規または墓場から追加出来ない場合デッキの頭から抜き出す
      unless jac
        jac = @deck_cards.find{|c| c.joker?}
        @deck_cards.delete(jac) if jac
      end
      if top
        @deck_cards << jac
      else
        i = rand(6)
        i = @deck_cards.size - 1 if @deck_cards.size < i
        i = -1 - i
        @deck_cards.insert(i, jac)
      end
      1
    end
    regist_event AppendJokerCardEvent

    def used_cards
      @used_cards
    end

  end
end
