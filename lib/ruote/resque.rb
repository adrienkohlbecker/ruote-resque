# encoding: UTF-8

require 'ruote'
require 'ruote/resque/client'
require 'ruote/resque/participant'
require 'ruote/resque/participant_registrar'
require 'ruote/resque/receiver'

module Ruote
  # Ruote::Resque allows a Ruote engine to delegates the work of it's participants
  # to Resque workers.
  #
  # Common use cases include:
  #
  # - You run a lot of jobs and need the reliability of Resque to process your jobs
  # - You have a Resque system you need to integrate with
  # - You want a separation of concerns between process orchestration and actual execution
  #
  # See the {file:README} for usage instructions
  module Resque

    # Registers resque participants using a DSL.
    # @example Using the dsl
    #     Ruote::Resque.register dashboard do
    #       be_awesome MyAwesomeJob, :my_queue
    #       be_really_awesome 'MyReallyAwesomeJob', :my_queue, :forget => true
    #     end
    # @example Using the participant method
    #     Ruote::Resque.register dashboard do
    #       participant /be_.*/, BeSomething, :my_queue
    #     end
    # @param [Ruote::Dashboard] dashboard the ruote dashboard
    # @return [void]
    def self.register(dashboard, &block)
      registrar = Ruote::Resque::ParticipantRegistrar.new(dashboard)
      registrar.instance_eval(&block)
    end

  end
end
