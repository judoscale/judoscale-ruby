# frozen_string_literal: true

require "test_helper"
require "judoscale/report"

module Judoscale
  describe GoodJob do
    it "adds itself as an adapter with information to be reported to the Rails Autoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-good_job" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::GoodJob::MetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-good_job")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.good_job.enabled).must_equal true
      _(config.good_job.max_queues).must_equal 20
      _(config.good_job.queues).must_equal []
      _(config.good_job.track_busy_jobs).must_equal false

      Judoscale.configure do |config|
        config.good_job.queues = %w[test drive]
        config.good_job.track_busy_jobs = true
      end

      _(config.good_job.queues).must_equal %w[test drive]
      _(config.good_job.track_busy_jobs).must_equal true

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:good_job)
    end
  end
end
