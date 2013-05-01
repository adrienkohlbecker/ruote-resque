# encoding: UTF-8

require 'spec_helper'

describe Ruote::Resque::ReplyJob do

  context '::queue' do

    let(:queue) { :my_queue }
    let!(:default_queue) { Ruote::Resque.configuration.reply_queue }

    before :each do
      Ruote::Resque.configure do |config|
        config.reply_queue = queue
      end
    end

    after :each do
      Ruote::Resque.configure do |config|
        config.reply_queue = default_queue
      end
    end

    it 'returns the configured reply queue' do
      expect(Ruote::Resque::ReplyJob.queue).to eq :my_queue
    end

  end

  context '::perform' do

    it 'returns nil' do
      expect(Ruote::Resque::ReplyJob.perform).to be_nil
    end

  end

end
