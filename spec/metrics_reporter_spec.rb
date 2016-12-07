require 'spec_helper'
require 'rails_autoscale_agent/metrics_reporter'
require 'rails_autoscale_agent/metric'
require 'webmock/rspec'

module RailsAutoscaleAgent
  describe MetricsReporter do

    describe "#report!" do
      it "reports stored metrics to the API" do
        metrics = [Metric.new(WAIT_TIME_TYPE, Time.now, 123)]
        store = double(:metrics_store, dump: metrics)

        stub_request(:post, "http://example.com/reports")

        MetricsReporter.instance.report!('http://example.com', store)

        # TODO: add expectations to make this a valid test
      end
    end

  end
end
