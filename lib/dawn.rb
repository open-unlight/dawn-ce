# frozen_string_literal: true

require 'dawn/version'

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
    if ENV['DAWN_LOG_TO_STDOUT']
      $stdout.sync = true
      @logger ||= Logger.new(STDOUT)
    else
      @logger ||= Logger.new(root.join("log/#{env}.log"))
    end
  end
end
