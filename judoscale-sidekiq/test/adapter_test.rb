# frozen_string_literal: true

require "test_helper"
require "judoscale/report"

module Judoscale
  describe Sidekiq do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-sidekiq" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::Sidekiq::MetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-sidekiq")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.sidekiq.enabled).must_equal true
      _(config.sidekiq.max_queues).must_equal 20
      _(config.sidekiq.queues).must_equal []
      _(config.sidekiq.track_busy_jobs).must_equal false

      Judoscale.configure do |config|
        config.sidekiq.queues = %w[test drive]
        config.sidekiq.track_busy_jobs = true
      end

      _(config.sidekiq.queues).must_equal %w[test drive]
      _(config.sidekiq.track_busy_jobs).must_equal true

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:sidekiq)
    end
  end
end
