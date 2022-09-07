# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails-autoscale-core"

require "minitest/autorun"
require "minitest/spec"
require "webmock/minitest"

require "rails_autoscale/job_metrics_collector"
require "rails_autoscale/web_metrics_collector"

module RailsAutoscale
  module Test
    class TestJobMetricsCollector < RailsAutoscale::JobMetricsCollector
      def self.adapter_config
        RailsAutoscale::Config.instance.test_job_config
      end

      def collect
        [Metric.new(:qt, 2, Time.now, "test-queue")]
      end
    end

    class TestWebMetricsCollector < RailsAutoscale::WebMetricsCollector
      def collect
        [Metric.new(:qt, 1, Time.now)]
      end
    end
  end

  add_adapter :test_web, {}, metrics_collector: Test::TestWebMetricsCollector
  add_adapter :test_job, {}, metrics_collector: Test::TestJobMetricsCollector,
    expose_config: Config::JobAdapterConfig.new(:test_job_config)
end

Dir[File.expand_path("./support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(RailsAutoscale::Test)
