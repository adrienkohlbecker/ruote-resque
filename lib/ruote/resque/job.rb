module Ruote
module Resque

  module Job

    def after_perform_reply_to_ruote(workitem)

      ::Resque.enqueue(Ruote::Resque::ReplyJob, workitem)

    end

    def on_failure_reply_to_ruote(e, workitem)

      error = {:class => e.class, :message => e, :backtrace => e.backtrace}
      ::Resque.enqueue(Ruote::Resque::ReplyJob, workitem, error)

    end

  end

end
end
