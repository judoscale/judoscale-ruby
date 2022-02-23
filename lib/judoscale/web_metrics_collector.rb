require "judoscale/metrics_store"

module Judoscale
  class WebMetricsCollector
    def collect
      MetricsStore.instance.flush
    end
  end
end
