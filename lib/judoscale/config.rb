# frozen_string_literal: true

require "singleton"

module Judoscale
  class Config
    DEFAULT_WORKER_ADAPTERS = "sidekiq,delayed_job,que,resque"

    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
      :dyno, :debug, :quiet, :track_long_running_jobs, :max_queues
    attr_reader :worker_adapters

    def initialize
      reset
    end

    def reset
      self.worker_adapters = DEFAULT_WORKER_ADAPTERS

      # Allow the API URL to be configured - needed for testing.
      @api_base_url = ENV["JUDOSCALE_URL"]
      @dyno = ENV["DYNO"]
      @debug = ENV["JUDOSCALE_DEBUG"] == "true"
      @quiet = false
      @track_long_running_jobs = false
      @max_queues = 50
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 10
      @logger = defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
    end

    def worker_adapters=(adapters_config)
      @worker_adapters = prepare_worker_adapters(adapters_config)
    end

    def to_s
      "#{@dyno}##{Process.pid}"
    end

    def ignore_large_requests?
      @max_request_size
    end

    alias_method :debug?, :debug
    alias_method :quiet?, :quiet

    private

    def prepare_worker_adapters(adapters_config)
      adapter_names = adapters_config.split(",")
      adapter_names.map do |adapter_name|
        require "judoscale/worker_adapters/#{adapter_name}"
        adapter_constant_name = adapter_name.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
        WorkerAdapters.const_get(adapter_constant_name).instance
      end
    end
  end
end
