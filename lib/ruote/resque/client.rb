# encoding: UTF-8

require 'logger'
require 'ruote/resque/job'
require 'ruote/resque/reply_job'
require 'ruote/resque/version'

module Ruote
  module Resque
    class << self

      attr_accessor :configuration

      def reply(*args)
        ::Resque.enqueue(Ruote::Resque::ReplyJob, *args)
      end

      def logger
        configuration.logger
      end

      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
      end

      class Configuration
        attr_accessor :reply_queue
        attr_accessor :logger
        attr_accessor :interval
      end

    end
  end
end

# setup default configuration
Ruote::Resque.configure do |config|
  config.reply_queue = :ruote_reply
  config.logger = Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
  config.interval = 5
end
