# frozen_string_literal: true

require "scmd"

module Scmd
  class CommandSpy
    attr_reader :cmd_str, :env, :options
    attr_reader :run_calls, :run_bang_calls, :start_calls
    attr_reader :wait_calls, :stop_calls, :kill_calls
    attr_accessor :pid, :exitstatus, :stdout, :stderr

    def initialize(cmd_str, opts = nil)
      opts ||= {}
      @cmd_str = cmd_str
      @env     = opts[:env]
      @options = opts[:options]

      @run_calls,  @run_bang_calls, @start_calls = [], [], []
      @wait_calls, @stop_calls,     @kill_calls  = [], [], []

      @running = false

      @stdout, @stderr, @pid, @exitstatus = "", "", 1, 0
    end

    def run(input = nil)
      @run_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input)) if ENV["SCMD_TEST_MODE"]
      self
    end

    def run_called?
      !@run_calls.empty?
    end

    def run!(input = nil)
      @run_bang_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input)) if ENV["SCMD_TEST_MODE"]
      self
    end

    def run_bang_called?
      !@run_bang_calls.empty?
    end

    def start(input = nil)
      @start_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input)) if ENV["SCMD_TEST_MODE"]
      @running = true
    end

    def start_called?
      !@start_calls.empty?
    end

    def wait(timeout = nil)
      @wait_calls.push(TimeoutCall.new(timeout))
      @running = false
    end

    def wait_called?
      !@wait_calls.empty?
    end

    def stop(timeout = nil)
      @stop_calls.push(TimeoutCall.new(timeout))
      @running = false
    end

    def stop_called?
      !@stop_calls.empty?
    end

    def kill(signal = nil)
      @kill_calls.push(SignalCall.new(signal))
      @running = false
    end

    def kill_called?
      !@kill_calls.empty?
    end

    def running?
      !!@running
    end

    def success?
      @exitstatus == 0
    end

    def to_s
      @cmd_str.to_s
    end

    def ==(other)
      if other.is_a?(CommandSpy)
        cmd_str         == other.cmd_str        &&
        env             == other.env            &&
        options         == other.options        &&
        run_calls       == other.run_calls      &&
        run_bang_calls  == other.run_bang_calls &&
        start_calls     == other.start_calls    &&
        wait_calls      == other.wait_calls     &&
        stop_calls      == other.stop_calls     &&
        kill_calls      == other.kill_calls     &&
        pid             == other.pid            &&
        exitstatus      == other.exitstatus     &&
        stdout          == other.stdout         &&
        stderr          == other.stderr
      else
        super
      end
    end

    InputCall   = Struct.new(:input)
    TimeoutCall = Struct.new(:timeout)
    SignalCall  = Struct.new(:signal)
  end
end
