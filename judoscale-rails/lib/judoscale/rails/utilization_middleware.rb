# frozen_string_literal: true

require "singleton"
require "concurrent"
require "judoscale/metrics_store"

module Judoscale
  module Rails
    class UtilizationMiddleware
      def initialize(app, interval:)
        @app = app
        @interval = interval
      end

      def call(env)
        tracker = UtilizationTracker.instance
        tracker.start!(interval: @interval)
        tracker.incr

        @app.call(env)
      ensure
        tracker.decr
      end
    end

    class UtilizationTracker
      include Singleton

      def initialize
        @active_request_counter = Concurrent::AtomicFixnum.new(0)
        @thread_ref = Concurrent::AtomicReference.new(nil)
      end

      def start!(interval:)
        @thread_ref.update do |current_thread|
          next current_thread if current_thread&.alive?

          Thread.new do
            # Advise multi-threaded app servers to ignore this thread for the purposes of fork safety warnings.
            Thread.current.thread_variable_set(:fork_safe, true)

            loop do
              sleep interval
              track_current_state
            end
          end
        end
      end

      def incr
        @active_request_counter.increment
      end

      def decr
        @active_request_counter.decrement
      end

      def track_current_state
        active_requests = @active_request_counter.value
        active_processes = (active_requests > 0) ? 1 : 0
        time = Time.now.utc

        MetricsStore.instance.tap do |store|
          store.push :pu, active_processes, time # pu = process utilization
          store.push :ru, active_requests, time  # ru = request utilization
        end
      end
    end
  end
end
