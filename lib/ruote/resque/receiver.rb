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

          job = ::Resque.reserve(Ruote::Resque.configuration.reply_queue)

          if job
            process(job)
          else
            sleep Ruote::Resque.configuration.interval
          end

        end

      end

      def process(job)

        item = job.args[0]
        error = job.args[1]
        if error
          flunk(item, error)
        elsif item
          receive(item)
        # elsif item['process_definition'] || item['definition']
        #   launch(item)
        end

      end

      def flunk(h, error)

        args = [ Ruote.constantize(error['class']), error['message'] ]
        args << error['backtrace']

        super(h, *args)
      end

  end

end
end
