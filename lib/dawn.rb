# frozen_string_literal: true

require 'semantic_logger'

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

  # @return [SemanticLogger] the game logger
  def logger
    @logger ||= SemanticLogger['Dawn']
  end

  # @return [Symbol] the game logger format
  def logger_format
    ENV.fetch('DAWN_LOG_FORMAT', :color).to_sym
  end
end

# TODO: Allow multiple output
if ENV['DAWN_LOG_TO_STDOUT']
  SemanticLogger.add_appender(io: $stdout, formatter: Dawn.logger_format)
else
  SemanticLogger.add_appender(file_name: "log/#{Dawn.env}.log", formatter: Dawn.logger_format)
end
