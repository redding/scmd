require 'scmd'

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

      @stdout, @stderr, @pid, @exitstatus = '', '', 1, 0
    end

    def run(input = nil)
      @run_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input))
      self
    end

    def run_called?
      !@run_calls.empty?
    end

    def run!(input = nil)
      @run_bang_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input))
      self
    end

    def run_bang_called?
      !@run_bang_calls.empty?
    end

    def start(input = nil)
      @start_calls.push(InputCall.new(input))
      Scmd.calls.push(Scmd::Call.new(self, input))
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

    def ==(other_spy)
      if other_spy.kind_of?(CommandSpy)
        self.cmd_str         == other_spy.cmd_str        &&
        self.env             == other_spy.env            &&
        self.options         == other_spy.options        &&
        self.run_calls       == other_spy.run_calls      &&
        self.run_bang_calls  == other_spy.run_bang_calls &&
        self.start_calls     == other_spy.start_calls    &&
        self.wait_calls      == other_spy.wait_calls     &&
        self.stop_calls      == other_spy.stop_calls     &&
        self.kill_calls      == other_spy.kill_calls     &&
        self.pid             == other_spy.pid            &&
        self.exitstatus      == other_spy.exitstatus     &&
        self.stdout          == other_spy.stdout         &&
        self.stderr          == other_spy.stderr
      else
        super
      end
    end

    InputCall   = Struct.new(:input)
    TimeoutCall = Struct.new(:timeout)
    SignalCall  = Struct.new(:signal)

  end

end
