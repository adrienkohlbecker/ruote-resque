module Ruote
module Resque

  module Job

    def after_perform_reply_to_ruote(workitem)

      ::Resque.enqueue(Ruote::Resque::ReplyJob, workitem)

    end

    def on_failure_reply_to_ruote(e, workitem)

      workitem['error'] = {:class => e.class.name, :message => e.message, :backtrace => e.backtrace}
      ::Resque.enqueue(Ruote::Resque::ReplyJob, workitem)

    end

  end

end
end
