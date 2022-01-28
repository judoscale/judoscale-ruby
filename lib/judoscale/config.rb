# frozen_string_literal: true

require "singleton"

module Judoscale
  class Config
    DEFAULT_WORKER_ADAPTERS = "sidekiq,delayed_job,que,resque"

    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
      :dyno, :addon_name, :worker_adapters, :debug, :quiet,
      :track_long_running_jobs, :max_queues

    def initialize
      reset
    end

    def reset
      @worker_adapters = prepare_worker_adapters

      # Allow the add-on name to be configured - needed for testing
      @addon_name = ENV["JUDOSCALE_ADDON"] || "JUDOSCALE"
      @api_base_url = ENV["#{@addon_name}_URL"]
      @debug = ENV["JUDOSCALE_DEBUG"] == "true"
      @track_long_running_jobs = ENV["JUDOSCALE_LONG_JOBS"] == "true"
      @max_queues = ENV.fetch("JUDOSCALE_MAX_QUEUES", 50).to_i
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 10
      @logger = defined?(Rails) ? Rails.logger : ::Logger.new($stdout)
      @dyno = ENV["DYNO"]
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

    def prepare_worker_adapters
      adapter_names = (ENV["JUDOSCALE_WORKER_ADAPTER"] || DEFAULT_WORKER_ADAPTERS).split(",")
      adapter_names.map do |adapter_name|
        require "judoscale/worker_adapters/#{adapter_name}"
        adapter_constant_name = adapter_name.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
        WorkerAdapters.const_get(adapter_constant_name).instance
      end
    end
  end
end
