# frozen_string_literal: true

require "singleton"
require "judoscale/utilization_tracker"

module Judoscale
  class UtilizationMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      tracker = UtilizationTracker.instance
      tracker.start! unless tracker.started?

      tracker.incr

      @app.call(env)
    ensure
      tracker.decr
    end
  end
end
