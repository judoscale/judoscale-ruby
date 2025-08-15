# frozen_string_literal: true

require "test_helper"
require "minitest/stub_const"
require "judoscale/web_metrics_collector"
require "judoscale/config"
require "judoscale/utilization_tracker"

module RailsMock
  module Command
    class GenerateCommand; end
  end
end

module Judoscale
  describe WebMetricsCollector do
    describe "#collect" do
      subject { WebMetricsCollector.new }

      let(:store) { MetricsStore.instance }

      after { reset_tracker_state }

      it "flushes the metrics previously collected from the store" do
        _(subject.collect).must_be :empty?

        1.upto(3) { |i| store.push :qt, i, Time.now }
        _(store.metrics.size).must_equal 3

        collected_metrics = subject.collect

        _(collected_metrics.size).must_equal 3
        _(collected_metrics.map(&:value)).must_equal [1, 2, 3]
        _(collected_metrics[0].identifier).must_equal :qt
        _(store.metrics).must_be :empty?
      end

      it "collects utilization percentage" do
        tracker = UtilizationTracker.instance
        tracker.start!
        sleep 0.001

        collected_metrics = subject.collect

        # No requests yet, utilization is 0
        _(collected_metrics.map(&:identifier)).must_equal [:up]
        _(collected_metrics[0].value).must_equal 0

        tracker.incr
        sleep 0.001

        collected_metrics = subject.collect

        # Request started, utilization is > 0
        _(collected_metrics.map(&:identifier)).must_equal [:up]
        _(collected_metrics[0].value).must_be :>, 0
      end
    end
  end
end
