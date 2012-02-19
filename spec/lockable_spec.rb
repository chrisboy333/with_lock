# encoding: utf-8
require File.expand_path(File.join('..','spec','spec_helper'), File.dirname(__FILE__))

describe Lockable do
  describe "#settings" do
    it "should have default settings" do
      Lockable::Client::settings.should == {
        'url' => 'druby://localhost:9999',
        'directory' => 'tmp',
        'scope' => 'lockable'
      }
    end
  end
  
  describe "#url" do
    it "returns the druby url from settings" do
      Lockable::Client::settings['url'].should == Lockable::Client::url
    end
  end
  
  describe "#running(pid)" do
    it "should report if given process id represents a running pid" do
      Lockable::Server::running?($$).should be_true
    end
    it "should report if given process id doesn't represent a running pid" do
      if pid = fork
        Process.wait(pid)
        Lockable::Server::running?(pid).should be_false
      else
        Kernel.exit!
      end
    end
  end
  
  describe "#with_lock" do 
    it "should raise an exception if lockable server not started" do
      Lockable::Server.stop_service
      while Lockable::Server.started? do
        sleep 0.1
      end
      error_message = ''
      begin
        with_lock('my_lock') do
          "I should not get here!".should be_nil
        end
      rescue Lockable::LockException => e
        e.message.should == "Couldn't connect to locker."
      end
    end
    describe "when the server is running" do
      before(:each) do
        `script/lockable start`
        while !Lockable::Server.started? do
          sleep 0.1
        end
        @locker = Lockable::Client.locker
      end
      after(:each) do
        `script/lockable stop`
        while Lockable::Server.started? do
          sleep 0.1
        end
      end
      it "should grab the named lock if its not locked" do
        with_lock('name') do 
          Lockable::Client.mine?('name').should be_true
        end
      end
      it "should not allow another process to grab the same named lock" do
        if pid = fork
          sleep 0.3
          Process.detach(pid)
          expect {
            with_lock('name',0.5) do
            end
          }.to raise_exception(Lockable::LockException)
        else
          Lockable::Client.reconnect!
          with_lock('name') do
            sleep 1
          end
          Kernel.exit!
        end
      end
      
      it "should have a counter of 1 when it first grabs the lock" do
        with_lock('blarg') do
          @locker.count(Lockable::Client.scoped_name('blarg')).should == 1
        end
      end
        
      it "should allow the same process to grab the same lock and increment its counter" do
        with_lock('blarg') do
          with_lock('blarg') do
            @locker.count(Lockable::Client.scoped_name('blarg')).should == 2
          end
        end
      end
      
      it "should decrement a lock's counter when it ends the block" do
        with_lock('blarg') do
          with_lock('blarg') do
          end
          @locker.count(Lockable::Client.scoped_name('blarg')).should == 1
        end
      end
      
      it "should release the lock when the block ends" do
        with_lock('blarg') do
        end
        @locker.locks[Lockable::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock if an exception closes the block" do
        begin
          with_lock('blarg') do
            raise "Blarg!!"
          end
        rescue => e
        end
        @locker.locks[Lockable::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock on a clean exit" do
        fork do
          Lockable::Client.reconnect!
          with_lock('blarg') do
            exit
          end
        end
        @locker.locks[Lockable::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock on an immediate exit" do
        fork do
          Lockable::Client.reconnect!
          with_lock('blarg') do
            Kernel.exit!
          end
        end
        @locker.locks[Lockable::Client.scoped_name('blarg')].should be_nil
      end
    end
  end
end