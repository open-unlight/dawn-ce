# frozen_string_literal: true

module Dawn
  module_function

  # @return [Pathname] project root
  def root
    Bundler.root
  end

  # @return [String] current environment
  def env
    ENV['DAWN_ENV'] || 'development'
  end

  # @return [Logger] the game logger
  def logger
    @logger = Logger.new(STDOUT)
  end
end
