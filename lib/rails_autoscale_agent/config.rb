# frozen_string_literal: true

require 'singleton'

module RailsAutoscaleAgent
  class Config
    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
                  :dyno, :addon_name, :worker_adapters, :dev_mode, :debug, :quiet

    def initialize
      require 'rails_autoscale_agent/worker_adapters/sidekiq'
      require 'rails_autoscale_agent/worker_adapters/delayed_job'
      require 'rails_autoscale_agent/worker_adapters/que'
      require 'rails_autoscale_agent/worker_adapters/resque'
      @worker_adapters = [
        WorkerAdapters::Sidekiq.instance,
        WorkerAdapters::DelayedJob.instance,
        WorkerAdapters::Que.instance,
        WorkerAdapters::Resque.instance,
      ]

      # Allow the add-on name to be configured - needed for testing
      @addon_name = ENV['RAILS_AUTOSCALE_ADDON'] || 'RAILS_AUTOSCALE'
      @api_base_url = ENV["#{@addon_name}_URL"]
      @dev_mode = ENV['RAILS_AUTOSCALE_DEV'] == 'true'
      @debug = dev_mode? || ENV['RAILS_AUTOSCALE_DEBUG'] == 'true'
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
  end
end
