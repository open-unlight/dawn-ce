# frozen_string_literal: true

module Game
  class V1 < Dawn::API::Base
    version 'v1', using: :path
  end
end
