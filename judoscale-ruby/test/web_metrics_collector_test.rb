# frozen_string_literal: true

require "test_helper"
require "judoscale/web_metrics_collector"

module Judoscale
  describe WebMetricsCollector do
    let(:store) { MetricsStore.instance }

    describe ".collect?" do
      it "always collects metrics data" do
        config = Minitest::Mock.new

        _(WebMetricsCollector.collect?(config)).must_equal true
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
