# encoding: UTF-8

require 'spec_helper'

describe Ruote::Resque::Job do

  context '::after_perform_reply_to_ruote' do

    class Job
      @queue = :rspec
      extend Ruote::Resque::Job
      def self.perform(workitem)
        workitem['is_resque_awesome'] = true
      end
    end

    let(:workitem) { { 'is_rspec_awesome' => true } }
    let(:enqued_job) { ::Resque.reserve(Ruote::Resque.configuration.reply_queue) }

    context 'enqueues a job' do

      before :each do
        Job.after_perform_reply_to_ruote(workitem)
      end

      it 'to resque' do
        expect(enqued_job.class).to eq ::Resque::Job
      end

      it 'to the configured reply_queue' do
        expect(enqued_job.queue).to eq Ruote::Resque.configuration.reply_queue
      end

      it 'with the workitem as arguments' do
        expect(enqued_job.args).to eq [workitem]
      end

    end

    context 'replies with the mutated workitem' do

      let(:mutated_workitem) { { 'is_rspec_awesome' => true, 'is_resque_awesome' => true } }

      before :each do
        Resque.inline = true
      end

      after :each do
        Resque.inline = false
      end

      it 'allows the workitem to be mutated' do

        Ruote::Resque::ReplyJob.should_receive(:perform).with(mutated_workitem)
        Resque.enqueue(Job, workitem)

      end

    end

  end

  context '::on_failure_reply_to_ruote' do

    class ErrorJob
      @queue = :rspec
      extend Ruote::Resque::Job
      def self.perform(workitem)
        workitem['is_resque_awesome'] = true
        raise 'i am a failure'
      end
    end

    let(:workitem) { { 'is_rspec_awesome' => true } }
    let(:enqued_job) { ::Resque.reserve(Ruote::Resque.configuration.reply_queue) }
    let(:exception) { RuntimeError.new('i am a failure') }
    let(:expected_job_args) do
      [
        exception.class.name,
        exception.message,
        exception.backtrace,
        workitem
      ]
    end

    context 'enqueues a job' do

      before :each do
        ErrorJob.on_failure_reply_to_ruote(exception, workitem)
      end

      it 'to resque' do
        expect(enqued_job.class).to eq ::Resque::Job
      end

      it 'to the configured reply_queue' do
        expect(enqued_job.queue).to eq Ruote::Resque.configuration.reply_queue
      end

      it 'with the workitem and the error as arguments' do
        expect(enqued_job.args).to eq expected_job_args
      end

    end

    context 'replies with the mutated workitem' do

      let(:mutated_workitem) { { 'is_rspec_awesome' => true, 'is_resque_awesome' => true } }

      before :each do
        Resque.inline = true
      end

      after :each do
        Resque.inline = false
      end

      it 'allows the workitem to be mutated' do

        Ruote::Resque::ReplyJob.should_receive(:perform).with(hash_including(mutated_workitem))
        Resque.enqueue(Job, workitem)

      end

    end

  end

end
