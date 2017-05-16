require 'singleton'
require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/autoscale_api'
require 'rails_autoscale_agent/time_rounder'
require 'rails_autoscale_agent/registration'

# Reporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class Reporter
    include Singleton
    include Logger

    def self.start(config, store)
      instance.start!(config, store) unless instance.running?
    end

    def start!(config, store)
      logger.info "Reporter starting, will report every minute"

      @running = true

      Thread.new do
        logger.tagged 'RailsAutoscale', config.to_s do
          register!(config)

          loop do
            beginning_of_next_minute = TimeRounder.beginning_of_minute(Time.now) + 60

            # add 0-5 seconds to avoid slamming the API at one moment
            next_report_time = beginning_of_next_minute + rand * 5

            sleep next_report_time - Time.now

            begin
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

    def running?
      @running
    end

    def report!(config, store)
      return unless config.api_base_url

      while report = store.pop_report
        logger.info "Reporting queue times for #{report.values.size} requests during minute #{report.time.iso8601}"

        params = report.to_params(config)
        result = AutoscaleApi.new(config.api_base_url).report_metrics!(params)

        case result
        when AutoscaleApi::SuccessResponse
          logger.info "Reported successfully"
        when AutoscaleApi::FailureResponse
          logger.error "Reporter failed: #{result.failure_message}"
        end
      end

      logger.debug "Reporter has nothing to report" unless result
    end

    def register!(config)
      params = Registration.new(config).to_params
      result = AutoscaleApi.new(config.api_base_url).register_reporter!(params)

      if result.is_a? AutoscaleApi::FailureResponse
        logger.error "Reporter failed to register: #{result.failure_message}"
      end
    end

  end
end
