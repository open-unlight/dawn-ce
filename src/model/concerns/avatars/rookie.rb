# frozen_string_literal: true

module Avatars
  module Rookie
    extend ActiveSupport::Concern

    included do
      def rookie_sale?
        return false if created_at.nil?

        sale_end_at = created_at + Unlight::ROOKIE_SALE_START_COND_AT_TIME
        sale_end_at >= Time.now.utc
      end
    end
  end
end
