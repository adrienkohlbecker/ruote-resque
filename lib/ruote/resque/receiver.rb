module Ruote
module Resque

  class Receiver < ::Ruote::Receiver

      def initialize(*args)

        super

        @listener = Thread.new do
          loop do
            begin
              work
            rescue => e
              Ruote::Resque.logger.error("*** UNCAUGHT EXCEPTION IN RUOTE::RESQUE::RECEIVER ***")
              Ruote::Resque.logger.error(e)
            end
          end
        end
      end

      def shutdown

        @listener.kill

      end

      protected

      def work

        begin

          job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

          if job
            process(job)
          else
            sleep Ruote::Resque.configuration.interval
          end

        rescue => e
          handle_error(e)
        end

      end

      def handle_error(e)
        # to be overridden by implementors
        Ruote::Resque.logger.error(e)
      end

      def process(job)

        begin

          job_class = job.payload_class.to_s
          if job_class != 'Ruote::Resque::ReplyJob'
            raise ArgumentError.new("Not a valid job: #{job_class}")
          end

          item = job.args[0]
          error = job.args[1]

          if not (item && item['fields'] && item['fei'])
            raise ArgumentError.new("Not a workitem: #{item.inspect}")
          end

          if error
            flunk(item, error)
          else
            receive(item)
          end

        rescue => e
          # Fail it on Resque, then raise to let handle_error do it's work
          job.fail(e)
          raise
        end

      end

      def flunk(h, error)

        begin
          klass = Ruote.constantize(error['class'])
        rescue NameError => e
          klass = Object.const_set(error['class'].split('::').last, Class.new(StandardError)) # TODO improve for Resque::DirtyExit for example
        end

        args = [ klass, error['message'] ]
        args << error['backtrace'] if error['backtrace']

        super(h, *args)
      end

  end

end
end
