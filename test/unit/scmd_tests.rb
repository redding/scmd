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

end
