# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/metrics_store"

module Judoscale
  class WebMetricsCollector < MetricsCollector
    # NOTE: We collect metrics on all running web processes since they
    # all receive and handle requests independently
    def self.collect?(config)
      config.runtime_container.web?
    end

    def collect
      MetricsStore.instance.flush
    end
  end
end
