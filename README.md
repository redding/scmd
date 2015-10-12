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
