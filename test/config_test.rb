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
        _(config.max_request_size).must_equal 100_000
        _(config.report_interval).must_equal 10
        _(config.worker_adapters).must_equal %i[sidekiq delayed_job que resque]

        config.worker_adapters.each do |adapter_name|
          adapter_config = config.public_send(adapter_name)
          _(adapter_config.max_queues).must_equal 50
          _(adapter_config.track_long_running_jobs).must_equal false
        end
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
        config.max_request_size = 50_000
        config.report_interval = 20
        config.worker_adapters = [:sidekiq, :resque]
        config.sidekiq.max_queues = 100
        config.sidekiq.track_long_running_jobs = true
      end

      config = Config.instance
      _(config.api_base_url).must_equal "https://block.example.com"
      _(config.dyno).must_equal "web.3"
      _(config.debug).must_equal true
      _(config.quiet).must_equal true
      _(config.logger).must_equal test_logger
      _(config.max_request_size).must_equal 50_000
      _(config.report_interval).must_equal 20
      _(config.worker_adapters).must_equal %i[sidekiq resque]
      _(config.resque.max_queues).must_equal 50
      _(config.resque.track_long_running_jobs).must_equal false
      _(config.sidekiq.max_queues).must_equal 100
      _(config.sidekiq.track_long_running_jobs).must_equal true
    end
  end
end
