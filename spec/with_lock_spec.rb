# encoding: utf-8
require File.expand_path(File.join('..','spec','spec_helper'), File.dirname(__FILE__))

describe WithLock do
  describe "#settings" do
    it "should have default settings" do
      WithLock::Client::settings.should == {
        'url' => 'druby://localhost:9999',
        'directory' => 'tmp',
        'scope' => 'with_lock'
      }
    end
  end
  
  describe "#url" do
    it "returns the druby url from settings" do
      WithLock::Client::settings['url'].should == WithLock::Client::url
    end
  end
  
  describe "#running(pid)" do
    it "should report if given process id represents a running pid" do
      WithLock::Server::running?($$).should be_true
    end
    it "should report if given process id doesn't represent a running pid" do
      pid = `spec/support/echo_pid.sh`.to_s.strip
      sleep 0.2
      WithLock::Server::running?(pid).should be_false
    end
  end
  
  describe "#with_lock" do 
    it "should raise an exception if with_lock server not started" do
      WithLock::Server.stop_service
      started_trying = Time.now
      while WithLock::Server.started? do
        sleep 0.2
        raise Exception.new("Couldn't stop server!") unless (Time.now - 3.seconds) > started_trying
      end
      error_message = ''
      begin
        with_lock('my_lock') do
          "I should not get here!".should be_nil
        end
      rescue WithLock::LockException => e
        e.message.should == "Couldn't connect to locker."
      end
    end
    describe "when the server is running" do
      before(:all) do
        `script/with_lock start`
        started_trying = Time.now
        while !WithLock::Server.started? do
          sleep 0.2
          raise Exception.new("Couldn't start server!") unless (Time.now - 3.seconds) > started_trying
        end
        @locker = WithLock::Client.locker
      end
      after(:all) do
        `script/with_lock stop`
        while WithLock::Server.started? do
          sleep 0.1
        end
      end
      it "should grab the named lock if its not locked" do
        with_lock('name') do 
          WithLock::Client.mine?('name').should be_true
        end
      end
      it "should not allow another process to grab the same named lock" do
        system("spec/support/get_lock.rb name 0.5 10 &")
        sleep 1
        expect {
          with_lock('name',0.5) do
          end
        }.to raise_exception(WithLock::LockException)
      end
      
      it "should have a counter of 1 when it first grabs the lock" do
        with_lock('blarg') do
          @locker.count(WithLock::Client.scoped_name('blarg')).should == 1
        end
      end
        
      it "should allow the same process to grab the same lock and increment its counter" do
        with_lock('blarg') do
          with_lock('blarg') do
            @locker.count(WithLock::Client.scoped_name('blarg')).should == 2
          end
        end
      end
      
      it "should decrement a lock's counter when it ends the block" do
        with_lock('blarg') do
          with_lock('blarg') do
          end
          @locker.count(WithLock::Client.scoped_name('blarg')).should == 1
        end
      end
      
      it "should release the lock when the block ends" do
        with_lock('blarg') do
        end
        @locker.locks[WithLock::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock if an exception closes the block" do
        begin
          with_lock('blarg') do
            raise "Blarg!!"
          end
        rescue => e
        end
        @locker.locks[WithLock::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock on a clean exit" do
        `spec/support/get_lock.rb blarg 0.3 exit`
        sleep 0.2
        @locker.locks[WithLock::Client.scoped_name('blarg')].should be_nil
      end
      
      it "should release the lock on an immediate exit" do
        `spec/support/get_lock.rb blarg 0.3 kernel_exit`
        sleep 0.2
        @locker.locks[WithLock::Client.scoped_name('blarg')].should be_nil
      end
    end
  end
end
