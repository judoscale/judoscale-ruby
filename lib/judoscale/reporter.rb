# frozen_string_literal: true

require "singleton"
require "judoscale/logger"
require "judoscale/autoscale_api"
require "judoscale/registration"

module Judoscale
  class Reporter
    include Singleton
    include Logger

    def self.start(config, store)
      instance.start!(config, store) unless instance.started?
    end

    def start!(config, store)
      @started = true
      worker_adapters = config.worker_adapters.select(&:enabled?)
      dyno_num = config.dyno.to_s.split(".").last.to_i

      if !config.api_base_url
        logger.info "Reporter not started: #{config.addon_name}_URL is not set"
        return
      end

      @_thread = Thread.new do
        loop do
          register!(config, worker_adapters) unless registered?

          # Stagger reporting to spread out reports from many processes
          multiplier = 1 - (rand / 4) # between 0.75 and 1.0
          sleep config.report_interval * multiplier

          # It's redundant to report worker metrics from every web dyno, so only report from web.1
          if dyno_num == 1
            worker_adapters.map do |adapter|
              log_exceptions { adapter.collect!(store) }
            end
          end

          log_exceptions { report!(config, store) }
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

    def report!(config, store)
      report = store.pop_report

      logger.info "Reporting #{report.measurements.size} measurements"

      params = report.to_params(config)
      result = AutoscaleApi.new(config).report_metrics!(params, report.to_csv)

      case result
      when AutoscaleApi::SuccessResponse
        logger.debug "Reported successfully"
      when AutoscaleApi::FailureResponse
        logger.error "Reporter failed: #{result.failure_message}"
      end
    end

    def register!(config, worker_adapters)
      params = Registration.new(worker_adapters).to_params
      result = AutoscaleApi.new(config).register_reporter!(params)

      case result
      when AutoscaleApi::SuccessResponse
        @registered = true
        worker_adapters_msg = worker_adapters.map { |a| a.class.name }.join(", ")
        logger.info "Reporter starting, will report every #{config.report_interval} seconds or so. Worker adapters: [#{worker_adapters_msg}]"
      when AutoscaleApi::FailureResponse
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
