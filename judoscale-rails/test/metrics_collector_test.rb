# frozen_string_literal: true

require "test_helper"
require "judoscale/rails/metrics_collector"
require "judoscale/rails/utilization_middleware"

module Judoscale
  describe Rails::MetricsCollector do
    describe "#collect" do
      subject { Rails::MetricsCollector.new }

      before { Judoscale::Config.instance.utilization_enabled = true }

      after do
        tracker = Rails::UtilizationTracker.instance
        tracker.instance_variable_set(:@report_cycle_started_at, nil)
        tracker.instance_variable_get(:@active_request_counter).value = 0
      end

      it "collects utilization percentage" do
        tracker = Rails::UtilizationTracker.instance
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
