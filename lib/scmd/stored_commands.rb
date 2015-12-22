require 'scmd/command_spy'

module Scmd

  class StoredCommands

    attr_reader :hash

    def initialize
      @hash = Hash.new{ |h, k| h[k] = Stub.new(k) }
    end

    def add(cmd_str, &block)
      @hash[cmd_str].tap{ |s| s.set_default_proc(&block) }
    end

    def get(cmd_str, opts = nil)
      @hash[cmd_str].call(opts)
    end

    def remove(cmd_str)
      @hash.delete(cmd_str)
    end

    def remove_all
      @hash.clear
    end

    def empty?
      @hash.empty?
    end

    def ==(other_stored_commands)
      if other_stored_commands.kind_of?(StoredCommands)
        self.hash == other_stored_commands.hash
      else
        super
      end
    end

    class Stub

      attr_reader :cmd_str, :hash

      def initialize(cmd_str)
        @cmd_str = cmd_str
        @default_proc = proc{ |cmd_spy| } # no-op
        @hash = {}
      end

      def set_default_proc(&block)
        @default_proc = block if block
      end

      def with(opts, &block)
        @hash[opts] = block
        self
      end

      def call(opts)
        block = @hash[opts] || @default_proc
        CommandSpy.new(@cmd_str, opts).tap(&block)
      end

      def ==(other_stub)
        if other_stub.kind_of?(Stub)
          self.cmd_str == other_stub.cmd_str &&
          self.hash    == other_stub.hash
        else
          super
        end
      end

    end

  end

end
