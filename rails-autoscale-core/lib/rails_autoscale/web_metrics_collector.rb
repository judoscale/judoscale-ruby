# frozen_string_literal: true

require "rails_autoscale/metrics_collector"
require "rails_autoscale/metrics_store"

module RailsAutoscale
  class WebMetricsCollector < MetricsCollector
    def self.collect?(config)
      config.dyno.name == "web"
    end

    def collect
      MetricsStore.instance.flush
    end
  end
end
