# frozen_string_literal: true

require "judoscale/metrics_collector"

module Judoscale
  class JobMetricsCollector < MetricsCollector
    class TempStore
      attr_reader :metrics

      def initialize
        @metrics = []
      end

      def push(identifier, value, time, queue_name)
        @metrics << Metric.new(identifier, value, time, queue_name)
      end
    end

    attr_reader :worker_adapter

    # TODO: the worker adapters will be refactored into job collectors, for now this allows us to
    # wrap that implementation temporarily to aid the refactoring and build the interfaces we want.
    def initialize(worker_adapter)
      @worker_adapter = worker_adapter
      super()
    end

    # Override the collector name to delegate to the worker adapter, so we can log "Sidekiq"
    # (for example) instead of "Job".
    def collector_name
      worker_adapter.class.adapter_name
    end

    def collect
      store = TempStore.new
      worker_adapter.collect!(store)
      store.metrics
    end
  end
end
