# frozen_string_literal: true

require 'semantic_logger'

# TODO: Allow multiple output
if ENV['DAWN_LOG_TO_STDOUT']
  SemanticLogger.add_appender(io: $stdout, formatter: Dawn.logger_format)
else
  SemanticLogger.add_appender(file_name: "log/#{Dawn.env}.log", formatter: Dawn.logger_format)
end

SemanticLogger.environment = Dawn.env
SemanticLogger.application = 'Dawn'
# TODO: Set hostname
