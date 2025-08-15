# frozen_string_literal: true

require "test_helper"
require "judoscale/utilization_tracker"

module Judoscale
  describe UtilizationTracker do
    after { reset_tracker_state }

    it "tracks utilization percentage based on time spent with no active requests" do
      # T=0:   Start tracker
      # T=1:   Request 1 starts -> total_idle_time=1
      # T=2:   Request 1 ends   -> total_idle_time=1
      # T=4:   Request 2 starts -> total_idle_time=3 (1 + 2)
      # T=5:   Request 3 starts -> total_idle_time=3
      # T=6:   Request 2 ends   -> total_idle_time=3
      # T=8:   Request 3 ends   -> total_idle_time=3
      # T=10:  Report cycle     -> total_idle_time=5 (3 + 2), utilization_pct=50

      current_time = 0

      # Stub Process.clock_gettime to return our controlled monotonic time
      Process.stub(:clock_gettime, ->(_) { current_time }) do
        # T=0: Tracker starts
        tracker.start!
        _(tracker.utilization_pct(reset: false)).must_equal 100 # No time has passed yet

        # T=1: Request 1 starts
        current_time = 1
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 0 # 1 second idle out of 1 total second = 100% idle

        # T=2: Request 1 ends
        current_time = 2
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 50 # 1 second idle out of 2 total seconds = 50% idle

        # T=4: Request 2 starts
        current_time = 4
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 25 # 3 seconds idle out of 4 total seconds = 75% idle

        # T=5: Request 3 starts
        current_time = 5
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 40 # 3 seconds idle out of 5 total seconds = 60% idle

        # T=6: Request 2 ends
        current_time = 6
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 50 # 3 seconds idle out of 6 total seconds = 50% idle

        # T=8: Request 3 ends
        current_time = 8
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 62 # 3 seconds idle out of 8 total seconds = 37.5% idle

        # T=10: Report cycle - should calculate final utilization percentage
        current_time = 10
        _(tracker.utilization_pct).must_equal 50 # 5 seconds idle out of 10 total seconds = 50% idle
      end
    end

    it "resets the tracking cycle when utilization_pct is requested with no args" do
      # T=0:   Start tracker
      # T=1:   Request 1 starts -> total_idle_time=1
      # T=2:   Request 1 ends   -> total_idle_time=1
      # T=4:   Report cycle     -> total_idle_time=3 (1 + 2), utilization_pct=25
      # T=5:   Request 2 starts -> total_idle_time=1
      # T=8:   Report cycle     -> total_idle_time=1 (request still running), utilization_pct=75
      # T=9:   Request 3 starts -> total_idle_time=0
      # T=10:  Request 2 ends   -> total_idle_time=0
      # T=11:  Request 3 ends   -> total_idle_time=0
      # T=12:  Report cycle     -> total_idle_time=1, utilization_pct=75

      current_time = 0

      # Stub Process.clock_gettime to return our controlled monotonic time
      Process.stub(:clock_gettime, ->(_) { current_time }) do
        # T=0: Tracker starts
        tracker.start!
        _(tracker.utilization_pct(reset: false)).must_equal 100 # No time has passed yet

        # T=1: Request 1 starts
        current_time = 1
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 0 # 1 second idle out of 1 total second = 100% idle

        # T=2: Request 1 ends
        current_time = 2
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 50 # 1 second idle out of 2 total seconds = 50% idle

        current_time = 3
        _(tracker.utilization_pct(reset: false)).must_equal 33 # 2 seconds idle out of 3 total seconds = 66.66% idle

        # T=4: Report cycle
        current_time = 4
        _(tracker.utilization_pct).must_equal 25 # 3 seconds idle out of 4 total seconds = 75% idle

        # T=5: Request 2 starts
        current_time = 5
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 0 # 1 second idle out of 1 total second = 100% idle

        # T=8: Report cycle
        current_time = 8
        _(tracker.utilization_pct).must_equal 75 # 1 second idle out of 4 total seconds = 25% idle

        # T=9: Request 3 starts
        current_time = 9
        tracker.incr
        _(tracker.utilization_pct(reset: false)).must_equal 100 # 0 seconds idle out of 1 total second = 0% idle

        # T=10: Request 2 ends
        current_time = 10
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 100 # 0 seconds idle out of 2 total second = 0% idle

        # T=11: Request 3 ends
        current_time = 11
        tracker.decr
        _(tracker.utilization_pct(reset: false)).must_equal 100 # 0 seconds idle out of 3 total second = 0% idle

        # T=12: Report cycle
        current_time = 12
        _(tracker.utilization_pct).must_equal 75 # 1 second idle out of 4 total seconds = 25% idle
      end
    end
  end
end
