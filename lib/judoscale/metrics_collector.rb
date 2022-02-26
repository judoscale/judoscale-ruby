# frozen_string_literal: true

module Judoscale
  class MetricsCollector
    # Collector class name extracted from the full class name.
    # Example: Judoscale::MyCustomMetricsCollector.collector_name => 'MyCustom'
    def self.collector_name
      @_collector_name ||= name.split("::").last.sub(/MetricsCollector$/, "")
    end

    def collector_name
      self.class.collector_name
    end

    def collect
      []
    end
  end
end
