module Ruote
module Resque

  #
  # This participant emits workitems towards a beanstalk queue.
  #
  #   engine.register_participant(
  #     :heavy_labour,
  #     :reply_by_default => true, :beanstalk => '127.0.0.1:11300')
  #
  #
  # == workitem format
  #
  # Workitems are encoded in the format
  #
  #   [ 'workitem', workitem.to_h ]
  #
  # and then serialized as JSON strings.
  #
  #
  # == cancel items
  #
  # Like workitems, but the format is
  #
  #   [ 'cancelitem', fei.to_h, flavour.to_s ]
  #
  # where fei is the FlowExpressionId of the expression getting cancelled
  # (and whose workitems are to be retired) and flavour is either 'cancel' or
  # 'kill'.
  #
  #
  # == extending this participant
  #
  # Extend and overwrite encode_workitem and encode_cancelitem or
  # simply re-open the class and change those methods.
  #
  #
  # == :beanstalk
  #
  # Indicates which beanstalk to talk to
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300')
  #
  #
  # == :tube
  #
  # Most of the time, you want the workitems (or the cancelitems) to be
  # emitted over/in a specific tube
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300',
  #     'tube' => 'ruote-workitems')
  #
  #
  # == :forget (or :reply_by_default)
  #
  # If the participant is configured with 'forget' => true, the
  # participant will dispatch the workitem over to Beanstalk and then
  # immediately reply to its ruote engine (letting the flow resume).
  #
  #   engine.register_participant(
  #     'alice'
  #     Ruote::Beanstalk::ParticipantProxy,
  #     'beanstalk' => '127.0.0.1:11300',
  #     'forget' => true)
  #
  module ParticipantModule
    include Ruote::LocalParticipant

    def initialize(opts)

      begin
      @resque = opts.delete('resque') || Resque

      @job_klass = opts.delete('class') || self.class
      @job_queue = opts.delete('queue') || ::Resque.queue_from_class(@job_klass)

      # Called here to raise eventual exceptions on initialization
      ::Resque.validate(@job_klass, @job_queue)

      @opts = opts

      Ruote::Resque.logger.debug("Initialized Ruote::Resque::ParticipantProxy, class is #{@job_klass}, queue is #{@job_queue}")

    rescue => e
      puts e
    end
    end

    def on_workitem

      begin

      payload = encode_workitem(workitem)
      ::Resque::Job.create(@job_queue, @job_klass, payload)

      Ruote::Resque.logger.debug("Enqueued #{@job_klass}to #{@job_queue} with payload #{payload}")

      reply if @opts['reply_by_default'] || @opts['forget']

    rescue => e
      puts e
    end

    end

    def on_cancel

      payload = encode_workitem(applied_workitem)
      destroyed = ::Resque::Job.destroy(@job_queue, @job_klass, payload)

      Ruote::Resque.logger.debug("Cancelled #{destroyed} jobs #{@job_klass} from #{@job_queue} with payload #{payload}")

    end

    def encode_workitem(workitem)

      workitem.to_h

    end

  end
end
end
