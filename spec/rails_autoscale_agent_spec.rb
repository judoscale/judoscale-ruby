require 'spec_helper'
require 'vcr'

describe RailsAutoscaleAgent do

  it 'has a version number' do
    expect(RailsAutoscaleAgent::VERSION).not_to be nil
  end

end
