# frozen_string_literal: true

require "test_helper"
require "judoscale/rails/utilization_middleware"

module Judoscale
  module TrackerTest
    def tracker
      Rails::UtilizationTracker.instance
    end

    def tracker_thread
      tracker.instance_variable_get(:@thread_ref).get
    end

    def tracker_request_counter
      tracker.instance_variable_get(:@active_request_counter)
    end

    def stub_tracker_loop
      tracker.stub(:loop, ->(&blk) { blk.call }) {
        tracker.stub(:sleep, true) {
          yield
        }
      }
    end

    def tracker_count
      tracker_request_counter.value
    end

    def reset_tracker_state
      # Reset all singleton state to ensure clean test isolation
      tracker.instance_variable_set(:@report_cycle_started_at, nil)
      tracker.instance_variable_set(:@idle_started_at, nil)
      tracker.instance_variable_set(:@total_idle_time, 0.0)
      tracker_thread&.terminate
      tracker_request_counter.value = 0
    end
  end

  class MockApp
    include TrackerTest

    attr_reader :env

    def call(env)
      @env = env
      @env["judoscale.test.tracker_count"] = tracker_count
      self
    end
  end

  describe Judoscale::Rails::UtilizationMiddleware do
    include TrackerTest

    after {
      MetricsStore.instance.clear
      reset_tracker_state
    }

    let(:app) { MockApp.new }
    let(:env) { {} }
    let(:middleware) { Rails::UtilizationMiddleware.new(app, interval: 1) }

    it "passes the request env up the middleware stack, returning the app's response" do
      response = middleware.call(env)

      _(response).must_equal app
      _(app.env).must_equal env
    end

    it "starts the utilization tracker and counts active requests" do
      stub_tracker_loop do
        middleware.call(env)
      end

      _(tracker_thread).must_be_instance_of Thread
      _(tracker_count).must_equal 0
      _(env["judoscale.test.tracker_count"]).must_equal 1

      # Simulate 2 calls to the middleware as if there were 2 requests being handled simultaneously.
      stub_tracker_loop do
        other_app = ->(env) { middleware.call(env) }

        other_middleware = Rails::UtilizationMiddleware.new(other_app, interval: 1)
        other_middleware.call(env)
      end

      _(tracker_thread).must_be_instance_of Thread
      _(tracker_count).must_equal 0
      _(env["judoscale.test.tracker_count"]).must_equal 2
    end
  end

  describe Judoscale::Rails::UtilizationTracker do
    include TrackerTest

    after {
      MetricsStore.instance.clear
      reset_tracker_state
    }

    it "tracks utilization metrics for active requests" do
      tracker.track_current_state

      metrics = MetricsStore.instance.flush
      _(metrics.map(&:identifier)).must_equal %i[pu ru]
      _(metrics.map(&:value)).must_equal [0, 0]

      3.times { tracker.incr }
      tracker.track_current_state

      metrics = MetricsStore.instance.flush
      _(metrics.map(&:identifier)).must_equal %i[pu ru]
      _(metrics.map(&:value)).must_equal [1, 3]

      tracker.decr
      tracker.track_current_state

      metrics = MetricsStore.instance.flush
      _(metrics.map(&:identifier)).must_equal %i[pu ru]
      _(metrics.map(&:value)).must_equal [1, 2]
    end

    it "tracks idle ratio based on time spent with no active requests" do
      # T=0:   Start tracker
      # T=1:   Request 1 starts -> total_idle_time=1
      # T=2:   Request 1 ends   -> total_idle_time=1
      # T=4:   Request 2 starts -> total_idle_time=3 (1 + 2)
      # T=5:   Request 3 starts -> total_idle_time=3
      # T=6:   Request 2 ends   -> total_idle_time=3
      # T=8:   Request 3 ends   -> total_idle_time=3
      # T=10:  Report cycle     -> total_idle_time=5 (3 + 2), idle_ratio=5/10=0.5

      current_time = 0

      # Stub Process.clock_gettime to return our controlled monotonic time
      Process.stub(:clock_gettime, ->(_) { current_time }) do
        # T=0: Tracker starts
        tracker.start!
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # No time has passed yet

        # T=1: Request 1 starts
        current_time = 1
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 1.0 # 1 second idle out of 1 total second = 100% idle

        # T=2: Request 1 ends
        current_time = 2
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.5 # 1 second idle out of 2 total seconds = 50% idle

        # T=4: Request 2 starts
        current_time = 4
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 0.75 # 3 seconds idle out of 4 total seconds = 75% idle

        # T=5: Request 3 starts
        current_time = 5
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 0.6 # 3 seconds idle out of 5 total seconds = 60% idle

        # T=6: Request 2 ends
        current_time = 6
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.5 # 3 seconds idle out of 6 total seconds = 50% idle

        # T=8: Request 3 ends
        current_time = 8
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.375 # 3 seconds idle out of 8 total seconds = 37.5% idle

        # T=10: Report cycle - should calculate final idle ratio
        current_time = 10
        _(tracker.idle_ratio).must_equal 0.5 # 5 seconds idle out of 10 total seconds = 50% idle
      end
    end

    it "resets the tracking cycle when idle_ratio is requested with no args" do
      # T=0:   Start tracker
      # T=1:   Request 1 starts -> total_idle_time=1
      # T=2:   Request 1 ends   -> total_idle_time=1
      # T=4:   Report cycle     -> total_idle_time=3 (1 + 2), idle_ratio=3/4=0.75
      # T=5:   Request 2 starts -> total_idle_time=1
      # T=8:   Report cycle     -> total_idle_time=1 (request still running), idle_ratio=1/4=0.25
      # T=9:   Request 3 starts -> total_idle_time=0
      # T=10:  Request 2 ends   -> total_idle_time=0
      # T=11:  Request 3 ends   -> total_idle_time=0
      # T=12:  Report cycle     -> total_idle_time=1, idle_ratio=1/4=0.25

      current_time = 0

      # Stub Process.clock_gettime to return our controlled monotonic time
      Process.stub(:clock_gettime, ->(_) { current_time }) do
        # T=0: Tracker starts
        tracker.start!
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # No time has passed yet

        # T=1: Request 1 starts
        current_time = 1
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 1.0 # 1 second idle out of 1 total second = 100% idle

        # T=2: Request 1 ends
        current_time = 2
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.5 # 1 second idle out of 2 total seconds = 50% idle

        current_time = 3
        _(tracker.idle_ratio(reset: false)).must_be_close_to 0.6666, 0.001 # 2 seconds idle out of 3 total seconds = 66.66% idle

        # T=4: Report cycle
        current_time = 4
        _(tracker.idle_ratio).must_equal 0.75 # 3 seconds idle out of 4 total seconds = 75% idle

        # T=5: Request 2 starts
        current_time = 5
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 1.0 # 1 second idle out of 1 total second = 100% idle

        # T=8: Report cycle
        current_time = 8
        _(tracker.idle_ratio).must_equal 0.25 # 1 second idle out of 4 total seconds = 25% idle

        # T=9: Request 3 starts
        current_time = 9
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # 0 seconds idle out of 1 total second = 0% idle

        # T=10: Request 2 ends
        current_time = 10
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # 0 seconds idle out of 2 total second = 0% idle

        # T=11: Request 3 ends
        current_time = 11
        tracker.decr
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # 0 seconds idle out of 3 total second = 0% idle

        # T=12: Report cycle
        current_time = 12
        _(tracker.idle_ratio).must_equal 0.25 # 1 second idle out of 4 total seconds = 25% idle
      end
    end

    it "gracefully handles calling start! multiple times" do
      current_time = 0

      # Stub Process.clock_gettime to return our controlled monotonic time
      Process.stub(:clock_gettime, ->(_) { current_time }) do
        # T=0: Tracker starts
        tracker.start!
        _(tracker.idle_ratio(reset: false)).must_equal 0.0 # No time has passed yet

        # T=1: Request 1 starts
        current_time = 1
        tracker.start!
        tracker.incr
        _(tracker.idle_ratio(reset: false)).must_equal 1.0 # 1 second idle out of 1 total second = 100% idle
      end
    end
  end
end
