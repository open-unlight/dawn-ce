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

      def parts_end_at_list_str(reload = true)
        refresh if reload
        now = Time.now.utc
        part_inventories.map { |p| p.get_end_at(now) }.join(',')
      end

      def part_used_list_str(reload = true)
        refresh if reload
        part_inventories.map(&:used).join(',')
      end

      def setted_parts_id_list
        part_inventories.select(&:equiped?).map(&:avatar_part_id)
      end

      def setted_parts_list_str
        setted_parts_id_list.join(',')
      end

      def get_equiped_parts_list
        part_inventories
          .each(&:work_end?)
          .select(&:equiped?)
          .map { |p| Unlight::AvatarPart[p.avatar_part_id] }
          .compact
      end
    end
  end
end
