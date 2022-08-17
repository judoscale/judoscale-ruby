# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/report"

module RailsAutoscale
  describe Sidekiq do
    it "adds itself as an adapter with information to be reported to the Rails Autoscale API" do
      adapter = RailsAutoscale.adapters.detect { |adapter| adapter.identifier == :"rails-autoscale-sidekiq" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal RailsAutoscale::Sidekiq::MetricsCollector

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"rails-autoscale-sidekiq")
    end

    it "sets up a config property for the library" do
      config = Config.instance
      _(config.sidekiq.enabled).must_equal true
      _(config.sidekiq.max_queues).must_equal 20
      _(config.sidekiq.queues).must_equal []
      _(config.sidekiq.track_busy_jobs).must_equal false

      RailsAutoscale.configure do |config|
        config.sidekiq.queues = %w[test drive]
        config.sidekiq.track_busy_jobs = true
      end

      _(config.sidekiq.queues).must_equal %w[test drive]
      _(config.sidekiq.track_busy_jobs).must_equal true

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:config]).must_include(:sidekiq)
    end
  end
end
