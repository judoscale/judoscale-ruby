# frozen_string_literal: true

require "test_helper"
require "judoscale/report"

module Judoscale
  describe Shoryuken do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-shoryuken" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::Shoryuken::MetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-shoryuken")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.shoryuken.enabled).must_equal true
      _(config.shoryuken.max_queues).must_equal 20
      _(config.shoryuken.queues).must_equal []
      _(config.shoryuken.track_busy_jobs).must_equal false

      Judoscale.configure do |config|
        config.shoryuken.queues = %w[test drive]
        config.shoryuken.track_busy_jobs = true
      end

      _(config.shoryuken.queues).must_equal %w[test drive]
      _(config.shoryuken.track_busy_jobs).must_equal true

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:shoryuken)
    end
  end
end
