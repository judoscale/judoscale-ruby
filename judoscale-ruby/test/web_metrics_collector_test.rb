# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/web_metrics_collector"

module RailsAutoscale
  describe WebMetricsCollector do
    let(:store) { MetricsStore.instance }

    describe ".collect?" do
      it "collects only from web dynos in the formation, to avoid unnecessary collection on workers" do
        %w[web.1 web.15 web.101].each do |dyno|
          RailsAutoscale.configure { |config| config.dyno = dyno }

          _(WebMetricsCollector.collect?(RailsAutoscale::Config.instance)).must_equal true
        end

        %w[worker.1 secondary.15 periodic.101].each do |dyno|
          RailsAutoscale.configure { |config| config.dyno = dyno }

          _(WebMetricsCollector.collect?(RailsAutoscale::Config.instance)).must_equal false
        end
      end
    end

    describe "#collect" do
      it "flushes the metrics previously collected from the store" do
        collector = WebMetricsCollector.new
        _(collector.collect).must_be :empty?

        1.upto(3) { |i| store.push :qt, i, Time.now }
        _(store.metrics.size).must_equal 3

        collected_metrics = collector.collect

        _(collected_metrics.size).must_equal 3
        _(collected_metrics.map(&:value)).must_equal [1, 2, 3]
        _(collected_metrics[0].identifier).must_equal :qt
        _(store.metrics).must_be :empty?
      end
    end
  end
end
