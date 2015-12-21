require 'scmd/version'
require 'scmd/command'

module Scmd

  # Scmd can be run in "test mode".  This means that command spies will be used
  # in place of "live" commands, each time a command is run or started will be
  # logged in a collection and option-specific spies can be added and used to
  # "stub" spies with specific attributes in specific contexts.

  def self.new(*args)
    if !ENV['SCMD_TEST_MODE']
      Command.new(*args)
    else
      self.commands.get(*args)
    end
  end

  def self.commands
    raise NoMethodError if !ENV['SCMD_TEST_MODE']
    @commands ||= begin
      require 'scmd/stored_commands'
      StoredCommands.new
    end
  end

  def self.calls
    raise NoMethodError if !ENV['SCMD_TEST_MODE']
    @calls ||= []
  end

  def self.reset
    raise NoMethodError if !ENV['SCMD_TEST_MODE']
    self.calls.clear
    self.commands.remove_all
  end

  def self.add_command(cmd_str, &block)
    self.commands.add(cmd_str, &block)
  end

  class Call < Struct.new(:cmd_str, :input, :cmd)
    def initialize(cmd_spy, input)
      super(cmd_spy.cmd_str, input, cmd_spy)
    end
  end

  TimeoutError = Class.new(::RuntimeError)

  class RunError < ::RuntimeError
    def initialize(stderr, called_from = nil)
      super(stderr)
      set_backtrace(called_from || caller)
    end
  end

end
