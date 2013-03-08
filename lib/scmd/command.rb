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
    RunData = Class.new(Struct.new(:pid, :stdin, :stdout, :stderr))

    attr_reader :cmd_str
    attr_reader :pid, :exitstatus, :stdout, :stderr

    def initialize(cmd_str)
      @cmd_str = cmd_str
      reset_results
    end

    def reset_results
      @pid = @exitstatus = @run_data = nil
      @stdout = @stderr = ''
    end

    def run(input=nil)
      run!(input) rescue RunError
      self
    end

    def run!(input=nil)
      called_from = caller

      begin
        @run_data = RunData.new(*POSIX::Spawn::popen4(@cmd_str))
        @pid = @run_data.pid.to_i
        if !input.nil?
          [*input].each{|line| @run_data.stdin.puts line.to_s}
          @run_data.stdin.close
        end
      ensure
        pidnum, pidstatus = ::Process::waitpid2(@run_data.pid)
        @stdout      += @run_data.stdout.read.strip
        @stderr      += @run_data.stderr.read.strip
        @exitstatus ||= pidstatus.exitstatus

        [@run_data.stdin, @run_data.stdout, @run_data.stderr].each do |io|
          io.close if !io.closed?
        end
        @run_data = nil
        raise RunError.new(@stderr, called_from) if !success?
      end

      self
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

  end
end
