# frozen_string_literal: true

# Dawn
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

require 'bundler/setup'
require 'eventmachine'

require 'dawn/server'
require 'unlight'

EM.set_descriptor_table_size(10_000)
EM.epoll

# TODO: Remove after Dawn::Application is ready
module Dawn
  class Bootstrap
    attr_reader :name, :server

    def initialize(server, *args)
      @server = server
      @name = server.name.split('::').last
      @args = args

      Dawn.logger.name = @name

      Signal.trap(:INT) { stop }
      Signal.trap(:TERM) { stop }
    end

    def start
      EM.run do
        server.setup(*@args)
        EM.start_server '0.0.0.0', Dawn::Server.port, server
        EM.set_quantum(10)

        Dawn.logger.info("Listening... #{Dawn::Server.hostname}:#{Dawn::Server.port}")

        start_database_connection_checker

        yield if defined?(yield)
      end
    end

    def stop
      Dawn.logger.info('Stopping...')
      SemanticLogger.flush
      EM.stop_event_loop
    end

    private

    def start_database_connection_checker
      return unless Unlight::DB_CONNECT_CHECK

      EM::PeriodicTimer.new(60 * 60 * 7) do
        server.check_db_connection
      rescue StandardError => e
        Dawn.logger.fatal('Check database connection failed', e)
      end
    end
  end
end
