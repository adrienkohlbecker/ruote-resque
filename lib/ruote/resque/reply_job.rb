# encoding: UTF-8

module Ruote
module Resque

  # An empty job used for message passing between job instances and ruote-resque.
  module ReplyJob

    # @return [#to_s] The configured queue for message passing.
    def self.queue
      Ruote::Resque.configuration.reply_queue
    end

    # This is a no-op.
    # @return [void]
    def self.perform(*args)
      # noop
    end

  end

end
end
