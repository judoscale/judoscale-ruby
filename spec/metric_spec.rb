require 'spec_helper'
require 'rails_autoscale_agent/metric'

module RailsAutoscaleAgent
  describe Metric do

    describe "#value" do
      it "is always an Integer" do
        metric = Metric.new('test-type', Time.now, 123.45)
        expect(metric.value).to eql 123
      end
    end

    describe "#time" do
      it "is always in UTC" do
        metric = Metric.new('test-type', Time.iso8601('2016-12-03T01:11:00-05:00'), 123)
        expect(metric.time.iso8601).to eql '2016-12-03T06:11:00Z'
      end
    end
  end
end
