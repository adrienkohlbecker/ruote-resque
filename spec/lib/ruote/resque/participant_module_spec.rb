# encoding: UTF-8

require 'spec_helper'

describe Ruote::Resque::ParticipantModule do

  class Participant
    @queue = :my_queue
    include Ruote::Resque::ParticipantModule
  end

  it 'includes Ruote::LocalParticipant' do
    expect(Ruote::Resque::ParticipantModule.ancestors).to include(Ruote::LocalParticipant)
  end

  context '#initialize' do

    it 'takes a job class in options' do

      participant = Participant.new('class' => Class, 'queue' => :my_other_queue)
      expect(participant.instance_variable_get(:@job_klass)).to eq Class

    end

    it 'defaults to self.class when no class is provided' do

      participant = Participant.new
      expect(participant.instance_variable_get(:@job_klass)).to eq Participant

    end

    it 'takes a job queue in options' do


      participant = Participant.new('class' => Class, 'queue' => :my_other_queue)
      expect(participant.instance_variable_get(:@job_queue)).to eq :my_other_queue

    end

    it 'defaults to ::Resque.queue_from_class when no queue is provided' do

      participant = Participant.new
      expect(participant.instance_variable_get(:@job_queue)).to eq :my_queue

    end

    it 'validates that jobs have a queue' do
      expect{Participant.new('class' => Class)}.to raise_error ::Resque::NoQueueError
    end

    it 'validates that jobs have a class' do
      expect{Participant.new('class' => '', 'queue' => :my_other_queue)}.to raise_error ::Resque::NoClassError
    end

  end


  context '#on_workitem' do

    let(:workitem) { { 'rspec_is_awesome' => true} }

    before :each do
      participant.stub(:workitem).and_return Ruote::Workitem.new(workitem)
    end

    context 'with forget set to false' do

      let(:participant) { Participant.new }

      it 'enqueues the given job to Resque' do
        participant.on_workitem
        expected_job = {'class' => 'Participant', 'args' => [workitem]}
        expect(::Resque.pop(:my_queue)).to eq expected_job
      end

      it 'does not reply to ruote' do
        participant.should_not_receive(:reply)
        participant.on_workitem
      end

    end

    context 'with forget set to true' do

      let(:participant) { Participant.new('forget' => true) }

      it 'replies to ruote' do
        participant.should_receive(:reply)
        participant.on_workitem
      end

    end

  end

  context '#on_cancel' do

    let(:workitem) { { 'rspec_is_awesome' => true} }
    let(:participant) { Participant.new }

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
      another_participant = Participant.new
      another_workitem = {'im_another_workitem' => true}
      another_participant.stub(:workitem).and_return Ruote::Workitem.new(another_workitem)
      another_participant.on_workitem

      participant.on_cancel
      expect(::Resque.pop(:my_queue)).to eq({'class' => 'Participant', 'args' => [another_workitem]})
    end

  end

  context '#encode_workitem' do

    let(:workitem_hash) { { 'rspec_is_awesome' => true} }
    let(:workitem) { Ruote::Workitem.new(workitem_hash) }

    it 'returns a hash representation of the workitem' do
      expect(Participant.new.encode_workitem(workitem)).to eq(workitem_hash)
    end

  end

end
