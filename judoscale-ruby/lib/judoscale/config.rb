# frozen_string_literal: true

require "singleton"
require "logger"

module Judoscale
  class Config
    class RuntimeContainer
      # E.g.:
      # :heroku, "worker_fast", "3"
      # :render, "srv-cfa1es5a49987h4vcvfg", "5497f74465-m5wwr", "web" (or "worker", "pserv", "cron", "static")
      def initialize(platform, service_name, instance, service_type)
        @platform = platform
        @service_name = service_name
        @instance = instance
        @service_type = service_type
      end

      def to_s
        # heroku: 'worker_fast.5'
        # render: 'srv-cfa1es5a49987h4vcvfg.5497f74465-m5wwr'
        "#{@service_name}.#{@instance}"
      end

      def web?
        # NOTE: Heroku isolates 'web' as the required _name_ for its web process
        # type, Render exposes the actual service type more explicitly
        @service_name == "web" || @service_type == "web"
      end

      def first?
        if on_heroku?
          @instance.to_i == 1
        end
      end

      def on_render?
        @platform == :render
      end

      def on_heroku?
        @platform == :heroku
      end
    end

    class JobAdapterConfig
      UUID_REGEXP = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
      DEFAULT_QUEUE_FILTER = ->(queue_name) { !UUID_REGEXP.match?(queue_name) }

      attr_accessor :identifier, :enabled, :max_queues, :queues, :queue_filter, :track_busy_jobs

      def initialize(identifier)
        @identifier = identifier
        reset
      end

      def reset
        @enabled = true
        @queues = []
        @queue_filter = DEFAULT_QUEUE_FILTER

        # Support for deprecated legacy env var configs.
        @max_queues = (ENV["RAILS_AUTOSCALE_MAX_QUEUES"] || 20).to_i
        @track_busy_jobs = ENV["RAILS_AUTOSCALE_LONG_JOBS"] == "true"
      end

      def as_json
        {
          identifier => {
            max_queues: max_queues,
            queues: queues,
            queue_filter: queue_filter != DEFAULT_QUEUE_FILTER,
            track_busy_jobs: track_busy_jobs
          }
        }
      end
    end

    include Singleton

    @adapter_configs = []
    class << self
      attr_reader :adapter_configs
    end

    def self.expose_adapter_config(config_instance)
      adapter_configs << config_instance

      define_method(config_instance.identifier) do
        config_instance
      end
    end

    attr_accessor :api_base_url, :report_interval_seconds, :max_request_size_bytes, :logger, :log_tag
    attr_reader :runtime_container, :log_level

    def initialize
      reset
    end

    def reset
      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["JUDOSCALE_URL"] || ENV["RAILS_AUTOSCALE_URL"]
      @log_tag = "Judoscale"
      @max_request_size_bytes = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval_seconds = 10

      self.log_level = ENV["JUDOSCALE_LOG_LEVEL"] || ENV["RAILS_AUTOSCALE_LOG_LEVEL"]
      @logger = ::Logger.new($stdout)

      self.class.adapter_configs.each(&:reset)

      if ENV["RENDER"] == "true"
        instance = ENV["RENDER_INSTANCE_ID"].delete_prefix(ENV["RENDER_SERVICE_ID"]).delete_prefix("-")
        self.runtime_container = {platform: :render, service_name: ENV["RENDER_SERVICE_ID"], instance: instance, service_type: ENV["RENDER_SERVICE_TYPE"]}
      elsif ENV["HEROKU"] == "true"
        service_name, instance = ENV["DYNO"].split "."
        self.runtime_container = {platform: :heroku, service_name: service_name, instance: instance}
      else
        # unsupported platform? Don't want to leave self.runtime_container nil though
        self.runtime_container = {}
      end
    end

    def runtime_container=(opts)
      @runtime_container = RuntimeContainer.new(opts[:platform], opts[:service_name], opts[:instance], opts[:service_type])
    end

    def log_level=(new_level)
      @log_level = new_level ? ::Logger::Severity.const_get(new_level.to_s.upcase) : nil
    end

    def as_json
      adapter_configs_json = self.class.adapter_configs.reduce({}) { |hash, config| hash.merge!(config.as_json) }

      {
        log_level: log_level,
        logger: logger.class.name,
        report_interval_seconds: report_interval_seconds,
        max_request_size_bytes: max_request_size_bytes
      }.merge!(adapter_configs_json)
    end

    def ignore_large_requests?
      @max_request_size_bytes
    end
  end
end
