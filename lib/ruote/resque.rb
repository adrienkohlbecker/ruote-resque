# encoding: UTF-8

require 'ruote'
require 'ruote/resque/client'
require 'ruote/resque/participant'
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
  end
end
