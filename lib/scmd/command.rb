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

  TimeoutError = Class.new(::RuntimeError)

  class Command
    WAIT_INTERVAL = 0.1 # seconds
    STOP_TIMEOUT  = 3   # seconds
    RunData = Class.new(Struct.new(:pid, :stdin, :stdout, :stderr))

    attr_reader :cmd_str
    attr_reader :pid, :exitstatus, :stdout, :stderr

    def initialize(cmd_str)
      @cmd_str = cmd_str
      setup
    end

    def run(input=nil)
      run!(input) rescue RunError
      self
    end

    def run!(input=nil)
      called_from = caller

      begin
        start(input)
      ensure
        wait # indefinitely until cmd is done running
        raise RunError.new(@stderr, called_from) if !success?
      end

      self
    end

    def start(input=nil)
      setup
      @run_data = RunData.new(*POSIX::Spawn::popen4(@cmd_str))
      @pid = @run_data.pid.to_i
      if !input.nil?
        [*input].each{|line| @run_data.stdin.puts line.to_s}
        @run_data.stdin.close
      end
    end

    def wait(timeout=nil)
      return if !running?

      pidnum, pidstatus = wait_for_exit(timeout)
      @stdout     += @run_data.stdout.read.strip
      @stderr     += @run_data.stderr.read.strip
      @exitstatus  = pidstatus.exitstatus || pidstatus.termsig

      teardown
    end

    def stop(timeout=nil)
      return if !running?

      send_term
      begin
        wait(timeout || STOP_TIMEOUT)
      rescue TimeoutError => err
        kill
      end
    end

    def kill
      return if !running?

      send_kill
      wait # indefinitely until cmd is killed
    end

    def running?
      !@run_data.nil?
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

    private

    def wait_for_exit(timeout)
      if timeout.nil?
        ::Process::waitpid2(@run_data.pid)
      else
        timeout_time = Time.now + timeout
        pid, status = nil, nil
        while pid.nil? &&  Time.now < timeout_time
          sleep WAIT_INTERVAL
          pid, status = ::Process.waitpid2(@run_data.pid, ::Process::WNOHANG)
          pid = nil if pid == 0 # may happen on jruby
        end
        raise(TimeoutError, "`#{@cmd_str}` timed out (#{timeout}s).") if pid.nil?
        [pid, status]
      end
    end

    def setup
      @pid = @exitstatus = @run_data = nil
      @stdout = @stderr = ''
    end

    def teardown
      [@run_data.stdin, @run_data.stdout, @run_data.stderr].each do |io|
        io.close if !io.closed?
      end
      @run_data = nil
      true
    end

    def send_term
      send_signal 'TERM'
    end

    def send_kill
      send_signal 'KILL'
    end

    def send_signal(sig)
      return if !running?
      ::Process.kill sig, @run_data.pid
    end

  end

end
