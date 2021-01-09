# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "scmd/version"

Gem::Specification.new do |gem|
  gem.name        = "scmd"
  gem.version     = Scmd::VERSION
  gem.authors     = ["Kelly Redding", "Collin Redding"]
  gem.email       = ["kelly@kellyredding.com", "collin.redding@me.com"]
  gem.summary     = "Build and run system commands."
  gem.description = "Build and run system commands."
  gem.homepage    = "http://github.com/redding/scmd"
  gem.license     = "MIT"

  gem.files = `git ls-files | grep "^[^.]"`.split($INPUT_RECORD_SEPARATOR)

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency("much-style-guide", ["~> 0.6.0"])
  gem.add_development_dependency("assert",           ["~> 2.19.2"])

  gem.add_dependency("posix-spawn", ["~> 0.3.11"])
end
