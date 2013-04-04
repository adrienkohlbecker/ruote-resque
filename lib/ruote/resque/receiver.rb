module Ruote
module Resque

  class Receiver < ::Ruote::Receiver

      def initialize(*args)

        super

        @listener = Thread.new do
          listen
        end
      end

      def shutdown

        @listener.kill

      end

      protected

      def listen

        loop do

          begin

            job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

            if job
              begin
                process(job)
              rescue => e
                job.fail(e)
                raise
              end
            else
              sleep Ruote::Resque.configuration.interval
            end

          rescue => e
            handle_error(e)
          end

        end

      end

      def handle_error(e)
        Ruote::Resque.logger.error(e)
      end

      def process(job)

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

      end

      def flunk(h, error)

        args = [ Ruote.constantize(error['class']), error['message'], error['backtrace'] ]

        super(h, *args)
      end

  end

end
end
