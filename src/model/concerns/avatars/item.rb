# frozen_string_literal: true

module Avatars
  # AvatarItem related methods
  module Item
    extend ActiveSupport::Concern

    included do
      def unused_item_inventories(reload = true)
        @unused_item_inventories = Unlight::ItemInventory.where(avatar_id: id).where { state < Unlight::ITEM_STATE_USED }.all if reload || @unused_item_inventories.nil?
        @unused_item_inventories
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
