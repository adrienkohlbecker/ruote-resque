# encoding: UTF-8

require 'logger'
require 'ruote/resque/job'
require 'ruote/resque/reply_job'
require 'ruote/resque/version'

module Ruote
  module Resque

    # A basic configuration object
    # @example Setting up ruote-resque (default values shown)
    #     Ruote::Resque.configure do |config|
    #       config.reply_queue = :ruote_replies
    #       config.logger = Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
    #       config.interval = 5
    #     end
    class Configuration
      # The queue used for message passing between Resque jobs and Ruote (defaults to `:ruote_replies`)
      attr_accessor :reply_queue
      # The logger used (defaults to STDOUT with log level INFO)
      attr_accessor :logger
      # The interval used by {Receiver} when polling Resque
      attr_accessor :interval
    end

    class << self

      # Returns the current {Configuration}
      attr_accessor :configuration

      # Enqueues a ReplyJob with the given arguments.
      # @return true if the job was queued, nil if the job was rejected by a before_enqueue hook.
      # @example
      #     Ruote::Resque.reply(workitem)
      def reply(*args)
        ::Resque.enqueue(Ruote::Resque::ReplyJob, *args)
      end

      # @return [Logger] the logger to be used inside ruote-resque
      def logger
        configuration.logger
      end

      # This method allows you to customize the ruote-resque configuration.
      # @see Configuration
      # @yield [Configuration]
      # @return [void]
      def configure
        self.configuration ||= Ruote::Resque::Configuration.new
        yield(configuration) if block_given?
      end
    end
  end
end

# setup default configuration
Ruote::Resque.configure do |config|
  config.reply_queue = :ruote_replies
  config.logger = Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
  config.interval = 5
end
