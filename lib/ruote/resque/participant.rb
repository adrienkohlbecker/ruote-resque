# encoding: UTF-8

require 'ruote/resque/participant_module'

# A resque participant implementation.
# @see Ruote::Resque::ParticipantModule
# @example
#     dashboard.register_participant 'be_awesome', Ruote::Resque::Participant, :class => 'MyAwesomeJob', :queue => :my_queue
class Ruote::Resque::Participant
  include Ruote::Resque::ParticipantModule
end
