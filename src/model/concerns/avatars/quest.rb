# frozen_string_literal: true

module Avatars
  module Quest
    extend ActiveSupport::Concern

    included do
      def quest_inventories_list(reload = true)
        refresh if reload
        avatar_quest_inventories.map(&:id)
      end

      def quest_inventories_list_str(reload = true)
        quest_inventories_list(reload).join(',')
      end

      def quest_id_list_str(reload = true)
        refresh if reload
        avatar_quest_inventories.map do |inv|
          next inv.quest_id unless inv.status == Unlight::QS_PENDING
          next 0 unless inv.quest_find?

          p.quest_id
        end.join(',')
      end

      def quest_status_list_str(reload = true)
        refresh if reload
        avatar_quest_inventories.map(&:status).join(',')
      end

      def quest_find_time_list_str(reload = true)
        refresh if reload
        now = Time.now.utc
        avatar_quest_inventories.map do |inv|
          next 0 unless inv.status == Unlight::QS_PENDING

          (inv.find_at - now).to_i
        end.join(',')
      end

      def quest_ba_name_list_str(reload = true)
        refresh if reload
        avatar_quest_inventories.map do |inv|
          next Unlight::QUEST_PRESENT_AVATAR_NAME_NIL if inv.before_avatar_id.nil?
          next Unlight::QUEST_PRESENT_AVATAR_NAME_NIL if inv.before_avatar_id.zero?

          avatar = Unlight::Avatar[inv.before_avatar_id]
          next Unlight::QUEST_PRESENT_AVATAR_NAME_NIL unless defined?(avatar.name)

          avatar.name
        end.join(',').force_encoding('UTF-8')
      end
    end
  end
end
