# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

require 'yaml'
require 'singleton'
require 'forwardable'

require 'sequel'

require 'dawn'

module Dawn
  class Database
    class << self
      extend Forwardable

      delegate %w[current] => :instance
    end

    include Singleton

    attr_reader :config_file

    def initialize
      # TODO: Add config manager
      @config_file = Dawn.root.join('config/database.yml')
      @mutex = Mutex.new
    end

    def config
      return @config if @config
      return @config = ENV['DATABASE_URL'] unless config_file.exist?

      @config ||=
        YAML.safe_load(config_file.read).fetch(Dawn.env)
      @config ||= ENV['DATABASE_URL']
      @config
    end

    def current
      return @current if @current

      @mutex.synchronize do
        return @current if @current

        @current = Sequel.connect(config, logger: SemanticLogger['Database'])
      end

      @current
    end
  end
end
