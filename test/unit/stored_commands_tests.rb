# frozen_string_literal: true

require "assert"
require "scmd/stored_commands"

require "scmd/command_spy"

class Scmd::StoredCommands
  class UnitTests < Assert::Context
    desc "Scmd::StoredCommands"
    setup do
      @cmd_str = Factory.string
      @opts    = { Factory.string => Factory.string }
      @output  = Factory.text

      @commands = Scmd::StoredCommands.new
    end
    subject{ @commands }

    should have_imeths :add, :get, :remove, :remove_all, :empty?

    should "allow adding and getting commands when yielded a command" do
      yielded = nil
      subject.add(@cmd_str) do |cmd|
        yielded = cmd
        cmd.stdout = @output
      end
      cmd_spy = subject.get(@cmd_str, {})

      assert_instance_of Scmd::CommandSpy, yielded
      assert_equal yielded, cmd_spy
      assert_equal @output, cmd_spy.stdout
    end

    should "return a stub when adding a command" do
      stub = subject.add(@cmd_str)
      assert_instance_of Scmd::StoredCommands::Stub, stub

      stub.with(@opts){ |cmd| cmd.stdout = @output }
      cmd = subject.get(@cmd_str, @opts)
      assert_equal @output, cmd.stdout

      cmd = subject.get(@cmd_str, {})
      assert_not_equal @output, cmd.stdout
    end

    should "return a unaltered cmd spy for a cmd str that isn't configured" do
      cmd_spy = Scmd::CommandSpy.new(@cmd_str)
      cmd = subject.get(@cmd_str)

      assert_equal cmd_spy, cmd
    end

    should "not call a cmd block until it is retrieved" do
      called = false
      subject.add(@cmd_str){ called = true }
      assert_false called
      subject.get(@cmd_str)
      assert_true called
    end

    should "allow removing a stub" do
      subject.add(@cmd_str){ |cmd| cmd.stdout = @output }
      cmd = subject.get(@cmd_str)
      assert_equal @output, cmd.stdout

      subject.remove(@cmd_str)
      cmd = subject.get(@cmd_str)
      assert_not_equal @output, cmd.stdout
    end

    should "allow removing all commands" do
      subject.add(@cmd_str){ |cmd| cmd.stdout = @output }
      other_cmd_str = Factory.string
      subject.add(other_cmd_str){ |cmd| cmd.stdout = @output }

      subject.remove_all
      cmd = subject.get(@cmd_str)
      assert_not_equal @output, cmd.stdout
      cmd = subject.get(other_cmd_str)
      assert_not_equal @output, cmd.stdout
    end

    should "know if it is empty or not" do
      assert_empty subject

      subject.add(@cmd_str)
      assert_not_empty subject

      subject.remove_all
      assert_empty subject
    end

    should "know if it is equal to another stored commands or not" do
      cmds1 = Scmd::StoredCommands.new
      cmds2 = Scmd::StoredCommands.new
      assert_equal cmds1, cmds2

      cmds1.add(@cmd_str)
      assert_not_equal cmds1, cmds2
    end
  end

  class StubTests < UnitTests
    desc "Stub"
    setup do
      @stub = Stub.new(@cmd_str)
    end
    subject{ @stub }

    should have_readers :cmd_str, :hash
    should have_imeths :set_default_proc, :with, :call

    should "default its default command proc" do
      cmd_spy = Scmd::CommandSpy.new(@cmd_str, @opts)
      cmd = subject.call(@opts)
      assert_equal cmd_spy, cmd
    end

    should "allow setting its default proc" do
      subject.set_default_proc{ |cmd| cmd.stdout = @output }
      cmd = subject.call(@opts)
      assert_equal @output, cmd.stdout
    end

    should "allow setting commands for specific opts" do
      cmd = subject.call(@opts)
      assert_equal "", cmd.stdout

      subject.with({}){ |cmd| cmd.stdout = @output }
      cmd = subject.call({})
      assert_equal @output, cmd.stdout
    end

    should "know if it is equal to another stub or not" do
      stub1 = Stub.new(@cmd_str)
      stub2 = Stub.new(@cmd_str)
      assert_equal stub1, stub2

      Assert.stub(stub1, [:cmd_str, :hash].sample){ Factory.string }
      assert_not_equal stub1, stub2
    end
  end
end
