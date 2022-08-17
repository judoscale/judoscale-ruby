# frozen_string_literal: true

require "singleton"
require "logger"

module RailsAutoscale
  class Config
    class Dyno
      attr_reader :name, :num

      def initialize(dyno_string)
        @name, @num = dyno_string.to_s.split(".")
        @num = @num.to_i
      end

      def to_s
        "#{name}.#{num}"
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
        @max_queues = 20
        @queues = []
        @queue_filter = DEFAULT_QUEUE_FILTER
        @track_busy_jobs = false
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

    attr_accessor :api_base_url, :report_interval_seconds, :max_request_size_bytes, :logger
    attr_reader :dyno, :log_level

    def initialize
      reset
    end

    def reset
      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["RAILS_AUTOSCALE_URL"]
      self.dyno = ENV["DYNO"]
      @max_request_size_bytes = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval_seconds = 10
      self.log_level = ENV["RAILS_AUTOSCALE_LOG_LEVEL"]
      @logger = ::Logger.new($stdout)

      self.class.adapter_configs.each(&:reset)
    end

    def dyno=(dyno_string)
      @dyno = Dyno.new(dyno_string)
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

    def to_s
      "#{@dyno}##{Process.pid}"
    end

    def ignore_large_requests?
      @max_request_size_bytes
    end
  end
end
