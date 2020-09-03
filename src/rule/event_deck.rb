# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

 # イベントデッキクラス
 class EventDeck  < Deck

   # 対戦者同士のイベントカードデッキをもらってIDの重複がないようにデッキを作る
   def EventDeck::create_decks(c, cards1, cards2,duel)
     acs = ActionCard::event_cards_to_action_cards(cards1.flatten, cards2.flatten)
     [ EventDeck.new(c, acs[0],duel,true),EventDeck.new(c, acs[1],duel,false)]
   end


   def initialize(c,event_cards,duel,dir)
     @event_cards = event_cards
     @duel = duel
     @c_num = Hash.new(0)
     @dir = dir
     super(c)
   end

   def init_cards
     @cards = ActionCard.event_deck_with_context(context,self,@duel, @event_cards)
     @special_event_cards = { }
   end
   private :init_cards

   def draw_cards(num)
     ret_cards = []
     # デッキの残りが引く数より少ない場合捨て札を再シャッフル
     while ret_cards.size != num
       if @deck_cards.size < 1
         break
       end
       c = @deck_cards.pop
       break if c.nil?
       ret_cards << c
       use_card(c)
     end
     ret_cards
   end
   regist_event DrawCardsEvent

   # カードを使う(デッキから引く場合)
   def use_card(card)
     @using_cards<< card if card
   end
   private :use_card

   # カードを捨てる
   def throw_card(card)
      card.throwed_event if card
   end

   # イベントカードを入れ替える。挿入でよい場合はフラグで。
   # id:イベカID, n:枚数, insert:挿入フラグ, 戻り値:成功数
   def replace_event_cards(id, n, insert=false)
     ec = EventCard[id]                            # 新しいイベントカードのインスタンス
     new_cards = []                                # アクションカード配列
     c_max = ec.max_in_deck - @c_num[ec.event_no]  # 作成上限のチェック

     c_size = c_max < n ? c_max : n
     c_size.times do

       ac_id = ec.event_no + @c_num[ec.event_no]
       ac_id += ec.max_in_deck unless @dir

       ac = ActionCard[ac_id]
       acwc = ActionCard.event_deck_with_context(context, self, @duel, [ac])
       create_chance_card_event(acwc[0]) if (1 .. 5).include?(ac.event_no)   # コントローラからリスナー登録関数を呼ぶ
       @special_event_cards[ac_id] = acwc[0]
       new_cards << @special_event_cards[ac_id]

       @c_num[ec.event_no]+=1
     end

     c_size.times do |i|
       c = new_cards.pop
       use_card(@deck_cards.shift) unless insert
       @deck_cards << c
     end

     return c_size
   end

   # イベントカードのドローを保留
   def freez_event_cards(n)

     n.times do |i|
       @deck_cards << nil
     end

   end

   # すべてのカードにイベントリスナーを登録する
   def all_cards_add_event_listener(event, listener)
     @cards.each{ |c| c.send(event,listener)}
   end

   # 単一のカードにイベントリスナーを登録する
   def card_add_event_listener(card, event, listener)
     card.send(event, listener)
   end

   # すべてのカードのイベントリスナーをリムーブする
   def all_cards_remove_all_event_listener()
     @cards.each{ |c|
       c.remove_all_event_listener
       c.remove_all_hook
     }
     @special_event_cards.each_value{ |c|
       c.remove_all_event_listener
       c.remove_all_hook
     }
     @duel = nil
   end

   def deck_init()
     0
   end
   regist_event DeckInitEvent

   def create_chance_card(card)
     card
   end
   regist_event CreateChanceCardEvent

 end
end

