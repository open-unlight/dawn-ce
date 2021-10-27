# frozen_string_literal: true

require 'dawn/services/command_dumper'

namespace :command do
  namespace :schema do
    desc 'Dump command schema to JSON format'
    task :dump do
      dumper = Dawn::CommandDumper.new
      dumper.dump
    end
  end
end
