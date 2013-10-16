require "assert"
require 'scmd'

require 'scmd/command'

module Scmd

  class UnitTests < Assert::Context
    desc "Scmd"
    subject{ Scmd }

    should have_instance_method :new

    should "build a `Command` with the `new` method" do
      assert_kind_of Scmd::Command, subject.new('echo hi')
    end

  end

  class TimeoutErrorTests < UnitTests
    desc "TimeoutError"
    setup do
      @error = Scmd::TimeoutError.new('test')
    end
    subject{ @error }

    should "be a RuntimeError" do
      assert_kind_of ::RuntimeError, subject
    end

  end

  class RunErrorTests < UnitTests
    desc "RunError"
    setup do
      @error = Scmd::RunError.new('test')
    end
    subject{ @error }

    should "be a RuntimeError" do
      assert_kind_of ::RuntimeError, subject
    end

    should "set its backtrace to the caller by default" do
      assert_match /scmd_tests.rb:.*$/, subject.backtrace.first
    end

    should "allow passing a custom backtrace" do
      called_from = caller
      error = Scmd::RunError.new('test', called_from)

      assert_equal called_from, error.backtrace
    end

  end

end
