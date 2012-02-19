# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'lockable/version'

Gem::Specification.new do |s|
  s.name        = "lockable"
  s.version     = Lockable::VERSION
  s.authors     = ["Christopher Louis Hauboldt"]
  s.email       = ["chris@hauboldt.us"]
  s.homepage    = "https://github.com/chrisboy333/lockable"
  s.summary     = %q{Implements named mutexes for ruby applications.}
  s.description = %q{Implements named mutexes for ruby applications by creating a resource server to query for locks.}

  s.rubyforge_project = "lockable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_dependency "daemons"
end
