# frozen_string_literal: true

require 'singleton'

module RailsAutoscaleAgent
  class Config
    DEFAULT_WORKER_ADAPTERS = 'sidekiq,delayed_job,que,resque'

    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
                  :dyno, :addon_name, :worker_adapters, :dev_mode, :debug, :quiet,
                  :track_long_running_jobs, :max_queues,

                  # legacy configs, no longer used
                  :sidekiq_latency_for_active_jobs, :latency_for_active_jobs

    def initialize
      @worker_adapters = prepare_worker_adapters

      # Allow the add-on name to be configured - needed for testing
      @addon_name = ENV['RAILS_AUTOSCALE_ADDON'] || 'RAILS_AUTOSCALE'
      @api_base_url = ENV["#{@addon_name}_URL"]
      @dev_mode = ENV['RAILS_AUTOSCALE_DEV'] == 'true'
      @debug = dev_mode? || ENV['RAILS_AUTOSCALE_DEBUG'] == 'true'
      @track_long_running_jobs = ENV['RAILS_AUTOSCALE_LONG_JOBS'] == 'true'
      @max_queues = ENV.fetch('RAILS_AUTOSCALE_MAX_QUEUES', 50).to_i
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 10 # this default will be overwritten during Reporter#register!
      @logger ||= defined?(Rails) ? Rails.logger : ::Logger.new(STDOUT)
      @dyno = dev_mode? ? 'dev.1' : ENV['DYNO']
    end

    def to_s
      "#{@dyno}##{Process.pid}"
    end

    def ignore_large_requests?
      @max_request_size
    end

    alias_method :dev_mode?, :dev_mode
    alias_method :debug?, :debug
    alias_method :quiet?, :quiet

    private

    def prepare_worker_adapters
      adapter_names = (ENV['RAILS_AUTOSCALE_WORKER_ADAPTER'] || DEFAULT_WORKER_ADAPTERS).split(',')
      adapter_names.map do |adapter_name|
        require "rails_autoscale_agent/worker_adapters/#{adapter_name}"
        adapter_constant_name = adapter_name.capitalize.gsub(/(?:_)(.)/i) { $1.upcase }
        WorkerAdapters.const_get(adapter_constant_name).instance
      end
    end
  end
end
