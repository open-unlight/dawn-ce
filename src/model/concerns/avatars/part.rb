# frozen_string_literal: true

module Avatars
  module Part
    extend ActiveSupport::Concern

    included do
      def part_list_str(reload = true)
        refresh if reload
        part_inventories.map(&:avatar_part_id).join(',')
      end

      def part_inventories_list(reload = true)
        refresh if reload
        part_inventories.map(&:id)
      end

      def part_inventories_list_str(_relaod = true)
        part_inventories_list(reload).join(',')
      end
    end
  end
end
