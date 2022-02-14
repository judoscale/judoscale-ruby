# frozen_string_literal: true

require "singleton"

module Judoscale
  class Config
    DEFAULT_WORKER_ADAPTERS = %i[sidekiq delayed_job que resque]

    class WorkerAdapterConfig
      UUID_REGEXP = /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/
      DEFAULT_QUEUE_FILTER = ->(queue_name) { !UUID_REGEXP.match?(queue_name) }

      attr_accessor :max_queues, :queues, :queue_filter, :track_busy_jobs

      def initialize(adapter_name)
        @adapter_name = adapter_name
        @max_queues = 20
        @queues = []
        @queue_filter = DEFAULT_QUEUE_FILTER
        @track_busy_jobs = false
      end
    end

    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
      :dyno, :debug, :quiet, :worker_adapters, *DEFAULT_WORKER_ADAPTERS

    def initialize
      reset
    end

    def reset
      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["JUDOSCALE_URL"]
      @dyno = ENV["DYNO"]
      @debug = ENV["JUDOSCALE_DEBUG"] == "true"
      @quiet = false
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 10
      @logger = defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
      @worker_adapters = DEFAULT_WORKER_ADAPTERS

      DEFAULT_WORKER_ADAPTERS.each do |adapter|
        instance_variable_set(:"@#{adapter}", WorkerAdapterConfig.new(adapter))
      end
    end

    def to_s
      "#{@dyno}##{Process.pid}"
    end

    def ignore_large_requests?
      @max_request_size
    end

    alias_method :debug?, :debug
    alias_method :quiet?, :quiet
  end
end
