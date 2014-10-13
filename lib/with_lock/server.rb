require 'drb'
require 'daemons'

class WithLock::Server
  extend WithLock::Common
  
  def self.mutex
    @@mutex ||= Mutex.new
  end
  
  def self.owner_uri?(name)
    locks[name][:owner]
  rescue => e
    ''
  end
  
  def self.owner_pid(name)
    locks[name][:pid]
  rescue => e
    ''
  end
  
  def self.count(name)
    locks[name][:count]
  rescue => e
    0
  end
  
  def self.locked?(name)
    !locks[name].nil?# && owner_active?(name)
  end
  
  def self.mine?(owner,name)
    locked?(name) && locks[name][:owner].eql?(owner)
  end
  
  def self.get(owner,name,timeout=5)
    endtime = Time.now.to_f + timeout.to_f
    owner_uri, owner_pid = owner.split('|')
    while !mine?(owner,name)  && (Time.now.to_f < endtime)
      mutex.synchronize do
        if !locked?(name)
          locks[name] = {owner: owner, count: 1}
        end
      end
      sleep 0.01 unless mine?(owner,name)
    end
    mine?(owner,name)
  end
  
  def self.release(owner,name)
    if mine?(owner,name)
      locks.delete(name)
      true
    else
      false
    end
  end
  
  def self.increment(owner,name)
    if mine?(owner,name)
      locks[name][:count] += 1
    end
    count(name)
  end

  def self.decrement(owner,name)
    if mine?(owner,name)
      locks[name][:count] -= 1
    end
    count(name)
  end
    
  def self.locks
    @@locks ||= {}
  end
  
  def self.write_url(url)
    File.open(File.join(settings['directory'],'with_lock'),'w'){|file| file.write(url)}
  end
  
  def self.started?
    pid.to_i > 0 && running?(pid)
  end
  
  def self.daemon_settings
    {
       :multiple   => false,
       :ontop      => false,
       :backtrace  => true,
       :log_output => true,
       :monitor    => false,
       :dir_mode   => :normal,
       :dir        => 'tmp/pids'
     }
  end
  
  def self.start_service
    return if started?
    FileUtils.rm(pidfile) if File.exists?(pidfile)
    options = daemon_settings.merge(:ARGV => ['start'])
    Daemons.run_proc('with_lock', options) do 
      DRb.start_service(WithLock::Server::url,WithLock::Server)
      DRb.thread.join
    end
  end
  
  def self.run_service
    return if started?
    DRb.start_service(WithLock::Server::url,WithLock::Server)
    DRb.thread.join
  end
  
  def self.stop_service
    return unless started?
    `kill #{pid}`
    FileUtils.rm_f(pidfile)
  end
end
