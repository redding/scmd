# Scmd::Command is a base wrapper for handling system commands. Initialize it
# with with a string specifying the command to execute.  You can then run the
# command and inspect its results.  It can be used as is, or inherited from to
# create a more custom command wrapper.

module Scmd
  class Command

    class Failure < RuntimeError; end

    ENGINE = if !(PLATFORM =~ /java/)
      require 'open4'
      Open4
    else
      IO
    end

    attr_reader :cmd_str
    attr_reader :pid, :exitcode, :stdout, :stderr

    def initialize(cmd_str)
      @cmd_str = cmd_str
      reset_results
    end

    def reset_results
      @pid = @exitcode = nil
      @stdout = @stderr = ''
    end

    def success?
      @exitcode == 0
    end

    def to_s
      @cmd_str.to_s
    end

    def inspect
      reference = '0x0%x' % (self.object_id << 1)
      "#<#{self.class}:#{reference}"\
      " @cmd_str=#{self.cmd_str.inspect}"\
      " @exitcode=#{@exitcode.inspect}>"
    end

    def run(input=nil)
      run!(input) rescue Failure
      self
    end

    def run!(input=nil)
      begin
        ENGINE::popen4(@cmd_str) do |pid, stdin, stdout, stderr|
          if !input.nil?
            [*input].each{|line| stdin.puts line.to_s}
            stdin.close
          end
          @pid =  pid.to_i
          @stdout += stdout.read.strip
          @stderr += stderr.read.strip
        end
        # `$?` is a thread-safe predefined variable that returns the exit status
        # of the last child process to terminate:
        # http://phrogz.net/ProgrammingRuby/language.html#predefinedvariables
        @exitcode = $?.to_i
      rescue Errno::ENOENT => err
        @exitcode = -1
        @stderr   = err.message
      end

      raise Failure, @stderr if !success?
      self
    end

  end
end
