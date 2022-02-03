# frozen_string_literal: true

require "singleton"

module Judoscale
  class Config
    DEFAULT_WORKER_ADAPTERS = %i[sidekiq delayed_job que resque]

    class WorkerAdapterConfig
      attr_accessor :max_queues

      def initialize(adapter_name)
        @adapter_name = adapter_name
        @max_queues = 50
      end
    end

    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
      :dyno, :debug, :quiet, :track_long_running_jobs, :worker_adapters, *DEFAULT_WORKER_ADAPTERS

    def initialize
      reset
    end

    def reset
      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["JUDOSCALE_URL"]
      @dyno = ENV["DYNO"]
      @debug = ENV["JUDOSCALE_DEBUG"] == "true"
      @quiet = false
      @track_long_running_jobs = false
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
