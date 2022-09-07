# frozen_string_literal: true

module RailsAutoscale
  class MetricsCollector
    def self.collect?(config)
      true
    end

    def collect
      []
    end
  end
end
