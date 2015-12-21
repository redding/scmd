require "assert"
require 'scmd/command_spy'

class Scmd::CommandSpy

  class UnitTests < Assert::Context
    desc "Scmd::CommandSpy"
    setup do
      @spy_class = Scmd::CommandSpy
    end

  end

  class InitTests < UnitTests
    setup do
      @orig_scmd_test_mode = ENV['SCMD_TEST_MODE']
      ENV['SCMD_TEST_MODE'] = '1'
      Scmd.reset

      @cmd_str = Factory.string
      @spy = @spy_class.new(@cmd_str)
    end
    teardown do
      Scmd.reset
      ENV['SCMD_TEST_MODE'] = @orig_scmd_test_mode
    end
    subject{ @spy }

    should have_readers :cmd_str, :env, :options
    should have_readers :run_calls, :run_bang_calls, :start_calls
    should have_readers :wait_calls, :stop_calls, :kill_calls
    should have_accessors :pid, :exitstatus, :stdout, :stderr
    should have_imeths :run, :run_called?, :run!, :run_bang_called?
    should have_imeths :start, :start_called?
    should have_imeths :wait, :wait_called?, :stop, :stop_called?
    should have_imeths :kill, :kill_called?
    should have_imeths :running?, :success?

    should "know and return its cmd string" do
      assert_equal @cmd_str, subject.cmd_str
      assert_equal @cmd_str, subject.to_s
    end

    should "default its attrs" do
      assert_nil subject.env
      assert_nil subject.options

      assert_equal [], subject.run_calls
      assert_equal [], subject.run_bang_calls
      assert_equal [], subject.start_calls
      assert_equal [], subject.wait_calls
      assert_equal [], subject.stop_calls
      assert_equal [], subject.kill_calls

      assert_equal 1,  subject.pid
      assert_equal 0,  subject.exitstatus
      assert_equal '', subject.stdout
      assert_equal '', subject.stderr
    end

    should "allow specifying env and options" do
      opts = { Factory.string => Factory.string }
      cmd = Scmd::Command.new(Factory.string, {
        :env     => { :SCMD_TEST_VAR => 1 },
        :options => opts
      })
      exp = { 'SCMD_TEST_VAR' => '1' }
      assert_equal exp,  cmd.env
      assert_equal opts, cmd.options
    end

    should "know whether it is running or not" do
      assert_false subject.running?

      subject.run
      assert_false subject.running?
      subject.run!
      assert_false subject.running?

      subject.start
      assert_true subject.running?
      subject.stop
      assert_false subject.running?

      subject.start
      subject.wait
      assert_false subject.running?

      subject.start
      subject.kill
      assert_false subject.running?
    end

    should "know if it was successful" do
      assert_true subject.success?

      subject.exitstatus = 1
      assert_false subject.success?

      subject.exitstatus = 0
      assert_true subject.success?

      subject.exitstatus = Factory.string
      assert_false subject.success?
    end

    should "track its run calls" do
      input = Factory.string
      subject.run(input)

      assert_equal 1, subject.run_calls.size
      assert_kind_of InputCall, subject.run_calls.first
      assert_equal input, subject.run_calls.first.input

      assert_equal 1, Scmd.calls.size
      assert_kind_of Scmd::Call, Scmd.calls.first
      assert_equal @cmd_str, Scmd.calls.first.cmd_str
      assert_equal input,    Scmd.calls.first.input
      assert_equal subject,  Scmd.calls.first.cmd

      subject.run(Factory.string)
      assert_equal 2, subject.run_calls.size
      assert_equal 2, Scmd.calls.size
    end

    should "track its run! calls" do
      input = Factory.string
      subject.run!(input)

      assert_equal 1, subject.run_bang_calls.size
      assert_kind_of InputCall, subject.run_bang_calls.first
      assert_equal input, subject.run_bang_calls.first.input

      assert_equal 1, Scmd.calls.size
      assert_kind_of Scmd::Call, Scmd.calls.first
      assert_equal @cmd_str, Scmd.calls.first.cmd_str
      assert_equal input,    Scmd.calls.first.input
      assert_equal subject,  Scmd.calls.first.cmd

      subject.run!(Factory.string)
      assert_equal 2, subject.run_bang_calls.size
      assert_equal 2, Scmd.calls.size
    end

    should "track its start calls" do
      input = Factory.string
      subject.start(input)

      assert_equal 1, subject.start_calls.size
      assert_kind_of InputCall, subject.start_calls.first
      assert_equal input, subject.start_calls.first.input

      assert_equal 1, Scmd.calls.size
      assert_kind_of Scmd::Call, Scmd.calls.first
      assert_equal @cmd_str, Scmd.calls.first.cmd_str
      assert_equal input,    Scmd.calls.first.input
      assert_equal subject,  Scmd.calls.first.cmd

      subject.start(Factory.string)
      assert_equal 2, subject.start_calls.size
      assert_equal 2, Scmd.calls.size
    end

    should "track its wait calls" do
      timeout = Factory.string
      subject.wait(timeout)

      assert_equal 1, subject.wait_calls.size
      assert_kind_of TimeoutCall, subject.wait_calls.first
      assert_equal timeout, subject.wait_calls.first.timeout

      subject.wait(Factory.string)
      assert_equal 2, subject.wait_calls.size
    end

    should "track its stop calls" do
      timeout = Factory.string
      subject.stop(timeout)

      assert_equal 1, subject.stop_calls.size
      assert_kind_of TimeoutCall, subject.stop_calls.first
      assert_equal timeout, subject.stop_calls.first.timeout

      subject.stop(Factory.string)
      assert_equal 2, subject.stop_calls.size
    end

    should "track its kill calls" do
      signal = Factory.string
      subject.kill(signal)

      assert_equal 1, subject.kill_calls.size
      assert_kind_of SignalCall, subject.kill_calls.first
      assert_equal signal, subject.kill_calls.first.signal

      subject.kill(Factory.string)
      assert_equal 2, subject.kill_calls.size
    end

    should "know if it is equal to another cmd spy" do
      spy1 = @spy_class.new(@cmd_str)
      spy2 = @spy_class.new(@cmd_str)

      assert_equal spy1, spy2

      a = [
        :cmd_str,
        :env,
        :options,
        :run_calls,
        :run_bang_calls,
        :start_calls,
        :wait_calls,
        :stop_calls,
        :kill_calls,
        :pid,
        :exitstatus,
        :stdout,
        :stderr
      ].choice
      Assert.stub(spy2, a){ Factory.string }

      assert_not_equal spy1, spy2
    end

  end

end
