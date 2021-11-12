# frozen_string_literal: true

module Avatars
  # AvatarItem related methods
  module Item
    extend ActiveSupport::Concern

    included do
      def item_inventories(reload = true)
        @item_inventories = nil if reload
        @item_inventories ||= Unlight::ItemInventory.where(avatar_id: id, state: Unlight::ITEM_STATE_NOT_USE).all
      end

      def full_item_inventories(reload = true)
        @full_item_inventories = nil if reload
        @full_item_inventories ||= Unlight::ItemInventory.filter(avatar_id: id).all
      end

      def unused_item_inventories(reload = true)
        @unused_item_inventories = nil if reload
        @unused_item_inventories ||= Unlight::ItemInventory.where(avatar_id: id).where { state < Unlight::ITEM_STATE_USED }.all
      end

      def items_num
        unused_item_inventories(false).size
      end

      def tickets
        refresh
        item_inventories.select { |i| i.avatar_item_id == Unlight::RARE_CARD_TICKET }
      end

      def copy_tickets
        refresh
        item_inventories.select { |i| i.avatar_item_id == Unlight::COPY_TICKET }
      end

      def item_count(item_id, reload = true)
        item_inventories(reload).count { |i| i.avatar_item_id == item_id }
      end

      def item_count_later(item_id, check_at, reload = true)
        item_inventories(reload).count { |i| i.avatar_item_id == item_id && i.created_at > check_at }
      end

      def set_item_count_later(item_ids, create_after_at, reload = true)
        item_inventories(reload).count do |i|
          item_ids.include?(i.avatar_item_id) && i.created_at > create_after_at
        end
      end

      def full_item_count(item_id, reload = true)
        full_item_inventories(reload).count { |i| i.avatar_item_id == item_id }
      end

      def item_list_str(reload = true)
        refresh if reload
        unused_item_inventories(reload).map(&:avatar_item_id).join(',')
      end

      def item_state_list_str(reload = true)
        refresh if reload
        unused_item_inventories(reload).map(&:state).join(',')
      end

      def item_inventories_list_str(reload = true)
        item_inventories_list(reload).join(',')
      end

      def item_inventories_list(reload = true)
        refresh if reload
        unused_item_inventories(reload).map(&:id)
      end
    end
  end
end
