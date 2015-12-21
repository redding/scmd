# Scmd

Build and run system commands.  Scmd uses `posix-spawn` to fork child processes to run the commands.

## Usage

Create a command object:

```ruby
cmd = Scmd.new("echo hi")

cmd.to_s    #=> "echo hi"
cmd.inspect #=> #<Scmd::Command:0x83220514 @cmd_str="echo hi" @exitstatus=nil>

cmd.pid        #=> nil
cmd.exitstatus #=> nil
cmd.stdout     #=> ''
cmd.stderr     #=> ''
```

Run it:

```ruby
cmd.run
```

**OR**, async run it:

```ruby
cmd.start
cmd.running? # => true
cmd.pid      #=> 12345

# do other stuff...
cmd.wait # indefinitely until cmd exits
```

**OR**, async run it with a timeout:

```ruby
cmd.start

begin
  cmd.wait(10)
rescue Scmd::Timeout => err
  cmd.stop # attempt to stop the cmd nicely, kill if doesn't stop in time
  cmd.kill # just kill the cmd now
end
```

Results:

```ruby
# written to the cmd instance
cmd.pid        #=> 12345
cmd.exitstatus #=> 0
cmd.stdout     #=> 'hi'
cmd.stderr     #=> ''

# the cmd instance is returned by `run` for chaining as well
cmd.run.stdout #=> 'hi'
```

### Run with input on stdin

A single input line

```ruby
input = "echo hi"
cmd = Scmd.new("sh").run(input)
cmd.stdout #=> 'hi'
```

Multiple input lines:

```ruby
input = ["echo hi", "echo err 1>&2"]
cmd = Scmd.new("sh").run(input)
cmd.stdout #=> 'hi'
cmd.stderr #=> 'err'
```

### Some helpers

Ask if cmd was successful:

```ruby
puts cmd.stderr if !cmd.success?
```

Raise an exception if not successful with `run!`:

```ruby
Scmd.new("cd /path/that/does/not/exist").run! #=> Scmd::Command::Failure
```

### Environment variables

Pass environment variables:

```ruby
cmd = Scmd.new("echo $TEST_VAR", {
  :env => {
    'TEST_VAR' => 'hi'
  }
})
```

### Process spawn options

Pass options:

```ruby
reader, writer = IO.pipe
# this is an example that uses file descriptor redirection options
cmd = Scmd.new("echo test 1>&#{writer.fileno}", {
  :options => { writer => writer }
})
reader.gets # => "test\n"
```

For all the possible options see [posix-spawn](https://github.com/rtomayko/posix-spawn#status).

## Testing

Scmd comes with some testing utilities built in.  Specifically this includes a command spy and a "test mode" API on the main `Scmd` namespace.

### Command Spy

```ruby
require 'scmd/command_spy'
spy = Scmd::CommandSpy.new(cmd_str)
spy.exitstatus = 1
spy.stdout = 'some test output'
Assert.stub(Scmd, :new).with(cmd_str){ spy }

cmd = Scmd.new(cmd_str) # => spy
cmd.run('some input')

cmd.run_called?           # => true
cmd.run_calls.size        # => 1
cmd.run_calls.first.input # => 'some input'
```

The spy is useful for stubbing out system commands that you don't want to call or aren't safe to call in the test suite.  It responds to the same API that commands do but doesn't run any system commands.

### "Test Mode" API

```ruby
Scmd.add_command(cmd_str){ |cmd| cmd.stdout = 'some output' } # => raises NoMethodError

ENV['SCMD_TEST_MODE'] = '1'
Scmd.add_command(cmd_str){ |cmd| cmd.stdout = 'some output' }
Scmd.add_command(cmd_str).with({:env => { :SOME_ENV_VAR => '1' }}) do |cmd|
  cmd.stdout = 'some other output'
end
Scmd.commands.empty? # => false

cmd = Scmd.new(cmd_str)
cmd.class                 # => Scmd::CommandSpy
cmd.stdout                # => 'some output'
cmd.run('some input')
Scmd.calls.size           # => 1
Scmd.calls.last.class     # => Scmd::Call
Scmd.calls.last.cmd_str   # => cmd_str
Scmd.calls.last.input     # => 'some input'
Scmd.calls.last.cmd.class # => Scmd::CommandSpy

cmd = Scmd.new(cmd_str, {:env => { 'SOME_ENV_VAR' => '1' }})
cmd.class                 # => Scmd::CommandSpy
cmd.stdout                # => 'some other output'
cmd.run('some input')
Scmd.calls.size           # => 2
Scmd.calls.last.class     # => Scmd::Call
Scmd.calls.last.cmd_str   # => cmd_str
Scmd.calls.last.input     # => 'some input'
Scmd.calls.last.cmd.class # => Scmd::CommandSpy
Scmd.calls.last.cmd.env   # => { 'SOME_ENV_VAR' => '1' }

Scmd.reset
Scmd.commands.empty? # => true
Scmd.calls.empty?    # => true
```

Use these singleton methods on the `Scmd` namespace to add specific command spies in specific contexts and to track command calls (runs, starts).  Use `reset` to reset the state of things.

**Note:** these methods are only available when test mode is enabled (when the `SCMD_TEST_MODE` env var has a non-falsey value).  Otherwise these methods will raise `NoMethodError`.

## Installation

Add this line to your application's Gemfile:

    gem 'scmd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scmd

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
