# encoding: UTF-8

module Ruote
module Resque

  # Raised when a job different from `Ruote::Resque::ReplyJob
  # is found on the reply_queue.
  class InvalidJob < RuntimeError
  end

  # Raised when a reply job has an invalid workitem.
  class InvalidWorkitem < RuntimeError
  end

  # The receiver will poll the reply_queue in Resque, waiting for reply jobs.
  # It does so in a new thread.
  #
  # By default it polls the reply_queue every 5 seconds, but this is configurable via
  # the `interval` configuration option. See {Ruote::Resque}.
  #
  # You should launch the Receiver as soon as your engine is set up.
  #
  # @example Running a ruote-resque Receiver
  #     Ruote::Resque::Receiver.new(dashboard)
  #
  # @example Overriding the handle_error method for custom exception handling
  #     class Ruote::Resque::Receiver
  #       def handle_error(e)
  #         MyErrorHandler.handle(e)
  #       end
  #     end
  #
  #     Ruote::Resque::Receiver.new(dashboard)
  #
  class Receiver < ::Ruote::Receiver

    # Retunrs a new Receiver instance and spawns a worker thread.
    # @param [Ruote::Dashboard] cwes Accepts context, worker, engine or storage
    # @param [Hash] options Passed on to Ruote, currently unused.
    # @return [Receiver]
    def initialize(cwes, options={})
      super
      @listener = listen
    end

    # Stops the worker thread.
    # @return [void]
    def shutdown
      @listener.kill
    end

    # Called when an error is raised during the poll/reserve/process flow of the Receiver.
    # You should override this method for custom error handling.
    # By default it just logs the exception.
    # @param [Exception] e
    # @return [void]
    def handle_error(e)
      Ruote::Resque.logger.error(e)
    end

    private

    def listen

      Thread.new do
        loop do
          work
        end
      end

    end

    def work

      reserve

    # handle_error may raise an exception itself
    # in this case protect the thread
    rescue => e
      Ruote::Resque.logger.error('*** UNCAUGHT EXCEPTION IN RUOTE::RESQUE::RECEIVER ***')
      Ruote::Resque.logger.error(e)
    end

    def reserve

      if job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)
        validate_job(job)
        process(job)
      else
        sleep Ruote::Resque.configuration.interval
      end

    rescue => e
      handle_error(e)
    end

    def process(job)

      job_arguments = job.args
      item = job_arguments.pop

      if job_arguments.any?
        flunk(item, *job_arguments)
      else
        receive(item)
      end

    rescue => e
      # Fail the job on Resque, then raise to let handle_error do it's work
      job.fail(e)
      raise
    end

    def validate_job(job)

      job_class = job.payload_class.to_s
      unless job_class == 'Ruote::Resque::ReplyJob'
        raise InvalidJob.new(job_class)
      end

      item = job.args.last
      unless item.is_a?(Hash) && item['fields'] && item['fei']
        raise InvalidWorkitem.new(item.inspect)
      end

    end

    def flunk(workitem, class_name, message, backtrace)

      error = Ruote::ReceivedError.new(class_name, message, backtrace)
      args = [error, message, backtrace]

      super(workitem, *args)

    end

  end

end
end
