require 'ruote/resque/participant_module'

class Ruote::Resque::Participant
  include Ruote::LocalParticipant
  include Ruote::Resque::ParticipantModule
end
