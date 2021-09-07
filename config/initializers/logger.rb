# frozen_string_literal: true

require 'semantic_logger'

# TODO: Allow multiple output
if ENV['DAWN_LOG_TO_STDOUT']
  $stdout.sync = true
  $stderr.sync = true

  SemanticLogger.add_appender(io: $stdout, formatter: Dawn.logger_format)
else
  SemanticLogger.add_appender(file_name: "log/#{Dawn.env}.log", formatter: Dawn.logger_format)
end

SemanticLogger.add_appender(io: $stdout, formatter: Dawn.logger_format) if Dawn.env == 'development'

SemanticLogger.environment = Dawn.env
SemanticLogger.application = 'Dawn'
# TODO: Set hostname
