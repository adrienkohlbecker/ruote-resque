# encoding: UTF-8

require 'spec_helper'
require 'ruote/storage/fs_storage'

class BravoJob
  @queue = :rspec
  extend Ruote::Resque::Job
  def self.perform(workitem)
    workitem['fields']['resque_bravo'] = 'was here'
  end
end

class BravoError < RuntimeError
end

class BravoFailureJob < BravoJob
  @queue = :rspec
  extend Ruote::Resque::Job
  def self.perform(workitem)
    raise BravoError, 'im a failure'
  end
end

RUOTE_WAIT_TIMEOUT = 10

describe Ruote::Resque::Receiver do

  before :each do

    Resque.redis.flushdb

    @board = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))
    # @board.noisy = true

    @board.register(/^block_/) do |workitem|
      workitem.fields[workitem.participant_name] = 'was here'
    end

    @worker = Thread.new do
      queues = ['rspec']
      worker = Resque::Worker.new(*queues)
      worker.term_timeout = 4
      worker.term_child = true
      # worker.verbose = true
      worker.work(1)
    end

    Ruote::Resque.configure do |config|
      config.interval = 1
    end

    @receiver = Ruote::Resque::Receiver.new(@board)

  end

  after :each do

    @board.shutdown
    @board.storage.purge!
    @receiver.shutdown
    @worker.kill

    Ruote::Resque.configure do |config|
      config.interval = 5
    end
  end

  let(:definition) do
    Ruote.define :on_error => 'block_delta' do
      block_alpha
      resque_bravo
      block_charly
    end
  end

  context 'invalid job handling' do

    it 'raises InvalidJob' do

      class AnotherJob
      end

      Ruote::Resque::Receiver.any_instance.should_receive(:handle_error) do |e|
        e.class.should eq(Ruote::Resque::InvalidJob)
      end

      Resque.enqueue_to(Ruote::Resque.configuration.reply_queue, 'AnotherJob')

      # Ensure it is picked up by the receiver + cleanup afterwards
      sleep 2
      ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

    end

    it 'raises InvalidWorkitem' do

      Ruote::Resque::Receiver.any_instance.should_receive(:handle_error) do |e|
        e.class.should eq(Ruote::Resque::InvalidWorkitem)
      end

      Resque.enqueue_to(Ruote::Resque.configuration.reply_queue, Ruote::Resque::ReplyJob, {})

      # Ensure it is picked up by the receiver + cleanup afterwards
      sleep 2
      ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

    end

  end

  context 'participant/reply flow' do

    context 'with no exceptions raised' do

      before(:each) do
        Ruote::Resque.register @board do
          resque_bravo BravoJob, :rspec
        end
      end

      it 'completes successfully' do

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => RUOTE_WAIT_TIMEOUT)
          # wait until process terminates or hits an error

        r['workitem'].should_not eq(nil)
        r['workitem']['fields']['block_alpha'].should eq('was here')
        r['workitem']['fields']['resque_bravo'].should eq('was here')
        r['workitem']['fields']['block_charly'].should eq('was here')
        r['workitem']['fields']['block_delta'].should eq(nil)
      end
    end

    context 'with an exception raised' do

      before(:each) do
        Ruote::Resque.register @board do
          resque_bravo BravoFailureJob, :rspec
        end
      end

      it 'routes to the error handler' do

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => RUOTE_WAIT_TIMEOUT)
          # wait until process terminates or hits an error

        r['workitem'].should_not eq(nil)
        r['workitem']['fields']['block_alpha'].should eq('was here')
        r['workitem']['fields']['resque_bravo'].should eq(nil)
        r['workitem']['fields']['block_charly'].should eq(nil)
        r['workitem']['fields']['block_delta'].should eq('was here')
      end

      it 'marks the job as failed in Resque' do

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => RUOTE_WAIT_TIMEOUT)
          # wait until process terminates or hits an error

        Resque::Failure.count.should eq(1)
        failed = Resque::Failure.all(0, 1)
        failed.class.should eq(Hash)
        failed['payload']['class'].should eq('BravoFailureJob')
        failed['exception'].should eq('BravoError')
        failed['error'].should eq('im a failure')
      end

      it 'can be replayed from Ruote' do

        definition = Ruote.define do
          block_alpha
          resque_bravo
          block_charly
        end

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => RUOTE_WAIT_TIMEOUT)
        error = @board.errors(wfid).first

        expect(error.class).to eq(Ruote::ProcessError)
        expect(error.klass).to eq('Ruote::ReceivedError')
        expect(error.message).to eq('raised: Ruote::ReceivedError: BravoError: im a failure')
        expect(error.trace).to include("/lib/resque/worker.rb:195:in `perform'")

        Ruote::Resque.register @board do
          resque_bravo BravoJob, :rspec
        end
        @board.replay_at_error(error)

        r = @board.wait_for(wfid, :timeout => RUOTE_WAIT_TIMEOUT)

        r['workitem'].should_not eq(nil)
        r['workitem']['fields']['block_alpha'].should eq('was here')
        r['workitem']['fields']['resque_bravo'].should eq('was here')
        r['workitem']['fields']['block_charly'].should eq('was here')

      end
    end
  end

end
