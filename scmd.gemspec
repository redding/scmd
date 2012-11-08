# -*- encoding: utf-8 -*-
require File.expand_path('../lib/scmd/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "scmd"
  gem.version     = Scmd::VERSION
  gem.description = %q{Build and run system commands.}
  gem.summary     = %q{Build and run system commands.}

  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.homepage    = "http://github.com/redding/scmd"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_development_dependency("assert")
  gem.add_dependency("posix-spawn")
end
