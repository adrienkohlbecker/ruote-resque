require 'spec_helper'
require 'ruote/storage/fs_storage'

class BravoJob
  @queue = :rspec
  include Ruote::Resque::ParticipantModule
  extend Ruote::Resque::Job
  def self.perform(workitem)
    workitem['fields']['resque_bravo'] = 'was here'
  end
end

class BravoFailureJob < BravoJob
  @queue = :rspec
  include Ruote::Resque::ParticipantModule
  extend Ruote::Resque::Job
  def self.perform(workitem)
    raise 'im a failure'
  end
end

describe Ruote::Resque::Receiver do

  before :each do

    @board = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::FsStorage.new('spec/tmp/ruote_work')))
    #@board.noisy = true

    @board.register /^block_/ do |workitem|
      workitem.fields[workitem.participant_name] = 'was here'
    end

    Thread.new do
      queues = ['rspec']
      worker = Resque::Worker.new(*queues)
      worker.term_timeout = 4
      worker.term_child = true
      #worker.verbose = true
      worker.work(1)
    end

    Ruote::Resque.configure do |config|
      config.interval = 1
    end
    Ruote::Resque::Receiver.new(@board)

  end

  after :each do

    @board.shutdown
    system('rm -rf spec/tmp/ruote_work')

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

  context 'participant/reply flow' do

    context 'with no exceptions raised' do

      before(:each) do
        @board.register_participant 'resque_bravo', BravoJob
      end

      it 'completes successfully' do

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => 5)
          # wait until process terminates or hits an error

        r['workitem'].should_not == nil
        r['workitem']['fields']['block_alpha'].should == 'was here'
        r['workitem']['fields']['resque_bravo'].should == 'was here'
        r['workitem']['fields']['block_charly'].should == 'was here'
        r['workitem']['fields']['block_delta'].should == nil
      end
    end

    context 'with an exception raised' do

      before(:each) do
        @board.register_participant 'resque_bravo', BravoFailureJob
      end

      it 'routes to the error handler' do

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => 5)
          # wait until process terminates or hits an error

        r['workitem'].should_not == nil
        r['workitem']['fields']['block_alpha'].should == 'was here'
        r['workitem']['fields']['resque_bravo'].should == nil
        r['workitem']['fields']['block_charly'].should == nil
        r['workitem']['fields']['block_delta'].should == 'was here'
      end

      it 'can be replayed from Ruote' do

        definition = Ruote.define do
          block_alpha
          resque_bravo
          block_charly
        end

        wfid = @board.launch(definition)

        r = @board.wait_for(wfid, :timeout => 5)
        error = @board.errors(wfid).first

        expect(error.class).to eq(Ruote::ProcessError)
        expect(error.klass).to eq('RuntimeError')
        expect(error.message).to eq('raised: RuntimeError: im a failure')
        expect(error.trace).to include("/lib/resque/worker.rb:195:in `perform'")

        @board.register_participant 'resque_bravo', BravoJob
        @board.replay_at_error(error)

        r = @board.wait_for(wfid, :timeout => 5)

        r['workitem'].should_not == nil
        r['workitem']['fields']['block_alpha'].should == 'was here'
        r['workitem']['fields']['resque_bravo'].should == 'was here'
        r['workitem']['fields']['block_charly'].should == 'was here'

      end
    end
  end

  context 'process launch flow' do

    before(:each) do
      @board.register_participant 'resque_bravo', BravoJob
    end

    it 'sets the fields' do

      fields = {'test' => 'im a field'}

      Ruote::Resque.launch_process( Ruote.define { noop }, fields)

      r = @board.wait_for('terminated', :timeout => 5)

      r['workitem'].should_not == nil
      r['workitem']['fields'].should == fields

    end

    it 'sets the variables' do

      variables = {'test' => 'im a variable'}

      Ruote::Resque.launch_process(Ruote.define { noop }, {}, variables)

      r = @board.wait_for('terminated', :timeout => 5)

      r['workitem'].should_not == nil
      r['variables'].should == variables

    end

  end
end
