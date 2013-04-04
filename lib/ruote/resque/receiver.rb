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

            job = reserve

            if job
              begin
                process(job)
              rescue => e
                job.fail(e)
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

        case job.payload_class.to_s
        when 'Ruote::Resque::ReplyJob'
          process_reply(job)
        when 'Ruote::Resque::LaunchJob'
          process_launch(job)
        end

      end

      def process_reply(job)

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

      def process_launch(job)

        process_definition = job.args[0]
        fields = job.args[1]
        variables = job.args[2]

        launch(process_definition, fields, variables)

      end

      def flunk(h, error)

        args = [ Ruote.constantize(error['class']), error['message'] ]
        args << error['backtrace']

        super(h, *args)
      end

      def reserve

        queues = [Ruote::Resque.configuration.launch_queue, Ruote::Resque.configuration.reply_queue]
        queues.each do |queue|
          if job = ::Resque.reserve(queue)
            return job
          end
        end

        return nil

      end

  end

end
end
