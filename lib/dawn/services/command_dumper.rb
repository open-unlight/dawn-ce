# frozen_string_literal: true

require 'dawn'

module Dawn
  # Dump Command to JSON
  #
  # @since 0.1.0
  class CommandDumper
    # Initialize Dumper
    #
    # @return Dawn::CommandDUmper
    def initialize
      @files = Dawn.root.join('src/protocol/command').glob('*?command.rb')
    end

    # Dump command
    #
    # @param dest [String] the dest path
    #
    # @since 0.1.0
    def dump(dest = nil)
      dest ||= Dawn.root.join('tmp/commands.json')
      File.write(dest, JSON.pretty_generate(commands))
    end

    private

    # :nodoc:
    def commands
      @files.map do |file|
        require file
        type = file.basename.to_s[/(.*)command/, 1]
        command = {
          server: convert(Unlight::Command::SEND_COMMANDS),
          client: convert(Unlight::Command::RECEIVE_COMMANDS)
        }
        ::Unlight.send(:remove_const, :Command)
        [type, command]
      end.to_h
    end

    # :nodoc:
    def convert(commands)
      commands.map.with_index do |(name, args, compress), index|
        [
          name,
          {
            id: index,
            compress: compress || false,
            args: format(args)
          }
        ]
      end.to_h
    end

    # :nodoc:
    def format(args)
      return [] if args.nil?

      args.map do |name, type, size|
        {
          name: name,
          type: type_with_size(type, size)
        }
      end
    end

    # :nodoc:
    def type_with_size(type, size)
      case type
      when :String then 'string'
      when :int
        return 'int32' if size == 4
        return 'int8' if size == 1
      when :char then 'char'
      when :Boolean then 'bool'
      else 'unknown'
      end
    end
  end
end
