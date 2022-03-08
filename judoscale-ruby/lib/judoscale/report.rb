# frozen_string_literal: true

module Judoscale
  class Report
    attr_reader :adapters, :config, :metrics

    def initialize(adapters, config, metrics = [])
      @adapters = adapters
      @config = config
      @metrics = metrics
    end

    def as_json
      {
        dyno: config.dyno,
        pid: Process.pid,
        config: config.as_json,
        adapters: adapters.each_with_object({}) { |adapter, hash|
          hash.merge!(adapter.as_json)
        },
        metrics: metrics.map { |metric|
          [
            metric.time.to_i,
            metric.value,
            metric.identifier,
            metric.queue_name
          ]
        }
      }
    end
  end
end
