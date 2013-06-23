module Ruote
module Resque



# An object to easy Participant registration
# @example Register a participant
#     # Will register a participant be_awesome
#     # that enqueues the Job MyAwesomeJob to my_queue
#     Ruote::Resque.register(dashboard) do
#       be_awesome 'MyAwesomeJob', :my_queue
#       # or via the participant method
#       participant 'be_awesome', 'MyAwesomeJob', :my_queue
#     end
class ParticipantRegistrar

  # @param [Ruote::Dashboard] dashboard
  # @return [Ruote::Resque::ParticipantRegistrar]
  def initialize(dashboard)
    @dashboard = dashboard
  end

  # Implements the dsl to register participants
  # @see Ruote::Resque::ParticipantRegistrar
  def method_missing(method_name, *args, &block)
    participant(method_name.to_s, *args, &block)
  end

  # Call this method to register a participant (or use method_missing)
  # @param [#to_s] name the name of the participant
  # @param [#to_s] klass the class of the Resque job
  # @param [#to_s] queue the queue of the job
  # @param [Hash] options options to be passed on to +Ruote::Resque::Participant+
  # @return [void]
  def participant(name, klass, queue, options={}, &block)
    options.merge!({:class => klass, :queue => queue})
    @dashboard.register_participant(name, Ruote::Resque::Participant, options, &block)
  end

end
end
end
