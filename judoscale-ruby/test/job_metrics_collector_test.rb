# frozen_string_literal: true

require "test_helper"
require "judoscale/job_metrics_collector"

module Judoscale
  describe JobMetricsCollector do
    describe ".collect?" do
      it "collects only from the first container in the formation (if we know that), to avoid redundant collection from multiple containers when possible" do
        [
          [:heroku, "web", "1"],
          [:heroku, "worker", "1"],
          [:heroku, "custom_name", "1"],
          [:render, "srv-cfa1es5a49987h4vcvfg", "5497f74465-m5wwr", "web"],
          [:render, "srv-cfa1es5a49987h4vcvfg", "aaacff2165-m5wwr", "worker"]
        ].each do |args|
          Judoscale.configure do |config|
            config.runtime_container = Config::RuntimeContainer.new(*args)
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        [
          [:heroku, "web", "2"],
          [:heroku, "worker", "8"],
          [:heroku, "custom_name", "15"]
        ].each do |args|
          Judoscale.configure do |config|
            config.runtime_container = Config::RuntimeContainer.new(*args)
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end

      it "skips collecting if the adapter has been explicitly disabled" do
        Judoscale.configure { |config|
          config.runtime_container = Config::RuntimeContainer.new(:heroku, "web", "1")
          config.test_job_config.enabled = true
        }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true

        Judoscale.configure { |config| config.test_job_config.enabled = false }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
      end
    end
  end
end
