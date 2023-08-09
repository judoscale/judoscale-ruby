# frozen_string_literal: true

require "test_helper"
require "rake_mock"
require "minitest/stub_const"
require "judoscale/job_metrics_collector"

module Judoscale
  describe JobMetricsCollector do
    describe ".collect?" do
      it "returns true when not running in a rake task" do
        Object.stub_const :Rake, nil do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal true
        end

        Object.stub_const :Rake, RakeMock.new([]) do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal true
        end
      end

      it "returns false when running in a rake task" do
        Object.stub_const :Rake, RakeMock.new(["foo"]) do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal false
        end
      end

      it "returns true when running in a whitelisted rake task" do
        config = Config.instance
        config.allow_rake_tasks << /foo/

        Object.stub_const :Rake, RakeMock.new(["bar", "foo"]) do
          _(WebMetricsCollector.collect?(config)).must_equal true
        end
      end

      it "collects only from the first container in the formation (if we know that), to avoid redundant collection from multiple containers when possible" do
        %w[
          web.1
          worker.1
          custom_name.1
          5497f74465-m5wwr
          aaacff2165-m5wwr
        ].each do |container_id|
          Judoscale.configure do |config|
            config.current_runtime_container = Config::RuntimeContainer.new(container_id)
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        %w[
          web.2
          worker.8
          custom_name.15
        ].each do |container_id|
          Judoscale.configure do |config|
            config.current_runtime_container = Config::RuntimeContainer.new(container_id)
          end

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end

      it "skips collecting if the adapter has been explicitly disabled" do
        Judoscale.configure { |config|
          config.current_runtime_container = Config::RuntimeContainer.new("web.1")
          config.test_job_config.enabled = true
        }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true

        Judoscale.configure { |config| config.test_job_config.enabled = false }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
      end
    end
  end
end
