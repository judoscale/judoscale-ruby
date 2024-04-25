# frozen_string_literal: true

require "test_helper"
require "judoscale/report"

module Judoscale
  describe SolidQueue do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-solid_queue" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::SolidQueue::MetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-solid_queue")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.solid_queue.enabled).must_equal true
      _(config.solid_queue.max_queues).must_equal 20
      _(config.solid_queue.queues).must_equal []
      _(config.solid_queue.track_busy_jobs).must_equal false

      Judoscale.configure do |config|
        config.solid_queue.queues = %w[test drive]
        config.solid_queue.track_busy_jobs = true
      end

      _(config.solid_queue.queues).must_equal %w[test drive]
      _(config.solid_queue.track_busy_jobs).must_equal true

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:solid_queue)
    end
  end
end
