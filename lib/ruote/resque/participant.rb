# encoding: UTF-8

# A module to be included in your Resque jobs
# to be able to register them as participants.
#
# Note that the participant should have a queue, either via the `@queue` variable
# when the class is accessible to Ruote, or via the `:queue` option on registration
#
# @example Register a participant
#     # This is defined on a remote Resque worker
#     # You do not need to extend Participant in this case
#     class MyAwesomeJob
#       extend Ruote::Resque::Job
#       @queue = :my_queue
#
#       def self.perform(workitem)
#         workitem['fields']['awesome'] = true
#       end
#     end
#
#     # Use it like this in your Ruote process
#     engine.register_participant 'be_awesome', Ruote::Resque::Participant, :class => 'MyAwesomeJob', :queue => :my_queue
#     # Or register it va the DSL
#     Ruote::Resque.register(dashboard) do
#       be_awesome 'MyAwesomeJob', :my_queue
#     end
# A resque participant implementation.
class Ruote::Resque::Participant
  include Ruote::LocalParticipant

  # Called with the options on `engine.register_participant`
  # @param [Hash] opts
  # @option opts [#to_s] :class (self.class) the job class to enqueue when called
  # @option opts [#to_s] :queue (Resque.queue_from_class(class)) the queue to enqueue the job in
  # @option opts [Boolean] :forget (false) wait for the worker's reply if false
  def initialize(opts = {})

    @job_klass = opts.delete('class')
    @job_queue = opts.delete('queue')
    @should_forget = opts.delete('forget') || false

    # Called here to raise eventual exceptions on initialization
    ::Resque.validate(@job_klass, @job_queue)

  end

  # Called when the participant is handed a workitem.
  # Enqueues the job to Resque
  # @return [void]
  def on_workitem

    payload = encode_workitem(workitem)
    ::Resque::Job.create(@job_queue, @job_klass, payload)

    reply if @should_forget

  end

  # Called when Ruote has to cancel an active workitem for this participant.
  # Destroys the job from the Resque queue.
  #
  # Note that if the job is being processed by the worker or if the job has been processed but the reply has not,
  # this method will do nothing.
  # @return [Boolean] wether the job was deleted or not.
  def on_cancel

    payload = encode_workitem(applied_workitem)
    ::Resque::Job.destroy(@job_queue, @job_klass, payload)

  end

  # Returns a representation of a workitem that is suitable for use in Resque.
  # @param [Ruote::Workitem] workitem
  # @return [Hash] the workitem as a hash
  def encode_workitem(workitem)

    workitem.to_h

  end

  # Returns true because enqueing a job in Resque is sufficiently fast to happen in the main thread.
  # @return [true]
  def do_not_thread
    true
  end
end
