# encoding: UTF-8

module Ruote
module Resque

  class InvalidJob < RuntimeError
  end

  class InvalidWorkitem < RuntimeError
  end

  class Receiver < ::Ruote::Receiver

    def initialize(*args)
      super
      @listener = listen
    end

    def shutdown
      @listener.kill
    end

    def handle_error(e)
      # to be overridden by implementors
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

      def conditional_define(constant, value, parent=Object)
        if parent.const_defined? constant
          parent.const_get(constant)
        else
          parent.const_set(constant, value)
        end
      end

      def recursive_define(constant, value, parent=Object)

        arr = constant.split('::')
        first = arr.shift
        if arr.empty?
          conditional_define(first, value, parent)
        else
          recursive_define(arr.join('::'), value, conditional_define(first, Class.new, parent))
        end

      end

      klass = recursive_define(class_name, Class.new(RuntimeError))
      args = [ klass, message, backtrace ]

      super(workitem, *args)


    end

  end

end
end
