# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/report"

module RailsAutoscale
  describe Resque do
    it "adds itself as an adapter with information to be reported to the Rails Autoscale API" do
      adapter = RailsAutoscale.adapters.detect { |adapter| adapter.identifier == :"rails-autoscale-resque" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal RailsAutoscale::Resque::MetricsCollector

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"rails-autoscale-resque")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.resque.enabled).must_equal true
      _(config.resque.max_queues).must_equal 20
      _(config.resque.queues).must_equal []
      _(config.resque.track_busy_jobs).must_equal false

      RailsAutoscale.configure do |config|
        config.resque.queues = %w[test drive]
        config.resque.track_busy_jobs = true
      end

      _(config.resque.queues).must_equal %w[test drive]
      _(config.resque.track_busy_jobs).must_equal true

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:resque)
    end
  end
end
