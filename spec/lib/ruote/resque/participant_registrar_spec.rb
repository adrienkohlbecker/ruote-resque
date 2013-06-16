# encoding: UTF-8

require 'spec_helper'

class MyAwesomeJob
end

describe Ruote::Resque::ParticipantRegistrar do

  context '#participant' do

    let(:mock_dashboard) { Object.new }
    let(:registrar) { Ruote::Resque::ParticipantRegistrar.new(mock_dashboard) }

    it 'registers the participant to the dashboard' do

      mock_dashboard.should_receive(:register_participant).with('be_awesome', Ruote::Resque::Participant, {:class => MyAwesomeJob, :queue => :rspec})
      registrar.participant('be_awesome', MyAwesomeJob, :rspec)

    end

    it 'allows more options to be sent' do

      mock_dashboard.should_receive(:register_participant).with('be_awesome', Ruote::Resque::Participant, {:class => MyAwesomeJob, :queue => :rspec, :custom_option => :custom_value})
      registrar.participant('be_awesome', MyAwesomeJob, :rspec, :custom_option => :custom_value)

    end

  end

  context '#method_missing' do

    let(:mock_dashboard) { Object.new }
    let(:registrar) { Ruote::Resque::ParticipantRegistrar.new(mock_dashboard) }

    it 'registers the participant to the dashboard' do

      mock_dashboard.should_receive(:register_participant).with('be_awesome', Ruote::Resque::Participant, {:class => MyAwesomeJob, :queue => :rspec})
      registrar.be_awesome(MyAwesomeJob, :rspec)

    end

    it 'allows more options to be sent' do

      mock_dashboard.should_receive(:register_participant).with('be_awesome', Ruote::Resque::Participant, {:class => MyAwesomeJob, :queue => :rspec, :custom_option => :custom_value})
      registrar.be_awesome(MyAwesomeJob, :rspec, :custom_option => :custom_value)

    end


  end

end




#   def method_missing(method_name, *args, &block)
#     participant(method_name, Ruote::Resque::Participant, {:class => args[Ø], :queue => args[1]}, &block)
#   end

#   def participant(name, klass, options={}, &block)
#     @dashboard.register_participant(name, klass, options, &block)
#   end

# end
