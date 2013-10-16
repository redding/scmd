require 'scmd/version'
require 'scmd/command'

module Scmd

  def self.new(*args, &block)
    Command.new(*args, &block)
  end

  TimeoutError = Class.new(::RuntimeError)

  class RunError < ::RuntimeError
    def initialize(stderr, called_from = nil)
      super(stderr)
      set_backtrace(called_from || caller)
    end
  end

end
