module Ruote
module Resque

  module Job

    def after_perform_reply_to_ruote(workitem)
      Ruote::Resque.reply(workitem)
    end

    def on_failure_reply_to_ruote(exception, workitem)
      Ruote::Resque.reply(workitem, {:class => exception.class.to_s, :message => exception.message, :backtrace => exception.backtrace})
    end

  end

end
end
