# frozen_string_literal: true

require "judoscale/utilization_tracker"

module UtilizationTrackerHelpers
  def tracker
    Judoscale::UtilizationTracker.instance
  end

  def reset_tracker_state
    # Reset all singleton state to ensure clean test isolation
    tracker.instance_variable_set(:@started, false)
    tracker.instance_variable_set(:@active_request_counter, 0)
    tracker.instance_variable_set(:@report_cycle_started_at, nil)
    tracker.instance_variable_set(:@idle_started_at, nil)
    tracker.instance_variable_set(:@total_idle_time, 0.0)
  end
end

Judoscale::Test.include(UtilizationTrackerHelpers)
