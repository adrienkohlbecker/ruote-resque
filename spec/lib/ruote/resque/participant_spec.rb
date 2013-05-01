# encoding: UTF-8

require 'spec_helper'

describe Ruote::Resque::Participant do

  it 'includes Ruote::LocalParticipant' do
    expect(Ruote::Resque::Participant.ancestors).to include(Ruote::LocalParticipant)
  end

  it 'includes Ruote::Resque::ParticipantModule' do
    expect(Ruote::Resque::Participant.ancestors).to include(Ruote::Resque::ParticipantModule)
  end

end
