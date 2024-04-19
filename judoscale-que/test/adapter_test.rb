# frozen_string_literal: true

require "test_helper"
require "judoscale/report"

module Judoscale
  describe Que do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-que" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::Que::MetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-que")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.que.enabled).must_equal true
      _(config.que.max_queues).must_equal 20
      _(config.que.queues).must_equal []
      _(config.que.track_busy_jobs).must_equal false

      Judoscale.configure do |config|
        config.que.queues = %w[test drive]
        config.que.track_busy_jobs = true
      end

      _(config.que.queues).must_equal %w[test drive]
      _(config.que.track_busy_jobs).must_equal true

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:que)
    end
  end
end
