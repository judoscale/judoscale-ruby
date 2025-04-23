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

    def stop_tracker_thread
      tracker_thread&.terminate
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

    def reset_tracker_count
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
      stop_tracker_thread
      reset_tracker_count
      MetricsStore.instance.clear
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
      reset_tracker_count
      MetricsStore.instance.clear
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
  end
end
