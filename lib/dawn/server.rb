# Unlight
# Copyright (c) 2019 CPA
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0
# frozen_string_literal: true

require 'singleton'
require 'forwardable'
require 'optparse'

module Dawn
  # Server
  #
  # The game server base class
  #
  # @since 0.1.0
  class Server
    class << self
      extend Forwardable

      delegate %w[id port hostname] => :instance
    end

    include Singleton

    # @since 0.1.0
    def initialize
      @parser = OptionParser.new
      @parser.on('-i ID') { |id| @id = id.to_i }
      @parser.on('-p PORT') { |port| @port = port.to_i }
      @parser.on('-h HOSTNAME') { |name| @hostname = name }
      @parser.parse!
    end

    # @return [Integer] the server id
    #
    # @since 0.1.0
    def id
      @id || 0
    end

    # @param port [Integer] port to listen
    #
    # @return [Integer] the server listen port
    #
    # @since 0.1.0
    def port(default = 12_000)
      (@port || default).to_i
    end

    # @return [String] the server hostname
    #
    # @since 0.1.0
    def hostname
      @hostname ||= ENV['HOSTNAME'] || Socket.gethostname
    end
  end
end
