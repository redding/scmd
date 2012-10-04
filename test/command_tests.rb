require "assert"
require 'scmd/command'

module Scmd

  class CommandTests < Assert::Context
    desc "a command"
    setup do
      @success_cmd = Command.new("echo hi")
      @failure_cmd = Command.new("cd /path/that/does/not/exist")
    end
    subject { @success_cmd }

    should have_readers :cmd_str, :pid, :exitcode, :stdout, :stderr
    should have_instance_methods :run, :run!

    should "know and return its cmd string" do
      assert_equal "echo hi", subject.cmd_str
      assert_equal "echo hi", subject.to_s
    end

    should "default its result values" do
      assert_nil subject.pid
      assert_nil subject.exitcode
      assert_equal '', subject.stdout
      assert_equal '', subject.stderr
    end

    should "run the command and set appropriate result data" do
      @success_cmd.run

      assert_not_nil @success_cmd.pid
      assert_equal 0, @success_cmd.exitcode
      assert @success_cmd.success?
      assert_equal 'hi', @success_cmd.stdout
      assert_equal '', @success_cmd.stderr

      @failure_cmd.run

      assert_not_nil @failure_cmd.pid
      assert_not_equal 0, @failure_cmd.exitcode
      assert_not @failure_cmd.success?
      assert_equal '', @failure_cmd.stdout
      assert_not_equal '', @failure_cmd.stderr
    end

    should "raise an exception on `run!` and a non-zero exitcode" do
      assert_raises Scmd::Command::Failure do
        @failure_cmd.run!
      end
    end

    should "return itself on `run`, `run!`" do
      assert_equal @success_cmd, @success_cmd.run
      assert_equal @success_cmd, @success_cmd.run!
      assert_equal @failure_cmd, @failure_cmd.run
    end

  end

  class InputTests < CommandTests
    desc "that takes input on stdin"
    setup do
      @cmd = Command.new("sh")
    end
    subject { @cmd }

    should "run the command given a single line of input" do
      subject.run "echo hi"

      assert @cmd.success?
      assert_equal 'hi', @cmd.stdout
    end

    should "run the command given multiple lines of input" do
      subject.run ["echo hi", "echo err 1>&2"]

      assert @cmd.success?
      assert_equal 'hi', @cmd.stdout
      assert_equal 'err', @cmd.stderr
    end

  end

end
