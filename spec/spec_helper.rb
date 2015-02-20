$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require 'simplecov'
SimpleCov.start 'rails'
require 'with_lock'
