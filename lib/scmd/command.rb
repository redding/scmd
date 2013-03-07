require 'posix-spawn'

# Scmd::Command is a base wrapper for handling system commands. Initialize it
# with with a string specifying the command to execute.  You can then run the
# command and inspect its results.  It can be used as is, or inherited from to
# create a more custom command wrapper.

module Scmd

  class RunError < ::RuntimeError
    def initialize(stderr, called_from)
      super(stderr)
      set_backtrace(called_from)
    end
  end

  class Command

    attr_reader :cmd_str
    attr_reader :pid, :exitstatus, :stdout, :stderr

    def initialize(cmd_str)
      @cmd_str = cmd_str
      reset_results
    end

    def reset_results
      @pid = @exitstatus = nil
      @stdout = @stderr = ''
    end

    def success?
      @exitstatus == 0
    end

    def to_s
      @cmd_str.to_s
    end

    def inspect
      reference = '0x0%x' % (self.object_id << 1)
      "#<#{self.class}:#{reference}"\
      " @cmd_str=#{self.cmd_str.inspect}"\
      " @exitstatus=#{@exitstatus.inspect}>"
    end

    def run(input=nil)
      run!(input) rescue RunError
      self
    end

    def run!(input=nil)
      called_from = caller

      begin
        pid, stdin, stdout, stderr = POSIX::Spawn::popen4(@cmd_str)
        @pid = pid.to_i
        if !input.nil?
          [*input].each{|line| stdin.puts line.to_s}
          stdin.close
        end
      ensure
        pidnum, pidstatus = ::Process::waitpid2(pid)
        @stdout      += stdout.read.strip
        @stderr      += stderr.read.strip
        @exitstatus ||= pidstatus.exitstatus

        [stdin, stdout, stderr].each{|io| io.close if !io.closed?}
        raise RunError.new(@stderr, called_from) if !success?
      end

      self
    end

  end
end
