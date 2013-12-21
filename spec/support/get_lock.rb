#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

$:.push File.expand_path(File.join('..','..','lib'), __FILE__)

require "rubygems"
require "bundler"
Bundler.setup

require 'lockable'
include Lockable::Public

begin
  with_lock(ARGV[0],ARGV[1].to_f||0.5) do
    sleep ARGV[2].to_f
    Kernel.exit! if ARGV[3].eql?('kernel_exit')
    exit(0) if ARGV[2].eql?('exit')
  end
rescue Lockable::LockException => e
  puts exit(1)
end