# frozen_string_literal: true

module Dawn
  module_function

  # @return [Pathname] project root
  def root
    Bundler.root
  end
end
