# frozen_string_literal: true

require "singleton"
require "judoscale/config"
require "judoscale/logger"
require "judoscale/adapter_api"
require "judoscale/job_metrics_collector"
require "judoscale/web_metrics_collector"

module Judoscale
  class Reporter
    include Singleton
    include Logger

    def self.start(config = Config.instance, adapters = Judoscale.adapters)
      instance.start!(config, adapters) unless instance.started?
    end

    def start!(config, adapters)
      @pid = Process.pid

      if config.api_base_url.nil? || config.api_base_url.strip.empty?
        logger.debug "Set api_base_url to enable metrics reporting"
        return
      end

      enabled_adapters, skipped_adapters = adapters.partition { |adapter|
        if adapter.metrics_collector&.collect?(config)
          adapter.enabled = true
        end
      }
      metrics_collectors_classes = enabled_adapters.map(&:metrics_collector)
      adapters_msg = enabled_adapters.map(&:identifier).concat(
        skipped_adapters.map { |adapter| "#{adapter.identifier}[skipped]" }
      ).join(", ")

      if metrics_collectors_classes.empty?
        logger.debug "No metrics need to be collected (adapters: #{adapters_msg})"
        return
      end

      logger.info "Reporter starting, will report every ~#{config.report_interval_seconds} seconds (adapters: #{adapters_msg})"

      metrics_collectors = metrics_collectors_classes.map(&:new)

      run_loop(config, metrics_collectors)
    end

    def run_loop(config, metrics_collectors)
      @_thread = Thread.new do
        loop do
          run_metrics_collection(config, metrics_collectors)

          # Stagger reporting to spread out reports from many processes
          multiplier = 1 - (rand / 4) # between 0.75 and 1.0
          sleep config.report_interval_seconds * multiplier
        end
      end
    end

    def run_metrics_collection(config, metrics_collectors)
      metrics = metrics_collectors.flat_map do |metric_collector|
        log_exceptions { metric_collector.collect } || []
      end

      log_exceptions { report(config, metrics) }
    end

    def started?
      @pid == Process.pid
    end

    def stop!
      @_thread&.terminate
      @_thread = nil
      @pid = nil
      @reported = false
    end

    private

    def report(config, metrics)
      # Make sure we report at least once, even if there are no metrics,
      # so Judoscale knows the adapter is installed and running.
      if @reported && metrics.empty?
        logger.debug "No metrics to report - skipping"
        return
      end

      report = Report.new(Judoscale.adapters, config, metrics)
      logger.info "Reporting #{report.metrics.size} metrics"
      result = AdapterApi.new(config).report_metrics(report.as_json)

      case result
      when AdapterApi::SuccessResponse
        @reported = true
        logger.debug "Reported successfully"
      when AdapterApi::FailureResponse
        logger.error "Reporter failed: #{result.failure_message}"
      end
    end

    def log_exceptions
      yield
    rescue => ex
      # Log the exception but swallow it to keep the thread running and processing reports.
      # Note: Exceptions in threads other than the main thread will fail silently and terminate it.
      # https://ruby-doc.org/core-3.1.0/Thread.html#class-Thread-label-Exception+handling
      logger.error "Reporter error: #{ex.inspect}", *ex.backtrace
      nil
    end
  end
end
