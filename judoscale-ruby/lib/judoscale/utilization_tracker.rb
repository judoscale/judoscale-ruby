# frozen_string_literal: true

require "singleton"

module Judoscale
  class UtilizationTracker
    include Singleton

    def initialize
      @mutex = Mutex.new
      @active_request_counter = 0
      @started = false
    end

    def start!
      @mutex.synchronize do
        unless started?
          @started = true
          init_idle_report_cycle!
        end
      end
    end

    def started?
      @started
    end

    def incr
      @mutex.synchronize do
        if @active_request_counter == 0 && @idle_started_at
          # We were idle and now we're not - add to total idle time
          @total_idle_time += get_current_time - @idle_started_at
          @idle_started_at = nil
        end

        @active_request_counter += 1
      end
    end

    def decr
      @mutex.synchronize do
        @active_request_counter -= 1

        if @active_request_counter == 0
          # We're now idle - start tracking idle time
          @idle_started_at = get_current_time
        end
      end
    end

    def utilization_pct(reset: true)
      @mutex.synchronize do
        current_time = get_current_time
        idle_ratio = get_idle_ratio(current_time: current_time)

        reset_idle_report_cycle!(current_time: current_time) if reset

        ((1.0 - idle_ratio) * 100.0).to_i
      end
    end

    private

    def get_current_time
      Process.clock_gettime Process::CLOCK_MONOTONIC
    end

    def init_idle_report_cycle!
      current_time = get_current_time
      @idle_started_at = current_time
      reset_idle_report_cycle! current_time: current_time
    end

    def reset_idle_report_cycle!(current_time:)
      @total_idle_time = 0.0
      @report_cycle_started_at = current_time
    end

    def get_idle_ratio(current_time: get_current_time)
      return 0.0 if @report_cycle_started_at.nil?

      total_report_cycle_time = current_time - @report_cycle_started_at

      return 0.0 if total_report_cycle_time <= 0

      # Capture remaining idle time
      if @idle_started_at
        @total_idle_time += current_time - @idle_started_at
        @idle_started_at = current_time
      end

      @total_idle_time / total_report_cycle_time
    end
  end
end
