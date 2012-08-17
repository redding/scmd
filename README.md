# Scmd

Wrapper to `open4` for running system commands.

## Installation

Add this line to your application's Gemfile:

    gem 'scmd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scmd

## Usage

Create a command object:

```ruby
cmd = Scmd.new("echo hi")

cmd.to_s    #=> "echo hi"
cmd.inspect #=> #<Scmd::Command:0x83220514 @cmd_str="echo hi" @exitcode=nil>

cmd.pid      #=> nil
cmd.exitcode #=> nil
cmd.stdout   #=> ''
cmd.stderr   #=> ''
```

Run it:

```ruby
cmd.run
```

Results:

```ruby
# written to the cmd instance
cmd.pid      #=> 12345
cmd.exitcode #=> 0
cmd.stdout   #=> 'hi'
cmd.stderr   #=> ''

# the cmd instance is returned by `run` for chaining as well
cmd.run.stdout #=> 'hi'
```

Some helpers:

```ruby
puts cmd.stderr if !cmd.success?
```

Raise an exception if not successful with `run!`:

```ruby
Scmd.new("cd /path/that/does/not/exist").run! #=> Scmd::Command::Failure
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
