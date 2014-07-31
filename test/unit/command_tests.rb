require "assert"
require 'scmd/command'

class Scmd::Command

  class UnitTests < Assert::Context
    desc "Scmd::Command"
    setup do
      @cmd = Scmd::Command.new("echo hi")
    end
    subject { @cmd }

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

    should "default its state" do
      assert_false subject.running?
      assert_false subject.success?
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

end
