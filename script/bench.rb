# $ bundle exec ruby script/bench.rb

require 'bench/runner'

class ScmdBenchLogger

  def initialize(file_path)
    @file = File.open(file_path, 'w')
    @ios = [@file, $stdout]
    yield self
    @file.close
  end

  def method_missing(meth, *args, &block)
    @ios.each do |io|
      io.respond_to?(meth.to_s) ? io.send(meth.to_s, *args, &block) : super
    end
  end

  def respond_to?(*args)
    @ios.first.respond_to?(args.first.to_s) ? true : super
  end

end

def run_cmd(logger, *args)
  GC.disable

  ScmdBenchRunner.run(logger, *args)
  logger.puts

  GC.enable
  GC.start
end

ScmdBenchLogger.new('bench/results.txt') do |logger|
  run_cmd(logger, Scmd.new("echo hi"), 1)
  run_cmd(logger, Scmd.new("echo hi"), 10)
  run_cmd(logger, Scmd.new("echo hi"), 100)
  run_cmd(logger, Scmd.new("echo hi"), 1000)

  run_cmd(logger, Scmd.new("cat test/support/bigger-than-64k.txt"), 1)
  run_cmd(logger, Scmd.new("cat test/support/bigger-than-64k.txt"), 10)
  run_cmd(logger, Scmd.new("cat test/support/bigger-than-64k.txt"), 100)
  run_cmd(logger, Scmd.new("cat test/support/bigger-than-64k.txt"), 1000)
end

