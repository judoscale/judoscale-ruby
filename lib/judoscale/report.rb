# frozen_string_literal: true

module Judoscale
  class Report
    attr_reader :config, :metrics

    def initialize(config, metrics = [])
      @config = config
      @metrics = metrics
    end

    def to_params
      {
        dyno: config.dyno,
        metrics: metrics.map do |metric|
          [
            metric.time.to_i,
            metric.value,
            metric.identifier,
            metric.queue_name
          ]
        end
      }
    end
  end
end
