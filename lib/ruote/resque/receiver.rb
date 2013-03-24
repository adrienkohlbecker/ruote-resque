module Ruote
module Resque

  class Receiver < ::Ruote::Receiver

      def initialize(engine, options={})

        super(engine, options)

        Thread.new do
          listen
        end
      end

      protected

      def listen

        loop do

          job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

          if job
            Ruote::Resque.logger.debug job.args
            process(job)
          else
            Ruote::Resque.logger.debug "no jobs"
            sleep Ruote::Resque.configuration.interval
          end

        end

      end

      def process(job)

        workitem = job.args.first

        if workitem['error'] && workitem['fei']
          raise_error(workitem)
        elsif workitem['fields'] && workitem['fei']
          receive(workitem)
        else
          raise ArgumentError.new("cannot receive #{workitem.inspect}")
        end

      end

      def raise_error(workitem)

        err = workitem.delete('error')

        message   = "#{err['class']}: #{err['message']}"
        backtrace = err['trace']

        error = RemoteError.new(message)
        error.set_backtrace(backtrace) if backtrace

        error_handler = @context.error_handler
        error_handler.action_handle('error', workitem['fei'], error)

      end

  end

  class RemoteError < StandardError; end
end
end
