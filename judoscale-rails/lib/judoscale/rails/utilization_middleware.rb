# frozen_string_literal: true

require "singleton"
require "concurrent"
require "judoscale/metrics_store"

module Judoscale
  module Rails
    class UtilizationMiddleware
      def initialize(app, interval: 1)
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
        @mutex = Mutex.new
      end

      def start!(interval: 1)
        @mutex.synchronize do
          reset_idle_report_cycle!(init: true) unless @report_cycle_started_at
        end

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
        @mutex.synchronize do
          current_count = @active_request_counter.increment

          if current_count == 1 && @idle_started_at
            # We were idle and now we're not - add to total idle time
            @total_idle_time += get_current_time - @idle_started_at
            @idle_started_at = nil
          end
        end
      end

      def decr
        @mutex.synchronize do
          current_count = @active_request_counter.decrement

          if current_count == 0
            # We're now idle - start tracking idle time
            @idle_started_at = get_current_time
          end
        end
      end

      def idle_ratio(reset: true)
        @mutex.synchronize do
          return 0.0 if @report_cycle_started_at.nil?

          current_time = get_current_time

          total_report_cycle_time = current_time - @report_cycle_started_at

          return 0.0 if total_report_cycle_time <= 0

          # Capture remaining idle time
          if @idle_started_at
            @total_idle_time += current_time - @idle_started_at
            @idle_started_at = current_time
          end

          idle_ratio = @total_idle_time / total_report_cycle_time

          reset_idle_report_cycle! if reset

          idle_ratio
        end
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

      private

      def get_current_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def reset_idle_report_cycle!(init: false)
        current_time = get_current_time

        @total_idle_time = 0.0
        @report_cycle_started_at = current_time

        # Only set idle_started_at if we're setting things up for the first time,
        # otherwise we'll handle it when capturing idle_ratio.
        @idle_started_at = current_time if init
      end
    end
  end
end
