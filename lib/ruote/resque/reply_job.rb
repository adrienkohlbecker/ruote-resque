# encoding: UTF-8

module Ruote
module Resque

  module ReplyJob

    def self.queue
      Ruote::Resque.configuration.reply_queue
    end

    def self.perform(*args)
      #noop
    end

  end

end
end
