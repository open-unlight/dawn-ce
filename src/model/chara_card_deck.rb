# Unlight
# Copyright(c)2019 CPA
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

module Unlight

  # キャラカードデッキクラス
  class CharaCardDeck < Sequel::Model

    # プラグインの設定
    plugin :schema
    plugin :validation_class_methods
    plugin :hook_class_methods

    many_to_one :avatar         # アバターに複数所持される
    one_to_many :card_inventories  # カードインベントリを複数所持する
    one_to_many :chara_card_slot_inventories  # カードインベントリを複数所持する

    # スキーマの設定
    set_schema do
      primary_key :id
      String      :name, :index=>true, :default =>"No Name"
      integer     :avatar_id, :index=>true #, :table => :avatars
      integer     :kind, :default => 0
      integer     :level, :default => 1
      integer     :exp, :default => 0
      integer     :max_cost, :default => 45
      integer     :status, :default => 0
      datetime    :created_at
      datetime    :updated_at
    end

    if !(CharaCardDeck.table_exists?)
      CharaCardDeck.create_table
    end

#    テーブルを変更する（履歴を残せ）
    DB.alter_table :chara_card_decks do
      add_column :level, :integer, :default => 1 unless Unlight::CharaCardDeck.columns.include?(:level)  # 新規追加2012/06/15
      add_column :exp, :integer, :default => 0 unless Unlight::CharaCardDeck.columns.include?(:exp)  # 新規追加2012/06/15
    end

    # インサート時の前処理
    before_create do
       self.created_at = Time.now.utc
    end

    # インサートとアップデート時の前処理
    before_save do
       self.updated_at = Time.now.utc
    end

    # 削除時の後処理
    before_destroy do
      self.card_inventories.each do |c|
        c.chara_card_deck_id = avatar.chara_card_decks[0].id if avatar && avatar.chara_card_decks[0]
        c.save_changes
      end
      refresh
    end

    # デッキが保有するキャラカード
    def cards(r = true)
      ret = []
      refresh if r
      self.card_inventories.each do |i|
        i.refresh if r
      end
      c_set =  self.card_inventories.sort{|a,b|
        # もしpositionがNullで来たらケツに突っ込む
        if a&&b
          unless  a.position
            a.positon = 2
            a.save_changes
          end
          unless b.position
            b.positon = 2
            b.save_changes
          end
          (a.position <=> b.position)
        end
      }

      c_set.each do |i|
        begin
          c = Unlight::CharaCard[i.chara_card_id]
          ret << c if c
        rescue =>e
          SERVER_LOG.fatal("CharaCardDeck:#{self.id} #{e.message}")
          ret << Unlight::CharaCard[i.chara_card_id]
        end
      end
      ret
    end

    def get_slot_card_inventory(list)
      ret = []
      chara_card_slot_inventories.each do |cc|
        if list.include?(cc.id)
          ret << cc
          list.delete(cc.id)
          break if list.size <= 0
       end
      end
      ret
    end

    # 合成後に対象Inventoryをリフレッシュする
    def refresh_inventory(inv_id)
      chara_card_slot_inventories.each do |cc|
        if cc.id == inv_id
          cc.refresh
          break
        end
      end
    end

    def cards_invalid?
      ret = false
      cards.each do |c|
        ret = true unless c
      end
      ret
    end

    def slot_inventories_id_list
      ret = []
      self.chara_card_slot_inventories.each do |i|
        ret << i.id
      end
      ret
    end

    # 完全削除(カードインベントリをバインダに戻さずに削除する)
    def complete_destroy
      self.card_inventories.each do |c|
        c.destroy
      end
      refresh # このあとのbefore_destroyに影響の内容に更新しておく
      self.destroy
    end

    # デッキが保有するキャラカード
    def cards_id(r = true)
      ret = []
      refresh if r
      cards.each do |c|
        ret << c.id
      end
      ret
    end

    # デッキが保有するキャラカード
    def mask_cards_id
      ret = []
      refresh
      cards.each do |c|
        if ret.size == 0
          ret << c.id
        else
          ret << 0
        end
      end
      ret
    end

    # デッキが保持するイベントカード(キャラごとの配列)
    def event_cards
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        ret[a.deck_position] << EventCard[a.card_id] if a.kind == SCT_EVENT && a.deck_position&&ret[a.deck_position]&& EventCard[a.card_id]
      end
     ret
    end

    # デッキが保持するイベントカードのID(キャラごとの配列)
    def event_cards_id
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        ret[a.deck_position] << a.card_id if a.kind == SCT_EVENT && a.deck_position&&ret[a.deck_position]
      end
     ret
    end

    # デッキが保持する武器カード(キャラごとの配列)
    def weapon_cards
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        if a.kind == SCT_WEAPON && a.deck_position&&ret[a.deck_position]
          if a.combined?
            ret[a.deck_position] << a if WeaponCard[a.card_id]
          else
            ret[a.deck_position] << WeaponCard[a.card_id] if WeaponCard[a.card_id]
          end
        end
      end
     ret
    end

    # デッキが保持する武器カードのIDを返す
    def weapon_cards_id
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        ret[a.deck_position] << a.card_id if a.kind == SCT_WEAPON && a.deck_position&&ret[a.deck_position]
      end
     ret
    end

    # デッキが保持する装備カード(キャラごとの配列)
    def equip_cards
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        ret[a.deck_position] << EquipCard[a.card_id] if a.kind ==SCT_EQUIP && a.deck_position&&ret[a.deck_position]&& EquipCard[a.card_id]
      end
      ret
    end

    # デッキが保持する装備カードのIDを返す
    def equip_cards_id
      ret = [[],[],[]]
      chara_card_slot_inventories.sort{ |a,b| a.card_position <=> b.card_position}.each do |a|
        ret[a.deck_position] << a.card_id if a.kind ==SCT_EQUIP && a.deck_position&&ret[a.deck_position]
      end
      ret
    end

    # イベントカードの色使用数
    def event_cards_color_size(pos, color_num)
      ret = 0
      event_cards[pos].each{|ec| ret +=1 if ec.color == color_num}
      ret
    end

    # イベントカードの特定カード使用数
    def event_cards_size(id_no)
      ret = 0
      event_cards.flatten.each{|ec| ret +=1 if ec.id == id_no}
      ret
    end

    # CPU戦用のキャラカードデッキを返す
    def CharaCardDeck::get_cpu_deck(no, player=nil)
    # CPUのアバターが持っているデッキを探す
      ccd = CpuCardData[no]
      ccd_id = ccd && player ? ccd.get_allocation_id(player) : no
      if @@CPU_DECK[ccd_id]&&@@CPU_DECK[ccd_id].card_inventories.length>0
        @@CPU_DECK[ccd_id]
      else
        CharaCardDeck.filter({ :name =>"Monster: #{ccd_id}", :avatar_id=>Unlight::Player.get_cpu_player.current_avatar.id}).all.first
      end
    end

    def CharaCardDeck::initialize_CPU_deck
        @@CPU_DECK = []
      # 登録されているCPUデータを全部なめる
      CpuCardData.all.each do |ccd|
        # データのデッキがあるか確認する
        decks = CharaCardDeck.filter({ :avatar_id=>Unlight::Player.get_cpu_player.current_avatar.id, :name =>"Monster: #{ccd.id}"}).all
        # デッキが存在した
        if decks
          # CPUDATAと同じか？
          if check_CPU_deck(decks.first,ccd)
            ret = decks.first
            decks[1..-1].each{|d| d.complete_destroy}
          else
            decks.each{|d| d.complete_destroy}
          end
        end
        unless ret
          ret = CharaCardDeck.create(:name =>"Monster: #{ccd.id}", :avatar_id=>Unlight::Player.get_cpu_player.current_avatar.id)
          ret.save
          CardInventory.create_cpu_card(ccd.id, ret.id)
          CharaCardSlotInventory.create_cpu_card(ccd.id, ret.id)
        end
        @@CPU_DECK[ccd.id] = ret
      end
    end
    def CharaCardDeck::check_CPU_deck(deck, cpudata)
      ret = false
      if deck&&cpudata
        ret = deck.cards_id == cpudata.chara_cards_id && deck.equip_cards_id == cpudata.equip_cards_id&& deck.weapon_cards_id == cpudata.weapon_cards_id&&deck.event_cards_id == cpudata.event_cards_id
      end
      ret
    end

    # 特定のデッキににいるSlotカードをすべてうつす
    def move_all_slot_inventory(to_deck, from_pos, to_pos)
      chara_card_slot_inventories.clone.each do|c|
        if c.deck_position == from_pos
          c.chara_card_deck = to_deck
          c.deck_position = to_pos
          c.save_changes
        end
      end
    end

    # デッキ内のポジション配列を返す
     def position_list_card()
       ret = []
       self.refresh
       self.card_inventories.sort{|a,b|(a.position <=> b.position)if a&&b&&a.position&&b.position}.each do |i|
        ret << i.id
      end
      ret
     end

     # 引数のカードインベントリと同じキャラがすでにデッキにある
    def chara_card_check(cci)
      ret = 0
      c = CharaCard[cci.chara_card_id]
      card_inventories.each do |ci|
        cic = CharaCard[ci.chara_card_id]
        # インベントリは違うが、キャラカード同じ
        if ((ci.id != cci.id)&&cic.same_person?(c))
          ret = ERROR_DECK_DUBBLE_CHARA
        end
      end
      ret
    end


    # このデッキに入るかどうか。入らなかった場合エラーコードを返す
    def slot_check(kind, id, pos, inv, r = true)
      refresh if r
      ret = 0
      # ポジションにキャラカードが刺さっているか？
      cc = cards(r)[pos]            # キャラカードを格納
      unless cc
        ret = ERROR_NOT_EXIST_CHARA
        return ret
      end
      # 各条件を調べる
      case kind
        # 武器の場合1枚しかもてない
      when SCT_WEAPON
        c = WeaponCard[id]
        # 装備するカードが存在する
        if c
          # キャラの条件に合っているか調べる
          ret = ERROR_RESTRICT_CHARA unless c.check_using_chara(cc.parent_id)
          # このデッキの同ポジションにすでに装備されていないか調べる
          w_cards = weapon_cards
          ret = ERROR_SLOT_MAX if w_cards[pos].length >= SLOT_MAX_WEAPON
          # MAX数ぴったりの場合でかつすでに装備されている場合エラーを無効にする
          if w_cards[pos].length == SLOT_MAX_WEAPON
            c_ids = self.slot_inventories_id_list
            ret = 0 if c_ids.include?(inv.id)
          end

        end
      when SCT_EQUIP
        c = EquipCard[id]
        if c
          # キャラの条件に合っているか調べる
          ret = ERROR_RESTRICT_CHARA unless c.check_using_chara(cc.parent_id)
          # このデッキの同ポジションにすでに装備されていないか調べる
          e_cards = equip_cards
          # SLOT_MAX_EQUIPへの*2はKoreaソースから移植、理由考察中 yamagishi
          ret = ERROR_SLOT_MAX if e_cards[pos].length >= (SLOT_MAX_EQUIP * 2)
          # MAX数ぴったりの場合でかつすでに装備されている場合エラーを無効にする
          if e_cards[pos][pos].length == (SLOT_MAX_EQUIP * 2)
          # # MAX数ぴったりの場合でかつすでに装備されている場合エラーを無効にする
            c_ids = self.slot_inventories_id_list
            ret = 0 if c_ids.include?(inv.id)
          end

        end
      when SCT_EVENT
        c = EventCard[id]
        if c
          # キャラの条件に合っているか調べる
          # キャラのカラーが十分か調べる
          ret = ERROR_NOT_ENOUGH_COLOR if c.color != ECC_NONE && cc.slot_color_num(c.color) > event_cards_color_size(pos, c.color)
          # カードのMAX制限に引っかからないか調べる
          # このデッキの同ポジションにすでに最大数装備されていないか調べる
          ev_cards = event_cards
          # SLOT_MAX_EVENTへの*3はKoreaソースから移植、理由考察中 yamagishi
          ret = ERROR_SLOT_MAX if ev_cards[pos].length >= (SLOT_MAX_EVENT * 3)
          # MAX数ぴったりの場合でかつすでに装備されている場合エラーを無効にする
          if ev_cards[pos].length == (SLOT_MAX_EVENT * 3)
          # # MAX数ぴったりの場合でかつすでに装備されている場合エラーを無効にする
          # if ev_cards[pos].length == SLOT_MAX_EVENT
            c_ids = self.slot_inventories_id_list
            ret = 0 if c_ids.include?(inv.id)
          end
        end
      end
      ret
    end

    # 現在の総コストを返す
    def current_cost
      ret = 0
      return ret if self.card_inventories.size > CHARA_CARD_DECK_MAX # 総コストが意味を持たないときは計算しない

      if self.card_inventories.size == 1
        cc = CharaCard[card_inventories[0].chara_card_id]
        ret += cc.deck_cost if cc
      elsif self.card_inventories.size > 1

        costs = []
        self.card_inventories.each do |i|
          cc = CharaCard[i.chara_card_id]
          costs << cc.deck_cost if cc
        end

        costs_max = costs.max

        costs.each do |cost|
          rem = ((costs_max - cost) / DECK_COST_CORRECTION_CRITERIA).to_i
          rem = 2 if rem > 2
          correction = rem * DECK_COST_CORRECTION_VALUE
          ret += cost + correction
        end

      end

      self.chara_card_slot_inventories.each do |c|
        ret += c.deck_cost
      end

      ret
    end

    # 現在のキャラ総コストを返す（モンスターを省く）
    def current_chara_cost
      ret = 0
      return ret if self.card_inventories.size > CHARA_CARD_DECK_MAX # 総コストが意味を持たないときは計算しない

      check_idx_list = []
      if self.card_inventories.size == 1
        cc = CharaCard[card_inventories[0].chara_card_id]
        if cc && (cc.kind == CC_KIND_CHARA||cc.kind == CC_KIND_REBORN_CHARA||cc.kind == CC_KIND_EPISODE)
          ret += cc.deck_cost
          check_idx_list << card_inventories[0].position
        end
      elsif self.card_inventories.size > 1

        costs = []
        self.card_inventories.each do |i|
          cc = CharaCard[i.chara_card_id]
          if cc && (cc.kind == CC_KIND_CHARA||cc.kind == CC_KIND_REBORN_CHARA||cc.kind == CC_KIND_EPISODE)
            costs << cc.deck_cost
            check_idx_list << i.position
          end
        end

        costs_max = costs.max

        costs.each do |cost|
          rem = ((costs_max - cost) / DECK_COST_CORRECTION_CRITERIA).to_i
          rem = 2 if rem > 2
          correction = rem * DECK_COST_CORRECTION_VALUE
          ret += cost + correction
        end

      end

      self.chara_card_slot_inventories.each do |c|
        ret += c.deck_cost if check_idx_list.include?(c.deck_position)
      end

      ret
    end

    class Cost
      attr_accessor :cost, :deck_index
    end


    # 現在の総レベルを返す
    def current_level
      ret = 0
      self.card_inventories.each do |i|
        ret += i.chara_card.level
      end
      ret
    end

    def invaid_slot_card_check
      m = self.cards.size-1

      self.chara_card_slot_inventories.each do |ccs|
        ccs.position
      end
    end

    # デッキの中身を全部リセット
    def deck_reset(binder)
      self.chara_card_slot_inventories.clone.each do |ccs|
        ccs.chara_card_deck = binder
        ccs.deck_position = 0
        ccs.save_changes
      end
      self.card_inventories.clone.each do |ci|
        ci.chara_card_deck = binder
        ci.position = 0
        ci.save_changes
      end
    end

    def deck_max_check
      if self.card_inventories.size > CHARA_CARD_DECK_MAX
        deck_reset
      end
    end

    # 最大コストに納まっているか？
    def cost_max_check
      self.current_cost <= self.max_cost
    end


    # デッキ経験値をセット
    def set_deck_exp(i, is_get_bp = 0, update = true)
      calc = i + i*is_get_bp*(RADDER_DUEL_DECK_EXP_POW-1)
      puts "selfexpis #{self.exp}, #{calc}"
      self.exp = 0 unless self.exp
      self.exp += calc
      self.save_changes if update
    end


    # デッキレベルアップをチェック
    def check_deck_level_up(update = true)
      ret = false
      self.max_cost = 45 unless self.max_cost
      self.level = 1 unless self.level
      if self.exp >= DECK_LEVEL_EXP_TABLE[self.level]
        self.max_cost += 1
        self.level += 1
        self.save_changes if update
        ret = true
      end
    end

    # 使用した合成武器のパッシブ使用回数を減らす 減らしたインベントリと消失したかを返す
    def check_use_combine_passive
      ret = []
      chara_card_slot_inventories.each do |a|
        if a.combined?&&a.combine_passive_id != 0
          vani_psv_ids = a.use_combine_passive
          ret << { :inv => a, :vani_psv_ids => vani_psv_ids}
        end
      end
      ret
    end
  end
end

