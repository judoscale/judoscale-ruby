# frozen_string_literal: true

require "rails_autoscale/metrics_store"
require "rails_autoscale/reporter"
require "rails_autoscale/logger"
require "rails_autoscale/request_metrics"

module RailsAutoscale
  class RequestMiddleware
    include Logger

    def initialize(app)
      @app = app
    end

    def call(env)
      request_metrics = RequestMetrics.new(env)

      unless request_metrics.ignore?
        queue_time = request_metrics.queue_time
        network_time = request_metrics.network_time
      end

      Reporter.start

      if queue_time
        store = MetricsStore.instance

        # NOTE: Expose queue time to the app
        env["rails_autoscale.queue_time"] = queue_time
        store.push :qt, queue_time

        unless network_time.zero?
          env["RailsAutoscale.network_time"] = network_time
          store.push :nt, network_time
        end

        logger.debug "Request queue_time=#{queue_time}ms network_time=#{network_time}ms request_id=#{request_metrics.request_id} size=#{request_metrics.size}"
      end

      @app.call(env)
    end
  end
end
