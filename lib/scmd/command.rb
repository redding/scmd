require 'thread'
require 'posix-spawn'
require 'scmd'

# Scmd::Command is a base wrapper for handling system commands. Initialize it
# with with a string specifying the command to execute.  You can then run the
# command and inspect its results.  It can be used as is, or inherited from to
# create a more custom command wrapper.

module Scmd

  class Command
    READ_SIZE            = 10240 # bytes
    READ_CHECK_TIMEOUT   = 0.001 # seconds
    DEFAULT_STOP_TIMEOUT = 3     # seconds

    attr_reader :cmd_str, :env, :options
    attr_reader :pid, :exitstatus, :stdout, :stderr

    def initialize(cmd_str, opts = nil)
      opts ||= {}
      @cmd_str = cmd_str
      @env     = stringify_hash(opts[:env] || {})
      @options = opts[:options] || {}
      reset_attrs
    end

    def run(input = nil)
      run!(input) rescue RunError
      self
    end

    def run!(input = nil)
      start_err_msg, start_err_bt = nil, nil
      begin
        start(input)
      rescue StandardError => err
        start_err_msg, start_err_bt = err.message, err.backtrace
      ensure
        wait # indefinitely until cmd is done running
        raise RunError.new(start_err_msg || @stderr, start_err_bt || caller) if !success?
      end

      self
    end

    def start(input = nil)
      setup_run

      @pid = @child_process.pid.to_i
      @child_process.write(input)
      @read_output_thread = Thread.new do
        while @child_process.check_for_exit
          begin
            read_output
          rescue EOFError => err
          end
        end
        @stop_w.write_nonblock('.')
      end
    end

    def wait(timeout = nil)
      return if !running?

      wait_for_exit(timeout)
      if @child_process.running?
        kill
        raise(TimeoutError, "`#{@cmd_str}` timed out (#{timeout}s).")
      end
      @read_output_thread.join

      @stdout << @child_process.flush_stdout
      @stderr << @child_process.flush_stderr
      @exitstatus = @child_process.exitstatus

      teardown_run
    end

    def stop(timeout = nil)
      return if !running?

      send_term
      begin
        wait(timeout || DEFAULT_STOP_TIMEOUT)
      rescue TimeoutError => err
        kill
      end
    end

    def kill(signal = nil)
      return if !running?

      send_kill(signal)
      wait # indefinitely until cmd is killed
    end

    def running?
      !@child_process.nil?
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

    def read_output
      @child_process.read(READ_SIZE){ |out, err| @stdout += out; @stderr += err }
    end

    def wait_for_exit(timeout)
      ios, _, _ = IO.select([ @stop_r ], nil, nil, timeout)
      @stop_r.read_nonblock(1) if ios && ios.include?(@stop_r)
    end

    def reset_attrs
      @stdout, @stderr, @pid, @exitstatus = '', '', nil, nil
    end

    def setup_run
      reset_attrs
      @stop_r, @stop_w = IO.pipe
      @read_output_thread = nil
      @child_process = ChildProcess.new(@cmd_str, @env, @options)
    end

    def teardown_run
      @child_process.teardown
      [@stop_r, @stop_w].each{ |fd| fd.close if fd && !fd.closed? }
      @stop_r, @stop_w = nil, nil
      @child_process, @read_output_thread = nil, nil
      true
    end

    def send_term
      send_signal 'TERM'
    end

    def send_kill(signal = nil)
      send_signal(signal || 'KILL')
    end

    def send_signal(sig)
      return if !running?
      @child_process.send_signal(sig)
    end

    def stringify_hash(hash)
      hash.inject({}) do |h, (k, v)|
        h.merge(k.to_s => v.to_s)
      end
    end

    class ChildProcess

      attr_reader :pid, :stdin, :stdout, :stderr

      def initialize(cmd_str, env, options)
        @pid, @stdin, @stdout, @stderr = *::POSIX::Spawn::popen4(
          env,
          cmd_str,
          options
        )
        @wait_pid, @wait_status = nil, nil
      end

      def check_for_exit
        if @wait_pid.nil?
          @wait_pid, @wait_status = ::Process.waitpid2(@pid, ::Process::WNOHANG)
          @wait_pid = nil if @wait_pid == 0 # may happen on jruby
        end
        @wait_pid.nil?
      end

      def running?
        @wait_pid.nil?
      end

      def exitstatus
        return nil if @wait_status.nil?
        @wait_status.exitstatus || @wait_status.termsig
      end

      def write(input)
        if !input.nil?
          [*input].each{ |line| @stdin.puts line.to_s }
          @stdin.close
        end
      end

      def read(size)
        ios, _, _ = IO.select([ @stdout, @stderr ], nil, nil, READ_CHECK_TIMEOUT)
        if ios && block_given?
          yield read_if_ready(ios, @stdout, size), read_if_ready(ios, @stderr, size)
        end
      end

      def send_signal(sig)
        process_kill(sig, self.pid)
      end

      def flush_stdout; @stdout.read; end
      def flush_stderr; @stderr.read; end

      def teardown
        [@stdin, @stdout, @stderr].each{ |fd| fd.close if fd && !fd.closed? }
      end

      private

      def read_if_ready(ready_ios, io, size)
        ready_ios.include?(io) ? read_by_size(io, size) : ''
      end

      def read_by_size(io, size)
        io.read_nonblock(size)
      end

      def process_kill(sig, pid)
        child_pids(pid).each{ |p| process_kill(sig, p) }
        ::Process.kill(sig, pid)
      end

      def child_pids(pid)
        Command.new("#{pgrep} -P #{pid}").run.stdout.split("\n").map(&:to_i)
      end

      def pgrep
        @pgrep ||= Command.new('which pgrep').run.stdout.strip
      end

    end

  end

end
