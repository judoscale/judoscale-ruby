# frozen_string_literal: true

require "test_helper"
require "judoscale/config"

module Judoscale
  describe Config do
    it "initializes the config from default heroku ENV vars and other sensible defaults" do
      use_env "DYNO" => "web.1", "JUDOSCALE_URL" => "https://example.com" do
        config = Config.instance
        _(config.api_base_url).must_equal "https://example.com"
        _(config.dyno).must_equal "web.1"
        _(config.debug).must_equal false
        _(config.quiet).must_equal false
        _(config.logger).must_equal Rails.logger
        _(config.max_queues).must_equal 50
        _(config.max_request_size).must_equal 100_000
        _(config.report_interval).must_equal 10
        _(config.track_long_running_jobs).must_equal false

        config_must_match_worker_adapters config, [
          WorkerAdapters::DelayedJob,
          WorkerAdapters::Que,
          WorkerAdapters::Resque,
          WorkerAdapters::Sidekiq
        ]
      end
    end

    it "allows ENV vars config overrides for the debug and URL" do
      env = {
        "DYNO" => "web.2",
        "JUDOSCALE_URL" => "https://custom.example.com",
        "JUDOSCALE_DEBUG" => "true"
      }

      use_env env do
        config = Config.instance
        _(config.api_base_url).must_equal "https://custom.example.com"
        _(config.dyno).must_equal "web.2"
        _(config.debug).must_equal true
      end
    end

    it "allows configuring all options via a block" do
      test_logger = ::Logger.new(StringIO.new)

      Judoscale.configure do |config|
        config.dyno = "web.3"
        config.api_base_url = "https://block.example.com"
        config.debug = true
        config.quiet = true
        config.logger = test_logger
        config.track_long_running_jobs = true
        config.max_queues = 100
        config.max_request_size = 50_000
        config.report_interval = 20
        config.worker_adapters = "sidekiq,resque"
      end

      config = Config.instance
      _(config.api_base_url).must_equal "https://block.example.com"
      _(config.dyno).must_equal "web.3"
      _(config.debug).must_equal true
      _(config.quiet).must_equal true
      _(config.logger).must_equal test_logger
      _(config.max_queues).must_equal 100
      _(config.max_request_size).must_equal 50_000
      _(config.report_interval).must_equal 20
      _(config.track_long_running_jobs).must_equal true

      config_must_match_worker_adapters config, [
        WorkerAdapters::Resque,
        WorkerAdapters::Sidekiq
      ]
    end

    private

    def config_must_match_worker_adapters(config, worker_adapter_classes)
      configured_worker_adapters_object_ids = config.worker_adapters.map(&:object_id)
      expected_worker_adapters_object_ids = worker_adapter_classes.map { |w| w.instance.object_id }

      _(configured_worker_adapters_object_ids.sort).must_equal expected_worker_adapters_object_ids.sort
    end
  end
end
