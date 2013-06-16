# encoding: UTF-8

require 'spec_helper'

describe Ruote::Resque::Participant do

  it 'includes Ruote::LocalParticipant' do
    expect(Ruote::Resque::Participant.ancestors).to include(Ruote::LocalParticipant)
  end

  it 'does not thread' do
    expect(Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue).do_not_thread).to be_true
  end

  context '#initialize' do

    it 'takes a job class in options' do

      participant = Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_other_queue)
      expect(participant.instance_variable_get(:@job_klass)).to eq Class

    end

    it 'takes a job queue in options' do

      participant = Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_other_queue)
      expect(participant.instance_variable_get(:@job_queue)).to eq :my_other_queue

    end

    it 'validates that jobs have a queue' do
      expect { Ruote::Resque::Participant.new('class' => Class) }.to raise_error ::Resque::NoQueueError
    end

    it 'validates that jobs have a class' do
      expect { Ruote::Resque::Participant.new('class' => '', 'queue' => :my_other_queue) }.to raise_error ::Resque::NoClassError
    end

  end

  context '#on_workitem' do

    let(:workitem) { { 'rspec_is_awesome' => true } }

    before :each do
      participant.stub(:workitem).and_return Ruote::Workitem.new(workitem)
    end

    context 'with forget set to false' do

      let(:participant) { Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue) }

      it 'enqueues the given job to Resque' do
        participant.on_workitem
        expected_job = { 'class' => 'Class', 'args' => [workitem] }
        expect(::Resque.pop(:my_queue)).to eq expected_job
      end

      it 'does not reply to ruote' do
        participant.should_not_receive(:reply)
        participant.on_workitem
      end

    end

    context 'with forget set to true' do

      let(:participant) { Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue, 'forget' => true) }

      it 'replies to ruote' do
        participant.should_receive(:reply)
        participant.on_workitem
      end

    end

  end

  context '#on_cancel' do

    let(:workitem) { { 'rspec_is_awesome' => true } }
    let(:participant) { Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue) }

    before :each do
      participant.stub(:workitem).and_return Ruote::Workitem.new(workitem)
      participant.stub(:applied_workitem).and_return Ruote::Workitem.new(workitem)
      participant.on_workitem
    end

    it 'removes the given job to Resque' do
      participant.on_cancel
      expect(::Resque.pop(:my_queue)).to eq nil
    end

    it 'removes only jobs with the same arguments' do
      another_participant = Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue)
      another_workitem = { 'im_another_workitem' => true }
      another_participant.stub(:workitem).and_return Ruote::Workitem.new(another_workitem)
      another_participant.on_workitem

      participant.on_cancel
      expect(::Resque.pop(:my_queue)).to eq({ 'class' => 'Class', 'args' => [another_workitem] })
    end

  end

  context '#encode_workitem' do

    let(:workitem_hash) { { 'rspec_is_awesome' => true } }
    let(:workitem) { Ruote::Workitem.new(workitem_hash) }

    it 'returns a hash representation of the workitem' do
      expect(Ruote::Resque::Participant.new('class' => Class, 'queue' => :my_queue).encode_workitem(workitem)).to eq(workitem_hash)
    end

  end

end
