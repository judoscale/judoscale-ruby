# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/metrics_store"
require "judoscale/config"
require "judoscale/utilization_tracker"

module Judoscale
  class WebMetricsCollector < MetricsCollector
    def collect
      metrics = MetricsStore.instance.flush

      # Only report utilization if a request has already started the tracker
      if UtilizationTracker.instance.started?
        # Report utilization percentage as a whole number (floats not supported)
        idle_ratio = UtilizationTracker.instance.idle_ratio
        utilization = (1.0 - idle_ratio) * 100.0
        metrics.push Metric.new(:up, utilization, Time.now)
      end

      metrics
    end
  end
end
