module Ruote
module Resque

  class Receiver < ::Ruote::Receiver

      def initialize(*args)

        super

        Thread.new do
          listen
        end
      end

      protected

      def listen

        loop do

          job = reserve

          if job
            process(job)
          else
            sleep Ruote::Resque.configuration.interval
          end

        end

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
        if error
          flunk(item, error)
        elsif item
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
