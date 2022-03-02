# frozen_string_literal: true

require "singleton"
require "judoscale/logger"
require "judoscale/adapter_api"
require "judoscale/registration"
require "judoscale/job_metrics_collector"
require "judoscale/web_metrics_collector"
require "judoscale/worker_adapters"

module Judoscale
  class Reporter
    include Singleton
    include Logger

    def self.start(config)
      unless instance.started?
        adapters = Judoscale.adapters
        metrics_collectors = adapters.map(&:metrics_collector)
        metrics_collectors.compact!
        metrics_collectors.select! { |ac| ac.collect?(config) }
        metrics_collectors.map!(&:new)

        instance.start!(config, metrics_collectors)
      end
    end

    def start!(config, metrics_collectors)
      @started = true

      if !config.api_base_url
        logger.info "Reporter not started: JUDOSCALE_URL is not set"
        return
      end

      @_thread = Thread.new do
        loop do
          register!(config) unless registered?

          # Stagger reporting to spread out reports from many processes
          multiplier = 1 - (rand / 4) # between 0.75 and 1.0
          sleep config.report_interval_seconds * multiplier

          metrics = metrics_collectors.flat_map do |metric_collector|
            log_exceptions { metric_collector.collect }
          end

          log_exceptions { report!(config, metrics) }
        end
      end
    end

    def registered?
      @registered
    end

    def started?
      @started
    end

    def stop!
      @_thread&.terminate
      @_thread = nil
      @registered = false
      @started = false
    end

    private

    def report!(config, metrics)
      report = Report.new(config, metrics)
      logger.info "Reporting #{report.metrics.size} metrics"
      result = AdapterApi.new(config).report_metrics!(report.as_json)

      case result
      when AdapterApi::SuccessResponse
        logger.debug "Reported successfully"
      when AdapterApi::FailureResponse
        logger.error "Reporter failed: #{result.failure_message}"
      end
    end

    def register!(config)
      adapters = Judoscale.adapters
      registration = Registration.new(adapters, config)
      result = AdapterApi.new(config).register_reporter!(registration.as_json)

      case result
      when AdapterApi::SuccessResponse
        @registered = true
        adapters_msg = adapters.map(&:identifier).join(", ")
        logger.info "Reporter starting, will report every #{config.report_interval_seconds} seconds or so. Adapters: [#{adapters_msg}]"
      when AdapterApi::FailureResponse
        logger.error "Reporter failed to register: #{result.failure_message}"
      end
    end

    def log_exceptions
      yield
    rescue => ex
      # Log the exception but swallow it to keep the thread running and processing reports.
      # Note: Exceptions in threads other than the main thread will fail silently and terminate it.
      # https://ruby-doc.org/core-3.1.0/Thread.html#class-Thread-label-Exception+handling
      logger.error "Reporter error: #{ex.inspect}", *ex.backtrace
    end
  end
end
