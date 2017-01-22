require 'spec_helper'
require 'rails_autoscale_agent/reporter'
require 'rails_autoscale_agent/measurement'
require 'rails_autoscale_agent/config'
require 'webmock/rspec'

module RailsAutoscaleAgent
  describe Reporter do

    describe "#report!" do
      it "reports stored metrics to the API" do
        metrics = [Measurement.new(Time.now, 123)]
        store = double(:store, dump: metrics)
        config = Config.new('RAILS_AUTOSCALE_URL' => 'http://example.com/api')

        stub_request(:post, "http://example.com/api/reports")

        Reporter.instance.report!(config, store)

        # TODO: add expectations to make this a valid test
      end
    end

  end
end
