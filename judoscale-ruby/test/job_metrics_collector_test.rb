# frozen_string_literal: true

require "test_helper"
require "minitest/stub_const"
require "judoscale/job_metrics_collector"

module Judoscale
  describe JobMetricsCollector do
    describe ".collect?" do
      it "collects only from the first container in the formation (if we know that), to avoid redundant collection from multiple containers when possible" do
        [
          Platform::Heroku.new("web.1"),
          Platform::Heroku.new("worker.1"),
          Platform::Heroku.new("custom_name.1"),
          Platform::Scalingo.new("web-1"),
          Platform::Scalingo.new("worker-1"),
          Platform::Scalingo.new("tcp-1"),
          # Opaque-id platforms can't identify an ordinal, so they always collect.
          Platform::Render.new("5497f74465-m5wwr", service_id: "srv-x"),
          Platform::Ecs.new("aaacff2165-m5wwr")
        ].each do |platform|
          Judoscale.configure do |config|
            config.current_platform = platform
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        [
          Platform::Heroku.new("web.2"),
          Platform::Heroku.new("worker.8"),
          Platform::Heroku.new("custom_name.15"),
          Platform::Scalingo.new("web-2"),
          Platform::Scalingo.new("worker-8"),
          Platform::Scalingo.new("tcp-2")
        ].each do |platform|
          Judoscale.configure do |config|
            config.current_platform = platform
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end

      it "skips collecting if the adapter has been explicitly disabled" do
        Judoscale.configure { |config|
          config.current_platform = Platform::Heroku.new("web.1")
          config.test_job_config.enabled = true
        }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true

        Judoscale.configure { |config| config.test_job_config.enabled = false }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
      end
    end
  end
end
