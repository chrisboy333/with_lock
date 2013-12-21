require "lockable/version"
require 'erb'
require 'yaml'
require 'fileutils'
require 'logger'

module Lockable
  class LockException < Exception
  end
  
  def self.setup
    gem_dir = File.expand_path(File.join('..','..'),__FILE__)
    app_dir = File.expand_path('.')
    FileUtils.cp(File.join(gem_dir,'config','lockable.yml'),File.join(app_dir,'config','lockable.yml'))
    FileUtils.cp(File.join(gem_dir,'script','lockable'),File.join(app_dir,'script','lockable'))
    FileUtils.chmod(0755, File.join(app_dir,'script','lockable'))
    true
  end

  module Public
    def with_lock(name,timeout=5,&block)
      Lockable::Client.with_lock(name,timeout) do
        yield
      end
    end
  end
  
  module Common
    def logger
      return @@logger if defined?(@@logger) && !@@logger.nil?
      @@logger = nil
      @@logger = Rails.logger if defined?(Rails)
      FileUtils.mkdir_p('log') if @@logger.nil?
      @@logger ||= Logger.new(File.join('log','lockable.log'))
    end
    
    def url
      settings['url']
    end
    
    def pidfile
      File.join('tmp','pids','lockable.pid')
    end
    
    def pid
      File.read(pidfile).strip
    rescue => e
      nil
    end
    
    def running?(pid)
      `ps -p#{pid} | wc -l`.to_i == 2
    end
    
    def settings_filename
      File.join('config','lockable.yml')
    end
    
    def local_settings_filename
      File.join('config','lockable.local.yml')
    end
    
    def settings
      return @@settings if defined? @@settings
      @@settings = default_settings
      @@settings = @@settings.merge!(load_settings(settings_filename)||{}) if File.exists?(settings_filename)
      @@settings.merge!(load_settings(local_settings_filename)||{}) if File.exists?(local_settings_filename)
      @@settings
    end
    
    def default_settings
      {
        'directory' => File.join('tmp'),
        'url' => "druby://localhost:9999",
        'scope' => "#{File.basename(File.expand_path('.'))}#{":#{Rails.env}" if defined?(Rails)}"
      }
    end
    
    def load_settings(filename)
      YAML.load(ERB.new(File.read(filename)).result)
    end
  end
end

Lockable::Public.respond_to?(:with_lock)

require 'lockable/server'
require 'lockable/client'
Object.send :include, Lockable::Public