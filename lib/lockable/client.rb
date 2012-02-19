class Lockable::Client
  extend Lockable::Common
  @@locker = nil
  
  def self.scoped_name(name)
    "#{scope}-#{name}"
  end
  
  def self.identity
    "#{`hostname`.strip}|#{$$}"
  end
  
  def self.get(name,timeout=5)
    locker.get(identity,scoped_name(name),timeout)
  end
  
  def self.release(name)
    locker.release(identity,scoped_name(name))
  end
  
  def self.mine?(name)
    locker.mine?(identity,scoped_name(name))
  end
  
  def self.with_lock(name, timeout=5, &block)
    begin
      locked = mine?(name) && increment(name)
      locked ||= get(name,timeout) || raise(Lockable::LockException.new("Failed to obtain lock #{name} in #{timeout} seconds."))
      yield
    ensure
      if locker_available?
        decrement(name).to_i > 0 || release(name) || logger.debug("Warning: lock #{name} not released!")
      end
    end
  end
  
  def self.locker_available?
    locker.url
    true
  rescue DRb::DRbConnError => e
    false
  end
  
  def self.increment(name)
    locker.increment(identity,scoped_name(name))
  end

  def self.decrement(name)
    locker.decrement(identity,scoped_name(name))
  end
  
  def self.scope
    @@scope ||= Rails.env if defined? Rails
    @@scope ||= File.expand_path('.').split(File::SEPARATOR).last
  end
  
  def self.reconnect!
    DRb.stop_service
    @@uri = DRb.start_service
    @@locker = DRbObject.new_with_uri(url)
  end
  
  def self.locker
    return @@locker if (@@locker.url rescue false)
    @@locker = nil
    tries = 3
    while @@locker.nil? && tries > 0 do
      sleep 0.2 if tries < 3
      tries -= 1
      reconnect!
      @@locker = nil unless (@@locker.url rescue false)
    end
    raise Lockable::LockException.new("Couldn't connect to locker.") if @@locker.nil?
    @@locker
  end
end