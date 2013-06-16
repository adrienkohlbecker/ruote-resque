class Ruote::Resque::ParticipantRegistrar

  def initialize(dashboard)
    @dashboard = dashboard
  end

  def method_missing(method_name, *args, &block)
    participant(method_name.to_s, *args, &block)
  end

  def participant(name, klass, queue, options={}, &block)
    options.merge!({:class => klass, :queue => queue})
    @dashboard.register_participant(name, Ruote::Resque::Participant, options, &block)
  end

end
