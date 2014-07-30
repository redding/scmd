require "assert"
require 'scmd/command'

class Scmd::Command

  class UnitTests < Assert::Context
    desc "Scmd::Command"
    setup do
      @success_cmd = Scmd::Command.new("echo hi")
      @failure_cmd = Scmd::Command.new("cd /path/that/does/not/exist")
    end
    subject { @success_cmd }

    should have_readers :cmd_str, :env
    should have_readers :pid, :exitstatus, :stdout, :stderr
    should have_imeths :run, :run!
    should have_imeths :start, :wait, :stop, :kill
    should have_imeths :running?, :success?

    should "know and return its cmd string" do
      assert_equal "echo hi", subject.cmd_str
      assert_equal "echo hi", subject.to_s
    end

    should "default its env to an empty hash" do
      assert_equal({}, subject.env)
    end

    should "stringify its env hash" do
      cmd = Scmd::Command.new("echo $SCMD_TEST_VAR", {
        :SCMD_TEST_VAR => 1
      })
      expected = { 'SCMD_TEST_VAR' => '1' }
      assert_equal expected, cmd.env
    end

    should "default its result values" do
      assert_nil subject.pid
      assert_nil subject.exitstatus
      assert_equal '', subject.stdout
      assert_equal '', subject.stderr
    end

    should "run the command and set appropriate result data" do
      @success_cmd.run

      assert_not_nil @success_cmd.pid
      assert_equal 0, @success_cmd.exitstatus
      assert @success_cmd.success?
      assert_equal "hi\n", @success_cmd.stdout
      assert_equal '', @success_cmd.stderr

      @failure_cmd.run

      assert_not_nil @failure_cmd.pid
      assert_not_equal 0, @failure_cmd.exitstatus
      assert_not @failure_cmd.success?
      assert_equal '', @failure_cmd.stdout
      assert_not_equal '', @failure_cmd.stderr
    end

    should "raise an exception with proper backtrace on `run!`" do
      err = begin;
        @failure_cmd.run!
      rescue Exception => err
        err
      end

      assert_kind_of Scmd::RunError, err
      assert_includes 'No such file or directory', err.message
      assert_includes 'test/unit/command_tests.rb:', err.backtrace.first
    end

    should "return itself on `run`, `run!`" do
      assert_equal @success_cmd, @success_cmd.run
      assert_equal @success_cmd, @success_cmd.run!
      assert_equal @failure_cmd, @failure_cmd.run
    end

    should "start and be running until `wait` is called and the cmd exits" do
      cmd = Scmd::Command.new("sleep .1")
      assert_not cmd.running?

      cmd.start
      assert cmd.running?
      assert_not_nil cmd.pid

      cmd.wait
      assert_not cmd.running?
    end

    should "do nothing and return when told to wait but not running" do
      assert_not subject.running?
      assert_nil subject.pid

      subject.wait
      assert_nil subject.pid
    end

    should "do nothing and return when told to stop but not running" do
      assert_not subject.running?
      assert_nil subject.pid

      subject.stop
      assert_nil subject.pid
    end

    should "do nothing and return when told to kill but not running" do
      assert_not subject.running?
      assert_nil subject.pid

      subject.kill
      assert_nil subject.pid
    end

  end

  class InputTests < UnitTests
    desc "that takes input on stdin"
    setup do
      @cmd = Scmd::Command.new("sh")
    end
    subject { @cmd }

    should "run the command given a single line of input" do
      subject.run "echo hi"

      assert @cmd.success?
      assert_equal "hi\n", @cmd.stdout
    end

    should "run the command given multiple lines of input" do
      subject.run ["echo hi", "echo err 1>&2"]

      assert @cmd.success?
      assert_equal "hi\n",  @cmd.stdout
      assert_equal "err\n", @cmd.stderr
    end

  end

  class LongRunningTests < UnitTests
    desc "that is long running"
    setup do
      @long_cmd = Scmd::Command.new("sleep .3 && echo hi")
    end

    should "not timeout if wait timeout is longer than cmd time" do
      assert_nothing_raised do
        @long_cmd.start
        @long_cmd.wait(1)
      end
      assert @long_cmd.success?
      assert_equal "hi\n", @long_cmd.stdout
    end

    should "timeout if wait timeout is shorter than cmd time" do
      assert_raises(Scmd::TimeoutError) do
        @long_cmd.start
        @long_cmd.wait(0.1)
      end
      assert_not @long_cmd.success?
      assert_empty @long_cmd.stdout
    end

    should "be stoppable" do
      @long_cmd.start
      @long_cmd.stop

      assert_not @long_cmd.running?
    end

    should "be killable" do
      @long_cmd.start
      @long_cmd.kill

      assert_not @long_cmd.running?
    end

  end

  class BufferDeadlockTests < UnitTests
    desc "when capturing data from an output buffer"
    setup do
      @small_path = File.join(ROOT_PATH, 'test/support/smaller-than-64k.txt')
      @small_data = File.read(@small_path)
      @small_cmd  = Scmd::Command.new("cat #{@small_path}")

      @big_path = File.join(ROOT_PATH, 'test/support/bigger-than-64k.txt')
      @big_data = File.read(@big_path)
      @big_cmd  = Scmd::Command.new("cat #{@big_path}")
    end

    should "not deadlock, just stream the data from the buffer" do
      @small_cmd.start
      assert_nothing_raised{ @small_cmd.wait(1) }
      assert_equal @small_data, @small_cmd.stdout

      @big_cmd.start
      assert_nothing_raised{ @big_cmd.wait(2) }
      assert_equal @big_data, @big_cmd.stdout
    end

  end

  class WithEnvVarTests < UnitTests
    desc "with environment variables"
    setup do
      @cmd = Scmd::Command.new("echo $SCMD_TEST_VAR", {
        'SCMD_TEST_VAR' => 'test'
      })
    end

    should "use them when running the command" do
      @cmd.run
      assert_equal "test\n", @cmd.stdout
    end

  end

end
