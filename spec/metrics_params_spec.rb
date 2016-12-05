require 'spec_helper'
require 'rails_autoscale_agent/metrics_params'

module RailsAutoscaleAgent
  describe MetricsParams do

    describe "#to_a" do
      it "prepares an array of hashes for consumption by the AutoScale API" do
        metrics = [
          Metric.new('type-a', Time.iso8601('2016-12-03T01:22:01Z'), 11),
          Metric.new('type-b', Time.iso8601('2016-12-03T01:22:02Z'), 22),
          Metric.new('type-a', Time.iso8601('2016-12-03T01:22:03Z'), 33),
          Metric.new('type-a', Time.iso8601('2016-12-03T01:23:03Z'), 44),
        ]

        ENV['DYNO'] = 'web.1'
        result = MetricsParams.new(metrics).to_a

        expect(result).to eql [
          {
            time: '2016-12-03T01:22:00+00:00',
            type: 'type-a',
            dyno: 'web.1',
            values: [11, 33],
          },
          {
            time: '2016-12-03T01:22:00+00:00',
            type: 'type-b',
            dyno: 'web.1',
            values: [22],
          },
          {
            time: '2016-12-03T01:23:00+00:00',
            type: 'type-a',
            dyno: 'web.1',
            values: [44],
          },
        ]
      end
    end

  end
end
