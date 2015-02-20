# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'with_lock/version'

Gem::Specification.new do |s|
  s.name        = "with_lock"
  s.version     = WithLock::VERSION
  s.authors     = ["Christopher Louis Hauboldt"]
  s.licenses    = ['MIT']
  s.email       = ["chris@hauboldt.us"]
  s.homepage    = "https://github.com/chrisboy333/with_lock"
  s.summary     = %q{Implements named mutexes for ruby applications.}
  s.description = %q{Implements named mutexes for ruby applications by creating a resource server to query for locks.}

  s.rubyforge_project = "with_lock"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">2.8", "~>2.8.0"
  s.add_dependency "daemons", ">1.1", "~>1.1.9"
end
