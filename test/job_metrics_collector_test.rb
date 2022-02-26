# frozen_string_literal: true

require "test_helper"
require "judoscale/job_metrics_collector"

module Judoscale
  class JobTestWorkerAdapter
    def collect!(store)
      1.upto(3) { |i| store.push :qt, i, Time.now, "some-queue" }
    end
  end

  describe JobMetricsCollector do
    describe "#collect" do
      it "wraps a worker adapter to collect metrics from" do
        collector = JobMetricsCollector.new(JobTestWorkerAdapter.new)
        collected_metrics = collector.collect

        _(collected_metrics.size).must_equal 3
        _(collected_metrics.map(&:value)).must_equal [1, 2, 3]
        _(collected_metrics[0].identifier).must_equal :qt
        _(collected_metrics[0].queue_name).must_equal "some-queue"
      end
    end
  end
end
