# frozen_string_literal: true

require "assert"
require "scmd"

require "scmd/command"
require "scmd/command_spy"
require "scmd/stored_commands"

module Scmd
  class UnitTests < Assert::Context
    desc "Scmd"
    subject{ Scmd }

    should have_imeths :new, :commands, :calls, :reset, :add_command
  end

  class NonTestModeTests < UnitTests
    desc "when NOT in test mode"

    should "build a `Command` with the `new` method" do
      assert_instance_of Scmd::Command, subject.new("echo hi")
    end

    should "raise no method error on the test mode API methods" do
      [:commands, :calls, :reset].each do |meth|
        assert_raises(NoMethodError) do
          subject.send(meth)
        end
      end
      assert_raises(NoMethodError) do
        subject.add_command(Factory.string)
      end
    end
  end

  class TestModeTests < UnitTests
    desc "when in test mode"
    setup do
      @orig_scmd_test_mode = ENV["SCMD_TEST_MODE"]
      ENV["SCMD_TEST_MODE"] = "1"
      Scmd.reset
    end
    teardown do
      Scmd.reset
      ENV["SCMD_TEST_MODE"] = @orig_scmd_test_mode
    end

    should "get a command spy from the commands collection with the `new` "\
           "method" do
      assert_equal Scmd::CommandSpy.new("echo hi"), subject.new("echo hi")
    end

    should "know its test mode API attrs" do
      assert_equal StoredCommands.new, subject.commands
      assert_equal [],                 subject.calls
    end

    should "clear/remove the test mode API attrs on `reset`" do
      cmd_str = Factory.string
      subject.commands.add(cmd_str)
      subject.calls.push(cmd_str)
      assert_not_empty subject.commands
      assert_not_empty subject.calls

      subject.reset
      assert_empty subject.commands
      assert_empty subject.calls
    end

    should "add stored commands using `add_command`" do
      cmd_str = Factory.string
      output  = Factory.text
      assert_not_equal output, subject.new(cmd_str).stdout

      subject.add_command(cmd_str){ |cmd| cmd.stdout = output }
      assert_equal output, subject.new(cmd_str).stdout
    end
  end

  class CallTests < UnitTests
    desc "Call"
    setup do
      @cmd_str = Factory.string
      @input   = Factory.text
      @cmd     = CommandSpy.new(@cmd_str)

      @call = Call.new(@cmd, @input)
    end
    subject{ @call }

    should have_accessors :cmd_str, :input, :cmd

    should "know its attrs" do
      assert_equal @cmd_str, subject.cmd_str
      assert_equal @input,   subject.input
      assert_equal @cmd,     subject.cmd
    end
  end

  class TimeoutErrorTests < UnitTests
    desc "TimeoutError"
    setup do
      @error = Scmd::TimeoutError.new("test")
    end
    subject{ @error }

    should "be a RuntimeError" do
      assert_kind_of ::RuntimeError, subject
    end
  end

  class RunErrorTests < UnitTests
    desc "RunError"
    setup do
      @error = Scmd::RunError.new("test")
    end
    subject{ @error }

    should "be a RuntimeError" do
      assert_kind_of ::RuntimeError, subject
    end

    should "set its backtrace to the caller by default" do
      assert_match(/scmd_tests.rb:.*$/, subject.backtrace.first)
    end

    should "allow passing a custom backtrace" do
      called_from = caller
      error = Scmd::RunError.new("test", called_from)

      assert_equal called_from, error.backtrace
    end
  end
end
