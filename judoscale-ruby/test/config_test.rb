# frozen_string_literal: true

require "test_helper"
require "judoscale/config"

module Judoscale
  describe Config do
    it "initializes the config from default heroku ENV vars and other sensible defaults" do
      env = {
        "DYNO" => "web.1",
        "JUDOSCALE_URL" => "https://example.com"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://example.com"
        _(config.current_runtime_container).must_equal "web.1"
        _(config.log_level).must_be_nil
        _(config.logger).must_be_instance_of ::Logger
        _(config.max_request_size_bytes).must_equal 100_000
        _(config.report_interval_seconds).must_equal 10

        enabled_adapter_configs = Config.adapter_configs.select(&:enabled).map(&:identifier)
        _(enabled_adapter_configs).must_equal %i[test_job_config]

        enabled_adapter_configs.each do |adapter_name|
          adapter_config = config.public_send(adapter_name)
          _(adapter_config.enabled).must_equal true
          _(adapter_config.max_queues).must_equal 20
          _(adapter_config.track_busy_jobs).must_equal false
        end
      end
    end

    it "initializes the config from default render ENV vars and other sensible defaults" do
      env = {
        "RENDER_SERVICE_ID" => "srv-cfa1es5a49987h4vcvfg",
        "RENDER_INSTANCE_ID" => "srv-cfa1es5a49987h4vcvfg-5497f74465-m5wwr",
        "RENDER_SERVICE_TYPE" => "web"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://adapter.judoscale.com/api/srv-cfa1es5a49987h4vcvfg"
        _(config.current_runtime_container).must_equal "5497f74465-m5wwr"
        _(config.log_level).must_be_nil
        _(config.logger).must_be_instance_of ::Logger
        _(config.max_request_size_bytes).must_equal 100_000
        _(config.report_interval_seconds).must_equal 10

        enabled_adapter_configs = Config.adapter_configs.select(&:enabled).map(&:identifier)
        _(enabled_adapter_configs).must_equal %i[test_job_config]

        enabled_adapter_configs.each do |adapter_name|
          adapter_config = config.public_send(adapter_name)
          _(adapter_config.enabled).must_equal true
          _(adapter_config.max_queues).must_equal 20
          _(adapter_config.track_busy_jobs).must_equal false
        end
      end
    end

    it "initializes the config from default Amazon ECS ENV vars" do
      # Users must set JUDOSCALE_URL manually when using Amazon ECS.
      env = {
        "ECS_CONTAINER_METADATA_URI" => "http://169.254.170.2/v3/a8880ee042bc4db3ba878dce65b769b6-2750272591",
        "JUDOSCALE_URL" => "https://adapter.judoscale.com/api/1234567890"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://adapter.judoscale.com/api/1234567890"
        _(config.current_runtime_container).must_equal "a8880ee042bc4db3ba878dce65b769b6-2750272591"
      end
    end

    it "allows ENV vars config overrides for the debug and URL" do
      env = {
        "DYNO" => "web.2",
        "JUDOSCALE_URL" => "https://custom.example.com",
        "RAILS_AUTOSCALE_LOG_LEVEL" => "debug"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://custom.example.com"
        _(config.current_runtime_container).must_equal "web.2"
        _(config.log_level).must_equal ::Logger::Severity::DEBUG
      end
    end

    it "supports legacy ENV var configs" do
      env = {
        "RAILS_AUTOSCALE_MAX_QUEUES" => "42",
        "RAILS_AUTOSCALE_LONG_JOBS" => "true"
      }

      use_env env do
        config = Config.instance
        _(config.test_job_config.max_queues).must_equal 42
        _(config.test_job_config.track_busy_jobs).must_equal true
      end
    end

    it "allows configuring all options via a block" do
      test_logger = ::Logger.new(StringIO.new)

      Judoscale.configure do |config|
        config.current_runtime_container = Config::RuntimeContainer.new("web.3")

        config.api_base_url = "https://block.example.com"
        config.log_level = :info
        config.logger = test_logger
        config.max_request_size_bytes = 50_000
        config.report_interval_seconds = 20
        config.test_job_config.max_queues = 100
        config.test_job_config.track_busy_jobs = true
        config.test_job_config.enabled = false
      end

      config = Config.instance
      _(config.api_base_url).must_equal "https://block.example.com"
      _(config.current_runtime_container).must_equal "web.3"
      _(config.log_level).must_equal ::Logger::Severity::INFO
      _(config.logger).must_equal test_logger
      _(config.max_request_size_bytes).must_equal 50_000
      _(config.report_interval_seconds).must_equal 20
      _(config.test_job_config.enabled).must_equal false
      _(config.test_job_config.max_queues).must_equal 100
      _(config.test_job_config.track_busy_jobs).must_equal true

      enabled_adapter_configs = Config.adapter_configs.select(&:enabled).map(&:identifier)
      _(enabled_adapter_configs).must_be :empty?
    end

    it "dumps the configuration options as json" do
      _(Config.instance.as_json).must_equal({
        log_level: nil,
        logger: "Logger",
        max_request_size_bytes: 100_000,
        report_interval_seconds: 10,
        test_job_config: {
          max_queues: 20,
          queues: [],
          queue_filter: false,
          track_busy_jobs: false
        }
      })
    end

    it "supports RailsAutoscale env vars" do
      env = {
        "JUDOSCALE_URL" => "https://custom.example.com",
        "JUDOSCALE_LOG_LEVEL" => "debug"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://custom.example.com"
        _(config.log_level).must_equal ::Logger::Severity::DEBUG
      end
    end

    it "support configuring via RailsAutoscale.configure" do
      RailsAutoscale.configure do |config|
        config.report_interval_seconds = 20

        config = Config.instance
        _(config.report_interval_seconds).must_equal 20
      end
    end
  end
end
