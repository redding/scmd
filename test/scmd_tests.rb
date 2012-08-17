require "assert"
require 'scmd'

class ScmdTest < Assert::Context
  desc "Scmd"
  subject { Scmd }

  should have_instance_method :new

  should "build a `Command` with the `new` method" do
    assert_kind_of Scmd::Command, subject.new('echo hi')
  end

end
