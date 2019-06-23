# frozen_string_literal: true

require 'singleton'
require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/autoscale_api'
require 'rails_autoscale_agent/time_rounder'
require 'rails_autoscale_agent/registration'
require 'rails_autoscale_agent/worker_adapters/sidekiq'

# Reporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class Reporter
    include Singleton
    include Logger

    WORKER_ADAPTERS = [
      WorkerAdapters::Sidekiq.new,
    ]

    def self.start(config, store)
      instance.start!(config, store) unless instance.started?
    end

    def start!(config, store)
      @started = true
      @worker_adapters = WORKER_ADAPTERS.select(&:enabled?)

      if !config.api_base_url
        logger.info "Reporter not started: #{config.addon_name}_URL is not set"
        return
      end

      Thread.new do
        logger.tagged 'RailsAutoscale' do
          register!(config)

          loop do
            # Stagger reporting to spread out reports from many processes
            multiplier = 1 - (rand / 4) # between 0.75 and 1.0
            sleep config.report_interval * multiplier

            begin
              @worker_adapters.map { |a| a.collect!(store) }
              report!(config, store)
            rescue => ex
              # Exceptions in threads other than the main thread will fail silently
              # https://ruby-doc.org/core-2.2.0/Thread.html#class-Thread-label-Exception+handling
              logger.error "Reporter error: #{ex.inspect}"
              logger.error ex.backtrace.join("\n")
            end
          end
        end
      end
    end

    def started?
      @started
    end

    def report!(config, store)
      report = store.pop_report

      if report.measurements.any?
        logger.info "Reporting #{report.measurements.size} measurements"

        params = report.to_params(config)
        result = AutoscaleApi.new(config.api_base_url).report_metrics!(params, report.to_csv)

        case result
        when AutoscaleApi::SuccessResponse
          logger.debug "Reported successfully"
        when AutoscaleApi::FailureResponse
          logger.error "Reporter failed: #{result.failure_message}"
        end
      else
        logger.debug "Reporter has nothing to report"
      end
    end

    def register!(config)
      params = Registration.new(config).to_params
      result = AutoscaleApi.new(config.api_base_url).register_reporter!(params)

      case result
      when AutoscaleApi::SuccessResponse
        config.report_interval = result.data['report_interval'] if result.data['report_interval']
        config.max_request_size = result.data['max_request_size'] if result.data['max_request_size']
        logger.info "Reporter starting, will report every #{config.report_interval} seconds or so"
      when AutoscaleApi::FailureResponse
        logger.error "Reporter failed to register: #{result.failure_message}"
      end
    end

  end
end
