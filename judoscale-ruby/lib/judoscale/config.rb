# frozen_string_literal: true

require "singleton"
require "logger"

module Judoscale
  class Config
    DEFAULT_WORKER_ADAPTERS = %i[delayed_job que resque]

    class WorkerAdapterConfig
      UUID_REGEXP = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
      DEFAULT_QUEUE_FILTER = ->(queue_name) { !UUID_REGEXP.match?(queue_name) }

      attr_accessor :enabled, :max_queues, :queues, :queue_filter, :track_busy_jobs

      def initialize(adapter_identifier)
        @adapter_identifier = adapter_identifier
        @enabled = true
        @max_queues = 20
        @queues = []
        @queue_filter = DEFAULT_QUEUE_FILTER
        @track_busy_jobs = false
      end

      def as_json
        {
          max_queues: max_queues,
          queues: queues,
          queue_filter: queue_filter != DEFAULT_QUEUE_FILTER,
          track_busy_jobs: track_busy_jobs
        }
      end
    end

    include Singleton

    attr_accessor :api_base_url, :dyno, :report_interval_seconds, :max_request_size_bytes,
      :logger, *DEFAULT_WORKER_ADAPTERS
    attr_reader :log_level

    def initialize
      reset
    end

    def reset
      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["JUDOSCALE_URL"]
      @dyno = ENV["DYNO"]
      @max_request_size_bytes = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval_seconds = 10
      self.log_level = ENV["JUDOSCALE_LOG_LEVEL"]
      @logger = ::Logger.new($stdout)

      DEFAULT_WORKER_ADAPTERS.each do |adapter|
        instance_variable_set(:"@#{adapter}", WorkerAdapterConfig.new(adapter))
      end
    end

    def log_level=(new_level)
      @log_level = new_level ? ::Logger::Severity.const_get(new_level.to_s.upcase) : nil
    end

    def as_json
      adapters_json = worker_adapters.each_with_object({}) do |adapter, hash|
        hash[adapter] = instance_variable_get(:"@#{adapter}").as_json
      end

      {
        log_level: log_level,
        logger: logger.class.name,
        report_interval_seconds: report_interval_seconds,
        max_request_size_bytes: max_request_size_bytes
      }.merge!(adapters_json)
    end

    def to_s
      "#{@dyno}##{Process.pid}"
    end

    def dyno_num
      dyno.to_s.split(".").last.to_i
    end

    def ignore_large_requests?
      @max_request_size_bytes
    end

    def worker_adapters
      DEFAULT_WORKER_ADAPTERS.select { |adapter|
        instance_variable_get(:"@#{adapter}").enabled
      }
    end
  end
end
