module Ruote
module Resque

  class Receiver < ::Ruote::Receiver

      # cwes = context, worker, engine or storage
      #
      def initialize(engine, options={})

        super(engine, options)

        LOGGER.info "starting resque thread"

        Thread.new do
          listen
        end
      end

      protected

      def listen

        LOGGER.info "listen"
        loop do
          job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)
          if job
            LOGGER.debug job.args
            process(job)
          else
            LOGGER.debug "no jobs"
            sleep Ruote::Resque.configuration.interval
          end
        end

      end

      def process(job)
        begin
          item = job.args.first
        if item['error'] && item['fei']
          raise_error(item)
        elsif item['fields'] && item['fei']
          receive(item)
        elsif item['process_definition'] || item['definition']
          launch(item)
        else
          raise ArgumentError.new("cannot receive or launch #{item.inspect}")
        end
      rescue => e
        puts e
      end
        # elsif type == 'launchitem'

        #   pdef, fields, variables = data

        #   launch(pdef, fields, variables)

        #else simply drop
      end

      def raise_error(h)

        err = h.delete('error')

        message   = "#{err['class']}: #{err['message']}"
        backtrace = err['trace']

        error = RemoteError.new(message)
        error.set_backtrace(backtrace) if backtrace

        error_handler = @context.error_handler
        error_handler.action_handle('error', h['fei'], error)

      end

  end

  class RemoteError < StandardError; end
end
end
