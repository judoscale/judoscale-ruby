module Judoscale
  class JobMetricsCollector
    # TODO: the worker adapters will be refactored into job collectors, for now this allows us to
    # wrap that implementation temporarily to aid the refactoring and build the interfaces we want.
    def initialize(worker_adapter)
      @worker_adapter = worker_adapter
      super()
    end

    def collect
      store = []
      worker_adapter.collect!(store)
      store.map! { |args| Metric.new(*args) }
      store
    end
  end
end
