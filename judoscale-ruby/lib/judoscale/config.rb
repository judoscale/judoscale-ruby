# frozen_string_literal: true

require "singleton"
require "logger"

module Judoscale
  class Config
    class RuntimeContainer < String
      # Since Heroku exposes ordinal dyno 'numbers', we can tell if the current
      # instance is redundant (and thus skip collecting some metrics sometimes)
      # We don't have a means of determining that on Render though — so every
      # instance must be considered non-redundant
      def redundant_instance?
        instance_number = split(".")[1].to_i
        instance_number > 1
      end
    end

    class JobAdapterConfig
      UUID_REGEXP = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
      DEFAULT_QUEUE_FILTER = ->(queue_name) { !UUID_REGEXP.match?(queue_name) }

      attr_accessor :identifier, :enabled, :max_queues, :queues, :queue_filter
      attr_reader :track_busy_jobs

      def initialize(identifier, support_busy_jobs: true)
        @identifier = identifier
        @support_busy_jobs = support_busy_jobs
        reset
      end

      def reset
        @enabled = true
        @queues = []
        @queue_filter = DEFAULT_QUEUE_FILTER

        # Support for deprecated legacy env var configs.
        @max_queues = (ENV["JUDOSCALE_MAX_QUEUES"] || ENV["RAILS_AUTOSCALE_MAX_QUEUES"] || 20).to_i
        self.track_busy_jobs = (ENV["JUDOSCALE_LONG_JOBS"] || ENV["RAILS_AUTOSCALE_LONG_JOBS"]) == "true"
      end

      def track_busy_jobs=(value)
        if value && !@support_busy_jobs
          raise "[#{Config.instance.log_tag}] #{identifier} does not support busy jobs"
        end

        @track_busy_jobs = value
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

    attr_accessor :api_base_url, :report_interval_seconds,
      :max_request_size_bytes, :logger, :log_tag, :current_runtime_container
    attr_reader :log_level

    def initialize
      reset
    end

    def reset
      @api_base_url = ENV["JUDOSCALE_URL"] || ENV["RAILS_AUTOSCALE_URL"]
      @log_tag = "Judoscale"
      @max_request_size_bytes = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval_seconds = 10

      self.log_level = ENV["JUDOSCALE_LOG_LEVEL"] || ENV["RAILS_AUTOSCALE_LOG_LEVEL"]
      @logger = ::Logger.new($stdout)

      self.class.adapter_configs.each(&:reset)

      @current_runtime_container =
        if ENV.include?("DYNO")
          RuntimeContainer.new ENV["DYNO"]
        elsif ENV.include?("RENDER_INSTANCE_ID")
          # Deprecated API url using the service ID for legacy render services not using `JUDOSCALE_URL`.
          @api_base_url ||= "https://adapter.judoscale.com/api/#{ENV["RENDER_SERVICE_ID"]}"

          instance = ENV["RENDER_INSTANCE_ID"].delete_prefix("#{ENV["RENDER_SERVICE_ID"]}-")
          RuntimeContainer.new instance
        elsif ENV.include?("ECS_CONTAINER_METADATA_URI")
          instance = ENV["ECS_CONTAINER_METADATA_URI"].split("/").last
          RuntimeContainer.new instance
        elsif ENV.include?("FLY_MACHINE_ID")
          RuntimeContainer.new ENV["FLY_MACHINE_ID"]
        elsif ENV.include?("RAILWAY_REPLICA_ID")
          RuntimeContainer.new ENV["RAILWAY_REPLICA_ID"]
        else
          # Unsupported platform...
          RuntimeContainer.new("")
        end
    end

    def log_level=(new_level)
      @log_level = get_severity_log_level(new_level)
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

    private

    def get_severity_log_level(log_level)
      return nil if log_level.to_s.strip.empty?

      upcased_log_level = log_level.to_s.upcase

      if ::Logger::Severity.const_defined?(upcased_log_level)
        ::Logger::Severity.const_get(upcased_log_level)
      else
        logger.warn "Invalid log_level detected: #{log_level}"

        nil
      end
    end
  end
end
