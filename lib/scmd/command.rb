# Scmd::Command is a base wrapper for handling system commands. Initialize it
# with with a string specifying the command to execute.  You can then run the
# command and inspect its results.  It can be used as is, or inherited from to
# create a more custom command wrapper.
#
# Notes:
# * Uses `open4`. Open4 is more reliable for actually getting the subprocesses
#   exit code (compared to `open3`).
# * The inspect method is overwritten to only display the name of the class and
#   the command string. This is to help reduce ridiculous inspect strings due to
#   result data that is stored in instance variables.
# * See the README.md for a walkthrough of the API.

require 'open4'

module Scmd
  class Command

    class Failure < RuntimeError; end

    attr_reader :cmd_str
    attr_reader :pid, :exitcode, :stdout, :stderr

    def initialize(cmd_str)
      @cmd_str = cmd_str
      reset_results
    end

    def success?; @exitcode == 0; end
    def to_s; @cmd_str.to_s; end
    def inspect
      "#<#{self.class}:0x#{self.object_id.to_s(16)} @cmd_str=#{self.cmd_str.inspect} @exitcode=#{@exitcode.inspect}>"
    end

    def run(input=nil)
      run!(input) rescue Failure
      self
    end

    def run!(input=nil)
      begin
        status = Open4::popen4(@cmd_str) do |pid, stdin, stdout, stderr|
          if !input.nil?
            [*input].each{|line| stdin.puts line.to_s}
            stdin.close
          end
          @pid =  pid.to_i
          @stdout += stdout.read.strip
          @stderr += stderr.read.strip
        end
        @exitcode = status.to_i
      rescue Errno::ENOENT => err
        @exitcode = -1
        @stderr   = err.message
      end

      raise Failure, @stderr if !success?
      self
    end

    def reset_results
      @pid = @exitcode = nil
      @stdout = @stderr = ''
    end

  end
end
