require 'scmd/command'

module Scmd

  def self.new(*args, &block)
    Command.new(*args, &block)
  end

end
