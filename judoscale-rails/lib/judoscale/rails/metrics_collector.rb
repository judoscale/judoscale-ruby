# frozen_string_literal: true

require "judoscale/web_metrics_collector"
require "judoscale/metric"
require "judoscale/config"
require "judoscale/rails/utilization_middleware"

module Judoscale
  module Rails
    class MetricsCollector < Judoscale::WebMetricsCollector
      def collect
        metrics = super

        if Judoscale::Config.instance.utilization_enabled && UtilizationTracker.instance.running?
          # Report utilization percentage as a whole number (floats not supported)
          idle_ratio = UtilizationTracker.instance.idle_ratio
          utilization = (1.0 - idle_ratio) * 100.0
          metrics.push(Metric.new(:up, utilization, Time.now)) # Utilization percentage
        end

        metrics
      end
    end
  end
end
