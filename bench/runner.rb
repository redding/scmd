# frozen_string_literal: true

require "whysoslow"
require "scmd"

class ScmdBenchRunner
  attr_reader :result

  def self.run(*args)
    new(*args).run
  end

  def initialize(printer_io, cmd, num_times = 10)
    @cmd = cmd
    @proc =
      proc do
        num_times.times{ cmd.run! }
      end

    @printer =
      Whysoslow::DefaultPrinter.new(
        printer_io,
        title: "#{@cmd.cmd_str}: #{num_times} times",
        verbose: true,
      )
    @runner = Whysoslow::Runner.new(@printer)
  end

  def run
    @runner.run(&@proc)
  end
end
