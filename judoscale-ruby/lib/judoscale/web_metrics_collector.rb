# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/metrics_store"
require "judoscale/utilization_tracker"

module Judoscale
  class WebMetricsCollector < MetricsCollector
    def collect
      metrics = MetricsStore.instance.flush

      # Only report utilization if a request has already started the tracker
      if UtilizationTracker.instance.started?
        utilization_pct = UtilizationTracker.instance.utilization_pct
        metrics.push Metric.new(:up, utilization_pct, Time.now)
      end

      metrics
    end
  end
end
