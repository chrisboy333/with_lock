require "bundler/gem_tasks"
require 'simplecov'

require 'rspec/core/rake_task'
desc 'Run the specs'
RSpec::Core::RakeTask.new do |r|
  r.verbose = false
end

#desc "Run all examples with RCov"
#RSpec::Core::RakeTask.new('examples_with_rcov') do |t|
#  #t.spec_files = FileList['spec/**/*.rb']
#  t.rcov = true
#  #t.rcov_opts = ['--exclude', 'spec']
#end
#
#begin
#  require 'spec/rake/verify_rcov'
#  RCov::VerifyTask.new(:verify_rcov => 'spec:rcov') do |t|
#    t.threshold = 100.0
#    t.index_html = 'coverage/index.html'
#  end
#rescue LoadError => e
#end

task :default => :spec
