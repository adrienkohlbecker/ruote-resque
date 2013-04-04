require 'spec_helper'

describe Ruote::Resque do

  context '::logger' do

    it 'returns a Logger instance' do
      expect(Ruote::Resque.logger.class).to eq Logger
    end

  end

  context '::configuration' do

    it 'returns a Configuration object' do
      expect(Ruote::Resque.configuration.class.name.split('::').last).to eq 'Configuration'
    end

    context '::reply_queue' do

      it 'is :ruote_reply by default' do
        expect(Ruote::Resque.configuration.reply_queue).to eq :ruote_reply
      end

      it 'is setable' do
        Ruote::Resque.configuration.reply_queue = :another_queue
        expect(Ruote::Resque.configuration.reply_queue).to eq :another_queue
      end

    end

    context '::interval' do

      it 'is 5 by default' do
        expect(Ruote::Resque.configuration.interval).to eq 5
      end

      it 'is setable' do
        Ruote::Resque.configuration.interval = 1
        expect(Ruote::Resque.configuration.interval).to eq 1
      end

    end

    context '::logger' do

      it 'is a Logger instance' do
        expect(Ruote::Resque.configuration.logger.class).to eq Logger
      end

      it 'is logging at INFO level' do
        expect(Ruote::Resque.configuration.logger.level).to eq Logger::INFO
      end

      it 'is a setable' do

        class MyLogger < Logger; end
        Ruote::Resque.configuration.logger = MyLogger.new(STDOUT)

        expect(Ruote::Resque.configuration.logger.class).to eq MyLogger
      end

    end

  end

end
