# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/metrics_store"
require "judoscale/rails/utilization_middleware"

module Judoscale
  class WebMetricsCollector < MetricsCollector
    def collect
      metrics = MetricsStore.instance.flush
      # TODO: Move this to a new Judoscale::Rails::MetricsCollector class
      if Judoscale::Config.instance.utilization_enabled
        # Report utilization percentage as a whole number (floats not supported)
        idle_ratio = Judoscale::Rails::UtilizationTracker.instance.idle_ratio
        utilization = (1.0 - idle_ratio) * 100.0
        metrics.push(Metric.new(:up, utilization, Time.now)) # Utilization percentage
      end

      metrics
    end
  end
end
