module Ruote
module Resque

  module ParticipantModule
    include Ruote::LocalParticipant

    def initialize(opts={})

      @job_klass = opts.delete('class') || self.class
      @job_queue = opts.delete('queue') || ::Resque.queue_from_class(@job_klass)
      @should_forget = opts.delete('forget') || false

      # Called here to raise eventual exceptions on initialization
      ::Resque.validate(@job_klass, @job_queue)

    end

    def on_workitem

      payload = encode_workitem(workitem)
      ::Resque::Job.create(@job_queue, @job_klass, payload)

      reply if @should_forget

    end

    def on_cancel

      payload = encode_workitem(applied_workitem)
      ::Resque::Job.destroy(@job_queue, @job_klass, payload)

    end

    def encode_workitem(workitem)

      workitem.to_h

    end

  end
end
end
