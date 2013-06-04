# encoding: UTF-8

module Ruote
module Resque

  # Include this module inside your Resque jobs to enable
  # them to respond to Ruote.
  #
  # - Note that the arity should be 1 for the `self.perform` method.
  # - The workitem will be sent as a Hash. (via `Ruote::Workitem#to_h`)
  #
  # @example
  #     class MyAwesomeJob
  #       extend Ruote::Resque::Job
  #
  #       def self.perform(workitem)
  #         workitem['fields']['awesome'] = true
  #       end
  #     end
  module Job

    # after_perform hook to send a reply to the Ruote process.
    # @param [Hash] workitem the workitem sent to the current Job
    # @return [void]
    def after_perform_reply_to_ruote(workitem)
      Ruote::Resque.reply(workitem)
    end

    # on_failure hook to send a reply to the Ruote process.
    # Will collect the exception details and send them along.
    # @param [Exception] exception the raised exception
    # @param [Hash] workitem the workitem sent to the current Job.
    #   TODO: this may be mutated from the original workitem, handle it.
    # @return [void]
    def on_failure_reply_to_ruote(exception, workitem)

      klass = exception.class.to_s
      message = exception.message
      backtrace = exception.backtrace

      Ruote::Resque.reply(klass, message, backtrace, workitem)
    end

  end

end
end
