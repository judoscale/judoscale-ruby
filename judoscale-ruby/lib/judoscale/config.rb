# frozen_string_literal: true

require "singleton"
require "logger"
require "judoscale/platform"

module Judoscale
  class Config
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

    def self.coerce_log_level(level)
      if level.is_a?(Integer)
        level
      else
        upcased_level = level.to_s.upcase

        if ::Logger::Severity.const_defined?(upcased_level)
          ::Logger::Severity.const_get(upcased_level)
        else
          raise ArgumentError, "invalid log level: #{level}"
        end
      end
    end

    attr_accessor :api_base_url, :report_interval_seconds,
      :max_request_size_bytes, :logger, :log_tag, :current_platform
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

      @current_platform = Platform.detect(ENV)
      # Legacy Render services not using JUDOSCALE_URL derive the API url from the platform.
      @api_base_url ||= @current_platform.default_api_base_url
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

      self.class.coerce_log_level(log_level)
    rescue ArgumentError
      logger.warn "Invalid log_level detected: #{log_level}"
      nil
    end
  end
end
